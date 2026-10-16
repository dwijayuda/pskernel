import Ps.KernelCore.Architecture.VerifiedIndexedHash
import Ps.KernelCore.Checker.State

/-!
A state-threaded, source-exact cache interface for immutable indexed syntax.
Each operation is an executable optimization with a Lean proof equating the
ENTIRE source state/cache result. In particular no hash, raw index or
previous proof receipt is permitted to authorize a checked judgment.

The certificate owner is immutable and every source expression originates
from that owner. Calling these helpers is not by itself type checking, DefEq
or admission; source algorithms retain their full error and resource rules.

This module is opt-in. A separate source-refinement theorem is required
before replacing a step of the public checked-inference state machine.
-/

/-- The five existing expression-result caches that can share certified
checker-hash bucket selection. A route never changes the original source
cache's selection, shape or insertion semantics. -/
inductive PsKernelC0IndexedExprCacheRoute where
  | checkedInfer
  | inferOnly
  | whnfCore
  | whnf
  | unfold
  deriving DecidableEq, Repr

def psKernelC0IndexedExprCacheSelect
    (route : PsKernelC0IndexedExprCacheRoute)
    (state : PsKernelCheckerState) : PsKernelExprMap :=
  match route with
  | .checkedInfer => state.checkedInfer
  | .inferOnly => state.inferOnly
  | .whnfCore => state.whnfCore
  | .whnf => state.whnf
  | .unfold => state.unfold

def psKernelC0IndexedExprCacheReplace
    (route : PsKernelC0IndexedExprCacheRoute)
    (state : PsKernelCheckerState)
    (cache : PsKernelExprMap) : PsKernelCheckerState :=
  match route with
  | .checkedInfer => psKernelCheckerStateWithCheckedInfer state cache
  | .inferOnly => psKernelCheckerStateWithInferOnly state cache
  | .whnfCore => psKernelCheckerStateWithWhnfCore state cache
  | .whnf => psKernelCheckerStateWithWhnf state cache
  | .unfold => psKernelCheckerStateWithUnfold state cache

/-- Exact source expression-map lookup in the corresponding source state
slot, using the O(1) checked-hash column as a bucket hint only. -/
def psKernelC0VerifiedIndexedStateCacheGet
    {owner : PsKernelC0CertifiedStore} {id : Nat}
    (route : PsKernelC0IndexedExprCacheRoute)
    (state : PsKernelCheckerState)
    (proof : PsKernelC0VerifiedIndexedHash owner id) :
    Option PsKernelExpr :=
  psKernelC0VerifiedIndexedCacheGet proof
    (psKernelC0IndexedExprCacheSelect route state)

theorem psKernelC0VerifiedIndexedStateCacheGet_source
    {owner : PsKernelC0CertifiedStore} {id : Nat}
    (route : PsKernelC0IndexedExprCacheRoute)
    (state : PsKernelCheckerState)
    (proof : PsKernelC0VerifiedIndexedHash owner id) :
    psKernelC0VerifiedIndexedStateCacheGet route state proof =
      psKernelExprMapGet
        (psKernelC0IndexedExprCacheSelect route state)
        proof.expr :=
  psKernelC0VerifiedIndexedCacheGet_source proof
    (psKernelC0IndexedExprCacheSelect route state)

/-- Source-exact state update after a checked type or reduction result.
The original cache still compares COMPLETE expression syntax after hashing.
Other checker-state fields are carried untouched through the original
state-update constructor. -/
def psKernelC0VerifiedIndexedStateCacheInsert
    {owner : PsKernelC0CertifiedStore} {id : Nat}
    (route : PsKernelC0IndexedExprCacheRoute)
    (state : PsKernelCheckerState)
    (proof : PsKernelC0VerifiedIndexedHash owner id)
    (result : PsKernelExpr) : PsKernelCheckerState :=
  psKernelC0IndexedExprCacheReplace route state
    (psKernelC0VerifiedIndexedCacheInsert proof
      (psKernelC0IndexedExprCacheSelect route state) result)

theorem psKernelC0VerifiedIndexedStateCacheInsert_source
    {owner : PsKernelC0CertifiedStore} {id : Nat}
    (route : PsKernelC0IndexedExprCacheRoute)
    (state : PsKernelCheckerState)
    (proof : PsKernelC0VerifiedIndexedHash owner id)
    (result : PsKernelExpr) :
    psKernelC0VerifiedIndexedStateCacheInsert route state proof result =
      psKernelC0IndexedExprCacheReplace route state
        (psKernelExprMapInsert
          (psKernelC0IndexedExprCacheSelect route state)
          proof.expr result) := by
  unfold psKernelC0VerifiedIndexedStateCacheInsert
  rw [psKernelC0VerifiedIndexedCacheInsert_source]

/-- Original DefEq pair-cache slots. A successful match is still only the
source cache observation, not a new definitional-equality judgment. -/
inductive PsKernelC0IndexedPairCacheRoute where
  | success
  | failure
  deriving DecidableEq, Repr

def psKernelC0IndexedPairCacheSelect
    (route : PsKernelC0IndexedPairCacheRoute)
    (state : PsKernelCheckerState) : PsKernelExprPairSet :=
  match route with
  | .success => state.success
  | .failure => state.failure

def psKernelC0IndexedPairCacheReplace
    (route : PsKernelC0IndexedPairCacheRoute)
    (state : PsKernelCheckerState)
    (cache : PsKernelExprPairSet) : PsKernelCheckerState :=
  match route with
  | .success => psKernelCheckerStateWithSuccess state cache
  | .failure => psKernelCheckerStateWithFailure state cache

/-- Exact original success or failure-cache membership. Symmetric source
pair comparison resolves collisions after the certified-hash bucket hint. -/
def psKernelC0VerifiedIndexedStatePairContains
    {owner : PsKernelC0CertifiedStore}
    {leftId rightId : Nat}
    (route : PsKernelC0IndexedPairCacheRoute)
    (state : PsKernelCheckerState)
    (left : PsKernelC0VerifiedIndexedHash owner leftId)
    (right : PsKernelC0VerifiedIndexedHash owner rightId) : Bool :=
  psKernelC0VerifiedIndexedPairContains
    (psKernelC0IndexedPairCacheSelect route state) left right

theorem psKernelC0VerifiedIndexedStatePairContains_source
    {owner : PsKernelC0CertifiedStore}
    {leftId rightId : Nat}
    (route : PsKernelC0IndexedPairCacheRoute)
    (state : PsKernelCheckerState)
    (left : PsKernelC0VerifiedIndexedHash owner leftId)
    (right : PsKernelC0VerifiedIndexedHash owner rightId) :
    psKernelC0VerifiedIndexedStatePairContains route state left right =
      psKernelExprPairSetContains
        (psKernelC0IndexedPairCacheSelect route state)
        left.expr right.expr :=
  psKernelC0VerifiedIndexedPairContains_source
    (psKernelC0IndexedPairCacheSelect route state) left right

/-- Source-equivalent success or failure-cache insertion. Both endpoints
must originate in the same immutable certified owner and retain exact
propositional source equality through the indexed certificates. -/
def psKernelC0VerifiedIndexedStatePairInsert
    {owner : PsKernelC0CertifiedStore}
    {leftId rightId : Nat}
    (route : PsKernelC0IndexedPairCacheRoute)
    (state : PsKernelCheckerState)
    (left : PsKernelC0VerifiedIndexedHash owner leftId)
    (right : PsKernelC0VerifiedIndexedHash owner rightId) :
    PsKernelCheckerState :=
  psKernelC0IndexedPairCacheReplace route state
    (psKernelC0VerifiedIndexedPairInsert
      (psKernelC0IndexedPairCacheSelect route state) left right)

theorem psKernelC0VerifiedIndexedStatePairInsert_source
    {owner : PsKernelC0CertifiedStore}
    {leftId rightId : Nat}
    (route : PsKernelC0IndexedPairCacheRoute)
    (state : PsKernelCheckerState)
    (left : PsKernelC0VerifiedIndexedHash owner leftId)
    (right : PsKernelC0VerifiedIndexedHash owner rightId) :
    psKernelC0VerifiedIndexedStatePairInsert route state left right =
      psKernelC0IndexedPairCacheReplace route state
        (psKernelExprPairSetInsert
          (psKernelC0IndexedPairCacheSelect route state)
          left.expr right.expr) := by
  unfold psKernelC0VerifiedIndexedStatePairInsert
  rw [psKernelC0VerifiedIndexedPairInsert_source]
