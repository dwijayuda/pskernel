import Ps.KernelCore.Environment.Semantic
import Ps.KernelCore.Runtime.Acceleration.EnvironmentIndex
import Ps.KernelCore.Runtime.Capability.Types

structure PsKernelEnvironment where
  constants : List PsKernelConstantInfo
  index : PsKernelEnvironmentIndex
  quotInitialized : Bool
  runtime : PsKernelEnvironmentRuntime

def psKernelEnvironmentEmpty : PsKernelEnvironment :=
  {
    constants := List.nil
    index := PsKernelEnvironmentIndex.empty
    quotInitialized := false
    runtime := psKernelEnvironmentRuntimeEmpty
  }

def psKernelEnvironmentWithNativeEvaluator
    (environment : PsKernelEnvironment)
    (nativeEvaluator : Option PsKernelNativeEvaluator) :
    PsKernelEnvironment :=
  {
    constants := environment.constants
    index := environment.index
    quotInitialized := environment.quotInitialized
    runtime := {
      nativeEvaluator := nativeEvaluator
    }
  }

/- Legacy environment wrappers retain capability configuration for callers;
   it is explicitly excluded from the semantic history view. -/
def psKernelEnvironmentSemantic
    (environment : PsKernelEnvironment) : PsKernelEnvironmentSemantic :=
  PsKernelEnvironmentSemantic.mk environment.constants environment.quotInitialized
