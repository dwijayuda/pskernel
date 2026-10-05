import Ps.KernelCore.Core.Expr

structure PsKernelNativeEvaluator where
  evalBool : PsKernelName -> Except String (Option Bool)
  evalNat : PsKernelName -> Except String (Option Nat)

structure PsKernelEnvironmentRuntime where
  nativeEvaluator : Option PsKernelNativeEvaluator

def psKernelEnvironmentRuntimeEmpty :
    PsKernelEnvironmentRuntime :=
  {
    nativeEvaluator := Option.none
  }

