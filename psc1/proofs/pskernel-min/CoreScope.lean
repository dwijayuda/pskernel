import Ps.Core.Subst
import Lean

namespace Ps.MinKernel.CoreScope

/- This is a law of the actual PSC1 Core operations, not a parallel substitution
   relation. Removing a freshly inserted binder preserves outer references. -/
theorem instantiate_lift_worker (expression replacement : PsExpr) (depth : Nat) :
    psExprInstantiateAtWorker replacement
      (psExprLiftBVarsWorker 1 expression depth) depth = expression := by
  induction expression generalizing depth with
  | bvar index =>
    by_cases h : Nat.ble depth index = true
    · have hle : depth ≤ index := by simpa only [Nat.ble_eq] using h
      have hne : ¬ Nat.beq (Nat.add index 1) depth = true := by
        simp only [Nat.beq_eq]
        omega
      have hlt : Nat.blt depth (Nat.add index 1) = true := by
        simp only [Nat.blt_eq]
        omega
      simp [psExprLiftBVarsWorker, psExprInstantiateAtWorker, h, hne, hlt]
    · have hle : ¬ depth ≤ index := by simpa only [Nat.ble_eq] using h
      have hne : ¬ Nat.beq index depth = true := by
        simp only [Nat.beq_eq]
        omega
      have hlt : ¬ Nat.blt depth index = true := by
        simp only [Nat.blt_eq]
        omega
      simp [psExprLiftBVarsWorker, psExprInstantiateAtWorker, h, hne, hlt]
  | fvar id => rfl
  | mvar id => rfl
  | sortE level => rfl
  | constE name levels => rfl
  | app fn arg ihFn ihArg =>
    simp only [psExprLiftBVarsWorker, psExprInstantiateAtWorker, ihFn, ihArg]
  | lam name type body binder ihType ihBody =>
    simp only [psExprLiftBVarsWorker, psExprInstantiateAtWorker, ihType, ihBody]
  | forallE name type body binder ihType ihBody =>
    simp only [psExprLiftBVarsWorker, psExprInstantiateAtWorker, ihType, ihBody]
  | letE name type value body ihType ihValue ihBody =>
    simp only [psExprLiftBVarsWorker, psExprInstantiateAtWorker, ihType, ihValue, ihBody]
  | lit value => rfl
  | proj name index value ihValue =>
    simp only [psExprLiftBVarsWorker, psExprInstantiateAtWorker, ihValue]

theorem instantiate_lift (expression replacement : PsExpr) (depth : Nat) :
    psExprInstantiateAt replacement depth (psExprLiftBVars 1 depth expression) =
      expression := by
  exact instantiate_lift_worker expression replacement depth

/- Constant recursor motives are represented by lambdas whose bodies lift the
   result into the new context. Applying beta's actual body-instantiation step
   is independent of the supplied major argument, including for open results. -/
theorem constant_motive_body (result major : PsExpr) :
    psExprInstantiate1 (psExprLiftBVars 1 0 result) major = result :=
  instantiate_lift result major 0

theorem constant_motive_argument_irrelevant (result left right : PsExpr) :
    psExprInstantiate1 (psExprLiftBVars 1 0 result) left =
      psExprInstantiate1 (psExprLiftBVars 1 0 result) right := by
  rw [constant_motive_body, constant_motive_body]

#print axioms instantiate_lift
#print axioms constant_motive_body
#print axioms constant_motive_argument_irrelevant

end Ps.MinKernel.CoreScope
