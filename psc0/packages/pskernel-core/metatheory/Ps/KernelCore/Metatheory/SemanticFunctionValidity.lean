import Ps.KernelCore.Metatheory.SemanticAnnotationValidity

/-!
Hereditary semantic evidence for function application and lambda reduction.

Design reference: Con Leche's kinded WellDenoted invariant
(65e74db49e89ad2bbd1e90aa4f784954db41fa3a, Semantics/WellDenoted.lean).
This is a PSKernel-owned invariant over all its annotated constructors. Only
the already-pinned pure set mathematics is imported. Projection/recursor
meaning, coherent raw readings and establishment by the whole checker remain
separate obligations; this predicate alone is not full term validity.
-/
namespace PsKernelSemantics.SetModel
open ConLeche ConLeche.SetTheory ConLeche.SetModel AnnotatedExpr
universe u
variable {V : Type u} [SetTheory V]

def FunctionValid (M : Reading V) : (Nat → V) → AnnotatedExpr → Prop
  | ρ, .forallE _ A B _ _ =>
      FunctionValid M ρ A ∧
      ∀ x, x ∈ˢ interp M ρ A → FunctionValid M (extend x ρ) B
  | ρ, .lam _ A b _ v =>
      FunctionValid M ρ A ∧
      (∀ x, x ∈ˢ interp M ρ A → FunctionValid M (extend x ρ) b) ∧
      ∃ B : V → V,
        (∀ x, x ∈ˢ interp M ρ A → interp M (extend x ρ) b ∈ˢ B x) ∧
        (M.level v = 0 → ∀ x, x ∈ˢ interp M ρ A → B x ∈ˢ (univ 0 : V))
  | ρ, .app f a =>
      FunctionValid M ρ f ∧ FunctionValid M ρ a ∧
      ∃ (v : Nat) (A : V) (B : V → V),
        interp M ρ f ∈ˢ piR v A B ∧ interp M ρ a ∈ˢ A ∧
        (v = 0 → ∀ x, x ∈ˢ A → B x ∈ˢ (univ 0 : V))
  | ρ, .letE _ A a b _ =>
      FunctionValid M ρ A ∧ FunctionValid M ρ a ∧
      FunctionValid M (extend (interp M ρ a) ρ) b
  | ρ, .mdata _ e | ρ, .proj _ _ e => FunctionValid M ρ e
  | _, _ => True

theorem functionValid_liftN (M : Reading V) (e : AnnotatedExpr)
    (amount cut : Nat) (ρ : Nat → V) :
    FunctionValid M ρ (liftN amount e cut) ↔
      FunctionValid M (shift amount cut ρ) e := by
  induction e generalizing cut ρ with
  | bvar _ | fvar _ | mvar _ | sort _ | const _ _ | lit _ => rfl
  | app f a ihf iha =>
      simp only [liftN, FunctionValid, ihf, iha, interp_liftN]
  | lam n A b bi v ihA ihb =>
      simp only [liftN, FunctionValid, ihA, interp_liftN, ihb, ← extend_shift]
  | forallE n A B bi v ihA ihB =>
      simp only [liftN, FunctionValid, ihA, interp_liftN, ihB, ← extend_shift]
  | letE n A a b nd ihA iha ihb =>
      simp only [liftN, FunctionValid, ihA, iha, interp_liftN, ihb, ← extend_shift]
  | mdata _ e ih | proj _ _ e ih => exact ih cut ρ

theorem functionValid_inst (M : Reading V) (e a : AnnotatedExpr)
    (cut : Nat) (ρ : Nat → V)
    (ha : FunctionValid M (shift cut 0 ρ) a)
    (he : FunctionValid M (insert cut (interp M (shift cut 0 ρ) a) ρ) e) :
    FunctionValid M ρ (inst a e cut) := by
  induction e generalizing cut ρ with
  | bvar i =>
      by_cases h : i < cut
      · simp [inst, h, FunctionValid]
      · by_cases hi : i = cut
        · simp only [inst, hi, Nat.lt_irrefl, ite_false, ite_true]
          exact (functionValid_liftN M a cut 0 ρ).mpr ha
        · simp [inst, h, hi, FunctionValid]
  | fvar _ | mvar _ | sort _ | const _ _ | lit _ => trivial
  | app f b ihf ihb =>
      refine ⟨ihf cut ρ ha he.1, ihb cut ρ ha he.2.1, ?_⟩
      simpa only [interp_inst] using he.2.2
  | lam n A b bi v ihA ihb =>
      refine ⟨ihA cut ρ ha he.1, ?_, ?_⟩
      · intro x hx
        rw [interp_inst] at hx
        apply ihb (cut + 1) (extend x ρ)
        · simpa only [shift_extend] using ha
        · simpa only [shift_extend, ← extend_insert] using he.2.1 x hx
      · simpa only [interp_inst, shift_extend, ← extend_insert] using he.2.2
  | forallE n A B bi v ihA ihB =>
      refine ⟨ihA cut ρ ha he.1, ?_⟩
      intro x hx
      rw [interp_inst] at hx
      apply ihB (cut + 1) (extend x ρ)
      · simpa only [shift_extend] using ha
      · simpa only [shift_extend, ← extend_insert] using he.2 x hx
  | letE n A b c nd ihA ihb ihc =>
      refine ⟨ihA cut ρ ha he.1, ihb cut ρ ha he.2.1, ?_⟩
      apply ihc (cut + 1) (extend (interp M ρ (inst a b cut)) ρ)
      · simpa only [shift_extend] using ha
      · simpa only [shift_extend, ← extend_insert, interp_inst] using he.2.2
  | mdata _ e ih | proj _ _ e ih => exact ih cut ρ ha he

theorem functionValid_inst_zero (M : Reading V) (e a : AnnotatedExpr)
    (ρ : Nat → V) (ha : FunctionValid M ρ a)
    (he : FunctionValid M (extend (interp M ρ a) ρ) e) :
    FunctionValid M ρ (inst a e 0) := by
  have hs : shift 0 0 ρ = ρ := by funext i; simp [shift]
  apply functionValid_inst M e a 0 ρ
  · simpa only [hs] using ha
  · simpa only [hs, insert_zero] using he

theorem functionValid_instLevels (M : Reading V) (e : AnnotatedExpr)
    (names : List PsKernelName) (values : List PsKernelLevel) (ρ : Nat → V) :
    FunctionValid M ρ (instLevels names values e) ↔
      FunctionValid (M.substLevels names values) ρ e := by
  induction e generalizing ρ with
  | bvar _ | fvar _ | mvar _ | sort _ | const _ _ | lit _ => rfl
  | app f a ihf iha =>
      simp only [instLevels, FunctionValid, ihf, iha, interp_instLevels]
  | lam n A b bi v ihA ihb =>
      simp only [instLevels, FunctionValid, ihA, interp_instLevels, ihb,
        Reading.substLevels_eval]
  | forallE n A B bi v ihA ihB =>
      simp only [instLevels, FunctionValid, ihA, interp_instLevels, ihB]
  | letE n A a b nd ihA iha ihb =>
      simp only [instLevels, FunctionValid, ihA, iha, interp_instLevels, ihb]
  | mdata _ e ih | proj _ _ e ih => exact ih ρ

theorem functionValid_app_of_type (M : Reading V) (ρ : Nat → V)
    (n : PsKernelName) (f a A B : AnnotatedExpr) (bi : PsKernelBinderInfo)
    (v : PsKernelLevel)
    (hf : FunctionValid M ρ f) (ha : FunctionValid M ρ a)
    (ft : interp M ρ f ∈ˢ interp M ρ (.forallE n A B bi v))
    (argTyped : interp M ρ a ∈ˢ interp M ρ A)
    (valid : AnnotationValid M ρ (.forallE n A B bi v)) :
    FunctionValid M ρ (.app f a) :=
  ⟨hf, ha, M.level v, interp M ρ A, fun x => interp M (extend x ρ) B,
    ft, argTyped, valid.2.2⟩

theorem functionValid_lam_of_type (M : Reading V) (ρ : Nat → V)
    (n : PsKernelName) (A b B : AnnotatedExpr) (bi : PsKernelBinderInfo)
    (v : PsKernelLevel)
    (hA : FunctionValid M ρ A)
    (hb : ∀ x, x ∈ˢ interp M ρ A → FunctionValid M (extend x ρ) b)
    (typed : ∀ x, x ∈ˢ interp M ρ A →
      interp M (extend x ρ) b ∈ˢ interp M (extend x ρ) B)
    (valid : AnnotationValid M ρ (.forallE n A B bi v)) :
    FunctionValid M ρ (.lam n A b bi v) :=
  ⟨hA, hb, (fun x => interp M (extend x ρ) B), typed, valid.2.2⟩

/-- Ordinary graph functions recover the lambda's own domain from their
semantic application evidence. This does not hold for collapsed proof values. -/
theorem functionValid_beta_positive (M : Reading V) (ρ : Nat → V)
    (n : PsKernelName) (A b a : AnnotatedExpr) (bi : PsKernelBinderInfo)
    (v : PsKernelLevel) (positive : M.level v ≠ 0)
    (valid : FunctionValid M ρ (.app (.lam n A b bi v) a)) :
    interp M ρ (.app (.lam n A b bi v) a) = interp M ρ (inst a b 0) ∧
      FunctionValid M ρ (inst a b 0) := by
  obtain ⟨hl, ha, k, domain, fibres, hf, hx, _⟩ := valid
  obtain ⟨_, hb, ownFibres, hbody, _⟩ := hl
  have hk : k ≠ 0 := by
    intro zero
    subst k
    have collapse := eq_pt_of_mem_piR_zero hf
    exact lamR_ne_pt positive collapse
  have hown : interp M ρ (.lam n A b bi v) ∈ˢ
      piR (M.level v) (interp M ρ A) ownFibres := lamR_mem hbody
  have domains : interp M ρ A = domain := piR_dom_unique positive hk hown hf
  have argument : interp M ρ a ∈ˢ interp M ρ A := by rwa [domains]
  refine ⟨?_, functionValid_inst_zero M b a ρ ha (hb _ argument)⟩
  rw [interp_inst_zero]
  exact app_lamR_pos positive argument

/-- At any regime an explicit argument-domain fact suffices. The proof-valued
case keeps that fact as an obligation of the actual checker bridge. -/
theorem functionValid_beta_on_domain (M : Reading V) (ρ : Nat → V)
    (n : PsKernelName) (A b a : AnnotatedExpr) (bi : PsKernelBinderInfo)
    (v : PsKernelLevel)
    (valid : FunctionValid M ρ (.app (.lam n A b bi v) a))
    (argument : interp M ρ a ∈ˢ interp M ρ A) :
    interp M ρ (.app (.lam n A b bi v) a) = interp M ρ (inst a b 0) ∧
      FunctionValid M ρ (inst a b 0) := by
  obtain ⟨hl, ha, _⟩ := valid
  obtain ⟨_, hb, fibres, typed, truthValues⟩ := hl
  refine ⟨?_, functionValid_inst_zero M b a ρ ha (hb _ argument)⟩
  rw [interp_inst_zero]
  apply app_lamR argument typed
  intro hz x hx
  simpa only [univ_zero] using truthValues hz x hx

end PsKernelSemantics.SetModel
