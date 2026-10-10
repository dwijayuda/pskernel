import Ps.KernelCore.Checker.State
import Ps.KernelCore.Metatheory.Judgments

theorem psKernelCheckerStateEmpty_nextFresh :
    psKernelCheckerStateEmpty.nextFresh = 0 := by
  rfl

theorem psKernelCheckerStateWithInferOnly_preserves_nextFresh
    (state : PsKernelCheckerState)
    (cache : PsKernelExprMap) :
    (psKernelCheckerStateWithInferOnly state cache).nextFresh =
      state.nextFresh := by
  rfl

theorem psKernelCheckerStateWithInferOnly_sets_cache
    (state : PsKernelCheckerState)
    (cache : PsKernelExprMap) :
    (psKernelCheckerStateWithInferOnly state cache).inferOnly =
      cache := by
  rfl

theorem psKernelCheckerStateWithCheckedInfer_preserves_inferOnly
    (state : PsKernelCheckerState)
    (cache : PsKernelExprMap) :
    (psKernelCheckerStateWithCheckedInfer state cache).inferOnly =
      state.inferOnly := by
  rfl

theorem psKernelCheckerStateWithWhnf_preserves_success
    (state : PsKernelCheckerState)
    (cache : PsKernelExprMap) :
    (psKernelCheckerStateWithWhnf state cache).success =
      state.success := by
  rfl

theorem psKernelCheckerStateWithSuccess_preserves_failure
    (state : PsKernelCheckerState)
    (cache : PsKernelExprPairSet) :
    (psKernelCheckerStateWithSuccess state cache).failure =
      state.failure := by
  rfl

theorem psKernelCheckerStateFreshName_fst
    (state : PsKernelCheckerState)
    (base : PsKernelName) :
    Prod.fst (psKernelCheckerStateFreshName state base) =
      PsKernelName.num base state.nextFresh := by
  rfl

theorem psKernelCheckerStateFreshName_nextFresh
    (state : PsKernelCheckerState)
    (base : PsKernelName) :
    (Prod.snd (psKernelCheckerStateFreshName state base)).nextFresh =
      Nat.succ state.nextFresh := by
  rfl

theorem psKernelCheckerStateFreshName_preserves_success
    (state : PsKernelCheckerState)
    (base : PsKernelName) :
    (Prod.snd (psKernelCheckerStateFreshName state base)).success =
      state.success := by
  rfl

theorem psKernelCheckerStateFreshName_preserves_failure
    (state : PsKernelCheckerState)
    (base : PsKernelName) :
    (Prod.snd (psKernelCheckerStateFreshName state base)).failure =
      state.failure := by
  rfl


theorem psKernelInferenceCacheSound_empty
    (environment : PsKernelEnvironment)
    (localContext : PsKernelLocalContext) :
    PsKernelInferenceCacheSound
      environment
      localContext
      psKernelExprMapEmpty := by
  intro expr result h
  simp [
    psKernelExprMapEmpty,
    psKernelExprMapGet,
    psKernelExprMapGetIn
  ] at h


theorem psKernelReductionCacheSound_empty
    (environment : PsKernelEnvironment)
    (localContext : PsKernelLocalContext) :
    PsKernelReductionCacheSound
      environment
      localContext
      psKernelExprMapEmpty := by
  intro expr result h
  simp [
    psKernelExprMapEmpty,
    psKernelExprMapGet,
    psKernelExprMapGetIn
  ] at h

theorem psKernelDefEqCacheSound_empty
    (environment : PsKernelEnvironment)
    (localContext : PsKernelLocalContext) :
    PsKernelDefEqCacheSound
      environment
      localContext
      psKernelExprPairSetEmpty := by
  intro left right h
  simp [
    psKernelExprPairSetEmpty,
    psKernelExprPairSetContains,
    psKernelExprPairSetContainsIn
  ] at h

theorem psKernelCheckerStateEmpty_semantic_caches_sound
    (environment : PsKernelEnvironment)
    (localContext : PsKernelLocalContext) :
    PsKernelInferOnlyCacheIsolated
        environment
        localContext
        psKernelCheckerStateEmpty.inferOnly ∧
    PsKernelInferenceCacheSound
        environment
        localContext
        psKernelCheckerStateEmpty.checkedInfer ∧
    PsKernelReductionCacheSound
        environment
        localContext
        psKernelCheckerStateEmpty.whnfCore ∧
    PsKernelReductionCacheSound
        environment
        localContext
        psKernelCheckerStateEmpty.whnf ∧
    PsKernelReductionCacheSound
        environment
        localContext
        psKernelCheckerStateEmpty.unfold ∧
    PsKernelDefEqCacheSound
        environment
        localContext
        psKernelCheckerStateEmpty.success := by
  constructor
  · simpa [psKernelCheckerStateEmpty] using
      psKernelInferOnlyCacheIsolated_empty
        environment
        localContext
  · constructor
    · simpa [psKernelCheckerStateEmpty] using
        psKernelInferenceCacheSound_empty
          environment
          localContext
    · constructor
      · simpa [psKernelCheckerStateEmpty] using
          psKernelReductionCacheSound_empty
            environment
            localContext
      · constructor
        · simpa [psKernelCheckerStateEmpty] using
            psKernelReductionCacheSound_empty
              environment
              localContext
        · constructor
          · simpa [psKernelCheckerStateEmpty] using
              psKernelReductionCacheSound_empty
                environment
                localContext
          · simpa [psKernelCheckerStateEmpty] using
              psKernelDefEqCacheSound_empty
                environment
                localContext

theorem psKernelCheckerStateEmpty_semantic_sound
    (environment : PsKernelEnvironment)
    (localContext : PsKernelLocalContext) :
    PsKernelCheckerStateSemanticSound
      environment
      localContext
      psKernelCheckerStateEmpty := by
  unfold PsKernelCheckerStateSemanticSound
  exact
    psKernelCheckerStateEmpty_semantic_caches_sound
      environment
      localContext


theorem psKernelCheckerStateExitLocalScope_nextFresh
    (parent child : PsKernelCheckerState) :
    (psKernelCheckerStateExitLocalScope parent child).nextFresh =
      Nat.max parent.nextFresh child.nextFresh := by
  rfl

theorem psKernelCheckerStateExitLocalScope_inferOnly
    (parent child : PsKernelCheckerState) :
    (psKernelCheckerStateExitLocalScope parent child).inferOnly =
      parent.inferOnly := by
  rfl

theorem psKernelCheckerStateExitLocalScope_checkedInfer
    (parent child : PsKernelCheckerState) :
    (psKernelCheckerStateExitLocalScope parent child).checkedInfer =
      parent.checkedInfer := by
  rfl

theorem psKernelCheckerStateExitLocalScope_whnfCore
    (parent child : PsKernelCheckerState) :
    (psKernelCheckerStateExitLocalScope parent child).whnfCore =
      parent.whnfCore := by
  rfl

theorem psKernelCheckerStateExitLocalScope_whnf
    (parent child : PsKernelCheckerState) :
    (psKernelCheckerStateExitLocalScope parent child).whnf =
      parent.whnf := by
  rfl

theorem psKernelCheckerStateExitLocalScope_unfold
    (parent child : PsKernelCheckerState) :
    (psKernelCheckerStateExitLocalScope parent child).unfold =
      parent.unfold := by
  rfl

theorem psKernelCheckerStateExitLocalScope_success
    (parent child : PsKernelCheckerState) :
    (psKernelCheckerStateExitLocalScope parent child).success =
      parent.success := by
  rfl

theorem psKernelCheckerStateExitLocalScope_failure
    (parent child : PsKernelCheckerState) :
    (psKernelCheckerStateExitLocalScope parent child).failure =
      parent.failure := by
  rfl
