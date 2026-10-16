import Ps.KernelCore.Architecture.VerifiedIndexedCheckedBatch
import Ps.KernelCore.Architecture.QualifiedCheckedDAGInference

/-!
One compositional opt-in indexed checked path with THREE soundly separated
strategies, in this order:
  (1) a genuine full source-checked receipt for this EXACT state/context/fuel;
  (2) the existing Lean-proved independent recursive checked-inference subset;
  (3) unchanged authoritative C0 source checking.

The first strategy never reuses a receipt from a different checker state.
The independent strategy is accepted only after the existing all-context
source refinement theorem proves the ENTIRE returned type and final state.
Neither a source hash nor an indexed node ID supplies a typing rule.
Every declined candidate falls back to original checking, preserving its
complete error and resource semantics. No arbitrary raw checker cache
write or declaration admission occurs in this module.
-/

/-- Real checked subterm operation with source-certified cached reuse, a
qualified independent recursive fragment, and authoritative source fallback.
The original checker state is never synthesized from guessed cache contents. -/
def psKernelC0IndexedMemoQualifiedStep
    (owner : PsKernelC0CertifiedStore)
    (fuel : Nat)
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (table : PsKernelC0IndexedCheckedReceiptTable
      owner fuel context state)
    (request : PsKernelC0IndexedCheckedBatchRequest owner) :
    Except String (PsKernelExpr × PsKernelCheckerState) :=
  match psKernelC0IndexedCheckedReceiptTableLookup table request.id with
  | some checked =>
      .ok (checked.val.inferredType, checked.val.finalState)
  | none =>
      match psKernelC0QualifiedDAGCandidateEligible request.hash.expr with
      | false =>
          psKernelCheckerCheck fuel context state request.hash.expr
      | true =>
          match psKernelC0RecursiveCheckedWithFuel
              fuel context state request.hash.expr with
          | none =>
              psKernelCheckerCheck fuel context state request.hash.expr
          | some result => .ok result

/-- Full original C0 checked judgment, including ALL source error cases,
for any mixed memo-hit/independent/authoritative-fallback operation. Each
successful non-source result is backed by an existing Lean source theorem. -/
theorem psKernelC0IndexedMemoQualifiedStep_source
    (owner : PsKernelC0CertifiedStore)
    (fuel : Nat)
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (table : PsKernelC0IndexedCheckedReceiptTable
      owner fuel context state)
    (request : PsKernelC0IndexedCheckedBatchRequest owner) :
    psKernelC0IndexedMemoQualifiedStep
        owner fuel context state table request =
      psKernelCheckerCheck fuel context state request.hash.expr := by
  unfold psKernelC0IndexedMemoQualifiedStep
  cases hLookup :
      psKernelC0IndexedCheckedReceiptTableLookup table request.id with
  | some checked =>
      simpa [hLookup] using
        (psKernelC0IndexedCheckedReceiptHash_source
          request.hash checked).symm
  | none =>
      cases hEligible :
          psKernelC0QualifiedDAGCandidateEligible request.hash.expr with
      | false =>
          simp [hLookup, hEligible]
      | true =>
          cases hCandidate :
              psKernelC0RecursiveCheckedWithFuel
                fuel context state request.hash.expr with
          | none =>
              simp [hLookup, hEligible, hCandidate]
          | some result =>
              have hSource : psKernelCheckerCheck
                  fuel context state request.hash.expr = .ok result :=
                psKernelC0RecursiveChecked_checkerCheck fuel context
                  state request.hash.expr result hCandidate
              simp [hLookup, hEligible, hCandidate, hSource]

/-- State-threaded qualified DAG execution. The memo table for each step
has an EXACT type-level reference to that step's source-produced state;
independent recursive inference is allowed only within its proved fragment.
Any unsupported recursive expression runs the source checker unchanged. -/
def psKernelC0IndexedMemoQualifiedBatch
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
      psKernelC0IndexedMemoQualifiedStep owner fuel context state
        (tables state) request)
    requests initialState

/-- Exact, complete source sequence refinement for arbitrary mixes of
previously checked receipts, independently accepted recursive subterms,
and original source fallbacks. Errors preserve their source identity and
no incomplete sequence may publish a final checker state. -/
theorem psKernelC0IndexedMemoQualifiedBatch_source
    (owner : PsKernelC0CertifiedStore)
    (fuel : Nat)
    (context : PsKernelCheckerContext)
    (tables : (state : PsKernelCheckerState) →
      PsKernelC0IndexedCheckedReceiptTable owner fuel context state)
    (requests : List (PsKernelC0IndexedCheckedBatchRequest owner))
    (initialState : PsKernelCheckerState) :
    psKernelC0IndexedMemoQualifiedBatch owner fuel context
        tables requests initialState =
      psKernelC0IndexedCheckedBatchSource owner fuel context
        requests initialState := by
  unfold psKernelC0IndexedMemoQualifiedBatch
    psKernelC0IndexedCheckedBatchSource
  apply psKernelC0IndexedCheckedBatchFold_congr
  intro state request
  exact psKernelC0IndexedMemoQualifiedStep_source
    owner fuel context state (tables state) request

/-- Opt-in live indexed session: all checked subterm states and syntax-store
ownership are preserved, including mixed memo/independent/source execution.
Nothing is implicitly installed in the production accepting kernel. -/
def psKernelC0IndexedSessionCheckMemoQualifiedBatch
    (fuel : Nat)
    (session : PsKernelC0IndexedCheckerSession)
    (owner : PsKernelC0CertifiedStore)
    (_sameOwner : owner.store = session.store)
    (requests : List (PsKernelC0IndexedCheckedBatchRequest owner))
    (tables : (state : PsKernelCheckerState) →
      PsKernelC0IndexedCheckedReceiptTable
        owner fuel session.checker.context state) :
    Except String (List PsKernelExpr × PsKernelC0IndexedCheckerSession) :=
  match psKernelC0IndexedMemoQualifiedBatch owner fuel
      session.checker.context tables requests session.checker.state with
  | .error reason => .error reason
  | .ok (types, finalState) =>
      .ok (types, {session with
        checker := {session.checker with state := finalState}})

/-- Complete source refinement of the actual live indexed-session result
for every certified request sequence. Neither unsupported nor exhausted
cases can be promoted to successful checked work. -/
theorem psKernelC0IndexedSessionCheckMemoQualifiedBatch_source
    (fuel : Nat)
    (session : PsKernelC0IndexedCheckerSession)
    (owner : PsKernelC0CertifiedStore)
    (sameOwner : owner.store = session.store)
    (requests : List (PsKernelC0IndexedCheckedBatchRequest owner))
    (tables : (state : PsKernelCheckerState) →
      PsKernelC0IndexedCheckedReceiptTable
        owner fuel session.checker.context state) :
    psKernelC0IndexedSessionCheckMemoQualifiedBatch
        fuel session owner sameOwner requests tables =
      psKernelC0IndexedSessionCheckSourceBatch
        fuel session owner requests := by
  unfold psKernelC0IndexedSessionCheckMemoQualifiedBatch
    psKernelC0IndexedSessionCheckSourceBatch
  rw [psKernelC0IndexedMemoQualifiedBatch_source]
  rfl
