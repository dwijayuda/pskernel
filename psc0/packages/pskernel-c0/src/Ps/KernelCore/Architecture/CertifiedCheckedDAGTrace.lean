import Ps.KernelCore.Architecture.CertifiedCheckedDAGMemo

/-!
Proof-indexed, state-threaded checked-DAG execution.

Every step checks one canonical node using the authoritative source checker.
Unlike fixed-initial-state memo batches, successive steps receive the actual
previous checker state. A checked result cannot be reused from another owner,
fuel, context or initial state without a separate exact source proof.

This is not yet a fast incremental proof checker. It is the sound state-flow
interface to which a future qualified per-subterm DAG execution can refine.
Neither raw Nat node IDs nor syntax hashes are checking judgments.
-/

/-- The actual source checked state after each operation becomes the
initial state of the next one. A trace cannot be constructed with a
caller-invented final state or a mismatched certified store. -/
inductive PsKernelC0CheckedDAGTrace
    (owner : PsKernelC0CertifiedStore)
    (fuel : Nat)
    (context : PsKernelCheckerContext) :
    PsKernelCheckerState → PsKernelCheckerState → Type where
  | done (state : PsKernelCheckerState) :
      PsKernelC0CheckedDAGTrace owner fuel context state state
  | step {before after : PsKernelCheckerState}
      (requestedId : Nat)
      (checked :
        { receipt : PsKernelC0ScopedCheckedDAGReceipt
            owner fuel context before // receipt.rootId = requestedId })
      (rest : PsKernelC0CheckedDAGTrace
        owner fuel context checked.val.finalState after) :
      PsKernelC0CheckedDAGTrace owner fuel context before after

/-- Retain the requested source-handle sequence, not hashes or inferred types. -/
def psKernelC0CheckedDAGTraceIds
    {owner : PsKernelC0CertifiedStore}
    {fuel : Nat}
    {context : PsKernelCheckerContext}
    {before after : PsKernelCheckerState} :
    PsKernelC0CheckedDAGTrace owner fuel context before after → List Nat
  | .done _ => []
  | .step id _ rest => id :: psKernelC0CheckedDAGTraceIds rest

/-- All-or-nothing state-threaded checked run. A later source error returns
no final state or partial trace. The initial state is advanced ONLY through
an exact checked-source result and never inferred from a cached hash. -/
def psKernelC0CheckIndexedDAGTrace
    (owner : PsKernelC0CertifiedStore)
    (fuel : Nat)
    (context : PsKernelCheckerContext)
    (initialState : PsKernelCheckerState) :
    (requested : List Nat) →
      Except String
        (Σ finalState : PsKernelCheckerState,
          PsKernelC0CheckedDAGTrace
            owner fuel context initialState finalState)
  | [] => .ok ⟨initialState, .done initialState⟩
  | id :: rest => do
      let checked ← psKernelC0ScopedCheckedDAGCapture
        owner fuel context initialState id
      let ⟨finalState, later⟩ ←
        psKernelC0CheckIndexedDAGTrace
          owner fuel context checked.val.finalState rest
      .ok ⟨finalState, .step id checked later⟩

/-- One trace step is a complete source checked judgment for exactly the
request ID and initial state written in the type. The next step begins at
that precise source-produced final state. -/
theorem psKernelC0CheckedDAGTraceStep_source
    {owner : PsKernelC0CertifiedStore}
    {fuel : Nat}
    {context : PsKernelCheckerContext}
    {initialState : PsKernelCheckerState}
    {id : Nat}
    (checked :
      { receipt : PsKernelC0ScopedCheckedDAGReceipt
        owner fuel context initialState // receipt.rootId = id }) :
    psKernelCheckerCheck fuel context initialState checked.val.expression =
      .ok (checked.val.inferredType, checked.val.finalState) :=
  checked.val.source
