import Ps.Host.KernelCoreProvider.Admission
import Ps.Host.KernelCoreProvider.Response

def main (args : List String) : IO UInt32 := do
  let stdout ← IO.getStdout
  match args with
  | ["--check"] =>
      let source ← (← IO.getStdin).readToEnd
      let response := match PsKernelCoreProvider.checkCanonicalAdmissions source with
        | .ok _ => PsKernelCoreProvider.providerAcceptedJson
        | .error error => PsKernelCoreProvider.providerRejectedJson error
      stdout.putStrLn response
      pure 0
  | ["--version"] | ["--health"] =>
      stdout.putStrLn (PsKernelCoreProvider.providerMetadataJson "ready")
      pure 0
  | _ =>
      stdout.putStrLn PsKernelCoreProvider.providerNotReadyJson
      pure 1
