import Ps.BackendWasm.RuntimeString
import Ps.BackendWasm.Type
import Ps.Foundation.List

def psWasmSelfHostAbiStringNewName : String :=
  "__ps_selfhost_string_new"

def psWasmSelfHostAbiStringSetName : String :=
  "__ps_selfhost_string_set"

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
      results := [psWasmStringRef]
      locals := []
      body := [
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.arrayNewDefault psWasmStringCharsName,
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.structNew psWasmStringName
      ]
    },
    {
      name := psWasmSelfHostAbiStringSetName
      typeName := Option.none
      parameters := [
        psWasmStringRef,
        PsWasmValueType.i32,
        PsWasmValueType.i32
      ]
      results := []
      locals := []
      body := [
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.structGet psWasmStringName 0,
        PsWasmInstruction.localGet 1,
        PsWasmInstruction.localGet 2,
        PsWasmInstruction.arraySet psWasmStringCharsName
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
      psWasmSelfHostAbiBytesIsNilName
      psWasmSelfHostAbiBytesIsNilName,
    Prod.mk
      psWasmSelfHostAbiBytesHeadName
      psWasmSelfHostAbiBytesHeadName,
    Prod.mk
      psWasmSelfHostAbiBytesTailName
      psWasmSelfHostAbiBytesTailName
  ]

def psWasmAddSelfHostGcAbi
    (module : PsWasmModule) : PsWasmModule :=
  {
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
  }
