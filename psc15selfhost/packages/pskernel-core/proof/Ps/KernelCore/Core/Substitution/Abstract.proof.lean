import Ps.KernelCore.Core.Substitution.Abstract

theorem psKernelNameLastIndexWorker_nil
    (needle : PsKernelName)
    (index : Nat)
    (answer : Option Nat) :
    psKernelNameLastIndexWorker List.nil needle index answer = answer := by
  rfl

theorem psKernelNameLastIndex_nil
    (needle : PsKernelName) :
    psKernelNameLastIndex needle List.nil = Option.none := by
  rfl

theorem psKernelExprAbstractFVarsAtChangedWithFuel_zero
    (expr : PsKernelExpr)
    (fvars : List PsKernelName)
    (offset : Nat) :
    psKernelExprAbstractFVarsAtChangedWithFuel
        0 expr fvars offset =
      Prod.mk expr false := by
  rfl

theorem psKernelExprAbstractFVarsAt_empty
    (expr : PsKernelExpr)
    (offset : Nat) :
    psKernelExprAbstractFVarsAt expr List.nil offset = expr := by
  rfl

theorem psKernelExprAbstractFVars_empty
    (expr : PsKernelExpr) :
    psKernelExprAbstractFVars expr List.nil = expr := by
  rfl
