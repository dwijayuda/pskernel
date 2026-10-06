import Ps.KernelCore.Environment.Environment
import Ps.KernelCore.Environment.Lookup

theorem psKernelEnvironmentEmpty_semantic :
    psKernelEnvironmentSemantic psKernelEnvironmentEmpty =
      PsKernelEnvironmentSemantic.mk List.nil false := by
  rfl

theorem psKernelEnvironmentWithNativeEvaluator_constants
    (environment : PsKernelEnvironment)
    (nativeEvaluator : Option PsKernelNativeEvaluator) :
    (psKernelEnvironmentWithNativeEvaluator
      environment nativeEvaluator).constants =
      environment.constants := by
  rfl

theorem psKernelEnvironmentWithNativeEvaluator_quot
    (environment : PsKernelEnvironment)
    (nativeEvaluator : Option PsKernelNativeEvaluator) :
    (psKernelEnvironmentWithNativeEvaluator
      environment nativeEvaluator).quotInitialized =
      environment.quotInitialized := by
  rfl

theorem psKernelEnvironmentWithNativeEvaluator_semantic
    (environment : PsKernelEnvironment)
    (nativeEvaluator : Option PsKernelNativeEvaluator) :
    psKernelEnvironmentSemantic
        (psKernelEnvironmentWithNativeEvaluator
          environment nativeEvaluator) =
      psKernelEnvironmentSemantic environment := by
  rfl


theorem psKernelEnvironmentWithNativeEvaluator_find
    (environment : PsKernelEnvironment)
    (nativeEvaluator : Option PsKernelNativeEvaluator)
    (name : PsKernelName) :
    psKernelEnvironmentFind
        (psKernelEnvironmentWithNativeEvaluator
          environment
          nativeEvaluator)
        name =
      psKernelEnvironmentFind environment name := by
  rfl
