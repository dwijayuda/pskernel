import Ps.KernelCore.Checker.DefEq.DeltaStep
import Ps.KernelCore.Metatheory.ExprEq

theorem psKernelDefEqFinishLazyStep_equal
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String (Prod Bool PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (left right : PsKernelExpr)
    (h :
      psKernelDefEqQuick
          defeq context state left right =
        Except.ok
          (Prod.mk (Option.some true) nextState)) :
    psKernelDefEqFinishLazyStep
        defeq context state left right =
      Except.ok
        (Prod.mk PsKernelDeltaStepResult.equal nextState) := by
  simp [psKernelDefEqFinishLazyStep, h]

theorem psKernelDefEqFinishLazyStep_different
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String (Prod Bool PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (left right : PsKernelExpr)
    (h :
      psKernelDefEqQuick
          defeq context state left right =
        Except.ok
          (Prod.mk (Option.some false) nextState)) :
    psKernelDefEqFinishLazyStep
        defeq context state left right =
      Except.ok
        (Prod.mk
          (PsKernelDeltaStepResult.different left right)
          nextState) := by
  simp [psKernelDefEqFinishLazyStep, h]

theorem psKernelDefEqFinishLazyStep_continue
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String (Prod Bool PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (left right : PsKernelExpr)
    (h :
      psKernelDefEqQuick
          defeq context state left right =
        Except.ok
          (Prod.mk Option.none nextState)) :
    psKernelDefEqFinishLazyStep
        defeq context state left right =
      Except.ok
        (Prod.mk
          (PsKernelDeltaStepResult.continue left right)
          nextState) := by
  simp [psKernelDefEqFinishLazyStep, h]


theorem psKernelDefEqFinishLazyStep_expr_equal_refines
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String (Prod Bool PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (left right : PsKernelExpr)
    (hEq : psKernelExprEq left right = true) :
    psKernelDefEqFinishLazyStep
        defeq context state left right =
      Except.ok
        (Prod.mk
          PsKernelDeltaStepResult.equal
          state) ∧
    PsKernelDefEqJudgment
      context.environment
      context.localContext
      left
      right := by
  constructor
  · simp [
      psKernelDefEqFinishLazyStep,
      psKernelDefEqQuick,
      hEq
    ]
  · exact
      psKernelExprEq_true_implies_defeq
        context.environment
        context.localContext
        left
        right
        hEq

theorem psKernelDefEqFinishLazyStep_success_cache_refines
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String (Prod Bool PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (left right : PsKernelExpr)
    (hEq : psKernelExprEq left right = false)
    (hCache :
      psKernelExprPairSetContains
          state.success
          left
          right =
        true)
    (hSound :
      PsKernelDefEqCacheSound
        context.environment
        context.localContext
        state.success) :
    psKernelDefEqFinishLazyStep
        defeq context state left right =
      Except.ok
        (Prod.mk
          PsKernelDeltaStepResult.equal
          state) ∧
    PsKernelDefEqJudgment
      context.environment
      context.localContext
      left
      right := by
  constructor
  · simp [
      psKernelDefEqFinishLazyStep,
      psKernelDefEqQuick,
      hEq,
      hCache
    ]
  · exact hSound left right hCache
