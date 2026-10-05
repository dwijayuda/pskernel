import Ps.KernelCore.Metatheory.Judgments
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
