import Ps.BackendWasm.Type

def psWasmProfile32 : PsWasmTargetProfile :=
  { wordSize := PsWasmWordSize.wasm32 }

def psWasmProfile64 : PsWasmTargetProfile :=
  { wordSize := PsWasmWordSize.wasm64 }

def psWasmIsI32 : PsWasmValueType -> Bool
  | .i32 => true
  | _ => false

def psWasmIsI64 : PsWasmValueType -> Bool
  | .i64 => true
  | _ => false

def psWasmIsF32 : PsWasmValueType -> Bool
  | .f32 => true
  | _ => false

def psWasmIsF64 : PsWasmValueType -> Bool
  | .f64 => true
  | _ => false

def psWasmIsPackedI8 : PsWasmStorageType -> Bool
  | .packedI8 => true
  | _ => false

def psWasmIsPackedI16 : PsWasmStorageType -> Bool
  | .packedI16 => true
  | _ => false

def psWasmIsNatRef : PsWasmValueType -> Bool
  | .refT name => name == "ProofScript.Nat"
  | _ => false

def psTestWasmScalarLowering : Bool :=
  psWasmIsI32 (psWasmValueTypeOfPrimitive psWasmProfile32 .uint8)
    && psWasmIsPackedI8 (psWasmStorageTypeOfPrimitive psWasmProfile32 .uint8)
    && psWasmIsI32 (psWasmValueTypeOfPrimitive psWasmProfile32 .int16)
    && psWasmIsPackedI16 (psWasmStorageTypeOfPrimitive psWasmProfile32 .int16)
    && psWasmIsI64 (psWasmValueTypeOfPrimitive psWasmProfile32 .uint64)
    && psWasmIsF32 (psWasmValueTypeOfPrimitive psWasmProfile32 .float32)
    && psWasmIsF64 (psWasmValueTypeOfPrimitive psWasmProfile32 .float)
    && psWasmIsNatRef (psWasmValueTypeOfPrimitive psWasmProfile32 .nat)

def psTestWasmWordProfiles : Bool :=
  psWasmIsI32 (psWasmValueTypeOfPrimitive psWasmProfile32 .usize)
    && psWasmIsI32 (psWasmValueTypeOfPrimitive psWasmProfile32 .isize)
    && psWasmIsI64 (psWasmValueTypeOfPrimitive psWasmProfile64 .usize)
    && psWasmIsI64 (psWasmValueTypeOfPrimitive psWasmProfile64 .isize)

def main : IO Unit := do
  if psTestWasmScalarLowering && psTestWasmWordProfiles then
    IO.println "PSC1_BACKEND_WASM_TESTS: PASS"
  else
    throw (IO.userError "PSC1_BACKEND_WASM_TESTS: FAIL")
