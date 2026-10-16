import Ps.Elab.Proof
import Ps.Elab.RecursionParameters

/-
Selected Nat-measure recursion, grounded in Lean 4.35.0
eb6cafb7290e8bd5f2937522d8d804f58f02bafc:
  Lean/Elab/PreDefinition/WF/Fix.lean (replaceRecApps, solveDecreasingGoals,
  mkFix), WF/Unfold.lean, and Init/WF.lean:470-517.
The checked Standard already contains WellFounded.Nat.fix and fix_eq.
This module constructs their actual typed application; it introduces no
recursive axiom, opacity marker, fuel bound, or unchecked equation.
-/

def psWellFoundedFixName : PsName :=
  psNameAppendStr (psNameAppendStr (psRootName "WellFounded") "Nat") "fix"
def psWellFoundedFixEqName : PsName :=
  psNameAppendStr (psNameAppendStr (psRootName "WellFounded") "Nat") "fix_eq"

def psElabWellFoundedIsNat (context : PsElabContext) (type : PsExpr) : Bool :=
  psDefEqReadOnlyWithEnv context.environment context.metaContext
    context.localContext type (.constE psNatName [])

def psElabWellFoundedReferenceEscapes
    (context : PsElabContext) (sourceName : PsSyntaxName) : Bool :=
  match context.wellFoundedRecursion, psSyntaxNameToName sourceName with
  | some recursion, some name =>
    psNameEq name recursion.functionName &&
      (psLocalFindUser context.localContext name).isNone
  | _, _ => false

-- Read the current callback telescope after dependent match refinement. In
-- particular, a successor branch must get measure(y) < measure(succ k), not
-- the stale outer major's type. The matcher already owns that generalization.
def psTryElabWellFoundedSelfCall (elaborate : PsElaborator)
    (context : PsElabContext) (fn : PsSyntaxTerm) (arguments : List PsSyntaxTerm)
    (expected : Option PsExpr) : Except PsElabError (Option PsElabTermResult) := do
  let some recursion := context.wellFoundedRecursion | return none
  let .reference sourceName := fn | return none
  if !psElabWellFoundedReferenceEscapes context sourceName then return none
  if arguments.length != recursion.parameterIds.length then
    throw (.data "PSCV0-WF-ARITY: the recursive call must supply every explicit Nat parameter")
  let nat := PsExpr.constE psNatName []
  let captured ← psElabRecursionCaptureArguments elaborate context arguments nat
  let some callback := psLocalFindUser captured.context.localContext recursion.callbackName
    | throw (.data "PSCV0-WF-INTERNAL: missing refined recursive callback")
  let span := context.sourceSpan.getD (psSyntaxTermSpan fn)
  let call : PsElabRecursionCall := {
    localContext := captured.context.localContext
    arguments := captured.values
    span := span }
  let current := { captured.context with
    wellFoundedCallsRev := call :: captured.context.wellFoundedCallsRev }
  let (next, term) ← if recursion.collectCalls then
      pure (current, psExprApplyMany (.fvar (psLocalDeclId callback)) captured.values)
    else do
      let some argument := psElabRecursionParameterArgument
          recursion.parameterIds captured.values recursion.majorId
        | throw (.data "PSCV0-WF-INTERNAL: missing measured recursive argument")
      let parameter ← (psInferEnsureForall current.environment current.metaContext
        current.localContext (psLocalDeclType callback)).mapError PsElabError.infer
      if !psElabWellFoundedIsNat current parameter.domain then
        throw (.data "PSCV0-WF-INTERNAL: recursive callback has a non-Nat domain")
      let proof ← (psInferEnsureForall current.environment current.metaContext
        current.localContext (psExprInstantiate1 parameter.body argument)).mapError PsElabError.infer
      let states ← recursion.stateIds.mapM fun id =>
        match psElabRecursionParameterArgument recursion.parameterIds captured.values id with
        | some value => pure value
        | none => throw (.data "PSCV0-WF-INTERNAL: missing recursive state argument")
      let fresh := psMetaFresh current.metaContext current.localContext
        proof.domain .syntheticOpaque { tag := "decrease" }
      let .mvar goal := fresh.expr
        | throw (.data "PSCV0-WF-INTERNAL: invalid decrease goal")
      let next := { current with
        metaContext := fresh.context
        wellFoundedGoalsRev := (goal, span) :: current.wellFoundedGoalsRev }
      pure (next, psExprApplyMany (.fvar (psLocalDeclId callback))
        ([argument, fresh.expr] ++ states))
  let resolved ← psElabResolvedTerm next term (some nat)
  let closed ← psElabAbstract context resolved.context captured.abstractions resolved.term nat
  return some (← psElabFinalizeExpected closed expected)

-- Defaults prove only the existing checked natural-order rules. There is no
-- Boolean termination oracle and no implicit omega or arithmetic fallback.
def psElabWellFoundedDefaultGoals (state : PsProofState) :
    Except PsElabError PsProofState := do
  let mut current ← psProofNormalize state
  for goal in state.goals do
    if (psMetaFindAssignment current.context.metaContext goal.id).isSome then continue
    let selected := { current with goals := [goal] }
    let solved ← match psProofAssumption selected with
      | .ok next => pure next
      | .error _ => match psProofNaturalBounds selected with
        | .ok next => pure next
        | .error _ =>
          throw (.data "PSCV0-WF-DECREASE: default natural-order rules could not prove a call decreases; supply decreasing_by by { ... }")
    if !solved.goals.isEmpty then
      throw (.data "PSCV0-WF-DECREASE: default proof left an unsolved decrease goal")
    current := { solved with goals := current.goals }
  psProofNormalize current

def psElabWellFoundedSolveGoals (elaborate : PsElaborator)
    (context : PsElabContext) (decreasing : Option PsSyntaxTerm) :
    Except PsElabError PsElabContext := do
  let calls := context.wellFoundedGoalsRev.reverse
  if calls.isEmpty then
    throw (.data "PSCV0-WF-NOT-RECURSIVE: termination_by was supplied for a nonrecursive declaration")
  let goals := calls.map fun entry => ({ id := entry.fst, tag := "decrease" } : PsProofGoal)
  -- A proof may use facts from a call's captured branch context, but cannot
  -- create new source recursive calls while proving those calls decrease.
  let state : PsProofState := {
    context := { context with wellFoundedRecursion := none }
    goals }
  let solved ← match decreasing with
    | none => psElabWellFoundedDefaultGoals state
    | some (.byE tactics scope _) => psProofRun elaborate scope 4096 state tactics
    | some _ =>
      throw (.data "PSCV0-WF-PROOF: decreasing_by requires the selected by { tactic sequence } body")
  let solved ← psProofNormalize solved
  if !solved.goals.isEmpty then
    throw (.data "PSCV0-WF-DECREASE: decreasing_by left unsolved call goals")
  for (id, _) in calls do
    if psExprHasUnresolvedMeta (psMetaInstantiate solved.context.metaContext (.mvar id)) then
      throw (.data "PSCV0-WF-DECREASE: unresolved decrease proof or scope closure")
  return solved.context

structure PsElabWellFoundedResult where
  declaration : PsDeclaration
  equation : PsDeclaration
  metaContext : PsMetaContext
  sourceInfo : PsElabSourceInfo

def psElabWellFoundedLambdas (binders : List PsElabTypedBinder) (body : PsExpr) : PsExpr :=
  binders.foldr (fun binder body =>
    .lam binder.name binder.type (psExprAbstractFVar binder.id body) binder.binder) body

def psElabWellFoundedForalls (binders : List PsElabTypedBinder) (body : PsExpr) : PsExpr :=
  binders.foldr (fun binder body =>
    .forallE binder.name binder.type (psExprAbstractFVar binder.id body) binder.binder) body

-- This explicit proof is needed because portable conversion does not add
-- function eta. The leaf compares fully applied terms by checked conversion;
-- every function layer is justified by the Standard's actual funext theorem.
def psElabWellFoundedExtensionalEquality (count : Nat) (context : PsElabContext)
    (type left right : PsExpr) : Except PsElabError PsExpr := do
  match count with
  | 0 =>
    let level ← psElabExpressionSort context type
    let proof := psLogicRefl level type left
    let checked ← psElabResolvedTerm context proof (some (psLogicEq level type left right))
    return checked.term
  | count + 1 =>
    let pi ← (psInferEnsureForall context.environment context.metaContext
      context.localContext type).mapError PsElabError.infer
    let pushed := psLocalPushBinding context.localContext pi.name pi.domain pi.binder
    let inner := { context with localContext := pushed.context }
    let argument := PsExpr.fvar pushed.id
    let resultType := psExprInstantiate1 pi.body argument
    let proof ← psElabWellFoundedExtensionalEquality count inner resultType
      (.app left argument) (.app right argument)
    let domainLevel ← psElabExpressionSort context pi.domain
    let resultLevel ← psElabExpressionSort inner resultType
    let motive := PsExpr.lam pi.name pi.domain
      (psExprAbstractFVar pushed.id resultType) pi.binder
    let pointwise := PsExpr.lam pi.name pi.domain
      (psExprAbstractFVar pushed.id proof) pi.binder
    return psExprApplyMany (.constE (psRootName "funext") [domainLevel, resultLevel])
      [pi.domain, motive, left, right, pointwise]

def psElabWellFoundedCongrArg (domain range left right function proof : PsExpr) : PsExpr :=
  let one := PsLevel.succ .zero
  psExprApplyMany (.constE (psRootName "congrArg") [one, one])
    [domain, range, left, right, function, proof]

-- Explicit Nat header parameters may be fixed or evolve independently of
-- the measure. One changing Nat argument owns the measure; the other changing
-- arguments are generalized into the result motive. No body lambda is moved
-- into the header or into the termination clause's lexical scope.
def psElabWellFoundedParts (elaborate : PsElaborator)
    (environment : PsEnvironment) (nameSyntax : PsSyntaxName)
    (binders : List (PsSyntaxBinderHead × PsSyntaxTerm))
    (typeSyntax valueSyntax : PsSyntaxTerm) (termination : PsSyntaxTermination)
    (levelNames : List PsName := []) :
    Except PsElabError PsElabWellFoundedResult := do
  let some name := psSyntaxNameToName nameSyntax | throw .emptyName
  let equationName := psNameAppendStr name "eq_def"
  if (psEnvironmentFind environment name).isSome then
    throw (.duplicateDeclaration name)
  if (psEnvironmentFind environment equationName).isSome then
    throw (.duplicateDeclaration equationName)
  if !levelNames.isEmpty then
    throw (.data "PSCV0-WF-TELESCOPE: universe-polymorphic well-founded declarations are outside the selected Nat slice")
  let some (.definitionDecl ..) := psEnvironmentFind environment psWellFoundedFixName
    | throw (.data "PSCV0-WF-FOUNDATION: checked WellFounded.Nat.fix is unavailable")
  let some (.theoremDecl ..) := psEnvironmentFind environment psWellFoundedFixEqName
    | throw (.data "PSCV0-WF-FOUNDATION: checked WellFounded.Nat.fix_eq is unavailable")
  let binderResult ← psElabTypedBinders elaborate (psElabContextEmpty environment) binders
  let parameters := binderResult.bindersRev.reverse
  if parameters.isEmpty then
    throw (.data "PSCV0-WF-TELESCOPE: the selected slice requires explicit Nat header parameters")
  for parameter in parameters do
    let .explicit := parameter.binder
      | throw (.data "PSCV0-WF-TELESCOPE: the selected Nat parameters must be explicit")
    if !psElabWellFoundedIsNat binderResult.context parameter.type then
      throw (.data "PSCV0-WF-DOMAIN: the selected argument domains are Nat")
  let annotation ← psElabType elaborate binderResult.context typeSyntax
  if !psElabWellFoundedIsNat annotation.context annotation.type then
    throw (.data "PSCV0-WF-RESULT: the selected result type is Nat")
  let nat := PsExpr.constE psNatName []
  -- The self callback is not in scope in the result annotation or measure.
  let measured ← elaborate annotation.context termination.measure (some nat)
  let measureBody := psMetaInstantiate measured.context.metaContext measured.term
  if psExprHasUnresolvedMeta measureBody then
    throw (.data "PSCV0-WF-MEASURE: unresolved Nat-valued measure")
  let parameterIds := parameters.map (·.id)
  if !(psExprFVarIds measureBody).all parameterIds.contains then
    throw (.data "PSCV0-WF-MEASURE: the measure escaped its declared header scope")
  let declaredParameters := parameters.map fun parameter =>
    { parameter with type := psMetaInstantiate measured.context.metaContext parameter.type }
  let declaredResult := psMetaInstantiate measured.context.metaContext annotation.type
  let declaredType := psElabWellFoundedForalls declaredParameters declaredResult
  -- Probe with a hygienic local function, not a temporary declaration/axiom.
  -- The probe owns no final proof goals, source information, or body value.
  let probeName := psNameAppendNum (psRootName "_psc0WellFoundedProbe")
    measured.context.localContext.nextId
  let probe := psLocalPushBinding measured.context.localContext probeName declaredType .explicit
  let probeContext := { measured.context with
    localContext := probe.context
    structuralRecursion := none
    wellFoundedRecursion := some {
      functionName := name, callbackName := probeName
      parameterIds := parameterIds, collectCalls := true }
    wellFoundedGoalsRev := []
    wellFoundedCallsRev := [] }
  let probed ← elaborate probeContext valueSyntax (some nat)
  if psExprHasUnresolvedMeta (psMetaInstantiate probed.context.metaContext probed.term) then
    throw (.data "PSCV0-WF-PARAMETERS: unresolved provisional body while checking fixed arguments")
  let plan ← psElabRecursionNatParameterPlan probed.context parameterIds
    probed.context.wellFoundedCallsRev.reverse measureBody
  let some major := parameters.find? (fun parameter => parameter.id == plan.majorId)
    | throw (.data "PSCV0-WF-INTERNAL: selected parameter is not in the header")
  let states := (parameters.filter fun parameter => plan.stateIds.contains parameter.id).map
    (fun parameter => { parameter with type := nat })
  let stateType := psElabWellFoundedForalls states nat
  let measure := PsExpr.lam major.name nat
    (psExprAbstractFVar major.id measureBody) .explicit
  let localId := measured.context.localContext.nextId
  let callbackName := psNameAppendNum (psRootName "_psc0WellFounded") localId
  let smallerMeasure := PsExpr.app measure (.fvar localId)
  let currentMeasure := PsExpr.app measure (.fvar major.id)
  let relation := psExprApplyMany (.constE (psNameAppendStr psNatName "lt") [])
    [smallerMeasure, currentMeasure]
  let callbackType := psLogicPi localId "_smaller" nat
    (psLogicPi (localId + 1) "_decreases" relation stateType)
  let _ ← psElabExpressionSort measured.context callbackType
  let callback := psLocalPushBinding measured.context.localContext callbackName callbackType .explicit
  let bodyContext := { measured.context with
    localContext := callback.context
    structuralRecursion := none
    wellFoundedRecursion := some {
      functionName := name, callbackName := callbackName
      parameterIds := parameterIds, majorId := plan.majorId
      stateIds := plan.stateIds, fixedIds := plan.fixedIds }
    wellFoundedGoalsRev := []
    wellFoundedCallsRev := [] }
  let value ← elaborate bodyContext valueSyntax (some nat)
  psElabRecursionValidateFixedParameters value.context plan value.context.wellFoundedCallsRev
  let solved ← psElabWellFoundedSolveGoals elaborate value.context termination.decreasing
  let body := psMetaInstantiate solved.metaContext value.term
  if psExprHasUnresolvedMeta body then
    throw (.data "PSCV0-WF-DECREASE: unresolved body or delayed proof abstraction")
  let callbackType := psMetaInstantiate solved.metaContext callbackType
  let stateBody := psElabWellFoundedLambdas states body
  let functional := PsExpr.lam major.name nat
    (psExprAbstractFVar major.id
      (.lam callbackName callbackType (psExprAbstractFVar callback.id stateBody) .explicit)) .explicit
  let measure := psMetaInstantiate solved.metaContext measure
  if [measure, functional].any (fun term =>
      !(psExprFVarIds term).all plan.fixedIds.contains) then
    throw (.data "PSCV0-WF-SCOPE: the fixedpoint captured a changing parameter")
  let motive := PsExpr.lam (psRootName "_") nat stateType .explicit
  let one := PsLevel.succ .zero
  let fixed := psExprApplyMany (.constE psWellFoundedFixName [one, one])
    [nat, motive, measure, functional]
  let stateArguments := states.map (fun parameter => PsExpr.fvar parameter.id)
  let declaredValue := psElabWellFoundedLambdas declaredParameters
    (psExprApplyMany fixed ([.fvar major.id] ++ stateArguments))
  if !(psExprFVarIds declaredType).isEmpty || !(psExprFVarIds declaredValue).isEmpty then
    throw (.data "PSCV0-WF-SCOPE: declaration retained an out-of-scope local")
  let closedContext := psElabContextEmpty environment
  let _ ← psElabResolvedTerm closedContext declaredValue (some declaredType)
  let declaration := PsDeclaration.definitionDecl name [] declaredType declaredValue
  let some withDefinition := psEnvironmentAdd environment declaration
    | throw (.duplicateDeclaration name)
  -- The callback below calls the actual public f in its original argument
  -- order. Its state lambdas are justified by explicit extensionality, not
  -- by assuming eta conversion or an unproved source unfolding equation.
  let x := PsExpr.fvar major.id
  let yId := solved.localContext.nextId
  let y := PsExpr.fvar yId
  let decrease := psExprApplyMany (.constE (psNameAppendStr psNatName "lt") [])
    [.app measure y, .app measure x]
  let self := PsExpr.constE name []
  let originalArguments := parameters.map (fun parameter => PsExpr.fvar parameter.id)
  let recursiveArguments := parameters.map fun parameter =>
    if parameter.id == major.id then y else PsExpr.fvar parameter.id
  let unfoldCallback := psLogicLam yId "_smaller" nat
    (psLogicLam (yId + 1) "_decreases" decrease
      (psElabWellFoundedLambdas states (psExprApplyMany self recursiveArguments)))
  let rawCallback := psLogicLam yId "_smaller" nat
    (psLogicLam (yId + 1) "_decreases" decrease (.app fixed y))
  let rawRhs := psExprApplyMany functional [x, rawCallback]
  let sourceRhs := psExprApplyMany functional [x, unfoldCallback]
  let rawProof := psExprApplyMany (.constE psWellFoundedFixEqName [one, one])
    [nat, motive, measure, functional, x]
  let equationContext := { measured.context with environment := withDefinition }
  let equationProof ← if states.isEmpty then pure rawProof else do
    for constantName in [psRootName "funext", psRootName "congrArg", psNameAppendStr psEqName "trans"] do
      match psEnvironmentFind environment constantName with
      | some (.theoremDecl ..) | some (.definitionDecl ..) => pure ()
      | _ => throw (.data "PSCV0-WF-FOUNDATION: checked equality transport is unavailable")
    let callbackEquality ← psElabWellFoundedExtensionalEquality (2 + states.length)
      equationContext callbackType rawCallback unfoldCallback
    let transported := psElabWellFoundedCongrArg callbackType stateType
      rawCallback unfoldCallback (.app functional x) callbackEquality
    let fullEquality := psExprApplyMany (.constE (psNameAppendStr psEqName "trans") [one])
      [stateType, .app fixed x, rawRhs, sourceRhs, rawProof, transported]
    let applyName := psRootName "_applyState"
    let applyStates := PsExpr.lam applyName stateType
      (psExprApplyMany (.bvar 0) stateArguments) .explicit
    pure (psElabWellFoundedCongrArg stateType nat (.app fixed x) sourceRhs applyStates fullEquality)
  let rhs := psExprApplyMany sourceRhs stateArguments
  let equationType := psElabWellFoundedForalls declaredParameters
    (psLogicEq one nat (psExprApplyMany self originalArguments) rhs)
  let equationValue := psElabWellFoundedLambdas declaredParameters equationProof
  let _ ← psElabResolvedTerm (psElabContextEmpty withDefinition)
    equationValue (some equationType)
  let equation := PsDeclaration.theoremDecl equationName [] equationType equationValue
  return {
    declaration, equation, metaContext := solved.metaContext
    sourceInfo := psElabFinishSourceInfo solved name }
