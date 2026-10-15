import Ps.BackendWasm.LowerFloat
import Ps.BackendWasm.Array
import Ps.BackendWasm.Word
import Ps.BackendWasm.Float
import Ps.BackendWasm.Hash

namespace PsWasm

structure IntrinsicPlan where
  parameters : List PsVerifiedIrType
  result : PsVerifiedIrType
  instructions : List PsWasmInstruction

-- Formal generic slots describe the physical runtime convention, independently
-- of the concrete signature used by the source type checker.
def intrinsicPlan (op : PsVerifiedIrIntrinsic) (arguments : List PsVerifiedIrType) :
    Except String IntrinsicPlan := do
  let generic := PsVerifiedIrType.typeParameter "__ps_element"
  let generics := arguments.map fun _ => generic
  let signature ← (psIrCheckIntrinsicSignature op generics).mapError
    (fun e => "PSCV0-WASM-INTRINSIC: " ++ e.detail)
  let runtime : String ← match op with
    | .floatOfBits .float => pure "float64_of_bits"
    | .floatOfBits .float32 => pure "float32_of_bits"
    | .floatToBits .float => pure "float64_to_bits"
    | .floatToBits .float32 => pure "float32_to_bits"
    | .floatTest type op =>
      pure ((match type with | .float => "float64" | .float32 => "float32") ++
        (match op with | .isNaN => "_is_nan" | .isInf => "_is_inf" | .isFinite => "_is_finite"))
    | .natAdd => pure "nat_add" | .natSub => pure "nat_sub" | .natMul => pure "nat_mul"
    | .hashMix => pure "hash_mix" | .stringHash => pure "string_hash"
    | .natPow => pure "nat_pow"
    | .natLog2 => pure "nat_log2"
    | .natDiv => pure "nat_div" | .natMod => pure "nat_mod"
    | .natEq => pure "nat_eq" | .natNe => pure "nat_ne" | .natLt => pure "nat_lt" | .natLe => pure "nat_le"
    | .intToNat => pure "int_to_nat"
    | .intOfNat => pure "int_of_nat" | .intNegSucc => pure "int_neg_succ"
    | .intNeg => pure "int_neg" | .intAdd => pure "int_add" | .intSub => pure "int_sub" | .intMul => pure "int_mul"
    | .intEq => pure "int_eq" | .intLt => pure "int_lt" | .intLe => pure "int_le" | .intRepr => pure "int_repr"
    | .charOfNat => pure "char_of_nat" | .charToNat => pure "nat_from_u32"
    | .stringPush => pure "string_push" | .stringSingleton => pure "string_singleton"
    | .stringLength => pure "string_length" | .stringAppend => pure "string_append"
    | .stringUtf8ByteSize => pure "string_byte_size" | .stringNext => pure "string_next"
    | .stringGet => pure "string_get" | .stringAtEnd => pure "string_at_end"
    | .stringExtract => pure "string_extract" | .stringEq => pure "string_eq"
    | .arrayBuild => pure "array_build"
    | .arrayEmptyWithCapacity => pure "array_empty" | .arraySize => pure "array_size"
    | .arrayPush => pure "array_push" | .arrayGet => pure "array_get" | .arrayGetD => pure "array_get_default"
    | .arraySet => pure "array_set" | .arraySetIfInBounds => pure "array_set_if_in_bounds"
    | .arrayMap => pure "array_map" | .arrayFoldl => pure "array_fold"
    | .boolNot | .boolAnd | .boolOr | .boolEq | .boolNe
    | .unsignedOfNat _ | .signedOfNat _ | .signedToUnsigned _ | .unsignedToNat _
    | .machineIntBinary .. | .machineIntCompare ..
    | .floatBinary .. | .floatCompare .. | .floatUnary ..
    | .floatOfWord .. | .floatToWord .. | .floatConvert .. => pure ""
  let instructions := if runtime.isEmpty then match op with
    | .unsignedOfNat type =>
      [.call (match type with | .uint64 => "__ps_nat_wrap_u64" | _ => "__ps_nat_wrap_u32")] ++
        psWasmNormalizeMachineInteger type
    | .signedOfNat type =>
      [.call (match type with | .int64 => "__ps_nat_wrap_u64" | _ => "__ps_nat_wrap_u32")] ++
        psWasmNormalizeMachineInteger type
    | .signedToUnsigned type =>
      match type with
      | .int8 => psWasmNormalizeMachineInteger .uint8
      | .int16 => psWasmNormalizeMachineInteger .uint16
      | .int32 | .int64 => []
      | _ => []
    | .unsignedToNat type =>
      [.call (match type with | .uint64 => "__ps_nat_from_u64" | _ => "__ps_nat_from_u32")]
    | .floatConvert source target =>
      match source, target with
      | .float, .float32 => [.word .f32DemoteF64]
      | .float32, .float => [.word .f64PromoteF32]
      | _, _ => []
    | .floatOfWord type word => [.word (floatWordConversion type word false)]
    | .floatToWord type word =>
      if ((psIrMachineIntegerFixedWidth word).getD 0) < 32 then
        [.call (floatWordRuntimeName type word)]
      else [.word (floatWordConversion type word true)]
    | .floatBinary type op => psWasmLowerFloatBinary type op
    | .floatCompare type op => psWasmLowerFloatCompare type op
    | .floatUnary type op => [.word (match type, op with
        | .float, .neg => .f64Neg | .float, .abs => .f64Abs
        | .float32, .neg => .f32Neg | .float32, .abs => .f32Abs)]
    | .machineIntBinary type op => psWasmLowerMachineIntegerBinary ⟨.wasm32⟩ type op
    | .machineIntCompare type op => psWasmLowerMachineIntegerCompare ⟨.wasm32⟩ type op
    | .boolNot => [.i32Const 0, .i32Eq]
    | .boolAnd => [.i32And] | .boolOr => [.i32Or] | .boolEq => [.i32Eq] | .boolNe => [.i32Ne]
    | _ => []
    else [.call ("__ps_" ++ runtime)]
  return { parameters := signature.parameters, result := signature.resultType, instructions }

def runtimeDefinitions : Except String (List RuntimeDefinition) := do
  return (← naturalRuntime) ++ (← integerRuntime) ++ (← stringRuntime) ++ (← arrayRuntime) ++ (← hashRuntime) ++ (← wordRuntime) ++ (← floatRuntime) ++ (← floatWordRuntime)

end PsWasm
