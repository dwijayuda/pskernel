import Ps.KernelCore.Metatheory.SemanticReferenceSessionGrade

/-!
Transparent metadata inference: a real, fuel-decreasing semantic case.

The executable checker uses the same recursive inference grade, inner term and
selected context under `mdata`, with its result/state unchanged in reference
mode. Metadata neither manufactures a new type nor changes denotation or
hereditary annotation/function validity.

The public model bridge makes the one actual smaller-fuel subcall premise
explicit. It neither assumes general checker soundness nor constructs an
annotation unrelated to that subcall. It is one inductive case, not a
full mutual inference/WHNF/DefEq theorem.
-/

namespace PsKernelSemantics.Reference
open PsKernelSemantics.SetModel ConLeche ConLeche.SetTheory
universe u
variable {V : Type u} [SetTheory V]

/-- The exact reference-mode mdata branch, including context depth entry
and an unchanged result/state from the smaller-fuel inference call. -/
theorem inferCore_mdata_trace
    (remaining : Nat) (whnf : InferOperation) (defeq : DefEqOperation)
    (c : PsKernelCheckerContext) (s next : PsKernelCheckerState)
    (metadata : Nat) (body result : PsKernelExpr) (io : Bool)
    (run : @psKernelInferCoreWithFuel psKernelReferenceCachePolicy
      (remaining + 1) whnf defeq c s (.mdata metadata body) io =
      .ok (result, next)) :
    ∃ entered : PsKernelCheckerContext,
      psKernelCheckerContextEnterRecDepth c = .ok entered ∧
      @psKernelInferCoreWithFuel psKernelReferenceCachePolicy
        remaining whnf defeq entered s body io = .ok (result, next) := by
  cases hd : psKernelCheckerContextEnterRecDepth c with
  | error error =>
      simp only [psKernelInferCoreWithFuel, psKernelReferenceCacheGet_miss,
        ite_self, hd] at run
      cases run
  | ok entered =>
      cases hb : @psKernelInferCoreWithFuel psKernelReferenceCachePolicy
          remaining whnf defeq entered s body io with
      | error error =>
          simp only [psKernelInferCoreWithFuel, psKernelReferenceCacheGet_miss,
            ite_self, hd, hb] at run
          cases run
      | ok pair =>
          rcases pair with ⟨innerType, innerState⟩
          have same :
              innerType = result ∧ innerState = next := by
            simpa only [psKernelInferCoreWithFuel, psKernelReferenceCacheGet_miss,
              ite_self, hd, hb, infer_publication_noop,
              Except.ok.injEq, Prod.mk.injEq] using run
          rcases same with ⟨rfl, rfl⟩
          exact ⟨entered, rfl, hb⟩

/-- Metadata carries the same exact interpreted term, selected type and
hereditary validity facts; it is semantically transparent by construction. -/
theorem checkedReading_mdata (M : Reading V) (Γ : List AnnotatedExpr)
    (metadata : Nat) (body type : AnnotatedExpr)
    (checked : CheckedReading M Γ body type) :
    CheckedReading M Γ (.mdata metadata body) type where
  typed := checked.typed
  termAnnotation := checked.termAnnotation
  typeAnnotation := checked.typeAnnotation
  termFunction := checked.termFunction
  typeFunction := checked.typeFunction

/-- A successful public session mdata inference, in either grade, is the
*same* smaller-fuel checker inference selected by the executable. -/
theorem referenceSessionGrade_mdata_trace
    (io : Bool) (remaining : Nat)
    (session next : PsKernelCheckerSession)
    (metadata : Nat) (body result : PsKernelExpr)
    (run : referenceSessionGrade io (remaining + 1)
      session (.mdata metadata body) = .ok (result, next)) :
    ∃ entered : PsKernelCheckerContext,
      ∃ returnedState : PsKernelCheckerState,
        psKernelCheckerContextEnterRecDepth session.context = .ok entered ∧
        @psKernelInferCoreWithFuel psKernelReferenceCachePolicy remaining
          (@psKernelWhnfWithRecursorFuel psKernelReferenceCachePolicy (remaining + 1)
            (@psKernelIsDefEqWithFuel psKernelReferenceCachePolicy (remaining + 1)))
          (@psKernelIsDefEqWithFuel psKernelReferenceCachePolicy (remaining + 1))
          entered session.state body io = .ok (result, returnedState) ∧
        next = PsKernelCheckerSession.mk session.context returnedState := by
  obtain ⟨returnedState, coreRun, nextEq⟩ :=
    referenceSessionGrade_core_trace io (remaining + 1)
      session next (.mdata metadata body) result run
  obtain ⟨entered, depth, bodyRun⟩ :=
    inferCore_mdata_trace remaining
      (@psKernelWhnfWithRecursorFuel psKernelReferenceCachePolicy (remaining + 1)
        (@psKernelIsDefEqWithFuel psKernelReferenceCachePolicy (remaining + 1)))
      (@psKernelIsDefEqWithFuel psKernelReferenceCachePolicy (remaining + 1))
      session.context session.state returnedState metadata body result io coreRun
  exact ⟨entered, returnedState, depth, bodyRun, nextEq⟩

/-- One concrete accepting-direction recursive inference CASE, rather
than a postulated whole-checker model. The premise is restricted to the
ACTUAL one-step smaller-fuel subcall and its exact return state. -/
theorem referenceSessionGrade_mdata_checked_reading
    (M : Reading V) (Γ : List AnnotatedExpr)
    (io : Bool) (remaining : Nat)
    (session next : PsKernelCheckerSession)
    (metadata : Nat) (body : AnnotatedExpr) (result : PsKernelExpr)
    (run : referenceSessionGrade io (remaining + 1)
      session (.mdata metadata body.erase) = .ok (result, next))
    (recursiveSound :
      ∀ entered returnedState,
        psKernelCheckerContextEnterRecDepth session.context = .ok entered →
        @psKernelInferCoreWithFuel psKernelReferenceCachePolicy remaining
          (@psKernelWhnfWithRecursorFuel psKernelReferenceCachePolicy (remaining + 1)
            (@psKernelIsDefEqWithFuel psKernelReferenceCachePolicy (remaining + 1)))
          (@psKernelIsDefEqWithFuel psKernelReferenceCachePolicy (remaining + 1))
          entered session.state body.erase io = .ok (result, returnedState) →
        ∃ type : AnnotatedExpr, type.erase = result ∧
          CheckedReading M Γ body type) :
    ∃ type : AnnotatedExpr, type.erase = result ∧
      CheckedReading M Γ (.mdata metadata body) type := by
  obtain ⟨entered, returnedState, depth, innerRun, _⟩ :=
    referenceSessionGrade_mdata_trace io remaining session next
      metadata body.erase result run
  obtain ⟨type, erasure, reading⟩ :=
    recursiveSound entered returnedState depth innerRun
  exact ⟨type, erasure, checkedReading_mdata M Γ metadata body type reading⟩

end PsKernelSemantics.Reference
