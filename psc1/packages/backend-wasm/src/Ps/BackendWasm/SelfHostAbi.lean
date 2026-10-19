import Ps.BackendWasm.RuntimeString
import Ps.BackendWasm.Type
import Ps.Foundation.List

def psWasmSelfHostAbiStringNewName : String :=
  "__ps_selfhost_string_new"

def psWasmSelfHostAbiStringSetName : String :=
  "__ps_selfhost_string_set"

def psWasmSelfHostAbiStringFinishName : String :=
  "__ps_selfhost_string_finish"

def psWasmSelfHostAbiBytesIsNilName : String :=
  "__ps_selfhost_bytes_is_nil"

def psWasmSelfHostAbiBytesHeadName : String :=
  "__ps_selfhost_bytes_head"

def psWasmSelfHostAbiBytesTailName : String :=
  "__ps_selfhost_bytes_tail"

def psWasmSelfHostAbiByteListName : String :=
  "List$spec$U8"

def psWasmSelfHostAbiByteListNilName : String :=
  "List$spec$U8$nil"

def psWasmSelfHostAbiByteListConsName : String :=
  "List$spec$U8$cons"

def psWasmSelfHostAbiByteListRef : PsWasmValueType :=
  PsWasmValueType.refT psWasmSelfHostAbiByteListName

def psWasmSelfHostAbiFunctions : List PsWasmFunction :=
  [
    {
      name := psWasmSelfHostAbiStringNewName
      typeName := Option.none
      parameters := [PsWasmValueType.i32]
      results := [psWasmStringCharsRef]
      locals := []
      body := [
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.arrayNewDefault psWasmStringCharsName
      ]
    },
    {
      name := psWasmSelfHostAbiStringSetName
      typeName := Option.none
      parameters := [
        psWasmStringCharsRef,
        PsWasmValueType.i32,
        PsWasmValueType.i32
      ]
      results := []
      locals := []
      body := [
        PsWasmInstruction.localGet 2,
        PsWasmInstruction.call psWasmCharUtf8WidthFn,
        PsWasmInstruction.drop,
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.localGet 1,
        PsWasmInstruction.localGet 2,
        PsWasmInstruction.arraySet psWasmStringCharsName
      ]
    },
    {
      name := psWasmSelfHostAbiStringFinishName
      typeName := Option.none
      parameters := [psWasmStringCharsRef]
      results := [psWasmStringRef]
      locals := []
      body := [
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.call psWasmStringFromCharsFn
      ]
    },
    {
      name := psWasmSelfHostAbiBytesIsNilName
      typeName := Option.none
      parameters := [psWasmSelfHostAbiByteListRef]
      results := [PsWasmValueType.i32]
      locals := []
      body := [
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.refTest psWasmSelfHostAbiByteListNilName
      ]
    },
    {
      name := psWasmSelfHostAbiBytesHeadName
      typeName := Option.none
      parameters := [psWasmSelfHostAbiByteListRef]
      results := [PsWasmValueType.i32]
      locals := []
      body := [
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.refCast psWasmSelfHostAbiByteListConsName,
        PsWasmInstruction.structGetU
          psWasmSelfHostAbiByteListConsName
          0
      ]
    },
    {
      name := psWasmSelfHostAbiBytesTailName
      typeName := Option.none
      parameters := [psWasmSelfHostAbiByteListRef]
      results := [psWasmSelfHostAbiByteListRef]
      locals := []
      body := [
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.refCast psWasmSelfHostAbiByteListConsName,
        PsWasmInstruction.structGet
          psWasmSelfHostAbiByteListConsName
          1
      ]
    }
  ]

def psWasmSelfHostAbiExports : List (String × String) :=
  [
    Prod.mk
      psWasmSelfHostAbiStringNewName
      psWasmSelfHostAbiStringNewName,
    Prod.mk
      psWasmSelfHostAbiStringSetName
      psWasmSelfHostAbiStringSetName,
    Prod.mk
      psWasmSelfHostAbiStringFinishName
      psWasmSelfHostAbiStringFinishName,
    Prod.mk
      psWasmSelfHostAbiBytesIsNilName
      psWasmSelfHostAbiBytesIsNilName,
    Prod.mk
      psWasmSelfHostAbiBytesHeadName
      psWasmSelfHostAbiBytesHeadName,
    Prod.mk
      psWasmSelfHostAbiBytesTailName
      psWasmSelfHostAbiBytesTailName
  ]

def psWasmHasSelfHostByteListType
    (structures : List PsWasmStructType) (name : String) : Bool :=
  match structures with
  | List.nil => false
  | List.cons type rest =>
      if psStringEq type.name name then true
      else psWasmHasSelfHostByteListType rest name

def psWasmNeedsSelfHostGcAbi (module : PsWasmModule) : Bool :=
  if psWasmHasSelfHostByteListType module.structures psWasmSelfHostAbiByteListName then
    if psWasmHasSelfHostByteListType module.structures psWasmSelfHostAbiByteListNilName then
      psWasmHasSelfHostByteListType module.structures psWasmSelfHostAbiByteListConsName
    else false
  else false

def psWasmAddSelfHostGcAbi
    (module : PsWasmModule) : PsWasmModule :=
  if psWasmNeedsSelfHostGcAbi module then {
    structures := module.structures
    arrays := module.arrays
    functionTypes := module.functionTypes
    functions :=
      psListAppend
        module.functions
        psWasmSelfHostAbiFunctions
    functionRefs := module.functionRefs
    exports :=
      psListAppend
        module.exports
        psWasmSelfHostAbiExports
  } else module
