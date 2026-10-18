import Ps.Elab.PreDefinition.Header
import Ps.Elab.RecursionParameters
import Ps.Meta.MutualPacking
import Ps.Meta.MutualWellFounded

/-!
Total mutual WF runtime recovery from checked Core.
Pinned Lean4.35.0 WF/Main and Basic.addAndCompilePartialRec separate logical
construction and execution. PSC0 additionally reconstructs the actual functional
body before allowing a private ordinary definition to supply runtime code.
No source sidecar, equation alone or partial marker grants this authority.
Reference commit eb6cafb7290e8bd5f2937522d8d804f58f02bafc;
see THIRD_PARTY_NOTICES.md for upstream attribution.
-/

def psElabWellFoundedRuntimeError (message : String) : PsElabError :=
  .data ("PSCV0-WF-RUNTIME: " ++ message)

def psElabWellFoundedRawArity : PsExpr → Nat
  | .lam _ _ body _ => 1 + psElabWellFoundedRawArity body
  | _ => 0

structure PsElabWellFoundedRuntimePublic where
  name : PsName
  type : PsExpr
  opened : PsElabPreDefinitionOpened
  fixedArguments : List PsExpr
  permutation : List (Option Nat)
  varyingNames : List PsName
  index : Nat
  major : PsExpr

-- Only the actual raw public lambda prefix owns source arity. Beta/zeta may
-- expose its packed entry, but may not turn a returned function into a header.
def psElabWellFoundedRuntimePublic (environment : PsEnvironment)
    (levels : List PsName) (auxiliary : PsName) (fixedCount arity : Nat)
    (fixed : PsElabPreDefinitionOpened) (domain : PsExpr) (name : PsName) :
    Except PsElabError PsElabWellFoundedRuntimePublic := do
  let some (.definitionDecl _ declaredLevels type value) := psEnvironmentFind environment name
    | throw (psElabWellFoundedRuntimeError "missing ordinary public definition")
  if !psElabMutualLevelNamesEqual levels declaredLevels ||
      psExprHasUnresolvedMeta type || psExprHasUnresolvedMeta value ||
      !psExprFVarsInContext psLocalEmpty type || !psExprFVarsInContext psLocalEmpty value then
    throw (psElabWellFoundedRuntimeError "public definition changed closed universes or scope")
  let opened ← psElabPreDefinitionOpen (psElabWellFoundedRawArity value)
    (psElabContextEmpty environment levels) type value
  let entry := psReduceAppView (psWhnfCore psMetaEmpty opened.context.localContext opened.value)
  if !psExprAlphaEq entry.head (.constE auxiliary (levels.map PsLevel.param)) ||
      entry.args.length != fixedCount + 1 then
    throw (psElabWellFoundedRuntimeError "public body is not the exact auxiliary entry")
  let fixedArguments := entry.args.take fixedCount
  let fixedIds ← fixedArguments.mapM fun argument =>
    match argument with
    | .fvar id => pure id
    | _ => throw (psElabWellFoundedRuntimeError "fixed argument is not an original source binding")
  let parameters := opened.bindersRev.reverse
  let parameterIds := parameters.map (·.id)
  if fixedIds.eraseDups.length != fixedIds.length || !fixedIds.all parameterIds.contains then
    throw (psElabWellFoundedRuntimeError "fixed arguments duplicate or escape the original header")
  let permutation := parameterIds.map fun id =>
    ((fixedIds.zipIdx).find? fun (candidate, _) => candidate == id).map Prod.snd
  psElabRecursionValidatePermutation permutation fixedCount
  let varying := (parameters.zip permutation).filterMap fun (parameter, position) =>
    if position.isNone then some parameter else none
  if varying.isEmpty then
    throw (psElabWellFoundedRuntimeError "no varying original arguments")
  let substitutions := (fixed.bindersRev.reverse.map (·.id)).zip fixedArguments
  let domain := psElabSubstituteLocals substitutions domain
  let some major := entry.args[fixedCount]?
    | throw (psElabWellFoundedRuntimeError "missing packed entry")
  let some (index, actualTuple) := psMutualPackingUnpack arity domain major
    | throw (psElabWellFoundedRuntimeError "entry has no owned component injection")
  let domains ← (psMutualPackingDomains arity domain).mapError PsElabError.infer
  let some memberDomain := domains[index]?
    | throw (psElabWellFoundedRuntimeError "entry has no original component domain")
  let expectedTuple ← (psWellFoundedTuplePack memberDomain
    (varying.map fun parameter => .fvar parameter.id)).mapError PsElabError.infer
  if !psExprAlphaEq actualTuple expectedTuple then
    throw (psElabWellFoundedRuntimeError "entry changed the original varying argument pack")
  let _ ← psElabResolvedTerm opened.context major (some domain)
  return { name, type, opened, fixedArguments, permutation
           varyingNames := varying.map (·.name), index, major }

-- A beta argument is substituted only when it is already a value. Keep
-- other arguments in real lets so recovery does not duplicate source work.
-- Constructors/type applications are values only when their fields are values.
private def psElabWellFoundedRuntimeValue (environment : PsEnvironment) : PsExpr → Bool
  | .fvar _ | .bvar _ | .lit _ | .lam .. | .sortE _ | .forallE .. => true
  | .constE name _ =>
    (psEnvironmentFindConstructor environment name).isSome ||
      (psEnvironmentFindInductive environment name).isSome
  | .app fn argument =>
    match (psReduceAppView fn).head with
    | .constE name _ =>
      ((psEnvironmentFindConstructor environment name).isSome ||
        (psEnvironmentFindInductive environment name).isSome) &&
        psElabWellFoundedRuntimeValue environment fn &&
        psElabWellFoundedRuntimeValue environment argument
    | _ => false
  | _ => false

-- Specialize the checked packing program, never the public recursive functions.
-- Only the two actual checked packing wrappers may delta-reduce; their
-- registered recursors/projections use the shared metadata-checked iota rule.
-- Pinned LCNF.ToLCNF.visitCases and Simp.Main.simpCasesOnCtor? likewise
-- eliminate known constructor cases. Here this happens before typed erasure.
private def psElabWellFoundedRuntimeSpecialize (fuel : Nat)
    (environment : PsEnvironment) (expression : PsExpr) : Except PsElabError PsExpr := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    let visit := psElabWellFoundedRuntimeSpecialize fuel environment
    match expression with
    | .letE name type value body =>
      let value ← visit value
      if psElabWellFoundedRuntimeValue environment value then
        visit (psExprInstantiate1 body value)
      else
        return .letE name type value (← visit body)
    | .lam name type body binder =>
      return .lam name type (← visit body) binder
    | .app .. =>
      let view := psReduceAppView expression
      -- Expand the frozen wrapper's actual body, not a name-based target
      -- primitive. No other definition, public peer or fixedpoint unfolds.
      if let .constE name levels := view.head then
        if psNameEq name (psNameAppendStr (psRootName "PSum") "casesOn") ||
            psNameEq name (psNameAppendStr psWellFoundedPairName "casesOn") then
          let some (.definitionDecl _ parameters _ body) := psEnvironmentFind environment name
            | throw (psElabWellFoundedRuntimeError "packing wrapper is not an actual checked definition")
          if parameters.length != levels.length then
            throw (psElabWellFoundedRuntimeError "packing wrapper universe arity changed")
          return ← visit (psReduceApply
            (psExprInstantiateLevelParams parameters levels body) view.args)
      let head ← visit view.head
      match head, view.args with
      | .lam name domain body _, argument :: rest =>
        if psElabWellFoundedRuntimeValue environment argument then
          visit (psReduceApply (psExprInstantiate1 body argument) rest)
        else
          -- Move later applications inside the let, preserving evaluation
          -- order and shifting them beneath its real de Bruijn binder.
          visit (.letE name domain argument
            (psReduceApply body (rest.map (psExprLiftBVars 1 0))))
      | .letE name type value body, arguments =>
        visit (.letE name type value
          (psReduceApply body (arguments.map (psExprLiftBVars 1 0))))
      | _, _ =>
        let arguments ← view.args.mapM visit
        let rebuilt := psReduceApply head arguments
        let packing := match head with
          | .constE name _ =>
            psNameEq name (psNameAppendStr (psRootName "PSum") "rec") ||
              psNameEq name (psNameAppendStr psWellFoundedPairName "rec")
          | _ => false
        if packing then
          if let some reduced := psReduceIota
              (psWhnfCore psMetaEmpty psLocalEmpty) environment rebuilt then
            return ← visit reduced
        return rebuilt
    | .proj owner index value =>
      let value ← visit value
      if psNameEq owner psWellFoundedPairName then
        if let some field := psReduceProjectionIota (fun term => term)
            environment owner index value then
          return ← visit field
      return .proj owner index value
    | _ => return expression

-- Produce ordinary checked implementation definitions from the actual logical
-- auxiliary/public projections. Callers must supply the real checked environment;
-- post-lifting validators first restore only owned ordinary recursor helpers.
def psElabWellFoundedRuntimeBodies (environment : PsEnvironment)
    (auxiliary : PsName) (publicNames : List PsName) :
    Except PsElabError (List PsDeclaration) := do
  if publicNames.length < 2 || publicNames.any (fun name =>
      (publicNames.filter (psNameEq name)).length != 1) then
    throw (psElabWellFoundedRuntimeError "component needs distinct original public members")
  let some (.definitionDecl _ levels type value) := psEnvironmentFind environment auxiliary
    | throw (psElabWellFoundedRuntimeError "missing actual auxiliary definition")
  if psExprHasUnresolvedMeta type || psExprHasUnresolvedMeta value ||
      !psExprFVarsInContext psLocalEmpty type || !psExprFVarsInContext psLocalEmpty value then
    throw (psElabWellFoundedRuntimeError "auxiliary is not closed")
  let fixedCount := psElabWellFoundedRawArity value
  -- Each original public header reopens from zero. The common fixed scope
  -- must be disjoint from all of them: local substitution is ordered, so
  -- overlapping source/target IDs could compose a permutation accidentally.
  -- This is the same freshness invariant as RecursionOpenFixedScope.
  let arities ← publicNames.mapM fun name =>
    match psEnvironmentFind environment name with
    | some (.definitionDecl _ _ _ body) => pure (psElabWellFoundedRawArity body)
    | _ => throw (psElabWellFoundedRuntimeError "missing original public header")
  let initial := { psElabContextEmpty environment levels with
    localContext := { psLocalEmpty with nextId := arities.foldl max 0 } }
  let fixed ← psElabPreDefinitionOpen fixedCount initial type value
  let parameter ← (psInferEnsureForall environment psMetaEmpty fixed.context.localContext
    fixed.type).mapError PsElabError.infer
  let probe := psLocalPushBinding fixed.context.localContext parameter.name parameter.domain .explicit
  let application := psReduceAppView
    (psWhnfCore psMetaEmpty probe.context (.app fixed.value (.fvar probe.id)))
  let some actual ← (psWellFoundedFixApplicationView application.head application.args).mapError
      PsElabError.infer
    | throw (psElabWellFoundedRuntimeError "auxiliary is not an actual selected well-founded fixpoint")
  if !actual.arguments.isEmpty || !psExprAlphaEq actual.major (.fvar probe.id) ||
      !psWellFoundedDefEq environment psMetaEmpty fixed.context.localContext
        actual.plan.domain parameter.domain ||
      (psWellFoundedPlanTerms actual.plan ++ [actual.motive, actual.functional]).any
        (fun term => !psExprFVarsInContext fixed.context.localContext term) then
    throw (psElabWellFoundedRuntimeError "fixedpoint changed its original unary or fixed telescope")
  let _ ← psElabResolvedTerm fixed.context fixed.value (some fixed.type)
  let publics ← publicNames.mapM
    (psElabWellFoundedRuntimePublic environment levels auxiliary fixedCount
      publicNames.length fixed parameter.domain)
  let ordered ← (List.range publicNames.length).mapM fun index =>
    match publics.filter (fun member => member.index == index) with
    | [member] => pure member
    | _ => throw (psElabWellFoundedRuntimeError "missing or duplicate public component projection")
  let some first := ordered.head?
    | throw (psElabWellFoundedRuntimeError "empty public component")
  if !psNameEq auxiliary (psNameAppendStr first.name "_mutual") then
    throw (psElabWellFoundedRuntimeError "auxiliary has a different original component owner")
  let fixedValues := psElabBinderArguments fixed.bindersRev
  let unaryPublics ← ordered.mapM fun member => do
    let specialized ← psElabRecursionSpecializeHeader fixed.context member.type
      member.permutation fixedValues
    let source := psCloseElabLambdaBinders psMetaEmpty specialized.bindersRev
      (psExprApplyMany (.constE member.name (levels.map PsLevel.param)) specialized.arguments)
    let unaryType ← (psMutualPackingProjectionType environment psMetaEmpty
      fixed.context.localContext ordered.length member.index fixed.type).mapError PsElabError.infer
    (psWellFoundedTupleUncurry environment psMetaEmpty fixed.context.localContext
      member.varyingNames unaryType source).mapError PsElabError.infer
  let aggregate ← (psMutualPackingUncurry environment psMetaEmpty fixed.context.localContext
    fixed.type unaryPublics).mapError PsElabError.infer
  ordered.mapM fun member => do
    let substitutions := (fixed.bindersRev.reverse.map (·.id)).zip member.fixedArguments
    let instantiate := psElabSubstituteLocals substitutions
    let context := member.opened.context
    let functional := instantiate actual.functional
    let branch := PsExpr.app functional member.major
    let branchType ← (psInferType environment psMetaEmpty context.localContext branch).mapError
      PsElabError.infer
    let callback ← (psInferEnsureForall environment psMetaEmpty context.localContext branchType).mapError
      PsElabError.infer
    let smaller ← (psInferEnsureForall environment psMetaEmpty context.localContext callback.domain).mapError
      PsElabError.infer
    let next := psLocalPushBinding context.localContext smaller.name smaller.domain smaller.binder
    let evidence ← (psInferEnsureForall environment psMetaEmpty next.context
      (psExprInstantiate1 smaller.body (.fvar next.id))).mapError PsElabError.infer
    let proofLevel ← psElabExpressionSort { context with localContext := next.context } evidence.domain
    if !psLevelEquivalent proofLevel .zero then
      throw (psElabWellFoundedRuntimeError "decreasing callback lost its genuine proof slot")
    let proof := psLocalPushBinding next.context evidence.name evidence.domain evidence.binder
    let call := PsExpr.app (instantiate aggregate) (.fvar next.id)
    let replacement := PsExpr.lam smaller.name smaller.domain
      (psExprAbstractFVar next.id
        (.lam evidence.name evidence.domain (psExprAbstractFVar proof.id call) evidence.binder))
      smaller.binder
    let checked ← psElabResolvedTerm context replacement (some callback.domain)
    let body := PsExpr.app branch checked.term
    let _ ← psElabResolvedTerm context body (some member.opened.type)
    let specialized ← psElabWellFoundedRuntimeSpecialize 4096 environment body
    let _ ← psElabResolvedTerm context specialized (some member.opened.type)
    -- The original header owns entry arity. Specializing a returned lambda
    -- must not silently turn it into another flat declaration parameter.
    let body := PsExpr.letE (psRootName "_psc0WFBody") member.opened.type specialized (.bvar 0)
    let closed := psCloseElabLambdaBinders psMetaEmpty member.opened.bindersRev body
    if psExprHasUnresolvedMeta closed || !psExprFVarsInContext psLocalEmpty closed then
      throw (psElabWellFoundedRuntimeError "recovered body retained a local or proof hole")
    let _ ← psElabResolvedTerm (psElabContextEmpty environment levels) closed (some member.type)
    return .definitionDecl (PsName.num member.name 0) levels member.type closed
