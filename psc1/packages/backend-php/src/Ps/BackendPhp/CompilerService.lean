import Ps.Compiler.Service
import Ps.BackendPhp.Module

namespace Ps.Internal.PhpCompilerService

def emit (module : PsValidatedIrModule) (publicNames : List String) :
    Except Ps.Internal.CompilerService.Error (Prod String (List String)) :=
  match psPhpEmitModule module publicNames false with
  | Except.error detail =>
      Except.error (Ps.Internal.CompilerService.failure "php-emission" detail)
  | Except.ok output => Except.ok (Prod.mk output.source output.runtimeRequirements)

end Ps.Internal.PhpCompilerService

/-- Provisional output only; independent host admission remains mandatory. -/
def psCompilerPhpServiceCandidate (input : String) : String :=
  Ps.Internal.CompilerService.candidate PsBackendTarget.php Ps.Internal.PhpCompilerService.emit input
