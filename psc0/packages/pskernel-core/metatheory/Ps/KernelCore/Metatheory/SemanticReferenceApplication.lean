import Ps.KernelCore.Metatheory.SemanticCoherentValidity
import Ps.KernelCore.Metatheory.SemanticReferenceSortChecks
import Ps.KernelCore.Metatheory.SemanticStructuralEquality

/-!
Checked application: exact production calls and their local semantic bridge.
The infer-only spine is deliberately a separate obligation. This file does not
assume general subject reduction or a sort for every inferred result type.
-/
namespace PsKernelSemantics.Reference

def applicationEqContext (c : PsKernelCheckerContext) (a : PsKernelExpr) :
    PsKernelCheckerContext :=
  if psKernelExprIsEagerReduce a then psKernelCheckerContextWithEagerReduce c true else c

inductive ApplicationComparison (defeq : DefEqOperation)
    (c : PsKernelCheckerContext) (s : PsKernelCheckerState)
    (arg argType domain : PsKernelExpr) : PsKernelCheckerState → Prop where
  | structural (h : psKernelExprEq argType domain = true) :
      ApplicationComparison defeq c s arg argType domain s
  | conversion (h : psKernelExprEq argType domain = false)
      (next : PsKernelCheckerState)
      (run : defeq (applicationEqContext c arg) s argType domain = .ok (true, next)) :
      ApplicationComparison defeq c s arg argType domain next

structure ApplicationTrace (remaining : Nat) (whnf : InferOperation) (defeq : DefEqOperation)
    (c : PsKernelCheckerContext) (s : PsKernelCheckerState)
    (fn arg result : PsKernelExpr) (next : PsKernelCheckerState) where
  entered : PsKernelCheckerContext
  fnType : PsKernelExpr
  fnState : PsKernelCheckerState
  view : PsKernelForallView
  forallState : PsKernelCheckerState
  argType : PsKernelExpr
  argState : PsKernelCheckerState
  depth : psKernelCheckerContextEnterRecDepth c = .ok entered
  fnRun : @psKernelInferCoreWithFuel psKernelReferenceCachePolicy
    remaining whnf defeq entered s fn false = .ok (fnType, fnState)
  forallRun : psKernelEnsureForallWith whnf entered fnState fnType =
    .ok (view, forallState)
  argRun : @psKernelInferCoreWithFuel psKernelReferenceCachePolicy
    remaining whnf defeq entered forallState arg false = .ok (argType, argState)
  comparison : ApplicationComparison defeq entered argState arg argType view.domain next
  resultEq : result = psKernelExprInstantiate1 view.body arg

theorem inferCore_app_trace (remaining : Nat)
    (whnf : InferOperation) (defeq : DefEqOperation)
    (c : PsKernelCheckerContext) (s next : PsKernelCheckerState)
    (fn arg result : PsKernelExpr)
    (run : @psKernelInferCoreWithFuel psKernelReferenceCachePolicy
      (remaining + 1) whnf defeq c s (.app fn arg) false = .ok (result, next)) :
    Nonempty (ApplicationTrace remaining whnf defeq c s fn arg result next) := by
  cases hd : psKernelCheckerContextEnterRecDepth c with
  | error error =>
      simp only [psKernelInferCoreWithFuel, psKernelReferenceCacheGet_miss,
        ite_self, hd] at run
      cases run
  | ok entered =>
      cases hf : @psKernelInferCoreWithFuel psKernelReferenceCachePolicy
          remaining whnf defeq entered s fn false with
      | error error =>
          simp only [psKernelInferCoreWithFuel, psKernelReferenceCacheGet_miss,
            ite_self, hd, Bool.false_eq_true, ite_false, hf] at run
          cases run
      | ok f =>
          rcases f with ⟨fnType, fnState⟩
          cases hp : psKernelEnsureForallWith whnf entered fnState fnType with
          | error error =>
              simp only [psKernelInferCoreWithFuel, psKernelReferenceCacheGet_miss,
                ite_self, hd, Bool.false_eq_true, ite_false, hf, hp] at run
              cases run
          | ok p =>
              rcases p with ⟨view, forallState⟩
              cases ha : @psKernelInferCoreWithFuel psKernelReferenceCachePolicy
                  remaining whnf defeq entered forallState arg false with
              | error error =>
                  simp only [psKernelInferCoreWithFuel, psKernelReferenceCacheGet_miss,
                    ite_self, hd, Bool.false_eq_true, ite_false, hf, hp, ha] at run
                  cases run
              | ok a =>
                  rcases a with ⟨argType, argState⟩
                  cases he : psKernelExprEq argType view.domain with
                  | true =>
                      simp only [psKernelInferCoreWithFuel, psKernelReferenceCacheGet_miss,
                        ite_self, hd, Bool.false_eq_true, ite_false, hf, hp, ha, he,
                        ite_true, infer_publication_noop, Except.ok.injEq, Prod.mk.injEq] at run
                      obtain ⟨rfl, rfl⟩ := run
                      exact ⟨⟨entered, fnType, fnState, view, forallState, argType, argState,
                        hd, hf, hp, ha, .structural he, rfl⟩⟩
                  | false =>
                      cases hc : defeq (applicationEqContext entered arg)
                          argState argType view.domain with
                      | error error =>
                          simp only [applicationEqContext] at hc
                          simp only [psKernelInferCoreWithFuel, psKernelReferenceCacheGet_miss,
                            ite_self, hd, Bool.false_eq_true, ite_false, hf, hp, ha, he, hc] at run
                          cases run
                      | ok answer =>
                          rcases answer with ⟨equal, compared⟩
                          cases equal with
                          | false =>
                              simp only [applicationEqContext] at hc
                              simp only [psKernelInferCoreWithFuel, psKernelReferenceCacheGet_miss,
                                ite_self, hd, Bool.false_eq_true, ite_false, hf, hp, ha, he, hc] at run
                              cases run
                          | true =>
                              have hc' := hc
                              simp only [applicationEqContext] at hc'
                              simp only [psKernelInferCoreWithFuel, psKernelReferenceCacheGet_miss,
                                ite_self, hd, Bool.false_eq_true, ite_false, hf, hp, ha, he, hc',
                                ite_true, infer_publication_noop, Except.ok.injEq, Prod.mk.injEq] at run
                              obtain ⟨rfl, rfl⟩ := run
                              exact ⟨⟨entered, fnType, fnState, view, forallState, argType, argState,
                                hd, hf, hp, ha, .conversion he compared hc, rfl⟩⟩

open ConLeche ConLeche.SetTheory ConLeche.SetModel SetModel AnnotatedExpr
universe w
variable {V : Type w} [SetTheory V]

/-- The two actual comparison routes have distinct, explicit obligations:
coherent readings for the structural shortcut; denotation preservation for
the specific successful recursive equality call. -/
theorem applicationComparison_models_equal (M : Reading V) (Γ : List AnnotatedExpr)
    (defeq : DefEqOperation) (c : PsKernelCheckerContext)
    (s next : PsKernelCheckerState) (arg : PsKernelExpr)
    (argType domain : AnnotatedExpr)
    (comparison : ApplicationComparison defeq c s arg argType.erase domain.erase next)
    (structural : psKernelExprEq argType.erase domain.erase = true →
      RegimesAgree M argType domain)
    (conversion : defeq (applicationEqContext c arg) s argType.erase domain.erase =
      .ok (true, next) → ModelsEqual M Γ argType domain) :
    ModelsEqual M Γ argType domain := by
  cases comparison with
  | structural h => exact fun ρ _ => exprEq_preserves_interp M argType domain h (structural h) ρ
  | conversion h state run => exact conversion run

/-- A concrete checked application returns the production-instantiated body
type. Product annotation validity supplies exactly the extra condition needed
by the impredicative model's application law. -/
theorem application_trace_has_model
    (M : Reading V) (Γ : List AnnotatedExpr)
    (remaining : Nat) (whnf : InferOperation) (defeq : DefEqOperation)
    (c : PsKernelCheckerContext) (s next : PsKernelCheckerState)
    (f a A B argType : AnnotatedExpr) (v : PsKernelLevel) (result : PsKernelExpr)
    (trace : ApplicationTrace remaining whnf defeq c s f.erase a.erase result next)
    (domainErasure : A.erase = trace.view.domain)
    (bodyErasure : B.erase = trace.view.body)
    (argTypeErasure : argType.erase = trace.argType)
    (hf : ModelsType M Γ f (.forallE trace.view.name A B trace.view.binderInfo v))
    (ha : ModelsType M Γ a argType)
    (structural : psKernelExprEq trace.argType trace.view.domain = true →
      RegimesAgree M argType A)
    (conversion : defeq (applicationEqContext trace.entered a.erase)
      trace.argState trace.argType trace.view.domain = .ok (true, next) →
      ModelsEqual M Γ argType A)
    (hfValid : ∀ ρ, Satisfies M Γ ρ → AnnotationValid M ρ f)
    (haValid : ∀ ρ, Satisfies M Γ ρ → AnnotationValid M ρ a)
    (piValid : ∀ ρ, Satisfies M Γ ρ →
      AnnotationValid M ρ (.forallE trace.view.name A B trace.view.binderInfo v)) :
    ∃ type : AnnotatedExpr, type.erase = result ∧
      ModelsType M Γ (.app f a) type ∧
      (∀ ρ, Satisfies M Γ ρ → AnnotationValid M ρ (.app f a)) ∧
      (∀ ρ, Satisfies M Γ ρ → AnnotationValid M ρ type) := by
  have comparison : ApplicationComparison defeq trace.entered trace.argState
      a.erase argType.erase A.erase next := by
    rw [argTypeErasure, domainErasure]
    exact trace.comparison
  have hCompare := applicationComparison_models_equal M Γ defeq trace.entered
    trace.argState next a.erase argType A comparison
    (fun h => structural (by simpa only [argTypeErasure, domainErasure] using h))
    (fun h => conversion (by simpa only [argTypeErasure, domainErasure] using h))
  have ha' := models_convert M Γ a argType A ha hCompare
  refine ⟨inst a B 0, ?_,
    models_app_of_annotationValid M Γ trace.view.name f a A B trace.view.binderInfo v
      hf ha' piValid,
    fun ρ hρ => ⟨hfValid ρ hρ, haValid ρ hρ⟩,
    application_result_annotationValid M Γ trace.view.name a A B trace.view.binderInfo v
      ha' haValid piValid⟩
  rw [erase_instantiate1, bodyErasure]
  exact trace.resultEq.symm

/-- Fix the particular application and result-type readings, including both
hereditary predicates. The structural branch needs the executable annotation
guard in addition to the raw comparison recorded by the trace. Establishing
that guard at every public acceptance path remains a checker-migration
obligation; it is not inferred from erasure or validity alone. -/
theorem application_trace_checked_reading
    (M : Reading V) (Γ : List AnnotatedExpr)
    (remaining : Nat) (whnf : InferOperation) (defeq : DefEqOperation)
    (c : PsKernelCheckerContext) (s next : PsKernelCheckerState)
    (f a A B argType : AnnotatedExpr) (v : PsKernelLevel) (result : PsKernelExpr)
    (trace : ApplicationTrace remaining whnf defeq c s f.erase a.erase result next)
    (domainErasure : A.erase = trace.view.domain)
    (bodyErasure : B.erase = trace.view.body)
    (argTypeErasure : argType.erase = trace.argType)
    (hf : ModelsType M Γ f (.forallE trace.view.name A B trace.view.binderInfo v))
    (ha : ModelsType M Γ a argType)
    (guard : psKernelExprEq trace.argType trace.view.domain = true →
      checkRegimes argType A = true)
    (conversion : defeq (applicationEqContext trace.entered a.erase)
      trace.argState trace.argType trace.view.domain = .ok (true, next) →
      ModelsEqual M Γ argType A)
    (hfValid : ∀ ρ, Satisfies M Γ ρ → AnnotationValid M ρ f ∧ FunctionValid M ρ f)
    (haValid : ∀ ρ, Satisfies M Γ ρ → AnnotationValid M ρ a ∧ FunctionValid M ρ a)
    (piValid : ∀ ρ, Satisfies M Γ ρ →
      AnnotationValid M ρ (.forallE trace.view.name A B trace.view.binderInfo v) ∧
      FunctionValid M ρ (.forallE trace.view.name A B trace.view.binderInfo v)) :
    let term : AnnotatedExpr := .app f a
    let type : AnnotatedExpr := inst a B 0
    term.erase = .app f.erase a.erase ∧ type.erase = result ∧
      ModelsType M Γ term type ∧
      ∀ ρ, Satisfies M Γ ρ →
        AnnotationValid M ρ term ∧ FunctionValid M ρ term ∧
        AnnotationValid M ρ type ∧ FunctionValid M ρ type := by
  have comparison : ApplicationComparison defeq trace.entered trace.argState
      a.erase argType.erase A.erase next := by
    rw [argTypeErasure, domainErasure]
    exact trace.comparison
  have hCompare := applicationComparison_models_equal M Γ defeq trace.entered
    trace.argState next a.erase argType A comparison
    (fun h => checkRegimes_sound M argType A
      (guard (by simpa only [argTypeErasure, domainErasure] using h)))
    (fun h => conversion (by simpa only [argTypeErasure, domainErasure] using h))
  have typedArg := models_convert M Γ a argType A ha hCompare
  refine ⟨rfl, ?_, models_app_of_annotationValid M Γ trace.view.name f a A B
    trace.view.binderInfo v hf typedArg (fun ρ hρ => (piValid ρ hρ).1), ?_⟩
  · rw [erase_instantiate1, bodyErasure]
    exact trace.resultEq.symm
  · intro ρ hρ
    have fValid := hfValid ρ hρ
    have aValid := haValid ρ hρ
    have pValid := piValid ρ hρ
    refine ⟨⟨fValid.1, aValid.1⟩,
      functionValid_app_of_type M ρ trace.view.name f a A B trace.view.binderInfo v
        fValid.2 aValid.2 (hf ρ hρ) (typedArg ρ hρ) pValid.1,
      ?_, ?_⟩
    · exact annotationValid_inst_zero M B a ρ aValid.1
        (pValid.1.2.1 _ (typedArg ρ hρ))
    · exact functionValid_inst_zero M B a ρ aValid.2
        (pValid.2.2 _ (typedArg ρ hρ))

end PsKernelSemantics.Reference
