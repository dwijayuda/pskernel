import Ps.KernelCore.Architecture.VerifiedIndexedCacheState
import Ps.KernelCore.Checker.IndexedSession

/-!
An executable operation-local verified cache-state machine. Commands contain
only certified, canonical handles from ONE immutable owned store. All of the
original C0 inference, WHNF, unfold and DefEq success/failure caches are
updated with proof-equivalent source state transitions. No cache command can
authorize a type, DefEq decision or admission.

This integrates source-proved indexed hash buckets into an actual checker
STATE, not just separate map/set calculations. Each command is fully
source-equivalent; the complete ordered batch carries its final-state proof.
It is an opt-in, non-admitting cache API. Production source checker operation
routing still requires a separate complete checked-inference theorem.
-/

/-- Cache write commands carry the EXACT same-store certified expression
and pair syntax needed by their original source operations. -/
inductive PsKernelC0VerifiedIndexedCacheCommand
    (owner : PsKernelC0CertifiedStore) where
  | exprInsert {id : Nat}
      (route : PsKernelC0IndexedExprCacheRoute)
      (source : PsKernelC0VerifiedIndexedHash owner id)
      (result : PsKernelExpr)
  | pairInsert {leftId rightId : Nat}
      (route : PsKernelC0IndexedPairCacheRoute)
      (left : PsKernelC0VerifiedIndexedHash owner leftId)
      (right : PsKernelC0VerifiedIndexedHash owner rightId)

/-- Fast operation-level source-state write using certified indexed hash
hints; every syntax equality/collision check stays with the original map. -/
def psKernelC0VerifiedIndexedCacheCommandApply
    {owner : PsKernelC0CertifiedStore}
    (state : PsKernelCheckerState) :
    PsKernelC0VerifiedIndexedCacheCommand owner →
      PsKernelCheckerState
  | .exprInsert route source result =>
      psKernelC0VerifiedIndexedStateCacheInsert route state source result
  | .pairInsert route left right =>
      psKernelC0VerifiedIndexedStatePairInsert route state left right

/-- Independent source C0 state transition for the very same cache command,
without any precomputed indexed hash. -/
def psKernelC0VerifiedIndexedCacheCommandSource
    {owner : PsKernelC0CertifiedStore}
    (state : PsKernelCheckerState) :
    PsKernelC0VerifiedIndexedCacheCommand owner →
      PsKernelCheckerState
  | .exprInsert route source result =>
      psKernelC0IndexedExprCacheReplace route state
        (psKernelExprMapInsert
          (psKernelC0IndexedExprCacheSelect route state)
          source.expr result)
  | .pairInsert route left right =>
      psKernelC0IndexedPairCacheReplace route state
        (psKernelExprPairSetInsert
          (psKernelC0IndexedPairCacheSelect route state)
          left.expr right.expr)

/-- Complete one-step state equality, including all non-target caches,
nextFresh and every DefEq success/failure set. No resource/typing result
is inferred from this cache-only operation. -/
theorem psKernelC0VerifiedIndexedCacheCommandApply_source
    {owner : PsKernelC0CertifiedStore}
    (state : PsKernelCheckerState)
    (cmd : PsKernelC0VerifiedIndexedCacheCommand owner) :
    psKernelC0VerifiedIndexedCacheCommandApply state cmd =
      psKernelC0VerifiedIndexedCacheCommandSource state cmd := by
  cases cmd with
  | exprInsert route source result =>
      exact psKernelC0VerifiedIndexedStateCacheInsert_source
        route state source result
  | pairInsert route left right =>
      exact psKernelC0VerifiedIndexedStatePairInsert_source
        route state left right

/-- Source-preserving checker cache sequence, in original order. -/
def psKernelC0VerifiedIndexedCacheTraceRun
    {owner : PsKernelC0CertifiedStore} :
    List (PsKernelC0VerifiedIndexedCacheCommand owner) →
    PsKernelCheckerState → PsKernelCheckerState
  | [], state => state
  | cmd :: rest, state =>
      psKernelC0VerifiedIndexedCacheTraceRun rest
        (psKernelC0VerifiedIndexedCacheCommandApply state cmd)

def psKernelC0VerifiedIndexedCacheTraceSource
    {owner : PsKernelC0CertifiedStore} :
    List (PsKernelC0VerifiedIndexedCacheCommand owner) →
    PsKernelCheckerState → PsKernelCheckerState
  | [], state => state
  | cmd :: rest, state =>
      psKernelC0VerifiedIndexedCacheTraceSource rest
        (psKernelC0VerifiedIndexedCacheCommandSource state cmd)

/-- Compositional complete source-state refinement under arbitrary ordered
cache sequences. Intermediate and final states are not inferred from keys,
hashes or an unverified state extension; each exact source transition is
the left-to-right previous step's output. -/
theorem psKernelC0VerifiedIndexedCacheTraceRun_source
    {owner : PsKernelC0CertifiedStore}
    (commands : List (PsKernelC0VerifiedIndexedCacheCommand owner))
    (initialState : PsKernelCheckerState) :
    psKernelC0VerifiedIndexedCacheTraceRun commands initialState =
      psKernelC0VerifiedIndexedCacheTraceSource commands initialState := by
  induction commands generalizing initialState with
  | nil => rfl
  | cons cmd rest ih =>
      calc
        psKernelC0VerifiedIndexedCacheTraceRun (cmd :: rest) initialState =
            psKernelC0VerifiedIndexedCacheTraceRun rest
              (psKernelC0VerifiedIndexedCacheCommandApply initialState cmd) := rfl
        _ = psKernelC0VerifiedIndexedCacheTraceSource rest
              (psKernelC0VerifiedIndexedCacheCommandApply initialState cmd) :=
                ih _
        _ = psKernelC0VerifiedIndexedCacheTraceSource rest
              (psKernelC0VerifiedIndexedCacheCommandSource initialState cmd) := by
                rw [psKernelC0VerifiedIndexedCacheCommandApply_source]
        _ = psKernelC0VerifiedIndexedCacheTraceSource
              (cmd :: rest) initialState := rfl

/-- A public cache-only session bridge: a certified owner must be exactly
the input session's store. Commands update only the checker state; the
environment/local context, retained roots, radix index and provenance
remain in that same input session. -/
def psKernelC0VerifiedIndexedCacheTraceSession
    (session : PsKernelC0IndexedCheckerSession)
    (owner : PsKernelC0CertifiedStore)
    (_sameOwner : owner.store = session.store)
    (commands : List (PsKernelC0VerifiedIndexedCacheCommand owner)) :
    { updated : PsKernelC0IndexedCheckerSession //
        updated.store = session.store ∧
        updated.checker.context = session.checker.context ∧
        updated.checker.state =
          psKernelC0VerifiedIndexedCacheTraceSource
            commands session.checker.state } :=
  ⟨{ session with checker :=
       { session.checker with state :=
           psKernelC0VerifiedIndexedCacheTraceRun
             commands session.checker.state } },
    ⟨rfl, rfl,
      psKernelC0VerifiedIndexedCacheTraceRun_source
        commands session.checker.state⟩⟩
