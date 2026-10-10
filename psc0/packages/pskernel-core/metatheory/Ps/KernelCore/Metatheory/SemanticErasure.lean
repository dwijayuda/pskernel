import Ps.KernelCore.Metatheory.SemanticInterpretation
import Ps.KernelCore.Core.Substitution.Instantiate

/-!
Exact erasure correspondence with PSKernel's production substitution operations.
The sharing implementations are already related to these definitions by their
compiler-simplification proofs. This bridge covers every constructor and the
closed-expression fast path; it makes no typing claim about arbitrary syntax.
-/

namespace PsKernelSemantics
open AnnotatedExpr

private theorem native_lift_unchanged (e : PsKernelExpr) (cut amount : Nat) :
    (psKernelExprLiftLooseBVarsChanged e cut amount).2 = false →
      (psKernelExprLiftLooseBVarsChanged e cut amount).1 = e := by
  cases e <;> simp only [psKernelExprLiftLooseBVarsChanged] <;>
    repeat' split <;> simp_all

private theorem native_inst_unchanged (e : PsKernelExpr) (cut : Nat)
    (a : PsKernelExpr) :
    (psKernelExprInstantiateAtChanged e 0 [a] cut).2 = false →
      (psKernelExprInstantiateAtChanged e 0 [a] cut).1 = e := by
  cases e <;> simp only [psKernelExprInstantiateAtChanged] <;>
    repeat' split <;> simp_all

theorem AnnotatedExpr.liftN_zero (e : AnnotatedExpr) (cut : Nat) :
    liftN 0 e cut = e := by
  induction e generalizing cut <;> simp_all [liftN]

theorem AnnotatedExpr.erase_liftN (e : AnnotatedExpr) (amount cut : Nat) :
    (liftN amount e cut).erase = psKernelExprLiftLooseBVars e.erase cut amount := by
  unfold psKernelExprLiftLooseBVars
  by_cases hz : amount = 0
  · subst amount
    rw [liftN_zero]
    exact (congrArg Prod.fst (PsKernelSharing.lift_zero e.erase cut)).symm
  induction e generalizing cut with
  | bvar i =>
      by_cases hi : i < cut
      · simp [liftN, erase, psKernelExprLiftLooseBVarsChanged, hz,
          psKernelNatGe, hi, show ¬ cut ≤ i by omega]
      · simp [liftN, erase, psKernelExprLiftLooseBVarsChanged, hz,
          psKernelNatGe, hi, show cut ≤ i by omega]
  | fvar _ | mvar _ | sort _ | const _ _ | lit _ =>
      simp [liftN, erase, psKernelExprLiftLooseBVarsChanged, hz]
  | app f a ihf iha =>
      have h0 := ihf cut
      have h1 := iha cut
      cases hc0 : (psKernelExprLiftLooseBVarsChanged f.erase cut amount).2 <;>
      cases hc1 : (psKernelExprLiftLooseBVarsChanged a.erase cut amount).2 <;>
        simp_all [liftN, erase, psKernelExprLiftLooseBVarsChanged, hz,
          native_lift_unchanged]
  | lam n A b bi v ihA ihb =>
      have h0 := ihA cut
      have h1 := ihb (cut + 1)
      cases hc0 : (psKernelExprLiftLooseBVarsChanged A.erase cut amount).2 <;>
      cases hc1 : (psKernelExprLiftLooseBVarsChanged b.erase (cut + 1) amount).2 <;>
        simp_all [liftN, erase, psKernelExprLiftLooseBVarsChanged, hz,
          native_lift_unchanged]
  | forallE n A B bi v ihA ihB =>
      have h0 := ihA cut
      have h1 := ihB (cut + 1)
      cases hc0 : (psKernelExprLiftLooseBVarsChanged A.erase cut amount).2 <;>
      cases hc1 : (psKernelExprLiftLooseBVarsChanged B.erase (cut + 1) amount).2 <;>
        simp_all [liftN, erase, psKernelExprLiftLooseBVarsChanged, hz,
          native_lift_unchanged]
  | letE n A a b nd ihA iha ihb =>
      have h0 := ihA cut
      have h1 := iha cut
      have h2 := ihb (cut + 1)
      cases hc0 : (psKernelExprLiftLooseBVarsChanged A.erase cut amount).2 <;>
      cases hc1 : (psKernelExprLiftLooseBVarsChanged a.erase cut amount).2 <;>
      cases hc2 : (psKernelExprLiftLooseBVarsChanged b.erase (cut + 1) amount).2 <;>
        simp_all [liftN, erase, psKernelExprLiftLooseBVarsChanged, hz,
          native_lift_unchanged]
  | mdata m e ihe =>
      have h0 := ihe cut
      cases hc0 : (psKernelExprLiftLooseBVarsChanged e.erase cut amount).2 <;>
        simp_all [liftN, erase, psKernelExprLiftLooseBVarsChanged, hz,
          native_lift_unchanged]
  | proj n i e ihe =>
      have h0 := ihe cut
      cases hc0 : (psKernelExprLiftLooseBVarsChanged e.erase cut amount).2 <;>
        simp_all [liftN, erase, psKernelExprLiftLooseBVarsChanged, hz,
          native_lift_unchanged]

theorem AnnotatedExpr.scoped_iff_noLoose (e : AnnotatedExpr) (cut : Nat) :
    e.Scoped cut ↔ psKernelExprHasLooseAt e.erase cut = false := by
  induction e generalizing cut <;>
    try { simp_all [Scoped, erase, psKernelExprHasLooseAt]; done }
  case bvar i =>
    change i < cut ↔ Nat.ble cut i = false
    constructor
    · intro hi
      cases hb : Nat.ble cut i with
      | false => rfl
      | true => have hle := Nat.le_of_ble_eq_true hb; omega
    · intro hb
      have hn : ¬ cut ≤ i := by
        intro hle
        have ht := Nat.ble_eq_true_of_le hle
        rw [hb] at ht
        contradiction
      omega

theorem AnnotatedExpr.inst_scoped (e a : AnnotatedExpr) (cut : Nat)
    (h : e.Scoped cut) : inst a e cut = e := by
  induction e generalizing cut <;> simp_all [Scoped, inst]

theorem AnnotatedExpr.erase_inst (e a : AnnotatedExpr) (cut : Nat) :
    (inst a e cut).erase =
      (psKernelExprInstantiateAtChanged e.erase 0 [a.erase] cut).1 := by
  induction e generalizing cut with
  | bvar i =>
      by_cases hi : i < cut
      · have hne : i ≠ cut := by omega
        simp [inst, erase, psKernelExprInstantiateAtChanged, psKernelNatLt,
          hi, hne, show i ≤ cut by omega]
      · by_cases he : i = cut
        · subst i
          simp [inst, erase, psKernelExprInstantiateAtChanged, psKernelNatLt,
            psKernelExprListGet, erase_liftN]
        · have hdiff : i - cut = (i - cut - 1) + 1 := by omega
          have hn : psKernelNatLt i cut = false := by
            simp [psKernelNatLt, he, show ¬ i ≤ cut by omega]
          simp only [inst, ite_eq_right hi, ite_eq_right he, erase,
            psKernelExprInstantiateAtChanged, Nat.zero_add, hn,
            Bool.false_eq_true, ite_false]
          rw [hdiff]
          rfl
  | fvar _ | mvar _ | sort _ | const _ _ | lit _ => rfl
  | app f b ihf ihb =>
      have h0 := ihf cut
      have h1 := ihb cut
      cases hc0 : (psKernelExprInstantiateAtChanged f.erase 0 [a.erase] cut).2 <;>
      cases hc1 : (psKernelExprInstantiateAtChanged b.erase 0 [a.erase] cut).2 <;>
        simp_all [inst, erase, psKernelExprInstantiateAtChanged, native_inst_unchanged]
  | lam n A b bi v ihA ihb =>
      have h0 := ihA cut
      have h1 := ihb (cut + 1)
      cases hc0 : (psKernelExprInstantiateAtChanged A.erase 0 [a.erase] cut).2 <;>
      cases hc1 : (psKernelExprInstantiateAtChanged b.erase 0 [a.erase] (cut + 1)).2 <;>
        simp_all [inst, erase, psKernelExprInstantiateAtChanged, native_inst_unchanged]
  | forallE n A B bi v ihA ihB =>
      have h0 := ihA cut
      have h1 := ihB (cut + 1)
      cases hc0 : (psKernelExprInstantiateAtChanged A.erase 0 [a.erase] cut).2 <;>
      cases hc1 : (psKernelExprInstantiateAtChanged B.erase 0 [a.erase] (cut + 1)).2 <;>
        simp_all [inst, erase, psKernelExprInstantiateAtChanged, native_inst_unchanged]
  | letE n A b c nd ihA ihb ihc =>
      have h0 := ihA cut
      have h1 := ihb cut
      have h2 := ihc (cut + 1)
      cases hc0 : (psKernelExprInstantiateAtChanged A.erase 0 [a.erase] cut).2 <;>
      cases hc1 : (psKernelExprInstantiateAtChanged b.erase 0 [a.erase] cut).2 <;>
      cases hc2 : (psKernelExprInstantiateAtChanged c.erase 0 [a.erase] (cut + 1)).2 <;>
        simp_all [inst, erase, psKernelExprInstantiateAtChanged, native_inst_unchanged]
  | mdata m e ihe =>
      have h0 := ihe cut
      cases hc0 : (psKernelExprInstantiateAtChanged e.erase 0 [a.erase] cut).2 <;>
        simp_all [inst, erase, psKernelExprInstantiateAtChanged, native_inst_unchanged]
  | proj n i e ihe =>
      have h0 := ihe cut
      cases hc0 : (psKernelExprInstantiateAtChanged e.erase 0 [a.erase] cut).2 <;>
        simp_all [inst, erase, psKernelExprInstantiateAtChanged, native_inst_unchanged]

/-- The actual public single-substitution function, including its closed test. -/
theorem AnnotatedExpr.erase_instantiate1 (e a : AnnotatedExpr) :
    (inst a e 0).erase = psKernelExprInstantiate1 e.erase a.erase := by
  unfold psKernelExprInstantiate1
  cases h : psKernelExprHasLooseBVar e.erase with
  | true =>
      simp only [h, ite_eq_left, psKernelExprInstantiate,
        psKernelExprInstantiateAt, psKernelExprListIsEmpty, Bool.false_eq_true,
        ite_eq_right]
      exact erase_inst e a 0
  | false =>
      have hs : e.Scoped 0 := (scoped_iff_noLoose e 0).mpr h
      simp [inst_scoped e a 0 hs]

namespace SetModel
open ConLeche

/-- The result of production substitution has the exact transported reading.
This is a refinement theorem, not checker or beta soundness for invalid inputs. -/
theorem instantiate1_has_reading {V : Type u} [SetTheory V]
    (M : Reading V) (e a : AnnotatedExpr) (ρ : Nat → V) :
    ∃ result : AnnotatedExpr,
      result.erase = psKernelExprInstantiate1 e.erase a.erase ∧
      interp M ρ result = interp M (extend (interp M ρ a) ρ) e :=
  ⟨inst a e 0, erase_instantiate1 e a, interp_inst_zero M e a ρ⟩

end SetModel
end PsKernelSemantics
