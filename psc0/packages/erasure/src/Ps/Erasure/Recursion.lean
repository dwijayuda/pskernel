import Ps.Erasure.Basic

-- A root recursor can reuse the current function only when its varying locals
-- are absent from all minors. Otherwise a recursive call would silently change
-- captured values. Unsupported folds keep their IH erased and fail if it is used.
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
  let (majorId, majorParameter) ← psErasureRecursionParameter scope major
  let positions ← (indices.zipIdx).mapM fun entry => do
    let (id, parameter) ← psErasureRecursionParameter scope entry.fst
    return (id, parameter, entry.snd)
  let varying := majorId :: positions.map (fun entry => entry.fst)
  if varying.eraseDups.length != varying.length then none else do
    if minors.any (fun minor => varying.any (fun id =>
        !(psExprAlphaEq minor (psExprAbstractFVar id minor)))) then none else
      return { family, numParams, numIndices := indices.length, majorParameter,
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
