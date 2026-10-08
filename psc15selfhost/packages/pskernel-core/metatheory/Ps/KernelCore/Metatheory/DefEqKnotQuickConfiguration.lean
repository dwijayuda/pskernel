import Ps.KernelCore.Metatheory.DefEqKnotEntryConfiguration
import Ps.KernelCore.Metatheory.DefEqQuickConfiguration

/-
Concrete successor-fuel DefEq stage after both early fast paths have missed.

The Quick helper may resolve the original pair and publish it immediately,
or return none and pass the unchanged original pair and sound checker
configuration to the reflection/reduction continuation.  This is not a
trusted assumption: the continuation requirement is named and must be proved
before the final checker knot can be considered closed.
-/

def PsKernelDefEqKnotAfterQuickSound (fuel : Nat) : Prop :=
  ∀ (context nextContext : PsKernelCheckerContext)
    (state quickState nextState : PsKernelCheckerState)
    (left right : PsKernelExpr)
    (value : Bool),
    PsKernelCheckerConfigurationSound nextContext quickState ->
    psKernelCheckerContextEnterRecDepth context =
      Except.ok nextContext ->
    psKernelExprEq left right = false ->
    psKernelExprPairSetContains state.success left right = false ->
    psKernelDefEqQuick
        (psKernelIsDefEqWithFuel fuel)
        nextContext state left right =
      Except.ok (Prod.mk Option.none quickState) ->
    psKernelIsDefEqWithFuel
        (Nat.succ fuel) context state left right =
      Except.ok (Prod.mk value nextState) ->
    PsKernelCheckerConfigurationSound nextContext nextState ∧
      (value = true ->
        PsKernelDefEqJudgment
          nextContext.environment nextContext.localContext
          left right)


theorem psKernelDefEqKnot_miss_sound_of_after_quick
    (fuel : Nat)
    (hDefEq :
      PsKernelDefEqConfigurationSound
        (psKernelIsDefEqWithFuel fuel))
    (hString : PsKernelStringEqSoundLaw)
    (hAfterQuick : PsKernelDefEqKnotAfterQuickSound fuel) :
    PsKernelDefEqKnotMissConfigurationSound fuel := by
  intro
    context nextContext state nextState
    left right value
    hConfig hEnter hDifferent hNotCached hRun
  have hQuickContract :
      PsKernelOptionalDefEqConfigurationSound
        (psKernelDefEqQuick
          (psKernelIsDefEqWithFuel fuel)) :=
    psKernelDefEqQuick_configuration_sound
      (psKernelIsDefEqWithFuel fuel)
      hDefEq hString
  cases hQuick :
      psKernelDefEqQuick
        (psKernelIsDefEqWithFuel fuel)
        nextContext state left right with
  | error error =>
      simp [
        psKernelIsDefEqWithFuel,
        hEnter, hDifferent, hNotCached, hQuick
      ] at hRun
  | ok quickRun =>
      rcases quickRun with ⟨quickAnswer, quickState⟩
      have hQuickSound :=
        hQuickContract
          nextContext state quickState
          left right quickAnswer hConfig hQuick
      cases quickAnswer with
      | some quickValue =>
          have hFinished :
              (Except.ok
                  (psKernelDefEqFinish
                    quickState left right quickValue) :
                Except String (Prod Bool PsKernelCheckerState)) =
              Except.ok (Prod.mk value nextState) := by
            simpa [
              psKernelIsDefEqWithFuel,
              hEnter, hDifferent, hNotCached, hQuick
            ] using hRun
          exact
            psKernelDefEqKnot_publish_optional
              nextContext quickState nextState
              left right left right
              quickValue value
              (PsKernelReductionClosure.refl left)
              (PsKernelReductionClosure.refl right)
              hQuickSound hFinished
      | none =>
          exact
            hAfterQuick
              context nextContext
              state quickState nextState
              left right value
              hQuickSound.1
              hEnter hDifferent hNotCached
              hQuick hRun
