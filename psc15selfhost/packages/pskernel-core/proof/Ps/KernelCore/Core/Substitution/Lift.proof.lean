import Ps.KernelCore.Core.Substitution.Lift

theorem psKernelExprLiftLooseBVarsChangedWithFuel_zero
    (expr : PsKernelExpr)
    (start amount : Nat) :
    psKernelExprLiftLooseBVarsChangedWithFuel
        0 expr start amount =
      Prod.mk expr false := by
  rfl

theorem psKernelExprLiftLooseBVarsChanged_zero_amount
    (expr : PsKernelExpr)
    (start : Nat) :
    psKernelExprLiftLooseBVarsChanged expr start 0 =
      Prod.mk expr false := by
  simp [psKernelExprLiftLooseBVarsChanged]

theorem psKernelExprLiftLooseBVars_zero_amount
    (expr : PsKernelExpr)
    (start : Nat) :
    psKernelExprLiftLooseBVars expr start 0 = expr := by
  simp [psKernelExprLiftLooseBVars, psKernelExprLiftLooseBVarsChanged_zero_amount]

theorem psKernelExprLift_zero
    (expr : PsKernelExpr) :
    psKernelExprLift expr 0 = expr := by
  simp [psKernelExprLift, psKernelExprLiftLooseBVars_zero_amount]
