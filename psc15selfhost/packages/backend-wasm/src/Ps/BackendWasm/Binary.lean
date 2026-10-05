import Ps.BackendWasm.Model
import Ps.Foundation.Name
import Ps.Foundation.List

inductive PsWasmEncodeError where
  | unsupportedValueType
  | unsupportedInstruction
  | negativeIntegerConstant
  | unknownFunction (name : String)
  | unknownFunctionType (name : String)
  | unknownStructure (name : String)

def psWasmByte (value : Nat) : UInt8 :=
  UInt8.ofNat value

def psWasmIntIsZero (value : Int) : Bool :=
  match value with
  | Int.ofNat magnitude => Nat.beq magnitude 0
  | Int.negSucc _ => false

def psWasmIntIsNegativeOne (value : Int) : Bool :=
  match value with
  | Int.ofNat _ => false
  | Int.negSucc magnitude => Nat.beq magnitude 0

def psWasmEncodeUlebWithFuel
    (remainingFuel : Nat)
    (value : Nat) : List UInt8 :=
  match remainingFuel with
  | 0 => List.nil
  | fuel + 1 =>
      let low := value % 128;
      let rest := value / 128;
      if Nat.beq rest 0 then
        [psWasmByte low]
      else
        List.cons
          (psWasmByte (low + 128))
          (psWasmEncodeUlebWithFuel fuel rest)

def psWasmEncodeUleb (value : Nat) : List UInt8 :=
  psWasmEncodeUlebWithFuel 16 value

def psWasmEncodeSlebWithFuel
    (remainingFuel : Nat)
    (value : Int) : List UInt8 :=
  match remainingFuel with
  | 0 => List.nil
  | fuel + 1 =>
      let lowInt := value % 128;
      let low := lowInt.toNat;
      let rest := value / 128;
      let signSet := 64 <= low;
      let donePositive :=
        if psWasmIntIsZero rest then
          if signSet then false else true
        else
          false;
      let doneNegative :=
        if psWasmIntIsNegativeOne rest then signSet else false;
      if donePositive then
        [psWasmByte low]
      else if doneNegative then
        [psWasmByte low]
      else
        List.cons
          (psWasmByte (low + 128))
          (psWasmEncodeSlebWithFuel fuel rest)

def psWasmEncodeSleb (value : Int) : List UInt8 :=
  psWasmEncodeSlebWithFuel 16 value

def psWasmNormalizeI32Immediate (value : Int) : Int :=
  let reduced := value % 4294967296;
  if reduced >= 2147483648 then
    reduced - 4294967296
  else
    reduced

def psWasmNormalizeI64Immediate (value : Int) : Int :=
  let reduced := value % 18446744073709551616;
  if reduced >= 9223372036854775808 then
    reduced - 18446744073709551616
  else
    reduced

def psWasmEncodeI32Constant (value : Int) : List UInt8 :=
  psWasmEncodeSleb (psWasmNormalizeI32Immediate value)

def psWasmEncodeI64Constant (value : Int) : List UInt8 :=
  psWasmEncodeSleb (psWasmNormalizeI64Immediate value)

def psWasmEncodeUtf8Char (char : Char) : List UInt8 :=
  let value := char.toNat;
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

def psWasmEncodeUtf8Chars
    (chars : List Char) :
    List UInt8 :=
  match chars with
  | List.nil => []
  | List.cons char rest =>
      psListAppend
        (psWasmEncodeUtf8Char char)
        (psWasmEncodeUtf8Chars rest)

def psWasmEncodeName (name : String) : List UInt8 :=
  let bytes := psWasmEncodeUtf8Chars name.toList;
  psListAppend
    (psWasmEncodeUleb bytes.length)
    bytes

def psWasmFindStructureIndexLoop
    (name : String)
    (index : Nat)
    (structures : List PsWasmStructType) : Option Nat :=
  match structures with
  | List.nil => none
  | List.cons structType rest =>
      if psStringEq structType.name name then
        some index
      else
        psWasmFindStructureIndexLoop name (index + 1) rest

def psWasmFindStructureIndex
    (structures : List PsWasmStructType)
    (name : String) : Option Nat :=
  psWasmFindStructureIndexLoop name 0 structures

def psWasmFindArrayIndexLoop
    (name : String)
    (index : Nat)
    (arrays : List PsWasmArrayType) : Option Nat :=
  match arrays with
  | List.nil => none
  | List.cons arrayType rest =>
      if psStringEq arrayType.name name then
        some index
      else
        psWasmFindArrayIndexLoop name (index + 1) rest

def psWasmFindArrayIndex
    (arrays : List PsWasmArrayType)
    (name : String) : Option Nat :=
  psWasmFindArrayIndexLoop name 0 arrays

def psWasmFindHeapTypeIndex
    (structures : List PsWasmStructType)
    (arrays : List PsWasmArrayType)
    (name : String) : Option Nat :=
  match psWasmFindStructureIndex structures name with
  | some index => some index
  | none =>
      match psWasmFindArrayIndex arrays name with
      | none => none
      | some index =>
          some (structures.length + index)

def psWasmEncodeValueType
    (structures : List PsWasmStructType)
    (arrays : List PsWasmArrayType)
    (type : PsWasmValueType) :
    Except PsWasmEncodeError (List UInt8) :=
  match type with
  | .i32 => Except.ok [psWasmByte 127]
  | .i64 => Except.ok [psWasmByte 126]
  | .f32 => Except.ok [psWasmByte 125]
  | .f64 => Except.ok [psWasmByte 124]
  | .refT name =>
      match psWasmFindHeapTypeIndex structures arrays name with
      | none =>
          Except.error (PsWasmEncodeError.unknownStructure name)
      | some index =>
          Except.ok
            (psListAppend [psWasmByte 100] (psWasmEncodeSleb (Int.ofNat index)))
  | .funcRef => Except.ok [psWasmByte 112]
  | .noValue => Except.error PsWasmEncodeError.unsupportedValueType

def psWasmEncodeValueTypes
    (structures : List PsWasmStructType)
    (arrays : List PsWasmArrayType)
    (types : List PsWasmValueType) :
    Except PsWasmEncodeError (List UInt8) :=
  match types with
  | List.nil => Except.ok []
  | List.cons type rest =>
      match psWasmEncodeValueType structures arrays type with
      | Except.error error => Except.error error
      | Except.ok encoded =>
          match psWasmEncodeValueTypes structures arrays rest with
          | Except.error error => Except.error error
          | Except.ok encodedRest =>
              Except.ok (psListAppend encoded encodedRest)

def psWasmEncodeVector
    (bytes : List UInt8)
    (count : Nat) : List UInt8 :=
  psListAppend
    (psWasmEncodeUleb count)
    bytes

def psWasmFindFunctionTypeIndexLoop
    (name : String)
    (index : Nat)
    (functionTypes : List PsWasmFunctionType) : Option Nat :=
  match functionTypes with
  | List.nil => none
  | List.cons functionType rest =>
      if psStringEq functionType.name name then
        some index
      else
        psWasmFindFunctionTypeIndexLoop
          name
          (index + 1)
          rest

def psWasmFindFunctionTypeIndex
    (structures : List PsWasmStructType)
    (arrays : List PsWasmArrayType)
    (functionTypes : List PsWasmFunctionType)
    (name : String) : Option Nat :=
  match psWasmFindFunctionTypeIndexLoop name 0 functionTypes with
  | none => none
  | some index =>
      some (structures.length + arrays.length + index)

def psWasmEncodeNamedFunctionType
    (structures : List PsWasmStructType)
    (arrays : List PsWasmArrayType)
    (functionType : PsWasmFunctionType) :
    Except PsWasmEncodeError (List UInt8) :=
  match psWasmEncodeValueTypes structures arrays functionType.parameters with
  | Except.error error => Except.error error
  | Except.ok parameters =>
      match psWasmEncodeValueTypes structures arrays functionType.results with
      | Except.error error => Except.error error
      | Except.ok results =>
          Except.ok
            (psListAppend [psWasmByte 96] (psListAppend (psWasmEncodeVector
                parameters
                functionType.parameters.length) (psWasmEncodeVector
                results
                functionType.results.length)))

def psWasmEncodeNamedFunctionTypes
    (structures : List PsWasmStructType)
    (arrays : List PsWasmArrayType)
    (functionTypesToEncode : List PsWasmFunctionType) :
    Except PsWasmEncodeError (List UInt8) :=
  match functionTypesToEncode with
  | List.nil => Except.ok []
  | List.cons functionType rest =>
      match psWasmEncodeNamedFunctionType structures arrays functionType with
      | Except.error error => Except.error error
      | Except.ok encoded =>
          match psWasmEncodeNamedFunctionTypes structures arrays rest with
          | Except.error error => Except.error error
          | Except.ok encodedRest =>
              Except.ok (psListAppend encoded encodedRest)

def psWasmEncodeFunctionType
    (structures : List PsWasmStructType)
    (arrays : List PsWasmArrayType)
    (function : PsWasmFunction) :
    Except PsWasmEncodeError (List UInt8) :=
  match psWasmEncodeValueTypes structures arrays function.parameters with
  | Except.error error => Except.error error
  | Except.ok parameters =>
      match psWasmEncodeValueTypes structures arrays function.results with
      | Except.error error => Except.error error
      | Except.ok results =>
          Except.ok
            (psListAppend [psWasmByte 96] (psListAppend (psWasmEncodeVector parameters function.parameters.length) (psWasmEncodeVector results function.results.length)))

def psWasmEncodeFunctionTypes
    (structures : List PsWasmStructType)
    (arrays : List PsWasmArrayType)
    (functionsToEncode : List PsWasmFunction) :
    Except PsWasmEncodeError (List UInt8) :=
  match functionsToEncode with
  | List.nil => Except.ok []
  | List.cons function rest =>
      match psWasmEncodeFunctionType structures arrays function with
      | Except.error error => Except.error error
      | Except.ok encoded =>
          match psWasmEncodeFunctionTypes structures arrays rest with
          | Except.error error => Except.error error
          | Except.ok encodedRest =>
              Except.ok (psListAppend encoded encodedRest)

def psWasmFindFunctionIndexLoop
    (name : String)
    (index : Nat)
    (functions : List PsWasmFunction) : Option Nat :=
  match functions with
  | List.nil => none
  | List.cons function rest =>
      if psStringEq function.name name then
        some index
      else
        psWasmFindFunctionIndexLoop name (index + 1) rest

def psWasmFindFunctionIndex
    (functions : List PsWasmFunction)
    (name : String) : Option Nat :=
  psWasmFindFunctionIndexLoop name 0 functions

def psWasmEncodeInstruction
    (structures : List PsWasmStructType)
    (arrays : List PsWasmArrayType)
    (functionTypes : List PsWasmFunctionType)
    (functions : List PsWasmFunction)
    (instruction : PsWasmInstruction) :
    Except PsWasmEncodeError (List UInt8) :=
  match instruction with
  | .localGet index =>
      Except.ok
        (List.cons
          (psWasmByte 32)
          (psWasmEncodeUleb index))
  | .localSet index =>
      Except.ok
        (List.cons
          (psWasmByte 33)
          (psWasmEncodeUleb index))
  | .drop => Except.ok [psWasmByte 26]
  | .unreachable => Except.ok [psWasmByte 0]
  | .call name =>
      match psWasmFindFunctionIndex functions name with
      | none => Except.error (PsWasmEncodeError.unknownFunction name)
      | some index =>
          Except.ok
            (List.cons
              (psWasmByte 16)
              (psWasmEncodeUleb index))
  | .return_ => Except.ok [psWasmByte 15]
  | .ifStart result =>
      match result with
      | none =>
          Except.ok [psWasmByte 4, psWasmByte 64]
      | some valueType =>
          match psWasmEncodeValueType structures arrays valueType with
          | Except.error error => Except.error error
          | Except.ok encodedType =>
              Except.ok (psListAppend [psWasmByte 4] encodedType)
  | .else_ => Except.ok [psWasmByte 5]
  | .end_ => Except.ok [psWasmByte 11]
  | .i32Const value =>
      Except.ok
        (List.cons
          (psWasmByte 65)
          (psWasmEncodeI32Constant value))
  | .i64Const value =>
      Except.ok
        (List.cons
          (psWasmByte 66)
          (psWasmEncodeI64Constant value))
  | .i32Add => Except.ok [psWasmByte 106]
  | .i32Sub => Except.ok [psWasmByte 107]
  | .i32Mul => Except.ok [psWasmByte 108]
  | .i32And => Except.ok [psWasmByte 113]
  | .i32Or => Except.ok [psWasmByte 114]
  | .i32Xor => Except.ok [psWasmByte 115]
  | .i32ShrU => Except.ok [psWasmByte 118]
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
            (psListAppend [psWasmByte 251] (psListAppend (psWasmEncodeUleb 0) (psWasmEncodeUleb typeIndex)))
  | .structGet typeName fieldIndex =>
      match psWasmFindStructureIndex structures typeName with
      | none =>
          Except.error (PsWasmEncodeError.unknownStructure typeName)
      | some typeIndex =>
          Except.ok
            (psListAppend [psWasmByte 251] (psListAppend (psWasmEncodeUleb 2) (psListAppend (psWasmEncodeUleb typeIndex) (psWasmEncodeUleb fieldIndex))))
  | .structGetS typeName fieldIndex =>
      match psWasmFindStructureIndex structures typeName with
      | none =>
          Except.error (PsWasmEncodeError.unknownStructure typeName)
      | some typeIndex =>
          Except.ok
            (psListAppend [psWasmByte 251] (psListAppend (psWasmEncodeUleb 3) (psListAppend (psWasmEncodeUleb typeIndex) (psWasmEncodeUleb fieldIndex))))
  | .structGetU typeName fieldIndex =>
      match psWasmFindStructureIndex structures typeName with
      | none =>
          Except.error (PsWasmEncodeError.unknownStructure typeName)
      | some typeIndex =>
          Except.ok
            (psListAppend [psWasmByte 251] (psListAppend (psWasmEncodeUleb 4) (psListAppend (psWasmEncodeUleb typeIndex) (psWasmEncodeUleb fieldIndex))))
  | .arrayNew typeName =>
      match psWasmFindHeapTypeIndex structures arrays typeName with
      | none =>
          Except.error (PsWasmEncodeError.unknownStructure typeName)
      | some typeIndex =>
          Except.ok
            (psListAppend [psWasmByte 251] (psListAppend (psWasmEncodeUleb 6) (psWasmEncodeUleb typeIndex)))
  | .arrayNewDefault typeName =>
      match psWasmFindHeapTypeIndex structures arrays typeName with
      | none =>
          Except.error (PsWasmEncodeError.unknownStructure typeName)
      | some typeIndex =>
          Except.ok
            (psListAppend [psWasmByte 251] (psListAppend (psWasmEncodeUleb 7) (psWasmEncodeUleb typeIndex)))
  | .arrayNewFixed typeName length =>
      match psWasmFindHeapTypeIndex structures arrays typeName with
      | none =>
          Except.error (PsWasmEncodeError.unknownStructure typeName)
      | some typeIndex =>
          Except.ok
            (psListAppend [psWasmByte 251] (psListAppend (psWasmEncodeUleb 8) (psListAppend (psWasmEncodeUleb typeIndex) (psWasmEncodeUleb length))))
  | .arrayGet typeName =>
      match psWasmFindHeapTypeIndex structures arrays typeName with
      | none =>
          Except.error (PsWasmEncodeError.unknownStructure typeName)
      | some typeIndex =>
          Except.ok
            (psListAppend [psWasmByte 251] (psListAppend (psWasmEncodeUleb 11) (psWasmEncodeUleb typeIndex)))
  | .arrayGetS typeName =>
      match psWasmFindHeapTypeIndex structures arrays typeName with
      | none =>
          Except.error (PsWasmEncodeError.unknownStructure typeName)
      | some typeIndex =>
          Except.ok
            (psListAppend [psWasmByte 251] (psListAppend (psWasmEncodeUleb 12) (psWasmEncodeUleb typeIndex)))
  | .arrayGetU typeName =>
      match psWasmFindHeapTypeIndex structures arrays typeName with
      | none =>
          Except.error (PsWasmEncodeError.unknownStructure typeName)
      | some typeIndex =>
          Except.ok
            (psListAppend [psWasmByte 251] (psListAppend (psWasmEncodeUleb 13) (psWasmEncodeUleb typeIndex)))
  | .arraySet typeName =>
      match psWasmFindHeapTypeIndex structures arrays typeName with
      | none =>
          Except.error (PsWasmEncodeError.unknownStructure typeName)
      | some typeIndex =>
          Except.ok
            (psListAppend [psWasmByte 251] (psListAppend (psWasmEncodeUleb 14) (psWasmEncodeUleb typeIndex)))
  | .arrayLen =>
      Except.ok
        (psListAppend [psWasmByte 251] (psWasmEncodeUleb 15))
  | .arrayCopy destinationType sourceType =>
      match
          psWasmFindHeapTypeIndex
            structures
            arrays
            destinationType with
      | none =>
          Except.error
            (PsWasmEncodeError.unknownStructure destinationType)
      | some destinationIndex =>
          match
              psWasmFindHeapTypeIndex
                structures
                arrays
                sourceType with
          | none =>
              Except.error
                (PsWasmEncodeError.unknownStructure sourceType)
          | some sourceIndex =>
              Except.ok
                (psListAppend [psWasmByte 251] (psListAppend (psWasmEncodeUleb 17) (psListAppend (psWasmEncodeUleb destinationIndex) (psWasmEncodeUleb sourceIndex))))
  | .refTest typeName =>
      match psWasmFindStructureIndex structures typeName with
      | none =>
          Except.error (PsWasmEncodeError.unknownStructure typeName)
      | some typeIndex =>
          Except.ok
            (psListAppend [psWasmByte 251] (psListAppend (psWasmEncodeUleb 20) (psWasmEncodeSleb (Int.ofNat typeIndex))))
  | .refCast typeName =>
      match psWasmFindStructureIndex structures typeName with
      | none =>
          Except.error (PsWasmEncodeError.unknownStructure typeName)
      | some typeIndex =>
          Except.ok
            (psListAppend [psWasmByte 251] (psListAppend (psWasmEncodeUleb 22) (psWasmEncodeSleb (Int.ofNat typeIndex))))
  | .refFunc functionName =>
      match psWasmFindFunctionIndex functions functionName with
      | none =>
          Except.error (PsWasmEncodeError.unknownFunction functionName)
      | some functionIndex =>
          Except.ok
            (psListAppend [psWasmByte 210] (psWasmEncodeUleb functionIndex))
  | .refCastFunction typeName =>
      match
          psWasmFindFunctionTypeIndex
            structures
            arrays
            functionTypes
            typeName with
      | none =>
          Except.error (PsWasmEncodeError.unknownFunctionType typeName)
      | some typeIndex =>
          Except.ok
            (psListAppend [psWasmByte 251] (psListAppend (psWasmEncodeUleb 22) (psWasmEncodeSleb (Int.ofNat typeIndex))))
  | .callRef typeName =>
      match
          psWasmFindFunctionTypeIndex
            structures
            arrays
            functionTypes
            typeName with
      | none =>
          Except.error (PsWasmEncodeError.unknownFunctionType typeName)
      | some typeIndex =>
          Except.ok
            (psListAppend [psWasmByte 20] (psWasmEncodeUleb typeIndex))
  | .f32ConstBits _ =>
      Except.error PsWasmEncodeError.unsupportedInstruction
  | .f64ConstBits _ =>
      Except.error PsWasmEncodeError.unsupportedInstruction

def psWasmEncodeInstructions
    (structures : List PsWasmStructType)
    (arrays : List PsWasmArrayType)
    (functionTypes : List PsWasmFunctionType)
    (functions : List PsWasmFunction)
    (instructions : List PsWasmInstruction) :
    Except PsWasmEncodeError (List UInt8) :=
  match instructions with
  | List.nil => Except.ok []
  | List.cons instruction rest =>
      match psWasmEncodeInstruction
          structures
          arrays
          functionTypes
          functions
          instruction with
      | Except.error error => Except.error error
      | Except.ok encoded =>
          match psWasmEncodeInstructions
              structures
              arrays
              functionTypes
              functions
              rest with
          | Except.error error => Except.error error
          | Except.ok encodedRest =>
              Except.ok (psListAppend encoded encodedRest)

def psWasmEncodeLocalDeclarations
    (structures : List PsWasmStructType)
    (arrays : List PsWasmArrayType)
    (types : List PsWasmValueType) :
    Except PsWasmEncodeError (List UInt8) :=
  match types with
  | List.nil => Except.ok []
  | List.cons type rest =>
      match psWasmEncodeValueType structures arrays type with
      | Except.error error => Except.error error
      | Except.ok encodedType =>
          match psWasmEncodeLocalDeclarations structures arrays rest with
          | Except.error error => Except.error error
          | Except.ok encodedRest =>
              Except.ok
                (psListAppend (psWasmEncodeUleb 1) (psListAppend encodedType encodedRest))

def psWasmEncodeFunctionBody
    (structures : List PsWasmStructType)
    (arrays : List PsWasmArrayType)
    (functionTypes : List PsWasmFunctionType)
    (functions : List PsWasmFunction)
    (function : PsWasmFunction) :
    Except PsWasmEncodeError (List UInt8) :=
  match
      psWasmEncodeLocalDeclarations
        structures
        arrays
        function.locals with
  | Except.error error => Except.error error
  | Except.ok encodedLocals =>
      match psWasmEncodeInstructions
          structures
          arrays
          functionTypes
          functions
          function.body with
      | Except.error error => Except.error error
      | Except.ok instructions =>
          let body :=
            psListAppend
              (psWasmEncodeUleb function.locals.length)
              (psListAppend
                encodedLocals
                (psListAppend
                  instructions
                  [psWasmByte 11]));
          Except.ok (psListAppend (psWasmEncodeUleb body.length) body)

def psWasmEncodeFunctionBodies
    (structures : List PsWasmStructType)
    (arrays : List PsWasmArrayType)
    (functionTypes : List PsWasmFunctionType)
    (functions : List PsWasmFunction)
    (functionsToEncode : List PsWasmFunction) :
    Except PsWasmEncodeError (List UInt8) :=
  match functionsToEncode with
  | List.nil => Except.ok []
  | List.cons function rest =>
      match psWasmEncodeFunctionBody
          structures
          arrays
          functionTypes
          functions
          function with
      | Except.error error => Except.error error
      | Except.ok encoded =>
          match psWasmEncodeFunctionBodies
              structures
              arrays
              functionTypes
              functions
              rest with
          | Except.error error => Except.error error
          | Except.ok encodedRest =>
              Except.ok (psListAppend encoded encodedRest)

def psWasmEncodeStorageType
    (structures : List PsWasmStructType)
    (arrays : List PsWasmArrayType)
    (type : PsWasmStorageType) :
    Except PsWasmEncodeError (List UInt8) :=
  match type with
  | .packedI8 => Except.ok [psWasmByte 120]
  | .packedI16 => Except.ok [psWasmByte 119]
  | .value valueType =>
      psWasmEncodeValueType structures arrays valueType

def psWasmEncodeStructField
    (structures : List PsWasmStructType)
    (arrays : List PsWasmArrayType)
    (field : PsWasmStructField) :
    Except PsWasmEncodeError (List UInt8) :=
  match psWasmEncodeStorageType structures arrays field.storageType with
  | Except.error error => Except.error error
  | Except.ok storage =>
      Except.ok (psListAppend storage [psWasmByte 0])

def psWasmEncodeStructFields
    (structures : List PsWasmStructType)
    (arrays : List PsWasmArrayType)
    (fields : List PsWasmStructField) :
    Except PsWasmEncodeError (List UInt8) :=
  match fields with
  | List.nil => Except.ok []
  | List.cons field rest =>
      match psWasmEncodeStructField structures arrays field with
      | Except.error error => Except.error error
      | Except.ok encoded =>
          match psWasmEncodeStructFields structures arrays rest with
          | Except.error error => Except.error error
          | Except.ok encodedRest =>
              Except.ok (psListAppend encoded encodedRest)

def psWasmEncodeStructCompositeType
    (structures : List PsWasmStructType)
    (arrays : List PsWasmArrayType)
    (structType : PsWasmStructType) :
    Except PsWasmEncodeError (List UInt8) :=
  match psWasmEncodeStructFields structures arrays structType.fields with
  | Except.error error => Except.error error
  | Except.ok fields =>
      Except.ok
        (psListAppend [psWasmByte 95] (psListAppend (psWasmEncodeUleb structType.fields.length) fields))

def psWasmEncodeStructType
    (structures : List PsWasmStructType)
    (arrays : List PsWasmArrayType)
    (structType : PsWasmStructType) :
    Except PsWasmEncodeError (List UInt8) :=
  match psWasmEncodeStructCompositeType structures arrays structType with
  | Except.error error => Except.error error
  | Except.ok composite =>
      match structType.superType with
      | none =>
          if structType.isFinal then
            Except.ok composite
          else
            Except.ok
              (psListAppend [psWasmByte 80] (psListAppend (psWasmEncodeUleb 0) composite))
      | some superName =>
          match psWasmFindStructureIndex structures superName with
          | none =>
              Except.error (PsWasmEncodeError.unknownStructure superName)
          | some superIndex =>
              let subtypeTag :=
                if structType.isFinal then
                  psWasmByte 79
                else
                  psWasmByte 80;
              Except.ok
                (psListAppend [subtypeTag] (psListAppend (psWasmEncodeUleb 1) (psListAppend (psWasmEncodeUleb superIndex) composite)))

def psWasmEncodeStructTypes
    (structures : List PsWasmStructType)
    (arrays : List PsWasmArrayType)
    (structTypes : List PsWasmStructType) :
    Except PsWasmEncodeError (List UInt8) :=
  match structTypes with
  | List.nil => Except.ok []
  | List.cons structType rest =>
      match psWasmEncodeStructType structures arrays structType with
      | Except.error error => Except.error error
      | Except.ok encoded =>
          match psWasmEncodeStructTypes structures arrays rest with
          | Except.error error => Except.error error
          | Except.ok encodedRest =>
              Except.ok (psListAppend encoded encodedRest)

def psWasmEncodeArrayType
    (structures : List PsWasmStructType)
    (arrays : List PsWasmArrayType)
    (arrayType : PsWasmArrayType) :
    Except PsWasmEncodeError (List UInt8) :=
  match
      psWasmEncodeStorageType
        structures
        arrays
        arrayType.elementType with
  | Except.error error => Except.error error
  | Except.ok elementType =>
      let mutability :=
        if arrayType.mutable then psWasmByte 1
        else psWasmByte 0;
      Except.ok
        (psListAppend [psWasmByte 94] (psListAppend elementType [mutability]))

def psWasmEncodeArrayTypes
    (structures : List PsWasmStructType)
    (arrays : List PsWasmArrayType)
    (arrayTypes : List PsWasmArrayType) :
    Except PsWasmEncodeError (List UInt8) :=
  match arrayTypes with
  | List.nil => Except.ok []
  | List.cons arrayType rest =>
      match
          psWasmEncodeArrayType
            structures
            arrays
            arrayType with
      | Except.error error => Except.error error
      | Except.ok encoded =>
          match
              psWasmEncodeArrayTypes
                structures
                arrays
                rest with
          | Except.error error => Except.error error
          | Except.ok encodedRest =>
              Except.ok (psListAppend encoded encodedRest)

def psWasmFunctionTypeIndex
    (structures : List PsWasmStructType)
    (arrays : List PsWasmArrayType)
    (functionTypes : List PsWasmFunctionType)
    (functionIndex : Nat)
    (function : PsWasmFunction) :
    Except PsWasmEncodeError Nat :=
  match function.typeName with
  | none =>
      Except.ok
        (structures.length
          + arrays.length
          + functionTypes.length
          + functionIndex)
  | some typeName =>
      match
          psWasmFindFunctionTypeIndex
            structures
            arrays
            functionTypes
            typeName with
      | none =>
          Except.error
            (PsWasmEncodeError.unknownFunctionType typeName)
      | some typeIndex => Except.ok typeIndex

def psWasmEncodeFunctionTypeIndicesLoop
    (structures : List PsWasmStructType)
    (arrays : List PsWasmArrayType)
    (functionTypes : List PsWasmFunctionType)
    (functionIndex : Nat)
    (functions : List PsWasmFunction) :
    Except PsWasmEncodeError (List UInt8) :=
  match functions with
  | List.nil => Except.ok List.nil
  | List.cons function rest =>
      match
          psWasmFunctionTypeIndex
            structures
            arrays
            functionTypes
            functionIndex
            function with
      | Except.error error => Except.error error
      | Except.ok typeIndex =>
          match
              psWasmEncodeFunctionTypeIndicesLoop
                structures
                arrays
                functionTypes
                (functionIndex + 1)
                rest with
          | Except.error error => Except.error error
          | Except.ok encodedRest =>
              Except.ok
                (psListAppend (psWasmEncodeUleb typeIndex) encodedRest)

def psWasmEncodeFunctionTypeIndices
    (structures : List PsWasmStructType)
    (arrays : List PsWasmArrayType)
    (functionTypes : List PsWasmFunctionType)
    (functions : List PsWasmFunction) :
    Except PsWasmEncodeError (List UInt8) :=
  psWasmEncodeFunctionTypeIndicesLoop
    structures arrays functionTypes 0 functions

def psWasmEncodeFunctionRefIndices
    (functions : List PsWasmFunction)
    (names : List String) :
    Except PsWasmEncodeError (List UInt8) :=
  match names with
  | List.nil => Except.ok []
  | List.cons name rest =>
      match psWasmFindFunctionIndex functions name with
      | none =>
          Except.error (PsWasmEncodeError.unknownFunction name)
      | some index =>
          match psWasmEncodeFunctionRefIndices functions rest with
          | Except.error error => Except.error error
          | Except.ok encodedRest =>
              Except.ok
                (psListAppend (psWasmEncodeUleb index) encodedRest)

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
            psListAppend
              (psWasmEncodeUleb 3)
              (psListAppend
                [psWasmByte 0]
                (psWasmEncodeVector
                  indices
                  functionRefs.length));
          Except.ok
            (psWasmEncodeVector segment 1)

def psWasmEncodeExports
    (functions : List PsWasmFunction)
    (exports : List (String × String)) :
    Except PsWasmEncodeError (List UInt8) :=
  match exports with
  | List.nil => Except.ok []
  | List.cons exportItem rest =>
      match psWasmFindFunctionIndex functions (Prod.snd exportItem) with
      | none =>
          Except.error (PsWasmEncodeError.unknownFunction (Prod.snd exportItem))
      | some index =>
          match psWasmEncodeExports functions rest with
          | Except.error error => Except.error error
          | Except.ok encodedRest =>
              Except.ok
                (psListAppend (psWasmEncodeName (Prod.fst exportItem)) (psListAppend [psWasmByte 0] (psListAppend (psWasmEncodeUleb index) encodedRest)))

def psWasmEncodeSection
    (sectionId : Nat)
    (payload : List UInt8) : List UInt8 :=
  psListAppend
    [psWasmByte sectionId]
    (psListAppend
      (psWasmEncodeUleb payload.length)
      payload)

def psWasmEncodeModule
    (module : PsWasmModule) :
    Except PsWasmEncodeError (List UInt8) :=
  match
      psWasmEncodeStructTypes
        module.structures
        module.arrays
        module.structures with
  | Except.error error => Except.error error
  | Except.ok encodedStructTypes =>
      match
          psWasmEncodeArrayTypes
            module.structures
            module.arrays
            module.arrays with
      | Except.error error => Except.error error
      | Except.ok encodedArrayTypes =>
          match
              psWasmEncodeNamedFunctionTypes
                module.structures
                module.arrays
                module.functionTypes with
          | Except.error error => Except.error error
          | Except.ok encodedNamedFunctionTypes =>
              match
                  psWasmEncodeFunctionTypes
                    module.structures
                    module.arrays
                    module.functions with
              | Except.error error => Except.error error
              | Except.ok encodedFunctionTypes =>
                  match
                      psWasmEncodeFunctionTypeIndices
                        module.structures
                        module.arrays
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
                                    module.arrays
                                    module.functionTypes
                                    module.functions
                                    module.functions with
                              | Except.error error => Except.error error
                              | Except.ok encodedBodies =>
                                  let typeCount :=
                                    module.structures.length
                                      + module.arrays.length
                                      + module.functionTypes.length
                                      + module.functions.length;
                                  let typePayload :=
                                    psWasmEncodeVector
                                      (psListAppend encodedStructTypes (psListAppend encodedArrayTypes (psListAppend encodedNamedFunctionTypes encodedFunctionTypes)))
                                      typeCount;
                                  let functionPayload :=
                                    psWasmEncodeVector
                                      encodedFunctionTypeIndices
                                      module.functions.length;
                                  let exportPayload :=
                                    psWasmEncodeVector
                                      encodedExports
                                      module.exports.length;
                                  let elementSection :=
                                    match module.functionRefs with
                                    | [] => []
                                    | _ =>
                                        psWasmEncodeSection
                                          9
                                          encodedFunctionRefs;
                                  let codePayload :=
                                    psWasmEncodeVector
                                      encodedBodies
                                      module.functions.length;
                                  Except.ok
                                    (psListAppend [
                                      psWasmByte 0,
                                      psWasmByte 97,
                                      psWasmByte 115,
                                      psWasmByte 109,
                                      psWasmByte 1,
                                      psWasmByte 0,
                                      psWasmByte 0,
                                      psWasmByte 0
                                    ] (psListAppend (psWasmEncodeSection 1 typePayload) (psListAppend (psWasmEncodeSection 3 functionPayload) (psListAppend (psWasmEncodeSection 7 exportPayload) (psListAppend elementSection (psWasmEncodeSection 10 codePayload))))))