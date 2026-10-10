import Ps.KernelCore.Metatheory.DefEqKnotConfiguration
import Ps.KernelCore.Metatheory.CheckerComposition
import Ps.KernelCore.Metatheory.BetaSpine

/-
Composition of the *concrete* executable checker entry points.

The public check, infer-only, WHNF and DefEq workers share the same fuel and
recursor callback wiring as the executable knot.  No abstract WHNF or DefEq
contracts remain as premises: they are instantiated by the fuel induction.

The two remaining explicitly stated external semantic boundaries are native
reduction and portable String comparison; the optimized beta-spine law is
internally proved and supplied by BetaSpine.
-/

def PsKernelConcreteCheckerConfigurationSound (fuel : Nat) : Prop :=
  PsKernelCheckedInferenceConfigurationSound
      (psKernelCheckerCheck fuel) ∧
    PsKernelInferOnlyConfigurationPreserves
      (psKernelCheckerInfer fuel) ∧
    PsKernelWhnfConfigurationSound
      (psKernelCheckerWhnf fuel) ∧
    PsKernelDefEqConfigurationSound
      (psKernelIsDefEq fuel)

theorem psKernelConcreteChecker_configuration_sound
    (fuel : Nat)
    (hNative : PsKernelNativeReductionSoundLaw)
    (hString : PsKernelStringEqSoundLaw) :
    PsKernelConcreteCheckerConfigurationSound fuel := by
  have hBeta : PsKernelBetaSpineSoundLaw :=
    psKernelBetaSpineSound_contract
  have hDefEq :
      PsKernelDefEqConfigurationSound
        (psKernelIsDefEqWithFuel fuel) :=
    psKernelIsDefEqWithFuel_configuration_sound
      fuel hBeta hNative hString
  have hWhnf :
      PsKernelWhnfConfigurationSound
        (psKernelWhnfWithRecursorFuel
          fuel (psKernelIsDefEqWithFuel fuel)) :=
    psKernelWhnfWithRecursorFuel_configuration_sound_of_defeq
      fuel (psKernelIsDefEqWithFuel fuel)
      hDefEq hBeta hNative
  exact
    ⟨
      psKernelCheckerCheck_configuration_sound_of_components
        fuel hString hWhnf hDefEq,
      psKernelCheckerInfer_configuration_preserves_of_whnf
        fuel hWhnf,
      psKernelCheckerWhnf_configuration_sound_of_core
        fuel hWhnf,
      psKernelIsDefEq_configuration_sound_of_core
        fuel hDefEq
    ⟩
