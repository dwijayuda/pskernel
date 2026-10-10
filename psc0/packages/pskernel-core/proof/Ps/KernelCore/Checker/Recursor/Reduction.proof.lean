import Ps.KernelCore.Checker.Recursor.Reduction

theorem psKernelReduceInductiveRecWith_bvar
    (publicWhnf :
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
    (inferType :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String (Prod Bool PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (index : Nat)
    (cheapRec cheapProj : Bool) :
    psKernelReduceInductiveRecWith
        publicWhnf coreWhnf inferType defeq
        context state (PsKernelExpr.bvar index)
        cheapRec cheapProj =
      Except.ok (Prod.mk Option.none state) := by
  rfl
