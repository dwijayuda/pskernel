import Ps.Erasure.Basic

-- Lean 4.35.0 keeps UInt's checked BitVec/Fin model and assigns a primitive
-- runtime representation. Platform descriptors resolve through the request profile.
def psErasureUnsignedWidth (owner : PsName) : Option PsVerifiedIrMachineIntegerType :=
  match psNameToString owner with
  | "UInt8" => some .uint8 | "UInt16" => some .uint16
  | "UInt32" => some .uint32 | "UInt64" => some .uint64
  | "USize" => some .usize
  | _ => none

-- Native SInt/Basic.lean models a signed word as the same-width two's
-- complement UInt carrier. This selects only the separately kernel-checked
-- four portable widths and explicitly profiled ISize.
def psErasureSignedWidth (owner : PsName) : Option PsVerifiedIrMachineIntegerType :=
  match psNameToString owner with
  | "Int8" => some .int8 | "Int16" => some .int16
  | "Int32" => some .int32 | "Int64" => some .int64
  | "ISize" => some .isize
  | _ => none

def psErasureSignedUnsignedWidth :
    PsVerifiedIrMachineIntegerType → Option PsVerifiedIrMachineIntegerType
  | .int8 => some .uint8 | .int16 => some .uint16
  | .int32 => some .uint32 | .int64 => some .uint64
  | _ => none

def psErasureSignedBinary : String → Option PsVerifiedIrIntegerBinaryOp
  | "add" => some .add | "sub" => some .sub | "mul" => some .mul
  | "div" => some .div | "mod" => some .mod
  | "land" => some .bitAnd | "lor" => some .bitOr | "xor" => some .bitXor
  | "shiftLeft" => some .shiftLeft | "shiftRight" => some .shiftRight
  | _ => none

def psErasureUnsignedBinary : String → Option PsVerifiedIrIntegerBinaryOp
  | "add" => some .add | "sub" => some .sub | "mul" => some .mul
  | "div" => some .div | "mod" => some .mod
  | "land" => some .bitAnd | "lor" => some .bitOr | "xor" => some .bitXor
  | "shiftLeft" => some .shiftLeft | "shiftRight" => some .shiftRight
  | _ => none

def psErasureUnsignedEntryArity (name : PsName) : Option Nat :=
  match name with
  | .str owner method =>
    if (psErasureUnsignedWidth owner).isSome then
      match method with
      | "ofNat" | "ofBitVec" | "toNat" | "toBitVec" | "toFin" => some 1
      | "ofNatLT" => some 2
      | "neg" | "complement" => some 1
      | "add" | "sub" | "mul" | "div" | "mod" | "land" | "lor" | "xor"
      | "shiftLeft" | "shiftRight" => some 2
      | _ => none
    else if (psErasureSignedWidth owner).isSome then
      match method with
      | "ofNat" | "ofBitVec" | "toBitVec" => some 1
      | "toUInt8" | "toUInt16" | "toUInt32" | "toUInt64" | "toUSize" | "ofUSize" => some 1
      | "neg" | "complement" => some 1
      | "add" | "sub" | "mul" | "div" | "mod"
      | "land" | "lor" | "xor" | "shiftLeft" | "shiftRight" => some 2
      | _ => none
    else if psNameToString owner == "BitVec" then
      match method with
      | "ofNat" | "toNat" | "toFin" => some 2
      | "ofNatLT" => some 3
      | _ => none
    else none
  | _ => none

def psEraseBoundedWrap (scope : PsErasureScope) (value : PsVerifiedIrExpr) (bitvec : Bool) :
    Except PsErasureError PsVerifiedIrExpr := do
  let (fin, val) ← psErasureSingleRuntimeField scope (psRootName "Fin")
  let value := PsVerifiedIrExpr.record fin.name [] [(val.name, value)]
  if !bitvec then return value
  let (bits, toFin) ← psErasureSingleRuntimeField scope (psRootName "BitVec")
  return .record bits.name [] [(toFin.name, value)]

def psEraseBitVecNatural (scope : PsErasureScope) (value : PsVerifiedIrExpr) :
    Except PsErasureError PsVerifiedIrExpr := do
  let (bits, toFin) ← psErasureSingleRuntimeField scope (psRootName "BitVec")
  let (fin, val) ← psErasureSingleRuntimeField scope (psRootName "Fin")
  return .projection fin.name [] (.projection bits.name [] value toFin.name) val.name

def psEraseUnsignedProjection (scope : PsErasureScope) (width : PsVerifiedIrMachineIntegerType)
    (value : PsVerifiedIrExpr) : Except PsErasureError PsVerifiedIrExpr :=
  psEraseBoundedWrap scope (.intrinsic (.unsignedToNat width) [] [value]) true

def psEraseUnsignedApplication (scope : PsErasureScope)
    (erase : PsExpr → Except PsErasureError PsVerifiedIrExpr) (view : PsErasureAppView) :
    Except PsErasureError (Option PsVerifiedIrExpr) := do
  let .constE (.str owner method) _ := view.head | return none
  if let some width := psErasureUnsignedWidth owner then
    let width ← psErasureResolveWord scope width
    if let some operation := psErasureUnsignedBinary method then
      let [left, right] := view.args | throw .unsupportedApplication
      return some (.intrinsic (.machineIntBinary width operation) [] [← erase left, ← erase right])
    match method, view.args with
    | "neg", [value] =>
      return some (.intrinsic (.machineIntBinary width .sub) []
        [.literal (.machineInteger width 0), ← erase value])
    | "complement", [value] =>
      let some bits := psIrMachineIntegerFixedWidth width | throw .unsupportedRuntimeTerm
      return some (.intrinsic (.machineIntBinary width .bitXor) []
        [← erase value, .literal (.machineInteger width (Int.ofNat (2 ^ bits - 1)))])
    | "ofNat", [value] | "ofNatLT", [value, _] =>
      return some (.intrinsic (.unsignedOfNat width) [] [← erase value])
    | "ofBitVec", [value] =>
      return some (.intrinsic (.unsignedOfNat width) [] [← psEraseBitVecNatural scope (← erase value)])
    | "toNat", [value] =>
      return some (.intrinsic (.unsignedToNat width) [] [← erase value])
    | "toBitVec", [value] =>
      return some (← psEraseUnsignedProjection scope width (← erase value))
    | "toFin", [value] =>
      return some (← psEraseBoundedWrap scope (.intrinsic (.unsignedToNat width) [] [← erase value]) false)
    | _, _ => return none
  else if let some width := psErasureSignedWidth owner then
    let width ← psErasureResolveWord scope width
    let some unsignedWidth := psErasureSignedUnsignedWidth width
      | throw .unsupportedRuntimeTerm
    let unsignedProjection := match width with
      | .int8 => "toUInt8" | .int16 => "toUInt16"
      | .int32 => "toUInt32" | .int64 => "toUInt64"
      | _ => ""
    if method == unsignedProjection || (psNameToString owner == "ISize" && method == "toUSize") then
      let [value] := view.args | throw .unsupportedApplication
      return some (.intrinsic (.signedToUnsigned width) [] [← erase value])
    if let some operation := psErasureSignedBinary method then
      let [left, right] := view.args | throw .unsupportedApplication
      return some (.intrinsic (.machineIntBinary width operation) []
        [← erase left, ← erase right])
    match method, view.args with
    | "ofNat", [value] =>
      return some (.intrinsic (.signedOfNat width) [] [← erase value])
    | "ofUSize", [value] =>
      return some (.intrinsic (.signedOfNat width) []
        [.intrinsic (.unsignedToNat unsignedWidth) [] [← erase value]])
    | "toBitVec", [value] =>
      let unsigned := PsVerifiedIrExpr.intrinsic (.signedToUnsigned width) [] [← erase value]
      return some (← psEraseUnsignedProjection scope unsignedWidth unsigned)
    | "ofBitVec", [value] =>
      return some (.intrinsic (.signedOfNat width) []
        [← psEraseBitVecNatural scope (← erase value)])
    | "neg", [value] =>
      return some (.intrinsic (.machineIntBinary width .sub) []
        [.literal (.machineInteger width 0), ← erase value])
    | "complement", [value] =>
      return some (.intrinsic (.machineIntBinary width .bitXor) []
        [← erase value, .literal (.machineInteger width (-1))])
    | _, _ => return none
  else if psNameToString owner == "BitVec" then
    match method, view.args with
    | "ofNat", [width, value] =>
      let modulus := PsVerifiedIrExpr.intrinsic .natPow [] [.literal (.natural 2), ← erase width]
      return some (← psEraseBoundedWrap scope (.intrinsic .natMod [] [← erase value, modulus]) true)
    | "ofNatLT", [_, value, _] => return some (← psEraseBoundedWrap scope (← erase value) true)
    | "toNat", [_, value] => return some (← psEraseBitVecNatural scope (← erase value))
    | "toFin", [_, value] =>
      let (bits, field) ← psErasureSingleRuntimeField scope (psRootName "BitVec")
      return some (.projection bits.name [] (← erase value) field.name)
    | _, _ => return none
  else return none
