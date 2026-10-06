import Ps.BackendWasm.Model
import Ps.Foundation.Name

def psWasmJoinTypeKeys
    (keys : List (Option String)) : Option String :=
  match keys with
  | List.nil => Option.some ""
  | List.cons key rest =>
      match key with
      | Option.none => Option.none
      | Option.some head =>
          match psWasmJoinTypeKeys rest with
          | Option.none => Option.none
          | Option.some tail =>
              if psStringEq tail "" then
                Option.some head
              else
                Option.some
                  (String.Internal.append
                    head
                    (String.Internal.append "," tail))

def psWasmMapTypeKeysWith
    (convert : PsVerifiedIrType -> Option String)
    (values : List PsVerifiedIrType) :
    List (Option String) :=
  match values with
  | List.nil => List.nil
  | List.cons value rest =>
      List.cons
        (convert value)
        (psWasmMapTypeKeysWith convert rest)

def psWasmIrTypeKeyWithFuel
    (remainingFuel : Nat) :
    PsVerifiedIrType -> Option String :=
  match remainingFuel with
  | 0 =>
      fun (_type : PsVerifiedIrType) => Option.none
  | fuel + 1 =>
      let smaller : PsVerifiedIrType -> Option String :=
        psWasmIrTypeKeyWithFuel fuel;
      fun (type : PsVerifiedIrType) =>
        match type with
        | .unknown => Option.none
        | .typeParameter _ => Option.none
        | .primitive primitive =>
            match primitive with
            | .nat => Option.some "Nat"
            | .int => Option.some "Int"
            | .uint8 => Option.some "U8"
            | .uint16 => Option.some "U16"
            | .uint32 => Option.some "U32"
            | .uint64 => Option.some "U64"
            | .usize => Option.some "USize"
            | .int8 => Option.some "I8"
            | .int16 => Option.some "I16"
            | .int32 => Option.some "I32"
            | .int64 => Option.some "I64"
            | .isize => Option.some "ISize"
            | .float => Option.some "F64"
            | .float32 => Option.some "F32"
            | .bool => Option.some "Bool"
            | .char => Option.some "Char"
            | .string => Option.some "String"
            | .unit => Option.some "Unit"
        | .named name arguments =>
            let argumentKeys :=
              psWasmMapTypeKeysWith
                smaller
                arguments;
            match psWasmJoinTypeKeys argumentKeys with
            | Option.none => Option.none
            | Option.some keys =>
                if psStringEq keys "" then
                  Option.some
                    (String.Internal.append
                      "N{"
                      (String.Internal.append name "}"))
                else
                  Option.some
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
                smaller
                parameters;
            match psWasmJoinTypeKeys parameterKeys with
            | Option.none => Option.none
            | Option.some parameterKey =>
                match smaller result with
                | Option.none => Option.none
                | Option.some resultKey =>
                    Option.some
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
      | Option.none => Option.none
      | Option.some key => Option.some (String.Internal.append "ProofScript.Closure$" key)
  | _ => Option.none

def psWasmClosureCodeTypeName
    (type : PsVerifiedIrType) : Option String :=
  match type with
  | .function _ _ =>
      match psWasmIrTypeKey type with
      | Option.none => Option.none
      | Option.some key => Option.some (String.Internal.append "ProofScript.ClosureCode$" key)
  | _ => Option.none

def psWasmArrayTypeName
    (elementType : PsVerifiedIrType) : Option String :=
  match psWasmIrTypeKey elementType with
  | Option.none => Option.none
  | Option.some key => Option.some (String.Internal.append "ProofScript.Array$" key)

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
  | .unit => PsWasmValueType.i32

def psWasmStorageTypeOfPrimitive
    (profile : PsWasmTargetProfile)
    (type : PsVerifiedIrPrimitiveType) : PsWasmStorageType :=
  match type with
  | .uint8 => PsWasmStorageType.packedI8
  | .int8 => PsWasmStorageType.packedI8
  | .uint16 => PsWasmStorageType.packedI16
  | .int16 => PsWasmStorageType.packedI16
  | _ => PsWasmStorageType.value (psWasmValueTypeOfPrimitive profile type)

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
      let valueType :=
        psWasmValueTypeOfPrimitive profile primitive;
      match valueType with
      | .noValue => Option.none
      | _ => Option.some valueType
  | .named name arguments =>
      if psStringEq name "Array" then
        match arguments with
        | List.nil => Option.none
        | List.cons elementType rest =>
            match rest with
            | List.nil =>
                match psWasmArrayTypeName elementType with
                | Option.none => Option.none
                | Option.some arrayName =>
                    Option.some (PsWasmValueType.refT arrayName)
            | List.cons _ _ => Option.none
      else
        match arguments with
        | List.nil =>
            Option.some (PsWasmValueType.refT name)
        | List.cons _ _ => Option.none
  | .function parameters result =>
      match
          psWasmClosureBaseName
            (PsVerifiedIrType.function parameters result) with
      | Option.none => Option.none
      | Option.some name => Option.some (PsWasmValueType.refT name)
  | _ => Option.none

def psWasmStorageTypeOfIrType?
    (profile : PsWasmTargetProfile) :
    PsVerifiedIrType -> Option PsWasmStorageType
  | .primitive primitive =>
      match psWasmValueTypeOfPrimitive profile primitive with
      | .noValue => Option.none
      | _ => Option.some (psWasmStorageTypeOfPrimitive profile primitive)
  | .named name arguments =>
      if psStringEq name "Array" then
        match arguments with
        | List.nil => Option.none
        | List.cons elementType rest =>
            match rest with
            | List.nil =>
                match psWasmArrayTypeName elementType with
                | Option.none => Option.none
                | Option.some arrayName =>
                    Option.some
                      (PsWasmStorageType.value
                        (PsWasmValueType.refT arrayName))
            | List.cons _ _ => Option.none
      else
        match arguments with
        | List.nil =>
            Option.some
              (PsWasmStorageType.value
                (PsWasmValueType.refT name))
        | List.cons _ _ => Option.none
  | .function parameters result =>
      match
          psWasmClosureBaseName
            (PsVerifiedIrType.function parameters result) with
      | Option.none => Option.none
      | Option.some name =>
          Option.some
            (PsWasmStorageType.value
              (PsWasmValueType.refT name))
  | _ => Option.none