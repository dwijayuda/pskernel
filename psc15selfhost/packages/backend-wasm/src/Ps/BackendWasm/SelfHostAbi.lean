import Ps.BackendWasm.RuntimeString
import Ps.BackendWasm.Type
import Ps.Foundation.List

def psWasmSelfHostAbiStringNewName : String :=
  "__ps_selfhost_string_new"

def psWasmSelfHostAbiStringSetName : String :=
  "__ps_selfhost_string_set"

def psWasmSelfHostAbiBytesSizeName : String :=
  "__ps_selfhost_bytes_size"

def psWasmSelfHostAbiBytesGetName : String :=
  "__ps_selfhost_bytes_get"

def psWasmSelfHostAbiByteArrayName : String :=
  "ProofScript.Array$U8"

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
      name := psWasmSelfHostAbiBytesSizeName
      typeName := Option.none
      parameters := [
        PsWasmValueType.refT psWasmSelfHostAbiByteArrayName
      ]
      results := [PsWasmValueType.i32]
      locals := []
      body := [
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.arrayLen
      ]
    },
    {
      name := psWasmSelfHostAbiBytesGetName
      typeName := Option.none
      parameters := [
        PsWasmValueType.refT psWasmSelfHostAbiByteArrayName,
        PsWasmValueType.i32
      ]
      results := [PsWasmValueType.i32]
      locals := []
      body := [
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.localGet 1,
        PsWasmInstruction.arrayGetU psWasmSelfHostAbiByteArrayName
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
      psWasmSelfHostAbiBytesSizeName
      psWasmSelfHostAbiBytesSizeName,
    Prod.mk
      psWasmSelfHostAbiBytesGetName
      psWasmSelfHostAbiBytesGetName
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
