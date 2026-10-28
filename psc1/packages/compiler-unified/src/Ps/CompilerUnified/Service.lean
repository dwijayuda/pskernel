import Ps.Compiler.Service
import Ps.BackendJs.Emit
import Ps.BackendTs.Emit
import Ps.BackendRust.Emit
import Ps.BackendWasm.Emit

-- One owned compiler source closure. Execution engine and output target are
-- independent; optional Python/PHP emitters are deliberately outside this root.
namespace Ps.Internal.UnifiedCompilerService

def refused (target code : String) : String :=
  psJsonObject [
    ("admission", psJsonQuote "not-run"),
    ("candidateOnly", "true"),
    ("code", psJsonQuote code),
    ("column", "0"),
    ("declaration", psJsonQuote ""),
    ("line", "0"),
    ("module", psJsonQuote ""),
    ("phase", psJsonQuote "wire"),
    ("protocol", psJsonQuote "psc1-compiler-service/1"),
    ("requestId", psJsonQuote ""),
    ("sourceClosureDigest", psJsonQuote ""),
    ("status", psJsonQuote "refused"),
    ("target", psJsonQuote target)
  ]

def run (target : PsBackendTarget)
    (emit : PsValidatedIrModule -> List String ->
      Except Ps.Internal.CompilerService.Error (Prod String (List String)))
    (values : List PsJsonValue) : String :=
  Ps.Internal.CompilerService.candidateFields target emit values

def dispatch (target : String) (values : List PsJsonValue) : String :=
  if psStringEq target "js" then
    run PsBackendTarget.js Ps.Internal.JsCompilerService.emit values
  else if psStringEq target "ts" then
    run PsBackendTarget.ts Ps.Internal.TsCompilerService.emit values
  else if psStringEq target "rust" then
    run PsBackendTarget.rust Ps.Internal.RustCompilerService.emit values
  else if psStringEq target "wasm-core" then
    run PsBackendTarget.wasmCore Ps.Internal.WasmCompilerService.emit values
  else refused target "target-unavailable"

def fields (values : List PsJsonValue) : String :=
  if !(Nat.beq (psListLength values) 3) then refused "" "request-arity"
  else
    match Ps.Internal.CompilerService.stringAt values 0 with
    | Except.error _ => refused "" "expected-string"
    | Except.ok protocol =>
        if !psStringEq protocol "psc1-unified-compiler-service/2" then refused "" "protocol"
        else
          match Ps.Internal.CompilerService.stringAt values 1 with
          | Except.error _ => refused "" "expected-string"
          | Except.ok target =>
              match Ps.Internal.CompilerService.atWorker values 2 with
              | Except.error _ => refused target "expected-array"
              | Except.ok input =>
                  match input with
                  | PsJsonValue.array request => dispatch target request
                  | _ => refused target "expected-array"

def candidate (input : String) : String :=
  match psJsonParse input with
  | Except.error _ => refused "" "invalid-json"
  | Except.ok value =>
      match value with
      | PsJsonValue.array values => fields values
      | _ => refused "" "expected-array"

end Ps.Internal.UnifiedCompilerService

/-- Candidates only. Independent admission remains in the external host. -/
def psCompilerServiceCandidate (input : String) : String :=
  Ps.Internal.UnifiedCompilerService.candidate input
