import Ps.Erasure.Basic

-- Float is primitive; its proof-bearing logical Model remains an ordinary
-- prepared record. Never erase a model invariant into a foreign constructor.
def psErasureFloatWidth (name : PsName) : Option PsVerifiedIrFloatingType :=
  match psNameToString name with
  | "Float" => some .float | "Float32" => some .float32 | _ => none

def psErasureFloatModel (width : PsVerifiedIrFloatingType) : PsName :=
  psNameAppendStr (psRootName (match width with | .float => "Float" | .float32 => "Float32")) "Model"

def psEraseFloatProjection (scope : PsErasureScope) (width : PsVerifiedIrFloatingType)
    (value : PsVerifiedIrExpr) : Except PsErasureError PsVerifiedIrExpr := do
  let (model, field) ← psErasureSingleRuntimeField scope (psErasureFloatModel width)
  return .record model.name [] [(field.name, .intrinsic (.floatToBits width) [] [value])]

def psErasureFloatEntryArity (name : PsName) : Option Nat :=
  match name with
  | .str owner method =>
    if (psErasureFloatWidth owner).isSome &&
        ["ofBits", "toBits", "ofModel", "toModel"].contains method then some 1
    else if psNameToString owner == "PsV7Native.FloatCanonical" &&
        ["fromBits64", "fromBits32"].contains method then some 1
    else none
  | _ => none

def psEraseFloatApplication (scope : PsErasureScope)
    (erase : PsExpr → Except PsErasureError PsVerifiedIrExpr) (view : PsErasureAppView) :
    Except PsErasureError (Option PsVerifiedIrExpr) := do
  let .constE (.str owner method) _ := view.head | return none
  let constructor := psNameToString owner == "PsV7Native.FloatCanonical"
  let width := if constructor then
    match method with | "fromBits64" => some .float | "fromBits32" => some .float32 | _ => none
    else psErasureFloatWidth owner
  let some width := width | return none
  if !(psErasureFloatEntryArity (.str owner method)).isSome then return none
  let [value] := view.args | throw .unsupportedApplication
  let value ← erase value
  if constructor || method == "ofBits" then
    return some (.intrinsic (.floatOfBits width) [] [value])
  else if method == "toBits" then
    return some (.intrinsic (.floatToBits width) [] [value])
  else if method == "toModel" then
    return some (← psEraseFloatProjection scope width value)
  else
    let (model, field) ← psErasureSingleRuntimeField scope (psErasureFloatModel width)
    return some (.intrinsic (.floatOfBits width) [] [.projection model.name [] value field.name])
