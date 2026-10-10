import Ps.KernelCore.Metatheory.DefEqKnotFinalConfiguration

/-
Concrete fuel induction for the complete executable DefEq checker.

Each successor step is discharged by composition of the independently proved
pieces: original structural/cache checks; Quick; reflection; two cheap core
WHNFs and Quick on the reduced pair; proof irrelevance; bounded LazyDelta;
projection shortcut; two full core WHNFs; recursive changed comparison; full
shape; and the final structure/string/unit continuation.

The induction hypothesis is used only for strictly smaller DefEq fuel. The
underlying recursor and WHNF callbacks consume their previously established
configuration contracts, and native reduction remains explicitly named as a
trusted capability rather than silently becoming a theorem. Algorithmic
DefEq is NOT assumed transitive.
-/

theorem psKernelIsDefEqWithFuel_configuration_sound
    (fuel : Nat)
    (hBeta : PsKernelBetaSpineSoundLaw)
    (hNative : PsKernelNativeReductionSoundLaw)
    (hString : PsKernelStringEqSoundLaw) :
    PsKernelDefEqConfigurationSound
      (psKernelIsDefEqWithFuel fuel) := by
  induction fuel with
  | zero =>
      exact psKernelDefEqKnot_zero_configuration_sound
  | succ remaining ih =>
      have hFinal :
          PsKernelDefEqKnotAfterFullWhnfSound remaining :=
        psKernelDefEqKnot_after_full_whnf_configuration_sound
          remaining ih hBeta hNative hString
      have hFullWhnf :
          PsKernelDefEqKnotAfterProjectionMissSound remaining :=
        psKernelDefEqKnot_after_projection_sound_of_full_whnf
          remaining ih hBeta hNative hFinal
      have hProjection :
          PsKernelDefEqKnotAfterLazyResidualSound remaining :=
        psKernelDefEqKnot_after_lazy_residual_sound_of_projection
          remaining ih hBeta hNative hString hFullWhnf
      have hLazy :
          PsKernelDefEqKnotAfterNonPropSound remaining :=
        psKernelDefEqKnot_after_nonprop_sound_of_lazy
          remaining ih hBeta hNative hString hProjection
      have hNonProp :
          PsKernelDefEqKnotAfterCoreQuickSound remaining :=
        psKernelDefEqKnot_after_core_quick_sound_of_nonprop
          remaining ih hBeta hNative hLazy
      have hCoreQuick :
          PsKernelDefEqKnotAfterReflectionSound remaining :=
        psKernelDefEqKnot_after_reflection_sound_of_core_quick
          remaining ih hBeta hNative hString hNonProp
      have hReflection :
          PsKernelDefEqKnotAfterQuickSound remaining :=
        psKernelDefEqKnot_after_quick_sound_of_reflection
          remaining ih hBeta hNative hString hCoreQuick
      have hQuick :
          PsKernelDefEqKnotMissConfigurationSound remaining :=
        psKernelDefEqKnot_miss_sound_of_after_quick
          remaining ih hString hReflection
      exact
        psKernelIsDefEqWithFuel_succ_configuration_sound_of_miss
          remaining hQuick
