import Ps.KernelCore.Checker.DefEq.FullShape

theorem psKernelDefEqFullShape_sort_sort
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String (Prod Bool PsKernelCheckerState))
    (inferType :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (whnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (left right : PsKernelLevel) :
    psKernelDefEqFullShapeWith
        defeq inferType whnf context state
        (PsKernelExpr.sort left)
        (PsKernelExpr.sort right) =
      Except.ok
        (Prod.mk
          (Option.some
            (psKernelLevelEquivalent left right))
          state) := by
  rfl

theorem psKernelDefEqFullShape_sort_bvar
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String (Prod Bool PsKernelCheckerState))
    (inferType :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (whnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (level : PsKernelLevel)
    (index : Nat) :
    psKernelDefEqFullShapeWith
        defeq inferType whnf context state
        (PsKernelExpr.sort level)
        (PsKernelExpr.bvar index) =
      Except.ok
        (Prod.mk Option.none state) := by
  rfl

theorem psKernelDefEqFullShape_lit_lit
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String (Prod Bool PsKernelCheckerState))
    (inferType :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (whnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (left right : PsKernelLiteral) :
    psKernelDefEqFullShapeWith
        defeq inferType whnf context state
        (PsKernelExpr.lit left)
        (PsKernelExpr.lit right) =
      Except.ok
        (Prod.mk
          (Option.some (psKernelLiteralEq left right))
          state) := by
  rfl
