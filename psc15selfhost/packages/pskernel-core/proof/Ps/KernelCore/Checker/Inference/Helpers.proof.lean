import Ps.KernelCore.Checker.Inference.Helpers

theorem psKernelCacheInferResult_ineligible
    (state : PsKernelCheckerState)
    (inferOnly : Bool)
    (expr result : PsKernelExpr)
    (h : psKernelInferCacheEligible inferOnly expr = false) :
    psKernelCacheInferResult state inferOnly expr result = state := by
  simp [psKernelCacheInferResult, h]

theorem psKernelEnsureSortWith_sort
    (whnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (level : PsKernelLevel) :
    psKernelEnsureSortWith
        whnf context state (PsKernelExpr.sort level) =
      Except.ok (Prod.mk level state) := by
  rfl

theorem psKernelEnsureForallWith_forall
    (whnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (name : PsKernelName)
    (domain body : PsKernelExpr)
    (binderInfo : PsKernelBinderInfo) :
    psKernelEnsureForallWith
        whnf context state
        (PsKernelExpr.forallE name domain body binderInfo) =
      Except.ok
        (Prod.mk
          (PsKernelForallView.mk name domain body binderInfo)
          state) := by
  rfl

theorem psKernelInferAppOnlyLoopWithFuel_zero
    (whnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (args : List PsKernelExpr)
    (index instantiated : Nat)
    (current : PsKernelExpr) :
    psKernelInferAppOnlyLoopWithFuel
        0 whnf context state args index instantiated current =
      Except.error "kernel inference budget exhausted" := by
  rfl


theorem psKernelCacheInferResult_preserves_nextFresh
    (state : PsKernelCheckerState)
    (inferOnly : Bool)
    (expr result : PsKernelExpr) :
    (psKernelCacheInferResult
      state inferOnly expr result).nextFresh =
      state.nextFresh := by
  cases hEligible :
      psKernelInferCacheEligible inferOnly expr <;>
    cases inferOnly <;>
    simp [
      psKernelCacheInferResult,
      hEligible,
      psKernelCheckerStateWithInferOnly,
      psKernelCheckerStateWithCheckedInfer
    ]

theorem psKernelCacheInferResult_inferOnly_preserves_checked
    (state : PsKernelCheckerState)
    (expr result : PsKernelExpr) :
    (psKernelCacheInferResult
      state true expr result).checkedInfer =
      state.checkedInfer := by
  cases hEligible :
      psKernelInferCacheEligible true expr <;>
    simp [
      psKernelCacheInferResult,
      hEligible,
      psKernelCheckerStateWithInferOnly
    ]

theorem psKernelCacheInferResult_checked_preserves_inferOnly
    (state : PsKernelCheckerState)
    (expr result : PsKernelExpr) :
    (psKernelCacheInferResult
      state false expr result).inferOnly =
      state.inferOnly := by
  cases hEligible :
      psKernelInferCacheEligible false expr <;>
    simp [
      psKernelCacheInferResult,
      hEligible,
      psKernelCheckerStateWithCheckedInfer
    ]

theorem psKernelCacheInferResult_preserves_whnf
    (state : PsKernelCheckerState)
    (inferOnly : Bool)
    (expr result : PsKernelExpr) :
    (psKernelCacheInferResult
      state inferOnly expr result).whnf =
      state.whnf := by
  cases hEligible :
      psKernelInferCacheEligible inferOnly expr <;>
    cases inferOnly <;>
    simp [
      psKernelCacheInferResult,
      hEligible,
      psKernelCheckerStateWithInferOnly,
      psKernelCheckerStateWithCheckedInfer
    ]

theorem psKernelCacheInferResult_preserves_defeq_caches
    (state : PsKernelCheckerState)
    (inferOnly : Bool)
    (expr result : PsKernelExpr) :
    (psKernelCacheInferResult
      state inferOnly expr result).success =
        state.success ∧
    (psKernelCacheInferResult
      state inferOnly expr result).failure =
        state.failure := by
  cases hEligible :
      psKernelInferCacheEligible inferOnly expr <;>
    cases inferOnly <;>
    simp [
      psKernelCacheInferResult,
      hEligible,
      psKernelCheckerStateWithInferOnly,
      psKernelCheckerStateWithCheckedInfer
    ]
