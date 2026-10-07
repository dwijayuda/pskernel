import Ps.KernelCore.Checker.Knot
import Ps.KernelCore.Metatheory.RecursorReduction
import Ps.KernelCore.Metatheory.WhnfConfiguration
import Ps.KernelCore.Metatheory.InferenceConfiguration
import Ps.KernelCore.Metatheory.BetaSpine

/-
Concrete bounded-recursion configuration theorem.

This is the first checker-knot theorem that follows the executable fuel
dependency graph instead of reopening recursor or WHNF branches:

  smaller bounded recursor
    -> public WHNF
    -> WHNF core
    -> infer-only preservation
    -> K / structure conversion
    -> inductive / Quot recursor composition.

DefEq remains an explicit callback contract here because the final concrete
checker knot must prove DefEq and recursor/WHNF together. Native evaluator
correctness remains the already-named TCB law consumed by public WHNF.
-/

theorem psKernelReduceRecursorBoundedWithFuel_configuration_sound
    (fuel : Nat)
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String (Prod Bool PsKernelCheckerState))
    (hDefEq :
      PsKernelDefEqConfigurationSound defeq)
    (hBeta :
      PsKernelBetaSpineSoundLaw)
    (hNative :
      PsKernelNativeReductionSoundLaw) :
    PsKernelRecursorReductionConfigurationSound
      (psKernelReduceRecursorBoundedWithFuel
        fuel
        defeq) := by
  induction fuel with
  | zero =>
      intro
        context state nextState expr
        cheapRec cheapProj answer
        hConfig hSuccess
      simp [psKernelReduceRecursorBoundedWithFuel] at hSuccess
  | succ remaining ih =>
      let reducer :=
        psKernelReduceRecursorBoundedWithFuel
          remaining
          defeq
      let publicWhnf :=
        psKernelWhnfWithFuel
          remaining
          reducer
      let coreWhnf :=
        psKernelWhnfCoreWithFuel
          remaining
          publicWhnf
          reducer
      let inferType :=
        psKernelInferWithFuel
          remaining
          publicWhnf
          defeq
      have hReducer :
          PsKernelRecursorReductionConfigurationSound
            reducer := by
        simpa [reducer] using ih
      have hWhnf :
          PsKernelWhnfConfigurationSound
            publicWhnf := by
        simpa [publicWhnf] using
          (psKernelWhnfWithFuel_configuration_sound_contract
            remaining
            reducer
            hReducer
            hBeta
            hNative)
      have hCore :
          PsKernelWhnfCoreConfigurationSound
            coreWhnf := by
        simpa [coreWhnf] using
          (psKernelWhnfCoreWithFuel_configuration_sound_contract
            remaining
            publicWhnf
            reducer
            hWhnf
            hReducer
            hBeta)
      have hInferCore :
          PsKernelInferOnlyCoreConfigurationPreserves
            publicWhnf
            defeq :=
        psKernelInferOnlyCoreConfigurationPreserves_contract
          publicWhnf
          defeq
          hWhnf
      have hInfer :
          PsKernelInferOnlyConfigurationPreserves
            inferType := by
        intro
          context state nextState expr result
          hConfig hSuccess
        apply
          hInferCore
            remaining
            context
            state
            nextState
            expr
            result
            hConfig
        simpa [
          inferType,
          psKernelInferWithFuel
        ] using hSuccess
      have hK :
          PsKernelRecursorKConversionConfigurationSound
            publicWhnf
            inferType
            defeq :=
        psKernelToConstructorWhenK_configuration_sound_of_components
          publicWhnf
          inferType
          defeq
          hWhnf
          hInfer
          hDefEq
      have hStructure :
          PsKernelRecursorStructureConversionConfigurationSound
            publicWhnf
            inferType :=
        psKernelToConstructorWhenStructure_configuration_sound_of_components
          publicWhnf
          inferType
          hWhnf
          hInfer
      have hInductive :
          PsKernelRecursorReductionConfigurationSound
            (psKernelReduceInductiveRecWith
              publicWhnf
              coreWhnf
              inferType
              defeq) :=
        psKernelReduceInductiveRecWith_configuration_sound_of_components
          publicWhnf
          coreWhnf
          inferType
          defeq
          hWhnf
          hCore
          hK
          hStructure
      have hRecursor :
          PsKernelRecursorReductionConfigurationSound
            (psKernelReduceRecursorWith
              publicWhnf
              coreWhnf
              inferType
              defeq) :=
        psKernelReduceRecursorWith_configuration_sound_of_inductive
          publicWhnf
          coreWhnf
          inferType
          defeq
          hWhnf
          hInductive
      simpa [
        psKernelReduceRecursorBoundedWithFuel,
        reducer,
        publicWhnf,
        coreWhnf,
        inferType
      ] using hRecursor
