import PsKernelLean.Protocol

namespace PsKernelLean

def runProviderCommand (args : List String) : IO Unit := do
  match args with
  | ["--version"] =>
      IO.println (providerMetadataJson "version")
  | ["--health"] =>
      IO.println (providerMetadataJson "ok")
  | [] =>
      IO.println providerNotReadyJson
  | _ =>
      IO.println providerNotReadyJson

end PsKernelLean

def main : IO Unit := do
  let args ← IO.getArgs
  PsKernelLean.runProviderCommand args.toList
