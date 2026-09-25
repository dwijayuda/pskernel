import Ps.BackendWasm.Model

inductive PsWasmEncodeError where
  | unsupportedValueType
  | unsupportedInstruction
  | negativeIntegerConstant
  | unknownFunction (name : String)
  | unknownFunctionType (name : String)
  | unknownStructure (name : String)

def psWasmByte (value : Nat) : UInt8 :=
  UInt8.ofNat value

def psWasmEncodeUlebWithFuel :
    Nat -> Nat -> List UInt8
  | 0, _ => []
  | fuel + 1, value =>
      let low := value % 128
      let rest := value / 128
      if rest == 0 then
        [psWasmByte low]
      else
        psWasmByte (low + 128) ::
          psWasmEncodeUlebWithFuel fuel rest

def psWasmEncodeUleb (value : Nat) : List UInt8 :=
  psWasmEncodeUlebWithFuel 16 value

def psWasmEncodeSlebWithFuel :
    Nat -> Int -> List UInt8
  | 0, _ => []
  | fuel + 1, value =>
      let lowInt := value % 128
      let low := lowInt.toNat
      let rest := value / 128
      let signSet := 64 <= low
      let donePositive := rest == 0 && !signSet
      let doneNegative := rest == -1 && signSet
      if donePositive || doneNegative then
        [psWasmByte low]
      else
        psWasmByte (low + 128) ::
          psWasmEncodeSlebWithFuel fuel rest

def psWasmEncodeSleb (value : Int) : List UInt8 :=
  psWasmEncodeSlebWithFuel 16 value

def psWasmNormalizeI32Immediate (value : Int) : Int :=
  let reduced := value % 4294967296
  if reduced >= 2147483648 then
    reduced - 4294967296
  else
    reduced

def psWasmNormalizeI64Immediate (value : Int) : Int :=
  let reduced := value % 18446744073709551616
  if reduced >= 9223372036854775808 then
    reduced - 18446744073709551616
  else
    reduced

def psWasmEncodeI32Constant (value : Int) : List UInt8 :=
  psWasmEncodeSleb (psWasmNormalizeI32Immediate value)

def psWasmEncodeI64Constant (value : Int) : List UInt8 :=
  psWasmEncodeSleb (psWasmNormalizeI64Immediate value)

def psWasmEncodeUtf8Char (char : Char) : List UInt8 :=
  let value := char.toNat
  if value <= 127 then
    [psWasmByte value]
  else if value <= 2047 then
    [
      psWasmByte (192 + value / 64),
      psWasmByte (128 + value % 64)
    ]
  else if value <= 65535 then
    [
      psWasmByte (224 + value / 4096),
      psWasmByte (128 + (value / 64) % 64),
      psWasmByte (128 + value % 64)
    ]
  else
    [
      psWasmByte (240 + value / 262144),
      psWasmByte (128 + (value / 4096) % 64),
      psWasmByte (128 + (value / 64) % 64),
      psWasmByte (128 + value % 64)
    ]

def psWasmEncodeUtf8Chars : List Char -> List UInt8
  | [] => []
  | char :: rest =>
      psWasmEncodeUtf8Char char ++ psWasmEncodeUtf8Chars rest

def psWasmEncodeName (name : String) : List UInt8 :=
  let bytes := psWasmEncodeUtf8Chars name.toList
  psWasmEncodeUleb bytes.length ++ bytes

def psWasmFindStructureIndexLoop
    (name : String) :
    Nat -> List PsWasmStructType -> Option Nat
  | _, [] => none
  | index, structType :: rest =>
      if structType.name == name then
        some index
      else
        psWasmFindStructureIndexLoop name (index + 1) rest

def psWasmFindStructureIndex
    (structures : List PsWasmStructType)
    (name : String) : Option Nat :=
  psWasmFindStructureIndexLoop name 0 structures

def psWasmEncodeValueType
    (structures : List PsWasmStructType)
    (type : PsWasmValueType) :
    Except PsWasmEncodeError (List UInt8) :=
  match type with
  | .i32 => Except.ok [psWasmByte 127]
  | .i64 => Except.ok [psWasmByte 126]
  | .f32 => Except.ok [psWasmByte 125]
  | .f64 => Except.ok [psWasmByte 124]
  | .refT name =>
      match psWasmFindStructureIndex structures name with
      | none =>
          Except.error (PsWasmEncodeError.unknownStructure name)
      | some index =>
          Except.ok
            ([psWasmByte 100]
              ++ psWasmEncodeSleb (Int.ofNat index))
  | .funcRef => Except.ok [psWasmByte 112]
  | .noValue => Except.error PsWasmEncodeError.unsupportedValueType

def psWasmEncodeValueTypes
    (structures : List PsWasmStructType) :
    List PsWasmValueType ->
    Except PsWasmEncodeError (List UInt8)
  | [] => Except.ok []
  | type :: rest =>
      match psWasmEncodeValueType structures type with
      | Except.error error => Except.error error
      | Except.ok encoded =>
          match psWasmEncodeValueTypes structures rest with
          | Except.error error => Except.error error
          | Except.ok encodedRest =>
              Except.ok (encoded ++ encodedRest)

def psWasmEncodeVector
    (bytes : List UInt8)
    (count : Nat) : List UInt8 :=
  psWasmEncodeUleb count ++ bytes

def psWasmFindFunctionTypeIndexLoop
    (name : String) :
    Nat -> List PsWasmFunctionType -> Option Nat
  | _, [] => none
  | index, functionType :: rest =>
      if functionType.name == name then
        some index
      else
        psWasmFindFunctionTypeIndexLoop
          name
          (index + 1)
          rest

def psWasmFindFunctionTypeIndex
    (structures : List PsWasmStructType)
    (functionTypes : List PsWasmFunctionType)
    (name : String) : Option Nat :=
  match psWasmFindFunctionTypeIndexLoop name 0 functionTypes with
  | none => none
  | some index => some (structures.length + index)

def psWasmEncodeNamedFunctionType
    (structures : List PsWasmStructType)
    (functionType : PsWasmFunctionType) :
    Except PsWasmEncodeError (List UInt8) :=
  match psWasmEncodeValueTypes structures functionType.parameters with
  | Except.error error => Except.error error
  | Except.ok parameters =>
      match psWasmEncodeValueTypes structures functionType.results with
      | Except.error error => Except.error error
      | Except.ok results =>
          Except.ok
            ([psWasmByte 96]
              ++ psWasmEncodeVector
                parameters
                functionType.parameters.length
              ++ psWasmEncodeVector
                results
                functionType.results.length)

def psWasmEncodeNamedFunctionTypes
    (structures : List PsWasmStructType) :
    List PsWasmFunctionType ->
    Except PsWasmEncodeError (List UInt8)
  | [] => Except.ok []
  | functionType :: rest =>
      match psWasmEncodeNamedFunctionType structures functionType with
      | Except.error error => Except.error error
      | Except.ok encoded =>
          match psWasmEncodeNamedFunctionTypes structures rest with
          | Except.error error => Except.error error
          | Except.ok encodedRest =>
              Except.ok (encoded ++ encodedRest)

def psWasmEncodeFunctionType
    (structures : List PsWasmStructType)
    (function : PsWasmFunction) :
    Except PsWasmEncodeError (List UInt8) :=
  match psWasmEncodeValueTypes structures function.parameters with
  | Except.error error => Except.error error
  | Except.ok parameters =>
      match psWasmEncodeValueTypes structures function.results with
      | Except.error error => Except.error error
      | Except.ok results =>
          Except.ok
            ([psWasmByte 96]
              ++ psWasmEncodeVector parameters function.parameters.length
              ++ psWasmEncodeVector results function.results.length)

def psWasmEncodeFunctionTypes
    (structures : List PsWasmStructType) :
    List PsWasmFunction ->
    Except PsWasmEncodeError (List UInt8)
  | [] => Except.ok []
  | function :: rest =>
      match psWasmEncodeFunctionType structures function with
      | Except.error error => Except.error error
      | Except.ok encoded =>
          match psWasmEncodeFunctionTypes structures rest with
          | Except.error error => Except.error error
          | Except.ok encodedRest =>
              Except.ok (encoded ++ encodedRest)

def psWasmFindFunctionIndexLoop
    (name : String) :
    Nat -> List PsWasmFunction -> Option Nat
  | _, [] => none
  | index, function :: rest =>
      if function.name == name then
        some index
      else
        psWasmFindFunctionIndexLoop name (index + 1) rest

def psWasmFindFunctionIndex
    (functions : List PsWasmFunction)
    (name : String) : Option Nat :=
  psWasmFindFunctionIndexLoop name 0 functions

def psWasmEncodeInstruction
    (structures : List PsWasmStructType)
    (functionTypes : List PsWasmFunctionType)
    (functions : List PsWasmFunction)
    (instruction : PsWasmInstruction) :
    Except PsWasmEncodeError (List UInt8) :=
  match instruction with
  | .localGet index =>
      Except.ok (psWasmByte 32 :: psWasmEncodeUleb index)
  | .localSet index =>
      Except.ok (psWasmByte 33 :: psWasmEncodeUleb index)
  | .call name =>
      match psWasmFindFunctionIndex functions name with
      | none => Except.error (PsWasmEncodeError.unknownFunction name)
      | some index =>
          Except.ok (psWasmByte 16 :: psWasmEncodeUleb index)
  | .return_ => Except.ok [psWasmByte 15]
  | .ifStart result =>
      match result with
      | none =>
          Except.ok [psWasmByte 4, psWasmByte 64]
      | some valueType =>
          match psWasmEncodeValueType structures valueType with
          | Except.error error => Except.error error
          | Except.ok encodedType =>
              Except.ok ([psWasmByte 4] ++ encodedType)
  | .else_ => Except.ok [psWasmByte 5]
  | .end_ => Except.ok [psWasmByte 11]
  | .i32Const value =>
      Except.ok
        (psWasmByte 65 :: psWasmEncodeI32Constant value)
  | .i64Const value =>
      Except.ok
        (psWasmByte 66 :: psWasmEncodeI64Constant value)
  | .i32Add => Except.ok [psWasmByte 106]
  | .i32Sub => Except.ok [psWasmByte 107]
  | .i32Mul => Except.ok [psWasmByte 108]
  | .i32And => Except.ok [psWasmByte 113]
  | .i32Or => Except.ok [psWasmByte 114]
  | .i32Xor => Except.ok [psWasmByte 115]
  | .i32Extend8S => Except.ok [psWasmByte 192]
  | .i32Extend16S => Except.ok [psWasmByte 193]
  | .i32Eq => Except.ok [psWasmByte 70]
  | .i32Ne => Except.ok [psWasmByte 71]
  | .i32LtS => Except.ok [psWasmByte 72]
  | .i32LtU => Except.ok [psWasmByte 73]
  | .i32GtS => Except.ok [psWasmByte 74]
  | .i32GtU => Except.ok [psWasmByte 75]
  | .i32LeS => Except.ok [psWasmByte 76]
  | .i32LeU => Except.ok [psWasmByte 77]
  | .i32GeS => Except.ok [psWasmByte 78]
  | .i32GeU => Except.ok [psWasmByte 79]
  | .i64Add => Except.ok [psWasmByte 124]
  | .i64Sub => Except.ok [psWasmByte 125]
  | .i64Mul => Except.ok [psWasmByte 126]
  | .i64And => Except.ok [psWasmByte 131]
  | .i64Or => Except.ok [psWasmByte 132]
  | .i64Xor => Except.ok [psWasmByte 133]
  | .i64Eq => Except.ok [psWasmByte 81]
  | .i64Ne => Except.ok [psWasmByte 82]
  | .i64LtS => Except.ok [psWasmByte 83]
  | .i64LtU => Except.ok [psWasmByte 84]
  | .i64GtS => Except.ok [psWasmByte 85]
  | .i64GtU => Except.ok [psWasmByte 86]
  | .i64LeS => Except.ok [psWasmByte 87]
  | .i64LeU => Except.ok [psWasmByte 88]
  | .i64GeS => Except.ok [psWasmByte 89]
  | .i64GeU => Except.ok [psWasmByte 90]
  | .f32Eq => Except.ok [psWasmByte 91]
  | .f32Ne => Except.ok [psWasmByte 92]
  | .f32Lt => Except.ok [psWasmByte 93]
  | .f32Gt => Except.ok [psWasmByte 94]
  | .f32Le => Except.ok [psWasmByte 95]
  | .f32Ge => Except.ok [psWasmByte 96]
  | .f64Eq => Except.ok [psWasmByte 97]
  | .f64Ne => Except.ok [psWasmByte 98]
  | .f64Lt => Except.ok [psWasmByte 99]
  | .f64Gt => Except.ok [psWasmByte 100]
  | .f64Le => Except.ok [psWasmByte 101]
  | .f64Ge => Except.ok [psWasmByte 102]
  | .f32Add => Except.ok [psWasmByte 146]
  | .f32Sub => Except.ok [psWasmByte 147]
  | .f32Mul => Except.ok [psWasmByte 148]
  | .f32Div => Except.ok [psWasmByte 149]
  | .f64Add => Except.ok [psWasmByte 160]
  | .f64Sub => Except.ok [psWasmByte 161]
  | .f64Mul => Except.ok [psWasmByte 162]
  | .f64Div => Except.ok [psWasmByte 163]
  | .structNew typeName =>
      match psWasmFindStructureIndex structures typeName with
      | none =>
          Except.error (PsWasmEncodeError.unknownStructure typeName)
      | some typeIndex =>
          Except.ok
            ([psWasmByte 251]
              ++ psWasmEncodeUleb 0
              ++ psWasmEncodeUleb typeIndex)
  | .structGet typeName fieldIndex =>
      match psWasmFindStructureIndex structures typeName with
      | none =>
          Except.error (PsWasmEncodeError.unknownStructure typeName)
      | some typeIndex =>
          Except.ok
            ([psWasmByte 251]
              ++ psWasmEncodeUleb 2
              ++ psWasmEncodeUleb typeIndex
              ++ psWasmEncodeUleb fieldIndex)
  | .structGetS typeName fieldIndex =>
      match psWasmFindStructureIndex structures typeName with
      | none =>
          Except.error (PsWasmEncodeError.unknownStructure typeName)
      | some typeIndex =>
          Except.ok
            ([psWasmByte 251]
              ++ psWasmEncodeUleb 3
              ++ psWasmEncodeUleb typeIndex
              ++ psWasmEncodeUleb fieldIndex)
  | .structGetU typeName fieldIndex =>
      match psWasmFindStructureIndex structures typeName with
      | none =>
          Except.error (PsWasmEncodeError.unknownStructure typeName)
      | some typeIndex =>
          Except.ok
            ([psWasmByte 251]
              ++ psWasmEncodeUleb 4
              ++ psWasmEncodeUleb typeIndex
              ++ psWasmEncodeUleb fieldIndex)
  | .refTest typeName =>
      match psWasmFindStructureIndex structures typeName with
      | none =>
          Except.error (PsWasmEncodeError.unknownStructure typeName)
      | some typeIndex =>
          Except.ok
            ([psWasmByte 251]
              ++ psWasmEncodeUleb 20
              ++ psWasmEncodeSleb (Int.ofNat typeIndex))
  | .refCast typeName =>
      match psWasmFindStructureIndex structures typeName with
      | none =>
          Except.error (PsWasmEncodeError.unknownStructure typeName)
      | some typeIndex =>
          Except.ok
            ([psWasmByte 251]
              ++ psWasmEncodeUleb 22
              ++ psWasmEncodeSleb (Int.ofNat typeIndex))
  | .refFunc functionName =>
      match psWasmFindFunctionIndex functions functionName with
      | none =>
          Except.error (PsWasmEncodeError.unknownFunction functionName)
      | some functionIndex =>
          Except.ok
            ([psWasmByte 210]
              ++ psWasmEncodeUleb functionIndex)
  | .refCastFunction typeName =>
      match
          psWasmFindFunctionTypeIndex
            structures
            functionTypes
            typeName with
      | none =>
          Except.error (PsWasmEncodeError.unknownFunctionType typeName)
      | some typeIndex =>
          Except.ok
            ([psWasmByte 251]
              ++ psWasmEncodeUleb 22
              ++ psWasmEncodeSleb (Int.ofNat typeIndex))
  | .callRef typeName =>
      match
          psWasmFindFunctionTypeIndex
            structures
            functionTypes
            typeName with
      | none =>
          Except.error (PsWasmEncodeError.unknownFunctionType typeName)
      | some typeIndex =>
          Except.ok
            ([psWasmByte 20]
              ++ psWasmEncodeUleb typeIndex)
  | .f32ConstBits _ =>
      Except.error PsWasmEncodeError.unsupportedInstruction
  | .f64ConstBits _ =>
      Except.error PsWasmEncodeError.unsupportedInstruction

def psWasmEncodeInstructions
    (structures : List PsWasmStructType)
    (functionTypes : List PsWasmFunctionType)
    (functions : List PsWasmFunction) :
    List PsWasmInstruction ->
    Except PsWasmEncodeError (List UInt8)
  | [] => Except.ok []
  | instruction :: rest =>
      match psWasmEncodeInstruction
          structures
          functionTypes
          functions
          instruction with
      | Except.error error => Except.error error
      | Except.ok encoded =>
          match psWasmEncodeInstructions
              structures
              functionTypes
              functions
              rest with
          | Except.error error => Except.error error
          | Except.ok encodedRest =>
              Except.ok (encoded ++ encodedRest)

def psWasmEncodeLocalDeclarations
    (structures : List PsWasmStructType) :
    List PsWasmValueType ->
    Except PsWasmEncodeError (List UInt8)
  | [] => Except.ok []
  | type :: rest =>
      match psWasmEncodeValueType structures type with
      | Except.error error => Except.error error
      | Except.ok encodedType =>
          match psWasmEncodeLocalDeclarations structures rest with
          | Except.error error => Except.error error
          | Except.ok encodedRest =>
              Except.ok
                (psWasmEncodeUleb 1
                  ++ encodedType
                  ++ encodedRest)

def psWasmEncodeFunctionBody
    (structures : List PsWasmStructType)
    (functionTypes : List PsWasmFunctionType)
    (functions : List PsWasmFunction)
    (function : PsWasmFunction) :
    Except PsWasmEncodeError (List UInt8) :=
  match psWasmEncodeLocalDeclarations structures function.locals with
  | Except.error error => Except.error error
  | Except.ok encodedLocals =>
      match psWasmEncodeInstructions
          structures
          functionTypes
          functions
          function.body with
      | Except.error error => Except.error error
      | Except.ok instructions =>
          let body :=
            psWasmEncodeUleb function.locals.length
              ++ encodedLocals
              ++ instructions
              ++ [psWasmByte 11]
          Except.ok (psWasmEncodeUleb body.length ++ body)

def psWasmEncodeFunctionBodies
    (structures : List PsWasmStructType)
    (functionTypes : List PsWasmFunctionType)
    (functions : List PsWasmFunction) :
    List PsWasmFunction ->
    Except PsWasmEncodeError (List UInt8)
  | [] => Except.ok []
  | function :: rest =>
      match psWasmEncodeFunctionBody
          structures
          functionTypes
          functions
          function with
      | Except.error error => Except.error error
      | Except.ok encoded =>
          match psWasmEncodeFunctionBodies
              structures
              functionTypes
              functions
              rest with
          | Except.error error => Except.error error
          | Except.ok encodedRest =>
              Except.ok (encoded ++ encodedRest)

def psWasmEncodeStorageType
    (structures : List PsWasmStructType)
    (type : PsWasmStorageType) :
    Except PsWasmEncodeError (List UInt8) :=
  match type with
  | .packedI8 => Except.ok [psWasmByte 120]
  | .packedI16 => Except.ok [psWasmByte 119]
  | .value valueType =>
      psWasmEncodeValueType structures valueType

def psWasmEncodeStructField
    (structures : List PsWasmStructType)
    (field : PsWasmStructField) :
    Except PsWasmEncodeError (List UInt8) :=
  match psWasmEncodeStorageType structures field.storageType with
  | Except.error error => Except.error error
  | Except.ok storage =>
      Except.ok (storage ++ [psWasmByte 0])

def psWasmEncodeStructFields
    (structures : List PsWasmStructType) :
    List PsWasmStructField ->
    Except PsWasmEncodeError (List UInt8)
  | [] => Except.ok []
  | field :: rest =>
      match psWasmEncodeStructField structures field with
      | Except.error error => Except.error error
      | Except.ok encoded =>
          match psWasmEncodeStructFields structures rest with
          | Except.error error => Except.error error
          | Except.ok encodedRest =>
              Except.ok (encoded ++ encodedRest)

def psWasmEncodeStructCompositeType
    (structures : List PsWasmStructType)
    (structType : PsWasmStructType) :
    Except PsWasmEncodeError (List UInt8) :=
  match psWasmEncodeStructFields structures structType.fields with
  | Except.error error => Except.error error
  | Except.ok fields =>
      Except.ok
        ([psWasmByte 95]
          ++ psWasmEncodeUleb structType.fields.length
          ++ fields)

def psWasmEncodeStructType
    (structures : List PsWasmStructType)
    (structType : PsWasmStructType) :
    Except PsWasmEncodeError (List UInt8) :=
  match psWasmEncodeStructCompositeType structures structType with
  | Except.error error => Except.error error
  | Except.ok composite =>
      match structType.superType with
      | none =>
          if structType.isFinal then
            Except.ok composite
          else
            Except.ok
              ([psWasmByte 80]
                ++ psWasmEncodeUleb 0
                ++ composite)
      | some superName =>
          match psWasmFindStructureIndex structures superName with
          | none =>
              Except.error (PsWasmEncodeError.unknownStructure superName)
          | some superIndex =>
              let subtypeTag :=
                if structType.isFinal then
                  psWasmByte 79
                else
                  psWasmByte 80
              Except.ok
                ([subtypeTag]
                  ++ psWasmEncodeUleb 1
                  ++ psWasmEncodeUleb superIndex
                  ++ composite)

def psWasmEncodeStructTypes
    (structures : List PsWasmStructType) :
    List PsWasmStructType ->
    Except PsWasmEncodeError (List UInt8)
  | [] => Except.ok []
  | structType :: rest =>
      match psWasmEncodeStructType structures structType with
      | Except.error error => Except.error error
      | Except.ok encoded =>
          match psWasmEncodeStructTypes structures rest with
          | Except.error error => Except.error error
          | Except.ok encodedRest =>
              Except.ok (encoded ++ encodedRest)

def psWasmFunctionTypeIndex
    (structures : List PsWasmStructType)
    (functionTypes : List PsWasmFunctionType)
    (functionIndex : Nat)
    (function : PsWasmFunction) :
    Except PsWasmEncodeError Nat :=
  match function.typeName with
  | none =>
      Except.ok
        (structures.length
          + functionTypes.length
          + functionIndex)
  | some typeName =>
      match
          psWasmFindFunctionTypeIndex
            structures
            functionTypes
            typeName with
      | none =>
          Except.error
            (PsWasmEncodeError.unknownFunctionType typeName)
      | some typeIndex => Except.ok typeIndex

def psWasmEncodeFunctionTypeIndicesLoop
    (structures : List PsWasmStructType)
    (functionTypes : List PsWasmFunctionType) :
    Nat ->
    List PsWasmFunction ->
    Except PsWasmEncodeError (List UInt8)
  | _, [] => Except.ok []
  | functionIndex, function :: rest =>
      match
          psWasmFunctionTypeIndex
            structures
            functionTypes
            functionIndex
            function with
      | Except.error error => Except.error error
      | Except.ok typeIndex =>
          match
              psWasmEncodeFunctionTypeIndicesLoop
                structures
                functionTypes
                (functionIndex + 1)
                rest with
          | Except.error error => Except.error error
          | Except.ok encodedRest =>
              Except.ok
                (psWasmEncodeUleb typeIndex ++ encodedRest)

def psWasmEncodeFunctionTypeIndices
    (structures : List PsWasmStructType)
    (functionTypes : List PsWasmFunctionType)
    (functions : List PsWasmFunction) :
    Except PsWasmEncodeError (List UInt8) :=
  psWasmEncodeFunctionTypeIndicesLoop
    structures functionTypes 0 functions

def psWasmEncodeFunctionRefIndices
    (functions : List PsWasmFunction) :
    List String ->
    Except PsWasmEncodeError (List UInt8)
  | [] => Except.ok []
  | name :: rest =>
      match psWasmFindFunctionIndex functions name with
      | none =>
          Except.error (PsWasmEncodeError.unknownFunction name)
      | some index =>
          match psWasmEncodeFunctionRefIndices functions rest with
          | Except.error error => Except.error error
          | Except.ok encodedRest =>
              Except.ok
                (psWasmEncodeUleb index ++ encodedRest)

def psWasmEncodeDeclarativeFunctionRefs
    (functions : List PsWasmFunction)
    (functionRefs : List String) :
    Except PsWasmEncodeError (List UInt8) :=
  match functionRefs with
  | [] => Except.ok []
  | _ =>
      match
          psWasmEncodeFunctionRefIndices
            functions
            functionRefs with
      | Except.error error => Except.error error
      | Except.ok indices =>
          let segment :=
            psWasmEncodeUleb 3
              ++ [psWasmByte 0]
              ++ psWasmEncodeVector
                indices
                functionRefs.length
          Except.ok
            (psWasmEncodeVector segment 1)

def psWasmEncodeExports
    (functions : List PsWasmFunction) :
    List (String × String) ->
    Except PsWasmEncodeError (List UInt8)
  | [] => Except.ok []
  | exportItem :: rest =>
      match psWasmFindFunctionIndex functions exportItem.2 with
      | none =>
          Except.error (PsWasmEncodeError.unknownFunction exportItem.2)
      | some index =>
          match psWasmEncodeExports functions rest with
          | Except.error error => Except.error error
          | Except.ok encodedRest =>
              Except.ok
                (psWasmEncodeName exportItem.1
                  ++ [psWasmByte 0]
                  ++ psWasmEncodeUleb index
                  ++ encodedRest)

def psWasmEncodeSection
    (sectionId : Nat)
    (payload : List UInt8) : List UInt8 :=
  [psWasmByte sectionId]
    ++ psWasmEncodeUleb payload.length
    ++ payload

def psWasmEncodeModule
    (module : PsWasmModule) :
    Except PsWasmEncodeError (List UInt8) :=
  match psWasmEncodeStructTypes module.structures module.structures with
  | Except.error error => Except.error error
  | Except.ok encodedStructTypes =>
      match
          psWasmEncodeNamedFunctionTypes
            module.structures
            module.functionTypes with
      | Except.error error => Except.error error
      | Except.ok encodedNamedFunctionTypes =>
          match
              psWasmEncodeFunctionTypes
                module.structures
                module.functions with
          | Except.error error => Except.error error
          | Except.ok encodedFunctionTypes =>
              match
                  psWasmEncodeFunctionTypeIndices
                    module.structures
                    module.functionTypes
                    module.functions with
              | Except.error error => Except.error error
              | Except.ok encodedFunctionTypeIndices =>
                  match
                      psWasmEncodeExports
                        module.functions
                        module.exports with
                  | Except.error error => Except.error error
                  | Except.ok encodedExports =>
                      match
                          psWasmEncodeDeclarativeFunctionRefs
                            module.functions
                            module.functionRefs with
                      | Except.error error => Except.error error
                      | Except.ok encodedFunctionRefs =>
                          match
                              psWasmEncodeFunctionBodies
                                module.structures
                                module.functionTypes
                                module.functions
                                module.functions with
                          | Except.error error => Except.error error
                          | Except.ok encodedBodies =>
                              let typeCount :=
                                module.structures.length
                                  + module.functionTypes.length
                                  + module.functions.length
                              let typePayload :=
                                psWasmEncodeVector
                                  (encodedStructTypes
                                    ++ encodedNamedFunctionTypes
                                    ++ encodedFunctionTypes)
                                  typeCount
                              let functionPayload :=
                                psWasmEncodeVector
                                  encodedFunctionTypeIndices
                                  module.functions.length
                              let exportPayload :=
                                psWasmEncodeVector
                                  encodedExports
                                  module.exports.length
                              let elementSection :=
                                match module.functionRefs with
                                | [] => []
                                | _ =>
                                    psWasmEncodeSection
                                      9
                                      encodedFunctionRefs
                              let codePayload :=
                                psWasmEncodeVector
                                  encodedBodies
                                  module.functions.length
                              Except.ok
                                ([
                                  psWasmByte 0,
                                  psWasmByte 97,
                                  psWasmByte 115,
                                  psWasmByte 109,
                                  psWasmByte 1,
                                  psWasmByte 0,
                                  psWasmByte 0,
                                  psWasmByte 0
                                ]
                                  ++ psWasmEncodeSection 1 typePayload
                                  ++ psWasmEncodeSection 3 functionPayload
                                  ++ psWasmEncodeSection 7 exportPayload
                                  ++ elementSection
                                  ++ psWasmEncodeSection 10 codePayload)
