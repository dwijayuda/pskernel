import Ps.KernelCore.Checker.DefEq.BinderSpines
import Ps.KernelCore.Metatheory.ContextState
import Ps.KernelCore.Metatheory.CacheSemantic

theorem psKernelDefEqFinish_false
    (state : PsKernelCheckerState)
    (left right : PsKernelExpr) :
    psKernelDefEqFinish state left right false =
      Prod.mk false state := by
  rfl

theorem psKernelDefEqFinish_true_value
    (state : PsKernelCheckerState)
    (left right : PsKernelExpr) :
    Prod.fst (psKernelDefEqFinish state left right true) =
      true := by
  cases hEligible :
      psKernelSemanticPairCacheEligible left right <;>
    simp [psKernelDefEqFinish, hEligible]

theorem psKernelDefEqFinish_true_preserves_failure
    (state : PsKernelCheckerState)
    (left right : PsKernelExpr) :
    (Prod.snd
      (psKernelDefEqFinish state left right true)).failure =
      state.failure := by
  cases hEligible :
      psKernelSemanticPairCacheEligible left right <;>
    simp [
      psKernelDefEqFinish,
      hEligible,
      psKernelCheckerStateWithSuccess
    ]

theorem psKernelDefEqLambdaSpineWithFuel_zero
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String (Prod Bool PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (left right : PsKernelExpr)
    (subst : List PsKernelExpr) :
    psKernelDefEqLambdaSpineWithFuel
        0 defeq context state left right subst =
      Except.error
        "kernel defeq lambda-spine budget exhausted" := by
  rfl


theorem psKernelDefEqFinish_preserves_semantic_sound
    (environment : PsKernelEnvironment)
    (localContext : PsKernelLocalContext)
    (state : PsKernelCheckerState)
    (left right : PsKernelExpr)
    (value : Bool)
    (hInsert : PsKernelDefEqCacheInsertLaw)
    (hState :
      PsKernelCheckerStateSemanticSound
        environment
        localContext
        state)
    (hDefEq :
      PsKernelDefEqJudgment
        environment
        localContext
        left
        right) :
    PsKernelCheckerStateSemanticSound
      environment
      localContext
      (Prod.snd
        (psKernelDefEqFinish
          state
          left
          right
          value)) := by
  unfold PsKernelCheckerStateSemanticSound at hState ⊢
  rcases hState with
    ⟨hInferOnly, hChecked, hWhnfCore, hWhnf, hUnfold, hSuccess⟩
  cases value with
  | false =>
      simpa [psKernelDefEqFinish] using
        (show
          PsKernelInferOnlyCacheIsolated
              environment localContext state.inferOnly ∧
            PsKernelInferenceCacheSound
              environment localContext state.checkedInfer ∧
            PsKernelReductionCacheSound
              environment localContext state.whnfCore ∧
            PsKernelReductionCacheSound
              environment localContext state.whnf ∧
            PsKernelReductionCacheSound
              environment localContext state.unfold ∧
            PsKernelDefEqCacheSound
              environment localContext state.success
          from
            ⟨hInferOnly, hChecked, hWhnfCore, hWhnf, hUnfold, hSuccess⟩)
  | true =>
      cases hEligible :
          psKernelSemanticPairCacheEligible left right with
      | false =>
          simpa [
            psKernelDefEqFinish,
            hEligible
          ] using
            (show
              PsKernelInferOnlyCacheIsolated
                  environment localContext state.inferOnly ∧
                PsKernelInferenceCacheSound
                  environment localContext state.checkedInfer ∧
                PsKernelReductionCacheSound
                  environment localContext state.whnfCore ∧
                PsKernelReductionCacheSound
                  environment localContext state.whnf ∧
                PsKernelReductionCacheSound
                  environment localContext state.unfold ∧
                PsKernelDefEqCacheSound
                  environment localContext state.success
              from
                ⟨hInferOnly, hChecked, hWhnfCore, hWhnf, hUnfold, hSuccess⟩)
      | true =>
          simpa [
            psKernelDefEqFinish,
            hEligible,
            psKernelCheckerStateWithSuccess
          ] using
            (show
              PsKernelInferOnlyCacheIsolated
                  environment localContext state.inferOnly ∧
                PsKernelInferenceCacheSound
                  environment localContext state.checkedInfer ∧
                PsKernelReductionCacheSound
                  environment localContext state.whnfCore ∧
                PsKernelReductionCacheSound
                  environment localContext state.whnf ∧
                PsKernelReductionCacheSound
                  environment localContext state.unfold ∧
                PsKernelDefEqCacheSound
                  environment localContext
                  (psKernelExprPairSetInsert
                    state.success left right)
              from
                ⟨
                  hInferOnly,
                  hChecked,
                  hWhnfCore,
                  hWhnf,
                  hUnfold,
                  hInsert
                    environment
                    localContext
                    state.success
                    left
                    right
                    hSuccess
                    hDefEq
                ⟩)



theorem psKernelDefEqFinish_value
    (state : PsKernelCheckerState)
    (left right : PsKernelExpr)
    (value : Bool) :
    Prod.fst
        (psKernelDefEqFinish
          state left right value) =
      value := by
  cases value with
  | false =>
      rfl
  | true =>
      exact psKernelDefEqFinish_true_value state left right


theorem psKernelDefEqFinish_preserves_configuration
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (left right : PsKernelExpr)
    (value : Bool)
    (hConfig :
      PsKernelCheckerConfigurationSound
        context
        state)
    (hDefEq :
      PsKernelDefEqJudgment
        context.environment
        context.localContext
        left
        right) :
    PsKernelCheckerConfigurationSound
      context
      (Prod.snd
        (psKernelDefEqFinish
          state
          left
          right
          value)) := by
  rcases hConfig with
    ⟨hIndex, hFresh, hState⟩
  refine ⟨hIndex, ?_, ?_⟩
  · have hNext :
        (Prod.snd
          (psKernelDefEqFinish
            state left right value)).nextFresh =
          state.nextFresh := by
      cases value with
      | false =>
          rfl
      | true =>
          cases hEligible :
              psKernelSemanticPairCacheEligible
                left
                right <;>
            simp [
              psKernelDefEqFinish,
              hEligible,
              psKernelCheckerStateWithSuccess
            ]
    simpa [hNext] using hFresh
  · exact
      psKernelDefEqFinish_preserves_semantic_sound
        context.environment
        context.localContext
        state
        left
        right
        value
        psKernelDefEqCacheInsertLaw_all
        hState
        hDefEq


theorem psKernelDefEqFinish_configuration_refines
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (left right : PsKernelExpr)
    (value : Bool)
    (hConfig :
      PsKernelCheckerConfigurationSound
        context
        state)
    (hDefEq :
      value = true ->
        PsKernelDefEqJudgment
          context.environment
          context.localContext
          left
          right) :
    PsKernelCheckerConfigurationSound
        context
        (Prod.snd
          (psKernelDefEqFinish
            state left right value)) ∧
      (Prod.fst
          (psKernelDefEqFinish
            state left right value) =
        true ->
        PsKernelDefEqJudgment
          context.environment
          context.localContext
          left
          right) := by
  cases value with
  | false =>
      constructor
      · simpa [psKernelDefEqFinish] using hConfig
      · simp [psKernelDefEqFinish]
  | true =>
      have hSemantic := hDefEq rfl
      constructor
      · exact
          psKernelDefEqFinish_preserves_configuration
            context state left right true hConfig hSemantic
      · intro _
        exact hSemantic


theorem psKernelDefEqFinish_fvar_pair_not_cached
    (state : PsKernelCheckerState)
    (name : PsKernelName)
    (right : PsKernelExpr) :
    psKernelDefEqFinish
        state
        (PsKernelExpr.fvar name)
        right
        true =
      Prod.mk true state := by
  simp [
    psKernelDefEqFinish,
    psKernelSemanticPairCacheEligible,
    psKernelSemanticCacheEligible,
    psKernelExprHasFVar
  ]
