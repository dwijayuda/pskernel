import Ps.BackendWasm.RuntimeNat

-- Exact pre-optimization function; every other runtime function is shared.
def psWasmNatDivModReference : PsWasmFunction :=
{
      name := psWasmNatDivModFn
      typeName := Option.none
      parameters := [psWasmNatRef, psWasmNatRef]
      results := [psWasmNatDivModRef]
      locals := [
        psWasmNatRef,
        psWasmNatDivModRef,
        psWasmNatRef,
        psWasmNatRef,
        psWasmNatRef
      ]
      body := [
        PsWasmInstruction.localGet 1,
        PsWasmInstruction.refTest psWasmNatZeroName,
        PsWasmInstruction.ifStart (Option.some psWasmNatDivModRef),
          PsWasmInstruction.call psWasmNatZeroFn,
          PsWasmInstruction.localGet 0,
          PsWasmInstruction.structNew psWasmNatDivModName,
        PsWasmInstruction.else_,
          PsWasmInstruction.localGet 0,
          PsWasmInstruction.refTest psWasmNatZeroName,
          PsWasmInstruction.ifStart (Option.some psWasmNatDivModRef),
            PsWasmInstruction.call psWasmNatZeroFn,
            PsWasmInstruction.call psWasmNatZeroFn,
            PsWasmInstruction.structNew psWasmNatDivModName,
          PsWasmInstruction.else_,
            PsWasmInstruction.localGet 0,
            PsWasmInstruction.call psWasmNatHalfFn,
            PsWasmInstruction.localSet 2,
            PsWasmInstruction.localGet 2,
            PsWasmInstruction.localGet 1,
            PsWasmInstruction.call psWasmNatDivModFn,
            PsWasmInstruction.localSet 3,
            PsWasmInstruction.localGet 3,
            PsWasmInstruction.structGet psWasmNatDivModName 0,
            PsWasmInstruction.localSet 4,
            PsWasmInstruction.localGet 3,
            PsWasmInstruction.structGet psWasmNatDivModName 1,
            PsWasmInstruction.localSet 5,
            PsWasmInstruction.localGet 0,
            PsWasmInstruction.call psWasmNatLowFn,
            PsWasmInstruction.ifStart (Option.some psWasmNatRef),
              PsWasmInstruction.localGet 5,
              PsWasmInstruction.call psWasmNatBit1Fn,
            PsWasmInstruction.else_,
              PsWasmInstruction.localGet 5,
              PsWasmInstruction.call psWasmNatMkBit0Fn,
            PsWasmInstruction.end_,
            PsWasmInstruction.localSet 6,
            PsWasmInstruction.localGet 6,
            PsWasmInstruction.localGet 1,
            PsWasmInstruction.call psWasmNatCmpFn,
            PsWasmInstruction.i32Const 0,
            PsWasmInstruction.i32GeS,
            PsWasmInstruction.ifStart (Option.some psWasmNatDivModRef),
              PsWasmInstruction.localGet 4,
              PsWasmInstruction.call psWasmNatBit1Fn,
              PsWasmInstruction.localGet 6,
              PsWasmInstruction.localGet 1,
              PsWasmInstruction.call psWasmNatSubGeFn,
              PsWasmInstruction.structNew psWasmNatDivModName,
            PsWasmInstruction.else_,
              PsWasmInstruction.localGet 4,
              PsWasmInstruction.call psWasmNatMkBit0Fn,
              PsWasmInstruction.localGet 6,
              PsWasmInstruction.structNew psWasmNatDivModName,
            PsWasmInstruction.end_,
          PsWasmInstruction.end_,
        PsWasmInstruction.end_
      ]
    }
