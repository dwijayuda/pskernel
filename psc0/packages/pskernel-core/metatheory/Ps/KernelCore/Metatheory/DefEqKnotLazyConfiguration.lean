import Ps.KernelCore.Metatheory.DefEqKnotPropositionConfiguration
import Ps.KernelCore.Metatheory.DefEqLazyFuelConfiguration

/-
The concrete recursive DefEq knot uses bounded lazy delta only in the
non-proposition branch.  A decided result is published for the original pair
after transporting the callback's independent equality over the two earlier
core-WHNF reduction closures.  An undecided residual carries BOTH composed
original-to-residual reduction closures into the following projection shortcut
and full-WHNF stages.
-/

def PsKernelDefEqKnotAfterLazyResidualSound (fuel : Nat) : Prop :=
  ∀ (context nextContext : PsKernelCheckerContext)
    (state quickState reflectionState leftCoreState rightCoreState
      coreQuickState leftTypeState propState lazyState nextState :
        PsKernelCheckerState)
    (left right leftCore rightCore leftType leftDelta rightDelta :
      PsKernelExpr)
    (value : Bool),
    PsKernelCheckerConfigurationSound nextContext lazyState ->
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
        (Prod.mk
          (PsKernelDeltaResult.residual leftDelta rightDelta)
          lazyState) ->
    psKernelIsDefEqWithFuel
        (Nat.succ fuel) context state left right =
      Except.ok (Prod.mk value nextState) ->
    PsKernelCheckerConfigurationSound nextContext nextState ∧
      (value = true ->
        PsKernelDefEqJudgment
          nextContext.environment nextContext.localContext left right)


theorem psKernelDefEqKnot_after_nonprop_sound_of_lazy
    (fuel : Nat)
    (hDefEq :
      PsKernelDefEqConfigurationSound
        (psKernelIsDefEqWithFuel fuel))
    (hBeta : PsKernelBetaSpineSoundLaw)
    (hNative : PsKernelNativeReductionSoundLaw)
    (hString : PsKernelStringEqSoundLaw)
    (hAfterLazyResidual :
      PsKernelDefEqKnotAfterLazyResidualSound fuel) :
    PsKernelDefEqKnotAfterNonPropSound fuel := by
  intro
    context nextContext
    state quickState reflectionState leftCoreState rightCoreState
    coreQuickState leftTypeState propState nextState
    left right leftCore rightCore leftType value
    hConfig hLeftReduction hRightReduction
    hEnter hDifferent hNotCached hQuickNone hReflectionNone
    hLeftCore hRightCore hCoreQuickNone hLeftInfer hPropFalse hRun
  have hWhnf :
      PsKernelWhnfConfigurationSound
        (psKernelWhnfWithRecursorFuel
          fuel (psKernelIsDefEqWithFuel fuel)) :=
    psKernelWhnfWithRecursorFuel_configuration_sound_of_defeq
      fuel (psKernelIsDefEqWithFuel fuel)
      hDefEq hBeta hNative
  have hCore :
      PsKernelWhnfCoreConfigurationSound
        (psKernelWhnfCoreWithRecursorFuel
          fuel (psKernelIsDefEqWithFuel fuel)) :=
    psKernelWhnfCoreWithRecursorFuel_configuration_sound_of_defeq
      fuel (psKernelIsDefEqWithFuel fuel)
      hDefEq hBeta hNative
  have hLazySound :
      PsKernelDeltaResultConfigurationSound
        (psKernelDefEqLazyReductionWithFuel
          fuel
          (psKernelIsDefEqWithFuel fuel)
          (psKernelWhnfWithRecursorFuel
            fuel (psKernelIsDefEqWithFuel fuel))
          (psKernelWhnfCoreWithRecursorFuel
            fuel (psKernelIsDefEqWithFuel fuel))) :=
    psKernelDefEqLazyReductionWithFuel_configuration_sound
      fuel
      (psKernelIsDefEqWithFuel fuel)
      (psKernelWhnfWithRecursorFuel
        fuel (psKernelIsDefEqWithFuel fuel))
      (psKernelWhnfCoreWithRecursorFuel
        fuel (psKernelIsDefEqWithFuel fuel))
      hDefEq hWhnf hCore hNative hString
  cases hLazy :
      psKernelDefEqLazyReductionWithFuel
        fuel
        (psKernelIsDefEqWithFuel fuel)
        (psKernelWhnfWithRecursorFuel
          fuel (psKernelIsDefEqWithFuel fuel))
        (psKernelWhnfCoreWithRecursorFuel
          fuel (psKernelIsDefEqWithFuel fuel))
        nextContext propState leftCore rightCore with
  | error error =>
      simp [
        psKernelIsDefEqWithFuel,
        hEnter, hDifferent, hNotCached, hQuickNone,
        hReflectionNone, hLeftCore, hRightCore,
        hCoreQuickNone, hLeftInfer, hPropFalse, hLazy
      ] at hRun
  | ok lazyRun =>
      rcases lazyRun with ⟨answer, lazyState⟩
      have hDelta :=
        hLazySound
          nextContext propState lazyState leftCore rightCore
          answer hConfig hLazy
      cases answer with
      | decided deltaValue =>
          have hFinish :
              (Except.ok
                  (psKernelDefEqFinish
                    lazyState left right deltaValue) :
                Except String (Prod Bool PsKernelCheckerState)) =
              Except.ok (Prod.mk value nextState) := by
            simpa [
              psKernelIsDefEqWithFuel,
              hEnter, hDifferent, hNotCached, hQuickNone,
              hReflectionNone, hLeftCore, hRightCore,
              hCoreQuickNone, hLeftInfer, hPropFalse, hLazy
            ] using hRun
          exact
            psKernelDefEqKnot_publish_delta_decision
              nextContext lazyState nextState
              left right leftCore rightCore deltaValue value
              hLeftReduction hRightReduction hDelta hFinish
      | residual leftDelta rightDelta =>
          have hOriginalLeft :
              PsKernelReductionClosure
                nextContext.environment nextContext.localContext
                left leftDelta :=
            psKernelReductionClosure_trans
              nextContext.environment nextContext.localContext
              left leftCore leftDelta
              hLeftReduction hDelta.2.1
          have hOriginalRight :
              PsKernelReductionClosure
                nextContext.environment nextContext.localContext
                right rightDelta :=
            psKernelReductionClosure_trans
              nextContext.environment nextContext.localContext
              right rightCore rightDelta
              hRightReduction hDelta.2.2
          exact
            hAfterLazyResidual
              context nextContext
              state quickState reflectionState leftCoreState rightCoreState
              coreQuickState leftTypeState propState lazyState nextState
              left right leftCore rightCore leftType leftDelta rightDelta value
              hDelta.1 hOriginalLeft hOriginalRight
              hEnter hDifferent hNotCached
              hQuickNone hReflectionNone hLeftCore hRightCore
              hCoreQuickNone hLeftInfer hPropFalse hLazy hRun
