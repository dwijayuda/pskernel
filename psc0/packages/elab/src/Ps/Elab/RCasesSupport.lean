import Ps.Elab.ProofTerm

-- Adapted from Lean 4.35.0 Lean/Elab/Tactic/RCases.lean at
-- eb6cafb7290e8bd5f2937522d8d804f58f02bafc (Apache-2.0).
-- Continuations carry checked identities through the shared elimination log.
structure PsProofRCasesFrame where
  context : PsElabContext
  target : PsExpr
  tag : String
  refinements : PsElabRefinements := []
  clears : List PsExpr := []

abbrev PsProofRCasesContinuation :=
  PsProofRCasesFrame → Except PsElabError PsElabTermResult

def psProofRCasesName? : PsSyntaxRCasesPattern → Option PsSyntaxName
  | .one name =>
    if name.segments == ["_"] || name.segments == ["rfl"] then none else some name
  | .paren pattern _ | .typed pattern _ _ | .alternatives [pattern] _ =>
    psProofRCasesName? pattern
  | _ => none

def psProofRCasesDefault (span : PsSourceSpan) : PsSyntaxRCasesPattern :=
  .one (PsSyntaxName.mk ["_"] span)

def psProofRCasesAsTuple : PsSyntaxRCasesPattern → Bool × List PsSyntaxRCasesPattern
  | .paren pattern _ => psProofRCasesAsTuple pattern
  | .explicit pattern _ => (true, (psProofRCasesAsTuple pattern).2)
  | .tuple patterns _ => (false, patterns)
  | pattern => (false, [pattern])

def psProofRCasesAsAlternatives : PsSyntaxRCasesPattern → List PsSyntaxRCasesPattern
  | .paren pattern _ => psProofRCasesAsAlternatives pattern
  | .alternatives patterns _ => patterns
  | pattern => [pattern]

-- Missing patterns are wildcards. Surplus patterns recursively match the last
-- explicit field; a zero-field constructor ignores them, as native rcases does.
def psProofRCasesFields (span : PsSourceSpan) (explicit : Bool)
    (binders : List PsBinderInfo) (patterns : List PsSyntaxRCasesPattern) :
    List PsSyntaxRCasesPattern :=
  match binders with
  | [] => []
  | binder :: rest =>
    if !explicit && !psBinderInfoEq binder .explicit then
      psProofRCasesDefault span :: psProofRCasesFields span explicit rest patterns
    else if !rest.isEmpty then
      patterns.headD (psProofRCasesDefault span) ::
        psProofRCasesFields span explicit rest (patterns.drop 1)
    else
      match patterns with
      | [] => [psProofRCasesDefault span]
      | [pattern] => [pattern]
      | patterns =>
        let pattern := PsSyntaxRCasesPattern.tuple patterns span
        [if explicit then .explicit pattern span else pattern]

def psProofRCasesCurrent (frame : PsProofRCasesFrame) (value : PsExpr) : PsExpr :=
  psMetaInstantiate frame.context.metaContext
    (psElabSubstituteLocals frame.refinements value)

def psProofRCasesRemoveLocals (context : PsElabContext) (ids : List Nat) : PsElabContext :=
  { context with
    localContext := { context.localContext with
      declarations := context.localContext.declarations.filter
        (fun declaration => !ids.contains (psLocalDeclId declaration))
      nameAliases := context.localContext.nameAliases.filter
        (fun alias => !ids.contains alias.id) }
    auxiliaryLocalIds := context.auxiliaryLocalIds.filter (fun id => !ids.contains id) }

-- Reverted roots are inaccessible while their dependents are reopened.
-- Keeping their checked declarations until closure lets the outer transport
-- retain its exact proof, without letting a soon-cleared name shadow a survivor.
def psProofRCasesHideLocals (context : PsElabContext) (ids : List Nat) : PsElabContext :=
  { context with localContext := { context.localContext with
    declarations := context.localContext.declarations.map fun declaration =>
      if !ids.contains (psLocalDeclId declaration) then declaration
      else
        let name := psNameAppendNum (psRootName "$psc0RCasesReverted") (psLocalDeclId declaration)
        match declaration with
        | .binding id _ type binder => .binding id name type binder
        | .letDecl id _ type value => .letDecl id name type value
    nameAliases := context.localContext.nameAliases.filter (fun alias => !ids.contains alias.id) } }

-- Native finish clears after every pattern continuation has run. Clear the
-- forward dependency closure where possible, retaining all actual goal needs.
def psProofRCasesFinish (frame : PsProofRCasesFrame) :
    Except PsElabError PsElabTermResult := do
  let context := frame.context
  let roots := frame.clears.filterMap fun value =>
    match psProofRCasesCurrent frame value with
    | .fvar id => if psLocalContainsId context.localContext id then some id else none
    | _ => none
  let candidates := roots ++ (psElabDependentLocals context roots []).map (·.binder.id)
  let needed := psExprFVarIds (psMetaInstantiate context.metaContext frame.target) ++
    context.localContext.declarations.filterMap (fun declaration =>
      if candidates.contains (psLocalDeclId declaration) then none
      else some (psLocalDeclId declaration))
  let needed := psElabMatchRequiredDependencies context needed
  let context := psProofRCasesRemoveLocals context
    (candidates.filter (fun id => !needed.contains id))
  let _ ← psElabExpressionSort context frame.target
  let fresh := psMetaFresh context.metaContext context.localContext frame.target
    .syntheticOpaque { tag := frame.tag }
  return {
    context := psElabContextWithMeta context fresh.context
    term := fresh.expr, type := frame.target }

def psProofRCasesType (elaborate : PsElaborator) (scope : PsSyntaxProofScope)
    (context : PsElabContext) (source : PsSyntaxTerm) :
    Except PsElabError PsElabTermResult := do
  let source ← psProofSource scope context source
  let result ← elaborate context source none
  let _ ← psElabExpressionSort result.context result.term
  return result

def psProofRCasesAscribeType (frame : PsProofRCasesFrame)
    (value type : PsExpr) : Except PsElabError PsProofRCasesFrame := do
  let checked ← psElabResolvedTerm frame.context value (some type)
  let context := checked.context
  let locals := match value with
    | .fvar id => context.localContext.declarations.map fun declaration =>
      match declaration with
      | .binding current name original binder =>
        .binding current name (if current == id then type else original) binder
      | .letDecl current name original term =>
        .letDecl current name (if current == id then type else original) term
    | _ => context.localContext.declarations
  return { frame with
    context := psElabContextWithLocal context { context.localContext with declarations := locals } }

def psProofRCasesAscribe (elaborate : PsElaborator) (scope : PsSyntaxProofScope)
    (frame : PsProofRCasesFrame) (value : PsExpr) (source : PsSyntaxTerm) :
    Except PsElabError PsProofRCasesFrame := do
  let annotation ← psProofRCasesType elaborate scope frame.context source
  psProofRCasesAscribeType { frame with context := annotation.context } value annotation.term

-- A constructor's complete checked telescope decides implicit-field visibility.
-- No source pattern is asked to predict binder kinds or promoted parameters.
def psProofRCasesConstructorBinders (context : PsElabContext)
    (constructor : PsConstructorInfo) : Except PsElabError (List PsBinderInfo) := do
  let opened ← psElabOpenCoreTelescope 4096 context constructor.type
    (some (constructor.numParams + constructor.numFields))
  return (opened.bindersRev.reverse.drop constructor.numParams).map (·.binder)

-- RHS-first is native substEq's choice. Both the replaced variable and equality
-- proof are abstracted with their dependent telescope, including let values.
def psProofRCasesSubstituteEq (finish : PsProofRCasesContinuation)
    (frame : PsProofRCasesFrame) (proof : PsExpr) :
    Except PsElabError PsElabTermResult := do
  let context := frame.context
  let .fvar proofId := proof | throw (.proof "rfl pattern requires a local equality")
  let some declaration := psLocalFindById context.localContext proofId
    | throw (.proof "rfl pattern equality is outside its checked scope")
  let originalType := psMetaInstantiate context.metaContext (psLocalDeclType declaration)
  let equation ← psElabEquationView context originalType proof
  let norm := psWhnf context.environment context.metaContext context.localContext
  let right := norm equation.right
  let left := norm equation.left
  let (id, symmetric) ← match right with
    | .fvar id => pure (id, false)
    | _ => match left with
      | .fvar id => pure (id, true)
      | _ => throw (.proof "rfl pattern requires an equality with a variable side")
  let equation ← if symmetric then psElabEquationSymm context { equation with left, right }
    else pure { equation with left, right }
  let dependencies := psElabMatchRequiredDependencies context (psExprFVarIds equation.left)
  if dependencies.contains id then
    throw (.proof "rfl pattern substitution would be cyclic")
  let roots := [id, proofId]
  let dependents := psElabDependentLocals context roots []
  let telescope := psElabCloseDependentType dependents frame.target
  let originalView := psExprAppView (norm originalType)
  let originalHEq := match originalView.head with
    | .constE name _ => psNameEq name (psRootName "HEq")
    | _ => false
  let reflexivity := if originalHEq then
      psExprApplyMany (.constE (psNameAppendStr (psRootName "HEq") "refl") [equation.level])
        [equation.type, equation.left]
    else psLogicRefl equation.level equation.type equation.left
  let substitutions := [(id, equation.left), (proofId, reflexivity)]
  let specialized := psElabSubstituteLocals substitutions telescope
  let opened ← psElabOpenDependents dependents {
    context := psProofRCasesHideLocals context roots
    body := specialized, bindersRev := [], aliasesRev := []
    replacements := substitutions }
  let removed := roots ++ dependents.map (·.binder.id)
  let inner := psProofRCasesRemoveLocals opened.context removed
  let body ← finish { frame with
    context := inner
    target := opened.body
    refinements := frame.refinements ++ opened.replacements }
  let base ← psElabCloseDependents context opened body specialized
  let context := base.context
  let xName := psNameAppendNum (psRootName "$psc0RCasesValue") context.localContext.nextId
  let x := psLocalPushBinding context.localContext xName equation.type .explicit
  let xContext := psElabContextWithLocal context x.context
  let hType := psLogicEq equation.level equation.type equation.left (.fvar x.id)
  let hName := psNameAppendNum (psRootName "$psc0RCasesEquality") x.context.nextId
  let h := psLocalPushBinding x.context hName hType .explicit
  let hContext := psElabContextWithLocal xContext h.context
  let currentEquation : PsElabEquation := {
    level := equation.level, type := equation.type
    left := equation.left, right := .fvar x.id, proof := .fvar h.id }
  let originalProof ← if symmetric then psElabEquationSymm hContext currentEquation
    else pure currentEquation
  let expectedProofType := psElabSubstituteLocals [(id, .fvar x.id)] originalType
  let originalProof ← psElabSourceMatchEquationConvert hContext
    (psLogicEq originalProof.level originalProof.type originalProof.left originalProof.right)
    originalProof.proof expectedProofType
  let motiveBody := psElabSubstituteLocals
    [(id, .fvar x.id), (proofId, originalProof.term)] telescope
  let motiveLevel ← psElabExpressionSort originalProof.context motiveBody
  let motive := psCloseElabLambdaBinders originalProof.context.metaContext
    [PsElabTypedBinder.mk h.id hName hType .explicit,
     PsElabTypedBinder.mk x.id xName equation.type .explicit] motiveBody
  let context := psElabLeaveScope context originalProof.context
  let transported := psExprApplyMany
    (.constE (psNameAppendStr psEqName "rec") [motiveLevel, equation.level])
    [equation.type, equation.left, motive, base.term, equation.right, equation.proof]
  psElabResolvedTerm context
    (psExprApplyMany transported (psElabDependentArguments dependents)) (some frame.target)

def psProofRCasesSubstitute (finish : PsProofRCasesContinuation)
    (frame : PsProofRCasesFrame) (proof : PsExpr) :
    Except PsElabError PsElabTermResult := do
  let .fvar proofId := proof | throw (.proof "rfl pattern requires a local equality")
  let some declaration := psLocalFindById frame.context.localContext proofId
    | throw (.proof "rfl pattern equality is outside its checked scope")
  let context := frame.context
  let type := psMetaInstantiate context.metaContext (psLocalDeclType declaration)
  let view := psExprAppView (psWhnf context.environment context.metaContext context.localContext type)
  let equation ← psElabEquationView context type proof
  let dependent := !(psElabDependentLocals context [proofId] []).isEmpty ||
    psElabExprContainsLocal proofId (psMetaInstantiate context.metaContext frame.target)
  let isHEq := match view.head with
    | .constE name _ => psNameEq name (psRootName "HEq")
    | _ => false
  if isHEq then
    let eqType := psLogicEq equation.level equation.type equation.left equation.right
    let name := psLocalDeclUserName declaration
    let pushed := psLocalPushBinding context.localContext name eqType .explicit
    let inner := psElabContextWithLocal context pushed.context
    let inner := if dependent then inner else psProofRCasesRemoveLocals inner [proofId]
    let result ← psProofRCasesSubstituteEq finish { frame with context := inner } (.fvar pushed.id)
    return ← psElabAbstract context result.context
      [.letE pushed.id name eqType equation.proof] result.term frame.target
  -- Native substReduced asserts a definitionally equal Eq and clears the old
  -- proof before substitution. A proof-dependent old local cannot be cleared.
  let right := psWhnf context.environment context.metaContext context.localContext equation.right
  let chosenOriginal := match right with | .fvar _ => equation.right | _ => equation.left
  let chosen := psWhnf context.environment context.metaContext context.localContext chosenOriginal
  if dependent && !psExprAlphaEq chosenOriginal chosen then
    throw (.proof "rfl pattern cannot clear a reduced equality with dependents")
  psProofRCasesSubstituteEq finish frame proof
