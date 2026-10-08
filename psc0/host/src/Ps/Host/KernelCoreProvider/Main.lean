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
  | ["--check", "--diagnostic-high-fuel"] =>
      -- Explicit diagnostic-only profile. The normal checked build never
      -- selects this mode, and it does not turn a rejection into acceptance.
      let source ← (← IO.getStdin).readToEnd
      let resources : PsKernelResourcePolicy :=
        { PsKernelCoreProvider.compilerSelfHostResourcePolicy with fuel := 1048576 }
      let response := match PsKernelCoreProvider.checkCanonicalAdmissions source resources with
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
