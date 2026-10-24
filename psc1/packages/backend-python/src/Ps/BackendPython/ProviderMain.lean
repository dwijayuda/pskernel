import Ps.Host.BackendProviderProtocol
import Ps.BackendPython.Module

-- This process contains an emitter, not the source frontend or admission host.
def main (args : List String) : IO Unit :=
  psBackendProviderRun .python (fun module names ioAbi => do
    let value ← psPythonEmitModule module names ioAbi
    return (value.source, value.stub, value.runtimeSource,
      value.runtimeHelpers, value.declarationLines)) args
