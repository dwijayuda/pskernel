import Ps.BackendWasm.Model

def psWasmJoinTypeKeys :
    List (Option String) -> Option String
  | [] => some ""
  | key :: rest =>
      match key with
      | none => none
      | some head =>
          match psWasmJoinTypeKeys rest with
          | none => none
          | some tail =>
              if tail == "" then
                some head
              else
                some (head ++ "," ++ tail)

def psWasmIrTypeKeyWithFuel :
    Nat -> PsVerifiedIrType -> Option String
  | 0, _ => none
  | fuel + 1, type =>
      match type with
      | .unknown => none
      | .typeParameter _ => none
      | .primitive primitive =>
          some
            (match primitive with
            | .nat => "Nat"
            | .int => "Int"
            | .uint8 => "U8"
            | .uint16 => "U16"
            | .uint32 => "U32"
            | .uint64 => "U64"
            | .usize => "USize"
            | .int8 => "I8"
            | .int16 => "I16"
            | .int32 => "I32"
            | .int64 => "I64"
            | .isize => "ISize"
            | .float => "F64"
            | .float32 => "F32"
            | .bool => "Bool"
            | .char => "Char"
            | .string => "String"
            | .unit => "Unit")
      | .named name [] => some ("N{" ++ name ++ "}")
      | .named _ (_ :: _) => none
      | .function parameters result =>
          let parameterKeys :=
            parameters.map (psWasmIrTypeKeyWithFuel fuel)
          match psWasmJoinTypeKeys parameterKeys with
          | none => none
          | some parameterKey =>
              match psWasmIrTypeKeyWithFuel fuel result with
              | none => none
              | some resultKey =>
                  some ("Fn{" ++ parameterKey ++ "}->{" ++ resultKey ++ "}")

def psWasmIrTypeKey
    (type : PsVerifiedIrType) : Option String :=
  psWasmIrTypeKeyWithFuel 64 type

def psWasmClosureBaseName
    (type : PsVerifiedIrType) : Option String :=
  match type with
  | .function _ _ =>
      match psWasmIrTypeKey type with
      | none => none
      | some key => some ("ProofScript.Closure$" ++ key)
  | _ => none

def psWasmClosureCodeTypeName
    (type : PsVerifiedIrType) : Option String :=
  match type with
  | .function _ _ =>
      match psWasmIrTypeKey type with
      | none => none
      | some key => some ("ProofScript.ClosureCode$" ++ key)
  | _ => none

def psWasmArrayTypeName
    (elementType : PsVerifiedIrType) : Option String :=
  match psWasmIrTypeKey elementType with
  | none => none
  | some key => some ("ProofScript.Array$" ++ key)

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
  | .named "Array" [elementType] =>
      match psWasmArrayTypeName elementType with
      | none => none
      | some name => some (.refT name)
  | .named name [] => some (.refT name)
  | .function parameters result =>
      match
          psWasmClosureBaseName
            (PsVerifiedIrType.function parameters result) with
      | none => none
      | some name => some (.refT name)
  | _ => none

def psWasmStorageTypeOfIrType?
    (profile : PsWasmTargetProfile) :
    PsVerifiedIrType -> Option PsWasmStorageType
  | .primitive primitive =>
      match psWasmValueTypeOfPrimitive profile primitive with
      | .noValue => none
      | _ => some (psWasmStorageTypeOfPrimitive profile primitive)
  | .named "Array" [elementType] =>
      match psWasmArrayTypeName elementType with
      | none => none
      | some name => some (.value (.refT name))
  | .named name [] => some (.value (.refT name))
  | .function parameters result =>
      match
          psWasmClosureBaseName
            (PsVerifiedIrType.function parameters result) with
      | none => none
      | some name => some (.value (.refT name))
  | _ => none
