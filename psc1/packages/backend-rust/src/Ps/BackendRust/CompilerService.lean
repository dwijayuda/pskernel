import Ps.Compiler.Service
import Ps.BackendRust.Emit


def psCompilerRustServiceCandidate (input : String) : String :=
  Ps.Internal.CompilerService.candidate PsBackendTarget.rust Ps.Internal.RustCompilerService.emit input
