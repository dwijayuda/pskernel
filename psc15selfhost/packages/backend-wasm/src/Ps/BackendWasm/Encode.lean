import Ps.BackendWasm.Model
import Ps.Bridge.Json
import Ps.Foundation.List

inductive PsWasmIrEncodeError where
  | unsupportedInstruction

def psWasmIrEncodeValues
    (values : List (Except PsWasmIrEncodeError String)) :
    Except PsWasmIrEncodeError String :=
  let unwrap :
      Except PsWasmIrEncodeError String ->
      Except PsWasmIrEncodeError String :=
    fun (value : Except PsWasmIrEncodeError String) =>
      value;
  match psListMapExcept unwrap values with
  | Except.error error =>
      Except.error error
  | Except.ok encoded =>
      Except.ok (psJsonArray encoded)

def psWasmIrEncodeNode
    (tag : String)
    (values : List (Except PsWasmIrEncodeError String)) :
    Except PsWasmIrEncodeError String :=
  psWasmIrEncodeValues
    (List.cons
      (Except.ok (psJsonQuote tag))
      values)

def psWasmIrEncodeText
    (value : String) :
    Except PsWasmIrEncodeError String :=
  Except.ok (psJsonQuote value)

def psWasmIrEncodeNat
    (value : Nat) :
    Except PsWasmIrEncodeError String :=
  psWasmIrEncodeText (psNatToString value)

def psWasmIrEncodeInt
    (value : Int) :
    Except PsWasmIrEncodeError String :=
  psWasmIrEncodeText (Int.repr value)

def psWasmIrEncodeBool
    (value : Bool) :
    Except PsWasmIrEncodeError String :=
  if value then
    Except.ok "true"
  else
    Except.ok "false"

def psWasmIrEncodeOptionText
    (value : Option String) :
    Except PsWasmIrEncodeError String :=
  match value with
  | Option.none =>
      psWasmIrEncodeNode "none" List.nil
  | Option.some text =>
      psWasmIrEncodeNode
        "some"
        [psWasmIrEncodeText text]

def psWasmIrEncodeValueType
    (value : PsWasmValueType) :
    Except PsWasmIrEncodeError String :=
  match value with
  | PsWasmValueType.i32 =>
      psWasmIrEncodeNode "i32" List.nil
  | PsWasmValueType.i64 =>
      psWasmIrEncodeNode "i64" List.nil
  | PsWasmValueType.f32 =>
      psWasmIrEncodeNode "f32" List.nil
  | PsWasmValueType.f64 =>
      psWasmIrEncodeNode "f64" List.nil
  | PsWasmValueType.refT name =>
      psWasmIrEncodeNode
        "ref"
        [psWasmIrEncodeText name]
  | PsWasmValueType.funcRef =>
      psWasmIrEncodeNode "funcRef" List.nil
  | PsWasmValueType.noValue =>
      psWasmIrEncodeNode "noValue" List.nil

def psWasmIrEncodeStorageType
    (value : PsWasmStorageType) :
    Except PsWasmIrEncodeError String :=
  match value with
  | PsWasmStorageType.value type =>
      psWasmIrEncodeNode
        "value"
        [psWasmIrEncodeValueType type]
  | PsWasmStorageType.packedI8 =>
      psWasmIrEncodeNode "packedI8" List.nil
  | PsWasmStorageType.packedI16 =>
      psWasmIrEncodeNode "packedI16" List.nil

def psWasmIrEncodeInstruction
    (value : PsWasmInstruction) :
    Except PsWasmIrEncodeError String :=
  match value with
  | PsWasmInstruction.localGet index =>
      psWasmIrEncodeNode
        "localGet"
        [psWasmIrEncodeNat index]
  | PsWasmInstruction.localSet index =>
      psWasmIrEncodeNode
        "localSet"
        [psWasmIrEncodeNat index]
  | PsWasmInstruction.drop =>
      psWasmIrEncodeNode "drop" List.nil
  | PsWasmInstruction.unreachable =>
      psWasmIrEncodeNode "unreachable" List.nil
  | PsWasmInstruction.call name =>
      psWasmIrEncodeNode
        "call"
        [psWasmIrEncodeText name]
  | PsWasmInstruction.returnCall name =>
      psWasmIrEncodeNode
        "returnCall"
        [psWasmIrEncodeText name]
  | PsWasmInstruction.return_ =>
      psWasmIrEncodeNode "return" List.nil
  | PsWasmInstruction.ifStart result =>
      match result with
      | Option.none =>
          psWasmIrEncodeNode
            "ifStart"
            [psWasmIrEncodeNode "none" List.nil]
      | Option.some type =>
          psWasmIrEncodeNode
            "ifStart"
            [
              psWasmIrEncodeNode
                "some"
                [psWasmIrEncodeValueType type]
            ]
  | PsWasmInstruction.else_ =>
      psWasmIrEncodeNode "else" List.nil
  | PsWasmInstruction.end_ =>
      psWasmIrEncodeNode "end" List.nil
  | PsWasmInstruction.i32Const integer =>
      psWasmIrEncodeNode
        "i32Const"
        [psWasmIrEncodeInt integer]
  | PsWasmInstruction.i64Const integer =>
      psWasmIrEncodeNode
        "i64Const"
        [psWasmIrEncodeInt integer]
  | PsWasmInstruction.f32ConstBits _ =>
      Except.error
        PsWasmIrEncodeError.unsupportedInstruction
  | PsWasmInstruction.f64ConstBits _ =>
      Except.error
        PsWasmIrEncodeError.unsupportedInstruction
  | PsWasmInstruction.i32Add => psWasmIrEncodeNode "i32Add" List.nil
  | PsWasmInstruction.i32Sub => psWasmIrEncodeNode "i32Sub" List.nil
  | PsWasmInstruction.i32Mul => psWasmIrEncodeNode "i32Mul" List.nil
  | PsWasmInstruction.i32And => psWasmIrEncodeNode "i32And" List.nil
  | PsWasmInstruction.i32Or => psWasmIrEncodeNode "i32Or" List.nil
  | PsWasmInstruction.i32Xor => psWasmIrEncodeNode "i32Xor" List.nil
  | PsWasmInstruction.i32ShrU => psWasmIrEncodeNode "i32ShrU" List.nil
  | PsWasmInstruction.i32Extend8S => psWasmIrEncodeNode "i32Extend8S" List.nil
  | PsWasmInstruction.i32Extend16S => psWasmIrEncodeNode "i32Extend16S" List.nil
  | PsWasmInstruction.i32Eq => psWasmIrEncodeNode "i32Eq" List.nil
  | PsWasmInstruction.i32Ne => psWasmIrEncodeNode "i32Ne" List.nil
  | PsWasmInstruction.i32LtS => psWasmIrEncodeNode "i32LtS" List.nil
  | PsWasmInstruction.i32LtU => psWasmIrEncodeNode "i32LtU" List.nil
  | PsWasmInstruction.i32LeS => psWasmIrEncodeNode "i32LeS" List.nil
  | PsWasmInstruction.i32LeU => psWasmIrEncodeNode "i32LeU" List.nil
  | PsWasmInstruction.i32GtS => psWasmIrEncodeNode "i32GtS" List.nil
  | PsWasmInstruction.i32GtU => psWasmIrEncodeNode "i32GtU" List.nil
  | PsWasmInstruction.i32GeS => psWasmIrEncodeNode "i32GeS" List.nil
  | PsWasmInstruction.i32GeU => psWasmIrEncodeNode "i32GeU" List.nil
  | PsWasmInstruction.i64Add => psWasmIrEncodeNode "i64Add" List.nil
  | PsWasmInstruction.i64Sub => psWasmIrEncodeNode "i64Sub" List.nil
  | PsWasmInstruction.i64Mul => psWasmIrEncodeNode "i64Mul" List.nil
  | PsWasmInstruction.i64And => psWasmIrEncodeNode "i64And" List.nil
  | PsWasmInstruction.i64Or => psWasmIrEncodeNode "i64Or" List.nil
  | PsWasmInstruction.i64Xor => psWasmIrEncodeNode "i64Xor" List.nil
  | PsWasmInstruction.i64Eq => psWasmIrEncodeNode "i64Eq" List.nil
  | PsWasmInstruction.i64Ne => psWasmIrEncodeNode "i64Ne" List.nil
  | PsWasmInstruction.i64LtS => psWasmIrEncodeNode "i64LtS" List.nil
  | PsWasmInstruction.i64LtU => psWasmIrEncodeNode "i64LtU" List.nil
  | PsWasmInstruction.i64LeS => psWasmIrEncodeNode "i64LeS" List.nil
  | PsWasmInstruction.i64LeU => psWasmIrEncodeNode "i64LeU" List.nil
  | PsWasmInstruction.i64GtS => psWasmIrEncodeNode "i64GtS" List.nil
  | PsWasmInstruction.i64GtU => psWasmIrEncodeNode "i64GtU" List.nil
  | PsWasmInstruction.i64GeS => psWasmIrEncodeNode "i64GeS" List.nil
  | PsWasmInstruction.i64GeU => psWasmIrEncodeNode "i64GeU" List.nil
  | PsWasmInstruction.f32Add => psWasmIrEncodeNode "f32Add" List.nil
  | PsWasmInstruction.f32Sub => psWasmIrEncodeNode "f32Sub" List.nil
  | PsWasmInstruction.f32Mul => psWasmIrEncodeNode "f32Mul" List.nil
  | PsWasmInstruction.f32Div => psWasmIrEncodeNode "f32Div" List.nil
  | PsWasmInstruction.f32Eq => psWasmIrEncodeNode "f32Eq" List.nil
  | PsWasmInstruction.f32Ne => psWasmIrEncodeNode "f32Ne" List.nil
  | PsWasmInstruction.f32Lt => psWasmIrEncodeNode "f32Lt" List.nil
  | PsWasmInstruction.f32Le => psWasmIrEncodeNode "f32Le" List.nil
  | PsWasmInstruction.f32Gt => psWasmIrEncodeNode "f32Gt" List.nil
  | PsWasmInstruction.f32Ge => psWasmIrEncodeNode "f32Ge" List.nil
  | PsWasmInstruction.f64Add => psWasmIrEncodeNode "f64Add" List.nil
  | PsWasmInstruction.f64Sub => psWasmIrEncodeNode "f64Sub" List.nil
  | PsWasmInstruction.f64Mul => psWasmIrEncodeNode "f64Mul" List.nil
  | PsWasmInstruction.f64Div => psWasmIrEncodeNode "f64Div" List.nil
  | PsWasmInstruction.f64Eq => psWasmIrEncodeNode "f64Eq" List.nil
  | PsWasmInstruction.f64Ne => psWasmIrEncodeNode "f64Ne" List.nil
  | PsWasmInstruction.f64Lt => psWasmIrEncodeNode "f64Lt" List.nil
  | PsWasmInstruction.f64Le => psWasmIrEncodeNode "f64Le" List.nil
  | PsWasmInstruction.f64Gt => psWasmIrEncodeNode "f64Gt" List.nil
  | PsWasmInstruction.f64Ge => psWasmIrEncodeNode "f64Ge" List.nil
  | PsWasmInstruction.structNew name =>
      psWasmIrEncodeNode
        "structNew"
        [psWasmIrEncodeText name]
  | PsWasmInstruction.structGet name index =>
      psWasmIrEncodeNode
        "structGet"
        [psWasmIrEncodeText name, psWasmIrEncodeNat index]
  | PsWasmInstruction.structGetS name index =>
      psWasmIrEncodeNode
        "structGetS"
        [psWasmIrEncodeText name, psWasmIrEncodeNat index]
  | PsWasmInstruction.structGetU name index =>
      psWasmIrEncodeNode
        "structGetU"
        [psWasmIrEncodeText name, psWasmIrEncodeNat index]
  | PsWasmInstruction.arrayNew name =>
      psWasmIrEncodeNode
        "arrayNew"
        [psWasmIrEncodeText name]
  | PsWasmInstruction.arrayNewDefault name =>
      psWasmIrEncodeNode
        "arrayNewDefault"
        [psWasmIrEncodeText name]
  | PsWasmInstruction.arrayNewFixed name length =>
      psWasmIrEncodeNode
        "arrayNewFixed"
        [psWasmIrEncodeText name, psWasmIrEncodeNat length]
  | PsWasmInstruction.arrayGet name =>
      psWasmIrEncodeNode
        "arrayGet"
        [psWasmIrEncodeText name]
  | PsWasmInstruction.arrayGetS name =>
      psWasmIrEncodeNode
        "arrayGetS"
        [psWasmIrEncodeText name]
  | PsWasmInstruction.arrayGetU name =>
      psWasmIrEncodeNode
        "arrayGetU"
        [psWasmIrEncodeText name]
  | PsWasmInstruction.arraySet name =>
      psWasmIrEncodeNode
        "arraySet"
        [psWasmIrEncodeText name]
  | PsWasmInstruction.arrayLen =>
      psWasmIrEncodeNode "arrayLen" List.nil
  | PsWasmInstruction.arrayCopy destination source =>
      psWasmIrEncodeNode
        "arrayCopy"
        [psWasmIrEncodeText destination, psWasmIrEncodeText source]
  | PsWasmInstruction.refTest name =>
      psWasmIrEncodeNode
        "refTest"
        [psWasmIrEncodeText name]
  | PsWasmInstruction.refCast name =>
      psWasmIrEncodeNode
        "refCast"
        [psWasmIrEncodeText name]
  | PsWasmInstruction.refFunc name =>
      psWasmIrEncodeNode
        "refFunc"
        [psWasmIrEncodeText name]
  | PsWasmInstruction.refCastFunction name =>
      psWasmIrEncodeNode
        "refCastFunction"
        [psWasmIrEncodeText name]
  | PsWasmInstruction.callRef name =>
      psWasmIrEncodeNode
        "callRef"
        [psWasmIrEncodeText name]
  | PsWasmInstruction.returnCallRef name =>
      psWasmIrEncodeNode
        "returnCallRef"
        [psWasmIrEncodeText name]

def psWasmIrEncodeStructField
    (value : PsWasmStructField) :
    Except PsWasmIrEncodeError String :=
  psWasmIrEncodeValues
    [
      psWasmIrEncodeText value.name,
      psWasmIrEncodeStorageType value.storageType
    ]

def psWasmIrEncodeStructType
    (value : PsWasmStructType) :
    Except PsWasmIrEncodeError String :=
  psWasmIrEncodeValues
    [
      psWasmIrEncodeText value.name,
      psWasmIrEncodeOptionText value.superType,
      psWasmIrEncodeBool value.isFinal,
      psWasmIrEncodeValues
        (psListMap
          psWasmIrEncodeStructField
          value.fields)
    ]

def psWasmIrEncodeArrayType
    (value : PsWasmArrayType) :
    Except PsWasmIrEncodeError String :=
  psWasmIrEncodeValues
    [
      psWasmIrEncodeText value.name,
      psWasmIrEncodeStorageType value.elementType,
      psWasmIrEncodeBool value.mutable
    ]

def psWasmIrEncodeValueTypes
    (values : List PsWasmValueType) :
    Except PsWasmIrEncodeError String :=
  psWasmIrEncodeValues
    (psListMap
      psWasmIrEncodeValueType
      values)

def psWasmIrEncodeFunctionType
    (value : PsWasmFunctionType) :
    Except PsWasmIrEncodeError String :=
  psWasmIrEncodeValues
    [
      psWasmIrEncodeText value.name,
      psWasmIrEncodeValueTypes value.parameters,
      psWasmIrEncodeValueTypes value.results
    ]

def psWasmIrEncodeInstructions
    (values : List PsWasmInstruction) :
    Except PsWasmIrEncodeError String :=
  psWasmIrEncodeValues
    (psListMap
      psWasmIrEncodeInstruction
      values)

def psWasmIrEncodeFunction
    (value : PsWasmFunction) :
    Except PsWasmIrEncodeError String :=
  psWasmIrEncodeValues
    [
      psWasmIrEncodeText value.name,
      psWasmIrEncodeOptionText value.typeName,
      psWasmIrEncodeValueTypes value.parameters,
      psWasmIrEncodeValueTypes value.results,
      psWasmIrEncodeValueTypes value.locals,
      psWasmIrEncodeInstructions value.body
    ]

def psWasmIrEncodeExport
    (value : String × String) :
    Except PsWasmIrEncodeError String :=
  psWasmIrEncodeValues
    [
      psWasmIrEncodeText (Prod.fst value),
      psWasmIrEncodeText (Prod.snd value)
    ]

def psWasmIrEncodeTexts
    (values : List String) :
    Except PsWasmIrEncodeError String :=
  psWasmIrEncodeValues
    (psListMap psWasmIrEncodeText values)

def psWasmIrEncodeModule
    (value : PsWasmModule) :
    Except PsWasmIrEncodeError String :=
  psWasmIrEncodeNode
    "psc-wasm-ir-json/1"
    [
      psWasmIrEncodeValues
        (psListMap
          psWasmIrEncodeStructType
          value.structures),
      psWasmIrEncodeValues
        (psListMap
          psWasmIrEncodeArrayType
          value.arrays),
      psWasmIrEncodeValues
        (psListMap
          psWasmIrEncodeFunctionType
          value.functionTypes),
      psWasmIrEncodeValues
        (psListMap
          psWasmIrEncodeFunction
          value.functions),
      psWasmIrEncodeTexts value.functionRefs,
      psWasmIrEncodeValues
        (psListMap
          psWasmIrEncodeExport
          value.exports)
    ]
