import Ps.BackendWasm.Array

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
    | .natAdd => pure "nat_add" | .natSub => pure "nat_sub" | .natMul => pure "nat_mul"
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
    | .boolNot | .boolAnd | .boolOr | .boolEq | .boolNe => pure ""
    | _ => throw "PSCV0-WASM-CAPABILITY: scalar intrinsic outside the checked runtime profile"
  let instructions := if runtime.isEmpty then match op with
    | .boolNot => [.i32Const 0, .i32Eq]
    | .boolAnd => [.i32And] | .boolOr => [.i32Or] | .boolEq => [.i32Eq] | .boolNe => [.i32Ne]
    | _ => []
    else [.call ("__ps_" ++ runtime)]
  return { parameters := signature.parameters, result := signature.resultType, instructions }

def runtimeDefinitions : Except String (List RuntimeDefinition) := do
  return (← naturalRuntime) ++ (← integerRuntime) ++ (← stringRuntime) ++ (← arrayRuntime)

end PsWasm
