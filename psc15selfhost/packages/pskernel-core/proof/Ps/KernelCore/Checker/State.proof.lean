import Ps.KernelCore.Checker.State

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
