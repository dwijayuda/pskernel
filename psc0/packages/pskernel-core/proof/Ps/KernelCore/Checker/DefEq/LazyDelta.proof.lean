import Ps.KernelCore.Checker.DefEq.LazyDelta

theorem psKernelDefEqLazyReductionWithFuel_zero
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String (Prod Bool PsKernelCheckerState))
    (whnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (coreWhnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Bool ->
      Bool ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (left right : PsKernelExpr) :
    psKernelDefEqLazyReductionWithFuel
        0 defeq whnf coreWhnf
        context state left right =
      Except.error "kernel lazy-delta budget exhausted" := by
  rfl

theorem psKernelDefEqLazyProjReductionWithFuel_zero
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String (Prod Bool PsKernelCheckerState))
    (coreWhnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Bool ->
      Bool ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (left right : PsKernelExpr)
    (typeName : PsKernelName)
    (index : Nat) :
    psKernelDefEqLazyProjReductionWithFuel
        0 defeq coreWhnf
        context state left right typeName index =
      Except.error "kernel lazy-projection budget exhausted" := by
  rfl
