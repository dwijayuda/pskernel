import Ps.KernelCore.Admission.Inductive.Common.Elimination

theorem psKernelSimpleExprMember_nil
    (expr : PsKernelExpr) :
    psKernelSimpleExprMember expr List.nil = false := by
  rfl

theorem psKernelSimpleCtorAllowsLargeElimWithFuel_zero
    (session : PsKernelCheckerSession)
    (type : PsKernelExpr)
    (revNonProp : List PsKernelExpr) :
    psKernelSimpleCtorAllowsLargeElimWithFuel
        0 session type revNonProp =
      Except.error "simple inductive elimination budget exhausted" := by
  rfl
