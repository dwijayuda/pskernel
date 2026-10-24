import Ps.BackendRust.CompilerService
import Ps.BackendTs.CompilerService
import Ps.BackendJs.CompilerService
import Ps.BackendWasm.CompilerService
import Ps.BackendPython.CompilerService
import Ps.BackendPhp.CompilerService

-- Native stage zero only. These are the same pure facades later compiled and
-- executed by G1/G2/G3. No target-side compiler is handwritten.
def main (args : List String) : IO Unit := do
  match args with
  | [target, input, output] =>
      let request <- IO.FS.readFile input
      let response <- if target == "rust" then pure (psCompilerRustServiceCandidate request)
        else if target == "ts" then pure (psCompilerTsServiceCandidate request)
        else if target == "js" then pure (psCompilerJsServiceCandidate request)
        else if target == "wasm-core" then pure (psCompilerWasmServiceCandidate request)
        else if target == "python" then pure (psCompilerPythonServiceCandidate request)
        else if target == "php" then pure (psCompilerPhpServiceCandidate request)
        else throw (IO.userError "PSC1_SERVICE_TARGET_UNSUPPORTED")
      IO.FS.writeFile output response
      IO.println "PSC1_NATIVE_SERVICE_SEED: provisional candidate; independent admission required"
  | _ => throw (IO.userError "usage: psc1_target_service_seed rust|ts|js|wasm-core|python|php request.json candidate.json")
