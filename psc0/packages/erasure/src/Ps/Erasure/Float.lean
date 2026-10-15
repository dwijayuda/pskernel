import Ps.Erasure.Basic

-- Primitive Float and proof-bearing Model share one typed runtime boundary.
-- Model remains an ordinary prepared record; its validity proof erases.
def psErasureFloatWidth (name : PsName) : Option PsVerifiedIrFloatingType :=
  match psNameToString name with
  | "Float" => some .float | "Float32" => some .float32 | _ => none

def psErasureFloatModel (width : PsVerifiedIrFloatingType) : PsName :=
  psNameAppendStr (psRootName (match width with | .float => "Float" | .float32 => "Float32")) "Model"

def psEraseFloatProjection (scope : PsErasureScope) (width : PsVerifiedIrFloatingType)
    (value : PsVerifiedIrExpr) : Except PsErasureError PsVerifiedIrExpr := do
  let (model, field) ← psErasureSingleRuntimeField scope (psErasureFloatModel width)
  return .record model.name [] [(field.name, .intrinsic (.floatToBits width) [] [value])]

def psEraseFloatFromModel (scope : PsErasureScope) (width : PsVerifiedIrFloatingType)
    (value : PsVerifiedIrExpr) : Except PsErasureError PsVerifiedIrExpr := do
  let (model, field) ← psErasureSingleRuntimeField scope (psErasureFloatModel width)
  return .intrinsic (.floatOfBits width) [] [.projection model.name [] value field.name]

-- Exact selected names only. In particular, an arbitrary user definition in
-- a Float namespace must not acquire intrinsic semantics from its suffix.
def psErasureFloatEntry (name : PsName) :
    Option (PsVerifiedIrFloatingType × Bool × String) := do
  let text := psNameToString name
  if ["instDecidableEqFloat", "instDecidableEqFloat.decEq"].contains text then
    return (.float, false, "logicalEq")
  if ["instDecidableEqFloat32", "instDecidableEqFloat32.decEq"].contains text then
    return (.float32, false, "logicalEq")
  if ["Float.instDecidableEqModel", "Float.instDecidableEqModel.decEq"].contains text then
    return (.float, true, "logicalEq")
  if ["Float32.instDecidableEqModel", "Float32.instDecidableEqModel.decEq"].contains text then
    return (.float32, true, "logicalEq")
  let .str owner method := name | none
  if psNameToString owner == "PsV7Native.FloatCanonical" then
    match method with
    | "fromBits64" => return (.float, false, "ofBits")
    | "fromBits32" => return (.float32, false, "ofBits")
    | _ => none
  else
    let (width, model) ← match psNameToString owner with
      | "Float" => some (.float, false) | "Float32" => some (.float32, false)
      | "Float.Model" => some (.float, true) | "Float32.Model" => some (.float32, true)
      | _ => none
    if ["add", "sub", "mul", "div", "neg", "abs", "beq", "lt", "le",
        "isNaN", "isInf", "isFinite", "nan", "inf"].contains method ||
        (!model && ["ofBits", "toBits", "ofModel", "toModel", "decLt", "decLe"].contains method) then
      return (width, model, method)
    else none

def psErasureFloatEntryArity (name : PsName) : Option Nat := do
  let (_, _, method) ← psErasureFloatEntry name
  if ["nan", "inf"].contains method then some 0
  else if ["add", "sub", "mul", "div", "beq", "lt", "le", "decLt", "decLe",
      "logicalEq"].contains method then some 2
  else some 1

def psEraseFloatApplication (scope : PsErasureScope)
    (erase : PsExpr → Except PsErasureError PsVerifiedIrExpr) (view : PsErasureAppView) :
    Except PsErasureError (Option PsVerifiedIrExpr) := do
  let .constE name _ := view.head | return none
  let some (width, model, method) := psErasureFloatEntry name | return none
  let args ← view.args.mapM erase
  if method == "ofModel" then
    let [value] := args | throw .unsupportedApplication
    return some (← psEraseFloatFromModel scope width value)
  if method == "toModel" then
    let [value] := args | throw .unsupportedApplication
    return some (← psEraseFloatProjection scope width value)
  let args ← if model then args.mapM (psEraseFloatFromModel scope width) else pure args
  let binary : PsVerifiedIrFloatBinaryOp := match method with
    | "sub" => .sub | "mul" => .mul | "div" => .div | _ => .add
  let comparison : PsVerifiedIrFloatCompareOp := match method with
    | "lt" | "decLt" => .lt | "le" | "decLe" => .le | _ => .eq
  let (result, floating) : PsVerifiedIrExpr × Bool ← match method, args with
    | "ofBits", [value] => pure (.intrinsic (.floatOfBits width) [] [value], true)
    | "toBits", [value] => pure (.intrinsic (.floatToBits width) [] [value], false)
    | "add", [a,b] | "sub", [a,b] | "mul", [a,b] | "div", [a,b] =>
        pure (.intrinsic (.floatBinary width binary) [] [a,b], true)
    | "neg", [value] => pure (.intrinsic (.floatUnary width .neg) [] [value], true)
    | "abs", [value] => pure (.intrinsic (.floatUnary width .abs) [] [value], true)
    | "beq", [a,b] | "lt", [a,b] | "le", [a,b] | "decLt", [a,b] | "decLe", [a,b] =>
        pure (.intrinsic (.floatCompare width comparison) [] [a,b], false)
    | "logicalEq", [a,b] =>
        let word := match width with | .float => PsVerifiedIrMachineIntegerType.uint64 | .float32 => .uint32
        pure (.intrinsic (.machineIntCompare word .eq) []
          [.intrinsic (.floatToBits width) [] [a], .intrinsic (.floatToBits width) [] [b]], false)
    | "isNaN", [value] => pure (.intrinsic (.floatTest width .isNaN) [] [value], false)
    | "isInf", [value] => pure (.intrinsic (.floatTest width .isInf) [] [value], false)
    | "isFinite", [value] => pure (.intrinsic (.floatTest width .isFinite) [] [value], false)
    | "nan", [] | "inf", [] =>
        let (word, bits) : PsVerifiedIrMachineIntegerType × Int := match width with
          | .float => (.uint64, if method == "nan" then 9221120237041090560 else 9218868437227405312)
          | .float32 => (.uint32, if method == "nan" then 2143289344 else 2139095040)
        pure (.intrinsic (.floatOfBits width) [] [.literal (.machineInteger word bits)], true)
    | _, _ => throw .unsupportedApplication
  return some (← if model && floating then psEraseFloatProjection scope width result else pure result)
