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

theorem psKernelExprLift_bvar
    (index amount : Nat) :
    psKernelExprLift (PsKernelExpr.bvar index) amount =
      PsKernelExpr.bvar (Nat.add index amount) := by
  cases amount <;> rfl

theorem psKernelExprLift_under_one_lambda
    (name : PsKernelName)
    (level : PsKernelLevel)
    (binderInfo : PsKernelBinderInfo) :
    psKernelExprLift
        (PsKernelExpr.lam
          name
          (PsKernelExpr.sort level)
          (PsKernelExpr.bvar 1)
          binderInfo)
        1 =
      PsKernelExpr.lam
        name
        (PsKernelExpr.sort level)
        (PsKernelExpr.bvar 2)
        binderInfo := by
  rfl

theorem psKernelExprLiftLooseBVars_bvar
    (index start amount : Nat) :
    psKernelExprLiftLooseBVars
        (PsKernelExpr.bvar index)
        start
        amount =
      if psKernelNatGe index start then
        PsKernelExpr.bvar (Nat.add index amount)
      else
        PsKernelExpr.bvar index := by
  cases amount <;>
    simp [
      psKernelExprLiftLooseBVars,
      psKernelExprLiftLooseBVarsChanged,
      psKernelExprLiftLooseBVarsChangedWithFuel,
      psKernelExprNodeCount
    ]

theorem psKernelExprLiftLooseBVars_bvar_hit
    (index start amount : Nat)
    (h : psKernelNatGe index start = true) :
    psKernelExprLiftLooseBVars
        (PsKernelExpr.bvar index)
        start
        amount =
      PsKernelExpr.bvar (Nat.add index amount) := by
  rw [psKernelExprLiftLooseBVars_bvar]
  simp [h]

theorem psKernelExprLiftLooseBVars_bvar_miss
    (index start amount : Nat)
    (h : psKernelNatGe index start = false) :
    psKernelExprLiftLooseBVars
        (PsKernelExpr.bvar index)
        start
        amount =
      PsKernelExpr.bvar index := by
  rw [psKernelExprLiftLooseBVars_bvar]
  simp [h]
