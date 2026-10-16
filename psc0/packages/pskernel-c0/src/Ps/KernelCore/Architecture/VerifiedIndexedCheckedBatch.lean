import Ps.KernelCore.Architecture.VerifiedIndexedCheckedSession

/-!
Proof-carrying indexed checked-DAG batch execution over an immutable owner.

Each request supplies an exact owned syntax/hash certificate, not a type or
DefEq judgment. The actual checker operation chooses a full source-checked
receipt at the CURRENT state (or calls the original checker on a miss).
A callback supplies only tables whose type fixes that precise original
state/context/fuel/owner. No receipt can silently cross a state transition.

The complete source-result and error refinement is compositional: every
successful operation feeds its EXACT checker final state to the next one.
A failure atomically returns Except.error, without publishing intermediate
checked results or mutating a live session. Original source checking remains
the independent oracle and all admission rules remain untouched.
-/

/-- One exact node identity and independently proven original hash/readback
from the SAME canonical immutable store. No checked judgment is inferred
from the certified syntax or hash alone. -/
structure PsKernelC0IndexedCheckedBatchRequest
    (owner : PsKernelC0CertifiedStore) where
  id : Nat
  hash : PsKernelC0VerifiedIndexedHash owner id

/-- One shared state-threading implementation; clients supply either the
original source checker or a proven-equivalent receipt-backed operation.
A later step begins at precisely the previous returned checker state. -/
def psKernelC0IndexedCheckedBatchFold
    {owner : PsKernelC0CertifiedStore}
    (step : PsKernelCheckerState →
      PsKernelC0IndexedCheckedBatchRequest owner →
        Except String (PsKernelExpr × PsKernelCheckerState)) :
    List (PsKernelC0IndexedCheckedBatchRequest owner) →
      PsKernelCheckerState →
        Except String (List PsKernelExpr × PsKernelCheckerState)
  | [], state => .ok ([], state)
  | request :: rest, state =>
      match step state request with
      | .error reason => .error reason
      | .ok (ty, nextState) =>
          match psKernelC0IndexedCheckedBatchFold step rest nextState with
          | .error reason => .error reason
          | .ok (types, finalState) => .ok (ty :: types, finalState)

/-- General compositional congruence: equality of one complete checked
operation (including errors/fuel outcomes) implies equality of an entire
ordered, state-threaded batch, without any state-transport assumptions. -/
theorem psKernelC0IndexedCheckedBatchFold_congr
    {owner : PsKernelC0CertifiedStore}
    (left right : PsKernelCheckerState →
      PsKernelC0IndexedCheckedBatchRequest owner →
        Except String (PsKernelExpr × PsKernelCheckerState))
    (same : ∀ state request, left state request = right state request)
    (requests : List (PsKernelC0IndexedCheckedBatchRequest owner))
    (initialState : PsKernelCheckerState) :
    psKernelC0IndexedCheckedBatchFold left requests initialState =
      psKernelC0IndexedCheckedBatchFold right requests initialState := by
  induction requests generalizing initialState with
  | nil => rfl
  | cons request rest ih =>
      simp only [psKernelC0IndexedCheckedBatchFold]
      rw [same initialState request]
      cases h : right initialState request with
      | error reason => rfl
      | ok result =>
          rcases result with ⟨ty, nextState⟩
          simpa using congrArg
            (fun outcome : Except String
                (List PsKernelExpr × PsKernelCheckerState) =>
              match outcome with
              | .error reason => .error reason
              | .ok (types, finalState) => .ok (ty :: types, finalState))
            (ih nextState)

/-- Independent original-C0 reference: every root goes through the
original full checker, with the exact source-returned state threaded onward.
No receipt or indexed hash decides source checking. -/
def psKernelC0IndexedCheckedBatchSource
    (owner : PsKernelC0CertifiedStore)
    (fuel : Nat)
    (context : PsKernelCheckerContext)
    (requests : List (PsKernelC0IndexedCheckedBatchRequest owner))
    (initialState : PsKernelCheckerState) :
    Except String (List PsKernelExpr × PsKernelCheckerState) :=
  psKernelC0IndexedCheckedBatchFold
    (fun state request =>
      psKernelCheckerCheck fuel context state request.hash.expr)
    requests initialState

/-- Executable indexed checked batch. Different successive original states
have DIFFERENT dependent receipt tables; the caller may not transport a
memo across a changed state or environment without an independent proof.
Receipts store the complete checked type and returned state. -/
def psKernelC0IndexedCheckedBatchVerified
    (owner : PsKernelC0CertifiedStore)
    (fuel : Nat)
    (context : PsKernelCheckerContext)
    (tables : (state : PsKernelCheckerState) →
      PsKernelC0IndexedCheckedReceiptTable owner fuel context state)
    (requests : List (PsKernelC0IndexedCheckedBatchRequest owner))
    (initialState : PsKernelCheckerState) :
    Except String (List PsKernelExpr × PsKernelCheckerState) :=
  psKernelC0IndexedCheckedBatchFold
    (fun state request =>
      psKernelC0IndexedCheckedReceiptTableOutcome owner fuel
        context state (tables state) request.hash)
    requests initialState

/-- COMPLETE positive and negative source refinement of an arbitrarily
long mixed memo-hit/source-fallback sequence. Types, full final state,
original error reasons, and source fuel policy agree for every request.
A transient syntax hash can never independently authorize an acceptance. -/
theorem psKernelC0IndexedCheckedBatchVerified_source
    (owner : PsKernelC0CertifiedStore)
    (fuel : Nat)
    (context : PsKernelCheckerContext)
    (tables : (state : PsKernelCheckerState) →
      PsKernelC0IndexedCheckedReceiptTable owner fuel context state)
    (requests : List (PsKernelC0IndexedCheckedBatchRequest owner))
    (initialState : PsKernelCheckerState) :
    psKernelC0IndexedCheckedBatchVerified owner fuel context
        tables requests initialState =
      psKernelC0IndexedCheckedBatchSource owner fuel context
        requests initialState := by
  unfold psKernelC0IndexedCheckedBatchVerified
    psKernelC0IndexedCheckedBatchSource
  apply psKernelC0IndexedCheckedBatchFold_congr
  intro state request
  exact psKernelC0IndexedCheckedReceiptTableOutcome_source
    request.hash (tables state)

/-- Atomically execute a source-refined verified node batch at a live indexed
checker session. Its syntax store and all nonchecker fields stay unchanged,
and its only advanced state is the source-checked final state of the batch. -/
def psKernelC0IndexedSessionCheckVerifiedBatch
    (fuel : Nat)
    (session : PsKernelC0IndexedCheckerSession)
    (owner : PsKernelC0CertifiedStore)
    (_sameOwner : owner.store = session.store)
    (requests : List (PsKernelC0IndexedCheckedBatchRequest owner))
    (tables : (state : PsKernelCheckerState) →
      PsKernelC0IndexedCheckedReceiptTable
        owner fuel session.checker.context state) :
    Except String (List PsKernelExpr × PsKernelC0IndexedCheckerSession) :=
  match psKernelC0IndexedCheckedBatchVerified owner fuel
      session.checker.context tables requests session.checker.state with
  | .error reason => .error reason
  | .ok (types, finalState) =>
      .ok (types, {session with
        checker := {session.checker with state := finalState}})

/-- Independent reference batch at the exact session context/initial state.
It uses the original C0 full checker for every node and changes no syntax
owner/index/session metadata. -/
def psKernelC0IndexedSessionCheckSourceBatch
    (fuel : Nat)
    (session : PsKernelC0IndexedCheckerSession)
    (owner : PsKernelC0CertifiedStore)
    (requests : List (PsKernelC0IndexedCheckedBatchRequest owner)) :
    Except String (List PsKernelExpr × PsKernelC0IndexedCheckerSession) :=
  match psKernelC0IndexedCheckedBatchSource owner fuel
      session.checker.context requests session.checker.state with
  | .error reason => .error reason
  | .ok (types, finalState) =>
      .ok (types, {session with
        checker := {session.checker with state := finalState}})

/-- Whole live-session source refinement, not merely a hash-table/update
equation: the entire Except outcome and final session are unchanged.
A failure cannot publish a partially advanced source checker state. -/
theorem psKernelC0IndexedSessionCheckVerifiedBatch_source
    (fuel : Nat)
    (session : PsKernelC0IndexedCheckerSession)
    (owner : PsKernelC0CertifiedStore)
    (sameOwner : owner.store = session.store)
    (requests : List (PsKernelC0IndexedCheckedBatchRequest owner))
    (tables : (state : PsKernelCheckerState) →
      PsKernelC0IndexedCheckedReceiptTable
        owner fuel session.checker.context state) :
    psKernelC0IndexedSessionCheckVerifiedBatch
        fuel session owner sameOwner requests tables =
      psKernelC0IndexedSessionCheckSourceBatch
        fuel session owner requests := by
  unfold psKernelC0IndexedSessionCheckVerifiedBatch
    psKernelC0IndexedSessionCheckSourceBatch
  rw [psKernelC0IndexedCheckedBatchVerified_source]
