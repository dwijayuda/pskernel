import Ps.KernelCore.Checker.Reduction.PrimitiveNat

theorem psKernelNatPowWithFuel_zero
    (base exponent : Nat) :
    psKernelNatPowWithFuel 0 base exponent = 1 := by
  rfl

theorem psKernelNatBitwiseWithFuel_zero
    (op : PsKernelNatBitwiseOp)
    (left right : Nat) :
    psKernelNatBitwiseWithFuel 0 op left right = 0 := by
  rfl

theorem psKernelNatShiftRightWithFuel_zero
    (value count : Nat) :
    psKernelNatShiftRightWithFuel 0 value count = value := by
  rfl

theorem psKernelNatShiftLeft_def
    (value count : Nat) :
    psKernelNatShiftLeft value count =
      Nat.mul value (psKernelNatPow 2 count) := by
  rfl
