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
  majorParameter : Nat
  indexParameters : List (Nat × Nat)

def psErasureFindStringIndex (target : String) (values : List String) (index : Nat) : Option Nat :=
  match values with
  | [] => none
  | value :: rest => if value == target then some index
    else psErasureFindStringIndex target rest (index + 1)

def psErasureRecursionParameter (scope : PsErasureScope) (expr : PsExpr) : Option (Nat × Nat) := do
  let some current := scope.currentDefinition | none
  let .fvar id := expr | none
  let name ← psErasureLookupNat scope.runtimeLocals id
  let position ← psErasureFindStringIndex name current.runtimeParameters 0
  return (id, position)

def psErasurePlanRecursion (scope : PsErasureScope) (family : PsName)
    (numParams : Nat) (major : PsExpr) (indices minors : List PsExpr) :
    Option PsErasureRecursionPlan := do
  let _ ← psRecursorVaryingLocals major indices minors
  let (_, majorParameter) ← psErasureRecursionParameter scope major
  let positions ← (indices.zipIdx).mapM fun entry => do
    let (id, parameter) ← psErasureRecursionParameter scope entry.fst
    return (id, parameter, entry.snd)
  return {
    family := family
    numParams := numParams
    numIndices := indices.length
    majorParameter := majorParameter
    indexParameters := positions.map (fun entry => entry.snd) }

def psErasureRecursiveCall (environment : PsEnvironment)
    (eraseAt : PsErasureScope -> PsExpr -> Except PsErasureError PsVerifiedIrExpr)
    (scope : PsErasureScope) (plan : PsErasureRecursionPlan) (childName : String) :
    Except PsErasureError PsVerifiedIrExpr := do
  let some current := scope.currentDefinition | throw .unsupportedRuntimeTerm
  let some child := scope.runtimeLocals.find? (fun entry => entry.snd == childName)
    | throw .binderMismatch
  let some declaration := psLocalFindById scope.localContext child.fst | throw .binderMismatch
  let view := psErasureAppView (psWhnf environment psMetaEmpty scope.localContext
    (psLocalDeclType declaration))
  let .constE family _ := view.head | throw .unsupportedRuntimeTerm
  if !psNameEq family plan.family || view.args.length != plan.numParams + plan.numIndices then
    throw .unsupportedRuntimeTerm
  let indices := view.args.drop plan.numParams
  let replacements ← plan.indexParameters.mapM fun entry => do
    let some index := indices[entry.snd]? | throw .unsupportedRuntimeTerm
    let value ← eraseAt { scope with currentDefinition := none } index
    return (entry.fst, value)
  let replacements := (plan.majorParameter, PsVerifiedIrExpr.var childName) :: replacements
  let arguments := current.runtimeParameters.zipIdx |>.map fun entry =>
    match replacements.find? (fun replacement => replacement.fst == entry.snd) with
    | some replacement => replacement.snd
    | none => .var entry.fst
  return .call (.var current.name) current.typeArgumentsRev.reverse arguments

structure PsErasureGroupRecursionPlan where
  workers : PsRecursorWorkerGroup
  captures : List PsExpr
  levels : List PsLevel

inductive PsErasureRecursionDispatch where
  | singleton (plan : PsErasureRecursionPlan)
  | group (plan : PsErasureGroupRecursionPlan)

-- Only the exact root equation of a validated worker may dispatch its IHs.
-- A nested fold or changed capture cannot reuse a caller merely because its
-- major happens to have the same family. The raw entry telescope is retained.
def psErasurePlanGroupRecursion (environment : PsEnvironment) (scope : PsErasureScope)
    (view : PsGroupRecursorApplication) : Option PsErasureGroupRecursionPlan := do
  let current ← scope.currentDefinition
  let name ← current.coreName
  let [workers] := scope.recursorWorkerGroups.filter
    (fun group => group.workers.any (fun worker => psNameEq worker.name name)) | none
  let worker ← workers.workers.find? (fun worker => psNameEq worker.name name)
  if !psNameEq worker.family view.family.name || !view.suffix.isEmpty then none else do
    let some (.definitionDecl _ levels _ value) := psEnvironmentFind environment name | none
    let arguments := current.coreParametersRev.reverse
    if arguments.length != workers.captureCount + view.info.numIndices + 1 then none else do
      let original ← psRecursorWorkerBetaApply value arguments
      if !psExprAlphaEq original
          (psReduceApply view.head (view.fixedArgs ++ view.indices ++ [view.major])) then none
      else return {
        workers, captures := arguments.take workers.captureCount
        levels := levels.map PsLevel.param
      }

def psErasureGroupRecursiveCall (environment : PsEnvironment)
    (eraseAt : PsErasureScope → PsExpr → Except PsErasureError PsVerifiedIrExpr)
    (scope : PsErasureScope) (plan : PsErasureGroupRecursionPlan) (childName : String) :
    Except PsErasureError PsVerifiedIrExpr := do
  let some child := scope.runtimeLocals.find? (fun entry => entry.2 == childName)
    | throw .binderMismatch
  let some declaration := psLocalFindById scope.localContext child.1 | throw .binderMismatch
  let view := psReduceAppView (psWhnf environment psMetaEmpty scope.localContext
    (psLocalDeclType declaration))
  let .constE owner _ := view.head | throw .unsupportedRuntimeTerm
  let some worker := plan.workers.workers.find? (fun worker => psNameEq worker.family owner)
    | throw .unsupportedRuntimeTerm
  let some family := psEnvironmentFindInductive environment owner | throw .unsupportedRuntimeTerm
  if view.args.length != family.numParams + family.numIndices then throw .unsupportedRuntimeTerm
  -- Reuse ordinary checked declaration-call erasure for type arguments,
  -- erased indices, proof slots and the target worker's distinct return type.
  -- No runtime slot or cross-family call signature is guessed here.
  let call := psReduceApply (.constE worker.name plan.levels)
    (plan.captures ++ view.args.drop family.numParams ++ [.fvar child.1])
  eraseAt { scope with currentDefinition := none } call

def psErasureDispatchRecursiveCall (environment : PsEnvironment)
    (eraseAt : PsErasureScope → PsExpr → Except PsErasureError PsVerifiedIrExpr)
    (scope : PsErasureScope) (plan : PsErasureRecursionDispatch) (childName : String) :
    Except PsErasureError PsVerifiedIrExpr :=
  match plan with
  | .singleton plan => psErasureRecursiveCall environment eraseAt scope plan childName
  | .group plan => psErasureGroupRecursiveCall environment eraseAt scope plan childName

