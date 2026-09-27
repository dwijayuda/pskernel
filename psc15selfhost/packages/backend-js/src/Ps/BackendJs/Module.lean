import Ps.BackendJs.Lower
import Ps.BackendJs.Emit

def psJsEmitModule (module : PsVerifiedIrModule) : Except PsJsError String :=
  match psJsLowerModule module with
  | Except.error error => Except.error error
  | Except.ok lowered => psJsEmitTargetModule lowered
