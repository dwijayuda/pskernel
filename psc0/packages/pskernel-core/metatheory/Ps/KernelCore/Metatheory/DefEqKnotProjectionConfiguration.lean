import Ps.KernelCore.Metatheory.DefEqKnotLazyConfiguration
import Ps.KernelCore.Metatheory.DefEqProjectionShortcutConfiguration

/-
After LazyDelta returns a residual expression pair, the executable knot
attempts projection-sensitive comparison. Positive results carry independent
DefEq evidence for the residual pair and may be published for the original
terms through the already established reduction closures. A miss proceeds
to the final full-WHNF comparison phases as an explicit proof obligation.
-/

def PsKernelDefEqKnotAfterProjectionMissSound (fuel : Nat) : Prop :=
  ∀ (context nextContext : PsKernelCheckerContext)
    (state quickState reflectionState leftCoreState rightCoreState
      coreQuickState leftTypeState propState lazyState shortcutState
      nextState : PsKernelCheckerState)
    (left right leftCore rightCore leftType leftDelta rightDelta :
      PsKernelExpr)
    (value : Bool),
    PsKernelCheckerConfigurationSound nextContext shortcutState ->
    PsKernelReductionClosure
      nextContext.environment nextContext.localContext left leftDelta ->
    PsKernelReductionClosure
      nextContext.environment nextContext.localContext right rightDelta ->
    psKernelCheckerContextEnterRecDepth context =
      Except.ok nextContext ->
    psKernelExprEq left right = false ->
    psKernelDefEqSuccessCacheHit state left right = false ->
    psKernelDefEqQuick
        (psKernelIsDefEqWithFuel fuel)
        nextContext state left right =
      Except.ok (Prod.mk Option.none quickState) ->
    psKernelDefEqReflectionWith
        (psKernelWhnfWithRecursorFuel
          fuel (psKernelIsDefEqWithFuel fuel))
        nextContext quickState left right =
      Except.ok (Prod.mk Option.none reflectionState) ->
    psKernelWhnfCoreWithRecursorFuel
        fuel (psKernelIsDefEqWithFuel fuel)
        nextContext reflectionState left false true =
      Except.ok (Prod.mk leftCore leftCoreState) ->
    psKernelWhnfCoreWithRecursorFuel
        fuel (psKernelIsDefEqWithFuel fuel)
        nextContext leftCoreState right false true =
      Except.ok (Prod.mk rightCore rightCoreState) ->
    psKernelDefEqQuick
        (psKernelIsDefEqWithFuel fuel)
        nextContext rightCoreState leftCore rightCore =
      Except.ok (Prod.mk Option.none coreQuickState) ->
    psKernelInferWithRecursorFuel
        fuel (psKernelIsDefEqWithFuel fuel)
        nextContext coreQuickState leftCore =
      Except.ok (Prod.mk leftType leftTypeState) ->
    psKernelDefEqIsPropWith
        (psKernelInferWithRecursorFuel
          fuel (psKernelIsDefEqWithFuel fuel))
        (psKernelWhnfWithRecursorFuel
          fuel (psKernelIsDefEqWithFuel fuel))
        nextContext leftTypeState leftType =
      Except.ok (Prod.mk false propState) ->
    psKernelDefEqLazyReductionWithFuel
        fuel
        (psKernelIsDefEqWithFuel fuel)
        (psKernelWhnfWithRecursorFuel
          fuel (psKernelIsDefEqWithFuel fuel))
        (psKernelWhnfCoreWithRecursorFuel
          fuel (psKernelIsDefEqWithFuel fuel))
        nextContext propState leftCore rightCore =
      Except.ok
        (Prod.mk (PsKernelDeltaResult.residual leftDelta rightDelta)
          lazyState) ->
    psKernelDefEqProjectionShortcut
        fuel
        (psKernelIsDefEqWithFuel fuel)
        nextContext lazyState leftDelta rightDelta =
      Except.ok (Prod.mk Option.none shortcutState) ->
    psKernelIsDefEqWithFuel
        (Nat.succ fuel) context state left right =
      Except.ok (Prod.mk value nextState) ->
    PsKernelCheckerConfigurationSound nextContext nextState ∧
      (value = true ->
        PsKernelDefEqJudgment
          nextContext.environment nextContext.localContext left right)


theorem psKernelDefEqKnot_after_lazy_residual_sound_of_projection
    (fuel : Nat)
    (hDefEq :
      PsKernelDefEqConfigurationSound
        (psKernelIsDefEqWithFuel fuel))
    (hBeta : PsKernelBetaSpineSoundLaw)
    (hNative : PsKernelNativeReductionSoundLaw)
    (hString : PsKernelStringEqSoundLaw)
    (hAfterProjectionMiss :
      PsKernelDefEqKnotAfterProjectionMissSound fuel) :
    PsKernelDefEqKnotAfterLazyResidualSound fuel := by
  intro
    context nextContext
    state quickState reflectionState leftCoreState rightCoreState
    coreQuickState leftTypeState propState lazyState nextState
    left right leftCore rightCore leftType leftDelta rightDelta value
    hConfig hLeftReduction hRightReduction
    hEnter hDifferent hNotCached hQuickNone hReflectionNone
    hLeftCore hRightCore hCoreQuickNone hLeftInfer hPropFalse
    hLazyResidual hRun
  have hShortcut :
      PsKernelOptionalDefEqConfigurationSound
        (psKernelDefEqProjectionShortcut
          fuel
          (psKernelIsDefEqWithFuel fuel)) :=
    psKernelDefEqProjectionShortcut_configuration_sound
      fuel
      (psKernelIsDefEqWithFuel fuel)
      hDefEq hBeta hNative hString
  cases hShortcutRun :
      psKernelDefEqProjectionShortcut
        fuel
        (psKernelIsDefEqWithFuel fuel)
        nextContext lazyState leftDelta rightDelta with
  | error error =>
      simp [
        psKernelIsDefEqWithFuel,
        hEnter, hDifferent, hNotCached, hQuickNone,
        hReflectionNone, hLeftCore, hRightCore, hCoreQuickNone,
        hLeftInfer, hPropFalse, hLazyResidual, hShortcutRun
      ] at hRun
  | ok shortcutRun =>
      rcases shortcutRun with ⟨answer, shortcutState⟩
      have hShortcutSound :=
        hShortcut
          nextContext lazyState shortcutState leftDelta rightDelta
          answer hConfig hShortcutRun
      cases answer with
      | some shortcutValue =>
          have hFinish :
              (Except.ok
                  (psKernelDefEqFinish
                    shortcutState left right shortcutValue) :
                Except String (Prod Bool PsKernelCheckerState)) =
              Except.ok (Prod.mk value nextState) := by
            simpa [
              psKernelIsDefEqWithFuel,
              hEnter, hDifferent, hNotCached, hQuickNone,
              hReflectionNone, hLeftCore, hRightCore, hCoreQuickNone,
              hLeftInfer, hPropFalse, hLazyResidual, hShortcutRun
            ] using hRun
          exact
            psKernelDefEqKnot_publish_optional
              nextContext shortcutState nextState
              left right leftDelta rightDelta shortcutValue value
              hLeftReduction hRightReduction
              hShortcutSound hFinish
      | none =>
          exact
            hAfterProjectionMiss
              context nextContext
              state quickState reflectionState leftCoreState rightCoreState
              coreQuickState leftTypeState propState lazyState
              shortcutState nextState
              left right leftCore rightCore leftType leftDelta rightDelta value
              hShortcutSound.1 hLeftReduction hRightReduction
              hEnter hDifferent hNotCached
              hQuickNone hReflectionNone hLeftCore hRightCore
              hCoreQuickNone hLeftInfer hPropFalse
              hLazyResidual hShortcutRun hRun
