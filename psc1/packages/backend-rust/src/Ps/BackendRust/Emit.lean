import Ps.BackendCommon.ServiceError
import Ps.BackendCommon.Plan
Ps.BackendRust.Module

-- Pure target emission only. Checked orchestration stays in the compiler driver.
namespace Ps.Internal.RustCompilerService

def emit (module : PsValidatedIrModule) (publicNames : List String) :
    Except Ps.Internal.CompilerService.Error (Prod String (List String)) :=
  match psRustEmitSelectedValidatedModule module publicNames [] with
  | Except.error code => Except.error (Ps.Internal.CompilerService.failure "rust-lowering" code)
  | Except.ok source =>
      let runtime : PsRustRuntimePlan := psRustPlanRuntime module.raw;
      Except.ok (Prod.mk source runtime.requirements)

end Ps.Internal.RustCompilerService
