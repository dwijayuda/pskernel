import Ps.CompilerUnified.Service
import Lean.Data.Json

def main : IO Unit := do
  for grammar in ["lean", "ps"] do
    let request := Lean.Json.arr #[.str "psc1-modular-build/1",
      .arr #[.str "psc1-compiler-service/1", .str "portable-module-test", .str "test-source",
        .str grammar, .str "checked", .str "Main",
        .arr #[.arr #[.str "Main", .str "def answer : Nat := 42\n"]]],
      .arr #[.str "@proofscript/foundation/generated/runtime",
        .str "@proofscript/core/generated/Main"]]
    let response ← match Lean.Json.parse (psCompilerServiceCandidate request.compress) with
      | .ok value => pure value
      | .error reason => throw (IO.userError reason)
    match response.getObjValAs? String "status" with
    | .ok "candidate" => pure ()
    | _ => throw (IO.userError response.compress)
    let files ← match (response.getObjVal? "files").bind Lean.Json.getArr? with
      | .ok values => pure values
      | .error reason => throw (IO.userError reason)
    unless files.size == 13 do throw (IO.userError "PSC1_PORTABLE_SMALL_GRAPH_FILES")
    match response.getObjValAs? String "admission" with
    | .ok "not-run" => pure ()
    | _ => throw (IO.userError "PSC1_PORTABLE_CANDIDATE_AUTHORITY")
  let refused := psCompilerServiceCandidate "[\"psc1-modular-build/1\"]"
  let refusal ← match Lean.Json.parse refused with
    | .ok result => pure result
    | .error reason => throw (IO.userError reason)
  match refusal.getObjValAs? String "code" with
  | .ok "PSC1_EXECUTABLE_REQUEST_ARITY" => pure ()
  | _ => throw (IO.userError "PSC1_PORTABLE_ARITY")
  IO.println "PSC1_PORTABLE_MODULE_PASS both grammars; native pure candidate; no admission authority; arity refusal"

