from pathlib import Path

path = Path('selfhost/packages/backend-wasm/src/Ps/BackendWasm/RuntimeNat.lean')
text = path.read_text()
old = '''      parameters := [PsWasmValueType.i32]
      results := [psWasmNatRef]
      locals := []
      body := [
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.i32Const 0,
        PsWasmInstruction.i32Eq,
        PsWasmInstruction.ifStart (some psWasmNatRef),
          PsWasmInstruction.call psWasmNatZeroFn,
        PsWasmInstruction.else_,
          PsWasmInstruction.localGet 0,
          PsWasmInstruction.i32Const 1,
          PsWasmInstruction.i32ShrU,
          PsWasmInstruction.call psWasmNatOfU32Fn,
          PsWasmInstruction.localGet 0,
          PsWasmInstruction.i32Const 1,
          PsWasmInstruction.i32And,
          PsWasmInstruction.ifStart (some psWasmNatRef),
            PsWasmInstruction.call psWasmNatBit1Fn,
          PsWasmInstruction.else_,
            PsWasmInstruction.call psWasmNatMkBit0Fn,
          PsWasmInstruction.end_,
        PsWasmInstruction.end_
      ]
'''
new = '''      parameters := [PsWasmValueType.i32]
      results := [psWasmNatRef]
      locals := [psWasmNatRef]
      body := [
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.i32Const 0,
        PsWasmInstruction.i32Eq,
        PsWasmInstruction.ifStart (some psWasmNatRef),
          PsWasmInstruction.call psWasmNatZeroFn,
        PsWasmInstruction.else_,
          PsWasmInstruction.localGet 0,
          PsWasmInstruction.i32Const 1,
          PsWasmInstruction.i32ShrU,
          PsWasmInstruction.call psWasmNatOfU32Fn,
          PsWasmInstruction.localSet 1,
          PsWasmInstruction.localGet 0,
          PsWasmInstruction.i32Const 1,
          PsWasmInstruction.i32And,
          PsWasmInstruction.ifStart (some psWasmNatRef),
            PsWasmInstruction.localGet 1,
            PsWasmInstruction.call psWasmNatBit1Fn,
          PsWasmInstruction.else_,
            PsWasmInstruction.localGet 1,
            PsWasmInstruction.call psWasmNatMkBit0Fn,
          PsWasmInstruction.end_,
        PsWasmInstruction.end_
      ]
'''
count = text.count(old)
if count != 1:
    raise SystemExit(f'expected one Nat.ofU32 bridge body, found {count}')
path.write_text(text.replace(old, new, 1))
print('WASM_ARRAY_NAT_U32_FIX: APPLIED')
