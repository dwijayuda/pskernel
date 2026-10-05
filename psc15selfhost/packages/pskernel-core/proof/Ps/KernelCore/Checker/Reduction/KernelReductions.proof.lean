import Ps.KernelCore.Checker.Reduction.KernelReductions

theorem psKernelNoRecursorReduction_none
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (expr : PsKernelExpr)
    (cheapRec cheapProj : Bool) :
    psKernelNoRecursorReduction
        context state expr cheapRec cheapProj =
      Except.ok (Prod.mk Option.none state) := by
  rfl
