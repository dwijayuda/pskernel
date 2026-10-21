import Ps.BackendJs.CompilerService

-- Stage0 only: native transport around the exact same pure scalar facade that
-- G1/G2/G3 must execute. The external host still checks its candidate graph.
def main (args : List String) : IO Unit := do
  match args with
  | [input, output] =>
      let request <- IO.FS.readFile input
      let response := psCompilerJsServiceCandidate request
      IO.FS.writeFile output response
      IO.println "PSC1_NATIVE_SERVICE_SEED: candidate written; admission/publication not authorized"
  | _ => throw (IO.userError "usage: psc1_js_service_seed request.json candidate.json")
