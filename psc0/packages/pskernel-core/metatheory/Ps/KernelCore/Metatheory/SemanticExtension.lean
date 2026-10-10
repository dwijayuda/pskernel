import Ps.KernelCore.Metatheory.SemanticContext

/-!
Conservative extension of a set interpretation by one constant.
This constructs and proves the model-side extension; actual declaration
admission must still establish freshness, type interpretation and the new
constant's membership at every universe instantiation.
-/

namespace PsKernelSemantics.SetModel
open ConLeche ConLeche.SetTheory
open AnnotatedExpr

universe u
variable {V : Type u} [SetTheory V]

def AvoidsConstant (fresh : PsKernelName) : AnnotatedExpr → Prop
  | .const name _ => name ≠ fresh
  | .app f a => AvoidsConstant fresh f ∧ AvoidsConstant fresh a
  | .lam _ A b _ _ => AvoidsConstant fresh A ∧ AvoidsConstant fresh b
  | .forallE _ A B _ _ => AvoidsConstant fresh A ∧ AvoidsConstant fresh B
  | .letE _ A a b _ =>
      AvoidsConstant fresh A ∧ AvoidsConstant fresh a ∧ AvoidsConstant fresh b
  | .mdata _ e => AvoidsConstant fresh e
  | .proj _ _ e => AvoidsConstant fresh e
  | _ => True

/-- Only the constant table is extended. Projection-model extensions, recursive
families and environment indexes require their own preservation theorems. -/
noncomputable def Reading.extendConstant (M : Reading V) (fresh : PsKernelName)
    (value : List Nat → V) : Reading V := by
  classical
  exact { M with constants := fun name levels =>
    if name = fresh then value levels else M.constants name levels }

theorem interp_extendConstant (M : Reading V) (fresh : PsKernelName)
    (value : List Nat → V) (e : AnnotatedExpr)
    (h : AvoidsConstant fresh e) (ρ : Nat → V) :
    interp (M.extendConstant fresh value) ρ e = interp M ρ e := by
  revert h
  induction e generalizing ρ with
  | bvar _ | fvar _ | mvar _ | sort _ | lit _ => intro _; rfl
  | const name levels =>
      intro h
      simp only [AvoidsConstant] at h
      simp [interp, Reading.extendConstant, Reading.level, h]
  | app f a ihf iha =>
      intro h
      simp only [interp, ihf ρ h.1, iha ρ h.2]
  | lam n A b bi v ihA ihb =>
      intro h
      simp only [interp, ihA ρ h.1]
      congr 1
      funext x
      exact ihb (extend x ρ) h.2
  | forallE n A B bi v ihA ihB =>
      intro h
      simp only [interp, ihA ρ h.1]
      congr 1
      funext x
      exact ihB (extend x ρ) h.2
  | letE n A a b nd ihA iha ihb =>
      intro h
      simp only [interp, iha ρ h.2.1]
      exact ihb _ h.2.2
  | mdata md e ih => intro h; exact ih ρ h
  | proj n i e ih =>
      intro h
      change M.projections n i (interp (M.extendConstant fresh value) ρ e) =
        M.projections n i (interp M ρ e)
      rw [ih ρ h]

theorem satisfies_extendConstant (M : Reading V) (fresh : PsKernelName)
    (value : List Nat → V) (Γ : List AnnotatedExpr)
    (hΓ : ∀ A, A ∈ Γ → AvoidsConstant fresh A) (ρ : Nat → V) :
    Satisfies (M.extendConstant fresh value) Γ ρ ↔ Satisfies M Γ ρ := by
  induction Γ generalizing ρ with
  | nil => rfl
  | cons A Γ ih =>
      have hA : AvoidsConstant fresh A := hΓ A (by simp)
      have hTail : ∀ B, B ∈ Γ → AvoidsConstant fresh B :=
        fun B hB => hΓ B (by simp [hB])
      simp only [Satisfies, interp_extendConstant M fresh value A hA,
        ih hTail]

theorem modelsType_extendConstant (M : Reading V) (fresh : PsKernelName)
    (value : List Nat → V) (Γ : List AnnotatedExpr) (e A : AnnotatedExpr)
    (hΓ : ∀ B, B ∈ Γ → AvoidsConstant fresh B)
    (he : AvoidsConstant fresh e) (hA : AvoidsConstant fresh A)
    (h : ModelsType M Γ e A) :
    ModelsType (M.extendConstant fresh value) Γ e A := by
  intro ρ hρ
  rw [interp_extendConstant M fresh value e he,
    interp_extendConstant M fresh value A hA]
  exact h ρ ((satisfies_extendConstant M fresh value Γ hΓ ρ).mp hρ)

/-- An explicitly supplied interpretation of a new axiom/constant is valid
only when its value really belongs to the interpretation of its declared type.
This premise is not inferred from the kernel accepting an axiom declaration. -/
theorem newConstant_modelsType (M : Reading V) (fresh : PsKernelName)
    (value : List Nat → V) (Γ : List AnnotatedExpr)
    (levels : List PsKernelLevel) (A : AnnotatedExpr)
    (hA : AvoidsConstant fresh A)
    (hValue : ∀ ρ, value (levels.map M.level) ∈ˢ interp M ρ A) :
    ModelsType (M.extendConstant fresh value) Γ (.const fresh levels) A := by
  intro ρ _
  rw [interp_extendConstant M fresh value A hA]
  simpa [interp, Reading.extendConstant, Reading.level] using hValue ρ

end PsKernelSemantics.SetModel
