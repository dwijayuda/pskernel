import Ps.KernelCore.Metatheory.SemanticSetDomain
import Ps.KernelCore.Metatheory.SemanticAnnotatedExpr

/-!
Set interpretation and variable transport for PSKernel's annotated expressions.

Constants, local free variables, metavariables, literals and projections have
explicit interpretation parameters. No validity is assumed for these tables:
typing/admission must prove it. In particular a total interpretation of raw
syntax is not a soundness theorem for accepting raw syntax.

The two binder regimes follow the pinned Con Leche set model. The environment
transport is ordinary de Bruijn substitution, proved here for PSKernel's full
constructor inventory, including lets and metadata.
-/

namespace PsKernelSemantics.SetModel

open ConLeche ConLeche.SetTheory ConLeche.SetModel
open AnnotatedExpr

universe u

/-- The semantic parameters whose correctness will be established by context
and environment validation. No checker-correctness field is hidden here. -/
structure Reading (V : Type u) where
  levelParams : PsKernelName → Nat
  levelMetavariables : PsKernelName → Nat
  freeVars : PsKernelName → V
  metavariables : PsKernelName → V
  constants : PsKernelName → List Nat → V
  literals : PsKernelLiteral → V
  projections : PsKernelName → Nat → V → V

def extend {V : Type u} (x : V) (ρ : Nat → V) : Nat → V
  | 0 => x
  | i + 1 => ρ i

def shift {V : Type u} (amount cut : Nat) (ρ : Nat → V) : Nat → V :=
  fun i => if i < cut then ρ i else ρ (i + amount)

def insert {V : Type u} (cut : Nat) (x : V) (ρ : Nat → V) : Nat → V :=
  fun i => if i < cut then ρ i else if i = cut then x else ρ (i - 1)

theorem extend_shift {V : Type u} (x : V) (amount cut : Nat) (ρ : Nat → V) :
    extend x (shift amount cut ρ) = shift amount (cut + 1) (extend x ρ) := by
  funext i
  cases i with
  | zero => simp [extend, shift]
  | succ i =>
      by_cases h : i < cut
      · simp [extend, shift, h, show i + 1 < cut + 1 by omega]
      · simp [extend, shift, h, show ¬ i + 1 < cut + 1 by omega,
          Nat.succ_add]

theorem extend_insert {V : Type u} (x y : V) (cut : Nat) (ρ : Nat → V) :
    extend x (insert cut y ρ) = insert (cut + 1) y (extend x ρ) := by
  funext i
  cases i with
  | zero => simp [extend, insert]
  | succ i =>
      by_cases h : i < cut
      · simp [insert, extend, h, show i + 1 < cut + 1 by omega]
      · by_cases he : i = cut
        · subst i; simp [insert, extend]
        · have hi : i ≠ 0 := by omega
          cases i with
          | zero => contradiction
          | succ i =>
              simp [insert, extend, h, he,
                show ¬ i + 1 + 1 < cut + 1 by omega,
                show i + 1 + 1 ≠ cut + 1 by omega]

theorem shift_extend {V : Type u} (x : V) (cut : Nat) (ρ : Nat → V) :
    shift (cut + 1) 0 (extend x ρ) = shift cut 0 ρ := by
  funext i
  simp [shift, extend, Nat.add_assoc]

theorem insert_zero {V : Type u} (x : V) (ρ : Nat → V) :
    insert 0 x ρ = extend x ρ := by
  funext i
  cases i <;> simp [insert, extend]

variable {V : Type u} [SetTheory V]

def Reading.level (M : Reading V) (l : PsKernelLevel) : Nat :=
  evalLevel M.levelParams M.levelMetavariables l

noncomputable def interp (M : Reading V) (ρ : Nat → V) : AnnotatedExpr → V
  | .bvar i => ρ i
  | .fvar n => M.freeVars n
  | .mvar n => M.metavariables n
  | .sort l => univ (M.level l)
  | .const n ls => M.constants n (ls.map M.level)
  | .app f a => app (interp M ρ f) (interp M ρ a)
  | .lam _ A b _ v =>
      lamR (M.level v) (interp M ρ A) (fun x => interp M (extend x ρ) b)
  | .forallE _ A B _ v =>
      piR (M.level v) (interp M ρ A) (fun x => interp M (extend x ρ) B)
  | .letE _ _ a b _ => interp M (extend (interp M ρ a) ρ) b
  | .lit l => M.literals l
  | .mdata _ e => interp M ρ e
  | .proj n i e => M.projections n i (interp M ρ e)

/-- Weakening is exactly a change of variable valuation. -/
theorem interp_liftN (M : Reading V) (e : AnnotatedExpr) (amount cut : Nat)
    (ρ : Nat → V) :
    interp M ρ (liftN amount e cut) = interp M (shift amount cut ρ) e := by
  induction e generalizing cut ρ with
  | bvar i =>
      by_cases h : i < cut <;> simp [liftN, interp, shift, h]
  | fvar _ | mvar _ | sort _ | const _ _ | lit _ => rfl
  | app f a ihf iha => simp only [liftN, interp, ihf, iha]
  | lam n A b bi v ihA ihb =>
      simp only [liftN, interp, ihA]
      congr 1
      funext x
      rw [ihb, ← extend_shift]
  | forallE n A B bi v ihA ihB =>
      simp only [liftN, interp, ihA]
      congr 1
      funext x
      rw [ihB, ← extend_shift]
  | letE n A a b nd ihA iha ihb =>
      simp only [liftN, interp, iha, ihb, ← extend_shift]
  | mdata m e ihe => exact ihe _ _
  | proj n i e ihe => simp only [liftN, interp, ihe]

/-- Substitution is exactly insertion of the replacement's value.
The replacement is read below the binders crossed by substitution. -/
theorem interp_inst (M : Reading V) (e a : AnnotatedExpr) (cut : Nat)
    (ρ : Nat → V) :
    interp M ρ (inst a e cut) =
      interp M (insert cut (interp M (shift cut 0 ρ) a) ρ) e := by
  induction e generalizing cut ρ with
  | bvar i =>
      by_cases h : i < cut
      · simp [inst, interp, insert, h]
      · by_cases he : i = cut
        · simp [inst, h, he, interp_liftN, interp, insert]
        · simp [inst, h, he, interp, insert]
  | fvar _ | mvar _ | sort _ | const _ _ | lit _ => rfl
  | app f b ihf ihb => simp only [inst, interp, ihf, ihb]
  | lam n A b bi v ihA ihb =>
      simp only [inst, interp, ihA]
      congr 1
      funext x
      rw [ihb, shift_extend, ← extend_insert]
  | forallE n A B bi v ihA ihB =>
      simp only [inst, interp, ihA]
      congr 1
      funext x
      rw [ihB, shift_extend, ← extend_insert]
  | letE n A b c nd ihA ihb ihc =>
      simp only [inst, interp, ihb, ihc, shift_extend, ← extend_insert]
  | mdata m e ihe => exact ihe _ _
  | proj n i e ihe => simp only [inst, interp, ihe]

theorem interp_inst_zero (M : Reading V) (e a : AnnotatedExpr) (ρ : Nat → V) :
    interp M ρ (inst a e 0) = interp M (extend (interp M ρ a) ρ) e := by
  rw [interp_inst, insert_zero]
  have h : shift 0 0 ρ = ρ := by funext i; simp [shift]
  rw [h]

/-- Scoped expressions cannot inspect the unused tail of a valuation. -/
theorem interp_scoped (M : Reading V) (e : AnnotatedExpr) (n : Nat)
    (hscope : e.Scoped n) (ρ σ : Nat → V)
    (h : ∀ i, i < n → ρ i = σ i) :
    interp M ρ e = interp M σ e := by
  induction e generalizing n ρ σ with
  | bvar i => exact h i hscope
  | fvar _ | mvar _ | sort _ | const _ _ | lit _ => rfl
  | app f a ihf iha =>
      exact congrArg₂ app (ihf n hscope.1 ρ σ h) (iha n hscope.2 ρ σ h)
  | lam name A b bi v ihA ihb =>
      simp only [interp]
      rw [ihA n hscope.1 ρ σ h]
      congr 1
      funext x
      apply ihb (n + 1) hscope.2
      intro i hi
      cases i with
      | zero => rfl
      | succ i => exact h i (by omega)
  | forallE name A B bi v ihA ihB =>
      simp only [interp]
      rw [ihA n hscope.1 ρ σ h]
      congr 1
      funext x
      apply ihB (n + 1) hscope.2
      intro i hi
      cases i with
      | zero => rfl
      | succ i => exact h i (by omega)
  | letE name A a b nd ihA iha ihb =>
      simp only [interp]
      rw [iha n hscope.2.1 ρ σ h]
      apply ihb (n + 1) hscope.2.2
      intro i hi
      cases i with
      | zero => rfl
      | succ i => exact h i (by omega)
  | mdata m e ihe => exact ihe n hscope ρ σ h
  | proj name index e ihe => exact congrArg _ (ihe n hscope ρ σ h)

theorem interp_closed (M : Reading V) (e : AnnotatedExpr)
    (h : e.Scoped 0) (ρ σ : Nat → V) : interp M ρ e = interp M σ e :=
  interp_scoped M e 0 h ρ σ (fun _ hi => False.elim (Nat.not_lt_zero _ hi))

end PsKernelSemantics.SetModel
