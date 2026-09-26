from pathlib import Path

path = Path("selfhost/packages/backend-wasm/src/Ps/BackendWasm/Lower.lean")
text = path.read_text()

old_nat = '''      | .intrinsic operation typeArguments arguments =>
          psWasmIntrinsicUsesNat operation
            || typeArguments.any psWasmTypeUsesNat
            || arguments.any uses'''
new_nat = '''      | .intrinsic operation arguments =>
          psWasmIntrinsicUsesNat operation
            || arguments.any uses'''

old_int = '''      | .intrinsic operation typeArguments arguments =>
          psWasmIntrinsicUsesInt operation
            || typeArguments.any psWasmTypeUsesInt
            || arguments.any uses'''
new_int = '''      | .intrinsic operation arguments =>
          psWasmIntrinsicUsesInt operation
            || arguments.any uses'''

if old_nat in text:
    text = text.replace(old_nat, new_nat, 1)
elif new_nat not in text:
    raise SystemExit("Nat intrinsic-use scanner shape is neither stale nor adapted")

if old_int in text:
    text = text.replace(old_int, new_int, 1)
elif new_int not in text:
    raise SystemExit("Int intrinsic-use scanner shape is neither stale nor adapted")

if "intrinsic operation typeArguments arguments" in text:
    raise SystemExit("stale three-argument intrinsic pattern remains")

path.write_text(text)
