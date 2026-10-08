import Ps.KernelCore.Runtime.Acceleration.Cache

structure PsKernelCheckerState where
  nextFresh : Nat
  inferOnly : PsKernelExprMap
  checkedInfer : PsKernelExprMap
  whnfCore : PsKernelExprMap
  whnf : PsKernelExprMap
  unfold : PsKernelExprMap
  success : PsKernelExprPairSet
  failure : PsKernelExprPairSet

def psKernelCheckerStateEmpty :
    PsKernelCheckerState :=
  {
    nextFresh := 0
    inferOnly := psKernelExprMapEmpty
    checkedInfer := psKernelExprMapEmpty
    whnfCore := psKernelExprMapEmpty
    whnf := psKernelExprMapEmpty
    unfold := psKernelExprMapEmpty
    success := psKernelExprPairSetEmpty
    failure := psKernelExprPairSetEmpty
  }

def psKernelCheckerStateWithInferOnly
    (state : PsKernelCheckerState)
    (cache : PsKernelExprMap) :
    PsKernelCheckerState :=
  {
    nextFresh := state.nextFresh
    inferOnly := cache
    checkedInfer := state.checkedInfer
    whnfCore := state.whnfCore
    whnf := state.whnf
    unfold := state.unfold
    success := state.success
    failure := state.failure
  }

def psKernelCheckerStateWithCheckedInfer
    (state : PsKernelCheckerState)
    (cache : PsKernelExprMap) :
    PsKernelCheckerState :=
  {
    nextFresh := state.nextFresh
    inferOnly := state.inferOnly
    checkedInfer := cache
    whnfCore := state.whnfCore
    whnf := state.whnf
    unfold := state.unfold
    success := state.success
    failure := state.failure
  }

def psKernelCheckerStateWithWhnfCore
    (state : PsKernelCheckerState)
    (cache : PsKernelExprMap) :
    PsKernelCheckerState :=
  {
    nextFresh := state.nextFresh
    inferOnly := state.inferOnly
    checkedInfer := state.checkedInfer
    whnfCore := cache
    whnf := state.whnf
    unfold := state.unfold
    success := state.success
    failure := state.failure
  }

def psKernelCheckerStateWithWhnf
    (state : PsKernelCheckerState)
    (cache : PsKernelExprMap) :
    PsKernelCheckerState :=
  {
    nextFresh := state.nextFresh
    inferOnly := state.inferOnly
    checkedInfer := state.checkedInfer
    whnfCore := state.whnfCore
    whnf := cache
    unfold := state.unfold
    success := state.success
    failure := state.failure
  }

def psKernelCheckerStateWithUnfold
    (state : PsKernelCheckerState)
    (cache : PsKernelExprMap) :
    PsKernelCheckerState :=
  {
    nextFresh := state.nextFresh
    inferOnly := state.inferOnly
    checkedInfer := state.checkedInfer
    whnfCore := state.whnfCore
    whnf := state.whnf
    unfold := cache
    success := state.success
    failure := state.failure
  }

def psKernelCheckerStateWithSuccess
    (state : PsKernelCheckerState)
    (cache : PsKernelExprPairSet) :
    PsKernelCheckerState :=
  {
    nextFresh := state.nextFresh
    inferOnly := state.inferOnly
    checkedInfer := state.checkedInfer
    whnfCore := state.whnfCore
    whnf := state.whnf
    unfold := state.unfold
    success := cache
    failure := state.failure
  }

def psKernelCheckerStateWithFailure
    (state : PsKernelCheckerState)
    (cache : PsKernelExprPairSet) :
    PsKernelCheckerState :=
  {
    nextFresh := state.nextFresh
    inferOnly := state.inferOnly
    checkedInfer := state.checkedInfer
    whnfCore := state.whnfCore
    whnf := state.whnf
    unfold := state.unfold
    success := state.success
    failure := cache
  }

def psKernelCheckerStateFreshName
    (state : PsKernelCheckerState)
    (base : PsKernelName) :
    Prod PsKernelName PsKernelCheckerState :=
  let name :=
    PsKernelName.num
      base
      state.nextFresh;
  Prod.mk
    name
    {
      nextFresh := Nat.succ state.nextFresh
      inferOnly := state.inferOnly
      checkedInfer := state.checkedInfer
      whnfCore := state.whnfCore
      whnf := state.whnf
      unfold := state.unfold
      success := state.success
      failure := state.failure
    }
