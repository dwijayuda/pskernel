import Ps.BackendWasm.RuntimeBuilder

namespace PsWasm

-- Native NaNs denote the unique logical NaN. Observe exactly Lean 4.35.0's
-- canonical quiet-NaN bits; all other patterns, including -0, are unchanged.
def floatWordConversion (type : PsVerifiedIrFloatingType)
    (word : PsVerifiedIrMachineIntegerType) (toWord : Bool) : PsWasmWordOp :=
  let wide := psIrMachineIntegerFixedWidth word == some 64
  let signed := psIrMachineIntegerIsSigned word
  match toWord, type, wide, signed with
  | false, .float32, false, true => .f32ConvertI32S
  | false, .float32, false, false => .f32ConvertI32U
  | false, .float32, true, true => .f32ConvertI64S
  | false, .float32, true, false => .f32ConvertI64U
  | false, .float, false, true => .f64ConvertI32S
  | false, .float, false, false => .f64ConvertI32U
  | false, .float, true, true => .f64ConvertI64S
  | false, .float, true, false => .f64ConvertI64U
  | true, .float32, false, true => .i32TruncSatF32S
  | true, .float32, false, false => .i32TruncSatF32U
  | true, .float, false, true => .i32TruncSatF64S
  | true, .float, false, false => .i32TruncSatF64U
  | true, .float32, true, true => .i64TruncSatF32S
  | true, .float32, true, false => .i64TruncSatF32U
  | true, .float, true, true => .i64TruncSatF64S
  | true, .float, true, false => .i64TruncSatF64U

def floatWordRuntimeName (type : PsVerifiedIrFloatingType)
    (word : PsVerifiedIrMachineIntegerType) : String :=
  "__ps_float" ++ (match type with | .float => "64" | .float32 => "32") ++
    "_to_" ++ (if psIrMachineIntegerIsSigned word then "i" else "u") ++
    toString ((psIrMachineIntegerFixedWidth word).getD 0)

-- Saturate at the native stack width, then clamp narrow words before narrowing.
-- The typed descriptor is shared by WAT, binary emission, and stack validation.
def floatWordRuntime : Except String (List RuntimeDefinition) := do
  let mut definitions := []
  for type in [PsVerifiedIrFloatingType.float, .float32] do
    let valueType := match type with | .float => PsWasmValueType.f64 | .float32 => .f32
    for word in [PsVerifiedIrMachineIntegerType.uint8, .uint16, .int8, .int16] do
      let signed := psIrMachineIntegerIsSigned word
      let bits := (psIrMachineIntegerFixedWidth word).getD 0
      let bound : Int := Int.ofNat (2 ^ (if signed then bits - 1 else bits))
      let n := RuntimeCode.get "integer"
      let result := RuntimeCode.ite (some .i32)
        (.op (if signed then .i32GtS else .i32GtU) [n, .i32 (bound - 1)])
        (.i32 (bound - 1)) n
      let result := if signed then RuntimeCode.ite (some .i32)
        (.op .i32LtS [n, .i32 (-bound)]) (.i32 (-bound)) result else result
      definitions := definitions ++ [← runtimeDefinition (floatWordRuntimeName type word)
        [("value", valueType)] [.i32] [("integer", .i32)]
        (.seq [.set "integer" (.op (.word (floatWordConversion type word true)) [.get "value"]), result])]
  return definitions

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
