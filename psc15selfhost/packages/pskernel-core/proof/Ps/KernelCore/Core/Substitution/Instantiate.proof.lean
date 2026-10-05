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

theorem psKernelExprInstantiate1_bvar_zero
    (replacement : PsKernelExpr) :
    psKernelExprInstantiate1
        (PsKernelExpr.bvar 0)
        replacement =
      replacement := by
  rfl

theorem psKernelExprInstantiate1_bvar_succ
    (index : Nat)
    (replacement : PsKernelExpr) :
    psKernelExprInstantiate1
        (PsKernelExpr.bvar (Nat.succ index))
        replacement =
      PsKernelExpr.bvar index := by
  rfl

theorem psKernelExprInstantiate1_under_one_lambda
    (name : PsKernelName)
    (level : PsKernelLevel)
    (binderInfo : PsKernelBinderInfo)
    (replacement : PsKernelExpr) :
    psKernelExprInstantiate1
        (PsKernelExpr.lam
          name
          (PsKernelExpr.sort level)
          (PsKernelExpr.bvar 1)
          binderInfo)
        replacement =
      PsKernelExpr.lam
        name
        (PsKernelExpr.sort level)
        (psKernelExprLift replacement 1)
        binderInfo := by
  rfl

theorem psKernelExprInstantiateAt_bvar_before
    (index start offset : Nat)
    (replacement : PsKernelExpr)
    (h :
      psKernelNatLt
          index
          (Nat.add start offset) =
        true) :
    psKernelExprInstantiateAt
        (PsKernelExpr.bvar index)
        start
        (List.cons replacement List.nil)
        offset =
      PsKernelExpr.bvar index := by
  simp [
    psKernelExprInstantiateAt,
    psKernelExprListIsEmpty,
    psKernelExprInstantiateAtChanged,
    psKernelExprInstantiateAtChangedWithFuel,
    psKernelExprNodeCount,
    h
  ]

theorem psKernelExprInstantiateAt_bvar_hit
    (start offset : Nat)
    (replacement : PsKernelExpr) :
    psKernelExprInstantiateAt
        (PsKernelExpr.bvar (Nat.add start offset))
        start
        (List.cons replacement List.nil)
        offset =
      psKernelExprLiftLooseBVars
        replacement
        0
        offset := by
  simp [
    psKernelExprInstantiateAt,
    psKernelExprListIsEmpty,
    psKernelExprInstantiateAtChanged,
    psKernelExprInstantiateAtChangedWithFuel,
    psKernelExprNodeCount,
    psKernelNatLt,
    psKernelExprListGet
  ]
