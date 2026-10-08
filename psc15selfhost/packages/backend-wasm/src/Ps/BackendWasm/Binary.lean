import Ps.BackendWasm.Model
import Ps.BackendWasm.IntUtil
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

def psWasmEncodeUlebWithFuel
    (remainingFuel : Nat) : Nat -> List UInt8 :=
  match remainingFuel with
  | 0 =>
      fun (_value : Nat) => List.nil
  | fuel + 1 =>
      let smaller : Nat -> List UInt8 :=
        psWasmEncodeUlebWithFuel fuel;
      fun (value : Nat) =>
        let low := Nat.mod value 128;
        let rest := Nat.div value 128;
        if Nat.beq rest 0 then
          [psWasmByte low]
        else
          List.cons
            (psWasmByte (Nat.add low 128))
            (smaller rest)

def psWasmEncodeUleb (value : Nat) : List UInt8 :=
  psWasmEncodeUlebWithFuel 16 value

def psWasmEncodeSlebWithFuel
    (remainingFuel : Nat) : Int -> List UInt8 :=
  match remainingFuel with
  | 0 =>
      fun (_value : Int) => List.nil
  | fuel + 1 =>
      let smaller : Int -> List UInt8 :=
        psWasmEncodeSlebWithFuel fuel;
      fun (value : Int) =>
        let lowInt := psWasmIntEModNat value 128;
        let low := psWasmIntToNat lowInt;
        let rest := psWasmIntEDivNat value 128;
        let signSet := Nat.ble 64 low;
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
            (psWasmByte (Nat.add low 128))
            (smaller rest)

def psWasmEncodeSleb (value : Int) : List UInt8 :=
  psWasmEncodeSlebWithFuel 16 value

def psWasmNormalizeI32Immediate (value : Int) : Int :=
  let reduced := psWasmIntEModNat value 4294967296;
  if Nat.ble 2147483648 (psWasmIntToNat reduced) then
    Int.sub reduced (Int.ofNat 4294967296)
  else
    reduced

def psWasmNormalizeI64Immediate (value : Int) : Int :=
  let reduced := psWasmIntEModNat value 18446744073709551616;
  if Nat.ble 9223372036854775808 (psWasmIntToNat reduced) then
    Int.sub reduced (Int.ofNat 18446744073709551616)
  else
    reduced

def psWasmEncodeI32Constant (value : Int) : List UInt8 :=
  psWasmEncodeSleb (psWasmNormalizeI32Immediate value)

def psWasmEncodeI64Constant (value : Int) : List UInt8 :=
  psWasmEncodeSleb (psWasmNormalizeI64Immediate value)

def psWasmStringToListFromWithFuel
    (remainingFuel : Nat) : String -> Nat -> List Char :=
  match remainingFuel with
  | Nat.zero =>
      fun (_source : String) =>
        fun (_position : Nat) =>
          List.nil
  | Nat.succ fuel =>
      let smaller : String -> Nat -> List Char :=
        psWasmStringToListFromWithFuel fuel;
      fun (source : String) =>
        fun (position : Nat) =>
          if
              String.Internal.atEnd
                source
                (String.Pos.Raw.mk position) then
            List.nil
          else
            let char : Char :=
              String.Internal.get
                source
                (String.Pos.Raw.mk position);
            let nextPosition : Nat :=
              String.Pos.Raw.byteIdx
                (String.Internal.next
                  source
                  (String.Pos.Raw.mk position));
            List.cons char (smaller source nextPosition)

def psWasmStringToListFrom
    (source : String)
    (position : Nat) : List Char :=
  psWasmStringToListFromWithFuel
    (Nat.succ (String.utf8ByteSize source))
    source
    position

def psWasmStringToList (source : String) : List Char :=
  psWasmStringToListFrom source 0

def psWasmEncodeUtf8Char (char : Char) : List UInt8 :=
  let value := Char.toNat char;
  if Nat.ble value 127 then
    [psWasmByte value]
  else if Nat.ble value 2047 then
    [
      psWasmByte (Nat.add 192 (Nat.div value 64)),
      psWasmByte (Nat.add 128 (Nat.mod value 64))
    ]
  else if Nat.ble value 65535 then
    [
      psWasmByte (Nat.add 224 (Nat.div value 4096)),
      psWasmByte
        (Nat.add 128 (Nat.mod (Nat.div value 64) 64)),
      psWasmByte (Nat.add 128 (Nat.mod value 64))
    ]
  else
    [
      psWasmByte (Nat.add 240 (Nat.div value 262144)),
      psWasmByte
        (Nat.add 128 (Nat.mod (Nat.div value 4096) 64)),
      psWasmByte
        (Nat.add 128 (Nat.mod (Nat.div value 64) 64)),
      psWasmByte (Nat.add 128 (Nat.mod value 64))
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
  let bytes := psWasmEncodeUtf8Chars (psWasmStringToList name);
  psListAppend
    (psWasmEncodeUleb (psListLength bytes))
    bytes

def psWasmFindStructureIndexWorker
    (name : String)
    (structures : List PsWasmStructType) :
    Nat -> Option Nat :=
  match structures with
  | List.nil =>
      fun (_index : Nat) => Option.none
  | List.cons structType rest =>
      let smaller : Nat -> Option Nat :=
        psWasmFindStructureIndexWorker name rest;
      fun (index : Nat) =>
        if psStringEq structType.name name then
          Option.some index
        else
          smaller (Nat.add index 1)

def psWasmFindStructureIndexLoop
    (name : String)
    (index : Nat)
    (structures : List PsWasmStructType) : Option Nat :=
  psWasmFindStructureIndexWorker name structures index

def psWasmFindStructureIndex
    (structures : List PsWasmStructType)
    (name : String) : Option Nat :=
  psWasmFindStructureIndexLoop name 0 structures

def psWasmFindArrayIndexWorker
    (name : String)
    (arrays : List PsWasmArrayType) :
    Nat -> Option Nat :=
  match arrays with
  | List.nil =>
      fun (_index : Nat) => Option.none
  | List.cons arrayType rest =>
      let smaller : Nat -> Option Nat :=
        psWasmFindArrayIndexWorker name rest;
      fun (index : Nat) =>
        if psStringEq arrayType.name name then
          Option.some index
        else
          smaller (Nat.add index 1)

def psWasmFindArrayIndexLoop
    (name : String)
    (index : Nat)
    (arrays : List PsWasmArrayType) : Option Nat :=
  psWasmFindArrayIndexWorker name arrays index

def psWasmFindArrayIndex
    (arrays : List PsWasmArrayType)
    (name : String) : Option Nat :=
  psWasmFindArrayIndexLoop name 0 arrays

def psWasmFindHeapTypeIndex
    (structures : List PsWasmStructType)
    (arrays : List PsWasmArrayType)
    (name : String) : Option Nat :=
  match psWasmFindStructureIndex structures name with
  | Option.some index => Option.some index
  | Option.none =>
      match psWasmFindArrayIndex arrays name with
      | Option.none => Option.none
      | Option.some index =>
          Option.some (Nat.add (psListLength structures) index)

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
      | Option.none =>
          Except.error (PsWasmEncodeError.unknownStructure name)
      | Option.some index =>
          Except.ok
            (psListAppend [psWasmByte 100] (psWasmEncodeSleb (Int.ofNat index)))
  | .funcRef => Except.ok [psWasmByte 112]
  | .noValue => Except.error PsWasmEncodeError.unsupportedValueType

def psWasmEncodeValueTypes
    (structures : List PsWasmStructType)
    (arrays : List PsWasmArrayType)
    (types : List PsWasmValueType) :
    Except PsWasmEncodeError (List UInt8) :=
  psListFlatMapExcept
    (psWasmEncodeValueType structures arrays)
    types

def psWasmEncodeVector
    (bytes : List UInt8)
    (count : Nat) : List UInt8 :=
  psListAppend
    (psWasmEncodeUleb count)
    bytes

def psWasmFindFunctionTypeIndexWorker
    (name : String)
    (functionTypes : List PsWasmFunctionType) :
    Nat -> Option Nat :=
  match functionTypes with
  | List.nil =>
      fun (_index : Nat) => Option.none
  | List.cons functionType rest =>
      let smaller : Nat -> Option Nat :=
        psWasmFindFunctionTypeIndexWorker name rest;
      fun (index : Nat) =>
        if psStringEq functionType.name name then
          Option.some index
        else
          smaller (Nat.add index 1)

def psWasmFindFunctionTypeIndexLoop
    (name : String)
    (index : Nat)
    (functionTypes : List PsWasmFunctionType) : Option Nat :=
  psWasmFindFunctionTypeIndexWorker name functionTypes index

def psWasmFindFunctionTypeIndex
    (structures : List PsWasmStructType)
    (arrays : List PsWasmArrayType)
    (functionTypes : List PsWasmFunctionType)
    (name : String) : Option Nat :=
  match psWasmFindFunctionTypeIndexLoop name 0 functionTypes with
  | Option.none => Option.none
  | Option.some index =>
      Option.some
        (Nat.add
          (Nat.add
            (psListLength structures)
            (psListLength arrays))
          index)

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
                (psListLength functionType.parameters)) (psWasmEncodeVector
                results
                (psListLength functionType.results))))

def psWasmEncodeNamedFunctionTypes
    (structures : List PsWasmStructType)
    (arrays : List PsWasmArrayType)
    (functionTypesToEncode : List PsWasmFunctionType) :
    Except PsWasmEncodeError (List UInt8) :=
  psListFlatMapExcept
    (psWasmEncodeNamedFunctionType structures arrays)
    functionTypesToEncode

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
            (psListAppend [psWasmByte 96] (psListAppend (psWasmEncodeVector parameters (psListLength function.parameters)) (psWasmEncodeVector results (psListLength function.results))))

def psWasmEncodeFunctionTypes
    (structures : List PsWasmStructType)
    (arrays : List PsWasmArrayType)
    (functionsToEncode : List PsWasmFunction) :
    Except PsWasmEncodeError (List UInt8) :=
  psListFlatMapExcept
    (psWasmEncodeFunctionType structures arrays)
    functionsToEncode

def psWasmFindFunctionIndexWorker
    (name : String)
    (functions : List PsWasmFunction) :
    Nat -> Option Nat :=
  match functions with
  | List.nil =>
      fun (_index : Nat) => Option.none
  | List.cons function rest =>
      let smaller : Nat -> Option Nat :=
        psWasmFindFunctionIndexWorker name rest;
      fun (index : Nat) =>
        if psStringEq function.name name then
          Option.some index
        else
          smaller (Nat.add index 1)

def psWasmFindFunctionIndexLoop
    (name : String)
    (index : Nat)
    (functions : List PsWasmFunction) : Option Nat :=
  psWasmFindFunctionIndexWorker name functions index

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
      | Option.none => Except.error (PsWasmEncodeError.unknownFunction name)
      | Option.some index =>
          Except.ok
            (List.cons
              (psWasmByte 16)
              (psWasmEncodeUleb index))
  | .returnCall name =>
      match psWasmFindFunctionIndex functions name with
      | Option.none => Except.error (PsWasmEncodeError.unknownFunction name)
      | Option.some index =>
          Except.ok
            (List.cons
              (psWasmByte 18)
              (psWasmEncodeUleb index))
  | .return_ => Except.ok [psWasmByte 15]
  | .ifStart result =>
      match result with
      | Option.none =>
          Except.ok [psWasmByte 4, psWasmByte 64]
      | Option.some valueType =>
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
      | Option.none =>
          Except.error (PsWasmEncodeError.unknownStructure typeName)
      | Option.some typeIndex =>
          Except.ok
            (psListAppend [psWasmByte 251] (psListAppend (psWasmEncodeUleb 0) (psWasmEncodeUleb typeIndex)))
  | .structGet typeName fieldIndex =>
      match psWasmFindStructureIndex structures typeName with
      | Option.none =>
          Except.error (PsWasmEncodeError.unknownStructure typeName)
      | Option.some typeIndex =>
          Except.ok
            (psListAppend [psWasmByte 251] (psListAppend (psWasmEncodeUleb 2) (psListAppend (psWasmEncodeUleb typeIndex) (psWasmEncodeUleb fieldIndex))))
  | .structGetS typeName fieldIndex =>
      match psWasmFindStructureIndex structures typeName with
      | Option.none =>
          Except.error (PsWasmEncodeError.unknownStructure typeName)
      | Option.some typeIndex =>
          Except.ok
            (psListAppend [psWasmByte 251] (psListAppend (psWasmEncodeUleb 3) (psListAppend (psWasmEncodeUleb typeIndex) (psWasmEncodeUleb fieldIndex))))
  | .structGetU typeName fieldIndex =>
      match psWasmFindStructureIndex structures typeName with
      | Option.none =>
          Except.error (PsWasmEncodeError.unknownStructure typeName)
      | Option.some typeIndex =>
          Except.ok
            (psListAppend [psWasmByte 251] (psListAppend (psWasmEncodeUleb 4) (psListAppend (psWasmEncodeUleb typeIndex) (psWasmEncodeUleb fieldIndex))))
  | .arrayNew typeName =>
      match psWasmFindHeapTypeIndex structures arrays typeName with
      | Option.none =>
          Except.error (PsWasmEncodeError.unknownStructure typeName)
      | Option.some typeIndex =>
          Except.ok
            (psListAppend [psWasmByte 251] (psListAppend (psWasmEncodeUleb 6) (psWasmEncodeUleb typeIndex)))
  | .arrayNewDefault typeName =>
      match psWasmFindHeapTypeIndex structures arrays typeName with
      | Option.none =>
          Except.error (PsWasmEncodeError.unknownStructure typeName)
      | Option.some typeIndex =>
          Except.ok
            (psListAppend [psWasmByte 251] (psListAppend (psWasmEncodeUleb 7) (psWasmEncodeUleb typeIndex)))
  | .arrayNewFixed typeName length =>
      match psWasmFindHeapTypeIndex structures arrays typeName with
      | Option.none =>
          Except.error (PsWasmEncodeError.unknownStructure typeName)
      | Option.some typeIndex =>
          Except.ok
            (psListAppend [psWasmByte 251] (psListAppend (psWasmEncodeUleb 8) (psListAppend (psWasmEncodeUleb typeIndex) (psWasmEncodeUleb length))))
  | .arrayGet typeName =>
      match psWasmFindHeapTypeIndex structures arrays typeName with
      | Option.none =>
          Except.error (PsWasmEncodeError.unknownStructure typeName)
      | Option.some typeIndex =>
          Except.ok
            (psListAppend [psWasmByte 251] (psListAppend (psWasmEncodeUleb 11) (psWasmEncodeUleb typeIndex)))
  | .arrayGetS typeName =>
      match psWasmFindHeapTypeIndex structures arrays typeName with
      | Option.none =>
          Except.error (PsWasmEncodeError.unknownStructure typeName)
      | Option.some typeIndex =>
          Except.ok
            (psListAppend [psWasmByte 251] (psListAppend (psWasmEncodeUleb 12) (psWasmEncodeUleb typeIndex)))
  | .arrayGetU typeName =>
      match psWasmFindHeapTypeIndex structures arrays typeName with
      | Option.none =>
          Except.error (PsWasmEncodeError.unknownStructure typeName)
      | Option.some typeIndex =>
          Except.ok
            (psListAppend [psWasmByte 251] (psListAppend (psWasmEncodeUleb 13) (psWasmEncodeUleb typeIndex)))
  | .arraySet typeName =>
      match psWasmFindHeapTypeIndex structures arrays typeName with
      | Option.none =>
          Except.error (PsWasmEncodeError.unknownStructure typeName)
      | Option.some typeIndex =>
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
      | Option.none =>
          Except.error
            (PsWasmEncodeError.unknownStructure destinationType)
      | Option.some destinationIndex =>
          match
              psWasmFindHeapTypeIndex
                structures
                arrays
                sourceType with
          | Option.none =>
              Except.error
                (PsWasmEncodeError.unknownStructure sourceType)
          | Option.some sourceIndex =>
              Except.ok
                (psListAppend [psWasmByte 251] (psListAppend (psWasmEncodeUleb 17) (psListAppend (psWasmEncodeUleb destinationIndex) (psWasmEncodeUleb sourceIndex))))
  | .refTest typeName =>
      match psWasmFindStructureIndex structures typeName with
      | Option.none =>
          Except.error (PsWasmEncodeError.unknownStructure typeName)
      | Option.some typeIndex =>
          Except.ok
            (psListAppend [psWasmByte 251] (psListAppend (psWasmEncodeUleb 20) (psWasmEncodeSleb (Int.ofNat typeIndex))))
  | .refCast typeName =>
      match psWasmFindStructureIndex structures typeName with
      | Option.none =>
          Except.error (PsWasmEncodeError.unknownStructure typeName)
      | Option.some typeIndex =>
          Except.ok
            (psListAppend [psWasmByte 251] (psListAppend (psWasmEncodeUleb 22) (psWasmEncodeSleb (Int.ofNat typeIndex))))
  | .refFunc functionName =>
      match psWasmFindFunctionIndex functions functionName with
      | Option.none =>
          Except.error (PsWasmEncodeError.unknownFunction functionName)
      | Option.some functionIndex =>
          Except.ok
            (psListAppend [psWasmByte 210] (psWasmEncodeUleb functionIndex))
  | .refCastFunction typeName =>
      match
          psWasmFindFunctionTypeIndex
            structures
            arrays
            functionTypes
            typeName with
      | Option.none =>
          Except.error (PsWasmEncodeError.unknownFunctionType typeName)
      | Option.some typeIndex =>
          Except.ok
            (psListAppend [psWasmByte 251] (psListAppend (psWasmEncodeUleb 22) (psWasmEncodeSleb (Int.ofNat typeIndex))))
  | .callRef typeName =>
      match
          psWasmFindFunctionTypeIndex
            structures
            arrays
            functionTypes
            typeName with
      | Option.none =>
          Except.error (PsWasmEncodeError.unknownFunctionType typeName)
      | Option.some typeIndex =>
          Except.ok
            (psListAppend [psWasmByte 20] (psWasmEncodeUleb typeIndex))
  | .returnCallRef typeName =>
      match
          psWasmFindFunctionTypeIndex
            structures
            arrays
            functionTypes
            typeName with
      | Option.none =>
          Except.error (PsWasmEncodeError.unknownFunctionType typeName)
      | Option.some typeIndex =>
          Except.ok
            (psListAppend [psWasmByte 21] (psWasmEncodeUleb typeIndex))
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
  psListFlatMapExcept
    (psWasmEncodeInstruction structures arrays functionTypes functions)
    instructions

def psWasmEncodeLocalDeclaration
    (structures : List PsWasmStructType)
    (arrays : List PsWasmArrayType)
    (type : PsWasmValueType) :
    Except PsWasmEncodeError (List UInt8) :=
  match psWasmEncodeValueType structures arrays type with
  | Except.error error => Except.error error
  | Except.ok encoded => Except.ok (List.cons (psWasmByte 1) encoded)

def psWasmEncodeLocalDeclarations
    (structures : List PsWasmStructType)
    (arrays : List PsWasmArrayType)
    (types : List PsWasmValueType) :
    Except PsWasmEncodeError (List UInt8) :=
  psListFlatMapExcept (psWasmEncodeLocalDeclaration structures arrays) types

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
              (psWasmEncodeUleb (psListLength function.locals))
              (psListAppend
                encodedLocals
                (psListAppend
                  instructions
                  [psWasmByte 11]));
          Except.ok (psListAppend (psWasmEncodeUleb (psListLength body)) body)

def psWasmEncodeFunctionBodies
    (structures : List PsWasmStructType)
    (arrays : List PsWasmArrayType)
    (functionTypes : List PsWasmFunctionType)
    (functions : List PsWasmFunction)
    (functionsToEncode : List PsWasmFunction) :
    Except PsWasmEncodeError (List UInt8) :=
  psListFlatMapExcept
    (psWasmEncodeFunctionBody structures arrays functionTypes functions)
    functionsToEncode

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
  psListFlatMapExcept
    (psWasmEncodeStructField structures arrays)
    fields

def psWasmEncodeStructCompositeType
    (structures : List PsWasmStructType)
    (arrays : List PsWasmArrayType)
    (structType : PsWasmStructType) :
    Except PsWasmEncodeError (List UInt8) :=
  match psWasmEncodeStructFields structures arrays structType.fields with
  | Except.error error => Except.error error
  | Except.ok fields =>
      Except.ok
        (psListAppend [psWasmByte 95] (psListAppend (psWasmEncodeUleb (psListLength structType.fields)) fields))

def psWasmEncodeStructType
    (structures : List PsWasmStructType)
    (arrays : List PsWasmArrayType)
    (structType : PsWasmStructType) :
    Except PsWasmEncodeError (List UInt8) :=
  match psWasmEncodeStructCompositeType structures arrays structType with
  | Except.error error => Except.error error
  | Except.ok composite =>
      match structType.superType with
      | Option.none =>
          if structType.isFinal then
            Except.ok composite
          else
            Except.ok
              (psListAppend [psWasmByte 80] (psListAppend (psWasmEncodeUleb 0) composite))
      | Option.some superName =>
          match psWasmFindStructureIndex structures superName with
          | Option.none =>
              Except.error (PsWasmEncodeError.unknownStructure superName)
          | Option.some superIndex =>
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
  psListFlatMapExcept
    (psWasmEncodeStructType structures arrays)
    structTypes

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
  psListFlatMapExcept
    (psWasmEncodeArrayType structures arrays)
    arrayTypes

def psWasmFunctionTypeIndex
    (structures : List PsWasmStructType)
    (arrays : List PsWasmArrayType)
    (functionTypes : List PsWasmFunctionType)
    (functionIndex : Nat)
    (function : PsWasmFunction) :
    Except PsWasmEncodeError Nat :=
  match function.typeName with
  | Option.none =>
      Except.ok
        (Nat.add
          (Nat.add
            (Nat.add
              (psListLength structures)
              (psListLength arrays))
            (psListLength functionTypes))
          functionIndex)
  | Option.some typeName =>
      match
          psWasmFindFunctionTypeIndex
            structures
            arrays
            functionTypes
            typeName with
      | Option.none =>
          Except.error
            (PsWasmEncodeError.unknownFunctionType typeName)
      | Option.some typeIndex => Except.ok typeIndex

def psWasmEncodeFunctionTypeIndicesAcc
    (structures : List PsWasmStructType)
    (arrays : List PsWasmArrayType)
    (functionTypes : List PsWasmFunctionType)
    (functions : List PsWasmFunction) :
    Nat -> List UInt8 -> Except PsWasmEncodeError (List UInt8) :=
  match functions with
  | List.nil =>
      fun (_functionIndex : Nat) =>
        fun (reversed : List UInt8) => Except.ok (psListReverse reversed)
  | List.cons function rest =>
      let smaller : Nat -> List UInt8 -> Except PsWasmEncodeError (List UInt8) :=
        psWasmEncodeFunctionTypeIndicesAcc structures arrays functionTypes rest;
      fun (functionIndex : Nat) =>
        fun (reversed : List UInt8) =>
          match psWasmFunctionTypeIndex structures arrays functionTypes functionIndex function with
          | Except.error error => Except.error error
          | Except.ok typeIndex =>
              smaller (Nat.add functionIndex 1)
                (psListReverseAcc (psWasmEncodeUleb typeIndex) reversed)

def psWasmEncodeFunctionTypeIndicesWorker
    (structures : List PsWasmStructType)
    (arrays : List PsWasmArrayType)
    (functionTypes : List PsWasmFunctionType)
    (functions : List PsWasmFunction) :
    Nat -> Except PsWasmEncodeError (List UInt8) :=
  fun (functionIndex : Nat) =>
    psWasmEncodeFunctionTypeIndicesAcc structures arrays functionTypes functions
      functionIndex List.nil

def psWasmEncodeFunctionTypeIndicesLoop
    (structures : List PsWasmStructType)
    (arrays : List PsWasmArrayType)
    (functionTypes : List PsWasmFunctionType)
    (functionIndex : Nat)
    (functions : List PsWasmFunction) :
    Except PsWasmEncodeError (List UInt8) :=
  psWasmEncodeFunctionTypeIndicesWorker
    structures
    arrays
    functionTypes
    functions
    functionIndex

def psWasmEncodeFunctionTypeIndices
    (structures : List PsWasmStructType)
    (arrays : List PsWasmArrayType)
    (functionTypes : List PsWasmFunctionType)
    (functions : List PsWasmFunction) :
    Except PsWasmEncodeError (List UInt8) :=
  psWasmEncodeFunctionTypeIndicesLoop
    structures arrays functionTypes 0 functions

def psWasmEncodeFunctionRefIndex
    (functions : List PsWasmFunction) (name : String) :
    Except PsWasmEncodeError (List UInt8) :=
  match psWasmFindFunctionIndex functions name with
  | Option.none => Except.error (PsWasmEncodeError.unknownFunction name)
  | Option.some index => Except.ok (psWasmEncodeUleb index)

def psWasmEncodeFunctionRefIndices
    (functions : List PsWasmFunction)
    (names : List String) :
    Except PsWasmEncodeError (List UInt8) :=
  psListFlatMapExcept (psWasmEncodeFunctionRefIndex functions) names

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
                  (psListLength functionRefs)));
          Except.ok
            (psWasmEncodeVector segment 1)

def psWasmEncodeExport
    (functions : List PsWasmFunction) (exportItem : Prod String String) :
    Except PsWasmEncodeError (List UInt8) :=
  match psWasmFindFunctionIndex functions (Prod.snd exportItem) with
  | Option.none =>
      Except.error (PsWasmEncodeError.unknownFunction (Prod.snd exportItem))
  | Option.some index =>
      Except.ok
        (psListAppend (psWasmEncodeName (Prod.fst exportItem))
          (List.cons (psWasmByte 0) (psWasmEncodeUleb index)))

def psWasmEncodeExports
    (functions : List PsWasmFunction)
    (exports : List (String × String)) :
    Except PsWasmEncodeError (List UInt8) :=
  psListFlatMapExcept (psWasmEncodeExport functions) exports

def psWasmEncodeSection
    (sectionId : Nat)
    (payload : List UInt8) : List UInt8 :=
  psListAppend
    [psWasmByte sectionId]
    (psListAppend
      (psWasmEncodeUleb (psListLength payload))
      payload)

def psWasmEncodeTypeSectionPayload
    (encodedTypes : List UInt8)
    (typeCount : Nat) : List UInt8 :=
  if Nat.beq typeCount 0 then
    psWasmEncodeVector List.nil 0
  else
    let recursiveGroup : List UInt8 :=
      psListAppend
        [psWasmByte 78]
        (psWasmEncodeVector encodedTypes typeCount);
    psWasmEncodeVector recursiveGroup 1

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
                                  let typeCount : Nat :=
                                    Nat.add
                                      (Nat.add
                                        (Nat.add
                                          (psListLength module.structures)
                                          (psListLength module.arrays))
                                        (psListLength module.functionTypes))
                                      (psListLength module.functions);
                                  let encodedTypes : List UInt8 :=
                                    psListAppend
                                      encodedStructTypes
                                      (psListAppend
                                        encodedArrayTypes
                                        (psListAppend
                                          encodedNamedFunctionTypes
                                          encodedFunctionTypes));
                                  let typePayload : List UInt8 :=
                                    psWasmEncodeTypeSectionPayload
                                      encodedTypes
                                      typeCount;
                                  let functionPayload :=
                                    psWasmEncodeVector
                                      encodedFunctionTypeIndices
                                      (psListLength module.functions);
                                  let exportPayload :=
                                    psWasmEncodeVector
                                      encodedExports
                                      (psListLength module.exports);
                                  let elementSection : List UInt8 :=
                                    match module.functionRefs with
                                    | [] => []
                                    | _ =>
                                        psWasmEncodeSection
                                          9
                                          encodedFunctionRefs;
                                  let codePayload :=
                                    psWasmEncodeVector
                                      encodedBodies
                                      (psListLength module.functions);
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