import Ps.KernelCore.Architecture.DeepBinderFrames

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

/-- Exactly one deferred operation is the source changed-flag instantiator
    projection at its original offset; no new de Bruijn rule. -/
theorem psKernelC0DeepSubstForceOne
    (expr replacement : PsKernelExpr) (offset : Nat) :
    psKernelC0DeepSubstForce
      (psKernelC0DeepSubstPush (psKernelC0DeepSubstPure expr)
        ⟨replacement, offset⟩) =
      (psKernelC0ExprInstantiateOneChanged expr replacement offset).1 := by
  simp [psKernelC0DeepSubstForcePush,
    psKernelC0DeepSubstForcePure, psKernelC0DeepSubstApply]

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
