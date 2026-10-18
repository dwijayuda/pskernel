import Ps.Erasure.Basic
import Ps.Meta.Recursor

-- A root recursor can reuse the current function only when its varying locals
-- are absent from all minors. Otherwise a recursive call would silently change
-- captured values. Higher-order folds/indexers must first normalize to a
-- function-valued worker with the structural major as an explicit parameter.
-- When no valid worker plan exists, the IH stays erased and cannot be used.
structure PsErasureRecursionPlan where
  family : PsName
  numParams : Nat
  numIndices : Nat
  majorId : Nat
  indexIds : List (Nat × Nat)

def psErasureRecursionParameter (scope : PsErasureScope) (expr : PsExpr) : Option Nat := do
  let current ← scope.currentDefinition
  let _ ← current.coreName
  let .fvar id := expr | none
  if current.coreParametersRev.any (psExprAlphaEq expr) then some id else none

def psErasurePlanRecursion (scope : PsErasureScope) (family : PsName)
    (numParams : Nat) (major : PsExpr) (indices minors : List PsExpr) :
    Option PsErasureRecursionPlan := do
  let _ ← psRecursorVaryingLocals major indices minors
  let majorId ← psErasureRecursionParameter scope major
  let indexIds ← (indices.zipIdx).mapM fun (index, position) => do
    let id ← psErasureRecursionParameter scope index
    return (id, position)
  return { family, numParams, numIndices := indices.length, majorId, indexIds }

-- Build the actual dependent call before erasing it. Core identities, rather
-- than runtime positions, also handle erased indices and function fields.
def psErasureRecursiveCoreCall (environment : PsEnvironment)
    (scope : PsErasureScope) (plan : PsErasureRecursionPlan) (child : PsExpr) :
    Except PsErasureError PsExpr := do
  let some current := scope.currentDefinition | throw .unsupportedRuntimeTerm
  let some name := current.coreName | throw .unsupportedRuntimeTerm
  if psErasureLookupName scope.declarationNames name != some current.name then
    throw .unsupportedRuntimeTerm
  let some declaration := psEnvironmentFind environment name | throw .unsupportedRuntimeTerm
  let type ← (psInferType environment psMetaEmpty scope.localContext child).mapError
    (fun _ => PsErasureError.unsupportedRuntimeTerm)
  let view := psErasureAppView (psWhnf environment psMetaEmpty scope.localContext type)
  let .constE family _ := view.head | throw .unsupportedRuntimeTerm
  if !psNameEq family plan.family || view.args.length != plan.numParams + plan.numIndices then
    throw .unsupportedRuntimeTerm
  let indices := view.args.drop plan.numParams
  let replacements ← plan.indexIds.mapM fun (id, position) => do
    let some index := indices[position]? | throw PsErasureError.unsupportedRuntimeTerm
    return (id, index)
  let replacements := (plan.majorId, child) :: replacements
  let arguments ← current.coreParametersRev.reverse.mapM fun argument => do
    let .fvar id := argument | throw PsErasureError.unsupportedRuntimeTerm
    return match replacements.find? (fun entry => entry.1 == id) with
      | some (_, replacement) => replacement
      | none => argument
  return psReduceApply (.constE name ((psDeclarationLevelParams declaration).map PsLevel.param)) arguments

-- A positive field telescope and its IH telescope have exactly the same
-- domains and binder kinds. Build Core lambdas once; ordinary erasure handles
-- type, proof, index and runtime arguments uniformly for every backend.
def psErasureRecursiveFieldHypothesis (fuel : Nat) (environment : PsEnvironment)
    (call : PsErasureScope → PsExpr → Except PsErasureError PsExpr)
    (scope : PsErasureScope) (child type : PsExpr) : Except PsErasureError PsExpr := do
  match fuel with
  | 0 => throw .unsupportedRuntimeTerm
  | fuel + 1 =>
    match psWhnf environment psMetaEmpty scope.localContext type with
    | .forallE name domain body binder =>
      let pushed := psLocalPushBinding scope.localContext name domain binder
      let value ← psErasureRecursiveFieldHypothesis fuel environment call
        { scope with localContext := pushed.context }
        (.app child (.fvar pushed.id)) (psExprInstantiate1 body (.fvar pushed.id))
      return .lam name domain (psExprAbstractFVar pushed.id value) binder
    | _ => call scope child

structure PsErasureGroupRecursionPlan where
  workers : PsRecursorWorkerGroup
  captures : List PsExpr
  levels : List PsLevel
  application : PsEliminationRecursorApplication

inductive PsErasureRecursionDispatch where
  | singleton (plan : PsErasureRecursionPlan)
  | group (plan : PsErasureGroupRecursionPlan)

-- Only the exact root equation of a validated worker may dispatch its IHs.
-- A nested fold or changed capture cannot reuse a caller merely because its
-- major happens to have the same family. The raw entry telescope is retained.
def psErasurePlanGroupRecursion (environment : PsEnvironment) (scope : PsErasureScope)
    (view : PsEliminationRecursorApplication) : Option PsErasureGroupRecursionPlan := do
  let current ← scope.currentDefinition
  let name ← current.coreName
  let [workers] := scope.recursorWorkerGroups.filter
    (fun group => group.workers.any (fun worker => psNameEq worker.name name)) | none
  let worker ← workers.workers.find? (fun worker => psNameEq worker.name name)
  if !psNameEq (psRecursorWorkerRecursorName worker) view.slot.recursorName ||
      !psNameEq worker.family view.slot.family.name || !view.suffix.isEmpty then none else do
    let some (.definitionDecl _ levels _ value) := psEnvironmentFind environment name | none
    let arguments := current.coreParametersRev.reverse
    if arguments.length != workers.captureCount + view.info.numIndices + 1 then none else do
      let original ← psRecursorWorkerBetaApply value arguments
      if !psExprAlphaEq original
          (psReduceApply view.head (view.fixedArgs ++ view.indices ++ [view.major])) then none
      else return {
        workers, captures := arguments.take workers.captureCount
        levels := levels.map PsLevel.param
        application := view
      }

-- A constructor's canonical field edge chooses the worker. The child's actual
-- instantiated type must then agree with that slot, including fixed container
-- parameters; a base name such as List is never a sufficient dispatch key.
def psErasureGroupRecursiveCoreCall (environment : PsEnvironment)
    (scope : PsErasureScope) (plan : PsErasureGroupRecursionPlan)
    (child : PsExpr) (target : PsName) : Except PsErasureError PsExpr := do
  let some (_, slot) := psInductiveEliminationSlotFor plan.application.plan target
    | throw .unsupportedRuntimeTerm
  let some worker := plan.workers.workers.find?
      (fun worker => psNameEq (psRecursorWorkerRecursorName worker) target)
    | throw .unsupportedRuntimeTerm
  let .constE _ recursorLevels := plan.application.head | throw .unsupportedRuntimeTerm
  let some levels := psInductiveEliminationFamilyLevels plan.application.plan
      plan.application.info recursorLevels | throw .unsupportedRuntimeTerm
  let type ← (psInferType environment psMetaEmpty scope.localContext child).mapError
    (fun _ => PsErasureError.unsupportedRuntimeTerm)
  let reduce := psWhnf environment psMetaEmpty scope.localContext
  let some indices := psInductiveEliminationIndicesAt (psReduceEliminationEqual reduce)
      plan.application.plan slot levels
      (plan.application.fixedArgs.take plan.application.info.numParams) (reduce type)
    | throw .unsupportedRuntimeTerm
  -- Reuse ordinary checked declaration-call erasure for type arguments,
  -- erased indices, proof slots and the target worker's distinct return type.
  -- No runtime slot or cross-family call signature is guessed here.
  return psReduceApply (.constE worker.name plan.levels) (plan.captures ++ indices ++ [child])

def psErasureDispatchRecursiveCoreCall (environment : PsEnvironment)
    (scope : PsErasureScope) (plan : PsErasureRecursionDispatch) (child : PsExpr)
    (target : Option PsName := none) : Except PsErasureError PsExpr := do
  let type ← (psInferType environment psMetaEmpty scope.localContext child).mapError
    (fun _ => PsErasureError.unsupportedRuntimeTerm)
  let call := fun scope child => match plan with
    | .singleton plan => psErasureRecursiveCoreCall environment scope plan child
    | .group plan => do
      let some target := target | throw .unsupportedRuntimeTerm
      psErasureGroupRecursiveCoreCall environment scope plan child target
  psErasureRecursiveFieldHypothesis 4096 environment call scope child type

def psErasureDispatchRecursiveCall (environment : PsEnvironment)
    (eraseAt : PsErasureScope → PsExpr → Except PsErasureError PsVerifiedIrExpr)
    (scope : PsErasureScope) (plan : PsErasureRecursionDispatch) (childName : String)
    (expected : PsExpr) (target : Option PsName := none) :
    Except PsErasureError PsVerifiedIrExpr := do
  let some (id, _) := scope.runtimeLocals.find? (fun entry => entry.2 == childName)
    | throw .binderMismatch
  let hypothesis ← psErasureDispatchRecursiveCoreCall environment scope plan (.fvar id) target
  let actual ← (psInferType environment psMetaEmpty scope.localContext hypothesis).mapError
    (fun _ => PsErasureError.unsupportedRuntimeTerm)
  if !psDefEqReadOnlyWithEnv environment psMetaEmpty scope.localContext actual expected then
    throw .binderMismatch
  eraseAt { scope with currentDefinition := none } hypothesis
