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
