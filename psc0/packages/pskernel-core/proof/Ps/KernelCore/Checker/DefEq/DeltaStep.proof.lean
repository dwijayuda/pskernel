import Ps.KernelCore.Checker.DefEq.DeltaStep
import Ps.KernelCore.Metatheory.ExprEq
import Ps.KernelCore.Metatheory.Delta

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
    (hEligible :
      psKernelSemanticPairCacheEligible left right =
        true)
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
      hEligible,
      hCache
    ]
  · exact hSound left right hCache


theorem psKernelDefEqDeltaOnce_success_refines_reduction
    (coreWhnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Bool ->
      Bool ->
      Except String
        (Prod PsKernelExpr PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (expr result : PsKernelExpr)
    (hIndex :
      PsKernelEnvironmentIndexRefines context.environment)
    (hCache :
      PsKernelReductionCacheSound
        context.environment
        context.localContext
        state.unfold)
    (hCoreSound :
      PsKernelWhnfCoreSound coreWhnf)
    (hSuccess :
      psKernelDefEqDeltaOnce
          coreWhnf
          context
          state
          expr =
        Except.ok (Prod.mk result nextState)) :
    PsKernelReductionClosure
      context.environment
      context.localContext
      expr
      result :=
  psKernelDefEqDeltaOnce_refines_reduction
    coreWhnf
    context
    state
    nextState
    expr
    result
    hIndex
    hCache
    hCoreSound
    hSuccess

theorem psKernelDefEqTryUnfoldProjApp_success_refines_reduction
    (coreWhnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Bool ->
      Bool ->
      Except String
        (Prod PsKernelExpr PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (expr result : PsKernelExpr)
    (hCoreSound :
      PsKernelWhnfCoreSound coreWhnf)
    (hSuccess :
      psKernelDefEqTryUnfoldProjApp
          coreWhnf
          context
          state
          expr =
        Except.ok
          (Prod.mk (Option.some result) nextState)) :
    PsKernelReductionClosure
      context.environment
      context.localContext
      expr
      result :=
  psKernelDefEqTryUnfoldProjApp_some_refines_reduction
    coreWhnf
    context
    state
    nextState
    expr
    result
    hCoreSound
    hSuccess


theorem psKernelDefEqUnfold_fvar_cache_miss
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (name : PsKernelName)
    (hMiss : psKernelExprMapGet state.unfold (.fvar name) = none) :
    psKernelDefEqUnfold context state (.fvar name) =
      Prod.mk Option.none state := by
  simp [psKernelDefEqUnfold, psKernelSemanticCacheEligible,
    psKernelSemanticCacheRemaining, psKernelSemanticCacheNodeBudget,
    hMiss, psKernelUnfoldDefinition, psKernelExprGetAppFn]
