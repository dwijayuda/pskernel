import Ps.Compiler.Service
import Ps.BackendWasm.Emit


/-- Owned binary bytes are provisional; the external host independently admits Core. -/
def psCompilerWasmServiceCandidate (input : String) : String :=
  Ps.Internal.CompilerService.candidate PsBackendTarget.wasmCore Ps.Internal.WasmCompilerService.emit input
