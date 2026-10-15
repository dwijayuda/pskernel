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
  for (suffix, value, absOp, toBits, eq, lt, infinity) in
      [("32", PsWasmValueType.f32, PsWasmWordOp.f32Abs,
        PsWasmWordOp.i32ReinterpretF32, PsWasmInstruction.i32Eq,
        PsWasmInstruction.i32LtU, RuntimeCode.i32 2139095040),
       ("64", .f64, .f64Abs, .i64ReinterpretF64, .i64Eq, .i64LtU,
        RuntimeCode.i64 9218868437227405312)] do
    let magnitude := RuntimeCode.op (.word toBits)
      [.op (.word absOp) [.get "value"]]
    let nan := RuntimeCode.op (if suffix == "32" then .f32Ne else .f64Ne)
      [.get "value", .get "value"]
    -- Classification is independent of NaN payload/sign. No memory is used.
    definitions := definitions ++ [
      ← runtimeDefinition ("__ps_float" ++ suffix ++ "_is_nan") [("value", value)] [.i32] [] nan,
      ← runtimeDefinition ("__ps_float" ++ suffix ++ "_is_inf") [("value", value)] [.i32] []
        (.op eq [magnitude, infinity]),
      ← runtimeDefinition ("__ps_float" ++ suffix ++ "_is_finite") [("value", value)] [.i32] []
        (.op lt [magnitude, infinity])]
  return definitions

end PsWasm
