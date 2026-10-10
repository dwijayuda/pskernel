import Ps.KernelCore.Metatheory.SemanticInterpretation

/-!
Dependent contexts and sound semantic rules. These are derived facts about the
set interpretation, not a claim that PSKernel's checker produces their premises.
They provide concrete targets for checked inference and valid-input contracts.
-/

namespace PsKernelSemantics.SetModel

open ConLeche ConLeche.SetTheory ConLeche.SetModel
open AnnotatedExpr

universe u
variable {V : Type u} [SetTheory V]

/-- Types in a context are expressed in the tail context, before their binder. -/
def Satisfies (M : Reading V) : List AnnotatedExpr → (Nat → V) → Prop
  | [], _ => True
  | A :: Γ, ρ =>
      Satisfies M Γ (fun i => ρ (i + 1)) ∧
      ρ 0 ∈ˢ interp M (fun i => ρ (i + 1)) A

theorem satisfies_extend (M : Reading V) (Γ : List AnnotatedExpr)
    (A : AnnotatedExpr) (ρ : Nat → V) (x : V)
    (hΓ : Satisfies M Γ ρ) (hx : x ∈ˢ interp M ρ A) :
    Satisfies M (A :: Γ) (extend x ρ) := ⟨hΓ, hx⟩

/-- Semantic typing quantifies over every satisfying valuation. An inconsistent
context may have no satisfying valuation; closed consistency uses the empty
context, whose explicit valuation is constructed below. -/
def ModelsType (M : Reading V) (Γ : List AnnotatedExpr) (e A : AnnotatedExpr) : Prop :=
  ∀ ρ, Satisfies M Γ ρ → interp M ρ e ∈ˢ interp M ρ A

def ModelsEqual (M : Reading V) (Γ : List AnnotatedExpr) (e f : AnnotatedExpr) : Prop :=
  ∀ ρ, Satisfies M Γ ρ → interp M ρ e = interp M ρ f

theorem models_sort (M : Reading V) (Γ : List AnnotatedExpr) (l : PsKernelLevel) :
    ModelsType M Γ (.sort l) (.sort (.succ l)) :=
  fun _ _ => univ_mem_univ (M.level l)

theorem models_forall (M : Reading V) (Γ : List AnnotatedExpr)
    (n : PsKernelName) (A B : AnnotatedExpr) (bi : PsKernelBinderInfo)
    (u v : PsKernelLevel)
    (hA : ModelsType M Γ A (.sort u))
    (hB : ModelsType M (A :: Γ) B (.sort v)) :
    ModelsType M Γ (.forallE n A B bi v) (.sort (.imax u v)) := by
  intro ρ hρ
  exact pi_mem_sort (hA ρ hρ)
    (fun x hx => hB (extend x ρ) (satisfies_extend M Γ A ρ x hρ hx))

theorem models_lam (M : Reading V) (Γ : List AnnotatedExpr)
    (n : PsKernelName) (A b B : AnnotatedExpr) (bi : PsKernelBinderInfo)
    (v : PsKernelLevel) (hb : ModelsType M (A :: Γ) b B) :
    ModelsType M Γ (.lam n A b bi v) (.forallE n A B bi v) := by
  intro ρ hρ
  exact lamR_mem (fun x hx => hb (extend x ρ) (satisfies_extend M Γ A ρ x hρ hx))

theorem models_app (M : Reading V) (Γ : List AnnotatedExpr)
    (n : PsKernelName) (f a A B : AnnotatedExpr) (bi : PsKernelBinderInfo)
    (v : PsKernelLevel)
    (hf : ModelsType M Γ f (.forallE n A B bi v))
    (ha : ModelsType M Γ a A)
    (hB : ModelsType M (A :: Γ) B (.sort v)) :
    ModelsType M Γ (.app f a) (inst a B 0) := by
  intro ρ hρ
  rw [interp_inst_zero]
  exact application_mem (hf ρ hρ) (ha ρ hρ)
    (fun x hx => hB (extend x ρ) (satisfies_extend M Γ A ρ x hρ hx))

theorem models_let (M : Reading V) (Γ : List AnnotatedExpr)
    (n : PsKernelName) (A a b B : AnnotatedExpr) (nd : Bool)
    (ha : ModelsType M Γ a A) (hb : ModelsType M (A :: Γ) b B) :
    ModelsType M Γ (.letE n A a b nd) (inst a B 0) := by
  intro ρ hρ
  rw [interp_inst_zero]
  exact hb _ (satisfies_extend M Γ A ρ (interp M ρ a) hρ (ha ρ hρ))

theorem models_convert (M : Reading V) (Γ : List AnnotatedExpr)
    (e A B : AnnotatedExpr)
    (he : ModelsType M Γ e A) (hAB : ModelsEqual M Γ A B) :
    ModelsType M Γ e B := by
  intro ρ hρ
  rw [← hAB ρ hρ]
  exact he ρ hρ

/-- Both actual terms must inhabit the proposition being compared. -/
theorem models_proof_irrelevance (M : Reading V) (Γ : List AnnotatedExpr)
    (a b P : AnnotatedExpr)
    (hP : ModelsType M Γ P (.sort .zero))
    (ha : ModelsType M Γ a P) (hb : ModelsType M Γ b P) :
    ModelsEqual M Γ a b := by
  intro ρ hρ
  exact (mem_univ_zero (hP ρ hρ) (ha ρ hρ)).trans
    (mem_univ_zero (hP ρ hρ) (hb ρ hρ)).symm

/-- A beta theorem with the validity premises that the actual kernel bridge
must establish; no blanket subject-reduction assumption is used. -/
theorem models_beta (M : Reading V) (Γ : List AnnotatedExpr)
    (n : PsKernelName) (A a b B : AnnotatedExpr) (bi : PsKernelBinderInfo)
    (v : PsKernelLevel)
    (ha : ModelsType M Γ a A)
    (hb : ModelsType M (A :: Γ) b B)
    (hB : ModelsType M (A :: Γ) B (.sort v)) :
    ModelsEqual M Γ (.app (.lam n A b bi v) a) (inst a b 0) := by
  intro ρ hρ
  rw [interp_inst_zero]
  exact beta (ha ρ hρ)
    (fun x hx => hb (extend x ρ) (satisfies_extend M Γ A ρ x hρ hx))
    (fun x hx => hB (extend x ρ) (satisfies_extend M Γ A ρ x hρ hx))

theorem models_zeta (M : Reading V) (Γ : List AnnotatedExpr)
    (n : PsKernelName) (A a b : AnnotatedExpr) (nd : Bool) :
    ModelsEqual M Γ (.letE n A a b nd) (inst a b 0) := by
  intro ρ _
  exact (interp_inst_zero M b a ρ).symm

theorem models_eta (M : Reading V) (Γ : List AnnotatedExpr)
    (n : PsKernelName) (A f B : AnnotatedExpr) (bi : PsKernelBinderInfo)
    (v : PsKernelLevel) (hf : ModelsType M Γ f (.forallE n A B bi v)) :
    ModelsEqual M Γ (.lam n A (.app (liftN 1 f 0) (.bvar 0)) bi v) f := by
  intro ρ hρ
  have hshift (x : V) : shift 1 0 (extend x ρ) = ρ := by
    funext i; simp [shift, extend]
  simp only [interp, interp_liftN, hshift]
  exact eta (hf ρ hρ)

theorem models_weaken (M : Reading V) (Γ : List AnnotatedExpr)
    (e A B : AnnotatedExpr) (h : ModelsType M Γ e A) :
    ModelsType M (B :: Γ) (liftN 1 e 0) (liftN 1 A 0) := by
  intro ρ hρ
  simp only [interp_liftN]
  have hs : shift 1 0 ρ = fun i => ρ (i + 1) := by funext i; simp [shift]
  rw [hs]
  exact h _ hρ.1

/-- Real empty-context valuation, rather than consistency by an empty context
interpretation. This construction relies only on the explicit set foundation. -/
theorem empty_context_satisfiable (M : Reading V) :
    ∃ ρ : Nat → V, Satisfies M [] ρ :=
  ⟨fun _ => empty, True.intro⟩

theorem no_closed_empty_type (M : Reading V) (e A : AnnotatedExpr)
    (hA : ∀ ρ, interp M ρ A = (empty : V)) :
    ¬ ModelsType M [] e A := by
  intro he
  obtain ⟨ρ, hρ⟩ := empty_context_satisfiable M
  have hm := he ρ hρ
  rw [hA ρ] at hm
  exact not_mem_empty _ hm

/-- A concrete closed contradictory type, expressed in PSKernel's syntax. -/
def allProps : AnnotatedExpr :=
  .forallE .anonymous (.sort .zero) (.bvar 0) .default .zero

theorem no_closed_allProps (M : Reading V) (e : AnnotatedExpr) :
    ¬ ModelsType M [] e allProps := by
  intro he
  have hm := he (fun _ => empty) True.intro
  exact no_proof_of_all_props ⟨_, hm⟩

end PsKernelSemantics.SetModel
