import Ps.KernelCore.Checker.Reduction.PrimitiveData

theorem psKernelNatGcdWithFuel_zero
    (left right : Nat) :
    psKernelNatGcdWithFuel 0 left right = left := by
  rfl

theorem psKernelNatHeapWordCountWithFuel_zero
    (value : Nat) :
    psKernelNatHeapWordCountWithFuel 0 value = 0 := by
  rfl

theorem psKernelBoolExpr_true :
    psKernelBoolExpr true =
      PsKernelExpr.const psKernelBoolTrueName List.nil := by
  rfl

theorem psKernelBoolExpr_false :
    psKernelBoolExpr false =
      PsKernelExpr.const psKernelBoolFalseName List.nil := by
  rfl
