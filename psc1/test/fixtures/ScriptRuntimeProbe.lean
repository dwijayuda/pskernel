import Ps.BackendPython.Runtime
import Ps.BackendPhp.Runtime
import Ps.BackendCommon.StateExcept
import Ps.Foundation.Text

def runtimeText (python : Bool) (helper : String) : String :=
  if python then psPythonRuntimeBody helper else psPhpRuntimePart helper

def dependencies (python : Bool) (helper : String) : String :=
  if python then psTextJoin "|" (psPythonRuntimeClosure [helper, helper, "unknown"])
  else psTextJoin "|" (psPhpRuntimeClosure [helper, helper, "unknown"])

def Ps.Internal.RuntimeProbe.stateNext (value : Nat) : PsBackendStateExcept Nat String Nat :=
  psBackendStateBind (psBackendStateSet (Nat.succ value))
    (fun (_unit : Unit) => psBackendStateGet Unit.unit)

def stateSummary (start : Nat) (fail : Bool) : Nat :=
  let action : PsBackendStateExcept Nat String Nat :=
    if fail then psBackendStateThrow "failure"
    else psBackendStateBind (psBackendStatePure start) Ps.Internal.RuntimeProbe.stateNext;
  match action start with
  | Except.error _ => 0
  | Except.ok pair => pair.fst
