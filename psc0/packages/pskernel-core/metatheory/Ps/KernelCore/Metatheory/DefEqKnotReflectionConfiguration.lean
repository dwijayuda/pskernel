import Ps.KernelCore.Metatheory.DefEqKnotQuickConfiguration
import Ps.KernelCore.Metatheory.DefEqReflectionConfiguration
import Ps.KernelCore.Metatheory.RecursorBoundedConfiguration

/-
The concrete DefEq knot's reflection stage is reached only after Quick has
returned none. Reflection may itself decide the original pair, in which case
the result is published with a sound cache entry. Otherwise it passes a
configuration-sound state to the later core-WHNF/reduction phases.

The after-reflection obligation is explicit; discharging it is still
required to close the concrete recursive checker.
-/

def PsKernelDefEqKnotAfterReflectionSound (fuel : Nat) : Prop :=
  ∀ (context nextContext : PsKernelCheckerContext)
    (state quickState reflectionState nextState : PsKernelCheckerState)
    (left right : PsKernelExpr)
    (value : Bool),
    PsKernelCheckerConfigurationSound nextContext reflectionState ->
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
    psKernelIsDefEqWithFuel
        (Nat.succ fuel) context state left right =
      Except.ok (Prod.mk value nextState) ->
    PsKernelCheckerConfigurationSound nextContext nextState ∧
      (value = true ->
        PsKernelDefEqJudgment
          nextContext.environment nextContext.localContext
          left right)


theorem psKernelDefEqKnot_after_quick_sound_of_reflection
    (fuel : Nat)
    (hDefEq :
      PsKernelDefEqConfigurationSound
        (psKernelIsDefEqWithFuel fuel))
    (hBeta : PsKernelBetaSpineSoundLaw)
    (hNative : PsKernelNativeReductionSoundLaw)
    (hString : PsKernelStringEqSoundLaw)
    (hAfterReflection : PsKernelDefEqKnotAfterReflectionSound fuel) :
    PsKernelDefEqKnotAfterQuickSound fuel := by
  intro
    context nextContext state quickState nextState
    left right value
    hConfig hEnter hDifferent hNotCached hQuickNone hRun
  have hWhnf :
      PsKernelWhnfConfigurationSound
        (psKernelWhnfWithRecursorFuel
          fuel (psKernelIsDefEqWithFuel fuel)) :=
    psKernelWhnfWithRecursorFuel_configuration_sound_of_defeq
      fuel (psKernelIsDefEqWithFuel fuel)
      hDefEq hBeta hNative
  cases hReflection :
      psKernelDefEqReflectionWith
        (psKernelWhnfWithRecursorFuel
          fuel (psKernelIsDefEqWithFuel fuel))
        nextContext quickState left right with
  | error error =>
      simp [
        psKernelIsDefEqWithFuel,
        hEnter, hDifferent, hNotCached,
        hQuickNone, hReflection
      ] at hRun
  | ok reflectionRun =>
      rcases reflectionRun with ⟨reflectionAnswer, reflectionState⟩
      have hReflectionSound :=
        psKernelDefEqReflectionWith_optional_configuration_sound
          (psKernelWhnfWithRecursorFuel
            fuel (psKernelIsDefEqWithFuel fuel))
          hWhnf hString
          nextContext quickState reflectionState
          left right reflectionAnswer
          hConfig hReflection
      cases reflectionAnswer with
      | some reflectionValue =>
          have hFinished :
              (Except.ok
                  (psKernelDefEqFinish
                    reflectionState left right reflectionValue) :
                Except String (Prod Bool PsKernelCheckerState)) =
              Except.ok (Prod.mk value nextState) := by
            simpa [
              psKernelIsDefEqWithFuel,
              hEnter, hDifferent, hNotCached,
              hQuickNone, hReflection
            ] using hRun
          exact
            psKernelDefEqKnot_publish_optional
              nextContext reflectionState nextState
              left right left right
              reflectionValue value
              (PsKernelReductionClosure.refl left)
              (PsKernelReductionClosure.refl right)
              hReflectionSound hFinished
      | none =>
          exact
            hAfterReflection
              context nextContext
              state quickState reflectionState nextState
              left right value
              hReflectionSound.1
              hEnter hDifferent hNotCached
              hQuickNone hReflection hRun
