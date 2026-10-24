import Ps.BackendPython.Runtime
import Ps.BackendPhp.Runtime

def runtimeText (python : Bool) (helper : String) : String :=
  if python then psPythonRuntimeBody helper else psPhpRuntimePart helper

def dependencies (python : Bool) (helper : String) : String :=
  if python then psTextJoin "|" (psPythonRuntimeClosure [helper, helper, "unknown"])
  else psTextJoin "|" (psPhpRuntimeClosure [helper, helper, "unknown"])
