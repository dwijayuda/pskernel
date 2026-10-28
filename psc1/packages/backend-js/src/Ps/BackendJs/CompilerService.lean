import Ps.Compiler.Service
import Ps.BackendJs.Emit


/-- Provisional output only; the external host independently admits the graph. -/
def psCompilerJsServiceCandidate (input : String) : String :=
  Ps.Internal.CompilerService.candidate PsBackendTarget.js Ps.Internal.JsCompilerService.emit input
