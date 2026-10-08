import Ps.KernelCore.Metatheory.DefEqKnotFullWhnfConfiguration
import Ps.KernelCore.Metatheory.DefEqFullShapeConfiguration

/-
Final concrete DefEq knot dispatcher.

At this point both operands have already been reduced by the full core-WHNF
phase. A changed pair is compared recursively, while an unchanged pair enters
the independently proved full-shape optional comparison. If that comparison
cannot decide, the existing proved after-full-shape continuation runs.

Only explicit reduction closures, not DefEq transitivity, carry soundness
back to the original arguments on the two branches.
-/

theorem psKernelDefEqKnot_after_full_whnf_configuration_sound
    (fuel : Nat)
    (hDefEq :
      PsKernelDefEqConfigurationSound
        (psKernelIsDefEqWithFuel fuel))
    (hBeta : PsKernelBetaSpineSoundLaw)
    (hNative : PsKernelNativeReductionSoundLaw)
    (hString : PsKernelStringEqSoundLaw) :
    PsKernelDefEqKnotAfterFullWhnfSound fuel := by
  intro
    context nextContext
    state quickState reflectionState leftCoreState rightCoreState
    coreQuickState leftTypeState propState lazyState shortcutState
    leftFullState rightFullState nextState
    left right leftCore rightCore leftType leftDelta rightDelta
    leftFull rightFull value
    hConfig hLeftReduction hRightReduction
    hEnter hDifferent hNotCached hQuickNone hReflectionNone
    hLeftCore hRightCore hCoreQuickNone hLeftInfer hPropFalse
    hLazyResidual hShortcutNone hLeftFull hRightFull hRun
  have hWhnf :
      PsKernelWhnfConfigurationSound
        (psKernelWhnfWithRecursorFuel
          fuel (psKernelIsDefEqWithFuel fuel)) :=
    psKernelWhnfWithRecursorFuel_configuration_sound_of_defeq
      fuel (psKernelIsDefEqWithFuel fuel)
      hDefEq hBeta hNative
  have hInfer :
      PsKernelInferOnlyConfigurationPreserves
        (psKernelInferWithRecursorFuel
          fuel (psKernelIsDefEqWithFuel fuel)) :=
    psKernelInferWithRecursorFuel_configuration_preserves_of_defeq
      fuel (psKernelIsDefEqWithFuel fuel)
      hDefEq hBeta hNative
  cases hChanged :
      (if psKernelExprEq leftFull leftDelta then
         if psKernelExprEq rightFull rightDelta then false else true
       else true) with
  | true =>
      cases hCompare :
          psKernelIsDefEqWithFuel fuel
            nextContext rightFullState leftFull rightFull with
      | error error =>
          simp [
            psKernelIsDefEqWithFuel,
            hEnter, hDifferent, hNotCached, hQuickNone,
            hReflectionNone, hLeftCore, hRightCore, hCoreQuickNone,
            hLeftInfer, hPropFalse, hLazyResidual, hShortcutNone,
            hLeftFull, hRightFull, hChanged, hCompare
          ] at hRun
      | ok compareRun =>
          rcases compareRun with ⟨compareValue, comparedState⟩
          have hFinish :
              (Except.ok
                  (psKernelDefEqFinish
                    comparedState left right compareValue) :
                Except String (Prod Bool PsKernelCheckerState)) =
              Except.ok (Prod.mk value nextState) := by
            simpa [
              psKernelIsDefEqWithFuel,
              hEnter, hDifferent, hNotCached, hQuickNone,
              hReflectionNone, hLeftCore, hRightCore, hCoreQuickNone,
              hLeftInfer, hPropFalse, hLazyResidual, hShortcutNone,
              hLeftFull, hRightFull, hChanged, hCompare
            ] using hRun
          exact
            psKernelDefEqKnot_publish_recursive_comparison
              (psKernelIsDefEqWithFuel fuel)
              hDefEq
              nextContext rightFullState comparedState nextState
              left right leftFull rightFull compareValue value
              hConfig hLeftReduction hRightReduction
              hCompare hFinish
  | false =>
      have hFullShape :
          PsKernelOptionalDefEqConfigurationSound
            (psKernelDefEqFullShapeWith
              (psKernelIsDefEqWithFuel fuel)
              (psKernelInferWithRecursorFuel
                fuel (psKernelIsDefEqWithFuel fuel))
              (psKernelWhnfWithRecursorFuel
                fuel (psKernelIsDefEqWithFuel fuel))) :=
        psKernelDefEqFullShapeWith_configuration_sound
          (psKernelIsDefEqWithFuel fuel)
          (psKernelInferWithRecursorFuel
            fuel (psKernelIsDefEqWithFuel fuel))
          (psKernelWhnfWithRecursorFuel
            fuel (psKernelIsDefEqWithFuel fuel))
          hDefEq hInfer hWhnf hString
      cases hShape :
          psKernelDefEqFullShapeWith
            (psKernelIsDefEqWithFuel fuel)
            (psKernelInferWithRecursorFuel
              fuel (psKernelIsDefEqWithFuel fuel))
            (psKernelWhnfWithRecursorFuel
              fuel (psKernelIsDefEqWithFuel fuel))
            nextContext rightFullState leftFull rightFull with
      | error error =>
          simp [
            psKernelIsDefEqWithFuel,
            hEnter, hDifferent, hNotCached, hQuickNone,
            hReflectionNone, hLeftCore, hRightCore, hCoreQuickNone,
            hLeftInfer, hPropFalse, hLazyResidual, hShortcutNone,
            hLeftFull, hRightFull, hChanged, hShape
          ] at hRun
      | ok shapeRun =>
          rcases shapeRun with ⟨shapeAnswer, shapeState⟩
          have hShapeSound :=
            hFullShape
              nextContext rightFullState shapeState
              leftFull rightFull shapeAnswer hConfig hShape
          cases shapeAnswer with
          | some shapeValue =>
              have hFinish :
                  (Except.ok
                      (psKernelDefEqFinish
                        shapeState left right shapeValue) :
                    Except String (Prod Bool PsKernelCheckerState)) =
                  Except.ok (Prod.mk value nextState) := by
                simpa [
                  psKernelIsDefEqWithFuel,
                  hEnter, hDifferent, hNotCached, hQuickNone,
                  hReflectionNone, hLeftCore, hRightCore, hCoreQuickNone,
                  hLeftInfer, hPropFalse, hLazyResidual, hShortcutNone,
                  hLeftFull, hRightFull, hChanged, hShape
                ] using hRun
              exact
                psKernelDefEqKnot_publish_optional
                  nextContext shapeState nextState
                  left right leftFull rightFull shapeValue value
                  hLeftReduction hRightReduction hShapeSound hFinish
          | none =>
              have hTail :
                  psKernelIsDefEqAfterFullShape
                      (psKernelIsDefEqWithFuel fuel)
                      (psKernelInferWithRecursorFuel
                        fuel (psKernelIsDefEqWithFuel fuel))
                      (psKernelWhnfWithRecursorFuel
                        fuel (psKernelIsDefEqWithFuel fuel))
                      nextContext shapeState
                      left right leftFull rightFull =
                    Except.ok (Prod.mk value nextState) := by
                simpa [
                  psKernelIsDefEqWithFuel,
                  hEnter, hDifferent, hNotCached, hQuickNone,
                  hReflectionNone, hLeftCore, hRightCore, hCoreQuickNone,
                  hLeftInfer, hPropFalse, hLazyResidual, hShortcutNone,
                  hLeftFull, hRightFull, hChanged, hShape
                ] using hRun
              exact
                psKernelIsDefEqAfterFullShape_configuration_sound
                  (psKernelIsDefEqWithFuel fuel)
                  (psKernelInferWithRecursorFuel
                    fuel (psKernelIsDefEqWithFuel fuel))
                  (psKernelWhnfWithRecursorFuel
                    fuel (psKernelIsDefEqWithFuel fuel))
                  hDefEq hInfer hWhnf
                  nextContext shapeState nextState
                  left right leftFull rightFull value
                  hShapeSound.1 hLeftReduction hRightReduction hTail
