import Ps.BackendWasm.RuntimeBuilder

namespace PsWasm

-- Native NaNs denote the unique logical NaN. Observe exactly Lean 4.35.0's
-- canonical quiet-NaN bits; all other patterns, including -0, are unchanged.
def floatRuntime : Except String (List RuntimeDefinition) := do
  let mut definitions := []
  for (suffix, bits, value, fromBits, toBits, ne, canonical) in
      [("32", PsWasmValueType.i32, PsWasmValueType.f32,
        PsWasmWordOp.f32ReinterpretI32, PsWasmWordOp.i32ReinterpretF32,
        PsWasmInstruction.f32Ne, RuntimeCode.i32 2143289344),
       ("64", .i64, .f64, .f64ReinterpretI64, .i64ReinterpretF64,
        .f64Ne, RuntimeCode.i64 9221120237041090560)] do
    let helperName := "__ps_float" ++ suffix
    definitions := definitions ++ [
      ← runtimeDefinition (helperName ++ "_to_bits") [("value", value)] [bits] []
        (.ite (some bits) (.op ne [.get "value", .get "value"]) canonical
          (.op (.word toBits) [.get "value"])),
      ← runtimeDefinition (helperName ++ "_of_bits") [("bits", bits)] [value] []
        (.call (helperName ++ "_canonical")
          [.op (.word fromBits) [.get "bits"]]),
      ← runtimeDefinition (helperName ++ "_canonical") [("value", value)] [value] []
        (.ite (some value) (.op ne [.get "value", .get "value"])
          (.op (.word fromBits) [canonical]) (.get "value"))]
  return definitions

end PsWasm
