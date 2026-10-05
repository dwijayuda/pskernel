import Ps.KernelCore.Checker.DefEq.Shortcuts

theorem psKernelDefEqReflectionWith_disabled_for_fvar
    (whnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (left right : PsKernelExpr)
    (hFVar : psKernelExprHasFVar left = true)
    (hEager : context.eagerReduce = false) :
    psKernelDefEqReflectionWith
        whnf context state left right =
      Except.ok (Prod.mk Option.none state) := by
  simp [psKernelDefEqReflectionWith, hFVar, hEager]
