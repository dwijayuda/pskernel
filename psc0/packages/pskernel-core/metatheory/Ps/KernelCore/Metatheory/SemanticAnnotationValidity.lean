import Ps.KernelCore.Metatheory.SemanticUniverseSubstitution
import Ps.KernelCore.Metatheory.SemanticAbstraction

/-!
Hereditary validity of the proposition bit on dependent products.
This supplies the extra semantic condition required by impredicative application.
It is not complete term validity, uniqueness of readings, or a checker theorem:
lambda fibre typing and application-domain membership remain separate.

The predicate and transport proofs cover every PSKernel expression constructor.
No "every inferred type has a sort" metatheorem is assumed.
-/
namespace PsKernelSemantics.SetModel
open ConLeche ConLeche.SetTheory ConLeche.SetModel AnnotatedExpr
universe u
variable {V : Type u} [SetTheory V]

def AnnotationValid (M : Reading V) : (Nat → V) → AnnotatedExpr → Prop
  | ρ, .forallE _ A B _ v =>
      AnnotationValid M ρ A ∧
      (∀ x, x ∈ˢ interp M ρ A → AnnotationValid M (extend x ρ) B) ∧
      (M.level v = 0 → ∀ x, x ∈ˢ interp M ρ A →
        interp M (extend x ρ) B ∈ˢ (univ 0 : V))
  | ρ, .lam _ A b _ _ =>
      AnnotationValid M ρ A ∧
      ∀ x, x ∈ˢ interp M ρ A → AnnotationValid M (extend x ρ) b
  | ρ, .app f a => AnnotationValid M ρ f ∧ AnnotationValid M ρ a
  | ρ, .letE _ A a b _ =>
      AnnotationValid M ρ A ∧ AnnotationValid M ρ a ∧
      AnnotationValid M (extend (interp M ρ a) ρ) b
  | ρ, .mdata _ e | ρ, .proj _ _ e => AnnotationValid M ρ e
  | _, _ => True

/-- The actual codomain sort fact discharges the product's proposition bit. -/
theorem annotationValid_forall_of_sort (M : Reading V) (ρ : Nat → V)
    (n : PsKernelName) (A B : AnnotatedExpr) (bi : PsKernelBinderInfo)
    (v : PsKernelLevel)
    (hA : AnnotationValid M ρ A)
    (hB : ∀ x, x ∈ˢ interp M ρ A → AnnotationValid M (extend x ρ) B)
    (hSort : ∀ x, x ∈ˢ interp M ρ A →
      interp M (extend x ρ) B ∈ˢ (univ (M.level v) : V)) :
    AnnotationValid M ρ (.forallE n A B bi v) := by
  refine ⟨hA, hB, ?_⟩
  intro hz x hx
  simpa only [hz] using hSort x hx

theorem annotationValid_liftN (M : Reading V) (e : AnnotatedExpr)
    (amount cut : Nat) (ρ : Nat → V) :
    AnnotationValid M ρ (liftN amount e cut) ↔
      AnnotationValid M (shift amount cut ρ) e := by
  induction e generalizing cut ρ with
  | bvar _ | fvar _ | mvar _ | sort _ | const _ _ | lit _ => rfl
  | app f a ihf iha =>
      simp only [liftN, AnnotationValid, ihf, iha]
  | lam n A b bi v ihA ihb =>
      simp only [liftN, AnnotationValid, ihA, interp_liftN, ihb, ← extend_shift]
  | forallE n A B bi v ihA ihB =>
      simp only [liftN, AnnotationValid, ihA, interp_liftN, ihB, ← extend_shift]
  | letE n A a b nd ihA iha ihb =>
      simp only [liftN, AnnotationValid, ihA, iha, interp_liftN, ihb, ← extend_shift]
  | mdata _ e ih | proj _ _ e ih => exact ih cut ρ

/-- Substitution preserves hereditary annotation validity when the substituted
argument itself is valid and the body is valid at its inserted value. -/
theorem annotationValid_inst (M : Reading V) (e a : AnnotatedExpr)
    (cut : Nat) (ρ : Nat → V)
    (ha : AnnotationValid M (shift cut 0 ρ) a)
    (he : AnnotationValid M
      (insert cut (interp M (shift cut 0 ρ) a) ρ) e) :
    AnnotationValid M ρ (inst a e cut) := by
  induction e generalizing cut ρ with
  | bvar i =>
      by_cases h : i < cut
      · simp [inst, h, AnnotationValid]
      · by_cases hi : i = cut
        · simp only [inst, hi, Nat.lt_irrefl, ite_false, ite_true]
          exact (annotationValid_liftN M a cut 0 ρ).mpr ha
        · simp [inst, h, hi, AnnotationValid]
  | fvar _ | mvar _ | sort _ | const _ _ | lit _ => trivial
  | app f b ihf ihb =>
      exact ⟨ihf cut ρ ha he.1, ihb cut ρ ha he.2⟩
  | lam n A b bi v ihA ihb =>
      refine ⟨ihA cut ρ ha he.1, ?_⟩
      intro x hx
      rw [interp_inst] at hx
      apply ihb (cut + 1) (extend x ρ)
      · simpa only [shift_extend] using ha
      · simpa only [shift_extend, ← extend_insert] using he.2 x hx
  | forallE n A B bi v ihA ihB =>
      refine ⟨ihA cut ρ ha he.1, ?_, ?_⟩
      · intro x hx
        rw [interp_inst] at hx
        apply ihB (cut + 1) (extend x ρ)
        · simpa only [shift_extend] using ha
        · simpa only [shift_extend, ← extend_insert] using he.2.1 x hx
      · intro hz x hx
        rw [interp_inst] at hx
        rw [interp_inst, shift_extend, ← extend_insert]
        exact he.2.2 hz x hx
  | letE n A b c nd ihA ihb ihc =>
      refine ⟨ihA cut ρ ha he.1, ihb cut ρ ha he.2.1, ?_⟩
      apply ihc (cut + 1) (extend (interp M ρ (inst a b cut)) ρ)
      · simpa only [shift_extend] using ha
      · simpa only [shift_extend, ← extend_insert, interp_inst] using he.2.2
  | mdata _ e ih | proj _ _ e ih => exact ih cut ρ ha he

theorem annotationValid_inst_zero (M : Reading V) (e a : AnnotatedExpr)
    (ρ : Nat → V) (ha : AnnotationValid M ρ a)
    (he : AnnotationValid M (extend (interp M ρ a) ρ) e) :
    AnnotationValid M ρ (inst a e 0) := by
  have hs : shift 0 0 ρ = ρ := by funext i; simp [shift]
  apply annotationValid_inst M e a 0 ρ
  · simpa only [hs] using ha
  · simpa only [hs, insert_zero] using he

/-- Symbolic binder annotations travel with their actual universe substitution. -/
theorem annotationValid_instLevels (M : Reading V) (e : AnnotatedExpr)
    (names : List PsKernelName) (values : List PsKernelLevel) (ρ : Nat → V) :
    AnnotationValid M ρ (instLevels names values e) ↔
      AnnotationValid (M.substLevels names values) ρ e := by
  induction e generalizing ρ with
  | bvar _ | fvar _ | mvar _ | sort _ | const _ _ | lit _ => rfl
  | app f a ihf iha =>
      simp only [instLevels, AnnotationValid, ihf, iha]
  | lam n A b bi v ihA ihb =>
      simp only [instLevels, AnnotationValid, ihA, interp_instLevels, ihb]
  | forallE n A B bi v ihA ihB =>
      simp only [instLevels, AnnotationValid, ihA, interp_instLevels, ihB,
        Reading.substLevels_eval]
  | letE n A a b nd ihA iha ihb =>
      simp only [instLevels, AnnotationValid, ihA, iha, interp_instLevels, ihb]
  | mdata _ e ih | proj _ _ e ih => exact ih ρ

/-- The bad product in the existing annotation counterexample fails this
additional condition, even though it has semantic membership in a universe. -/
theorem forged_product_annotation_invalid (M : Reading V) (ρ : Nat → V) :
    ¬ AnnotationValid M ρ
      (.forallE .anonymous (.sort .zero) (.sort .zero) .default .zero) := by
  intro h
  have bad := h.2.2 rfl (empty : V) (empty_mem_univ 0)
  exact not_mem_self (univ 0 : V) bad


/-- A genuinely fresh free-variable assignment also preserves the hereditary
validity condition; this is needed when entering a production local scope. -/
theorem annotationValid_withFree_fresh (M : Reading V) (e : AnnotatedExpr)
    (name : PsKernelName) (h : Fresh name e) (x : V) (ρ : Nat → V) :
    AnnotationValid (M.withFree name x) ρ e ↔ AnnotationValid M ρ e := by
  induction e generalizing ρ with
  | bvar _ | fvar _ | mvar _ | sort _ | const _ _ | lit _ => rfl
  | app f a ihf iha =>
      simp only [AnnotationValid, ihf h.1, iha h.2]
  | lam n A b bi v ihA ihb =>
      simp only [AnnotationValid, ihA h.1,
        interp_withFree_fresh M A name h.1 x, ihb h.2]
  | forallE n A B bi v ihA ihB =>
      simp only [AnnotationValid, ihA h.1, Reading.withFree_level,
        interp_withFree_fresh M A name h.1 x, ihB h.2,
        interp_withFree_fresh M B name h.2 x]
  | letE n A a b nd ihA iha ihb =>
      simp only [AnnotationValid, ihA h.1, iha h.2.1,
        interp_withFree_fresh M a name h.2.1 x, ihb h.2.2]
  | mdata _ e ih | proj _ _ e ih => exact ih h ρ

theorem annotationValid_close (M : Reading V) (e : AnnotatedExpr)
    (name : PsKernelName) (cut : Nat) (ρ : Nat → V) :
    AnnotationValid M ρ (close name e cut) ↔
      AnnotationValid (M.withFree name (ρ cut)) ρ e := by
  induction e generalizing cut ρ with
  | bvar _ | mvar _ | sort _ | const _ _ | lit _ => rfl
  | fvar n =>
      cases h : psKernelNameEq n name <;> simp [close, h, AnnotationValid]
  | app f a ihf iha =>
      simp only [close, AnnotationValid, ihf, iha]
  | lam n A b bi v ihA ihb =>
      simp only [close, AnnotationValid, ihA, interp_close, ihb, extend]
  | forallE n A B bi v ihA ihB =>
      simp only [close, AnnotationValid, ihA, interp_close, ihB,
        Reading.withFree_level, extend]
  | letE n A a b nd ihA iha ihb =>
      simp only [close, AnnotationValid, ihA, iha, interp_close, ihb, extend]
  | mdata _ e ih | proj _ _ e ih => exact ih cut ρ

/-- Product-bit validity alone cannot replace lambda typing or coherent
readings. Both readings here satisfy this predicate but denote different sets. -/
theorem annotationValidity_alone_not_coherence (M : Reading V) (ρ : Nat → V) :
    ∃ a b : AnnotatedExpr, a.erase = b.erase ∧
      AnnotationValid M ρ a ∧ AnnotationValid M ρ b ∧
      interp M ρ a ≠ interp M ρ b := by
  let a : AnnotatedExpr :=
    .lam .anonymous (.sort .zero) (.sort .zero) .default (.succ .zero)
  let b : AnnotatedExpr :=
    .lam .anonymous (.sort .zero) (.sort .zero) .default .zero
  refine ⟨a, b, rfl, ⟨True.intro, fun _ _ => True.intro⟩,
    ⟨True.intro, fun _ _ => True.intro⟩, ?_⟩
  change lamR 1 (univ 0 : V) (fun _ => univ 0) ≠
    lamR 0 (univ 0 : V) (fun _ => univ 0)
  rw [lamR_zero]
  exact lamR_ne_pt (by decide)


/-- Application needs the proposition-bit condition on the exposed product;
it does not need a blanket theorem that its codomain has an inferred sort. -/
theorem models_app_of_annotationValid (M : Reading V) (Γ : List AnnotatedExpr)
    (n : PsKernelName) (f a A B : AnnotatedExpr) (bi : PsKernelBinderInfo)
    (v : PsKernelLevel)
    (hf : ModelsType M Γ f (.forallE n A B bi v))
    (ha : ModelsType M Γ a A)
    (hvalid : ∀ ρ, Satisfies M Γ ρ →
      AnnotationValid M ρ (.forallE n A B bi v)) :
    ModelsType M Γ (.app f a) (inst a B 0) := by
  intro ρ hρ
  rw [interp_inst_zero]
  apply app_mem_piR (hf ρ hρ) (ha ρ hρ)
  intro hz x hx
  simpa only [univ_zero] using (hvalid ρ hρ).2.2 hz x hx

/-- The same local product validity is sufficient for beta on a typed body. -/
theorem models_beta_of_annotationValid (M : Reading V) (Γ : List AnnotatedExpr)
    (n : PsKernelName) (A a b B : AnnotatedExpr) (bi : PsKernelBinderInfo)
    (v : PsKernelLevel)
    (ha : ModelsType M Γ a A)
    (hb : ModelsType M (A :: Γ) b B)
    (hvalid : ∀ ρ, Satisfies M Γ ρ →
      AnnotationValid M ρ (.forallE n A B bi v)) :
    ModelsEqual M Γ (.app (.lam n A b bi v) a) (inst a b 0) := by
  intro ρ hρ
  rw [interp_inst_zero]
  apply app_lamR (ha ρ hρ)
    (fun x hx => hb (extend x ρ) (satisfies_extend M Γ A ρ x hρ hx))
  intro hz x hx
  simpa only [univ_zero] using (hvalid ρ hρ).2.2 hz x hx

/-- Valid argument substitution also carries the hereditary annotation
condition into the dependent result type selected by application. -/
theorem application_result_annotationValid (M : Reading V) (Γ : List AnnotatedExpr)
    (n : PsKernelName) (a A B : AnnotatedExpr) (bi : PsKernelBinderInfo)
    (v : PsKernelLevel)
    (ha : ModelsType M Γ a A)
    (haValid : ∀ ρ, Satisfies M Γ ρ → AnnotationValid M ρ a)
    (hvalid : ∀ ρ, Satisfies M Γ ρ →
      AnnotationValid M ρ (.forallE n A B bi v)) :
    ∀ ρ, Satisfies M Γ ρ → AnnotationValid M ρ (inst a B 0) := by
  intro ρ hρ
  exact annotationValid_inst_zero M B a ρ (haValid ρ hρ)
    ((hvalid ρ hρ).2.1 (interp M ρ a) (ha ρ hρ))

end PsKernelSemantics.SetModel
