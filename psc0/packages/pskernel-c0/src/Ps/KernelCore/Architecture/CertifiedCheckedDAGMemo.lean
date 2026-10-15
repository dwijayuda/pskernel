import Ps.KernelCore.Core.CertifiedStore
import Ps.KernelCore.Checker.Knot

/-!
A proof-carrying boundary for future DAG-indexed checked inference.

An indexed root alone is *not* proof of type correctness. Even an internally
consistent node store is only syntax. Only the authoritative source C0
checker can construct a checked root receipt, and every receipt retains the
exact immutable store, original expression, local context, original checker
state, and fuel in its type.

This module deliberately does not memoize across changing contexts or states.
Any later acceleration must prove a valid state-extension/transport theorem
before it can reuse a receipt in a different checker state. No raw Nat ID,
hash, pointer, or unchecked infer-only result grants checked admission.
-/

/-- A proof-relevant source-checker result tied to one certified indexed
expression, precise context, initial state and source fuel. -/
structure PsKernelC0CertifiedCheckedDAGRoot
    (fuel : Nat)
    (context : PsKernelCheckerContext)
    (initialState : PsKernelCheckerState) where
  root : PsKernelC0CertifiedRoot
  inferredType : PsKernelExpr
  finalState : PsKernelCheckerState
  checked :
    psKernelCheckerCheck fuel context initialState root.expression =
      Except.ok (inferredType, finalState)

/-- Construct a receipt ONLY after the complete, authoritative checked
inference returns success. The typed evidence is not created from a syntax
hash, a source node ID, or infer-only typing. -/
def psKernelC0CaptureCheckedDAGRoot
    (fuel : Nat)
    (context : PsKernelCheckerContext)
    (initialState : PsKernelCheckerState)
    (root : PsKernelC0CertifiedRoot) :
    Except String
      (PsKernelC0CertifiedCheckedDAGRoot fuel context initialState) :=
  match h : psKernelCheckerCheck fuel context initialState root.expression with
  | Except.error reason => Except.error reason
  | Except.ok (inferredType, finalState) =>
      Except.ok {
        root := root
        inferredType := inferredType
        finalState := finalState
        checked := h
      }

/-- No cache result may be extracted as checked unless the full source
judgment succeeded for that *same* fuel, context and initial state. -/
theorem psKernelC0CertifiedCheckedDAGRoot_source
    {fuel : Nat}
    {context : PsKernelCheckerContext}
    {initialState : PsKernelCheckerState}
    (cert : PsKernelC0CertifiedCheckedDAGRoot fuel context initialState) :
    psKernelCheckerCheck fuel context initialState cert.root.expression =
      Except.ok (cert.inferredType, cert.finalState) :=
  cert.checked

/-- The snapshot was independently replay-validated and has proved
topological, metadata, and canonical-index invariants. -/
theorem psKernelC0CertifiedCheckedDAGRoot_storeWF
    {fuel : Nat}
    {context : PsKernelCheckerContext}
    {initialState : PsKernelCheckerState}
    (cert : PsKernelC0CertifiedCheckedDAGRoot fuel context initialState) :
    psKernelC0StoreWF cert.root.owner.store :=
  cert.root.owner.wellFormed

/-- The checked term is precisely the syntax decoded from this same
certified owner's root. The certificate cannot silently transfer an ID
from another immutable store. -/
theorem psKernelC0CertifiedCheckedDAGRoot_exactRead
    {fuel : Nat}
    {context : PsKernelCheckerContext}
    {initialState : PsKernelCheckerState}
    (cert : PsKernelC0CertifiedCheckedDAGRoot fuel context initialState) :
    psKernelC0DecodeExpr cert.root.owner.store cert.root.root =
      some cert.root.expression :=
  cert.root.readback

/-!
A scoped checked-result memo, with an explicit store ownership and source
equation at each entry. These are immutable results of genuine checked
inference, not guessed types or unchecked AST annotations.

The input owner, source fuel, checker context and initial state appear in
the ENTRY TYPE. A caller changing any of them cannot pass the old memo to
this interface without proving the necessary exact contextual equalities.
In particular, this is not yet an incremental-state DAG checker: checked
state transport needs its own future refinement proof.
-/

/-- A checked source judgment for a specific node of one immutable,
canonical, fully certified indexed syntax store. -/
structure PsKernelC0ScopedCheckedDAGReceipt
    (owner : PsKernelC0CertifiedStore)
    (fuel : Nat)
    (context : PsKernelCheckerContext)
    (initialState : PsKernelCheckerState) where
  rootId : Nat
  inBounds : psKernelC0StoreValid owner.store rootId = true
  expression : PsKernelExpr
  readback : psKernelC0DecodeExpr owner.store rootId = some expression
  inferredType : PsKernelExpr
  finalState : PsKernelCheckerState
  source :
    psKernelCheckerCheck fuel context initialState expression =
      Except.ok (inferredType, finalState)

/-- Return checked information only after evaluating the authoritative
source judgment. The returned root-ID equality is a real Lean proof,
not a fingerprint comparison or a claim made by a caller. -/
def psKernelC0ScopedCheckedDAGCapture
    (owner : PsKernelC0CertifiedStore)
    (fuel : Nat)
    (context : PsKernelCheckerContext)
    (initialState : PsKernelCheckerState)
    (id : Nat) :
    Except String
      { receipt : PsKernelC0ScopedCheckedDAGReceipt
            owner fuel context initialState // receipt.rootId = id } :=
  if hv : psKernelC0StoreValid owner.store id = true then
    match hr : psKernelC0DecodeExpr owner.store id with
    | none =>
        .error "certified DAG root could not be read from its owning store"
    | some expression =>
        match hc : psKernelCheckerCheck fuel context initialState expression with
        | .error reason => .error reason
        | .ok (ty, nextState) =>
            .ok ⟨{
              rootId := id
              inBounds := hv
              expression := expression
              readback := hr
              inferredType := ty
              finalState := nextState
              source := hc
            }, rfl⟩
  else
    .error "certified DAG root is not in bounds"

/-- No memo lookup can forget which immutable owner, fuel, checker context,
and source-initial state qualified a prior result. -/
abbrev PsKernelC0ScopedCheckedDAGMemo
    (owner : PsKernelC0CertifiedStore)
    (fuel : Nat)
    (context : PsKernelCheckerContext)
    (initialState : PsKernelCheckerState) :=
  List (PsKernelC0ScopedCheckedDAGReceipt owner fuel context initialState)

/-- Check precise root IDs (not hash or runtime pointer identity). The
dependent result proves the returned receipt is for the requested ID. -/
def psKernelC0ScopedCheckedDAGLookup
    {owner : PsKernelC0CertifiedStore}
    {fuel : Nat}
    {context : PsKernelCheckerContext}
    {initialState : PsKernelCheckerState}
    (id : Nat) :
    PsKernelC0ScopedCheckedDAGMemo owner fuel context initialState →
      Option
        { receipt : PsKernelC0ScopedCheckedDAGReceipt
              owner fuel context initialState // receipt.rootId = id }
  | [] => none
  | entry :: rest =>
      if h : entry.rootId = id then
        some ⟨entry, h⟩
      else
        psKernelC0ScopedCheckedDAGLookup id rest

/-- A memo miss performs the complete checked source judgment; a hit
returns the prior exact source proof under the SAME typed parameters.
No status, type, state or assumption from a distinct checking session is
introduced, and no memo entry can be built from an unverified raw node. -/
def psKernelC0ScopedCheckedDAGCheck
    (owner : PsKernelC0CertifiedStore)
    (fuel : Nat)
    (context : PsKernelCheckerContext)
    (initialState : PsKernelCheckerState)
    (memo : PsKernelC0ScopedCheckedDAGMemo
      owner fuel context initialState)
    (id : Nat) :
    Except String
      ({ receipt : PsKernelC0ScopedCheckedDAGReceipt
          owner fuel context initialState // receipt.rootId = id } ×
        PsKernelC0ScopedCheckedDAGMemo
          owner fuel context initialState) :=
  match psKernelC0ScopedCheckedDAGLookup id memo with
  | some checked => .ok (checked, memo)
  | none =>
      match psKernelC0ScopedCheckedDAGCapture
          owner fuel context initialState id with
      | .error reason => .error reason
      | .ok checked => .ok (checked, checked.val :: memo)

/-- Cached and newly checked receipts both prove the exact source checked
judgment; the memo has no alternative admission rule. -/
theorem psKernelC0ScopedCheckedDAGReceipt_source
    {owner : PsKernelC0CertifiedStore}
    {fuel : Nat}
    {context : PsKernelCheckerContext}
    {initialState : PsKernelCheckerState}
    (receipt : PsKernelC0ScopedCheckedDAGReceipt
      owner fuel context initialState) :
    psKernelCheckerCheck fuel context initialState receipt.expression =
      .ok (receipt.inferredType, receipt.finalState) :=
  receipt.source

/-- A checked indexed result carries the exact successful readback of its
root in the immutable, replay-validated owner store. -/
theorem psKernelC0ScopedCheckedDAGReceipt_readback
    {owner : PsKernelC0CertifiedStore}
    {fuel : Nat}
    {context : PsKernelCheckerContext}
    {initialState : PsKernelCheckerState}
    (receipt : PsKernelC0ScopedCheckedDAGReceipt
      owner fuel context initialState) :
    psKernelC0DecodeExpr owner.store receipt.rootId =
      some receipt.expression :=
  receipt.readback

/-- Under the same certified owner, fuel, context and initial state, equal
node IDs MUST yield the same expression, checked type and final checker
state. This prevents conflicting cache entries from silently changing an
already source-checked result, even if a caller supplies multiple entries.
The proof does not rely on hashes, pointer equality or cache policies. -/
theorem psKernelC0ScopedCheckedDAGSameRoot
    {owner : PsKernelC0CertifiedStore}
    {fuel : Nat}
    {context : PsKernelCheckerContext}
    {initialState : PsKernelCheckerState}
    (left right : PsKernelC0ScopedCheckedDAGReceipt
      owner fuel context initialState)
    (hId : left.rootId = right.rootId) :
    left.expression = right.expression ∧
      left.inferredType = right.inferredType ∧
        left.finalState = right.finalState := by
  have hRead : some left.expression = some right.expression := by
    calc
      some left.expression =
          psKernelC0DecodeExpr owner.store left.rootId :=
        left.readback.symm
      _ = psKernelC0DecodeExpr owner.store right.rootId := by rw [hId]
      _ = some right.expression := right.readback
  have hExpr : left.expression = right.expression := by
    injection hRead with he
    exact he
  have hCheck :
      Except.ok (left.inferredType, left.finalState) =
        Except.ok (right.inferredType, right.finalState) := by
    calc
      Except.ok (left.inferredType, left.finalState) =
          psKernelCheckerCheck fuel context initialState left.expression :=
        left.source.symm
      _ = psKernelCheckerCheck fuel context initialState right.expression := by
        rw [hExpr]
      _ = Except.ok (right.inferredType, right.finalState) :=
        right.source
  have hPair :
      (left.inferredType, left.finalState) =
        (right.inferredType, right.finalState) := by
    injection hCheck with hp
    exact hp
  exact ⟨hExpr, congrArg Prod.fst hPair, congrArg Prod.snd hPair⟩
