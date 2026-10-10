import Ps.KernelCore.Metatheory.SemanticFunctionValidity

/-!
Locality of the two hereditary validity invariants. A term cannot depend on
bound-variable values outside its scope. This also transports the validity of
an actual inferred type across closing a fresh local variable.
-/
namespace PsKernelSemantics.SetModel
open ConLeche ConLeche.SetTheory ConLeche.SetModel AnnotatedExpr
universe w
variable {V : Type w} [SetTheory V]

private theorem extend_agrees {n : Nat} {ρ σ : Nat → V}
    (h : ∀ i, i < n → ρ i = σ i) (x : V) :
    ∀ i, i < n + 1 → extend x ρ i = extend x σ i := by
  intro i hi
  cases i with
  | zero => rfl
  | succ i => exact h i (by omega)

theorem annotationValid_scoped (M : Reading V) (e : AnnotatedExpr)
    (n : Nat) (scoped : e.Scoped n) (ρ σ : Nat → V)
    (agree : ∀ i, i < n → ρ i = σ i) :
    AnnotationValid M ρ e ↔ AnnotationValid M σ e := by
  induction e generalizing n ρ σ with
  | bvar _ | fvar _ | mvar _ | sort _ | const _ _ | lit _ => rfl
  | app f a ihf iha =>
      simp only [AnnotationValid, ihf n scoped.1 ρ σ agree,
        iha n scoped.2 ρ σ agree]
  | lam name A b bi v ihA ihb =>
      have hb (x : V) := ihb (n + 1) scoped.2
        (extend x ρ) (extend x σ) (extend_agrees agree x)
      simp only [AnnotationValid, ihA n scoped.1 ρ σ agree,
        interp_scoped M A n scoped.1 ρ σ agree, hb]
  | forallE name A B bi v ihA ihB =>
      have hb (x : V) := ihB (n + 1) scoped.2
        (extend x ρ) (extend x σ) (extend_agrees agree x)
      have eb (x : V) := interp_scoped M B (n + 1) scoped.2
        (extend x ρ) (extend x σ) (extend_agrees agree x)
      simp only [AnnotationValid, ihA n scoped.1 ρ σ agree,
        interp_scoped M A n scoped.1 ρ σ agree, hb, eb]
  | letE name A a b nd ihA iha ihb =>
      have hb (x : V) := ihb (n + 1) scoped.2.2
        (extend x ρ) (extend x σ) (extend_agrees agree x)
      simp only [AnnotationValid, ihA n scoped.1 ρ σ agree,
        iha n scoped.2.1 ρ σ agree,
        interp_scoped M a n scoped.2.1 ρ σ agree, hb]
  | mdata _ e ih | proj _ _ e ih => exact ih n scoped ρ σ agree

theorem functionValid_scoped (M : Reading V) (e : AnnotatedExpr)
    (n : Nat) (scoped : e.Scoped n) (ρ σ : Nat → V)
    (agree : ∀ i, i < n → ρ i = σ i) :
    FunctionValid M ρ e ↔ FunctionValid M σ e := by
  induction e generalizing n ρ σ with
  | bvar _ | fvar _ | mvar _ | sort _ | const _ _ | lit _ => rfl
  | app f a ihf iha =>
      simp only [FunctionValid, ihf n scoped.1 ρ σ agree,
        iha n scoped.2 ρ σ agree,
        interp_scoped M f n scoped.1 ρ σ agree,
        interp_scoped M a n scoped.2 ρ σ agree]
  | lam name A b bi v ihA ihb =>
      have hb (x : V) := ihb (n + 1) scoped.2
        (extend x ρ) (extend x σ) (extend_agrees agree x)
      have eb (x : V) := interp_scoped M b (n + 1) scoped.2
        (extend x ρ) (extend x σ) (extend_agrees agree x)
      simp only [FunctionValid, ihA n scoped.1 ρ σ agree,
        interp_scoped M A n scoped.1 ρ σ agree, hb, eb]
  | forallE name A B bi v ihA ihB =>
      have hb (x : V) := ihB (n + 1) scoped.2
        (extend x ρ) (extend x σ) (extend_agrees agree x)
      simp only [FunctionValid, ihA n scoped.1 ρ σ agree,
        interp_scoped M A n scoped.1 ρ σ agree, hb]
  | letE name A a b nd ihA iha ihb =>
      have hb (x : V) := ihb (n + 1) scoped.2.2
        (extend x ρ) (extend x σ) (extend_agrees agree x)
      simp only [FunctionValid, ihA n scoped.1 ρ σ agree,
        iha n scoped.2.1 ρ σ agree,
        interp_scoped M a n scoped.2.1 ρ σ agree, hb]
  | mdata _ e ih | proj _ _ e ih => exact ih n scoped ρ σ agree

theorem annotationValid_closed (M : Reading V) (e : AnnotatedExpr)
    (scoped : e.Scoped 0) (ρ σ : Nat → V) :
    AnnotationValid M ρ e ↔ AnnotationValid M σ e :=
  annotationValid_scoped M e 0 scoped ρ σ
    (fun _ hi => False.elim (Nat.not_lt_zero _ hi))

theorem functionValid_closed (M : Reading V) (e : AnnotatedExpr)
    (scoped : e.Scoped 0) (ρ σ : Nat → V) :
    FunctionValid M ρ e ↔ FunctionValid M σ e :=
  functionValid_scoped M e 0 scoped ρ σ
    (fun _ hi => False.elim (Nat.not_lt_zero _ hi))

theorem annotationValid_abstractFVar (M : Reading V) (e : AnnotatedExpr)
    (name : PsKernelName) (scoped : e.Scoped 0) (ρ : Nat → V) (x : V) :
    AnnotationValid M (extend x ρ) (close name e 0) ↔
      AnnotationValid (M.withFree name x) ρ e := by
  rw [annotationValid_close]
  exact annotationValid_closed (M.withFree name x) e scoped (extend x ρ) ρ

theorem functionValid_abstractFVar (M : Reading V) (e : AnnotatedExpr)
    (name : PsKernelName) (scoped : e.Scoped 0) (ρ : Nat → V) (x : V) :
    FunctionValid M (extend x ρ) (close name e 0) ↔
      FunctionValid (M.withFree name x) ρ e := by
  rw [functionValid_close]
  exact functionValid_closed (M.withFree name x) e scoped (extend x ρ) ρ

end PsKernelSemantics.SetModel
