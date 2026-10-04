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
      | .named name arguments =>
          let argumentKeys :=
            arguments.map (psWasmIrTypeKeyWithFuel fuel)
          match psWasmJoinTypeKeys argumentKeys with
          | none => none
          | some "" => some ("N{" ++ name ++ "}")
          | some keys =>
              some ("N{" ++ name ++ "}<" ++ keys ++ ">")
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
  | .wasm32 => PsWasmValueType.i32
  | .wasm64 => PsWasmValueType.i64

def psWasmValueTypeOfPrimitive
    (profile : PsWasmTargetProfile)
    (type : PsVerifiedIrPrimitiveType) : PsWasmValueType :=
  match type with
  | .nat => PsWasmValueType.refT "ProofScript.Nat"
  | .int => PsWasmValueType.refT "ProofScript.Int"
  | .uint8 => PsWasmValueType.i32
  | .uint16 => PsWasmValueType.i32
  | .uint32 => PsWasmValueType.i32
  | .uint64 => PsWasmValueType.i64
  | .usize => psWasmWordValueType profile
  | .int8 => PsWasmValueType.i32
  | .int16 => PsWasmValueType.i32
  | .int32 => PsWasmValueType.i32
  | .int64 => PsWasmValueType.i64
  | .isize => psWasmWordValueType profile
  | .float => PsWasmValueType.f64
  | .float32 => PsWasmValueType.f32
  | .bool => PsWasmValueType.i32
  | .char => PsWasmValueType.i32
  | .string => PsWasmValueType.refT "ProofScript.String"
  | .unit => PsWasmValueType.noValue

def psWasmStorageTypeOfPrimitive
    (profile : PsWasmTargetProfile)
    (type : PsVerifiedIrPrimitiveType) : PsWasmStorageType :=
  match type with
  | .uint8 => PsWasmStorageType.packedI8
  | .int8 => PsWasmStorageType.packedI8
  | .uint16 => PsWasmStorageType.packedI16
  | .int16 => PsWasmStorageType.packedI16
  | other => PsWasmStorageType.value (psWasmValueTypeOfPrimitive profile other)

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
