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
  · rename_i u he
    simp only [Except.ok.injEq, Prod.mk.injEq] at run
    exact Or.inl ⟨he.trans (congrArg PsKernelExpr.sort run.1), run.2.symm⟩
  · cases hw : whnf c s input with
    | error error =>
        simp only [hw] at run
        cases run
    | ok pair =>
        rcases pair with ⟨reduced, state⟩
        simp only [hw] at run
        split at run
        · rename_i u he
          simp only [Except.ok.injEq, Prod.mk.injEq] at run
          obtain ⟨rfl, rfl⟩ := run
          exact Or.inr (by simpa only [he] using hw)
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
  rw [interp_withFree_fresh M B name fresh (σ 0)] at h
  have hσ' : extend (σ 0) ρ = σ := by
    funext i
    cases i <;> rfl
  rw [hσ'] at h
  exact h

end PsKernelSemantics.Reference
