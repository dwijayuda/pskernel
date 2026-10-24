import Ps.Host.BackendProviderProtocol
import Ps.BackendPhp.Module

-- This process contains an emitter, not the source frontend or admission host.
def main (args : List String) : IO Unit :=
  psBackendProviderRun .php (fun module names ioAbi => do
    let value ← psPhpEmitValidatedModule module names ioAbi
    return (value.source, value.composer, value.runtimeSource,
      value.runtimeRequirements, value.declarationLines)) args
