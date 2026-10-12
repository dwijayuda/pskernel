import Ps.KernelCore.Environment.Semantic
import Ps.KernelCore.Runtime.Acceleration.EnvironmentIndex

structure PsKernelEnvironment where
  constants : List PsKernelConstantInfo
  index : PsKernelEnvironmentIndex
  quotInitialized : Bool

def psKernelEnvironmentEmpty : PsKernelEnvironment :=
  {
    constants := List.nil
    index := PsKernelEnvironmentIndex.empty
    quotInitialized := false
  }

/-- Immutable semantic view excludes performance indexes from declaration history. -/
def psKernelEnvironmentSemantic
    (environment : PsKernelEnvironment) : PsKernelEnvironmentSemantic :=
  PsKernelEnvironmentSemantic.mk environment.constants environment.quotInitialized
