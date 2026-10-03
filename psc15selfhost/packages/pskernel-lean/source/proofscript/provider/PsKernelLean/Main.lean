import PsKernelLean.Response

namespace PsKernelLean

def runProviderCheck : IO Unit := do
  let source ← (← IO.getStdin).readToEnd
  let response ← checkCanonicalAdmissionsJson source
  IO.println response

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
