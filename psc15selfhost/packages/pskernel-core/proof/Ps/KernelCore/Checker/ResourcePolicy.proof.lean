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


theorem psKernelResourcePreflight_none_refines_ready
    (policy : PsKernelResourcePolicy)
    (hReady :
      psKernelResourcePreflight policy =
        Option.none) :
    policy.cancelled = false ∧
    policy.fuel ≠ 0 := by
  cases hCancelled : policy.cancelled with
  | true =>
      simp [
        psKernelResourcePreflight,
        hCancelled
      ] at hReady
  | false =>
      constructor
      · rfl
      · intro hFuel
        simp [
          psKernelResourcePreflight,
          hCancelled,
          hFuel
        ] at hReady

theorem psKernelResourceAllowsSize_true_refines_bound
    (policy : PsKernelResourcePolicy)
    (declarations : Nat)
    (hAllowed :
      psKernelResourceAllowsSize
          policy
          declarations =
        true) :
    policy.maxDeclarations = 0 ∨
      declarations ≤ policy.maxDeclarations := by
  cases hUnlimited :
      Nat.beq policy.maxDeclarations 0 with
  | true =>
      left
      simpa using hUnlimited
  | false =>
      right
      simpa [
        psKernelResourceAllowsSize,
        hUnlimited
      ] using hAllowed

theorem psKernelResourceAllowsSize_false_refines_overflow
    (policy : PsKernelResourcePolicy)
    (declarations : Nat)
    (hDenied :
      psKernelResourceAllowsSize
          policy
          declarations =
        false) :
    policy.maxDeclarations ≠ 0 ∧
      policy.maxDeclarations < declarations := by
  cases hUnlimited :
      Nat.beq policy.maxDeclarations 0 with
  | true =>
      simp [
        psKernelResourceAllowsSize,
        hUnlimited
      ] at hDenied
  | false =>
      have hNonzero :
          policy.maxDeclarations ≠ 0 := by
        intro hZero
        have hEqTrue :
            Nat.beq policy.maxDeclarations 0 = true := by
          simpa [hZero]
        rw [hUnlimited] at hEqTrue
        cases hEqTrue
      have hNotLe :
          ¬ declarations ≤ policy.maxDeclarations := by
        intro hLe
        have hBleTrue :
            Nat.ble declarations policy.maxDeclarations = true :=
          Nat.ble_eq_true_of_le hLe
        have hBleFalse :
            Nat.ble declarations policy.maxDeclarations = false := by
          simpa [
            psKernelResourceAllowsSize,
            hUnlimited
          ] using hDenied
        rw [hBleFalse] at hBleTrue
        cases hBleTrue
      exact
        ⟨
          hNonzero,
          Nat.lt_of_not_ge hNotLe
        ⟩
