import Ps.KernelCore.Metatheory.DefEqLazyConfiguration
import Ps.KernelCore.Metatheory.NativeReduction

/-
Callback contracts for the fuel-driven lazy-delta continuation.

This module composes native reduction, recursive DefEq, one lazy-delta step
and the recursive continuation through the independent DeltaResult
postcondition. In particular, a successful comparison after native reduction
is lifted using the specific reduceCompare constructor, never transitivity.
-/

def PsKernelDeltaStepConfigurationSound
    (step :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String
        (Prod PsKernelDeltaStepResult PsKernelCheckerState)) : Prop :=
  ∀ (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (left right : PsKernelExpr)
    (answer : PsKernelDeltaStepResult),
    PsKernelCheckerConfigurationSound context state ->
    step context state left right =
      Except.ok (Prod.mk answer nextState) ->
    PsKernelDeltaStepPostcondition
      context nextState left right answer


def PsKernelDeltaResultConfigurationSound
    (resume :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String
        (Prod PsKernelDeltaResult PsKernelCheckerState)) : Prop :=
  ∀ (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (left right : PsKernelExpr)
    (answer : PsKernelDeltaResult),
    PsKernelCheckerConfigurationSound context state ->
    resume context state left right =
      Except.ok (Prod.mk answer nextState) ->
    PsKernelDeltaResultPostcondition
      context nextState left right answer


theorem psKernelDefEqNativeThenLazyStep_configuration_sound_of_components
    (resume :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String
        (Prod PsKernelDeltaResult PsKernelCheckerState))
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String (Prod Bool PsKernelCheckerState))
    (coreWhnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Bool ->
      Bool ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (hResume : PsKernelDeltaResultConfigurationSound resume)
    (hDefEq : PsKernelDefEqConfigurationSound defeq)
    (hStep :
      PsKernelDeltaStepConfigurationSound
        (psKernelDefEqLazyStep defeq coreWhnf))
    (hNative : PsKernelNativeReductionSoundLaw)
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (left right : PsKernelExpr)
    (answer : PsKernelDeltaResult)
    (hConfig : PsKernelCheckerConfigurationSound context state)
    (hRun :
      psKernelDefEqNativeThenLazyStep
          resume defeq coreWhnf context state left right =
        Except.ok (Prod.mk answer nextState)) :
    PsKernelDeltaResultPostcondition
      context nextState left right answer := by
  unfold psKernelDefEqNativeThenLazyStep at hRun
  cases hLeftNative : psKernelReduceNative context left with
  | error error =>
      simp only [hLeftNative] at hRun
      simp at hRun
  | ok leftNative =>
      simp only [hLeftNative] at hRun
      cases leftNative with
      | some leftValue =>
          cases hEq : defeq context state leftValue right with
          | error error =>
              simp only [hEq] at hRun
              simp at hRun
          | ok eqRun =>
              simp only [hEq] at hRun
              rcases eqRun with ⟨eqValue, eqState⟩
              have hEqSound :=
                hDefEq
                  context state eqState
                  leftValue right eqValue
                  hConfig hEq
              have hNativeReduction :=
                hNative context left leftValue hLeftNative
              simp at hRun
              rcases hRun with ⟨rfl, rfl⟩
              refine ⟨hEqSound.1, ?_⟩
              cases eqValue with
              | false =>
                  trivial
              | true =>
                  exact
                    PsKernelDefEqJudgment.reduceCompare
                      left right leftValue right
                      hNativeReduction
                      (PsKernelReductionClosure.refl right)
                      (hEqSound.2 rfl)
      | none =>
          cases hRightNative : psKernelReduceNative context right with
          | error error =>
              simp only [hRightNative] at hRun
              simp at hRun
          | ok rightNative =>
              simp only [hRightNative] at hRun
              cases rightNative with
              | some rightValue =>
                  cases hEq : defeq context state left rightValue with
                  | error error =>
                      simp only [hEq] at hRun
                      simp at hRun
                  | ok eqRun =>
                      simp only [hEq] at hRun
                      rcases eqRun with ⟨eqValue, eqState⟩
                      have hEqSound :=
                        hDefEq
                          context state eqState
                          left rightValue eqValue
                          hConfig hEq
                      have hNativeReduction :=
                        hNative context right rightValue hRightNative
                      simp at hRun
                      rcases hRun with ⟨rfl, rfl⟩
                      refine ⟨hEqSound.1, ?_⟩
                      cases eqValue with
                      | false =>
                          trivial
                      | true =>
                          exact
                            PsKernelDefEqJudgment.reduceCompare
                              left right left rightValue
                              (PsKernelReductionClosure.refl left)
                              hNativeReduction
                              (hEqSound.2 rfl)
              | none =>
                  cases hStepRun :
                      psKernelDefEqLazyStep
                        defeq coreWhnf context state left right with
                  | error error =>
                      simp only [hStepRun] at hRun
                      simp at hRun
                  | ok stepRun =>
                      simp only [hStepRun] at hRun
                      rcases stepRun with ⟨stepAnswer, stepState⟩
                      have hStepSound :=
                        hStep
                          context state stepState
                          left right stepAnswer
                          hConfig hStepRun
                      cases stepAnswer with
                      | «continue» nextLeft nextRight =>
                          cases hResumeRun :
                              resume
                                context stepState
                                nextLeft nextRight with
                          | error error =>
                              simp only [hResumeRun] at hRun
                              simp at hRun
                          | ok resumedRun =>
                              simp only [hResumeRun] at hRun
                              rcases resumedRun with
                                ⟨resumedAnswer, resumedState⟩
                              simp at hRun
                              rcases hRun with ⟨rfl, rfl⟩
                              have hResumeSound :=
                                hResume
                                  context stepState resumedState
                                  nextLeft nextRight resumedAnswer
                                  hStepSound.1 hResumeRun
                              exact
                                psKernelDeltaResultPostcondition_transport
                                  context resumedState
                                  left right nextLeft nextRight resumedAnswer
                                  hStepSound.2.1
                                  hStepSound.2.2
                                  hResumeSound
                      | unknown nextLeft nextRight =>
                          simp at hRun
                          rcases hRun with ⟨rfl, rfl⟩
                          exact ⟨hStepSound.1, hStepSound.2⟩
                      | equal =>
                          simp at hRun
                          rcases hRun with ⟨rfl, rfl⟩
                          exact ⟨hStepSound.1, hStepSound.2⟩
                      | different nextLeft nextRight =>
                          simp at hRun
                          rcases hRun with ⟨rfl, rfl⟩
                          exact ⟨hStepSound.1, trivial⟩
