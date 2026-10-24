import Ps.CompilerUnified.Service

-- The only native seed for the enlarged default compiler; no optional emitters.
def main (args : List String) : IO Unit := do
  match args with
  | [target, input, output] =>
      let request <- IO.FS.readFile input
      unless ["js", "ts", "rust", "wasm-core"].contains target do
        throw (IO.userError "PSC1_UNIFIED_ENGINE_UNSUPPORTED")
      let response := psCompilerServiceCandidate request
      IO.FS.writeFile output response
      IO.println "PSC1_UNIFIED_NATIVE_SEED: candidate only; independent admission required"
  | _ => throw (IO.userError "usage: psc1_unified_service_seed target request candidate")
