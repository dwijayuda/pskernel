import Ps.Elab.Proof
import Ps.Elab.RecursionParameters
import Ps.Elab.Universe

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
    throw (.data "PSCV0-WF-ARITY: the recursive call must supply the complete explicit header telescope")
  let some sourceType := recursion.sourceType
    | throw (.data "PSCV0-WF-INTERNAL: missing recursive source telescope")
  let captured ← psElabRecursionCaptureArguments elaborate context arguments sourceType
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
  let resolved ← psElabResolvedTerm next term (some captured.resultType)
  let resultType := psMetaInstantiate resolved.context.metaContext resolved.type
  -- Independent result types already belong to the caller's scope. Delaying
  -- them on unresolved dictionaries in argument let values would hide a real
  -- function result behind an opaque type meta before a chained application.
  -- Value closure still retains every original argument let in source order.
  let closedType ← if !psExprHasTermMeta resultType &&
      psExprFVarsInContext context.localContext resultType then
    psElabResolvedTerm (psElabLeaveScope context resolved.context) resultType none
  else psElabAbstractType context resolved.context captured.abstractions resultType
  let inner := psElabContextWithMeta resolved.context closedType.context.metaContext
  let closed ← psElabAbstract context inner captured.abstractions resolved.term closedType.term
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

def psElabWellFoundedCongrArg (context : PsElabContext)
    (domain range left right function proof : PsExpr) : Except PsElabError PsExpr := do
  let domainLevel ← psElabExpressionSort context domain
  let rangeLevel ← psElabExpressionSort context range
  return psExprApplyMany (.constE (psRootName "congrArg") [domainLevel, rangeLevel])
    [domain, range, left, right, function, proof]

-- Explicit typed header parameters may be fixed or evolve independently of
-- the Nat-valued measure. The measured argument's domain depends only on fixed
-- captures; changing state and the declared result form a dependent motive.
-- No body lambda enters the header or the termination clause's lexical scope.
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
  let some (.definitionDecl ..) := psEnvironmentFind environment psWellFoundedFixName
    | throw (.data "PSCV0-WF-FOUNDATION: checked WellFounded.Nat.fix is unavailable")
  let some (.theoremDecl ..) := psEnvironmentFind environment psWellFoundedFixEqName
    | throw (.data "PSCV0-WF-FOUNDATION: checked WellFounded.Nat.fix_eq is unavailable")
  let binderResult ← psElabTypedBinders elaborate
    (psElabContextEmpty environment levelNames) binders
  let parameters := binderResult.bindersRev.reverse
  if parameters.isEmpty then
    throw (.data "PSCV0-WF-TELESCOPE: the selected slice requires explicit typed header parameters")
  for parameter in parameters do
    let .explicit := parameter.binder
      | throw (.data "PSCV0-WF-TELESCOPE: the selected header parameters must be explicit")
  let annotation ← psElabType elaborate binderResult.context typeSyntax
  let nat := PsExpr.constE psNatName []
  -- The self callback is not in scope in the result annotation or measure.
  let measured ← elaborate annotation.context termination.measure (some nat)
  let measureBody := psMetaInstantiate measured.context.metaContext measured.term
  if psExprHasUnresolvedMeta (psElabGeneralizeExpr measureBody) then
    throw (.data "PSCV0-WF-MEASURE: unresolved Nat-valued measure")
  let parameterIds := parameters.map (·.id)
  if !(psExprFVarIds measureBody).all parameterIds.contains then
    throw (.data "PSCV0-WF-MEASURE: the measure escaped its declared header scope")
  let declaredParameters := parameters.map fun parameter =>
    { parameter with type := psMetaInstantiate measured.context.metaContext parameter.type }
  let declaredResult := psMetaInstantiate measured.context.metaContext annotation.type
  let declaredType := psElabWellFoundedForalls declaredParameters declaredResult
  if psExprHasUnresolvedMeta (psElabGeneralizeExpr declaredType) then
    throw (.data "PSCV0-WF-TELESCOPE: the complete declared parameter and result types must be resolved")
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
      parameterIds := parameterIds, collectCalls := true, sourceType := some declaredType }
    wellFoundedGoalsRev := []
    wellFoundedCallsRev := [] }
  let probed ← elaborate probeContext valueSyntax (some declaredResult)
  if psExprHasUnresolvedMeta (psElabGeneralizeExpr
      (psMetaInstantiate probed.context.metaContext probed.term)) then
    throw (.data "PSCV0-WF-PARAMETERS: unresolved provisional body while checking fixed arguments")
  let plan ← psElabRecursionNatParameterPlan probed.context parameterIds
    probed.context.wellFoundedCallsRev.reverse measureBody
  let some major := declaredParameters.find? (fun parameter => parameter.id == plan.majorId)
    | throw (.data "PSCV0-WF-INTERNAL: selected parameter is not in the header")
  if !(psExprFVarIds major.type).all plan.fixedIds.contains then
    throw (.data "PSCV0-WF-MAJOR-DOMAIN: the measured argument's domain depends on changing state; dependent argument packing is unavailable")
  let states := declaredParameters.filter fun parameter => plan.stateIds.contains parameter.id
  let stateType := psElabWellFoundedForalls states declaredResult
  let measure := PsExpr.lam major.name major.type
    (psExprAbstractFVar major.id measureBody) .explicit
  let localId := measured.context.localContext.nextId
  let callbackName := psNameAppendNum (psRootName "_psc0WellFounded") localId
  let smallerMeasure := PsExpr.app measure (.fvar localId)
  let currentMeasure := PsExpr.app measure (.fvar major.id)
  let relation := psExprApplyMany (.constE (psNameAppendStr psNatName "lt") [])
    [smallerMeasure, currentMeasure]
  let smallerStateType := psExprInstantiate1
    (psExprAbstractFVar major.id stateType) (.fvar localId)
  let callbackType := psLogicPi localId "_smaller" major.type
    (psLogicPi (localId + 1) "_decreases" relation smallerStateType)
  let _ ← psElabExpressionSort measured.context callbackType
  let callback := psLocalPushBinding measured.context.localContext callbackName callbackType .explicit
  let bodyContext := { measured.context with
    localContext := callback.context
    structuralRecursion := none
    wellFoundedRecursion := some {
      functionName := name, callbackName := callbackName
      parameterIds := parameterIds, majorId := plan.majorId
      stateIds := plan.stateIds, fixedIds := plan.fixedIds, sourceType := some declaredType }
    wellFoundedGoalsRev := []
    wellFoundedCallsRev := [] }
  let value ← elaborate bodyContext valueSyntax (some declaredResult)
  psElabRecursionValidateFixedParameters value.context plan value.context.wellFoundedCallsRev
  let solved ← psElabWellFoundedSolveGoals elaborate value.context termination.decreasing
  -- Generalize only at this actual declaration boundary, as ordinary checked
  -- declarations do. All terms and the equation's local telescope use the same
  -- instantiated levels; unresolved term/proof holes remain an error.
  let normalize := fun (expression : PsExpr) =>
    psElabGeneralizeExpr (psMetaInstantiate solved.metaContext expression)
  let body := normalize value.term
  if psExprHasUnresolvedMeta body then
    throw (.data "PSCV0-WF-DECREASE: unresolved body or delayed proof abstraction")
  let declaredParameters := declaredParameters.map fun parameter =>
    { parameter with type := normalize parameter.type }
  let declaredResult := normalize declaredResult
  let declaredType := psElabWellFoundedForalls declaredParameters declaredResult
  let major := { major with type := normalize major.type }
  let states := states.map fun parameter => { parameter with type := normalize parameter.type }
  let stateType := psElabWellFoundedForalls states declaredResult
  let callbackType := normalize callbackType
  let measure := normalize measure
  let localDeclarations := measured.context.localContext.declarations.map fun declaration =>
    match declaration with
    | .binding id name type binder => .binding id name (normalize type) binder
    | .letDecl id name type value => .letDecl id name (normalize type) (normalize value)
  let localContext := { measured.context.localContext with
    declarations := localDeclarations
    nextId := max measured.context.localContext.nextId solved.localContext.nextId }
  let normalizedContext := { measured.context with
    localContext := localContext
    metaContext := psMetaEmpty }
  let stateBody := psElabWellFoundedLambdas states body
  let functional := PsExpr.lam major.name major.type
    (psExprAbstractFVar major.id
      (.lam callbackName callbackType (psExprAbstractFVar callback.id stateBody) .explicit)) .explicit
  let motive := PsExpr.lam major.name major.type
    (psExprAbstractFVar major.id stateType) .explicit
  if [major.type, motive, measure, functional].any (fun term =>
      !(psExprFVarIds term).all plan.fixedIds.contains) then
    throw (.data "PSCV0-WF-SCOPE: the fixedpoint captured a changing parameter")
  if [declaredType, motive, measure, functional].any psExprHasUnresolvedMeta then
    throw (.data "PSCV0-WF-TELESCOPE: unresolved fixedpoint type or universe")
  let domainLevel ← psElabExpressionSort normalizedContext major.type
  let stateLevel ← psElabExpressionSort normalizedContext stateType
  let resultLevel ← psElabExpressionSort normalizedContext declaredResult
  let fixed := psExprApplyMany (.constE psWellFoundedFixName [domainLevel, stateLevel])
    [major.type, motive, measure, functional]
  let stateArguments := states.map (fun parameter => PsExpr.fvar parameter.id)
  let declaredValue := psElabWellFoundedLambdas declaredParameters
    (psExprApplyMany fixed ([.fvar major.id] ++ stateArguments))
  if !(psExprFVarIds declaredType).isEmpty || !(psExprFVarIds declaredValue).isEmpty then
    throw (.data "PSCV0-WF-SCOPE: declaration retained an out-of-scope local")
  let levels := psElabDeclarationLevels levelNames [declaredType, declaredValue]
  let closedContext := psElabContextEmpty environment levels
  let _ ← psElabResolvedTerm closedContext declaredValue (some declaredType)
  let declaration := PsDeclaration.definitionDecl name levels declaredType declaredValue
  let some withDefinition := psEnvironmentAdd environment declaration
    | throw (.duplicateDeclaration name)
  -- The callback calls the actual public f in original header order. Its
  -- dependent state domains are specialized to the smaller major before any
  -- state binder is opened. Explicit extensionality justifies state lambdas.
  let x := PsExpr.fvar major.id
  let yId := normalizedContext.localContext.nextId
  let y := PsExpr.fvar yId
  let decrease := psExprApplyMany (.constE (psNameAppendStr psNatName "lt") [])
    [.app measure y, .app measure x]
  let self := PsExpr.constE name (levels.map PsLevel.param)
  let originalArguments := declaredParameters.map (fun parameter => PsExpr.fvar parameter.id)
  let recursiveArguments := declaredParameters.map fun parameter =>
    if parameter.id == major.id then y else PsExpr.fvar parameter.id
  let smallerStates := states.map fun parameter =>
    { parameter with type := psExprInstantiate1 (psExprAbstractFVar major.id parameter.type) y }
  let unfoldCallback := psLogicLam yId "_smaller" major.type
    (psLogicLam (yId + 1) "_decreases" decrease
      (psElabWellFoundedLambdas smallerStates (psExprApplyMany self recursiveArguments)))
  let rawCallback := psLogicLam yId "_smaller" major.type
    (psLogicLam (yId + 1) "_decreases" decrease (.app fixed y))
  let rawRhs := psExprApplyMany functional [x, rawCallback]
  let sourceRhs := psExprApplyMany functional [x, unfoldCallback]
  let rawProof := psExprApplyMany (.constE psWellFoundedFixEqName [domainLevel, stateLevel])
    [major.type, motive, measure, functional, x]
  let equationContext := { normalizedContext with environment := withDefinition }
  let equationProof ← if states.isEmpty then pure rawProof else do
    for constantName in [psRootName "funext", psRootName "congrArg", psNameAppendStr psEqName "trans"] do
      match psEnvironmentFind environment constantName with
      | some (.theoremDecl ..) | some (.definitionDecl ..) => pure ()
      | _ => throw (.data "PSCV0-WF-FOUNDATION: checked equality transport is unavailable")
    let callbackEquality ← psElabWellFoundedExtensionalEquality (2 + states.length)
      equationContext callbackType rawCallback unfoldCallback
    let transported ← psElabWellFoundedCongrArg equationContext callbackType stateType
      rawCallback unfoldCallback (.app functional x) callbackEquality
    let fullEquality := psExprApplyMany (.constE (psNameAppendStr psEqName "trans") [stateLevel])
      [stateType, .app fixed x, rawRhs, sourceRhs, rawProof, transported]
    let applyName := psRootName "_applyState"
    let applyStates := PsExpr.lam applyName stateType
      (psExprApplyMany (.bvar 0) stateArguments) .explicit
    psElabWellFoundedCongrArg equationContext stateType declaredResult
      (.app fixed x) sourceRhs applyStates fullEquality
  let rhs := psExprApplyMany sourceRhs stateArguments
  let equationType := psElabWellFoundedForalls declaredParameters
    (psLogicEq resultLevel declaredResult (psExprApplyMany self originalArguments) rhs)
  let equationValue := psElabWellFoundedLambdas declaredParameters equationProof
  let equationLevels := psElabDeclarationLevels levels [equationType, equationValue]
  let _ ← psElabResolvedTerm (psElabContextEmpty withDefinition equationLevels)
    equationValue (some equationType)
  let equation := PsDeclaration.theoremDecl equationName equationLevels equationType equationValue
  return {
    declaration, equation, metaContext := solved.metaContext
    sourceInfo := psElabFinishSourceInfo solved name }
