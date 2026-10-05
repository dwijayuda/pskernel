import Ps.BackendWasm.Model
import Ps.Foundation.Name

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
              if psStringEq tail "" then
                some head
              else
                some
                  (String.Internal.append
                    head
                    (String.Internal.append "," tail))

def psWasmMapTypeKeysWith
    (convert : PsVerifiedIrType -> Option String) :
    List PsVerifiedIrType ->
    List (Option String)
  | List.nil => List.nil
  | List.cons value rest =>
      List.cons
        (convert value)
        (psWasmMapTypeKeysWith convert rest)

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
            psWasmMapTypeKeysWith
              (psWasmIrTypeKeyWithFuel fuel)
              arguments;
          match psWasmJoinTypeKeys argumentKeys with
          | none => none
          | some "" => some
                (String.Internal.append
                  "N{"
                  (String.Internal.append name "}"))
          | some keys =>
              some
                (String.Internal.append
                  "N{"
                  (String.Internal.append
                    name
                    (String.Internal.append
                      "}<"
                      (String.Internal.append keys ">"))))
      | .function parameters result =>
          let parameterKeys :=
            psWasmMapTypeKeysWith
              (psWasmIrTypeKeyWithFuel fuel)
              parameters;
          match psWasmJoinTypeKeys parameterKeys with
          | none => none
          | some parameterKey =>
              match psWasmIrTypeKeyWithFuel fuel result with
              | none => none
              | some resultKey =>
                  some
                    (String.Internal.append
                      "Fn{"
                      (String.Internal.append
                        parameterKey
                        (String.Internal.append
                          "}->{"
                          (String.Internal.append resultKey "}"))))

def psWasmIrTypeKey
    (type : PsVerifiedIrType) : Option String :=
  psWasmIrTypeKeyWithFuel 64 type

def psWasmClosureBaseName
    (type : PsVerifiedIrType) : Option String :=
  match type with
  | .function _ _ =>
      match psWasmIrTypeKey type with
      | none => none
      | some key => some (String.Internal.append "ProofScript.Closure$" key)
  | _ => none

def psWasmClosureCodeTypeName
    (type : PsVerifiedIrType) : Option String :=
  match type with
  | .function _ _ =>
      match psWasmIrTypeKey type with
      | none => none
      | some key => some (String.Internal.append "ProofScript.ClosureCode$" key)
  | _ => none

def psWasmArrayTypeName
    (elementType : PsVerifiedIrType) : Option String :=
  match psWasmIrTypeKey elementType with
  | none => none
  | some key => some (String.Internal.append "ProofScript.Array$" key)

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
  | .named "Array" arguments =>
      match arguments with
      | List.nil => none
      | List.cons elementType rest =>
          match rest with
          | List.nil =>
              match psWasmArrayTypeName elementType with
              | none => none
              | some name =>
                  some (PsWasmValueType.refT name)
          | List.cons _ _ => none
  | .named name arguments =>
      match arguments with
      | List.nil =>
          some (PsWasmValueType.refT name)
      | List.cons _ _ => none
  | .function parameters result =>
      match
          psWasmClosureBaseName
            (PsVerifiedIrType.function parameters result) with
      | none => none
      | some name => some (PsWasmValueType.refT name)
  | _ => none

def psWasmStorageTypeOfIrType?
    (profile : PsWasmTargetProfile) :
    PsVerifiedIrType -> Option PsWasmStorageType
  | .primitive primitive =>
      match psWasmValueTypeOfPrimitive profile primitive with
      | .noValue => none
      | _ => some (psWasmStorageTypeOfPrimitive profile primitive)
  | .named "Array" arguments =>
      match arguments with
      | List.nil => none
      | List.cons elementType rest =>
          match rest with
          | List.nil =>
              match psWasmArrayTypeName elementType with
              | none => none
              | some name =>
                  some
                    (PsWasmStorageType.value
                      (PsWasmValueType.refT name))
          | List.cons _ _ => none
  | .named name arguments =>
      match arguments with
      | List.nil =>
          some
            (PsWasmStorageType.value
              (PsWasmValueType.refT name))
      | List.cons _ _ => none
  | .function parameters result =>
      match
          psWasmClosureBaseName
            (PsVerifiedIrType.function parameters result) with
      | none => none
      | some name =>
          some
            (PsWasmStorageType.value
              (PsWasmValueType.refT name))
  | _ => none