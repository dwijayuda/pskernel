import CompilerPreservation

/- C2 first recursive caller fragment. Source evaluation is a pure literal/zeta
   relation, independent of erasure. Eligibility selects actual type/proof-let
   branches and finite fuel; it never assumes the eraser's result. Runtime lets,
   typing/classifier soundness, variables/calls and freshness remain open. -/
namespace Ps.MinKernel.CompilerCaller

inductive Value where
  | natural (value : Nat)
  | text (value : String)

inductive SourceEval : PsExpr → Value → Prop where
  | natural (n) : SourceEval (.lit (.natural n)) (.natural n)
  | text (s) : SourceEval (.lit (.string s)) (.text s)
  | zeta (h : SourceEval (psExprInstantiate1 body value) result) :
      SourceEval (.letE name domain value body) result

inductive TargetEval : PsVerifiedIrExpr → Value → Prop where
  | natural (n) : TargetEval (.literal (.natural n)) (.natural n)
  | text (s) : TargetEval (.literal (.string s)) (.text s)

inductive Eligible (environment : PsEnvironment) :
    Nat → PsErasureScope → PsExpr → Value → Prop where
  | natural (remaining scope n) :
      Eligible environment (Nat.succ remaining) scope (.lit (.natural n)) (.natural n)
  | text (remaining scope s) :
      Eligible environment (Nat.succ remaining) scope (.lit (.string s)) (.text s)
  | erasedType (remaining scope name domain value body result)
      (kind : psErasureClassifyBinder environment scope.localContext domain = .type)
      (eligible : Eligible environment remaining (psErasureNestedRuntimeScope scope)
        (psExprInstantiate1 body value) result) :
      Eligible environment (Nat.succ remaining) scope (.letE name domain value body) result
  | erasedProof (remaining scope name domain value body result)
      (kind : psErasureClassifyBinder environment scope.localContext domain = .proof)
      (eligible : Eligible environment remaining (psErasureNestedRuntimeScope scope)
        (psExprInstantiate1 body value) result) :
      Eligible environment (Nat.succ remaining) scope (.letE name domain value body) result

theorem fuel_zero (environment : PsEnvironment) (scope : PsErasureScope) (expression : PsExpr) :
    psEraseRuntimeExprWithFuelWorker environment 0 scope expression = .error .fuelExhausted := rfl

theorem nested_idempotent (scope : PsErasureScope) :
    psErasureNestedRuntimeScope (psErasureNestedRuntimeScope scope) =
      psErasureNestedRuntimeScope scope := rfl

theorem nested_context (scope : PsErasureScope) :
    (psErasureNestedRuntimeScope scope).localContext = scope.localContext ∧
    (psErasureNestedRuntimeScope scope).runtimeLocals = scope.runtimeLocals ∧
    (psErasureNestedRuntimeScope scope).typeLocals = scope.typeLocals ∧
    (psErasureNestedRuntimeScope scope).erasedLocals = scope.erasedLocals :=
  ⟨rfl, rfl, rfl, rfl⟩

theorem nested_names (scope : PsErasureScope) :
    (psErasureNestedRuntimeScope scope).declarationNames = scope.declarationNames ∧
    (psErasureNestedRuntimeScope scope).runtimeExpressions = scope.runtimeExpressions ∧
    (psErasureNestedRuntimeScope scope).currentDefinition = none :=
  ⟨rfl, rfl, rfl⟩

theorem eligible_positive (h : Eligible environment fuel scope expression value) :
    0 < fuel := by
  cases h <;> exact Nat.zero_lt_succ _

theorem eligible_source (h : Eligible environment fuel scope expression value) :
    SourceEval expression value := by
  induction h with
  | natural => exact .natural _
  | text => exact .text _
  | erasedType remaining scope name domain value body result kind eligible ih =>
      exact .zeta ih
  | erasedProof remaining scope name domain value body result kind eligible ih =>
      exact .zeta ih

theorem eligible_erases (h : Eligible environment fuel scope expression value) :
    ∃ ir, psEraseRuntimeExprWithFuelWorker environment fuel scope expression = .ok ir ∧
      TargetEval ir value := by
  induction h with
  | natural => exact ⟨_, rfl, .natural _⟩
  | text => exact ⟨_, rfl, .text _⟩
  | erasedType remaining scope name domain value body result kind eligible ih =>
      obtain ⟨ir, lowered, evaluates⟩ := ih
      refine ⟨ir, ?_, evaluates⟩
      simpa only [psEraseRuntimeExprWithFuelWorker, kind] using lowered
  | erasedProof remaining scope name domain value body result kind eligible ih =>
      obtain ⟨ir, lowered, evaluates⟩ := ih
      refine ⟨ir, ?_, evaluates⟩
      simpa only [psEraseRuntimeExprWithFuelWorker, kind] using lowered

theorem public_preserves (h : Eligible environment fuel scope expression value) :
    ∃ ir, psEraseRuntimeExprWithFuel environment scope fuel expression = .ok ir ∧
      SourceEval expression value ∧ TargetEval ir value := by
  obtain ⟨ir, lowered, evaluates⟩ := eligible_erases h
  exact ⟨ir, lowered, eligible_source h, evaluates⟩

theorem entry_preserves (h : Eligible environment 4096 scope expression value) :
    ∃ ir, psEraseRuntimeExpr environment scope expression = .ok ir ∧
      SourceEval expression value ∧ TargetEval ir value :=
  public_preserves h

theorem natural_bridge (h : TargetEval ir (.natural n))
    (targetEnvironment : Ps.MinKernel.CompilerPreservation.Env) :
    Ps.MinKernel.CompilerPreservation.Eval targetEnvironment ir (.natural n) := by
  cases h
  exact .natural _ _

end Ps.MinKernel.CompilerCaller
