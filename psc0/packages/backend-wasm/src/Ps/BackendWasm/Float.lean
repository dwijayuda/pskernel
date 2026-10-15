import Ps.BackendWasm.RuntimeBuilder

namespace PsWasm

-- Native NaNs denote the unique logical NaN. Observe exactly Lean 4.35.0's
-- canonical quiet-NaN bits; all other patterns, including -0, are unchanged.
def floatRuntime : Except String (List RuntimeDefinition) := do
  let mut definitions := []
  for (suffix, bits, value, fromBits, toBits, ne, canonical) in
      [("32", PsWasmValueType.i32, PsWasmValueType.f32,
        PsWasmWordOp.f32ReinterpretI32, PsWasmWordOp.i32ReinterpretF32,
        PsWasmInstruction.f32Ne, R.i32 2143289344),
       ("64", .i64, .f64, .f64ReinterpretI64, .i64ReinterpretF64,
        .f64Ne, R.i64 9221120237041090560)] do
    let prefix := "__ps_float" ++ suffix
    definitions := definitions ++ [
      ← runtimeDefinition (prefix ++ "_to_bits") [("value", value)] [bits] []
        (.ite (some bits) (.op ne [.get "value", .get "value"]) canonical
          (.op (.word toBits) [.get "value"])),
      ← runtimeDefinition (prefix ++ "_of_bits") [("bits", bits)] [value] []
        (.call (prefix ++ "_canonical")
          [.op (.word fromBits) [.get "bits"]]),
      ← runtimeDefinition (prefix ++ "_canonical") [("value", value)] [value] []
        (.ite (some value) (.op ne [.get "value", .get "value"])
          (.op (.word fromBits) [canonical]) (.get "value"))]
  return definitions

end PsWasm
