import Ps.KernelCore.Metatheory.SemanticReferenceBinders

/-!
Sort evidence is extracted only where the executable checks for a sort.
In particular these lemmas do not assert that every inferred type has a sort.
-/
namespace PsKernelSemantics.Reference

theorem ensureSort_result_sources (whnf : InferOperation)
    (c : PsKernelCheckerContext) (s next : PsKernelCheckerState)
    (input : PsKernelExpr) (level : PsKernelLevel)
    (run : psKernelEnsureSortWith whnf c s input = .ok (level, next)) :
    (input = .sort level ∧ next = s) ∨
      whnf c s input = .ok (.sort level, next) := by
  unfold psKernelEnsureSortWith at run
  split at run
  · simp only [Except.ok.injEq, Prod.mk.injEq] at run
    obtain ⟨rfl, rfl⟩ := run
    exact Or.inl ⟨rfl, rfl⟩
  · cases hw : whnf c s input with
    | error error =>
        simp only [hw] at run
        cases run
    | ok pair =>
        rcases pair with ⟨reduced, state⟩
        simp only [hw] at run
        split at run
        · simp only [Except.ok.injEq, Prod.mk.injEq] at run
          obtain ⟨rfl, rfl⟩ := run
          exact Or.inr hw
        · cases run

open ConLeche ConLeche.SetTheory ConLeche.SetModel SetModel AnnotatedExpr
universe w
variable {V : Type w} [SetTheory V]

private theorem interp_of_sort_erasure (M : Reading V) (A : AnnotatedExpr)
    (level : PsKernelLevel) (he : A.erase = .sort level) (ρ : Nat → V) :
    interp M ρ A = univ (M.level level) := by
  cases A <;> simp [erase] at he
  rename_i l
  cases he
  rfl

/-- Infer evidence plus the actual sort-exposure call establishes the sort
fact needed by annotation validity. Reduction's local semantic obligation
remains explicit; no global checker-correctness premise is hidden. -/
theorem ensureSort_models_type
    (M : Reading V) (Γ : List AnnotatedExpr)
    (whnf : InferOperation) (c : PsKernelCheckerContext)
    (s next : PsKernelCheckerState) (e A : AnnotatedExpr)
    (level : PsKernelLevel)
    (typed : ModelsType M Γ e A)
    (run : psKernelEnsureSortWith whnf c s A.erase = .ok (level, next))
    (reduction : whnf c s A.erase = .ok (.sort level, next) →
      ModelsEqual M Γ A (.sort level)) :
    ModelsType M Γ e (.sort level) := by
  rcases ensureSort_result_sources whnf c s next A.erase level run with fast | slow
  · intro ρ hρ
    have h := typed ρ hρ
    rw [interp_of_sort_erasure M A level fast.1 ρ] at h
    exact h
  · exact models_convert M Γ e A (.sort level) typed (reduction slow)

/-- Transfer a verified opened-body sort back across the exact production
fresh-variable opening. This is the valuation/frame step needed at forall. -/
theorem opened_sort_to_bound_sort (M : Reading V) (Γ : List AnnotatedExpr)
    (A B : AnnotatedExpr) (name : PsKernelName) (v : PsKernelLevel)
    (fresh : Fresh name B)
    (checked : ∀ ρ, Satisfies M Γ ρ → ∀ x, x ∈ˢ interp M ρ A →
      interp (M.withFree name x) ρ (inst (.fvar name) B 0) ∈ˢ
        (univ (M.level v) : V)) :
    ModelsType M (A :: Γ) B (.sort v) := by
  intro σ hσ
  let ρ : Nat → V := fun i => σ (i + 1)
  have hρ : Satisfies M Γ ρ := hσ.1
  have hx : σ 0 ∈ˢ interp M ρ A := hσ.2
  have h := checked ρ hρ (σ 0) hx
  rw [interp_inst_zero] at h
  have hn : psKernelNameEq name name = true :=
    psKernelNameEq_refl_of_string_law (fun s => by simp [psKernelStringEq]) name
  simp only [interp, Reading.withFree, hn, ite_true] at h
  change interp (M.withFree name (σ 0)) (extend (σ 0) ρ) B ∈ˢ
    univ (M.level v) at h
  rw [interp_withFree_fresh M B name fresh (σ 0)] at h
  have hσ' : extend (σ 0) ρ = σ := by
    funext i
    cases i <;> rfl
  rw [hσ'] at h
  exact h


theorem ensureSort_mem (M : Reading V) (ρ : Nat → V)
    (whnf : InferOperation) (c : PsKernelCheckerContext)
    (s next : PsKernelCheckerState) (e A : AnnotatedExpr) (level : PsKernelLevel)
    (typed : interp M ρ e ∈ˢ interp M ρ A)
    (run : psKernelEnsureSortWith whnf c s A.erase = .ok (level, next))
    (reduction : whnf c s A.erase = .ok (.sort level, next) →
      interp M ρ A = univ (M.level level)) :
    interp M ρ e ∈ˢ (univ (M.level level) : V) := by
  rcases ensureSort_result_sources whnf c s next A.erase level run with fast | slow
  · rwa [interp_of_sort_erasure M A level fast.1 ρ] at typed
  · rwa [reduction slow] at typed

/-- Discharge the product's annotation and typing from the actual domain/body
visits, including the checker's fresh local name. Recursive inference supplies
membership at its returned type; WHNF supplies meaning preservation only at
the sort exposure sites. All these local induction obligations are explicit. -/
theorem forall_trace_model_from_visits
    (M : Reading V) (Γ : List AnnotatedExpr)
    (remaining : Nat) (whnf : InferOperation) (defeq : DefEqOperation)
    (c : PsKernelCheckerContext) (s next : PsKernelCheckerState)
    (n : PsKernelName) (A B U W : AnnotatedExpr) (bi : PsKernelBinderInfo)
    (result : PsKernelExpr) (io : Bool)
    (trace : ForallTrace remaining whnf defeq c s n A.erase B.erase bi io result next)
    (domainType : U.erase = trace.domainType)
    (bodyType : W.erase = trace.bodyType)
    (fresh : Fresh (psKernelCheckerStateFreshName trace.domainSortState n).1 B)
    (domainTyped : ModelsType M Γ A U)
    (domainValid : ∀ ρ, Satisfies M Γ ρ → AnnotationValid M ρ A)
    (domainReduction : ∀ ρ, Satisfies M Γ ρ →
      whnf trace.entered trace.domainState trace.domainType =
        .ok (.sort trace.domainLevel, trace.domainSortState) →
      interp M ρ U = univ (M.level trace.domainLevel))
    (bodyTyped : ∀ ρ, Satisfies M Γ ρ → ∀ x, x ∈ˢ interp M ρ A →
      interp (M.withFree (psKernelCheckerStateFreshName trace.domainSortState n).1 x) ρ
        (inst (.fvar (psKernelCheckerStateFreshName trace.domainSortState n).1) B 0) ∈ˢ
      interp (M.withFree (psKernelCheckerStateFreshName trace.domainSortState n).1 x) ρ W)
    (bodyValid : ∀ ρ, Satisfies M Γ ρ → ∀ x, x ∈ˢ interp M ρ A →
      AnnotationValid
        (M.withFree (psKernelCheckerStateFreshName trace.domainSortState n).1 x) ρ
        (inst (.fvar (psKernelCheckerStateFreshName trace.domainSortState n).1) B 0))
    (bodyReduction : ∀ ρ, Satisfies M Γ ρ → ∀ x, x ∈ˢ interp M ρ A →
      whnf (binderChild trace.entered trace.domainSortState n A.erase bi)
          trace.bodyState trace.bodyType = .ok (.sort trace.rangeLevel, trace.bodySortState) →
      interp (M.withFree (psKernelCheckerStateFreshName trace.domainSortState n).1 x) ρ W =
        univ (M.level trace.rangeLevel)) :
    ∃ term type : AnnotatedExpr,
      term.erase = .forallE n A.erase B.erase bi ∧ type.erase = result ∧
      ModelsType M Γ term type ∧
      (∀ ρ, Satisfies M Γ ρ → AnnotationValid M ρ term) := by
  have hA : ModelsType M Γ A (.sort trace.domainLevel) := by
    intro ρ hρ
    apply ensureSort_mem M ρ whnf trace.entered trace.domainState trace.domainSortState
      A U trace.domainLevel (domainTyped ρ hρ)
    · simpa only [domainType] using trace.domainSortRun
    · intro hr
      exact domainReduction ρ hρ (by simpa only [domainType] using hr)
  have hB : ModelsType M (A :: Γ) B (.sort trace.rangeLevel) := by
    apply opened_sort_to_bound_sort M Γ A B
      (psKernelCheckerStateFreshName trace.domainSortState n).1 trace.rangeLevel fresh
    intro ρ hρ x hx
    apply ensureSort_mem
      (M.withFree (psKernelCheckerStateFreshName trace.domainSortState n).1 x) ρ whnf
      (binderChild trace.entered trace.domainSortState n A.erase bi)
      trace.bodyState trace.bodySortState
      (inst (.fvar (psKernelCheckerStateFreshName trace.domainSortState n).1) B 0)
      W trace.rangeLevel (bodyTyped ρ hρ x hx)
    · simpa only [bodyType] using trace.bodySortRun
    · intro hr
      exact bodyReduction ρ hρ x hx (by simpa only [bodyType] using hr)
  have hvalid : ∀ σ, Satisfies M (A :: Γ) σ → AnnotationValid M σ B := by
    intro σ hσ
    let ρ : Nat → V := fun i => σ (i + 1)
    have opened := bodyValid ρ hσ.1 (σ 0) hσ.2
    have bound := (annotationValid_open_fresh M B
      (psKernelCheckerStateFreshName trace.domainSortState n).1 fresh (σ 0) ρ).mp opened
    have he : extend (σ 0) ρ = σ := by funext i; cases i <;> rfl
    simpa only [he] using bound
  exact forall_trace_has_model M Γ remaining whnf defeq c s next n A B bi result io
    trace hA hB domainValid hvalid

end PsKernelSemantics.Reference
