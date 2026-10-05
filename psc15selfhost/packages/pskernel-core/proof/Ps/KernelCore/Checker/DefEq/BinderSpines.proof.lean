import Ps.KernelCore.Checker.DefEq.BinderSpines

theorem psKernelDefEqFinish_false
    (state : PsKernelCheckerState)
    (left right : PsKernelExpr) :
    psKernelDefEqFinish state left right false =
      Prod.mk false state := by
  rfl

theorem psKernelDefEqFinish_true_value
    (state : PsKernelCheckerState)
    (left right : PsKernelExpr) :
    Prod.fst (psKernelDefEqFinish state left right true) =
      true := by
  rfl

theorem psKernelDefEqFinish_true_preserves_failure
    (state : PsKernelCheckerState)
    (left right : PsKernelExpr) :
    (Prod.snd
      (psKernelDefEqFinish state left right true)).failure =
      state.failure := by
  rfl

theorem psKernelDefEqLambdaSpineWithFuel_zero
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String (Prod Bool PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (left right : PsKernelExpr)
    (subst : List PsKernelExpr) :
    psKernelDefEqLambdaSpineWithFuel
        0 defeq context state left right subst =
      Except.error
        "kernel defeq lambda-spine budget exhausted" := by
  rfl
