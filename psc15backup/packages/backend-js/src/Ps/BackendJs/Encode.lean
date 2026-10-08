import Ps.BackendJs.Model
import Ps.Bridge.Json
import Ps.Foundation.List

inductive PsJsIrEncodeError where
  | depthExhausted

def psJsIrEncodeValues
    (values : List (Except PsJsIrEncodeError String)) :
    Except PsJsIrEncodeError String :=
  let unwrap :
      Except PsJsIrEncodeError String ->
      Except PsJsIrEncodeError String :=
    fun (value : Except PsJsIrEncodeError String) =>
      value;
  match psListMapExcept unwrap values with
  | Except.error error =>
      Except.error error
  | Except.ok encoded =>
      Except.ok (psJsonArray encoded)

def psJsIrEncodeNode
    (tag : String)
    (values : List (Except PsJsIrEncodeError String)) :
    Except PsJsIrEncodeError String :=
  psJsIrEncodeValues
    (List.cons
      (Except.ok (psJsonQuote tag))
      values)

def psJsIrEncodeText
    (value : String) :
    Except PsJsIrEncodeError String :=
  Except.ok (psJsonQuote value)

def psJsIrEncodeBoolText
    (value : Bool) : String :=
  if value then
    "true"
  else
    "false"

def psJsIrEncodeMachineType
    (value : PsJsIrMachineIntegerType) : String :=
  match value with
  | PsJsIrMachineIntegerType.uint8 => psJsonQuote "uint8"
  | PsJsIrMachineIntegerType.uint16 => psJsonQuote "uint16"
  | PsJsIrMachineIntegerType.uint32 => psJsonQuote "uint32"
  | PsJsIrMachineIntegerType.uint64 => psJsonQuote "uint64"
  | PsJsIrMachineIntegerType.int8 => psJsonQuote "int8"
  | PsJsIrMachineIntegerType.int16 => psJsonQuote "int16"
  | PsJsIrMachineIntegerType.int32 => psJsonQuote "int32"
  | PsJsIrMachineIntegerType.int64 => psJsonQuote "int64"

def psJsIrEncodeIntegerBinary
    (value : PsJsIrIntegerBinaryOp) : String :=
  match value with
  | PsJsIrIntegerBinaryOp.add => psJsonQuote "add"
  | PsJsIrIntegerBinaryOp.sub => psJsonQuote "sub"
  | PsJsIrIntegerBinaryOp.mul => psJsonQuote "mul"
  | PsJsIrIntegerBinaryOp.bitAnd => psJsonQuote "bitAnd"
  | PsJsIrIntegerBinaryOp.bitOr => psJsonQuote "bitOr"
  | PsJsIrIntegerBinaryOp.bitXor => psJsonQuote "bitXor"

def psJsIrEncodeIntegerCompare
    (value : PsJsIrIntegerCompareOp) : String :=
  match value with
  | PsJsIrIntegerCompareOp.eq => psJsonQuote "eq"
  | PsJsIrIntegerCompareOp.ne => psJsonQuote "ne"
  | PsJsIrIntegerCompareOp.lt => psJsonQuote "lt"
  | PsJsIrIntegerCompareOp.le => psJsonQuote "le"
  | PsJsIrIntegerCompareOp.gt => psJsonQuote "gt"
  | PsJsIrIntegerCompareOp.ge => psJsonQuote "ge"

def psJsIrEncodeFloatingType
    (value : PsJsIrFloatingType) : String :=
  match value with
  | PsJsIrFloatingType.float => psJsonQuote "float"
  | PsJsIrFloatingType.float32 => psJsonQuote "float32"

def psJsIrEncodeFloatBinary
    (value : PsJsIrFloatBinaryOp) : String :=
  match value with
  | PsJsIrFloatBinaryOp.add => psJsonQuote "add"
  | PsJsIrFloatBinaryOp.sub => psJsonQuote "sub"
  | PsJsIrFloatBinaryOp.mul => psJsonQuote "mul"
  | PsJsIrFloatBinaryOp.div => psJsonQuote "div"

def psJsIrEncodeFloatCompare
    (value : PsJsIrFloatCompareOp) : String :=
  match value with
  | PsJsIrFloatCompareOp.eq => psJsonQuote "eq"
  | PsJsIrFloatCompareOp.ne => psJsonQuote "ne"
  | PsJsIrFloatCompareOp.lt => psJsonQuote "lt"
  | PsJsIrFloatCompareOp.le => psJsonQuote "le"
  | PsJsIrFloatCompareOp.gt => psJsonQuote "gt"
  | PsJsIrFloatCompareOp.ge => psJsonQuote "ge"

def psJsIrEncodeLiteral
    (value : PsJsIrLiteral) :
    Except PsJsIrEncodeError String :=
  match value with
  | PsJsIrLiteral.natural natural =>
      psJsIrEncodeNode
        "natural"
        [psJsIrEncodeText (psNatToString natural)]
  | PsJsIrLiteral.integer integer =>
      psJsIrEncodeNode
        "integer"
        [psJsIrEncodeText (Int.repr integer)]
  | PsJsIrLiteral.machineInteger type integer =>
      psJsIrEncodeNode
        "machineInteger"
        [
          Except.ok (psJsIrEncodeMachineType type),
          psJsIrEncodeText (Int.repr integer)
        ]
  | PsJsIrLiteral.string value =>
      psJsIrEncodeNode
        "string"
        [psJsIrEncodeText value]
  | PsJsIrLiteral.bool value =>
      psJsIrEncodeNode
        "bool"
        [
          Except.ok
            (psJsIrEncodeBoolText value)
        ]
  | PsJsIrLiteral.unit =>
      psJsIrEncodeNode
        "unit"
        List.nil

def psJsIrEncodeUnary
    (value : PsJsIrUnaryOp) : String :=
  match value with
  | PsJsIrUnaryOp.bigintNeg => psJsonQuote "bigintNeg"
  | PsJsIrUnaryOp.boolNot => psJsonQuote "boolNot"

def psJsIrEncodeBinary
    (value : PsJsIrBinaryOp) : String :=
  match value with
  | PsJsIrBinaryOp.bigintAdd => psJsonArray [psJsonQuote "bigintAdd"]
  | PsJsIrBinaryOp.bigintSub => psJsonArray [psJsonQuote "bigintSub"]
  | PsJsIrBinaryOp.bigintMul => psJsonArray [psJsonQuote "bigintMul"]
  | PsJsIrBinaryOp.bigintEq => psJsonArray [psJsonQuote "bigintEq"]
  | PsJsIrBinaryOp.bigintNe => psJsonArray [psJsonQuote "bigintNe"]
  | PsJsIrBinaryOp.bigintLe => psJsonArray [psJsonQuote "bigintLe"]
  | PsJsIrBinaryOp.bigintLt => psJsonArray [psJsonQuote "bigintLt"]
  | PsJsIrBinaryOp.boolAnd => psJsonArray [psJsonQuote "boolAnd"]
  | PsJsIrBinaryOp.boolOr => psJsonArray [psJsonQuote "boolOr"]
  | PsJsIrBinaryOp.boolEq => psJsonArray [psJsonQuote "boolEq"]
  | PsJsIrBinaryOp.boolNe => psJsonArray [psJsonQuote "boolNe"]
  | PsJsIrBinaryOp.stringConcat => psJsonArray [psJsonQuote "stringConcat"]
  | PsJsIrBinaryOp.stringEq => psJsonArray [psJsonQuote "stringEq"]
  | PsJsIrBinaryOp.machineInt type operation =>
      psJsonArray
        [
          psJsonQuote "machineInt",
          psJsIrEncodeMachineType type,
          psJsIrEncodeIntegerBinary operation
        ]
  | PsJsIrBinaryOp.machineIntCompare operation =>
      psJsonArray
        [
          psJsonQuote "machineIntCompare",
          psJsIrEncodeIntegerCompare operation
        ]
  | PsJsIrBinaryOp.floatBinary type operation =>
      psJsonArray
        [
          psJsonQuote "floatBinary",
          psJsIrEncodeFloatingType type,
          psJsIrEncodeFloatBinary operation
        ]
  | PsJsIrBinaryOp.floatCompare operation =>
      psJsonArray
        [
          psJsonQuote "floatCompare",
          psJsIrEncodeFloatCompare operation
        ]

def psJsIrEncodeRuntime
    (value : PsJsIrRuntimeOp) : String :=
  match value with
  | PsJsIrRuntimeOp.uint8OfNat => "uint8OfNat"
  | PsJsIrRuntimeOp.natSub => "natSub"
  | PsJsIrRuntimeOp.natDiv => "natDiv"
  | PsJsIrRuntimeOp.natMod => "natMod"
  | PsJsIrRuntimeOp.intNegSucc => "intNegSucc"
  | PsJsIrRuntimeOp.intRepr => "intRepr"
  | PsJsIrRuntimeOp.charOfNat => "charOfNat"
  | PsJsIrRuntimeOp.charToNat => "charToNat"
  | PsJsIrRuntimeOp.stringLength => "stringLength"
  | PsJsIrRuntimeOp.stringUtf8ByteSize => "stringUtf8ByteSize"
  | PsJsIrRuntimeOp.stringNext => "stringNext"
  | PsJsIrRuntimeOp.stringGet => "stringGet"
  | PsJsIrRuntimeOp.stringAtEnd => "stringAtEnd"
  | PsJsIrRuntimeOp.stringExtract => "stringExtract"
  | PsJsIrRuntimeOp.arrayEmptyWithCapacity => "arrayEmptyWithCapacity"
  | PsJsIrRuntimeOp.arraySize => "arraySize"
  | PsJsIrRuntimeOp.arrayPush => "arrayPush"
  | PsJsIrRuntimeOp.arrayGet => "arrayGet"
  | PsJsIrRuntimeOp.arrayGetD => "arrayGetD"
  | PsJsIrRuntimeOp.arraySet => "arraySet"
  | PsJsIrRuntimeOp.arraySetIfInBounds => "arraySetIfInBounds"
  | PsJsIrRuntimeOp.arrayMap => "arrayMap"
  | PsJsIrRuntimeOp.arrayFoldl => "arrayFoldl"

def psJsIrEncodeStringValues
    (values : List String) :
    Except PsJsIrEncodeError String :=
  Except.ok
    (psJsonArray
      (psListMap psJsonQuote values))

def psJsIrEncodeFieldWith
    (encode :
      PsJsIrExpr ->
        Except PsJsIrEncodeError String)
    (field : String × PsJsIrExpr) :
    Except PsJsIrEncodeError String :=
  psJsIrEncodeValues
    [
      psJsIrEncodeText (Prod.fst field),
      encode (Prod.snd field)
    ]

def psJsIrEncodeBinding
    (binding : PsJsIrMatchBinding) :
    Except PsJsIrEncodeError String :=
  psJsIrEncodeValues
    [
      psJsIrEncodeText binding.field,
      psJsIrEncodeText binding.name
    ]

def psJsIrEncodeAlternativeWith
    (encode :
      PsJsIrExpr ->
        Except PsJsIrEncodeError String)
    (value :
      String ×
        List PsJsIrMatchBinding ×
        PsJsIrExpr) :
    Except PsJsIrEncodeError String :=
  let payload :
      List PsJsIrMatchBinding × PsJsIrExpr :=
    Prod.snd value;
  psJsIrEncodeValues
    [
      psJsIrEncodeText (Prod.fst value),
      psJsIrEncodeValues
        (psListMap
          psJsIrEncodeBinding
          (Prod.fst payload)),
      encode (Prod.snd payload)
    ]

def psJsIrEncodeExprWithFuel
    (fuel : Nat) :
    PsJsIrExpr ->
      Except PsJsIrEncodeError String :=
  match fuel with
  | Nat.zero =>
      fun (_value : PsJsIrExpr) =>
        Except.error PsJsIrEncodeError.depthExhausted
  | Nat.succ remaining =>
      let smaller :
          PsJsIrExpr ->
            Except PsJsIrEncodeError String :=
        psJsIrEncodeExprWithFuel remaining;
      fun (value : PsJsIrExpr) =>
        match value with
        | PsJsIrExpr.literal literal =>
            psJsIrEncodeNode
              "literal"
              [psJsIrEncodeLiteral literal]
        | PsJsIrExpr.var name =>
            psJsIrEncodeNode
              "var"
              [psJsIrEncodeText name]
        | PsJsIrExpr.unary operation operand =>
            psJsIrEncodeNode
              "unary"
              [
                Except.ok
                  (psJsIrEncodeUnary operation),
                smaller operand
              ]
        | PsJsIrExpr.binary operation left right =>
            psJsIrEncodeNode
              "binary"
              [
                Except.ok
                  (psJsIrEncodeBinary operation),
                smaller left,
                smaller right
              ]
        | PsJsIrExpr.runtime operation arguments =>
            psJsIrEncodeNode
              "runtime"
              [
                psJsIrEncodeText
                  (psJsIrEncodeRuntime operation),
                psJsIrEncodeValues
                  (psListMap smaller arguments)
              ]
        | PsJsIrExpr.lambda parameters body =>
            psJsIrEncodeNode
              "lambda"
              [
                psJsIrEncodeStringValues parameters,
                smaller body
              ]
        | PsJsIrExpr.call fn arguments =>
            psJsIrEncodeNode
              "call"
              [
                smaller fn,
                psJsIrEncodeValues
                  (psListMap smaller arguments)
              ]
        | PsJsIrExpr.letE name bound body =>
            psJsIrEncodeNode
              "let"
              [
                psJsIrEncodeText name,
                smaller bound,
                smaller body
              ]
        | PsJsIrExpr.ifE condition yes no =>
            psJsIrEncodeNode
              "if"
              [
                smaller condition,
                smaller yes,
                smaller no
              ]
        | PsJsIrExpr.record fields =>
            psJsIrEncodeNode
              "record"
              [
                psJsIrEncodeValues
                  (psListMap
                    (psJsIrEncodeFieldWith smaller)
                    fields)
              ]
        | PsJsIrExpr.projection target field =>
            psJsIrEncodeNode
              "projection"
              [
                smaller target,
                psJsIrEncodeText field
              ]
        | PsJsIrExpr.constructor constructorName fields =>
            psJsIrEncodeNode
              "constructor"
              [
                psJsIrEncodeText constructorName,
                psJsIrEncodeValues
                  (psListMap
                    (psJsIrEncodeFieldWith smaller)
                    fields)
              ]
        | PsJsIrExpr.matchE scrutinee alternatives =>
            psJsIrEncodeNode
              "match"
              [
                smaller scrutinee,
                psJsIrEncodeValues
                  (psListMap
                    (psJsIrEncodeAlternativeWith smaller)
                    alternatives)
              ]

def psJsIrEncodeImport
    (value : PsJsIrImport) :
    Except PsJsIrEncodeError String :=
  psJsIrEncodeValues
    [
      psJsIrEncodeText value.localName,
      psJsIrEncodeText value.source,
      psJsIrEncodeText value.importedName
    ]

def psJsIrEncodeParameter
    (value : PsJsIrParameter) :
    Except PsJsIrEncodeError String :=
  psJsIrEncodeText value.name

def psJsIrEncodeDeclaration
    (value : PsJsIrDeclaration) :
    Except PsJsIrEncodeError String :=
  psJsIrEncodeValues
    [
      psJsIrEncodeText value.name,
      psJsIrEncodeValues
        (psListMap
          psJsIrEncodeParameter
          value.parameters),
      psJsIrEncodeExprWithFuel
        65536
        value.body
    ]

def psJsIrEncodeModule
    (value : PsJsIrModule) :
    Except PsJsIrEncodeError String :=
  psJsIrEncodeNode
    "psc-js-ir-json/1"
    [
      psJsIrEncodeValues
        (psListMap psJsIrEncodeImport value.imports),
      psJsIrEncodeValues
        (psListMap
          psJsIrEncodeDeclaration
          value.declarations)
    ]
