import Ps.KernelCore.Architecture.CertifiedCheckedIndexedSession
import Ps.KernelCore.Architecture.QualifiedRecursiveInference

/-!
Executable independent checked-subterm selection for canonical indexed DAG
roots. The bounded source-syntax work check prevents a candidate proof check
on a heavily shared DAG from recursively exploring exponentially many
expanded nodes. A declined candidate always runs the full source checker.

The eligible candidate uses the already LEAN-PROVED
psKernelC0RecursiveChecked_checkerCheck theorem, which certifies the
complete public source type AND final state at the original fuel/context.
This is a genuine accepting independent recursive fragment; it does not
make raw handles, source hashes, infer-only results or context-free caches
trusted. The original source checker is retained for all unqualified terms.
-/

/-- Inspect at most 2048 source-work units before selecting an independent
checking fragment. This is only a performance policy, never an acceptance
predicate or extra source resource limit: declines run full source checking. -/
def psKernelC0QualifiedDAGCandidateEligible
    (expr : PsKernelExpr) : Bool :=
  (psKernelC0ChargeExpr expr 2048).isSome

/-- Source-proved independent recursive checking of bounded canonical DAG
roots, with exact fallback. The certified owner and node ID are matched
before any candidate inference. The independent branch carries the actual
checker equation; it cannot create a false acceptance or a fabricated state. -/
def psKernelC0ScopedQualifiedDAGCapture
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
        if psKernelC0QualifiedDAGCandidateEligible expression then
          match hc : psKernelC0RecursiveCheckedWithFuel
              fuel context initialState expression with
          | none =>
              psKernelC0ScopedCheckedDAGCapture
                owner fuel context initialState id
          | some (ty, nextState) =>
              have source :
                  psKernelCheckerCheck fuel context initialState expression =
                    .ok (ty, nextState) :=
                psKernelC0RecursiveChecked_checkerCheck
                  fuel context initialState expression
                  (ty, nextState) hc
              .ok ⟨{
                rootId := id
                inBounds := hv
                expression := expression
                readback := hr
                inferredType := ty
                finalState := nextState
                source := source
              }, rfl⟩
        else
          psKernelC0ScopedCheckedDAGCapture
            owner fuel context initialState id
  else
    .error "certified DAG root is not in bounds"

/-- Execute independent checked fragments over exact DAG roots and
sequential source-returned states. After any decline or unsupported node,
the original checker remains mandatory and its error policy authoritative.
The existing dependent trace type forces each step to preserve exact checked
source-state semantics, including across mixed independent/fallback steps. -/
def psKernelC0QualifiedDAGCheckTrace
    (owner : PsKernelC0CertifiedStore)
    (fuel : Nat)
    (context : PsKernelCheckerContext)
    (initialState : PsKernelCheckerState) :
    List Nat →
    Except String
      (Σ finalState : PsKernelCheckerState,
        PsKernelC0CheckedDAGTrace
          owner fuel context initialState finalState)
  | [] => .ok ⟨initialState, .done initialState⟩
  | id :: rest => do
      let checked ← psKernelC0ScopedQualifiedDAGCapture
        owner fuel context initialState id
      let ⟨finalState, later⟩ ← psKernelC0QualifiedDAGCheckTrace
        owner fuel context checked.val.finalState rest
      .ok ⟨finalState, .step id checked later⟩

/-- Every successful mixed qualified/fallback trace is the exact original
source checked sequence: checked inference is neither assumed nor
reconstructed from a hash/handle, and the final state is identical. -/
theorem psKernelC0QualifiedDAGCheckTrace_source
    {owner : PsKernelC0CertifiedStore}
    {fuel : Nat}
    {context : PsKernelCheckerContext}
    {initialState finalState : PsKernelCheckerState}
    (trace : PsKernelC0CheckedDAGTrace
      owner fuel context initialState finalState) :
    psKernelC0IndexedDAGReferenceFold owner fuel context
        (psKernelC0CheckedDAGTraceIds trace) initialState =
      .ok finalState :=
  psKernelC0CheckedDAGTrace_sourceFold trace

/-- Opt-in indexed-session authority entry. The *source-owned* store
must be canonically certified even for an empty request, and every complete
result carries exact owner identity and the proof-carrying checked trace. -/
def psKernelC0IndexedSessionCheckQualifiedTrace
    (fuel : Nat)
    (session : PsKernelC0IndexedCheckerSession)
    (requested : List Nat) :
    Except String (PsKernelC0CertifiedIndexedSourceRun fuel session) :=
  match psKernelC0CertifyStoreOwned session.store with
  | none =>
      .error "indexed checker session store is not canonically certified"
  | some owner => do
      let ⟨finalState, checkedTrace⟩ ← psKernelC0QualifiedDAGCheckTrace
        owner.val fuel session.checker.context session.checker.state requested
      pure {
        owner := owner.val
        ownerExact := owner.property
        finalState := finalState
        checkedTrace := checkedTrace
      }
