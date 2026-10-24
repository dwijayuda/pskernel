import Ps.CompilerUnified.Service
import Lean

def psUnifiedTestRequest : String :=
  "[\"psc1-compiler-service/1\",\"fixture\",\"digest\",\"lean\",\"checked\",\"Entry\",[[\"Entry\",\"def truth : Bool := true\\n\"]]]"

def main : IO Unit := do
  for target in ["js", "ts", "rust", "wasm-core"] do
    let envelope := (Lean.toJson (["psc1-unified-compiler-service/1", target, psUnifiedTestRequest] : List String)).compress
    let expected := Ps.Internal.UnifiedCompilerService.dispatch target psUnifiedTestRequest
    let actual := psCompilerServiceCandidate envelope
    unless actual == expected do throw (IO.userError ("dispatch mismatch: " ++ target))
    let Except.ok parsed := Lean.Json.parse actual | throw (IO.userError "candidate JSON")
    unless (parsed.getObjValAs? String "status").toOption == some "candidate" do
      throw (IO.userError actual)
  for input in ["null", "{}", "malformed", "[]", "[\"wrong\",\"js\",\"{}\"]",
      "[\"psc1-unified-compiler-service/1\",\"python\",\"{}\"]",
      "[\"psc1-unified-compiler-service/1\",\"php\",\"{}\"]",
      "[\"psc1-unified-compiler-service/1\",\"unknown\",\"{}\"]",
      "[\"psc1-unified-compiler-service/1\",\"js\",0]"] do
    let Except.ok parsed := Lean.Json.parse (psCompilerServiceCandidate input)
      | throw (IO.userError "refusal JSON")
    unless (parsed.getObjValAs? String "status").toOption == some "refused" do
      throw (IO.userError "invalid envelope accepted")
    match parsed.getObjVal? "source" with
    | Except.ok _ => throw (IO.userError "refusal leaked candidate")
    | Except.error _ => pure ()
  IO.println "PSC1_UNIFIED_SERVICE_NATIVE: four exact retained emitters; nine envelope/optional refusals"
