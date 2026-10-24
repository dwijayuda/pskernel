import Ps.BackendJs.CompilerService
import Ps.BackendTs.CompilerService
import Ps.BackendRust.CompilerService
import Ps.BackendWasm.CompilerService

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

def dispatch (target input : String) : String :=
  if psStringEq target "js" then psCompilerJsServiceCandidate input
  else if psStringEq target "ts" then psCompilerTsServiceCandidate input
  else if psStringEq target "rust" then psCompilerRustServiceCandidate input
  else if psStringEq target "wasm-core" then psCompilerWasmServiceCandidate input
  else refused target "target-unavailable"

def fields (values : List PsJsonValue) : String :=
  if !(Nat.beq (psListLength values) 3) then refused "" "request-arity"
  else
    match Ps.Internal.CompilerService.stringAt values 0 with
    | Except.error _ => refused "" "expected-string"
    | Except.ok protocol =>
        if !psStringEq protocol "psc1-unified-compiler-service/1" then refused "" "protocol"
        else
          match Ps.Internal.CompilerService.stringAt values 1 with
          | Except.error _ => refused "" "expected-string"
          | Except.ok target =>
              match Ps.Internal.CompilerService.stringAt values 2 with
              | Except.error _ => refused target "expected-string"
              | Except.ok input => dispatch target input

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
