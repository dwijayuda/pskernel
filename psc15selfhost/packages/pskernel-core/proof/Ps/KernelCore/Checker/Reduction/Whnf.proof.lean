import Ps.KernelCore.Checker.Reduction.Whnf

theorem psKernelWhnfWithFuel_zero
    (reduceRecursor :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Bool ->
      Bool ->
      Except String
        (Prod (Option PsKernelExpr) PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (expr : PsKernelExpr) :
    psKernelWhnfWithFuel
        0 reduceRecursor context state expr =
      Except.error "kernel reduction budget exhausted" := by
  rfl

theorem psKernelWhnfWithFuel_bvar
    (remaining : Nat)
    (reduceRecursor :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Bool ->
      Bool ->
      Except String
        (Prod (Option PsKernelExpr) PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (index : Nat) :
    psKernelWhnfWithFuel
        (Nat.succ remaining)
        reduceRecursor
        context
        state
        (PsKernelExpr.bvar index) =
      Except.ok
        (Prod.mk (PsKernelExpr.bvar index) state) := by
  rfl

theorem psKernelWhnfWithFuel_sort
    (remaining : Nat)
    (reduceRecursor :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Bool ->
      Bool ->
      Except String
        (Prod (Option PsKernelExpr) PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (level : PsKernelLevel) :
    psKernelWhnfWithFuel
        (Nat.succ remaining)
        reduceRecursor
        context
        state
        (PsKernelExpr.sort level) =
      Except.ok
        (Prod.mk (PsKernelExpr.sort level) state) := by
  rfl

theorem psKernelWhnfNoRecursor_def
    (fuel : Nat)
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (expr : PsKernelExpr) :
    psKernelWhnfNoRecursor fuel context state expr =
      psKernelWhnfWithFuel
        fuel psKernelNoRecursorReduction context state expr := by
  rfl
