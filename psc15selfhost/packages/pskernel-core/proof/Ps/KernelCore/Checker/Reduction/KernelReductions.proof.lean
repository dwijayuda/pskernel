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


theorem psKernelReduceQuotWith_not_initialized
    (publicWhnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String
        (Prod PsKernelExpr PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (expr : PsKernelExpr)
    (h : context.environment.quotInitialized = false) :
    psKernelReduceQuotWith
        publicWhnf
        context
        state
        expr =
      Except.ok
        (Prod.mk Option.none state) := by
  simp [psKernelReduceQuotWith, h]
