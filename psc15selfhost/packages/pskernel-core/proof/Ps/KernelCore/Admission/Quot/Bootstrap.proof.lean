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
