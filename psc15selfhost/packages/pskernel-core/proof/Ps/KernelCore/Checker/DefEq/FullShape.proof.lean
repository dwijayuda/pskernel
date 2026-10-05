import Ps.KernelCore.Checker.DefEq.FullShape
import Ps.KernelCore.Metatheory.Judgments

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


theorem psKernelDefEqFullShape_sort_true_refines
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
    (left right : PsKernelLevel)
    (hLevel : psKernelLevelEquivalent left right = true) :
    psKernelDefEqFullShapeWith
        defeq inferType whnf context state
        (PsKernelExpr.sort left)
        (PsKernelExpr.sort right) =
      Except.ok
        (Prod.mk (Option.some true) state) ∧
    PsKernelDefEqJudgment
      context.environment
      context.localContext
      (PsKernelExpr.sort left)
      (PsKernelExpr.sort right) := by
  constructor
  · simpa [hLevel] using
      psKernelDefEqFullShape_sort_sort
        defeq inferType whnf context state left right
  · exact PsKernelDefEqJudgment.sort left right hLevel

theorem psKernelDefEqFullShape_literal_true_refines
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
    (left right : PsKernelLiteral)
    (hLiteral : psKernelLiteralEq left right = true) :
    psKernelDefEqFullShapeWith
        defeq inferType whnf context state
        (PsKernelExpr.lit left)
        (PsKernelExpr.lit right) =
      Except.ok
        (Prod.mk (Option.some true) state) ∧
    PsKernelDefEqJudgment
      context.environment
      context.localContext
      (PsKernelExpr.lit left)
      (PsKernelExpr.lit right) := by
  constructor
  · simpa [hLiteral] using
      psKernelDefEqFullShape_lit_lit
        defeq inferType whnf context state left right
  · exact PsKernelDefEqJudgment.literal left right hLiteral
