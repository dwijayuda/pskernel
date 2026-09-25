import Ps.BackendWasm.Model

def psWasmWordValueType (profile : PsWasmTargetProfile) : PsWasmValueType :=
  match profile.wordSize with
  | .wasm32 => .i32
  | .wasm64 => .i64

def psWasmValueTypeOfPrimitive
    (profile : PsWasmTargetProfile)
    (type : PsVerifiedIrPrimitiveType) : PsWasmValueType :=
  match type with
  | .nat => .refT "ProofScript.Nat"
  | .int => .refT "ProofScript.Int"
  | .uint8 => .i32
  | .uint16 => .i32
  | .uint32 => .i32
  | .uint64 => .i64
  | .usize => psWasmWordValueType profile
  | .int8 => .i32
  | .int16 => .i32
  | .int32 => .i32
  | .int64 => .i64
  | .isize => psWasmWordValueType profile
  | .float => .f64
  | .float32 => .f32
  | .bool => .i32
  | .char => .i32
  | .string => .refT "ProofScript.String"
  | .unit => .noValue

def psWasmStorageTypeOfPrimitive
    (profile : PsWasmTargetProfile)
    (type : PsVerifiedIrPrimitiveType) : PsWasmStorageType :=
  match type with
  | .uint8 => .packedI8
  | .int8 => .packedI8
  | .uint16 => .packedI16
  | .int16 => .packedI16
  | other => .value (psWasmValueTypeOfPrimitive profile other)

def psWasmLowerPrimitive
    (profile : PsWasmTargetProfile)
    (type : PsVerifiedIrPrimitiveType) : PsWasmLoweredType :=
  {
    valueType := psWasmValueTypeOfPrimitive profile type
    storageType := psWasmStorageTypeOfPrimitive profile type
  }


def psWasmValueTypeOfIrType?
    (profile : PsWasmTargetProfile) :
    PsVerifiedIrType -> Option PsWasmValueType
  | .primitive primitive =>
      match psWasmValueTypeOfPrimitive profile primitive with
      | .noValue => none
      | valueType => some valueType
  | .named name [] => some (.refT name)
  | _ => none

def psWasmStorageTypeOfIrType?
    (profile : PsWasmTargetProfile) :
    PsVerifiedIrType -> Option PsWasmStorageType
  | .primitive primitive =>
      match psWasmValueTypeOfPrimitive profile primitive with
      | .noValue => none
      | _ => some (psWasmStorageTypeOfPrimitive profile primitive)
  | .named name [] => some (.value (.refT name))
  | _ => none
