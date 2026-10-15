import Ps.KernelCore.Architecture.CertifiedCheckedDAGTrace
import Ps.KernelCore.Checker.IndexedSession

/-!
An opt-in checked execution entry for the existing source-owned indexed
session. Unlike the syntax-retention and WHNF preview methods, this method
returns a genuine complete checked-state trace. The untrusted indexed store
must first prove its exact ownership, canonical index, topological ordering
and metadata via psKernelC0CertifyStoreOwned.

No raw root ID, hash, decoded term or cached type is proof of admission.
Each requested node is checked using the authoritative native C0 source
checker at exactly the state produced by the previous checked node.
-/

structure PsKernelC0CertifiedIndexedSourceRun
    (fuel : Nat)
    (session : PsKernelC0IndexedCheckerSession) where
  owner : PsKernelC0CertifiedStore
  ownerExact : owner.store = session.store
  finalState : PsKernelCheckerState
  checkedTrace : PsKernelC0CheckedDAGTrace
    owner fuel session.checker.context session.checker.state finalState

/-- Atomically check the source-owned, immutable session's canonical
indexed store and then all requested checked roots. A failed certificate or
failed later source judgment publishes no trace or final state. -/
def psKernelC0IndexedSessionCheckCertifiedTrace
    (fuel : Nat)
    (session : PsKernelC0IndexedCheckerSession)
    (requested : List Nat) :
    Except String (PsKernelC0CertifiedIndexedSourceRun fuel session) := do
  let some owner ← pure (psKernelC0CertifyStoreOwned session.store)
    | .error "indexed checker session store is not canonically certified"
  let ⟨finalState, checkedTrace⟩ ← psKernelC0CheckIndexedDAGTrace
    owner.val fuel session.checker.context session.checker.state requested
  .ok {
    owner := owner.val
    ownerExact := owner.property
    finalState := finalState
    checkedTrace := checkedTrace
  }

/-- An indexed session run is a real successful sequence of fully checked
C0 source judgments in the exact original context and state. -/
theorem psKernelC0CertifiedIndexedSourceRun_source
    {fuel : Nat}
    {session : PsKernelC0IndexedCheckerSession}
    (receipt : PsKernelC0CertifiedIndexedSourceRun fuel session) :
    psKernelC0IndexedDAGReferenceFold receipt.owner
        fuel session.checker.context
        (psKernelC0CheckedDAGTraceIds receipt.checkedTrace)
        session.checker.state =
      .ok receipt.finalState :=
  psKernelC0CheckedDAGTrace_sourceFold receipt.checkedTrace

/-- The certified owner is the exact input session store, not a separately
validated store with coincidentally equal hashes or node counts. -/
theorem psKernelC0CertifiedIndexedSourceRun_owned
    {fuel : Nat}
    {session : PsKernelC0IndexedCheckerSession}
    (receipt : PsKernelC0CertifiedIndexedSourceRun fuel session) :
    receipt.owner.store = session.store :=
  receipt.ownerExact
