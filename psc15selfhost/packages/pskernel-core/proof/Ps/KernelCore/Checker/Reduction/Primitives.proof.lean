import Ps.KernelCore.Checker.Reduction.Primitives

theorem psKernelPrimitives_pow_zero_fuel
    (base exponent : Nat) :
    psKernelNatPowWithFuel 0 base exponent = 1 := by
  rfl
