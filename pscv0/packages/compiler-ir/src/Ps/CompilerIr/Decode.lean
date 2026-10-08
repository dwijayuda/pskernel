import Ps.CompilerIr.Encode

inductive PsIrDecodeError where
  | schema
  | depthExhausted
  | bytesExhausted
  | parse (error : PsJsonParseError)
  | nonCanonical

def psIrDecodeMap1 {alpha result : Type}
    (build : alpha -> result)
    (value0 : Except PsIrDecodeError alpha) : Except PsIrDecodeError result :=
  match value0 with
  | Except.error error => Except.error error
  | Except.ok decoded0 =>
      Except.ok (build decoded0)

def psIrDecodeMap2 {alpha beta result : Type}
    (build : alpha -> beta -> result)
    (value0 : Except PsIrDecodeError alpha)
    (value1 : Except PsIrDecodeError beta) : Except PsIrDecodeError result :=
  match value0 with
  | Except.error error => Except.error error
  | Except.ok decoded0 =>
      match value1 with
      | Except.error error => Except.error error
      | Except.ok decoded1 =>
          Except.ok (build decoded0 decoded1)

def psIrDecodeMap3 {alpha beta gamma result : Type}
    (build : alpha -> beta -> gamma -> result)
    (value0 : Except PsIrDecodeError alpha)
    (value1 : Except PsIrDecodeError beta)
    (value2 : Except PsIrDecodeError gamma) : Except PsIrDecodeError result :=
  match value0 with
  | Except.error error => Except.error error
  | Except.ok decoded0 =>
      match value1 with
      | Except.error error => Except.error error
      | Except.ok decoded1 =>
          match value2 with
          | Except.error error => Except.error error
          | Except.ok decoded2 =>
              Except.ok (build decoded0 decoded1 decoded2)

def psIrDecodeMap4 {alpha beta gamma delta result : Type}
    (build : alpha -> beta -> gamma -> delta -> result)
    (value0 : Except PsIrDecodeError alpha)
    (value1 : Except PsIrDecodeError beta)
    (value2 : Except PsIrDecodeError gamma)
    (value3 : Except PsIrDecodeError delta) : Except PsIrDecodeError result :=
  match value0 with
  | Except.error error => Except.error error
  | Except.ok decoded0 =>
      match value1 with
      | Except.error error => Except.error error
      | Except.ok decoded1 =>
          match value2 with
          | Except.error error => Except.error error
          | Except.ok decoded2 =>
              match value3 with
              | Except.error error => Except.error error
              | Except.ok decoded3 =>
                  Except.ok (build decoded0 decoded1 decoded2 decoded3)

def psIrDecodeMap5 {alpha beta gamma delta epsilon result : Type}
    (build : alpha -> beta -> gamma -> delta -> epsilon -> result)
    (value0 : Except PsIrDecodeError alpha)
    (value1 : Except PsIrDecodeError beta)
    (value2 : Except PsIrDecodeError gamma)
    (value3 : Except PsIrDecodeError delta)
    (value4 : Except PsIrDecodeError epsilon) : Except PsIrDecodeError result :=
  match value0 with
  | Except.error error => Except.error error
  | Except.ok decoded0 =>
      match value1 with
      | Except.error error => Except.error error
      | Except.ok decoded1 =>
          match value2 with
          | Except.error error => Except.error error
          | Except.ok decoded2 =>
              match value3 with
              | Except.error error => Except.error error
              | Except.ok decoded3 =>
                  match value4 with
                  | Except.error error => Except.error error
                  | Except.ok decoded4 =>
                      Except.ok (build decoded0 decoded1 decoded2 decoded3 decoded4)

def psIrDecodeText (value : PsJsonValue) : Except PsIrDecodeError String :=
  match value with
  | PsJsonValue.string text => Except.ok text
  | _ => Except.error PsIrDecodeError.schema

def psIrDecodeBool (value : PsJsonValue) : Except PsIrDecodeError Bool :=
  match value with
  | PsJsonValue.bool result => Except.ok result
  | _ => Except.error PsIrDecodeError.schema

def psIrDecodeArray {alpha : Type}
    (decode : PsJsonValue -> Except PsIrDecodeError alpha)
    (value : PsJsonValue) : Except PsIrDecodeError (List alpha) :=
  match value with
  | PsJsonValue.array values => psListMapExcept decode values
  | _ => Except.error PsIrDecodeError.schema

def psIrDecodePrimitive (value : PsJsonValue) : Except PsIrDecodeError PsVerifiedIrPrimitiveType :=
  match value with
  | PsJsonValue.string text =>
      if psStringEq text "nat" then Except.ok PsVerifiedIrPrimitiveType.nat
      else if psStringEq text "int" then Except.ok PsVerifiedIrPrimitiveType.int
      else if psStringEq text "uint8" then Except.ok PsVerifiedIrPrimitiveType.uint8
      else if psStringEq text "uint16" then Except.ok PsVerifiedIrPrimitiveType.uint16
      else if psStringEq text "uint32" then Except.ok PsVerifiedIrPrimitiveType.uint32
      else if psStringEq text "uint64" then Except.ok PsVerifiedIrPrimitiveType.uint64
      else if psStringEq text "usize" then Except.ok PsVerifiedIrPrimitiveType.usize
      else if psStringEq text "int8" then Except.ok PsVerifiedIrPrimitiveType.int8
      else if psStringEq text "int16" then Except.ok PsVerifiedIrPrimitiveType.int16
      else if psStringEq text "int32" then Except.ok PsVerifiedIrPrimitiveType.int32
      else if psStringEq text "int64" then Except.ok PsVerifiedIrPrimitiveType.int64
      else if psStringEq text "isize" then Except.ok PsVerifiedIrPrimitiveType.isize
      else if psStringEq text "float" then Except.ok PsVerifiedIrPrimitiveType.float
      else if psStringEq text "float32" then Except.ok PsVerifiedIrPrimitiveType.float32
      else if psStringEq text "bool" then Except.ok PsVerifiedIrPrimitiveType.bool
      else if psStringEq text "char" then Except.ok PsVerifiedIrPrimitiveType.char
      else if psStringEq text "string" then Except.ok PsVerifiedIrPrimitiveType.string
      else if psStringEq text "unit" then Except.ok PsVerifiedIrPrimitiveType.unit
      else Except.error PsIrDecodeError.schema
  | _ => Except.error PsIrDecodeError.schema

def psIrDecodeMachine (value : PsJsonValue) : Except PsIrDecodeError PsVerifiedIrMachineIntegerType :=
  match value with
  | PsJsonValue.string text =>
      if psStringEq text "uint8" then Except.ok PsVerifiedIrMachineIntegerType.uint8
      else if psStringEq text "uint16" then Except.ok PsVerifiedIrMachineIntegerType.uint16
      else if psStringEq text "uint32" then Except.ok PsVerifiedIrMachineIntegerType.uint32
      else if psStringEq text "uint64" then Except.ok PsVerifiedIrMachineIntegerType.uint64
      else if psStringEq text "usize" then Except.ok PsVerifiedIrMachineIntegerType.usize
      else if psStringEq text "int8" then Except.ok PsVerifiedIrMachineIntegerType.int8
      else if psStringEq text "int16" then Except.ok PsVerifiedIrMachineIntegerType.int16
      else if psStringEq text "int32" then Except.ok PsVerifiedIrMachineIntegerType.int32
      else if psStringEq text "int64" then Except.ok PsVerifiedIrMachineIntegerType.int64
      else if psStringEq text "isize" then Except.ok PsVerifiedIrMachineIntegerType.isize
      else Except.error PsIrDecodeError.schema
  | _ => Except.error PsIrDecodeError.schema

def psIrDecodeIntegerBinary (value : PsJsonValue) : Except PsIrDecodeError PsVerifiedIrIntegerBinaryOp :=
  match value with
  | PsJsonValue.string text =>
      if psStringEq text "add" then Except.ok PsVerifiedIrIntegerBinaryOp.add
      else if psStringEq text "sub" then Except.ok PsVerifiedIrIntegerBinaryOp.sub
      else if psStringEq text "mul" then Except.ok PsVerifiedIrIntegerBinaryOp.mul
      else if psStringEq text "bitAnd" then Except.ok PsVerifiedIrIntegerBinaryOp.bitAnd
      else if psStringEq text "bitOr" then Except.ok PsVerifiedIrIntegerBinaryOp.bitOr
      else if psStringEq text "bitXor" then Except.ok PsVerifiedIrIntegerBinaryOp.bitXor
      else Except.error PsIrDecodeError.schema
  | _ => Except.error PsIrDecodeError.schema

def psIrDecodeIntegerCompare (value : PsJsonValue) : Except PsIrDecodeError PsVerifiedIrIntegerCompareOp :=
  match value with
  | PsJsonValue.string text =>
      if psStringEq text "eq" then Except.ok PsVerifiedIrIntegerCompareOp.eq
      else if psStringEq text "ne" then Except.ok PsVerifiedIrIntegerCompareOp.ne
      else if psStringEq text "lt" then Except.ok PsVerifiedIrIntegerCompareOp.lt
      else if psStringEq text "le" then Except.ok PsVerifiedIrIntegerCompareOp.le
      else if psStringEq text "gt" then Except.ok PsVerifiedIrIntegerCompareOp.gt
      else if psStringEq text "ge" then Except.ok PsVerifiedIrIntegerCompareOp.ge
      else Except.error PsIrDecodeError.schema
  | _ => Except.error PsIrDecodeError.schema

def psIrDecodeFloating (value : PsJsonValue) : Except PsIrDecodeError PsVerifiedIrFloatingType :=
  match value with
  | PsJsonValue.string text =>
      if psStringEq text "float" then Except.ok PsVerifiedIrFloatingType.float
      else if psStringEq text "float32" then Except.ok PsVerifiedIrFloatingType.float32
      else Except.error PsIrDecodeError.schema
  | _ => Except.error PsIrDecodeError.schema

def psIrDecodeFloatBinary (value : PsJsonValue) : Except PsIrDecodeError PsVerifiedIrFloatBinaryOp :=
  match value with
  | PsJsonValue.string text =>
      if psStringEq text "add" then Except.ok PsVerifiedIrFloatBinaryOp.add
      else if psStringEq text "sub" then Except.ok PsVerifiedIrFloatBinaryOp.sub
      else if psStringEq text "mul" then Except.ok PsVerifiedIrFloatBinaryOp.mul
      else if psStringEq text "div" then Except.ok PsVerifiedIrFloatBinaryOp.div
      else Except.error PsIrDecodeError.schema
  | _ => Except.error PsIrDecodeError.schema

def psIrDecodeFloatCompare (value : PsJsonValue) : Except PsIrDecodeError PsVerifiedIrFloatCompareOp :=
  match value with
  | PsJsonValue.string text =>
      if psStringEq text "eq" then Except.ok PsVerifiedIrFloatCompareOp.eq
      else if psStringEq text "ne" then Except.ok PsVerifiedIrFloatCompareOp.ne
      else if psStringEq text "lt" then Except.ok PsVerifiedIrFloatCompareOp.lt
      else if psStringEq text "le" then Except.ok PsVerifiedIrFloatCompareOp.le
      else if psStringEq text "gt" then Except.ok PsVerifiedIrFloatCompareOp.gt
      else if psStringEq text "ge" then Except.ok PsVerifiedIrFloatCompareOp.ge
      else Except.error PsIrDecodeError.schema
  | _ => Except.error PsIrDecodeError.schema

def psIrDecodeSimpleIntrinsic (value : PsJsonValue) : Except PsIrDecodeError PsVerifiedIrIntrinsic :=
  match value with
  | PsJsonValue.string text =>
      if psStringEq text "uint8OfNat" then Except.ok PsVerifiedIrIntrinsic.uint8OfNat
      else if psStringEq text "natAdd" then Except.ok PsVerifiedIrIntrinsic.natAdd
      else if psStringEq text "natSub" then Except.ok PsVerifiedIrIntrinsic.natSub
      else if psStringEq text "natMul" then Except.ok PsVerifiedIrIntrinsic.natMul
      else if psStringEq text "natDiv" then Except.ok PsVerifiedIrIntrinsic.natDiv
      else if psStringEq text "natMod" then Except.ok PsVerifiedIrIntrinsic.natMod
      else if psStringEq text "natEq" then Except.ok PsVerifiedIrIntrinsic.natEq
      else if psStringEq text "natNe" then Except.ok PsVerifiedIrIntrinsic.natNe
      else if psStringEq text "natLe" then Except.ok PsVerifiedIrIntrinsic.natLe
      else if psStringEq text "natLt" then Except.ok PsVerifiedIrIntrinsic.natLt
      else if psStringEq text "intOfNat" then Except.ok PsVerifiedIrIntrinsic.intOfNat
      else if psStringEq text "intRepr" then Except.ok PsVerifiedIrIntrinsic.intRepr
      else if psStringEq text "intNegSucc" then Except.ok PsVerifiedIrIntrinsic.intNegSucc
      else if psStringEq text "intNeg" then Except.ok PsVerifiedIrIntrinsic.intNeg
      else if psStringEq text "intAdd" then Except.ok PsVerifiedIrIntrinsic.intAdd
      else if psStringEq text "intSub" then Except.ok PsVerifiedIrIntrinsic.intSub
      else if psStringEq text "intMul" then Except.ok PsVerifiedIrIntrinsic.intMul
      else if psStringEq text "intEq" then Except.ok PsVerifiedIrIntrinsic.intEq
      else if psStringEq text "intLe" then Except.ok PsVerifiedIrIntrinsic.intLe
      else if psStringEq text "intLt" then Except.ok PsVerifiedIrIntrinsic.intLt
      else if psStringEq text "boolNot" then Except.ok PsVerifiedIrIntrinsic.boolNot
      else if psStringEq text "boolAnd" then Except.ok PsVerifiedIrIntrinsic.boolAnd
      else if psStringEq text "boolOr" then Except.ok PsVerifiedIrIntrinsic.boolOr
      else if psStringEq text "boolEq" then Except.ok PsVerifiedIrIntrinsic.boolEq
      else if psStringEq text "boolNe" then Except.ok PsVerifiedIrIntrinsic.boolNe
      else if psStringEq text "charOfNat" then Except.ok PsVerifiedIrIntrinsic.charOfNat
      else if psStringEq text "charToNat" then Except.ok PsVerifiedIrIntrinsic.charToNat
      else if psStringEq text "stringPush" then Except.ok PsVerifiedIrIntrinsic.stringPush
      else if psStringEq text "stringSingleton" then Except.ok PsVerifiedIrIntrinsic.stringSingleton
      else if psStringEq text "stringLength" then Except.ok PsVerifiedIrIntrinsic.stringLength
      else if psStringEq text "stringAppend" then Except.ok PsVerifiedIrIntrinsic.stringAppend
      else if psStringEq text "stringUtf8ByteSize" then Except.ok PsVerifiedIrIntrinsic.stringUtf8ByteSize
      else if psStringEq text "stringNext" then Except.ok PsVerifiedIrIntrinsic.stringNext
      else if psStringEq text "stringGet" then Except.ok PsVerifiedIrIntrinsic.stringGet
      else if psStringEq text "stringAtEnd" then Except.ok PsVerifiedIrIntrinsic.stringAtEnd
      else if psStringEq text "stringExtract" then Except.ok PsVerifiedIrIntrinsic.stringExtract
      else if psStringEq text "stringEq" then Except.ok PsVerifiedIrIntrinsic.stringEq
      else if psStringEq text "arrayEmptyWithCapacity" then Except.ok PsVerifiedIrIntrinsic.arrayEmptyWithCapacity
      else if psStringEq text "arraySize" then Except.ok PsVerifiedIrIntrinsic.arraySize
      else if psStringEq text "arrayPush" then Except.ok PsVerifiedIrIntrinsic.arrayPush
      else if psStringEq text "arrayGet" then Except.ok PsVerifiedIrIntrinsic.arrayGet
      else if psStringEq text "arrayGetD" then Except.ok PsVerifiedIrIntrinsic.arrayGetD
      else if psStringEq text "arraySet" then Except.ok PsVerifiedIrIntrinsic.arraySet
      else if psStringEq text "arraySetIfInBounds" then Except.ok PsVerifiedIrIntrinsic.arraySetIfInBounds
      else if psStringEq text "arrayMap" then Except.ok PsVerifiedIrIntrinsic.arrayMap
      else if psStringEq text "arrayFoldl" then Except.ok PsVerifiedIrIntrinsic.arrayFoldl
      else Except.error PsIrDecodeError.schema
  | _ => Except.error PsIrDecodeError.schema

def psIrDecodeNaturalDigits (chars : List Char) (value : Nat) : Except PsIrDecodeError Nat :=
  match psJsonDecodeNaturalDigits chars value with
  | Option.none => Except.error PsIrDecodeError.schema
  | Option.some number => Except.ok number

def psIrDecodeNatural (value : PsJsonValue) : Except PsIrDecodeError Nat :=
  match psJsonDecodeNaturalString value with
  | Option.none => Except.error PsIrDecodeError.schema
  | Option.some number => Except.ok number

def psIrDecodeInteger (value : PsJsonValue) : Except PsIrDecodeError Int :=
  match value with
  | PsJsonValue.string text =>
      match psJsonStringToChars text with
      | List.nil => Except.error PsIrDecodeError.schema
      | List.cons first rest =>
          if Nat.beq (Char.toNat first) 45 then
            match psIrDecodeNaturalDigits rest 0 with
            | Except.error error => Except.error error
            | Except.ok number =>
                let result : Int := Int.neg (Int.ofNat number);
                if psStringEq (Int.repr result) text then Except.ok result
                else Except.error PsIrDecodeError.schema
          else psIrDecodeMap1 Int.ofNat (psIrDecodeNatural value)
  | _ => Except.error PsIrDecodeError.schema

def psIrDecodeItem (index : Nat) : List PsJsonValue -> PsJsonValue :=
  psJsonArrayItem index

def psIrDecodeTuple {alpha : Type} (count : Nat)
    (build : List PsJsonValue -> Except PsIrDecodeError alpha)
    (value : PsJsonValue) : Except PsIrDecodeError alpha :=
  match value with
  | PsJsonValue.array values =>
      if Nat.beq (psListLength values) count then build values else Except.error PsIrDecodeError.schema
  | _ => Except.error PsIrDecodeError.schema

def psIrDecodeIntrinsic (value : PsJsonValue) : Except PsIrDecodeError PsVerifiedIrIntrinsic :=
  match value with
  | PsJsonValue.array values =>
      if Nat.beq (psListLength values) 1 then psIrDecodeSimpleIntrinsic (psIrDecodeItem 0 values)
      else if Nat.beq (psListLength values) 3 then
        match psIrDecodeItem 0 values with
        | PsJsonValue.string tag =>
            let type := psIrDecodeItem 1 values;
            let operation := psIrDecodeItem 2 values;
            if psStringEq tag "machineIntBinary" then
              psIrDecodeMap2 PsVerifiedIrIntrinsic.machineIntBinary (psIrDecodeMachine type) (psIrDecodeIntegerBinary operation)
            else if psStringEq tag "machineIntCompare" then
              psIrDecodeMap2 PsVerifiedIrIntrinsic.machineIntCompare (psIrDecodeMachine type) (psIrDecodeIntegerCompare operation)
            else if psStringEq tag "floatBinary" then
              psIrDecodeMap2 PsVerifiedIrIntrinsic.floatBinary (psIrDecodeFloating type) (psIrDecodeFloatBinary operation)
            else if psStringEq tag "floatCompare" then
              psIrDecodeMap2 PsVerifiedIrIntrinsic.floatCompare (psIrDecodeFloating type) (psIrDecodeFloatCompare operation)
            else Except.error PsIrDecodeError.schema
        | _ => Except.error PsIrDecodeError.schema
      else Except.error PsIrDecodeError.schema
  | _ => Except.error PsIrDecodeError.schema

def psIrDecodeLiteral (value : PsJsonValue) : Except PsIrDecodeError PsVerifiedIrLiteral :=
  match value with
  | PsJsonValue.array values =>
      match psIrDecodeItem 0 values with
      | PsJsonValue.string tag =>
          let count : Nat := psListLength values;
          if Nat.beq count 1 then
            if psStringEq tag "unit" then Except.ok PsVerifiedIrLiteral.unit else Except.error PsIrDecodeError.schema
          else if Nat.beq count 2 then
            let argument := psIrDecodeItem 1 values;
            if psStringEq tag "natural" then psIrDecodeMap1 PsVerifiedIrLiteral.natural (psIrDecodeNatural argument)
            else if psStringEq tag "integer" then psIrDecodeMap1 PsVerifiedIrLiteral.integer (psIrDecodeInteger argument)
            else if psStringEq tag "string" then psIrDecodeMap1 PsVerifiedIrLiteral.string (psIrDecodeText argument)
            else if psStringEq tag "bool" then psIrDecodeMap1 PsVerifiedIrLiteral.bool (psIrDecodeBool argument)
            else Except.error PsIrDecodeError.schema
          else if Nat.beq count 3 then
            if psStringEq tag "machineInteger" then
              psIrDecodeMap2 PsVerifiedIrLiteral.machineInteger
                (psIrDecodeMachine (psIrDecodeItem 1 values)) (psIrDecodeInteger (psIrDecodeItem 2 values))
            else Except.error PsIrDecodeError.schema
          else Except.error PsIrDecodeError.schema
      | _ => Except.error PsIrDecodeError.schema
  | _ => Except.error PsIrDecodeError.schema

def psIrDecodeTypeWithFuel (fuel : Nat) : PsJsonValue -> Except PsIrDecodeError PsVerifiedIrType :=
  match fuel with
  | Nat.zero => fun (_value : PsJsonValue) => Except.error PsIrDecodeError.depthExhausted
  | Nat.succ remaining =>
      let smaller : PsJsonValue -> Except PsIrDecodeError PsVerifiedIrType := psIrDecodeTypeWithFuel remaining;
      fun (value : PsJsonValue) =>
        match value with
        | PsJsonValue.array values =>
            match psIrDecodeItem 0 values with
            | PsJsonValue.string tag =>
                let count : Nat := psListLength values;
                let first := psIrDecodeItem 1 values;
                let second := psIrDecodeItem 2 values;
                if Nat.beq count 1 then
                  if psStringEq tag "unknown" then Except.ok PsVerifiedIrType.unknown else Except.error PsIrDecodeError.schema
                else if Nat.beq count 2 then
                  if psStringEq tag "typeParameter" then psIrDecodeMap1 PsVerifiedIrType.typeParameter (psIrDecodeText first)
                  else if psStringEq tag "primitive" then psIrDecodeMap1 PsVerifiedIrType.primitive (psIrDecodePrimitive first)
                  else Except.error PsIrDecodeError.schema
                else if Nat.beq count 3 then
                  if psStringEq tag "named" then psIrDecodeMap2 PsVerifiedIrType.named (psIrDecodeText first) (psIrDecodeArray smaller second)
                  else if psStringEq tag "function" then
                    psIrDecodeMap2 PsVerifiedIrType.function (psIrDecodeArray smaller first) (smaller second)
                  else Except.error PsIrDecodeError.schema
                else Except.error PsIrDecodeError.schema
            | _ => Except.error PsIrDecodeError.schema
        | _ => Except.error PsIrDecodeError.schema

def psIrDecodeType (value : PsJsonValue) : Except PsIrDecodeError PsVerifiedIrType :=
  psIrDecodeTypeWithFuel 4096 value

def psIrDecodeParameter (value : PsJsonValue) : Except PsIrDecodeError PsVerifiedIrParameter :=
  let build : List PsJsonValue -> Except PsIrDecodeError PsVerifiedIrParameter :=
    fun (values : List PsJsonValue) =>
      psIrDecodeMap2 PsVerifiedIrParameter.mk (psIrDecodeText (psIrDecodeItem 0 values)) (psIrDecodeType (psIrDecodeItem 1 values));
  psIrDecodeTuple 2 build value

def psIrDecodeBinding (value : PsJsonValue) : Except PsIrDecodeError PsVerifiedIrMatchBinding :=
  let build : List PsJsonValue -> Except PsIrDecodeError PsVerifiedIrMatchBinding :=
    fun (values : List PsJsonValue) =>
      psIrDecodeMap3 PsVerifiedIrMatchBinding.mk (psIrDecodeText (psIrDecodeItem 0 values))
        (psIrDecodeText (psIrDecodeItem 1 values)) (psIrDecodeType (psIrDecodeItem 2 values));
  psIrDecodeTuple 3 build value

def psIrDecodeFieldWith (decode : PsJsonValue -> Except PsIrDecodeError PsVerifiedIrExpr)
    (value : PsJsonValue) : Except PsIrDecodeError (Prod String PsVerifiedIrExpr) :=
  let build : List PsJsonValue -> Except PsIrDecodeError (Prod String PsVerifiedIrExpr) :=
    fun (values : List PsJsonValue) =>
      psIrDecodeMap2 Prod.mk (psIrDecodeText (psIrDecodeItem 0 values)) (decode (psIrDecodeItem 1 values));
  psIrDecodeTuple 2 build value

def psIrDecodeAlternativeWith (decode : PsJsonValue -> Except PsIrDecodeError PsVerifiedIrExpr)
    (value : PsJsonValue) : Except PsIrDecodeError (Prod String (Prod (List PsVerifiedIrMatchBinding) PsVerifiedIrExpr)) :=
  let build : List PsJsonValue -> Except PsIrDecodeError (Prod String (Prod (List PsVerifiedIrMatchBinding) PsVerifiedIrExpr)) :=
    fun (values : List PsJsonValue) =>
      psIrDecodeMap2 Prod.mk (psIrDecodeText (psIrDecodeItem 0 values))
        (psIrDecodeMap2 Prod.mk (psIrDecodeArray psIrDecodeBinding (psIrDecodeItem 1 values)) (decode (psIrDecodeItem 2 values)));
  psIrDecodeTuple 3 build value

def psIrDecodeExprWithFuel (fuel : Nat) : PsJsonValue -> Except PsIrDecodeError PsVerifiedIrExpr :=
  match fuel with
  | Nat.zero => fun (_value : PsJsonValue) => Except.error PsIrDecodeError.depthExhausted
  | Nat.succ remaining =>
      let smaller : PsJsonValue -> Except PsIrDecodeError PsVerifiedIrExpr := psIrDecodeExprWithFuel remaining;
      let fieldDecoder : PsJsonValue -> Except PsIrDecodeError (Prod String PsVerifiedIrExpr) := psIrDecodeFieldWith smaller;
      let alternativeDecoder : PsJsonValue -> Except PsIrDecodeError (Prod String (Prod (List PsVerifiedIrMatchBinding) PsVerifiedIrExpr)) :=
        psIrDecodeAlternativeWith smaller;
      fun (value : PsJsonValue) =>
        match value with
        | PsJsonValue.array values =>
            match psIrDecodeItem 0 values with
            | PsJsonValue.string tag =>
                let count : Nat := psListLength values;
                let first := psIrDecodeItem 1 values;
                let second := psIrDecodeItem 2 values;
                let third := psIrDecodeItem 3 values;
                let fourth := psIrDecodeItem 4 values;
                if Nat.beq count 2 then
                  if psStringEq tag "literal" then psIrDecodeMap1 PsVerifiedIrExpr.literal (psIrDecodeLiteral first)
                  else if psStringEq tag "var" then psIrDecodeMap1 PsVerifiedIrExpr.var (psIrDecodeText first)
                  else Except.error PsIrDecodeError.schema
                else if Nat.beq count 4 then
                  if psStringEq tag "intrinsic" then
                    psIrDecodeMap3 PsVerifiedIrExpr.intrinsic (psIrDecodeIntrinsic first)
                      (psIrDecodeArray psIrDecodeType second) (psIrDecodeArray smaller third)
                  else if psStringEq tag "lambda" then
                    psIrDecodeMap3 PsVerifiedIrExpr.lambda (psIrDecodeArray psIrDecodeParameter first) (psIrDecodeType second) (smaller third)
                  else if psStringEq tag "call" then
                    psIrDecodeMap3 PsVerifiedIrExpr.call (smaller first) (psIrDecodeArray psIrDecodeType second) (psIrDecodeArray smaller third)
                  else if psStringEq tag "if" then psIrDecodeMap3 PsVerifiedIrExpr.ifE (smaller first) (smaller second) (smaller third)
                  else if psStringEq tag "record" then
                    psIrDecodeMap3 PsVerifiedIrExpr.record (psIrDecodeText first)
                      (psIrDecodeArray psIrDecodeType second) (psIrDecodeArray fieldDecoder third)
                  else Except.error PsIrDecodeError.schema
                else if Nat.beq count 5 then
                  if psStringEq tag "let" then
                    psIrDecodeMap4 PsVerifiedIrExpr.letE (psIrDecodeText first) (psIrDecodeType second) (smaller third) (smaller fourth)
                  else if psStringEq tag "projection" then
                    psIrDecodeMap4 PsVerifiedIrExpr.projection (psIrDecodeText first)
                      (psIrDecodeArray psIrDecodeType second) (smaller third) (psIrDecodeText fourth)
                  else if psStringEq tag "constructor" then
                    psIrDecodeMap4 PsVerifiedIrExpr.constructor (psIrDecodeText first) (psIrDecodeText second)
                      (psIrDecodeArray psIrDecodeType third) (psIrDecodeArray fieldDecoder fourth)
                  else if psStringEq tag "match" then
                    psIrDecodeMap4 PsVerifiedIrExpr.matchE (psIrDecodeText first)
                      (psIrDecodeArray psIrDecodeType second) (smaller third) (psIrDecodeArray alternativeDecoder fourth)
                  else Except.error PsIrDecodeError.schema
                else Except.error PsIrDecodeError.schema
            | _ => Except.error PsIrDecodeError.schema
        | _ => Except.error PsIrDecodeError.schema

def psIrDecodeExpr (value : PsJsonValue) : Except PsIrDecodeError PsVerifiedIrExpr :=
  psIrDecodeExprWithFuel 4096 value

def psIrDecodeTypeParameter (value : PsJsonValue) : Except PsIrDecodeError PsVerifiedIrTypeParameter :=
  psIrDecodeMap1 PsVerifiedIrTypeParameter.mk (psIrDecodeText value)

def psIrDecodeStructureField (value : PsJsonValue) : Except PsIrDecodeError PsVerifiedIrStructureField :=
  let build : List PsJsonValue -> Except PsIrDecodeError PsVerifiedIrStructureField :=
    fun (values : List PsJsonValue) =>
      psIrDecodeMap2 PsVerifiedIrStructureField.mk (psIrDecodeText (psIrDecodeItem 0 values)) (psIrDecodeType (psIrDecodeItem 1 values));
  psIrDecodeTuple 2 build value

def psIrDecodeConstructorField (value : PsJsonValue) : Except PsIrDecodeError PsVerifiedIrConstructorField :=
  let build : List PsJsonValue -> Except PsIrDecodeError PsVerifiedIrConstructorField :=
    fun (values : List PsJsonValue) =>
      psIrDecodeMap2 PsVerifiedIrConstructorField.mk (psIrDecodeText (psIrDecodeItem 0 values)) (psIrDecodeType (psIrDecodeItem 1 values));
  psIrDecodeTuple 2 build value

def psIrDecodeConstructor (value : PsJsonValue) : Except PsIrDecodeError PsVerifiedIrConstructor :=
  let build : List PsJsonValue -> Except PsIrDecodeError PsVerifiedIrConstructor :=
    fun (values : List PsJsonValue) =>
      psIrDecodeMap2 PsVerifiedIrConstructor.mk (psIrDecodeText (psIrDecodeItem 0 values))
        (psIrDecodeArray psIrDecodeConstructorField (psIrDecodeItem 1 values));
  psIrDecodeTuple 2 build value

def psIrDecodeStructure (value : PsJsonValue) : Except PsIrDecodeError PsVerifiedIrStructure :=
  let build : List PsJsonValue -> Except PsIrDecodeError PsVerifiedIrStructure :=
    fun (values : List PsJsonValue) =>
      psIrDecodeMap3 PsVerifiedIrStructure.mk (psIrDecodeText (psIrDecodeItem 0 values))
        (psIrDecodeArray psIrDecodeTypeParameter (psIrDecodeItem 1 values)) (psIrDecodeArray psIrDecodeStructureField (psIrDecodeItem 2 values));
  psIrDecodeTuple 3 build value

def psIrDecodeInductive (value : PsJsonValue) : Except PsIrDecodeError PsVerifiedIrInductive :=
  let build : List PsJsonValue -> Except PsIrDecodeError PsVerifiedIrInductive :=
    fun (values : List PsJsonValue) =>
      psIrDecodeMap3 PsVerifiedIrInductive.mk (psIrDecodeText (psIrDecodeItem 0 values))
        (psIrDecodeArray psIrDecodeTypeParameter (psIrDecodeItem 1 values)) (psIrDecodeArray psIrDecodeConstructor (psIrDecodeItem 2 values));
  psIrDecodeTuple 3 build value

def psIrDecodeImport (value : PsJsonValue) : Except PsIrDecodeError PsVerifiedIrExternalImport :=
  let build : List PsJsonValue -> Except PsIrDecodeError PsVerifiedIrExternalImport :=
    fun (values : List PsJsonValue) =>
      psIrDecodeMap4 PsVerifiedIrExternalImport.mk (psIrDecodeText (psIrDecodeItem 0 values))
        (psIrDecodeText (psIrDecodeItem 1 values)) (psIrDecodeText (psIrDecodeItem 2 values)) (psIrDecodeType (psIrDecodeItem 3 values));
  psIrDecodeTuple 4 build value

def psIrDecodeDeclaration (value : PsJsonValue) : Except PsIrDecodeError PsVerifiedIrDeclaration :=
  let build : List PsJsonValue -> Except PsIrDecodeError PsVerifiedIrDeclaration :=
    fun (values : List PsJsonValue) =>
      psIrDecodeMap5 PsVerifiedIrDeclaration.mk (psIrDecodeText (psIrDecodeItem 0 values))
        (psIrDecodeArray psIrDecodeTypeParameter (psIrDecodeItem 1 values)) (psIrDecodeArray psIrDecodeParameter (psIrDecodeItem 2 values))
        (psIrDecodeType (psIrDecodeItem 3 values)) (psIrDecodeExpr (psIrDecodeItem 4 values));
  psIrDecodeTuple 5 build value

def psIrDecodeModuleValue (value : PsJsonValue) : Except PsIrDecodeError PsVerifiedIrModule :=
  let build : List PsJsonValue -> Except PsIrDecodeError PsVerifiedIrModule :=
    fun (values : List PsJsonValue) =>
      match psIrDecodeItem 0 values with
      | PsJsonValue.string tag =>
          if psStringEq tag "psc-runtime-ir-json/1" then
            psIrDecodeMap4 PsVerifiedIrModule.mk (psIrDecodeArray psIrDecodeImport (psIrDecodeItem 1 values))
              (psIrDecodeArray psIrDecodeStructure (psIrDecodeItem 2 values)) (psIrDecodeArray psIrDecodeInductive (psIrDecodeItem 3 values))
              (psIrDecodeArray psIrDecodeDeclaration (psIrDecodeItem 4 values))
          else Except.error PsIrDecodeError.schema
      | _ => Except.error PsIrDecodeError.schema;
  psIrDecodeTuple 5 build value

-- Decoding creates construction IR only. Exact re-encoding prevents ambiguous
-- JSON/decimal spellings from acquiring the identity of canonical stage bytes.
-- Host callers must additionally bound process resources and preflight depth.
def psIrDecodeModuleWithByteLimit (maxBytes : Nat) (source : String) : Except PsIrDecodeError PsVerifiedIrModule :=
  if Nat.ble (String.utf8ByteSize source) maxBytes then
    match psJsonParse source with
    | Except.error error => Except.error (PsIrDecodeError.parse error)
    | Except.ok json =>
        match psIrDecodeModuleValue json with
        | Except.error error => Except.error error
        | Except.ok module =>
            match psIrEncodeModule module with
            | Except.error _ => Except.error PsIrDecodeError.depthExhausted
            | Except.ok encoded =>
                if psStringEq encoded source then Except.ok module else Except.error PsIrDecodeError.nonCanonical
  else Except.error PsIrDecodeError.bytesExhausted

def psIrDecodeModule (source : String) : Except PsIrDecodeError PsVerifiedIrModule :=
  psIrDecodeModuleWithByteLimit 134217728 source
