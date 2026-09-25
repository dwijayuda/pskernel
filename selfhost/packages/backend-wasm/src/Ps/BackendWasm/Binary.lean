import Ps.BackendWasm.Model

inductive PsWasmEncodeError where
  | unsupportedValueType
  | unsupportedInstruction
  | negativeIntegerConstant
  | unknownFunction (name : String)
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
  | index, structure :: rest =>
      if structure.name == name then
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
          match psWasmEncodeValueType valueType with
          | Except.error error => Except.error error
          | Except.ok encodedType =>
              Except.ok [psWasmByte 4, encodedType]
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
  | .f32ConstBits _ =>
      Except.error PsWasmEncodeError.unsupportedInstruction
  | .f64ConstBits _ =>
      Except.error PsWasmEncodeError.unsupportedInstruction

def psWasmEncodeInstructions
    (functions : List PsWasmFunction) :
    List PsWasmInstruction ->
    Except PsWasmEncodeError (List UInt8)
  | [] => Except.ok []
  | instruction :: rest =>
      match psWasmEncodeInstruction functions instruction with
      | Except.error error => Except.error error
      | Except.ok encoded =>
          match psWasmEncodeInstructions functions rest with
          | Except.error error => Except.error error
          | Except.ok encodedRest =>
              Except.ok (encoded ++ encodedRest)

def psWasmEncodeLocalDeclarations :
    List PsWasmValueType ->
    Except PsWasmEncodeError (List UInt8)
  | [] => Except.ok []
  | type :: rest =>
      match psWasmEncodeValueType type with
      | Except.error error => Except.error error
      | Except.ok encodedType =>
          match psWasmEncodeLocalDeclarations rest with
          | Except.error error => Except.error error
          | Except.ok encodedRest =>
              Except.ok
                (psWasmEncodeUleb 1
                  ++ [encodedType]
                  ++ encodedRest)

def psWasmEncodeFunctionBody
    (functions : List PsWasmFunction)
    (function : PsWasmFunction) :
    Except PsWasmEncodeError (List UInt8) :=
  match psWasmEncodeLocalDeclarations function.locals with
  | Except.error error => Except.error error
  | Except.ok encodedLocals =>
      match psWasmEncodeInstructions functions function.body with
      | Except.error error => Except.error error
      | Except.ok instructions =>
          let body :=
            psWasmEncodeUleb function.locals.length
              ++ encodedLocals
              ++ instructions
              ++ [psWasmByte 11]
          Except.ok (psWasmEncodeUleb body.length ++ body)

def psWasmEncodeFunctionBodies
    (functions : List PsWasmFunction) :
    List PsWasmFunction ->
    Except PsWasmEncodeError (List UInt8)
  | [] => Except.ok []
  | function :: rest =>
      match psWasmEncodeFunctionBody functions function with
      | Except.error error => Except.error error
      | Except.ok encoded =>
          match psWasmEncodeFunctionBodies functions rest with
          | Except.error error => Except.error error
          | Except.ok encodedRest =>
              Except.ok (encoded ++ encodedRest)

def psWasmEncodeFunctionTypeIndicesLoop :
    Nat -> Nat -> List UInt8
  | _, 0 => []
  | index, count + 1 =>
      psWasmEncodeUleb index ++
        psWasmEncodeFunctionTypeIndicesLoop (index + 1) count

def psWasmEncodeFunctionTypeIndices
    (count : Nat) : List UInt8 :=
  psWasmEncodeFunctionTypeIndicesLoop 0 count

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
  match psWasmEncodeFunctionTypes module.functions with
  | Except.error error => Except.error error
  | Except.ok encodedTypes =>
      match psWasmEncodeExports module.functions module.exports with
      | Except.error error => Except.error error
      | Except.ok encodedExports =>
          match psWasmEncodeFunctionBodies module.functions module.functions with
          | Except.error error => Except.error error
          | Except.ok encodedBodies =>
              let typePayload :=
                psWasmEncodeVector encodedTypes module.functions.length
              let functionPayload :=
                psWasmEncodeVector
                  (psWasmEncodeFunctionTypeIndices module.functions.length)
                  module.functions.length
              let exportPayload :=
                psWasmEncodeVector encodedExports module.exports.length
              let codePayload :=
                psWasmEncodeVector encodedBodies module.functions.length
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
                  ++ psWasmEncodeSection 10 codePayload)
