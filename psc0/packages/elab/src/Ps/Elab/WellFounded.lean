import Ps.Elab.Proof

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
  let [source] := arguments
    | throw (.data "PSCV0-WF-ARITY: the selected recursive call requires one explicit Nat argument")
  let some callback := psLocalFindUser context.localContext recursion.callbackName
    | throw (.data "PSCV0-WF-INTERNAL: missing refined recursive callback")
  let parameter ← (psInferEnsureForall context.environment context.metaContext
    context.localContext (psLocalDeclType callback)).mapError PsElabError.infer
  if !psElabWellFoundedIsNat context parameter.domain then
    throw (.data "PSCV0-WF-INTERNAL: recursive callback has a non-Nat domain")
  let argument ← elaborate context source (some parameter.domain)
  let remaining := psExprInstantiate1 parameter.body argument.term
  let proof ← (psInferEnsureForall argument.context.environment argument.context.metaContext
    argument.context.localContext remaining).mapError PsElabError.infer
  if !psElabWellFoundedIsNat argument.context proof.body then
    throw (.data "PSCV0-WF-INTERNAL: recursive callback has a non-Nat result")
  let fresh := psMetaFresh argument.context.metaContext argument.context.localContext
    proof.domain .syntheticOpaque { tag := "decrease" }
  let .mvar goal := fresh.expr
    | throw (.data "PSCV0-WF-INTERNAL: invalid decrease goal")
  let span := context.sourceSpan.getD (psSyntaxTermSpan source)
  let next := { argument.context with
    metaContext := fresh.context
    wellFoundedGoalsRev := (goal, span) :: argument.context.wellFoundedGoalsRev }
  let term := psExprApplyMany (.fvar (psLocalDeclId callback)) [argument.term, fresh.expr]
  return some (← psElabResolvedTerm next term expected)

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

-- The initial executable slice has one explicit Nat argument and Nat result.
-- The measure itself is an ordinary scoped Nat-valued source term. Broader
-- telescopes require the argument-packing and invariant-parameter owners;
-- they must not silently run through structural recursion instead.
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
  let [major] := binderResult.bindersRev
    | throw (.data "PSCV0-WF-TELESCOPE: the selected slice requires exactly one explicit Nat parameter")
  let .explicit := major.binder
    | throw (.data "PSCV0-WF-TELESCOPE: the selected Nat parameter must be explicit")
  if !psElabWellFoundedIsNat binderResult.context major.type then
    throw (.data "PSCV0-WF-DOMAIN: the selected argument domain is Nat")
  let annotation ← psElabType elaborate binderResult.context typeSyntax
  if !psElabWellFoundedIsNat annotation.context annotation.type then
    throw (.data "PSCV0-WF-RESULT: the selected result type is Nat")
  let nat := PsExpr.constE psNatName []
  -- The self callback is not in scope in the result annotation or measure.
  let measured ← elaborate annotation.context termination.measure (some nat)
  let measureBody := psMetaInstantiate measured.context.metaContext measured.term
  if psExprHasUnresolvedMeta measureBody then
    throw (.data "PSCV0-WF-MEASURE: unresolved Nat-valued measure")
  let measure := PsExpr.lam major.name nat
    (psExprAbstractFVar major.id measureBody) .explicit
  let localId := measured.context.localContext.nextId
  let callbackName := psNameAppendNum (psRootName "_psc0WellFounded") localId
  let smallerMeasure := PsExpr.app measure (.fvar localId)
  let currentMeasure := PsExpr.app measure (.fvar major.id)
  let relation := psExprApplyMany (.constE (psNameAppendStr psNatName "lt") [])
    [smallerMeasure, currentMeasure]
  let callbackType := psLogicPi localId "_smaller" nat
    (psLogicPi (localId + 1) "_decreases" relation nat)
  let _ ← psElabExpressionSort measured.context callbackType
  let callback := psLocalPushBinding measured.context.localContext callbackName callbackType .explicit
  let bodyContext := { measured.context with
    localContext := callback.context
    structuralRecursion := none
    wellFoundedRecursion := some { functionName := name, callbackName }
    wellFoundedGoalsRev := [] }
  let value ← elaborate bodyContext valueSyntax (some nat)
  let solved ← psElabWellFoundedSolveGoals elaborate value.context termination.decreasing
  let body := psMetaInstantiate solved.metaContext value.term
  if psExprHasUnresolvedMeta body then
    throw (.data "PSCV0-WF-DECREASE: unresolved body or delayed proof abstraction")
  let callbackType := psMetaInstantiate solved.metaContext callbackType
  let functional := PsExpr.lam major.name nat
    (psExprAbstractFVar major.id
      (.lam callbackName callbackType (psExprAbstractFVar callback.id body) .explicit)) .explicit
  let measure := psMetaInstantiate solved.metaContext measure
  let motive := PsExpr.lam (psRootName "_") nat nat .explicit
  let one := PsLevel.succ .zero
  let fixed := psExprApplyMany (.constE psWellFoundedFixName [one, one])
    [nat, motive, measure, functional]
  let declaredDomain := psMetaInstantiate solved.metaContext major.type
  let declaredResult := psMetaInstantiate solved.metaContext annotation.type
  let declaredType := PsExpr.forallE major.name declaredDomain
    (psExprAbstractFVar major.id declaredResult) .explicit
  -- Keep the written parameter as an actual entry binder, including when the
  -- Core fixedpoint is a function-valued term before the final application.
  let declaredValue := PsExpr.lam major.name declaredDomain
    (.app fixed (.bvar 0)) .explicit
  if !(psExprFVarIds declaredType).isEmpty || !(psExprFVarIds declaredValue).isEmpty then
    throw (.data "PSCV0-WF-SCOPE: declaration retained an out-of-scope local")
  let closedContext := psElabContextEmpty environment
  let _ ← psElabResolvedTerm closedContext declaredValue (some declaredType)
  let declaration := PsDeclaration.definitionDecl name [] declaredType declaredValue
  let some withDefinition := psEnvironmentAdd environment declaration
    | throw (.duplicateDeclaration name)
  -- fix_eq proves the actual source equation after beta-reducing F's checked
  -- callback applications. The callback ignores only the decrease proof;
  -- its argument is the actual recursive argument already elaborated above.
  let x := PsExpr.fvar major.id
  let yId := solved.localContext.nextId
  let y := PsExpr.fvar yId
  let decrease := psExprApplyMany (.constE (psNameAppendStr psNatName "lt") [])
    [.app measure y, .app measure x]
  let self := PsExpr.constE name []
  let unfoldCallback := psLogicLam yId "_smaller" nat
    (psLogicLam (yId + 1) "_decreases" decrease (.app self y))
  let rhs := psExprApplyMany functional [x, unfoldCallback]
  let equationType := PsExpr.forallE major.name declaredDomain
    (psExprAbstractFVar major.id (psLogicEq one nat (.app self x) rhs)) .explicit
  let equationProof := psExprApplyMany (.constE psWellFoundedFixEqName [one, one])
    [nat, motive, measure, functional, x]
  let equationValue := PsExpr.lam major.name declaredDomain
    (psExprAbstractFVar major.id equationProof) .explicit
  let _ ← psElabResolvedTerm (psElabContextEmpty withDefinition)
    equationValue (some equationType)
  let equation := PsDeclaration.theoremDecl equationName [] equationType equationValue
  return {
    declaration, equation, metaContext := solved.metaContext
    sourceInfo := psElabFinishSourceInfo solved name }
