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
  -- Pure, context-independent source-certified FVar-membership memo.
  -- Never stores types, DefEq facts, or admissions.
  semanticFVarMemo : PsKernelC0FVarMemo := PsKernelC0HashTrie.empty

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
    semanticFVarMemo := PsKernelC0HashTrie.empty
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
    semanticFVarMemo := state.semanticFVarMemo
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
    semanticFVarMemo := state.semanticFVarMemo
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
    semanticFVarMemo := state.semanticFVarMemo
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
    semanticFVarMemo := state.semanticFVarMemo
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
    semanticFVarMemo := state.semanticFVarMemo
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
    semanticFVarMemo := state.semanticFVarMemo
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
    semanticFVarMemo := state.semanticFVarMemo
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
      semanticFVarMemo := state.semanticFVarMemo
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
    failure := parent.failure
    -- Presence of an FVar is a pure syntactic fact independent of scope.
    semanticFVarMemo := child.semanticFVarMemo }

/-!
Source-proved, state-owned FVar memo. Repeated WHNF requests can reuse
certificates for identical immutable syntax DAGs rather than traversing
an expanded graph. Every entry is indexed by exact syntax and carries a
Lean proof of equality with `psKernelExprHasFVar`.

No entry is a type, DefEq fact or checked declaration; all existing
semantic caches still obey parent-scope restoration. A source-only FVar
presence certificate can leave local scope without changing semantics.
-/

/-- Original eligibility result and a state that differs ONLY in its
nonsemantic proof-carrying membership memo. -/
def psKernelC0SemanticEligibilityWithState
    (state : PsKernelCheckerState)
    (expr : PsKernelExpr) : Bool × PsKernelCheckerState :=
  let checked := psKernelC0FVarMemoGo expr state.semanticFVarMemo
  (!checked.1.value, { state with semanticFVarMemo := checked.2 })

/-- All-input original eligibility equality; no fuel, scope or cache
assumptions. The memo's source proof is sufficient on every lookup. -/
theorem psKernelC0SemanticEligibilityWithState_source
    (state : PsKernelCheckerState)
    (expr : PsKernelExpr) :
    (psKernelC0SemanticEligibilityWithState state expr).1 =
      psKernelSemanticCacheEligible expr := by
  change Bool.not
      (psKernelC0FVarMemoGo expr state.semanticFVarMemo).1.value =
        Bool.not (psKernelExprHasFVar expr)
  exact congrArg Bool.not
    (psKernelC0FVarMemoGo expr state.semanticFVarMemo).1.source

/-- The nonsemantic lookup cannot alter resource or checker caches. -/
theorem psKernelC0SemanticEligibilityWithState_preservesFresh
    (state : PsKernelCheckerState) (expr : PsKernelExpr) :
    (psKernelC0SemanticEligibilityWithState state expr).2.nextFresh =
      state.nextFresh := rfl

theorem psKernelC0SemanticEligibilityWithState_preservesWhnf
    (state : PsKernelCheckerState) (expr : PsKernelExpr) :
    (psKernelC0SemanticEligibilityWithState state expr).2.whnf =
      state.whnf := rfl

theorem psKernelC0SemanticEligibilityWithState_preservesWhnfCore
    (state : PsKernelCheckerState) (expr : PsKernelExpr) :
    (psKernelC0SemanticEligibilityWithState state expr).2.whnfCore =
      state.whnfCore := rfl
