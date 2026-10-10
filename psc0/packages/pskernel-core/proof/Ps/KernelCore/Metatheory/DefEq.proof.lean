import Ps.KernelCore.Metatheory.ExprEq
import Ps.KernelCore.Checker.DefEq.Quick

theorem psKernelReductionStep_implies_defeq
    (environment : PsKernelEnvironment)
    (localContext : PsKernelLocalContext)
    (left right : PsKernelExpr)
    (h :
      PsKernelReductionStep
        environment
        localContext
        left
        right) :
    PsKernelDefEqJudgment
      environment
      localContext
      left
      right := by
  exact
    PsKernelDefEqJudgment.reduction
      left
      right
      h

theorem psKernelDefEqQuick_sort_true_refines
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String
        (Prod Bool PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (left right : PsKernelLevel)
    (hLevel :
      psKernelLevelEquivalent left right = true) :
    psKernelDefEqQuick
        defeq
        context
        state
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
  · cases hExpr :
        psKernelExprEq
          (PsKernelExpr.sort left)
          (PsKernelExpr.sort right) <;>
      cases hCache :
        psKernelExprPairSetContains
          state.success
          (PsKernelExpr.sort left)
          (PsKernelExpr.sort right) <;>
      simp [
        psKernelDefEqQuick,
        hExpr,
        hCache,
        hLevel
      ]
  · exact PsKernelDefEqJudgment.sort left right hLevel

theorem psKernelDefEqQuick_literal_true_refines
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String
        (Prod Bool PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (left right : PsKernelLiteral)
    (hLiteral :
      psKernelLiteralEq left right = true) :
    psKernelDefEqQuick
        defeq
        context
        state
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
  · cases hExpr :
        psKernelExprEq
          (PsKernelExpr.lit left)
          (PsKernelExpr.lit right) <;>
      cases hCache :
        psKernelExprPairSetContains
          state.success
          (PsKernelExpr.lit left)
          (PsKernelExpr.lit right) <;>
      simp [
        psKernelDefEqQuick,
        hExpr,
        hCache,
        hLiteral
      ]
  · exact PsKernelDefEqJudgment.literal left right hLiteral


theorem psKernelDefEqQuick_expr_equal_refines
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String
        (Prod Bool PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (left right : PsKernelExpr)
    (hSound :
      PsKernelExprEqSound
        context.environment
        context.localContext)
    (hEq : psKernelExprEq left right = true) :
    psKernelDefEqQuick
        defeq context state left right =
      Except.ok
        (Prod.mk (Option.some true) state) ∧
    PsKernelDefEqJudgment
      context.environment
      context.localContext
      left
      right := by
  constructor
  · simp [psKernelDefEqQuick, hEq]
  · exact hSound left right hEq

theorem psKernelDefEqQuick_success_cache_refines
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String
        (Prod Bool PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (left right : PsKernelExpr)
    (hSound :
      PsKernelDefEqCacheSound
        context.environment
        context.localContext
        state.success)
    (hEq : psKernelExprEq left right = false)
    (hEligible :
      psKernelSemanticPairCacheEligible
        left
        right =
      true)
    (hCache :
      psKernelExprPairSetContains
        state.success left right =
      true) :
    psKernelDefEqQuick
        defeq context state left right =
      Except.ok
        (Prod.mk (Option.some true) state) ∧
    PsKernelDefEqJudgment
      context.environment
      context.localContext
      left
      right := by
  constructor
  · simp [
      psKernelDefEqQuick,
      hEq,
      hEligible,
      hCache
    ]
  · exact hSound left right hCache


theorem psKernelDefEqQuick_expr_equal_refines_unconditional
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String
        (Prod Bool PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (left right : PsKernelExpr)
    (hEq : psKernelExprEq left right = true) :
    psKernelDefEqQuick
        defeq context state left right =
      Except.ok
        (Prod.mk (Option.some true) state) ∧
    PsKernelDefEqJudgment
      context.environment
      context.localContext
      left
      right := by
  exact
    psKernelDefEqQuick_expr_equal_refines
      defeq
      context
      state
      left
      right
      (psKernelExprEqSound_all
        context.environment
        context.localContext)
      hEq


theorem psKernelReductionClosure_implies_defeq
    (environment : PsKernelEnvironment)
    (localContext : PsKernelLocalContext)
    (left right : PsKernelExpr)
    (h :
      PsKernelReductionClosure
        environment
        localContext
        left
        right) :
    PsKernelDefEqJudgment
      environment
      localContext
      left
      right :=
  PsKernelDefEqJudgment.reductionClosure
    left
    right
    h
