import Ps.KernelCore.Metatheory.SemanticReferenceLambda
import Ps.KernelCore.Metatheory.SemanticReferenceSortChecks

/-!
Checked lambda annotations are chosen from the actual codomain sort visit.
No arbitrary annotation or proof-valued-fibre premise is supplied here.
The remaining premises are the local induction obligations at recorded
recursive calls, plus scope/freshness and hereditary validity.
-/
namespace PsKernelSemantics.Reference
open ConLeche ConLeche.SetTheory ConLeche.SetModel SetModel AnnotatedExpr
universe w
variable {V : Type w} [SetTheory V]

theorem lambda_trace_codomain_sort
    (M : Reading V) (Γ : List AnnotatedExpr)
    (remaining : Nat) (whnf : InferOperation) (defeq : DefEqOperation)
    (c : PsKernelCheckerContext) (s next : PsKernelCheckerState)
    (n : PsKernelName) (A b U T : AnnotatedExpr) (bi : PsKernelBinderInfo)
    (result : PsKernelExpr)
    (trace : LambdaTrace remaining whnf defeq c s n A.erase b.erase bi result next)
    (hT : T.erase = trace.typeOfBodyType)
    (typeTyped : ∀ ρ, Satisfies M Γ ρ → ∀ x, x ∈ˢ interp M ρ A →
      interp (M.withFree (psKernelCheckerStateFreshName trace.domainSortState n).1 x) ρ U ∈ˢ
        interp (M.withFree (psKernelCheckerStateFreshName trace.domainSortState n).1 x) ρ T)
    (typeReduction : ∀ ρ, Satisfies M Γ ρ → ∀ x, x ∈ˢ interp M ρ A →
      whnf (binderChild trace.entered trace.domainSortState n A.erase bi)
        trace.typeState trace.typeOfBodyType =
          .ok (.sort trace.codomainLevel, trace.codomainState) →
      interp (M.withFree (psKernelCheckerStateFreshName trace.domainSortState n).1 x) ρ T =
        univ (M.level trace.codomainLevel)) :
    ∀ ρ, Satisfies M Γ ρ → ∀ x, x ∈ˢ interp M ρ A →
      interp (M.withFree (psKernelCheckerStateFreshName trace.domainSortState n).1 x) ρ U ∈ˢ
        (univ (M.level trace.codomainLevel) : V) := by
  intro ρ hρ x hx
  apply ensureSort_mem
    (M.withFree (psKernelCheckerStateFreshName trace.domainSortState n).1 x) ρ
    whnf (binderChild trace.entered trace.domainSortState n A.erase bi)
    trace.typeState trace.codomainState U T trace.codomainLevel
    (typeTyped ρ hρ x hx)
  · simpa only [hT] using trace.codomainSortRun
  · intro run
    exact typeReduction ρ hρ x hx (by simpa only [hT] using run)

/-- The specific lambda and returned-type readings share the level produced
by execution. All four hereditary facts and typing concern these same readings,
rather than separate existential annotations that need not agree. -/
theorem lambda_trace_checked_reading
    (M : Reading V) (Γ : List AnnotatedExpr)
    (remaining : Nat) (whnf : InferOperation) (defeq : DefEqOperation)
    (c : PsKernelCheckerContext) (s next : PsKernelCheckerState)
    (n : PsKernelName) (A b U T : AnnotatedExpr) (bi : PsKernelBinderInfo)
    (result : PsKernelExpr)
    (trace : LambdaTrace remaining whnf defeq c s n A.erase b.erase bi result next)
    (hU : U.erase = trace.bodyType) (hT : T.erase = trace.typeOfBodyType)
    (scopedU : U.Scoped 0)
    (fresh : Fresh (psKernelCheckerStateFreshName trace.domainSortState n).1 b)
    (domainValid : ∀ ρ, Satisfies M Γ ρ →
      AnnotationValid M ρ A ∧ FunctionValid M ρ A)
    (bodyTyped : ∀ ρ, Satisfies M Γ ρ → ∀ x, x ∈ˢ interp M ρ A →
      interp (M.withFree (psKernelCheckerStateFreshName trace.domainSortState n).1 x)
          ρ (inst (.fvar (psKernelCheckerStateFreshName trace.domainSortState n).1) b 0) ∈ˢ
        interp (M.withFree (psKernelCheckerStateFreshName trace.domainSortState n).1 x) ρ U)
    (bodyValid : ∀ ρ, Satisfies M Γ ρ → ∀ x, x ∈ˢ interp M ρ A →
      AnnotationValid (M.withFree (psKernelCheckerStateFreshName trace.domainSortState n).1 x)
          ρ (inst (.fvar (psKernelCheckerStateFreshName trace.domainSortState n).1) b 0) ∧
      FunctionValid (M.withFree (psKernelCheckerStateFreshName trace.domainSortState n).1 x)
          ρ (inst (.fvar (psKernelCheckerStateFreshName trace.domainSortState n).1) b 0))
    (typeValid : ∀ ρ, Satisfies M Γ ρ → ∀ x, x ∈ˢ interp M ρ A →
      AnnotationValid (M.withFree (psKernelCheckerStateFreshName trace.domainSortState n).1 x) ρ U ∧
      FunctionValid (M.withFree (psKernelCheckerStateFreshName trace.domainSortState n).1 x) ρ U)
    (typeTyped : ∀ ρ, Satisfies M Γ ρ → ∀ x, x ∈ˢ interp M ρ A →
      interp (M.withFree (psKernelCheckerStateFreshName trace.domainSortState n).1 x) ρ U ∈ˢ
        interp (M.withFree (psKernelCheckerStateFreshName trace.domainSortState n).1 x) ρ T)
    (typeReduction : ∀ ρ, Satisfies M Γ ρ → ∀ x, x ∈ˢ interp M ρ A →
      whnf (binderChild trace.entered trace.domainSortState n A.erase bi)
        trace.typeState trace.typeOfBodyType =
          .ok (.sort trace.codomainLevel, trace.codomainState) →
      interp (M.withFree (psKernelCheckerStateFreshName trace.domainSortState n).1 x) ρ T =
        univ (M.level trace.codomainLevel)) :
    let name := (psKernelCheckerStateFreshName trace.domainSortState n).1
    let term := AnnotatedExpr.lam n A b bi trace.codomainLevel
    let type := AnnotatedExpr.forallE n A (close name U 0) bi trace.codomainLevel
    term.erase = .lam n A.erase b.erase bi ∧ type.erase = result ∧
      ModelsType M Γ term type ∧
      ∀ ρ, Satisfies M Γ ρ →
        AnnotationValid M ρ term ∧ FunctionValid M ρ term ∧
        AnnotationValid M ρ type ∧ FunctionValid M ρ type := by
  let name := (psKernelCheckerStateFreshName trace.domainSortState n).1
  have sortTyped := lambda_trace_codomain_sort M Γ remaining whnf defeq c s next
    n A b U T bi result trace hT typeTyped typeReduction
  have opened (ρ : Nat → V) (x : V) :
      interp (M.withFree name x) ρ (inst (.fvar name) b 0) =
        interp M (extend x ρ) b := by
    rw [interp_inst_zero]
    have hn : psKernelNameEq name name = true :=
      psKernelNameEq_refl_of_string_law (fun s => by simp [psKernelStringEq]) name
    change interp (M.withFree name x)
      (extend (if psKernelNameEq name name then x else M.freeVars name) ρ) b = _
    simp only [hn, ite_true]
    exact interp_withFree_fresh M b name fresh x (extend x ρ)
  have typed (ρ : Nat → V) (hρ : Satisfies M Γ ρ)
      (x : V) (hx : x ∈ˢ interp M ρ A) :
      interp M (extend x ρ) b ∈ˢ interp M (extend x ρ) (close name U 0) := by
    rw [abstractFVar_closed_input M U name scopedU ρ x, ← opened ρ x]
    exact bodyTyped ρ hρ x hx
  have truth (ρ : Nat → V) (hρ : Satisfies M Γ ρ)
      (hz : M.level trace.codomainLevel = 0)
      (x : V) (hx : x ∈ˢ interp M ρ A) :
      interp M (extend x ρ) (close name U 0) ∈ˢ (univ 0 : V) := by
    rw [abstractFVar_closed_input M U name scopedU ρ x]
    simpa only [hz] using sortTyped ρ hρ x hx
  refine ⟨rfl, ?_, ?_, ?_⟩
  · change PsKernelExpr.forallE n A.erase (close name U 0).erase bi = result
    rw [erase_abstractFVar, hU]
    exact trace.resultEq.symm
  · intro ρ hρ
    exact lamR_mem (typed ρ hρ)
  · intro ρ hρ
    have termAV : AnnotationValid M ρ (.lam n A b bi trace.codomainLevel) := by
      refine ⟨(domainValid ρ hρ).1, ?_⟩
      intro x hx
      exact (annotationValid_open_fresh M b name fresh x ρ).mp (bodyValid ρ hρ x hx).1
    have termFV : FunctionValid M ρ (.lam n A b bi trace.codomainLevel) := by
      refine ⟨(domainValid ρ hρ).2, ?_,
        (fun x => interp M (extend x ρ) (close name U 0)), typed ρ hρ, truth ρ hρ⟩
      intro x hx
      exact (functionValid_open_fresh M b name fresh x ρ).mp (bodyValid ρ hρ x hx).2
    have typeAV : AnnotationValid M ρ
        (.forallE n A (close name U 0) bi trace.codomainLevel) := by
      refine ⟨(domainValid ρ hρ).1, ?_, truth ρ hρ⟩
      intro x hx
      exact (annotationValid_abstractFVar M U name scopedU ρ x).mpr
        (typeValid ρ hρ x hx).1
    have typeFV : FunctionValid M ρ
        (.forallE n A (close name U 0) bi trace.codomainLevel) := by
      refine ⟨(domainValid ρ hρ).2, ?_⟩
      intro x hx
      exact (functionValid_abstractFVar M U name scopedU ρ x).mpr
        (typeValid ρ hρ x hx).2
    exact ⟨termAV, termFV, typeAV, typeFV⟩

end PsKernelSemantics.Reference
