import Ps.KernelCore.Admission.Quot.Bootstrap

theorem psKernelCloseOpenBinders_nil
    (body : PsKernelExpr) :
    psKernelCloseOpenBinders List.nil body = body := by
  rfl

theorem psKernelCheckQuotReservedNames_nil
    (environment : PsKernelEnvironment) :
    psKernelCheckQuotReservedNames environment List.nil =
      Except.ok Unit.unit := by
  rfl


theorem psKernelCheckQuotReservedNames_cons_taken
    (environment : PsKernelEnvironment)
    (name : PsKernelName)
    (rest : List PsKernelName)
    (hTaken :
      psKernelEnvironmentContains environment name = true) :
    psKernelCheckQuotReservedNames
        environment
        (List.cons name rest) =
      Except.error
        "failed to initialize quot module, quotient name is already declared" := by
  simp [psKernelCheckQuotReservedNames, hTaken]

theorem psKernelCheckQuotReservedNames_cons_free
    (environment : PsKernelEnvironment)
    (name : PsKernelName)
    (rest : List PsKernelName)
    (hFree :
      psKernelEnvironmentContains environment name = false) :
    psKernelCheckQuotReservedNames
        environment
        (List.cons name rest) =
      psKernelCheckQuotReservedNames environment rest := by
  simp [psKernelCheckQuotReservedNames, hFree]
