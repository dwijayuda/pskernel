import PsKernelLean.Admission

namespace PsKernelLean

def providerAcceptedJson : String :=
  "{\"protocol\":" ++ psJsonQuote providerProtocol ++
  ",\"accepted\":true" ++
  ",\"provider\":" ++ psJsonQuote providerName ++
  ",\"leanVersion\":" ++ psJsonQuote providerVersion ++
  ",\"profile\":" ++ psJsonQuote providerProfile ++
  "}"

def providerErrorIndexJson : Option Nat -> String
  | none => ""
  | some declarationIndex =>
      ",\"declarationIndex\":" ++ toString declarationIndex

def providerRejectedJson (error : PsKernelLeanError) : String :=
  "{\"protocol\":" ++ psJsonQuote providerProtocol ++
  ",\"accepted\":false" ++
  ",\"provider\":" ++ psJsonQuote providerName ++
  ",\"leanVersion\":" ++ psJsonQuote providerVersion ++
  ",\"profile\":" ++ psJsonQuote providerProfile ++
  ",\"errorKind\":" ++ psJsonQuote error.kind.code ++
  providerErrorIndexJson error.declarationIndex ++
  ",\"message\":" ++ psJsonQuote error.message ++
  "}"

def runProviderCheck : IO Unit := do
  let source ← (← IO.getStdin).readToEnd
  let result ← admitCanonicalAdmissions source
  match result with
  | .ok _ => IO.println providerAcceptedJson
  | .error error => IO.println (providerRejectedJson error)

def runProviderCommand (args : List String) : IO Unit := do
  match args with
  | ["--version"] =>
      IO.println (providerMetadataJson "version")
  | ["--health"] =>
      IO.println (providerMetadataJson "ok")
  | ["--check"] =>
      runProviderCheck
  | [] =>
      IO.println providerNotReadyJson
  | _ =>
      IO.println providerNotReadyJson

end PsKernelLean

def main (args : List String) : IO Unit :=
  PsKernelLean.runProviderCommand args