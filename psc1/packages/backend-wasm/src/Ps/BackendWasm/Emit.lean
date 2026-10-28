import Ps.BackendCommon.ServiceError
import Ps.BackendCommon.Plan
import Ps.BackendWasm.Lower
import Ps.BackendWasm.BinaryBytes
import Ps.BackendWasm.ValidateIr
import Ps.BackendWasm.ServiceAbi

-- Pure target emission only. Checked orchestration stays in the compiler driver.
namespace Ps.Internal.WasmCompilerService

def nibble (value : Nat) : String :=
  if Nat.beq value 0 then "0" else if Nat.beq value 1 then "1"
  else if Nat.beq value 2 then "2" else if Nat.beq value 3 then "3"
  else if Nat.beq value 4 then "4" else if Nat.beq value 5 then "5"
  else if Nat.beq value 6 then "6" else if Nat.beq value 7 then "7"
  else if Nat.beq value 8 then "8" else if Nat.beq value 9 then "9"
  else if Nat.beq value 10 then "a" else if Nat.beq value 11 then "b"
  else if Nat.beq value 12 then "c" else if Nat.beq value 13 then "d"
  else if Nat.beq value 14 then "e" else "f"

def hexWorker (bytes : List Nat) (builder : PsTextBuilder) : String :=
  match bytes with
  | List.nil => psTextBuilderFinish builder
  | List.cons byte rest =>
      let value := byte;
      let text := String.Internal.append (nibble (Nat.div value 16)) (nibble (Nat.mod value 16));
      hexWorker rest (psTextBuilderAppend builder text)

def emit (module : PsValidatedIrModule) (publicNames : List String) :
    Except Ps.Internal.CompilerService.Error (Prod String (List String)) :=
  match psWasmLowerSpecializedModule (PsWasmTargetProfile.mk PsWasmWordSize.wasm32) module.raw with
  | Except.error _ => Except.error (Ps.Internal.CompilerService.failure "wasm-lowering" "target-refused")
  | Except.ok lowered =>
      let target := psWasmServiceTransport lowered publicNames;
      match psWasmIrValidateModule target with
      | Except.error _ => Except.error (Ps.Internal.CompilerService.failure "wasm-validation" "target-refused")
      | Except.ok _ =>
          match Ps.Internal.WasmBinaryBytes.psWasmEncodeModule target with
          | Except.error _ => Except.error (Ps.Internal.CompilerService.failure "wasm-binary" "target-refused")
          | Except.ok bytes => Except.ok (Prod.mk
              (String.Internal.append "psc1-wasm-hex/1:" (hexWorker bytes psTextBuilderEmpty))
              ["psc1-wasm-selfhost-gc/1"])

end Ps.Internal.WasmCompilerService
