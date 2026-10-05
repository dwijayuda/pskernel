import Ps.BackendWasm.RuntimeInt
import Ps.BackendWasm.RuntimeString
import Ps.Foundation.List

def psWasmNatTenFn : String := "__ps_wasm_nat_ten"
def psWasmNatReprPositiveFn : String := "__ps_wasm_nat_repr_positive"
def psWasmNatReprFn : String := "__ps_wasm_nat_repr"
def psWasmIntReprFn : String := "__ps_wasm_int_repr"

def psWasmIntReprRuntimeFunctions : List PsWasmFunction :=
  [
    {
      name := psWasmNatTenFn
      typeName := Option.none
      parameters := []
      results := [psWasmNatRef]
      locals := []
      body := [
        PsWasmInstruction.call psWasmNatZeroFn,
        PsWasmInstruction.call psWasmNatBit1Fn,
        PsWasmInstruction.call psWasmNatMkBit0Fn,
        PsWasmInstruction.call psWasmNatBit1Fn,
        PsWasmInstruction.call psWasmNatMkBit0Fn
      ]
    },
    {
      name := psWasmNatReprPositiveFn
      typeName := Option.none
      parameters := [psWasmNatRef]
      results := [psWasmStringRef]
      locals := [
        psWasmNatRef,
        psWasmNatRef
      ]
      body := [
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.call psWasmNatTenFn,
        PsWasmInstruction.call psWasmNatDivFn,
        PsWasmInstruction.localSet 1,
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.call psWasmNatTenFn,
        PsWasmInstruction.call psWasmNatModFn,
        PsWasmInstruction.localSet 2,
        PsWasmInstruction.localGet 1,
        PsWasmInstruction.refTest psWasmNatZeroName,
        PsWasmInstruction.ifStart
          (Option.some psWasmStringRef),
          PsWasmInstruction.localGet 2,
          PsWasmInstruction.call psWasmNatToU32Fn,
          PsWasmInstruction.i32Const 48,
          PsWasmInstruction.i32Add,
          PsWasmInstruction.call psWasmStringSingletonFn,
        PsWasmInstruction.else_,
          PsWasmInstruction.localGet 1,
          PsWasmInstruction.call psWasmNatReprPositiveFn,
          PsWasmInstruction.localGet 2,
          PsWasmInstruction.call psWasmNatToU32Fn,
          PsWasmInstruction.i32Const 48,
          PsWasmInstruction.i32Add,
          PsWasmInstruction.call psWasmStringPushFn,
        PsWasmInstruction.end_
      ]
    },
    {
      name := psWasmNatReprFn
      typeName := Option.none
      parameters := [psWasmNatRef]
      results := [psWasmStringRef]
      locals := []
      body := [
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.refTest psWasmNatZeroName,
        PsWasmInstruction.ifStart
          (Option.some psWasmStringRef),
          PsWasmInstruction.i32Const 48,
          PsWasmInstruction.call psWasmStringSingletonFn,
        PsWasmInstruction.else_,
          PsWasmInstruction.localGet 0,
          PsWasmInstruction.call psWasmNatReprPositiveFn,
        PsWasmInstruction.end_
      ]
    },
    {
      name := psWasmIntReprFn
      typeName := Option.none
      parameters := [psWasmIntRef]
      results := [psWasmStringRef]
      locals := []
      body := [
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.structGet psWasmIntName 0,
        PsWasmInstruction.i32Const 0,
        PsWasmInstruction.i32LtS,
        PsWasmInstruction.ifStart
          (Option.some psWasmStringRef),
          PsWasmInstruction.i32Const 45,
          PsWasmInstruction.call psWasmStringSingletonFn,
          PsWasmInstruction.localGet 0,
          PsWasmInstruction.structGet psWasmIntName 1,
          PsWasmInstruction.call psWasmNatReprFn,
          PsWasmInstruction.call psWasmStringAppendFn,
        PsWasmInstruction.else_,
          PsWasmInstruction.localGet 0,
          PsWasmInstruction.structGet psWasmIntName 1,
          PsWasmInstruction.call psWasmNatReprFn,
        PsWasmInstruction.end_
      ]
    }
  ]
