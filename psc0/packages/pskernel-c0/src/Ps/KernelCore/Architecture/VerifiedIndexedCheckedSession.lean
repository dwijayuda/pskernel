import Ps.KernelCore.Architecture.VerifiedIndexedCheckedReceipt
import Ps.KernelCore.Checker.IndexedSession

/-!
A live-session CHECKED operation using actual full source-checked receipts,
not the non-admitting raw indexed cache-write model.

An immutable certified owner must equal the session's current syntax store.
An exact fuel/context/initial-state-indexed table can return only receipts
whose complete type and checker final state were already checked by the
authoritative C0 source checker. Cache misses delegate unchanged source
checking. No independent DefEq or synthetic typed cache insert is admitted.

A later session operation that changes checker state must use a new table
indexed by the new initial state; this API supplies NO unchecked state
transport or cross-environment result reuse.
-/

/-- Production-shape opt-in indexed session CHECK with exact source typing.
The source-equivalent memo operation cannot inject raw source cache entries:
its final session state is precisely the genuine checked result state. -/
def psKernelC0IndexedSessionCheckWithVerifiedReceipt
    (fuel : Nat)
    (session : PsKernelC0IndexedCheckerSession)
    (owner : PsKernelC0CertifiedStore)
    (_sameOwner : owner.store = session.store)
    {id : Nat}
    (hash : PsKernelC0VerifiedIndexedHash owner id)
    (table : PsKernelC0IndexedCheckedReceiptTable
      owner fuel session.checker.context session.checker.state) :
    Except String (PsKernelExpr × PsKernelC0IndexedCheckerSession) :=
  match psKernelC0IndexedCheckedReceiptTableOutcome owner fuel
      session.checker.context session.checker.state table hash with
  | .error reason => .error reason
  | .ok (ty, nextState) =>
      .ok (ty, { session with
        checker := { session.checker with state := nextState } })

/-- Complete public indexed checked-session refinement, for either a
checked memo HIT or a source fallback MISS. The exact type, entire final
checker/session state, syntax owner, resource/error outcomes and every
non-target indexed-session field match the ORIGINAL trusted checker entry. -/
theorem psKernelC0IndexedSessionCheckWithVerifiedReceipt_source
    (fuel : Nat)
    (session : PsKernelC0IndexedCheckerSession)
    (owner : PsKernelC0CertifiedStore)
    (sameOwner : owner.store = session.store)
    {id : Nat}
    (hash : PsKernelC0VerifiedIndexedHash owner id)
    (table : PsKernelC0IndexedCheckedReceiptTable
      owner fuel session.checker.context session.checker.state) :
    psKernelC0IndexedSessionCheckWithVerifiedReceipt
        fuel session owner sameOwner hash table =
      psKernelC0IndexedSessionCheck fuel session hash.expr := by
  unfold psKernelC0IndexedSessionCheckWithVerifiedReceipt
  rw [psKernelC0IndexedCheckedReceiptTableOutcome_source hash table]
  unfold psKernelC0IndexedSessionCheck psKernelSessionCheck
  cases hCheck :
      psKernelCheckerCheck fuel session.checker.context
        session.checker.state hash.expr with
  | error reason => rfl
  | ok result =>
      rcases result with ⟨ty, nextState⟩
      rfl
