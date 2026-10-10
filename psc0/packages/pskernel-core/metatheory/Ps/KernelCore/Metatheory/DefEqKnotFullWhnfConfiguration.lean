import Ps.KernelCore.Metatheory.DefEqKnotProjectionConfiguration

/-
In the final DefEq phase the two residual operands are each normalized using
core WHNF with both cheap flags disabled. The semantic relation connecting
the original pair to those final shapes is the COMPOSITION of the earlier
lazy-delta residual reductions and these two independent core reductions.

The remaining final changed/full-shape dispatch is explicit. No algorithmic
DefEq transitivity is introduced by this composition.
-/

def PsKernelDefEqKnotAfterFullWhnfSound (fuel : Nat) : Prop :=
  ∀ (context nextContext : PsKernelCheckerContext)
    (state quickState reflectionState leftCoreState rightCoreState
      coreQuickState leftTypeState propState lazyState shortcutState
      leftFullState rightFullState nextState : PsKernelCheckerState)
    (left right leftCore rightCore leftType leftDelta rightDelta
      leftFull rightFull : PsKernelExpr)
    (value : Bool),
    PsKernelCheckerConfigurationSound nextContext rightFullState ->
    PsKernelReductionClosure
      nextContext.environment nextContext.localContext left leftFull ->
    PsKernelReductionClosure
      nextContext.environment nextContext.localContext right rightFull ->
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
    psKernelWhnfCoreWithRecursorFuel
        fuel (psKernelIsDefEqWithFuel fuel)
        nextContext shortcutState leftDelta false false =
      Except.ok (Prod.mk leftFull leftFullState) ->
    psKernelWhnfCoreWithRecursorFuel
        fuel (psKernelIsDefEqWithFuel fuel)
        nextContext leftFullState rightDelta false false =
      Except.ok (Prod.mk rightFull rightFullState) ->
    psKernelIsDefEqWithFuel
        (Nat.succ fuel) context state left right =
      Except.ok (Prod.mk value nextState) ->
    PsKernelCheckerConfigurationSound nextContext nextState ∧
      (value = true ->
        PsKernelDefEqJudgment
          nextContext.environment nextContext.localContext left right)


theorem psKernelDefEqKnot_after_projection_sound_of_full_whnf
    (fuel : Nat)
    (hDefEq :
      PsKernelDefEqConfigurationSound
        (psKernelIsDefEqWithFuel fuel))
    (hBeta : PsKernelBetaSpineSoundLaw)
    (hNative : PsKernelNativeReductionSoundLaw)
    (hAfterFullWhnf : PsKernelDefEqKnotAfterFullWhnfSound fuel) :
    PsKernelDefEqKnotAfterProjectionMissSound fuel := by
  intro
    context nextContext
    state quickState reflectionState leftCoreState rightCoreState
    coreQuickState leftTypeState propState lazyState shortcutState nextState
    left right leftCore rightCore leftType leftDelta rightDelta value
    hConfig hLeftReduction hRightReduction
    hEnter hDifferent hNotCached hQuickNone hReflectionNone
    hLeftCore hRightCore hCoreQuickNone hLeftInfer hPropFalse
    hLazyResidual hShortcutNone hRun
  have hCore :
      PsKernelWhnfCoreConfigurationSound
        (psKernelWhnfCoreWithRecursorFuel
          fuel (psKernelIsDefEqWithFuel fuel)) :=
    psKernelWhnfCoreWithRecursorFuel_configuration_sound_of_defeq
      fuel (psKernelIsDefEqWithFuel fuel)
      hDefEq hBeta hNative
  cases hLeftFull :
      psKernelWhnfCoreWithRecursorFuel
        fuel (psKernelIsDefEqWithFuel fuel)
        nextContext shortcutState leftDelta false false with
  | error error =>
      simp [
        psKernelIsDefEqWithFuel,
        hEnter, hDifferent, hNotCached, hQuickNone,
        hReflectionNone, hLeftCore, hRightCore, hCoreQuickNone,
        hLeftInfer, hPropFalse, hLazyResidual, hShortcutNone, hLeftFull
      ] at hRun
  | ok leftRun =>
      rcases leftRun with ⟨leftFull, leftFullState⟩
      have hLeftSound :=
        hCore
          nextContext shortcutState leftFullState
          leftDelta leftFull false false hConfig hLeftFull
      cases hRightFull :
          psKernelWhnfCoreWithRecursorFuel
            fuel (psKernelIsDefEqWithFuel fuel)
            nextContext leftFullState rightDelta false false with
      | error error =>
          simp [
            psKernelIsDefEqWithFuel,
            hEnter, hDifferent, hNotCached, hQuickNone,
            hReflectionNone, hLeftCore, hRightCore, hCoreQuickNone,
            hLeftInfer, hPropFalse, hLazyResidual, hShortcutNone,
            hLeftFull, hRightFull
          ] at hRun
      | ok rightRun =>
          rcases rightRun with ⟨rightFull, rightFullState⟩
          have hRightSound :=
            hCore
              nextContext leftFullState rightFullState
              rightDelta rightFull false false hLeftSound.2 hRightFull
          have hOriginalLeft :
              PsKernelReductionClosure
                nextContext.environment nextContext.localContext
                left leftFull :=
            psKernelReductionClosure_trans
              nextContext.environment nextContext.localContext
              left leftDelta leftFull hLeftReduction hLeftSound.1
          have hOriginalRight :
              PsKernelReductionClosure
                nextContext.environment nextContext.localContext
                right rightFull :=
            psKernelReductionClosure_trans
              nextContext.environment nextContext.localContext
              right rightDelta rightFull hRightReduction hRightSound.1
          exact
            hAfterFullWhnf
              context nextContext
              state quickState reflectionState leftCoreState rightCoreState
              coreQuickState leftTypeState propState lazyState shortcutState
              leftFullState rightFullState nextState
              left right leftCore rightCore leftType leftDelta rightDelta
              leftFull rightFull value
              hRightSound.2 hOriginalLeft hOriginalRight
              hEnter hDifferent hNotCached
              hQuickNone hReflectionNone hLeftCore hRightCore
              hCoreQuickNone hLeftInfer hPropFalse
              hLazyResidual hShortcutNone hLeftFull hRightFull hRun
