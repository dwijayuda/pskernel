import Ps.MinKernel.Profile.LowerUnusedBinder
import CoreScope

namespace Ps.MinKernel.BinderLowering

theorem lower_worker_sound (expression : PsExpr) (depth : Nat) (result : PsExpr)
    (success : psMinLowerUnusedBinderWorker expression depth = some result) :
    psExprLiftBVarsWorker 1 result depth = expression := by
  induction expression generalizing depth result with
  | bvar index =>
    by_cases small : Nat.blt index depth = true
    · have less : index < depth := by simpa only [Nat.blt_eq] using small
      have noLift : ¬ Nat.ble depth index = true := by
        intro lift
        have le : depth ≤ index := by simpa only [Nat.ble_eq] using lift
        exact (Nat.not_le_of_gt less) le
      simp [psMinLowerUnusedBinderWorker, small] at success
      subst result
      simp [psExprLiftBVarsWorker, noLift]
    · by_cases equal : Nat.beq index depth = true
      · simp [psMinLowerUnusedBinderWorker, small, equal] at success
      · have notSmall : ¬ index < depth := by simpa only [Nat.blt_eq] using small
        have notEqual : index ≠ depth := by simpa only [Nat.beq_eq] using equal
        have less : depth < index :=
          Nat.lt_of_le_of_ne (Nat.le_of_not_gt notSmall) (Ne.symm notEqual)
        cases index with
        | zero => exact False.elim (Nat.not_lt_zero depth less)
        | succ previous =>
          have lift : Nat.ble depth previous = true := by
            simpa only [Nat.ble_eq] using Nat.le_of_lt_succ less
          simp [psMinLowerUnusedBinderWorker, small, equal] at success
          subst result
          change (if Nat.ble depth previous then
            PsExpr.bvar (Nat.add previous 1) else PsExpr.bvar previous) =
              PsExpr.bvar (Nat.succ previous)
          rw [if_pos lift]
  | fvar id =>
      simp [psMinLowerUnusedBinderWorker] at success
      subst result
      rfl
  | mvar id =>
      simp [psMinLowerUnusedBinderWorker] at success
      subst result
      rfl
  | sortE level =>
      simp [psMinLowerUnusedBinderWorker] at success
      subst result
      rfl
  | constE name levels =>
      simp [psMinLowerUnusedBinderWorker] at success
      subst result
      rfl
  | lit value =>
      simp [psMinLowerUnusedBinderWorker] at success
      subst result
      rfl
  | app fn arg ihFn ihArg =>
      cases hFn : psMinLowerUnusedBinderWorker fn depth with
      | none => simp [psMinLowerUnusedBinderWorker, hFn] at success
      | some loweredFn =>
          cases hArg : psMinLowerUnusedBinderWorker arg depth with
          | none => simp [psMinLowerUnusedBinderWorker, hFn, hArg] at success
          | some loweredArg =>
              simp [psMinLowerUnusedBinderWorker, hFn, hArg] at success
              subst result
              simp only [psExprLiftBVarsWorker, ihFn depth loweredFn hFn, ihArg depth loweredArg hArg]
  | lam name type body binder ihType ihBody =>
      cases hType : psMinLowerUnusedBinderWorker type depth with
      | none => simp [psMinLowerUnusedBinderWorker, hType] at success
      | some loweredType =>
          cases hBody : psMinLowerUnusedBinderWorker body (Nat.succ depth) with
          | none => simp [psMinLowerUnusedBinderWorker, hType, hBody] at success
          | some loweredBody =>
              simp [psMinLowerUnusedBinderWorker, hType, hBody] at success
              subst result
              simp only [psExprLiftBVarsWorker, ihType depth loweredType hType, ihBody (Nat.succ depth) loweredBody hBody]
  | forallE name type body binder ihType ihBody =>
      cases hType : psMinLowerUnusedBinderWorker type depth with
      | none => simp [psMinLowerUnusedBinderWorker, hType] at success
      | some loweredType =>
          cases hBody : psMinLowerUnusedBinderWorker body (Nat.succ depth) with
          | none => simp [psMinLowerUnusedBinderWorker, hType, hBody] at success
          | some loweredBody =>
              simp [psMinLowerUnusedBinderWorker, hType, hBody] at success
              subst result
              simp only [psExprLiftBVarsWorker, ihType depth loweredType hType, ihBody (Nat.succ depth) loweredBody hBody]
  | letE name type value body ihType ihValue ihBody =>
      cases hType : psMinLowerUnusedBinderWorker type depth with
      | none => simp [psMinLowerUnusedBinderWorker, hType] at success
      | some loweredType =>
          cases hValue : psMinLowerUnusedBinderWorker value depth with
          | none => simp [psMinLowerUnusedBinderWorker, hType, hValue] at success
          | some loweredValue =>
              cases hBody : psMinLowerUnusedBinderWorker body (Nat.succ depth) with
              | none => simp [psMinLowerUnusedBinderWorker, hType, hValue, hBody] at success
              | some loweredBody =>
                  simp [psMinLowerUnusedBinderWorker, hType, hValue, hBody] at success
                  subst result
                  simp only [psExprLiftBVarsWorker, ihType depth loweredType hType, ihValue depth loweredValue hValue, ihBody (Nat.succ depth) loweredBody hBody]
  | proj name index value ihValue =>
      cases hValue : psMinLowerUnusedBinderWorker value depth with
      | none => simp [psMinLowerUnusedBinderWorker, hValue] at success
      | some loweredValue =>
          simp [psMinLowerUnusedBinderWorker, hValue] at success
          subst result
          simp only [psExprLiftBVarsWorker, ihValue depth loweredValue hValue]

theorem lower_sound (body result : PsExpr) (depth : Nat)
    (success : psMinLowerUnusedBinder depth body = some result) :
    psExprLiftBVars 1 depth result = body := by
  exact lower_worker_sound body depth result success

theorem lower_instantiate (body result replacement : PsExpr) (depth : Nat)
    (success : psMinLowerUnusedBinder depth body = some result) :
    psExprInstantiateAt replacement depth body = result := by
  rw [← lower_sound body result depth success]
  exact Ps.MinKernel.CoreScope.instantiate_lift result replacement depth

theorem lower_motive_body (body result major : PsExpr)
    (success : psMinLowerUnusedBinder 0 body = some result) :
    psExprInstantiate1 body major = result := by
  exact lower_instantiate body result major 0 success

#print axioms lower_sound
#print axioms lower_instantiate
#print axioms lower_motive_body

end Ps.MinKernel.BinderLowering
