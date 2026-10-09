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


/-
Leaving a binder scope must not publish semantic cache entries learned under
that child local context.  Preserve only the globally monotone fresh-name
counter from the child computation and restore every semantic cache to the
pre-child state.

This is intentionally conservative.  PSKernel local fvar names are structural
and forgeable at raw API boundaries, unlike Lean's opaque globally unique fvar
identities, so scope-local cache knowledge must not escape its scope.
-/
def psKernelCheckerStateExitLocalScope
    (parent child : PsKernelCheckerState) :
    PsKernelCheckerState :=
  {
    nextFresh := Nat.max parent.nextFresh child.nextFresh
    inferOnly := parent.inferOnly
    checkedInfer := parent.checkedInfer
    whnfCore := parent.whnfCore
    whnf := parent.whnf
    unfold := parent.unfold
    success := parent.success
    failure := parent.failure
  }


/-- Syntax hashes are independent of the environment and local context.
Only this intrinsically certified metadata is carried out of a child scope. -/
def psKernelExprMapRetainHash (parent child : PsKernelExprMap) : PsKernelExprMap :=
  { parent with hashMemo := child.hashMemo }

theorem psKernelExprMapRetainHash_eq (parent child : PsKernelExprMap) :
    psKernelExprMapRetainHash parent child = parent := by
  cases parent
  unfold psKernelExprMapRetainHash
  congr 1
  exact Subsingleton.elim _ _

def psKernelExprPairSetRetainHash (parent child : PsKernelExprPairSet) : PsKernelExprPairSet :=
  { parent with hashMemo := child.hashMemo }

theorem psKernelExprPairSetRetainHash_eq (parent child : PsKernelExprPairSet) :
    psKernelExprPairSetRetainHash parent child = parent := by
  cases parent
  unfold psKernelExprPairSetRetainHash
  congr 1
  exact Subsingleton.elim _ _

def psKernelCheckerStateExitLocalScopeShared
    (parent child : PsKernelCheckerState) : PsKernelCheckerState :=
  {
    nextFresh := Nat.max parent.nextFresh child.nextFresh
    inferOnly := psKernelExprMapRetainHash parent.inferOnly child.inferOnly
    checkedInfer := psKernelExprMapRetainHash parent.checkedInfer child.checkedInfer
    whnfCore := psKernelExprMapRetainHash parent.whnfCore child.whnfCore
    whnf := psKernelExprMapRetainHash parent.whnf child.whnf
    unfold := psKernelExprMapRetainHash parent.unfold child.unfold
    success := psKernelExprPairSetRetainHash parent.success child.success
    failure := psKernelExprPairSetRetainHash parent.failure child.failure
  }

@[csimp] theorem psKernelCheckerStateExitLocalScope_shared_eq :
    psKernelCheckerStateExitLocalScope = psKernelCheckerStateExitLocalScopeShared := by
  funext parent child
  simp [psKernelCheckerStateExitLocalScopeShared, psKernelCheckerStateExitLocalScope,
    psKernelExprMapRetainHash_eq, psKernelExprPairSetRetainHash_eq]
