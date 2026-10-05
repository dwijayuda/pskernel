import Ps.KernelCore.Checker.ResourcePolicy

theorem psKernelResourcePreflight_cancelled
    (policy : PsKernelResourcePolicy)
    (h : policy.cancelled = true) :
    psKernelResourcePreflight policy =
      Option.some PsKernelResourceError.cancelled := by
  simp [psKernelResourcePreflight, h]

theorem psKernelResourcePreflight_zero_fuel
    (policy : PsKernelResourcePolicy)
    (hCancelled : policy.cancelled = false)
    (hFuel : policy.fuel = 0) :
    psKernelResourcePreflight policy =
      Option.some PsKernelResourceError.fuel := by
  simp [psKernelResourcePreflight, hCancelled, hFuel]

theorem psKernelResourceAllowsSize_unbounded
    (policy : PsKernelResourcePolicy)
    (declarations : Nat)
    (h : policy.maxDeclarations = 0) :
    psKernelResourceAllowsSize policy declarations = true := by
  simp [psKernelResourceAllowsSize, h]
