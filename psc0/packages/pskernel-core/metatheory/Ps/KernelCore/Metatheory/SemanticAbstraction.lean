import Ps.KernelCore.Metatheory.SemanticContext
import Ps.KernelCore.Metatheory.SemanticErasure
import Ps.KernelCore.Metatheory.Comparator
import Ps.KernelCore.Core.Substitution.Abstract

/-!
Opening and closing the local names used by production inference. The closing
operation has exact erasure correspondence with the production singleton-list
abstraction, including its unchanged-node branches. Freshness is stated for
the expression being opened, not inferred from a name's spelling.
-/

namespace PsKernelSemantics
namespace AnnotatedExpr

def Fresh (name : PsKernelName) : AnnotatedExpr → Prop
  | .fvar n => psKernelNameEq n name = false
  | .app f a => Fresh name f ∧ Fresh name a
  | .lam _ A b _ _ | .forallE _ A b _ _ => Fresh name A ∧ Fresh name b
  | .letE _ A a b _ => Fresh name A ∧ Fresh name a ∧ Fresh name b
  | .mdata _ e | .proj _ _ e => Fresh name e
  | _ => True

/-- Close a single free variable at the current binder depth. Just as in the
production operation, pre-existing bound indices are not shifted. -/
def close (name : PsKernelName) : AnnotatedExpr → Nat → AnnotatedExpr
  | .fvar n, k => if psKernelNameEq n name then .bvar k else .fvar n
  | .app f a, k => .app (close name f k) (close name a k)
  | .lam n A b bi v, k => .lam n (close name A k) (close name b (k + 1)) bi v
  | .forallE n A B bi v, k => .forallE n (close name A k) (close name B (k + 1)) bi v
  | .letE n A a b nd, k =>
      .letE n (close name A k) (close name a k) (close name b (k + 1)) nd
  | .mdata md e, k => .mdata md (close name e k)
  | .proj n i e, k => .proj n i (close name e k)
  | e, _ => e

private theorem native_abstract_unchanged (e : PsKernelExpr)
    (names : List PsKernelName) (cut : Nat) :
    (psKernelExprAbstractFVarsAtChanged e names cut).2 = false →
      (psKernelExprAbstractFVarsAtChanged e names cut).1 = e := by
  cases e <;> simp only [psKernelExprAbstractFVarsAtChanged]
  all_goals repeat' first | (solve | simp_all) | split

theorem erase_close (e : AnnotatedExpr) (name : PsKernelName) (cut : Nat) :
    (close name e cut).erase =
      (psKernelExprAbstractFVarsAtChanged e.erase [name] cut).1 := by
  induction e generalizing cut with
  | fvar n =>
      cases h : psKernelNameEq n name <;>
        simp [close, erase, psKernelExprAbstractFVarsAtChanged,
          psKernelNameLastIndex, psKernelNameLastIndexWorker, psKernelNameListLength, h]
  | bvar _ | mvar _ | sort _ | const _ _ | lit _ => rfl
  | app f a ihf iha =>
      have h0 := ihf cut
      have h1 := iha cut
      cases hc0 : (psKernelExprAbstractFVarsAtChanged f.erase [name] cut).2 <;>
      cases hc1 : (psKernelExprAbstractFVarsAtChanged a.erase [name] cut).2 <;>
        simp_all [close, erase, psKernelExprAbstractFVarsAtChanged, native_abstract_unchanged]
  | lam n A b bi v ihA ihb =>
      have h0 := ihA cut
      have h1 := ihb (cut + 1)
      cases hc0 : (psKernelExprAbstractFVarsAtChanged A.erase [name] cut).2 <;>
      cases hc1 : (psKernelExprAbstractFVarsAtChanged b.erase [name] (cut + 1)).2 <;>
        simp_all [close, erase, psKernelExprAbstractFVarsAtChanged, native_abstract_unchanged]
  | forallE n A B bi v ihA ihB =>
      have h0 := ihA cut
      have h1 := ihB (cut + 1)
      cases hc0 : (psKernelExprAbstractFVarsAtChanged A.erase [name] cut).2 <;>
      cases hc1 : (psKernelExprAbstractFVarsAtChanged B.erase [name] (cut + 1)).2 <;>
        simp_all [close, erase, psKernelExprAbstractFVarsAtChanged, native_abstract_unchanged]
  | letE n A a b nd ihA iha ihb =>
      have h0 := ihA cut
      have h1 := iha cut
      have h2 := ihb (cut + 1)
      cases hc0 : (psKernelExprAbstractFVarsAtChanged A.erase [name] cut).2 <;>
      cases hc1 : (psKernelExprAbstractFVarsAtChanged a.erase [name] cut).2 <;>
      cases hc2 : (psKernelExprAbstractFVarsAtChanged b.erase [name] (cut + 1)).2 <;>
        simp_all [close, erase, psKernelExprAbstractFVarsAtChanged, native_abstract_unchanged]
  | mdata md e ih =>
      have h0 := ih cut
      cases hc0 : (psKernelExprAbstractFVarsAtChanged e.erase [name] cut).2 <;>
        simp_all [close, erase, psKernelExprAbstractFVarsAtChanged, native_abstract_unchanged]
  | proj n i e ih =>
      have h0 := ih cut
      cases hc0 : (psKernelExprAbstractFVarsAtChanged e.erase [name] cut).2 <;>
        simp_all [close, erase, psKernelExprAbstractFVarsAtChanged, native_abstract_unchanged]

theorem erase_abstractFVar (e : AnnotatedExpr) (name : PsKernelName) :
    (close name e 0).erase = psKernelExprAbstractFVars e.erase [name] :=
  erase_close e name 0

end AnnotatedExpr

namespace SetModel
open ConLeche ConLeche.SetTheory ConLeche.SetModel AnnotatedExpr
universe u
variable {V : Type u} [SetTheory V]

def Reading.withFree (M : Reading V) (name : PsKernelName) (value : V) : Reading V :=
  { M with freeVars := fun n => if psKernelNameEq n name then value else M.freeVars n }

theorem Reading.withFree_level (M : Reading V) (name : PsKernelName) (x : V) :
    (M.withFree name x).level = M.level := rfl

private theorem nameEq_self (name : PsKernelName) : psKernelNameEq name name = true :=
  psKernelNameEq_refl_of_string_law (fun s => by simp [psKernelStringEq]) name

/-- Updating a genuinely fresh local name cannot alter the expression's meaning. -/
theorem interp_withFree_fresh (M : Reading V) (e : AnnotatedExpr)
    (name : PsKernelName) (h : Fresh name e) (x : V) (ρ : Nat → V) :
    interp (M.withFree name x) ρ e = interp M ρ e := by
  induction e generalizing ρ with
  | bvar _ | mvar _ | sort _ | const _ _ | lit _ => rfl
  | fvar n => simp [interp, Reading.withFree, show psKernelNameEq n name = false from h]
  | app f a ihf iha => simp only [interp]; rw [ihf h.1, iha h.2]
  | lam n A b bi v ihA ihb =>
      simp only [interp, Reading.withFree_level]
      rw [ihA h.1]
      congr 1
      funext y
      exact ihb h.2 _
  | forallE n A B bi v ihA ihB =>
      simp only [interp, Reading.withFree_level]
      rw [ihA h.1]
      congr 1
      funext y
      exact ihB h.2 _
  | letE n A a b nd ihA iha ihb =>
      simp only [interp]
      rw [iha h.2.1, ihb h.2.2]
  | mdata md e ih => exact ih h _
  | proj n i e ih =>
      exact congrArg (M.projections n i) (ih h ρ)

/-- Abstraction rebinds the chosen free name to the value at the stated depth.
No typing or global checker-soundness premise is used. -/
theorem interp_close (M : Reading V) (e : AnnotatedExpr) (name : PsKernelName)
    (cut : Nat) (ρ : Nat → V) :
    interp M ρ (close name e cut) =
      interp (M.withFree name (ρ cut)) ρ e := by
  induction e generalizing cut ρ with
  | bvar _ | mvar _ | sort _ | const _ _ | lit _ => rfl
  | fvar n =>
      cases h : psKernelNameEq n name <;> simp [close, interp, Reading.withFree, h]
  | app f a ihf iha => simp only [close, interp, ihf, iha]
  | lam n A b bi v ihA ihb =>
      simp only [close, interp, Reading.withFree_level]
      rw [ihA]
      congr 1
      funext x
      exact ihb (cut + 1) (extend x ρ)
  | forallE n A B bi v ihA ihB =>
      simp only [close, interp, Reading.withFree_level]
      rw [ihA]
      congr 1
      funext x
      exact ihB (cut + 1) (extend x ρ)
  | letE n A a b nd ihA iha ihb =>
      simp only [close, interp]
      rw [iha]
      exact ihb (cut + 1) (extend (interp (M.withFree name (ρ cut)) ρ a) ρ)
  | mdata md e ih => exact ih _ _
  | proj n i e ih => exact congrArg (M.projections n i) (ih cut ρ)

/-- The actual opening operation is sound under an explicit freshness premise. -/
theorem open_fresh_has_reading (M : Reading V) (e : AnnotatedExpr)
    (name : PsKernelName) (h : Fresh name e) (x : V) (ρ : Nat → V) :
    ∃ opened : AnnotatedExpr,
      opened.erase = psKernelExprInstantiate1 e.erase (.fvar name) ∧
      interp (M.withFree name x) ρ opened = interp M (extend x ρ) e := by
  refine ⟨inst (.fvar name) e 0, erase_instantiate1 e (.fvar name), ?_⟩
  rw [interp_inst_zero]
  simp only [interp, Reading.withFree, nameEq_self, ite_true]
  exact interp_withFree_fresh M e name h x _

/-- Exact reading of the production closing operation used for inferred types. -/
theorem abstractFVar_has_reading (M : Reading V) (e : AnnotatedExpr)
    (name : PsKernelName) (ρ : Nat → V) (x : V) :
    ∃ closed : AnnotatedExpr,
      closed.erase = psKernelExprAbstractFVars e.erase [name] ∧
      interp M (extend x ρ) closed =
        interp (M.withFree name x) (extend x ρ) e :=
  ⟨close name e 0, erase_abstractFVar e name, interp_close M e name 0 (extend x ρ)⟩

/-- A locally closed inferred type permits closing a fresh name to move between the outer and extended valuations. -/
theorem abstractFVar_closed_input (M : Reading V) (e : AnnotatedExpr)
    (name : PsKernelName) (h : e.Scoped 0) (ρ : Nat → V) (x : V) :
    interp M (extend x ρ) (close name e 0) = interp (M.withFree name x) ρ e := by
  rw [interp_close]
  exact interp_closed (M.withFree name x) e h _ _

end SetModel
end PsKernelSemantics
