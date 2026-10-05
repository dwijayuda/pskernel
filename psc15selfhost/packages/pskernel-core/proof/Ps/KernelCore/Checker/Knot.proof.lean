import Ps.KernelCore.Checker.Knot

theorem psKernelIsDefEqWithFuel_zero
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (left right : PsKernelExpr) :
    psKernelIsDefEqWithFuel 0 context state left right =
      Except.error
        "kernel definitional equality budget exhausted" := by
  rfl

theorem psKernelIsDefEq_def
    (fuel : Nat)
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (left right : PsKernelExpr) :
    psKernelIsDefEq fuel context state left right =
      psKernelIsDefEqWithFuel fuel context state left right := by
  rfl

theorem psKernelCheckerInfer_def
    (fuel : Nat)
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (expr : PsKernelExpr) :
    psKernelCheckerInfer fuel context state expr =
      psKernelInferWithRecursorFuel
        fuel
        (psKernelIsDefEqWithFuel fuel)
        context
        state
        expr := by
  rfl

theorem psKernelCheckerWhnf_def
    (fuel : Nat)
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (expr : PsKernelExpr) :
    psKernelCheckerWhnf fuel context state expr =
      psKernelWhnfWithRecursorFuel
        fuel
        (psKernelIsDefEqWithFuel fuel)
        context
        state
        expr := by
  rfl
