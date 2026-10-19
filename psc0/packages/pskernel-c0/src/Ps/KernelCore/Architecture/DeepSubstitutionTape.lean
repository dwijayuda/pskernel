import Ps.KernelCore.Architecture.DeepInferenceFrames

/-!
Non-admitting lazy capture-avoiding substitution tape.

Repeated materialization of deeply nested binder bodies is expensive on
shared DAGs. A future continuation evaluator may store source substitutions
in O(1) push time and only force them when a real source typing/WHNF/DefEq
rule observes the expression. Crucially this tape means *sequential*
original single-variable operations; it does NOT silently treat them as a
simultaneous substitution or conflate binder offsets.

This is an exact source-valued representation, not yet an optimized kernel
inference operation. No fuel adjustment, unchecked equality or axiom.
-/

structure PsKernelC0DeepSubstOperation where
  replacement : PsKernelExpr
  binderOffset : Nat

/-- Original source single-variable capture-avoiding operation, including
    the original de Bruijn offset and changed-flag reconstruction. -/
def psKernelC0DeepSubstApply
    (source : PsKernelExpr)
    (operation : PsKernelC0DeepSubstOperation) : PsKernelExpr :=
  if operation.binderOffset == 0 then
    psKernelExprInstantiate1 source operation.replacement
  else
    (psKernelC0ExprInstantiateOneChanged
      source operation.replacement operation.binderOffset).1

/-- The newest pending operation is stored at the *head*: appending a
    dependent substitution is O(1) and preserves all previous operations. -/
structure PsKernelC0DeepSubstTape where
  original : PsKernelExpr
  newestFirst : List PsKernelC0DeepSubstOperation

def psKernelC0DeepSubstPure
    (expr : PsKernelExpr) : PsKernelC0DeepSubstTape :=
  ⟨expr, []⟩

def psKernelC0DeepSubstPush
    (tape : PsKernelC0DeepSubstTape)
    (operation : PsKernelC0DeepSubstOperation) :
    PsKernelC0DeepSubstTape :=
  ⟨tape.original, operation :: tape.newestFirst⟩

/-- A forcing boundary replays the exact original source operations
    oldest-first, not an invented multi-substitution algebra. -/
def psKernelC0DeepSubstForce
    (tape : PsKernelC0DeepSubstTape) : PsKernelExpr :=
  tape.newestFirst.reverse.foldl psKernelC0DeepSubstApply tape.original

/-- Forcing the zero-operation tape never traverses the expression. -/
theorem psKernelC0DeepSubstForcePure (expr : PsKernelExpr) :
    psKernelC0DeepSubstForce (psKernelC0DeepSubstPure expr) = expr := by
  rfl

/-- An O(1) deferred push is observationally the exact next original
    capture-avoiding single-variable instantiation, including offset. -/
theorem psKernelC0DeepSubstForcePush
    (tape : PsKernelC0DeepSubstTape)
    (operation : PsKernelC0DeepSubstOperation) :
    psKernelC0DeepSubstForce (psKernelC0DeepSubstPush tape operation) =
      psKernelC0DeepSubstApply (psKernelC0DeepSubstForce tape) operation := by
  simp [psKernelC0DeepSubstForce, psKernelC0DeepSubstPush,
    List.reverse_cons, List.foldl_append]

/-- A single deferred operation forces to its original source
    operation at the same offset. At offset zero, that operation includes
    the public binder-headed loose-variable shortcut. -/
theorem psKernelC0DeepSubstForceOne
    (expr replacement : PsKernelExpr) (offset : Nat) :
    psKernelC0DeepSubstForce
      (psKernelC0DeepSubstPush (psKernelC0DeepSubstPure expr)
        ⟨replacement, offset⟩) =
      psKernelC0DeepSubstApply expr ⟨replacement, offset⟩ := by
  simp [psKernelC0DeepSubstForcePush,
    psKernelC0DeepSubstForcePure]

/-- Offset zero is exactly the public source capture-avoiding instantiator,
    including its binder-headed loose-variable shortcut. -/
theorem psKernelC0DeepSubstForceOneSource
    (expr replacement : PsKernelExpr) :
    psKernelC0DeepSubstForce
      (psKernelC0DeepSubstPush (psKernelC0DeepSubstPure expr)
        ⟨replacement, 0⟩) =
      psKernelExprInstantiate1 expr replacement := by
  simp [psKernelC0DeepSubstForcePush,
    psKernelC0DeepSubstForcePure, psKernelC0DeepSubstApply]

/-- The original source rule for opening a lambda/Pi body. Kept as an
    independent eager oracle for validating a later suspended worklist. -/
def psKernelC0DeepEagerBinderOpening
    (body : PsKernelExpr)
    (fresh : PsKernelName)
    (ranges : List Nat) : PsKernelExpr × List Nat :=
  match ranges with
  | range :: tail =>
    if range == 0 then (body, tail)
    else (psKernelExprInstantiate1 body (.fvar fresh), [])
  | [] => (psKernelExprInstantiate1 body (.fvar fresh), [])

/-- Build the identical binder-opening operation *without traversing body*.
    Only a zero-range summary may omit substitution, as in the old source.
    Otherwise we append the exactly equivalent offset-zero operation in O(1).
    A consumer must force the tape before any operation that observes its
    expression, until a stronger head-observation theorem is established. -/
def psKernelC0DeepDeferBinderOpening
    (body : PsKernelExpr)
    (fresh : PsKernelName)
    (ranges : List Nat) : PsKernelC0DeepSubstTape × List Nat :=
  match ranges with
  | range :: tail =>
    if range == 0 then (psKernelC0DeepSubstPure body, tail)
    else
      (psKernelC0DeepSubstPush (psKernelC0DeepSubstPure body)
        ⟨.fvar fresh, 0⟩, [])
  | [] =>
    (psKernelC0DeepSubstPush (psKernelC0DeepSubstPure body)
      ⟨.fvar fresh, 0⟩, [])

/-- Both the body and remaining source Pi/lambda range metadata are EXACT.
    This is a pure all-input semantic equality, with no assumptions about
    DAG sharing, freshness or the actual source binder term. -/
theorem psKernelC0DeepDeferBinderOpening_source
    (body : PsKernelExpr)
    (fresh : PsKernelName)
    (ranges : List Nat) :
    (psKernelC0DeepSubstForce
        (psKernelC0DeepDeferBinderOpening body fresh ranges).1,
      (psKernelC0DeepDeferBinderOpening body fresh ranges).2) =
      psKernelC0DeepEagerBinderOpening body fresh ranges := by
  cases ranges with
  | nil =>
      simp [psKernelC0DeepDeferBinderOpening,
        psKernelC0DeepEagerBinderOpening,
        psKernelC0DeepSubstForceOneSource]
  | cons range tail =>
      by_cases h : range = 0
      · simp [psKernelC0DeepDeferBinderOpening,
          psKernelC0DeepEagerBinderOpening, h,
          psKernelC0DeepSubstForcePure]
      · simp [psKernelC0DeepDeferBinderOpening,
          psKernelC0DeepEagerBinderOpening, h,
          psKernelC0DeepSubstForceOneSource]
