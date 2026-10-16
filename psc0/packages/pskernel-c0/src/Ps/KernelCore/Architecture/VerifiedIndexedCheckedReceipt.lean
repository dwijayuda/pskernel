import Ps.KernelCore.Architecture.CertifiedCheckedDAGMemo
import Ps.KernelCore.Architecture.VerifiedIndexedHash

/-!
A source-checked, fixed-scope indexed memo for canonical expression nodes.

Unlike the non-admitting cache-command model, entries carry original C0
checked inference and the EXACT resulting checker state at the specified
immutable owner, fuel, context and initial state. Hashes prove exact syntax,
not typing. Array slots are only O(1) lookup hints: every hit must also
prove the exact owner-local ID. Malformed tables cannot return a receipt
for another root.

This is an opt-in checked-operation primitive. It does not mutate the
trusted source checker's caches, transport judgments across changing
initial states/environments, or authorize declaration admission.
-/

/-- Stored values can only be genuine, full source-checked receipts. All
scope dimensions appear in the type, not just in an untrusted hash key. -/
structure PsKernelC0IndexedCheckedReceiptTable
    (owner : PsKernelC0CertifiedStore)
    (fuel : Nat)
    (context : PsKernelCheckerContext)
    (initialState : PsKernelCheckerState) where
  entries : Array (Option
    (PsKernelC0ScopedCheckedDAGReceipt owner fuel context initialState))

/-- Allocate exactly one slot per node in the certified immutable owner. -/
def psKernelC0IndexedCheckedReceiptTableEmpty
    (owner : PsKernelC0CertifiedStore)
    (fuel : Nat)
    (context : PsKernelCheckerContext)
    (initialState : PsKernelCheckerState) :
    PsKernelC0IndexedCheckedReceiptTable
      owner fuel context initialState :=
  { entries := Array.replicate owner.store.nodes.size
      (none : Option (PsKernelC0ScopedCheckedDAGReceipt
        owner fuel context initialState)) }

/-- An array hit never bypasses a checked receipt's exact root-ID test.
Even a mispositioned value in a caller-built table is rejected. -/
def psKernelC0IndexedCheckedReceiptTableLookup
    {owner : PsKernelC0CertifiedStore}
    {fuel : Nat}
    {context : PsKernelCheckerContext}
    {initialState : PsKernelCheckerState}
    (table : PsKernelC0IndexedCheckedReceiptTable
      owner fuel context initialState)
    (id : Nat) :
    Option
      { receipt : PsKernelC0ScopedCheckedDAGReceipt
          owner fuel context initialState // receipt.rootId = id } :=
  match table.entries[id]? with
  | some (some checked) =>
      if h : checked.rootId = id then some ⟨checked, h⟩ else none
  | _ => none

/-- A missed root is checked by the ORIGINAL C0 checker. The source hash
saves an additional expanded-tree readback, but cannot supply its type.
Errors, exhausted fuel and invalid terms remain ordinary source errors. -/
def psKernelC0CaptureCheckedIndexedHash
    (owner : PsKernelC0CertifiedStore)
    (fuel : Nat)
    (context : PsKernelCheckerContext)
    (initialState : PsKernelCheckerState)
    {id : Nat}
    (hash : PsKernelC0VerifiedIndexedHash owner id) :
    Except String
      { receipt : PsKernelC0ScopedCheckedDAGReceipt
          owner fuel context initialState // receipt.rootId = id } :=
  if hv : psKernelC0StoreValid owner.store id = true then
    match hc : psKernelCheckerCheck fuel context initialState hash.expr with
    | .error reason => .error reason
    | .ok (ty, finalState) =>
        .ok ⟨{
          rootId := id
          inBounds := hv
          expression := hash.expr
          readback := hash.readback
          inferredType := ty
          finalState := finalState
          source := hc
        }, rfl⟩
  else
    .error "certified indexed checked receipt root is not in bounds"

/-- Reuse only a checked receipt at the SAME owner/fuel/context/initial
state. A miss does the full source check, then retains its precise result.
A short externally constructed table skips retention rather than fabricating
a result. Source checker state is never changed by table writes. -/
def psKernelC0IndexedCheckedReceiptTableCheck
    (owner : PsKernelC0CertifiedStore)
    (fuel : Nat)
    (context : PsKernelCheckerContext)
    (initialState : PsKernelCheckerState)
    (table : PsKernelC0IndexedCheckedReceiptTable
      owner fuel context initialState)
    {id : Nat}
    (hash : PsKernelC0VerifiedIndexedHash owner id) :
    Except String
      ({ receipt : PsKernelC0ScopedCheckedDAGReceipt
          owner fuel context initialState // receipt.rootId = id } ×
       PsKernelC0IndexedCheckedReceiptTable
          owner fuel context initialState) :=
  match psKernelC0IndexedCheckedReceiptTableLookup table id with
  | some checked => .ok (checked, table)
  | none =>
      match psKernelC0CaptureCheckedIndexedHash
          owner fuel context initialState hash with
      | .error reason => .error reason
      | .ok checked =>
          let updated :=
            if h : id < table.entries.size then
              { table with
                entries := table.entries.set id (some checked.val) h }
            else table
          .ok (checked, updated)

/-- Complete source CHECKER judgment (type AND final state) for any checked
entry at this exact hash node. The store's two proof-carrying readbacks
establish expression identity without trusting the hash value. -/
theorem psKernelC0IndexedCheckedReceiptHash_source
    {owner : PsKernelC0CertifiedStore}
    {fuel : Nat}
    {context : PsKernelCheckerContext}
    {initialState : PsKernelCheckerState}
    {id : Nat}
    (hash : PsKernelC0VerifiedIndexedHash owner id)
    (checked :
      { receipt : PsKernelC0ScopedCheckedDAGReceipt
          owner fuel context initialState // receipt.rootId = id }) :
    psKernelCheckerCheck fuel context initialState hash.expr =
      .ok (checked.val.inferredType, checked.val.finalState) := by
  have hRead :
      psKernelC0DecodeExpr owner.store id =
        some checked.val.expression := by
    calc
      psKernelC0DecodeExpr owner.store id =
          psKernelC0DecodeExpr owner.store checked.val.rootId := by
            rw [checked.property]
      _ = some checked.val.expression := checked.val.readback
  have hExpr : hash.expr = checked.val.expression := by
    have hSome : some hash.expr = some checked.val.expression := by
      calc
        some hash.expr = psKernelC0DecodeExpr owner.store id :=
          hash.readback.symm
        _ = some checked.val.expression := hRead
    exact Option.some.inj hSome
  rw [hExpr]
  exact checked.val.source

/-- A successful executable table check preserves the COMPLETE original
source checked result. Retention cannot alter source type, full checker
state, fuel/resource behavior or error/unsupported decisions. -/
theorem psKernelC0IndexedCheckedReceiptTableCheck_source
    {owner : PsKernelC0CertifiedStore}
    {fuel : Nat}
    {context : PsKernelCheckerContext}
    {initialState : PsKernelCheckerState}
    {id : Nat}
    (hash : PsKernelC0VerifiedIndexedHash owner id)
    (table nextTable : PsKernelC0IndexedCheckedReceiptTable
      owner fuel context initialState)
    (checked :
      { receipt : PsKernelC0ScopedCheckedDAGReceipt
          owner fuel context initialState // receipt.rootId = id })
    (_run : psKernelC0IndexedCheckedReceiptTableCheck
        owner fuel context initialState table hash =
        .ok (checked, nextTable)) :
    psKernelCheckerCheck fuel context initialState hash.expr =
      .ok (checked.val.inferredType, checked.val.finalState) :=
  psKernelC0IndexedCheckedReceiptHash_source hash checked


/-- A failed indexed memo check is the ORIGINAL source checker error under
the exact certified root-validity premise. A hash hit can only return a
successful source-checked receipt; a miss delegates failure classification
to the unchanged source checker. This includes exhausted fuel and malformed
expressions, without replacing the reason with a synthetic cache status. -/
theorem psKernelC0IndexedCheckedReceiptTableCheck_error_source
    {owner : PsKernelC0CertifiedStore}
    {fuel : Nat}
    {context : PsKernelCheckerContext}
    {initialState : PsKernelCheckerState}
    {id : Nat}
    (hash : PsKernelC0VerifiedIndexedHash owner id)
    (table : PsKernelC0IndexedCheckedReceiptTable
      owner fuel context initialState)
    (reason : String)
    (valid : psKernelC0StoreValid owner.store id = true)
    (hError : psKernelC0IndexedCheckedReceiptTableCheck
        owner fuel context initialState table hash = .error reason) :
    psKernelCheckerCheck fuel context initialState hash.expr =
      .error reason := by
  cases hLookup :
      psKernelC0IndexedCheckedReceiptTableLookup table id with
  | some checked =>
      simp [psKernelC0IndexedCheckedReceiptTableCheck, hLookup] at hError
  | none =>
      unfold psKernelC0IndexedCheckedReceiptTableCheck at hError
      simp only [hLookup] at hError
      unfold psKernelC0CaptureCheckedIndexedHash at hError
      simp only [valid, if_true] at hError
      split at hError <;> simp_all

/-- Erase only the indexing implementation detail; retain the checker
result and its EXACT final state, or its original error. This is the
executable source-compatible operation callers can compose safely. -/
def psKernelC0IndexedCheckedReceiptTableOutcome
    (owner : PsKernelC0CertifiedStore)
    (fuel : Nat)
    (context : PsKernelCheckerContext)
    (initialState : PsKernelCheckerState)
    (table : PsKernelC0IndexedCheckedReceiptTable
      owner fuel context initialState)
    {id : Nat}
    (hash : PsKernelC0VerifiedIndexedHash owner id) :
    Except String (PsKernelExpr × PsKernelCheckerState) :=
  match psKernelC0IndexedCheckedReceiptTableCheck
      owner fuel context initialState table hash with
  | .error reason => .error reason
  | .ok (checked, _) =>
      .ok (checked.val.inferredType, checked.val.finalState)

/-- COMPLETE source refinement for the opt-in checked operation: positive
types, exact final states, all negative errors and checked resource outcomes
are identical to the original kernel call, not merely to an insertion
operation. A certified hash/ID is never a typing or DefEq oracle. -/
theorem psKernelC0IndexedCheckedReceiptTableOutcome_source
    {owner : PsKernelC0CertifiedStore}
    {fuel : Nat}
    {context : PsKernelCheckerContext}
    {initialState : PsKernelCheckerState}
    {id : Nat}
    (hash : PsKernelC0VerifiedIndexedHash owner id)
    (table : PsKernelC0IndexedCheckedReceiptTable
      owner fuel context initialState)
    (valid : psKernelC0StoreValid owner.store id = true) :
    psKernelC0IndexedCheckedReceiptTableOutcome
        owner fuel context initialState table hash =
      psKernelCheckerCheck fuel context initialState hash.expr := by
  cases hResult : psKernelC0IndexedCheckedReceiptTableCheck
      owner fuel context initialState table hash with
  | error reason =>
      have hSource :=
        psKernelC0IndexedCheckedReceiptTableCheck_error_source
          hash table reason valid hResult
      simp [psKernelC0IndexedCheckedReceiptTableOutcome, hResult, hSource]
  | ok result =>
      rcases result with ⟨checked, nextTable⟩
      have hSource :=
        psKernelC0IndexedCheckedReceiptTableCheck_source
          hash table nextTable checked hResult
      simp [psKernelC0IndexedCheckedReceiptTableOutcome, hResult, hSource]
