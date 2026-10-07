import Ps.InterfaceIr.Model
import Ps.Bridge.Json
import Ps.Foundation.List

inductive PsForeignEncodeError where
  | depthExhausted

def psForeignEncodeValues
    (values : List (Except PsForeignEncodeError String)) :
    Except PsForeignEncodeError String :=
  let unwrap :
      Except PsForeignEncodeError String ->
      Except PsForeignEncodeError String :=
    fun (value : Except PsForeignEncodeError String) =>
      value;
  match psListMapExcept unwrap values with
  | Except.error error =>
      Except.error error
  | Except.ok encoded =>
      Except.ok (psJsonArray encoded)

def psForeignEncodeNode
    (tag : String)
    (values : List (Except PsForeignEncodeError String)) :
    Except PsForeignEncodeError String :=
  psForeignEncodeValues
    (List.cons
      (Except.ok (psJsonQuote tag))
      values)

def psForeignEncodeText
    (value : String) :
    Except PsForeignEncodeError String :=
  Except.ok (psJsonQuote value)

def psForeignEncodeBool
    (value : Bool) :
    Except PsForeignEncodeError String :=
  if value then
    Except.ok "true"
  else
    Except.ok "false"

def psForeignEncodeScalar
    (value : PsForeignScalar) : String :=
  match value with
  | PsForeignScalar.bool => psJsonQuote "bool"
  | PsForeignScalar.u8 => psJsonQuote "u8"
  | PsForeignScalar.u16 => psJsonQuote "u16"
  | PsForeignScalar.u32 => psJsonQuote "u32"
  | PsForeignScalar.u64 => psJsonQuote "u64"
  | PsForeignScalar.s8 => psJsonQuote "s8"
  | PsForeignScalar.s16 => psJsonQuote "s16"
  | PsForeignScalar.s32 => psJsonQuote "s32"
  | PsForeignScalar.s64 => psJsonQuote "s64"
  | PsForeignScalar.f32 => psJsonQuote "f32"
  | PsForeignScalar.f64 => psJsonQuote "f64"
  | PsForeignScalar.char => psJsonQuote "char"
  | PsForeignScalar.string => psJsonQuote "string"

def psForeignEncodeOptionTypeWith
    (encode :
      PsForeignType ->
        Except PsForeignEncodeError String)
    (value : Option PsForeignType) :
    Except PsForeignEncodeError String :=
  match value with
  | Option.none =>
      psForeignEncodeNode "none" List.nil
  | Option.some type =>
      psForeignEncodeNode
        "some"
        [encode type]

def psForeignEncodeTypeWithFuel
    (fuel : Nat) :
    PsForeignType ->
      Except PsForeignEncodeError String :=
  match fuel with
  | Nat.zero =>
      fun (_value : PsForeignType) =>
        Except.error PsForeignEncodeError.depthExhausted
  | Nat.succ remaining =>
      let smaller :
          PsForeignType ->
            Except PsForeignEncodeError String :=
        psForeignEncodeTypeWithFuel remaining;
      fun (value : PsForeignType) =>
        match value with
        | PsForeignType.scalar scalar =>
            psForeignEncodeNode
              "scalar"
              [Except.ok (psForeignEncodeScalar scalar)]
        | PsForeignType.named name =>
            psForeignEncodeNode
              "named"
              [psForeignEncodeText name]
        | PsForeignType.list element =>
            psForeignEncodeNode
              "list"
              [smaller element]
        | PsForeignType.option element =>
            psForeignEncodeNode
              "option"
              [smaller element]
        | PsForeignType.result ok error =>
            psForeignEncodeNode
              "result"
              [
                psForeignEncodeOptionTypeWith
                  smaller
                  ok,
                psForeignEncodeOptionTypeWith
                  smaller
                  error
              ]
        | PsForeignType.tuple elements =>
            psForeignEncodeNode
              "tuple"
              [
                psForeignEncodeValues
                  (psListMap smaller elements)
              ]
        | PsForeignType.own resource =>
            psForeignEncodeNode
              "own"
              [psForeignEncodeText resource]
        | PsForeignType.borrow resource =>
            psForeignEncodeNode
              "borrow"
              [psForeignEncodeText resource]
        | PsForeignType.future element =>
            psForeignEncodeNode
              "future"
              [
                psForeignEncodeOptionTypeWith
                  smaller
                  element
              ]
        | PsForeignType.stream element =>
            psForeignEncodeNode
              "stream"
              [
                psForeignEncodeOptionTypeWith
                  smaller
                  element
              ]

def psForeignEncodeType
    (depth : Nat)
    (value : PsForeignType) :
    Except PsForeignEncodeError String :=
  psForeignEncodeTypeWithFuel depth value

def psForeignEncodeField
    (depth : Nat)
    (value : PsForeignField) :
    Except PsForeignEncodeError String :=
  psForeignEncodeValues
    [
      psForeignEncodeText value.name,
      psForeignEncodeType depth value.type
    ]

def psForeignEncodeCase
    (depth : Nat)
    (value : PsForeignCase) :
    Except PsForeignEncodeError String :=
  psForeignEncodeValues
    [
      psForeignEncodeText value.name,
      psForeignEncodeOptionTypeWith
        (psForeignEncodeType depth)
        value.payload
    ]

def psForeignEncodeTexts
    (values : List String) :
    Except PsForeignEncodeError String :=
  psForeignEncodeValues
    (psListMap
      psForeignEncodeText
      values)

def psForeignEncodeDefinitionBody
    (depth : Nat)
    (value : PsForeignDefinitionBody) :
    Except PsForeignEncodeError String :=
  match value with
  | PsForeignDefinitionBody.alias type =>
      psForeignEncodeNode
        "alias"
        [psForeignEncodeType depth type]
  | PsForeignDefinitionBody.record fields =>
      psForeignEncodeNode
        "record"
        [
          psForeignEncodeValues
            (psListMap
              (psForeignEncodeField depth)
              fields)
        ]
  | PsForeignDefinitionBody.variant cases =>
      psForeignEncodeNode
        "variant"
        [
          psForeignEncodeValues
            (psListMap
              (psForeignEncodeCase depth)
              cases)
        ]
  | PsForeignDefinitionBody.enumeration cases =>
      psForeignEncodeNode
        "enum"
        [psForeignEncodeTexts cases]
  | PsForeignDefinitionBody.resource =>
      psForeignEncodeNode
        "resource"
        List.nil

def psForeignEncodeDefinition
    (depth : Nat)
    (value : PsForeignDefinition) :
    Except PsForeignEncodeError String :=
  psForeignEncodeValues
    [
      psForeignEncodeText value.name,
      psForeignEncodeDefinitionBody
        depth
        value.body
    ]

def psForeignEncodeFunction
    (depth : Nat)
    (value : PsForeignFunction) :
    Except PsForeignEncodeError String :=
  psForeignEncodeValues
    [
      psForeignEncodeText value.name,
      psForeignEncodeValues
        (psListMap
          (psForeignEncodeField depth)
          value.parameters),
      psForeignEncodeOptionTypeWith
        (psForeignEncodeType depth)
        value.result,
      psForeignEncodeBool value.asynchronous,
      psForeignEncodeTexts value.targets
    ]

def psForeignEncodeInterface
    (depth : Nat)
    (value : PsForeignInterface) :
    Except PsForeignEncodeError String :=
  psForeignEncodeValues
    [
      psForeignEncodeText value.name,
      psForeignEncodeValues
        (psListMap
          (psForeignEncodeDefinition depth)
          value.definitions),
      psForeignEncodeValues
        (psListMap
          (psForeignEncodeFunction depth)
          value.functions),
      psForeignEncodeTexts
        value.requiredCapabilities,
      psForeignEncodeTexts
        value.providedCapabilities
    ]

def psForeignEncodeWorld
    (depth : Nat)
    (value : PsForeignWorld) :
    Except PsForeignEncodeError String :=
  psForeignEncodeNode
    "psc-interface-ir-json/1"
    [
      psForeignEncodeText value.contract,
      psForeignEncodeText value.packageNamespace,
      psForeignEncodeText value.packageName,
      psForeignEncodeText value.name,
      psForeignEncodeValues
        (psListMap
          (psForeignEncodeInterface depth)
          value.interfaces),
      psForeignEncodeTexts value.imports,
      psForeignEncodeTexts value.exports
    ]
