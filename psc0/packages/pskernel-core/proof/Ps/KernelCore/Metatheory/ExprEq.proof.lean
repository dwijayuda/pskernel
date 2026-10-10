import Ps.KernelCore.Metatheory.ExprEq

theorem psKernelExprEqSound_available
    (environment : PsKernelEnvironment)
    (localContext : PsKernelLocalContext) :
    PsKernelExprEqSound
      environment
      localContext := by
  exact psKernelExprEqSound_all environment localContext
