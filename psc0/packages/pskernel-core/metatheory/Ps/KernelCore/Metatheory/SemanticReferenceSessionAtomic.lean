import Ps.KernelCore.Metatheory.SemanticReferenceSessionMData

/-!
Concrete reference core and public-session ATOMIC inference cases.

The executable inference core rejects loose bound variables and metavariables
in both grades. Successful Nat and String literal inference returns the exact
primitive type with unchanged state. The Nat result still follows its real
maxNatSize resource guard. We do not claim these syntactic primitive type
results construct the modeled Nat/String constants or establish general
inference soundness. They are suitable base cases for later joint induction.
-/

namespace PsKernelSemantics.Reference

/-- Neither grade of the ACTUAL reference core can successfully infer a loose
bound variable, for any fuel, callbacks, checker state, or low-level context. -/
theorem inferCore_bvar_no_success
    (fuel : Nat) (whnf : InferOperation) (defeq : DefEqOperation)
    (c : PsKernelCheckerContext) (s next : PsKernelCheckerState)
    (index : Nat) (result : PsKernelExpr) (io : Bool) :
    @psKernelInferCoreWithFuel psKernelReferenceCachePolicy fuel
      whnf defeq c s (.bvar index) io ≠ .ok (result, next) := by
  intro run
  cases fuel with
  | zero =>
      simp only [psKernelInferCoreWithFuel] at run
      cases run
  | succ remaining =>
      cases hd : psKernelCheckerContextEnterRecDepth c with
      | error err =>
          simp only [psKernelInferCoreWithFuel, psKernelReferenceCacheGet_miss,
            ite_self, hd] at run
          cases run
      | ok entered =>
          simp only [psKernelInferCoreWithFuel, psKernelReferenceCacheGet_miss,
            ite_self, hd] at run
          cases run

/-- Neither grade of the ACTUAL reference core can successfully infer an
unresolved metavariable, even in an arbitrary hand-constructed context. -/
theorem inferCore_mvar_no_success
    (fuel : Nat) (whnf : InferOperation) (defeq : DefEqOperation)
    (c : PsKernelCheckerContext) (s next : PsKernelCheckerState)
    (name : PsKernelName) (result : PsKernelExpr) (io : Bool) :
    @psKernelInferCoreWithFuel psKernelReferenceCachePolicy fuel
      whnf defeq c s (.mvar name) io ≠ .ok (result, next) := by
  intro run
  cases fuel with
  | zero =>
      simp only [psKernelInferCoreWithFuel] at run
      cases run
  | succ remaining =>
      cases hd : psKernelCheckerContextEnterRecDepth c with
      | error err =>
          simp only [psKernelInferCoreWithFuel, psKernelReferenceCacheGet_miss,
            ite_self, hd] at run
          cases run
      | ok entered =>
          simp only [psKernelInferCoreWithFuel, psKernelReferenceCacheGet_miss,
            ite_self, hd] at run
          cases run

/-- The exact STRING primitive type and unmodified state returned on any
successful reference core inference of a string literal, in either grade. -/
theorem inferCore_string_literal_result
    (remaining : Nat) (whnf : InferOperation) (defeq : DefEqOperation)
    (c : PsKernelCheckerContext) (s next : PsKernelCheckerState)
    (value : String) (result : PsKernelExpr) (io : Bool)
    (run : @psKernelInferCoreWithFuel psKernelReferenceCachePolicy
      (remaining + 1) whnf defeq c s (.lit (.str value)) io =
      .ok (result, next)) :
    result = .const psKernelStringName [] ∧ next = s := by
  cases hd : psKernelCheckerContextEnterRecDepth c with
  | error err =>
      simp only [psKernelInferCoreWithFuel, psKernelReferenceCacheGet_miss,
        ite_self, hd] at run
      cases run
  | ok entered =>
      have both : (PsKernelExpr.const psKernelStringName []) = result ∧
          s = next := by
        simpa only [psKernelInferCoreWithFuel, psKernelReferenceCacheGet_miss,
          ite_self, hd, infer_publication_noop, Except.ok.injEq,
          Prod.mk.injEq] using run
      exact ⟨both.1.symm, both.2.symm⟩

/-- A NATURAL literal is returned with the exact primitive Nat type and
unmodified state only after the genuine maxNatSize guard has succeeded. -/
theorem inferCore_nat_literal_result
    (remaining : Nat) (whnf : InferOperation) (defeq : DefEqOperation)
    (c : PsKernelCheckerContext) (s next : PsKernelCheckerState)
    (value : Nat) (result : PsKernelExpr) (io : Bool)
    (run : @psKernelInferCoreWithFuel psKernelReferenceCachePolicy
      (remaining + 1) whnf defeq c s (.lit (.nat value)) io =
      .ok (result, next)) :
    result = .const psKernelNatName [] ∧ next = s := by
  cases hd : psKernelCheckerContextEnterRecDepth c with
  | error err =>
      simp only [psKernelInferCoreWithFuel, psKernelReferenceCacheGet_miss,
        ite_self, hd] at run
      cases run
  | ok entered =>
      cases hs : psKernelCheckNatSize entered.maxNatSize value with
      | error err =>
          simp only [psKernelInferCoreWithFuel, psKernelReferenceCacheGet_miss,
            ite_self, hd, hs] at run
          cases run
      | ok accepted =>
          have both : (PsKernelExpr.const psKernelNatName []) = result ∧
              s = next := by
            simpa only [psKernelInferCoreWithFuel, psKernelReferenceCacheGet_miss,
              ite_self, hd, hs, infer_publication_noop, Except.ok.injEq,
              Prod.mk.injEq] using run
          exact ⟨both.1.symm, both.2.symm⟩

/-- Fuel exhaustion cannot produce a false success through the public session
wrapper in either inference grade. -/
theorem referenceSessionGrade_zero_no_success
    (io : Bool) (session next : PsKernelCheckerSession)
    (expr result : PsKernelExpr) :
    referenceSessionGrade io 0 session expr ≠ .ok (result, next) := by
  intro run
  obtain ⟨returnedState, coreRun, _⟩ :=
    referenceSessionGrade_core_trace io 0 session next expr result run
  simp only [psKernelInferCoreWithFuel] at coreRun
  cases coreRun

/-- Public reference checker rejection of loose bound variables follows
from the actual checker core, without inventing a validity premise. -/
theorem referenceSessionGrade_bvar_no_success
    (io : Bool) (fuel : Nat) (session next : PsKernelCheckerSession)
    (index : Nat) (result : PsKernelExpr) :
    referenceSessionGrade io fuel session (.bvar index) ≠
      .ok (result, next) := by
  intro run
  obtain ⟨returnedState, coreRun, _⟩ :=
    referenceSessionGrade_core_trace io fuel session next (.bvar index) result run
  exact (inferCore_bvar_no_success fuel
    (@psKernelWhnfWithRecursorFuel psKernelReferenceCachePolicy fuel
      (@psKernelIsDefEqWithFuel psKernelReferenceCachePolicy fuel))
    (@psKernelIsDefEqWithFuel psKernelReferenceCachePolicy fuel)
    session.context session.state returnedState index result io) coreRun

/-- Public reference checker rejection of unresolved metavariables in both
grades, regardless of a low-level constructed checker state. -/
theorem referenceSessionGrade_mvar_no_success
    (io : Bool) (fuel : Nat) (session next : PsKernelCheckerSession)
    (name : PsKernelName) (result : PsKernelExpr) :
    referenceSessionGrade io fuel session (.mvar name) ≠
      .ok (result, next) := by
  intro run
  obtain ⟨returnedState, coreRun, _⟩ :=
    referenceSessionGrade_core_trace io fuel session next (.mvar name) result run
  exact (inferCore_mvar_no_success fuel
    (@psKernelWhnfWithRecursorFuel psKernelReferenceCachePolicy fuel
      (@psKernelIsDefEqWithFuel psKernelReferenceCachePolicy fuel))
    (@psKernelIsDefEqWithFuel psKernelReferenceCachePolicy fuel)
    session.context session.state returnedState name result io) coreRun

/-- Both public reference inference grades return exactly String for a String
literal, with the same public session and no callback soundness hypothesis. -/
theorem referenceSessionGrade_string_literal_result
    (io : Bool) (remaining : Nat)
    (session next : PsKernelCheckerSession)
    (value : String) (result : PsKernelExpr)
    (run : referenceSessionGrade io (remaining + 1) session
      (.lit (.str value)) = .ok (result, next)) :
    result = .const psKernelStringName [] ∧ next = session := by
  obtain ⟨returnedState, coreRun, nextEq⟩ :=
    referenceSessionGrade_core_trace io (remaining + 1) session next
      (.lit (.str value)) result run
  obtain ⟨hType, hState⟩ :=
    inferCore_string_literal_result remaining
      (@psKernelWhnfWithRecursorFuel psKernelReferenceCachePolicy (remaining + 1)
        (@psKernelIsDefEqWithFuel psKernelReferenceCachePolicy (remaining + 1)))
      (@psKernelIsDefEqWithFuel psKernelReferenceCachePolicy (remaining + 1))
      session.context session.state returnedState value result io coreRun
  refine ⟨hType, ?_⟩
  calc
    next = PsKernelCheckerSession.mk session.context returnedState := nextEq
    _ = PsKernelCheckerSession.mk session.context session.state := by rw [hState]
    _ = session := by cases session; rfl

/-- The public Nat literal result is also exactly Nat with the unmodified
session, conditional only on successful EXECUTION of the size guard. -/
theorem referenceSessionGrade_nat_literal_result
    (io : Bool) (remaining : Nat)
    (session next : PsKernelCheckerSession)
    (value : Nat) (result : PsKernelExpr)
    (run : referenceSessionGrade io (remaining + 1) session
      (.lit (.nat value)) = .ok (result, next)) :
    result = .const psKernelNatName [] ∧ next = session := by
  obtain ⟨returnedState, coreRun, nextEq⟩ :=
    referenceSessionGrade_core_trace io (remaining + 1) session next
      (.lit (.nat value)) result run
  obtain ⟨hType, hState⟩ :=
    inferCore_nat_literal_result remaining
      (@psKernelWhnfWithRecursorFuel psKernelReferenceCachePolicy (remaining + 1)
        (@psKernelIsDefEqWithFuel psKernelReferenceCachePolicy (remaining + 1)))
      (@psKernelIsDefEqWithFuel psKernelReferenceCachePolicy (remaining + 1))
      session.context session.state returnedState value result io coreRun
  refine ⟨hType, ?_⟩
  calc
    next = PsKernelCheckerSession.mk session.context returnedState := nextEq
    _ = PsKernelCheckerSession.mk session.context session.state := by rw [hState]
    _ = session := by cases session; rfl

end PsKernelSemantics.Reference
