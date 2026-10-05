import Ps.KernelCore.Checker.Reduction.WhnfCore

theorem psKernelWhnfCountLambdasWithFuel_zero
    (expr : PsKernelExpr)
    (argCount count : Nat) :
    psKernelWhnfCountLambdasWithFuel
        0 expr argCount count =
      Prod.mk expr count := by
  rfl

theorem psKernelWhnfCoreFinish_cheap
    (original result : PsKernelExpr)
    (state : PsKernelCheckerState) :
    psKernelWhnfCoreFinish original true result state =
      Except.ok (Prod.mk result state) := by
  rfl

theorem psKernelWhnfFinish_result
    (original result : PsKernelExpr)
    (state : PsKernelCheckerState) :
    Prod.fst
      (match psKernelWhnfFinish original result state with
       | Except.ok pair => pair
       | Except.error _ => Prod.mk result state) =
      result := by
  rfl

theorem psKernelWhnfCoreWithFuel_zero
    (publicWhnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
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
    (expr : PsKernelExpr)
    (cheapRec cheapProj : Bool) :
    psKernelWhnfCoreWithFuel
        0 publicWhnf reduceRecursor
        context state expr cheapRec cheapProj =
      Except.error "kernel reduction budget exhausted" := by
  rfl
