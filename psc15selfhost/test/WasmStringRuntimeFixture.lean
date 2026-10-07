import Ps.BackendWasm.Binary
import Ps.BackendWasm.SelfHostAbi
import Ps.BackendWasm.TailCalls
import Ps.BackendWasm.ValidateIr

def stringRuntimeFixture : PsWasmModule :=
  let exported := [
    psWasmSelfHostAbiStringNewName, psWasmSelfHostAbiStringSetName,
    psWasmSelfHostAbiStringFinishName, psWasmNatZeroFn, psWasmNatMkBit0Fn,
    psWasmNatBit1Fn, psWasmNatToU32Fn, psWasmNatCmpFn,
    psWasmStringSingletonFn, psWasmStringPushFn, psWasmStringLengthFn,
    psWasmStringAppendFn, psWasmStringUtf8ByteSizeFn, psWasmStringNextFn,
    psWasmStringGetFn, psWasmStringAtEndFn, psWasmStringExtractFn,
    psWasmStringEqFn, psWasmStringSizeAddFn];
  {
    structures := psWasmNatRuntimeStructures ++ psWasmStringRuntimeStructures
    arrays := psWasmStringRuntimeArrays
    functionTypes := []
    functions := psWasmTailCallFunctions
      (psWasmNatRuntimeFunctions ++ psWasmStringRuntimeFunctions ++
        psWasmSelfHostAbiFunctions.take 3)
    functionRefs := []
    exports := exported.map (fun name => (name, name))
  }

def main (args : List String) : IO Unit := do
  let [output] := args | throw (IO.userError "expected output Wasm path")
  match psWasmIrValidateModule stringRuntimeFixture with
  | .error _ => throw (IO.userError "string fixture structural validation failed")
  | .ok _ => pure ()
  match psWasmEncodeModule stringRuntimeFixture with
  | .error _ => throw (IO.userError "string fixture encoding failed")
  | .ok bytes => IO.FS.writeBinFile output (ByteArray.mk bytes.toArray)
