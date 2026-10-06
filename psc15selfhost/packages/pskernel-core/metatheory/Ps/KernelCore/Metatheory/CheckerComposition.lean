import Ps.KernelCore.Checker.Knot
import Ps.KernelCore.Metatheory.CheckedInferenceConfiguration

/-
Importable composition layer for the public checker wrappers.

The substantial checked-inference proof lives in CheckedInferenceConfiguration.
These theorems expose the exact contracts of the public knot entry points without
repeating the core fuel induction.  The remaining assumptions are deliberately
the concrete WHNF and DefEq configuration contracts that the checker-knot proof
must discharge.
-/

theorem psKernelCheckerCheck_configuration_sound_of_core
    (fuel : Nat)
    (hCore :
      PsKernelCheckedInferenceCoreConfigurationSound
        (psKernelWhnfWithRecursorFuel
          fuel
          (psKernelIsDefEqWithFuel fuel))
        (psKernelIsDefEqWithFuel fuel)) :
    PsKernelCheckedInferenceConfigurationSound
      (psKernelCheckerCheck fuel) := by
  intro context state nextState expr result hConfig hSuccess
  unfold psKernelCheckerCheck at hSuccess
  unfold psKernelCheckWithFuel at hSuccess
  exact
    hCore
      fuel
      context
      state
      nextState
      expr
      result
      hConfig
      hSuccess


theorem psKernelCheckerInfer_configuration_preserves_of_core
    (fuel : Nat)
    (hCore :
      PsKernelInferOnlyCoreConfigurationPreserves
        (psKernelWhnfWithRecursorFuel
          fuel
          (psKernelIsDefEqWithFuel fuel))
        (psKernelIsDefEqWithFuel fuel)) :
    PsKernelInferOnlyConfigurationPreserves
      (psKernelCheckerInfer fuel) := by
  intro context state nextState expr result hConfig hSuccess
  unfold psKernelCheckerInfer at hSuccess
  unfold psKernelInferWithRecursorFuel at hSuccess
  unfold psKernelInferWithFuel at hSuccess
  exact
    hCore
      fuel
      context
      state
      nextState
      expr
      result
      hConfig
      hSuccess


theorem psKernelCheckerWhnf_configuration_sound_of_core
    (fuel : Nat)
    (hWhnf :
      PsKernelWhnfConfigurationSound
        (psKernelWhnfWithRecursorFuel
          fuel
          (psKernelIsDefEqWithFuel fuel))) :
    PsKernelWhnfConfigurationSound
      (psKernelCheckerWhnf fuel) := by
  intro context state nextState expr result hConfig hSuccess
  unfold psKernelCheckerWhnf at hSuccess
  exact
    hWhnf
      context
      state
      nextState
      expr
      result
      hConfig
      hSuccess


theorem psKernelIsDefEq_configuration_sound_of_core
    (fuel : Nat)
    (hDefEq :
      PsKernelDefEqConfigurationSound
        (psKernelIsDefEqWithFuel fuel)) :
    PsKernelDefEqConfigurationSound
      (psKernelIsDefEq fuel) := by
  intro context state nextState left right value hConfig hSuccess
  unfold psKernelIsDefEq at hSuccess
  exact
    hDefEq
      context
      state
      nextState
      left
      right
      value
      hConfig
      hSuccess


theorem psKernelCheckerCheck_configuration_sound_of_components
    (fuel : Nat)
    (hString : PsKernelStringEqSoundLaw)
    (hWhnf :
      PsKernelWhnfConfigurationSound
        (psKernelWhnfWithRecursorFuel
          fuel
          (psKernelIsDefEqWithFuel fuel)))
    (hDefEq :
      PsKernelDefEqConfigurationSound
        (psKernelIsDefEqWithFuel fuel)) :
    PsKernelCheckedInferenceConfigurationSound
      (psKernelCheckerCheck fuel) :=
  psKernelCheckerCheck_configuration_sound_of_core
    fuel
    (psKernelCheckedInferenceCoreConfigurationSound_contract
      (psKernelWhnfWithRecursorFuel
        fuel
        (psKernelIsDefEqWithFuel fuel))
      (psKernelIsDefEqWithFuel fuel)
      hString
      hWhnf
      hDefEq)


theorem psKernelCheckerInfer_configuration_preserves_of_whnf
    (fuel : Nat)
    (hWhnf :
      PsKernelWhnfConfigurationSound
        (psKernelWhnfWithRecursorFuel
          fuel
          (psKernelIsDefEqWithFuel fuel))) :
    PsKernelInferOnlyConfigurationPreserves
      (psKernelCheckerInfer fuel) :=
  psKernelCheckerInfer_configuration_preserves_of_core
    fuel
    (psKernelInferOnlyCoreConfigurationPreserves_contract
      (psKernelWhnfWithRecursorFuel
        fuel
        (psKernelIsDefEqWithFuel fuel))
      (psKernelIsDefEqWithFuel fuel)
      hWhnf)
