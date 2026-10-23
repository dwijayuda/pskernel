import Ps.Compiler.Service
import Ps.BackendRust.Module

namespace Ps.Internal.RustCompilerService
open Ps.Internal.CompilerService

def emit (module : PsValidatedIrModule) (publicNames : List String) :
    Except Error (Prod String (List String)) :=
  match psRustEmitSelectedValidatedModule module publicNames [] with
  | Except.error code => Except.error (failure "rust-lowering" code)
  | Except.ok source =>
      let runtime : PsRustRuntimePlan := psRustPlanRuntime module.raw;
      Except.ok (Prod.mk source runtime.requirements)

end Ps.Internal.RustCompilerService

def psCompilerRustServiceCandidate (input : String) : String :=
  Ps.Internal.CompilerService.candidate PsBackendTarget.rust Ps.Internal.RustCompilerService.emit input
