import Ps.KernelCore.Runtime.Acceleration.Cache
import Ps.KernelCore.Runtime.Acceleration.CachePolicy

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
  -- Checked inference opens temporary binders from the checker state's
  -- independent counter. They must NEVER alias session/local-context FVars,
  -- whose names end in the `.num` constructor. A separate terminal `.str`
  -- namespace is structurally disjoint for every source binder name/counter.
  -- Caches compare exact FVar names, so this identity separation is essential
  -- for sound dependent application checking across nested binder sessions.
  let name :=
    PsKernelName.str
      (PsKernelName.num base state.nextFresh)
      "_c0_checked_binder";
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

/-- Restore parent semantic caches when leaving a local checker scope.
Only the monotone global fresh-name counter may flow out of the child. -/
def psKernelCheckerStateExitLocalScope
    (parent child : PsKernelCheckerState) : PsKernelCheckerState :=
  { nextFresh := Nat.max parent.nextFresh child.nextFresh
    inferOnly := parent.inferOnly
    checkedInfer := parent.checkedInfer
    whnfCore := parent.whnfCore
    whnf := parent.whnf
    unfold := parent.unfold
    success := parent.success
    failure := parent.failure }
