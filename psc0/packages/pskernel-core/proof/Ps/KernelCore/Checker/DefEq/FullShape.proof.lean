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


/-
Regression lock for Lean-compatible symmetric function eta.

After the full-shape/WHNF stage, a lambda on either side must route to the
corresponding eta helper whenever the other side is not itself a lambda.
These equations directly cover the application/partial-application family that
Arena exposed, plus the constant-function shape handled by the same rule.
-/

theorem psKernelDefEqFullShape_app_lambda_uses_eta_right
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String (Prod Bool PsKernelCheckerState))
    (inferType whnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (fn arg : PsKernelExpr)
    (name : PsKernelName)
    (domain body : PsKernelExpr)
    (binderInfo : PsKernelBinderInfo) :
    psKernelDefEqFullShapeWith
        defeq inferType whnf context state
        (PsKernelExpr.app fn arg)
        (PsKernelExpr.lam name domain body binderInfo) =
      psKernelDefEqLambdaEtaRightWith
        defeq inferType whnf context state
        (PsKernelExpr.app fn arg)
        (PsKernelExpr.lam name domain body binderInfo) := by
  rfl


theorem psKernelDefEqFullShape_lambda_app_uses_eta_left
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String (Prod Bool PsKernelCheckerState))
    (inferType whnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (fn arg : PsKernelExpr)
    (name : PsKernelName)
    (domain body : PsKernelExpr)
    (binderInfo : PsKernelBinderInfo) :
    psKernelDefEqFullShapeWith
        defeq inferType whnf context state
        (PsKernelExpr.lam name domain body binderInfo)
        (PsKernelExpr.app fn arg) =
      psKernelDefEqLambdaEtaLeftWith
        defeq inferType whnf context state
        (PsKernelExpr.lam name domain body binderInfo)
        (PsKernelExpr.app fn arg) := by
  rfl


theorem psKernelDefEqFullShape_const_lambda_uses_eta_right
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String (Prod Bool PsKernelCheckerState))
    (inferType whnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (constName : PsKernelName)
    (levels : List PsKernelLevel)
    (name : PsKernelName)
    (domain body : PsKernelExpr)
    (binderInfo : PsKernelBinderInfo) :
    psKernelDefEqFullShapeWith
        defeq inferType whnf context state
        (PsKernelExpr.const constName levels)
        (PsKernelExpr.lam name domain body binderInfo) =
      psKernelDefEqLambdaEtaRightWith
        defeq inferType whnf context state
        (PsKernelExpr.const constName levels)
        (PsKernelExpr.lam name domain body binderInfo) := by
  rfl


theorem psKernelDefEqFullShape_lambda_const_uses_eta_left
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String (Prod Bool PsKernelCheckerState))
    (inferType whnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (constName : PsKernelName)
    (levels : List PsKernelLevel)
    (name : PsKernelName)
    (domain body : PsKernelExpr)
    (binderInfo : PsKernelBinderInfo) :
    psKernelDefEqFullShapeWith
        defeq inferType whnf context state
        (PsKernelExpr.lam name domain body binderInfo)
        (PsKernelExpr.const constName levels) =
      psKernelDefEqLambdaEtaLeftWith
        defeq inferType whnf context state
        (PsKernelExpr.lam name domain body binderInfo)
        (PsKernelExpr.const constName levels) := by
  rfl
