import Ps.KernelCore.Core.Substitution.Instantiate

theorem psKernelExprInstantiateAtChangedWithFuel_zero
    (expr : PsKernelExpr)
    (start offset : Nat)
    (subst : List PsKernelExpr) :
    psKernelExprInstantiateAtChangedWithFuel
        0 expr start subst offset =
      Prod.mk expr false := by
  rfl

theorem psKernelExprInstantiateAt_empty
    (expr : PsKernelExpr)
    (start offset : Nat) :
    psKernelExprInstantiateAt expr start List.nil offset = expr := by
  rfl

theorem psKernelExprInstantiate_empty
    (expr : PsKernelExpr) :
    psKernelExprInstantiate expr List.nil = expr := by
  rfl

theorem psKernelExprInstantiateRev_empty
    (expr : PsKernelExpr) :
    psKernelExprInstantiateRev expr List.nil = expr := by
  rfl

theorem psKernelExprInstantiate1_closed
    (expr replacement : PsKernelExpr)
    (h : psKernelExprHasLooseBVar expr = false) :
    psKernelExprInstantiate1 expr replacement = expr := by
  simp [psKernelExprInstantiate1, h]
