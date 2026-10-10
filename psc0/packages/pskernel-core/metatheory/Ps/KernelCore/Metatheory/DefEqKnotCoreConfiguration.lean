import Ps.KernelCore.Metatheory.DefEqKnotReflectionConfiguration
import Ps.KernelCore.Metatheory.DefEqQuickConfiguration

/-
The concrete DefEq knot next normalizes both original expressions with the
recursor-aware core WHNF and invokes Quick once more on that reduced pair.

Unlike an unqualified equality-transitivity argument, positive Quick results
are transported to the ORIGINAL pair only over the two independently proved
reduction closures. The remaining proof-irrelevance/lazy-delta continuation is
an explicit unclosed theorem obligation, not an axiom.
-/

def PsKernelDefEqKnotAfterCoreQuickSound (fuel : Nat) : Prop :=
  ∀ (context nextContext : PsKernelCheckerContext)
    (state quickState reflectionState leftCoreState rightCoreState
      coreQuickState nextState : PsKernelCheckerState)
    (left right leftCore rightCore : PsKernelExpr)
    (value : Bool),
    PsKernelCheckerConfigurationSound nextContext coreQuickState ->
    PsKernelReductionClosure
      nextContext.environment nextContext.localContext left leftCore ->
    PsKernelReductionClosure
      nextContext.environment nextContext.localContext right rightCore ->
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
    psKernelIsDefEqWithFuel
        (Nat.succ fuel) context state left right =
      Except.ok (Prod.mk value nextState) ->
    PsKernelCheckerConfigurationSound nextContext nextState ∧
      (value = true ->
        PsKernelDefEqJudgment
          nextContext.environment nextContext.localContext left right)


theorem psKernelDefEqKnot_after_reflection_sound_of_core_quick
    (fuel : Nat)
    (hDefEq :
      PsKernelDefEqConfigurationSound
        (psKernelIsDefEqWithFuel fuel))
    (hBeta : PsKernelBetaSpineSoundLaw)
    (hNative : PsKernelNativeReductionSoundLaw)
    (hString : PsKernelStringEqSoundLaw)
    (hAfterCoreQuick : PsKernelDefEqKnotAfterCoreQuickSound fuel) :
    PsKernelDefEqKnotAfterReflectionSound fuel := by
  intro
    context nextContext state quickState reflectionState nextState
    left right value
    hConfig hEnter hDifferent hNotCached hQuickNone
    hReflectionNone hRun
  have hCore :
      PsKernelWhnfCoreConfigurationSound
        (psKernelWhnfCoreWithRecursorFuel
          fuel (psKernelIsDefEqWithFuel fuel)) :=
    psKernelWhnfCoreWithRecursorFuel_configuration_sound_of_defeq
      fuel (psKernelIsDefEqWithFuel fuel)
      hDefEq hBeta hNative
  have hQuick :
      PsKernelOptionalDefEqConfigurationSound
        (psKernelDefEqQuick (psKernelIsDefEqWithFuel fuel)) :=
    psKernelDefEqQuick_configuration_sound
      (psKernelIsDefEqWithFuel fuel) hDefEq hString
  cases hLeftCore :
      psKernelWhnfCoreWithRecursorFuel
        fuel (psKernelIsDefEqWithFuel fuel)
        nextContext reflectionState left false true with
  | error error =>
      simp [
        psKernelIsDefEqWithFuel,
        hEnter, hDifferent, hNotCached,
        hQuickNone, hReflectionNone, hLeftCore
      ] at hRun
  | ok leftRun =>
      rcases leftRun with ⟨leftCore, leftCoreState⟩
      have hLeftSound :=
        hCore
          nextContext reflectionState leftCoreState
          left leftCore false true hConfig hLeftCore
      cases hRightCore :
          psKernelWhnfCoreWithRecursorFuel
            fuel (psKernelIsDefEqWithFuel fuel)
            nextContext leftCoreState right false true with
      | error error =>
          simp [
            psKernelIsDefEqWithFuel,
            hEnter, hDifferent, hNotCached,
            hQuickNone, hReflectionNone, hLeftCore, hRightCore
          ] at hRun
      | ok rightRun =>
          rcases rightRun with ⟨rightCore, rightCoreState⟩
          have hRightSound :=
            hCore
              nextContext leftCoreState rightCoreState
              right rightCore false true hLeftSound.2 hRightCore
          cases hCoreQuick :
              psKernelDefEqQuick
                (psKernelIsDefEqWithFuel fuel)
                nextContext rightCoreState leftCore rightCore with
          | error error =>
              simp [
                psKernelIsDefEqWithFuel,
                hEnter, hDifferent, hNotCached, hQuickNone,
                hReflectionNone, hLeftCore, hRightCore, hCoreQuick
              ] at hRun
          | ok quickRun =>
              rcases quickRun with ⟨answer, coreQuickState⟩
              have hQuickSound :=
                hQuick
                  nextContext rightCoreState coreQuickState
                  leftCore rightCore answer hRightSound.2 hCoreQuick
              cases answer with
              | some coreValue =>
                  have hFinish :
                      (Except.ok
                          (psKernelDefEqFinish
                            coreQuickState left right coreValue) :
                        Except String (Prod Bool PsKernelCheckerState)) =
                      Except.ok (Prod.mk value nextState) := by
                    simpa [
                      psKernelIsDefEqWithFuel,
                      hEnter, hDifferent, hNotCached, hQuickNone,
                      hReflectionNone, hLeftCore, hRightCore, hCoreQuick
                    ] using hRun
                  exact
                    psKernelDefEqKnot_publish_optional
                      nextContext coreQuickState nextState
                      left right leftCore rightCore
                      coreValue value
                      hLeftSound.1 hRightSound.1
                      hQuickSound hFinish
              | none =>
                  exact
                    hAfterCoreQuick
                      context nextContext
                      state quickState reflectionState
                      leftCoreState rightCoreState coreQuickState nextState
                      left right leftCore rightCore value
                      hQuickSound.1 hLeftSound.1 hRightSound.1
                      hEnter hDifferent hNotCached
                      hQuickNone hReflectionNone
                      hLeftCore hRightCore hCoreQuick hRun
