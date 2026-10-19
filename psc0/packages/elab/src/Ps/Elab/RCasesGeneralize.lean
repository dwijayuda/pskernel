import Ps.Elab.RCasesSupport

structure PsProofRCasesItem where
  value : PsExpr
  pattern : PsSyntaxRCasesPattern
  -- A top-level type annotation is elaborated before its target, retaining
  -- that checked expression instead of resolving its names in a new scope.
  annotation? : Option PsExpr := none

structure PsProofRCasesInput where
  item : PsProofRCasesItem
  type : PsExpr
  equationName? : Option PsSyntaxName := none

def psProofRCasesNeedsGeneralization (input : PsProofRCasesInput) : Bool :=
  input.equationName?.isSome || match input.item.value with | .fvar _ => false | _ => true

def psProofRCasesGeneralizedType (context : PsElabContext)
    (inputs : List PsProofRCasesInput) (target : PsExpr) :
    Except PsElabError (PsElabContext × PsExpr) := do
  match inputs with
  | [] => return (context, target)
  | input :: rest =>
    let (context, body) ← psProofRCasesGeneralizedType context rest target
    let name ← match psProofRCasesName? input.item.pattern with
      | some sourceName => match psSyntaxNameToName sourceName with
        | some name => pure name
        | none => throw .emptyName
      | none => pure (psNameAppendNum (psRootName "$psc0RCasesTarget") rest.length)
    let term := psMetaInstantiate context.metaContext input.item.value
    let type := psMetaInstantiate context.metaContext input.type
    let (context, body) ← psElabKeyAbstract context term body .instances
    return (context, .forallE name type body .explicit)

-- Native generalizeExceptFVar is simultaneous. Build and check the complete
-- telescope before opening any target; only requested equations keep originals.
def psProofRCasesGeneralize
    (finish : List PsProofRCasesItem → PsProofRCasesContinuation)
    (frame : PsProofRCasesFrame) (inputs : List PsProofRCasesInput) :
    Except PsElabError PsElabTermResult := do
  let inputs := inputs.map fun input => { input with item := { input.item with
    value := psMetaInstantiate frame.context.metaContext input.item.value } }
  let generalized := inputs.filter psProofRCasesNeedsGeneralization
  if generalized.isEmpty then return ← finish (inputs.map (·.item)) frame
  let (context, telescope) ← psProofRCasesGeneralizedType frame.context generalized frame.target
  let _ ← psElabExpressionSort context telescope
  let opened ← psElabOpenCoreTelescope 4096 context telescope (some generalized.length)
  let variables := psElabBinderArguments opened.bindersRev
  let mut current := opened.context
  let mut equationBinders : List PsElabTypedBinder := []
  let mut reflexivities : List PsExpr := []
  for (input, generalizedValue) in generalized.zip variables do
    if let some sourceName := input.equationName? then
      let some name := psSyntaxNameToName sourceName | throw .emptyName
      let (type, _) ← psElabIndexEquation current input.item.value generalizedValue
      let view := psExprAppView type
      let heterogeneous := match view.head with
        | .constE name _ => psNameEq name (psRootName "HEq")
        | _ => false
      let level ← psElabExpressionSort current input.type
      let proof := if heterogeneous then
          psExprApplyMany (.constE (psNameAppendStr (psRootName "HEq") "refl") [level])
            [input.type, input.item.value]
        else psLogicRefl level input.type input.item.value
      let pushed := psLocalPushBinding current.localContext name type .explicit
      current := psElabContextWithLocal current pushed.context
      equationBinders := PsElabTypedBinder.mk pushed.id name type .explicit :: equationBinders
      reflexivities := reflexivities ++ [proof]
  let (items, remaining) ← inputs.foldlM
    (fun (state : List PsProofRCasesItem × List PsExpr) input => do
      if !psProofRCasesNeedsGeneralization input then
        pure (state.1 ++ [input.item], state.2)
      else
        let value :: rest := state.2
          | throw (.proof "recursive elimination lost a generalized target")
        pure (state.1 ++ [{ input.item with value }], rest)) ([], variables)
  if !remaining.isEmpty then throw (.proof "recursive elimination target arity mismatch")
  let binders := equationBinders ++ opened.bindersRev
  let type := psCloseElabForallBinders current.metaContext binders opened.body
  let _ ← psElabExpressionSort context type
  let result ← finish items { frame with context := current, target := opened.body }
  let closed ← psElabAbstract context result.context
    (psElabLambdaAbstractions binders) result.term type
  psElabResolvedTerm closed.context
    (psExprApplyMany closed.term (generalized.map (·.item.value) ++ reflexivities))
    (some frame.target)

def psProofRCasesReadInputs (elaborate : PsElaborator) (scope : PsSyntaxProofScope)
    (context : PsElabContext)
    (targets : List (PsSyntaxMatchDiscriminant PsSyntaxTerm))
    (patterns : List PsSyntaxRCasesPattern) :
    Except PsElabError (PsElabContext × List PsProofRCasesInput) := do
  match targets, patterns with
  | [], [] => return (context, [])
  | target :: targets, pattern :: patterns =>
    let annotation ← match pattern with
      | .typed _ type _ => do
        let value ← psProofRCasesType elaborate scope context type
        pure (value.context, some value.term)
      | _ => pure (context, none)
    let source ← psProofSource scope annotation.1 target.term
    let value ← elaborate annotation.1 source annotation.2
    let input : PsProofRCasesInput := {
      item := { value := value.term, pattern, annotation? := annotation.2 }
      type := value.type, equationName? := target.equationName? }
    let (context, rest) ← psProofRCasesReadInputs elaborate scope value.context targets patterns
    return (context, input :: rest)
  | _, _ => throw (.proof "recursive elimination source arity mismatch")

def psProofRCasesComplete (elaborate : PsElaborator) (state : PsProofState)
    (action : PsProofRCasesContinuation) : Except PsElabError PsProofState := do
  let (goal, context, target) ← psProofMain state
  let result ← psProofWithTermSynthesis elaborate context fun current =>
    action { context := current, target, tag := goal.tag }
  let pending := psProofFreshGoals context.metaContext.nextId result.context
  let next ← psProofAssign (psProofUpdate state result.context) goal.id result.term
  psProofNormalize { next with goals := pending ++ state.goals.drop 1 }
