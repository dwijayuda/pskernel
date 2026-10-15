import Ps.Erasure.FloatRuntime

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

-- The descriptor owns arity and operand/result representation. In particular,
-- integer/scientific Model constructors do not unwrap their integer arguments.
inductive PsErasureFloatOperation where
  | ofBits | toBits | ofModel | toModel
  | binary (op : PsVerifiedIrFloatBinaryOp)
  | unary (op : PsVerifiedIrFloatUnaryOp)
  | test (op : PsVerifiedIrFloatTestOp)
  | compare (op : PsVerifiedIrFloatCompareOp)
  | logicalEq | nan | inf | ofNat | ofInt | scientific
  | ofWord (word : PsVerifiedIrMachineIntegerType)
  | toWord (word : PsVerifiedIrMachineIntegerType)

def psErasureFloatWord : String → Option PsVerifiedIrMachineIntegerType
  | "UInt8" => some .uint8 | "UInt16" => some .uint16
  | "UInt32" => some .uint32 | "UInt64" => some .uint64
  | "Int8" => some .int8 | "Int16" => some .int16
  | "Int32" => some .int32 | "Int64" => some .int64 | _ => none

-- Exact native identities only; neither suffixes nor arbitrary user definitions
-- gain a primitive contract. USize/ISize and opaque cross-width Float conversions
-- are deliberately outside this fixed-width logical family.
def psErasureFloatEntry (name : PsName) :
    Option (PsVerifiedIrFloatingType × Bool × PsErasureFloatOperation) := do
  let text := psNameToString name
  if ["instDecidableEqFloat", "instDecidableEqFloat.decEq"].contains text then
    return (.float, false, .logicalEq)
  if ["instDecidableEqFloat32", "instDecidableEqFloat32.decEq"].contains text then
    return (.float32, false, .logicalEq)
  if ["Float.instDecidableEqModel", "Float.instDecidableEqModel.decEq"].contains text then
    return (.float, true, .logicalEq)
  if ["Float32.instDecidableEqModel", "Float32.instDecidableEqModel.decEq"].contains text then
    return (.float32, true, .logicalEq)
  let .str owner method := name | none
  let ownerText := psNameToString owner
  if ownerText == "PsV7Native.FloatCanonical" then
    match method with
    | "fromBits64" => return (.float, false, .ofBits)
    | "fromBits32" => return (.float32, false, .ofBits)
    | _ => none
  else if method == "toFloat" || method == "toFloat32" then
    let width := if method == "toFloat" then PsVerifiedIrFloatingType.float else .float32
    match ownerText with
    | "Nat" => return (width, false, .ofNat)
    | "Int" => return (width, false, .ofInt)
    | _ => return (width, false, .ofWord (← psErasureFloatWord ownerText))
  else
    let (width, model) ← match ownerText with
      | "Float" => some (.float, false) | "Float32" => some (.float32, false)
      | "Float.Model" => some (.float, true) | "Float32.Model" => some (.float32, true)
      | _ => none
    let operation ← match method with
      | "add" => some (.binary .add) | "sub" => some (.binary .sub)
      | "mul" => some (.binary .mul) | "div" => some (.binary .div)
      | "neg" => some (.unary .neg) | "abs" => some (.unary .abs)
      | "beq" => some (.compare .eq) | "lt" => some (.compare .lt) | "le" => some (.compare .le)
      | "isNaN" => some (.test .isNaN) | "isInf" => some (.test .isInf) | "isFinite" => some (.test .isFinite)
      | "nan" => some .nan | "inf" => some .inf
      | "ofNat" => if model then none else some .ofNat
      | "ofInt" => if model then none else some .ofInt
      | "ofScientific" => some .scientific
      | "ofBits" => if model then none else some .ofBits
      | "toBits" => if model then none else some .toBits
      | "ofModel" => if model then none else some .ofModel
      | "toModel" => if model then none else some .toModel
      | "decLt" => if model then none else some (.compare .lt)
      | "decLe" => if model then none else some (.compare .le)
      | _ =>
        if method.startsWith "to" then
          (psErasureFloatWord (method.drop 2).toString).map PsErasureFloatOperation.toWord
        else if model && method.startsWith "of" then
          (psErasureFloatWord (method.drop 2).toString).map PsErasureFloatOperation.ofWord
        else none
    return (width, model, operation)

def psErasureFloatEntryArity (name : PsName) : Option Nat := do
  let (_, model, operation) ← psErasureFloatEntry name
  return match operation with
    | .nan | .inf => 0
    | .binary _ | .compare _ | .logicalEq => 2
    | .scientific => if model then 2 else 3
    | _ => 1

def psEraseFloatApplication (scope : PsErasureScope)
    (erase : PsExpr → Except PsErasureError PsVerifiedIrExpr) (view : PsErasureAppView) :
    Except PsErasureError (Option PsVerifiedIrExpr) := do
  let .constE name _ := view.head | return none
  let some (width, model, operation) := psErasureFloatEntry name | return none
  let args ← view.args.mapM erase
  let floatingInput := match operation with
    | .binary _ | .unary _ | .test _ | .compare _ | .logicalEq | .toWord _ => true
    | _ => false
  let args ← if model && floatingInput then args.mapM (psEraseFloatFromModel scope width) else pure args
  let (result, floating) : PsVerifiedIrExpr × Bool ← match operation, args with
    | .ofModel, [value] => pure (← psEraseFloatFromModel scope width value, true)
    | .toModel, [value] => pure (← psEraseFloatProjection scope width value, false)
    | .ofBits, [value] => pure (.intrinsic (.floatOfBits width) [] [value], true)
    | .toBits, [value] => pure (.intrinsic (.floatToBits width) [] [value], false)
    | .binary op, [a,b] => pure (.intrinsic (.floatBinary width op) [] [a,b], true)
    | .unary op, [value] => pure (.intrinsic (.floatUnary width op) [] [value], true)
    | .test op, [value] => pure (.intrinsic (.floatTest width op) [] [value], false)
    | .compare op, [a,b] => pure (.intrinsic (.floatCompare width op) [] [a,b], false)
    | .ofWord word, [value] => pure (.intrinsic (.floatOfWord width word) [] [value], true)
    | .toWord word, [value] => pure (.intrinsic (.floatToWord width word) [] [value], false)
    | .ofNat, [value] => pure (← PsFloatRuntime.call scope width "natural" [value], true)
    | .ofInt, [value] => pure (← PsFloatRuntime.call scope width "integer" [value], true)
    | .scientific, _ =>
        if args.length != (if model then 2 else 3) then throw .unsupportedApplication
        pure (← PsFloatRuntime.call scope width (if model then "model_scientific" else "scientific") args, true)
    | .logicalEq, [a,b] =>
        let word := match width with | .float => PsVerifiedIrMachineIntegerType.uint64 | .float32 => .uint32
        pure (.intrinsic (.machineIntCompare word .eq) []
          [.intrinsic (.floatToBits width) [] [a], .intrinsic (.floatToBits width) [] [b]], false)
    | .nan, [] | .inf, [] =>
        let nan := match operation with | .nan => true | _ => false
        let (word, bits) : PsVerifiedIrMachineIntegerType × Int := match width with
          | .float => (.uint64, if nan then 9221120237041090560 else 9218868437227405312)
          | .float32 => (.uint32, if nan then 2143289344 else 2139095040)
        pure (.intrinsic (.floatOfBits width) [] [.literal (.machineInteger word bits)], true)
    | _, _ => throw .unsupportedApplication
  return some (← if model && floating then psEraseFloatProjection scope width result else pure result)
