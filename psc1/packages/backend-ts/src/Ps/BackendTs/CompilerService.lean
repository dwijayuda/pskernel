import Ps.Compiler.Service
import Ps.BackendTs.Emit


def psCompilerTsServiceCandidate (input : String) : String :=
  Ps.Internal.CompilerService.candidate PsBackendTarget.ts Ps.Internal.TsCompilerService.emit input
