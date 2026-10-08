import Ps.KernelCore.Metatheory.DefEqLazyConfiguration
import Ps.KernelCore.Metatheory.NativeReduction
import Ps.KernelCore.Metatheory.DefEqApplicationConfiguration

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


/-
The public lazy-delta one-step dispatcher only selects among the independent
one-sided and two-definition comparison workers. Its proof therefore needs
one explicit contract for the still-open two-definition family; it does not
inline or re-specify the sorted-hint, same-definition, or cache algorithms.
-/
def PsKernelDeltaStepBothConfigurationSound
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
      Except String (Prod PsKernelExpr PsKernelCheckerState)) : Prop :=
  ∀ (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (left right : PsKernelExpr)
    (leftDef rightDef : PsKernelDefinitionInfo)
    (answer : PsKernelDeltaStepResult),
    psKernelDeltaDefinition context left = Option.some leftDef ->
    psKernelDeltaDefinition context right = Option.some rightDef ->
    PsKernelCheckerConfigurationSound context state ->
    psKernelDefEqLazyStepBoth
        defeq coreWhnf context state
        left right leftDef rightDef =
      Except.ok (Prod.mk answer nextState) ->
    PsKernelDeltaStepPostcondition
      context nextState left right answer



/-
The equal-hint argument shortcut has two separate obligations:
* configuration soundness, even if the negative-result cache is consulted;
* whole-application DefEq evidence only after an independently justified
  equality of constant heads has been supplied.

The shortcut flag itself is not an equality certificate. The caller must
supply a proof of the head relation, grounded in authoritative lookups.
-/
theorem psKernelLazyDelta_same_hint_args_configuration_sound
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String (Prod Bool PsKernelCheckerState))
    (hDefEq : PsKernelDefEqConfigurationSound defeq)
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (left right : PsKernelExpr)
    (shortcut value : Bool)
    (hHead :
      shortcut = true ->
        PsKernelDefEqJudgment
          context.environment context.localContext
          (psKernelExprGetAppFn left)
          (psKernelExprGetAppFn right))
    (hConfig : PsKernelCheckerConfigurationSound context state)
    (hRun :
      (if shortcut then
         if psKernelSemanticPairCacheEligible left right then
           if psKernelExprPairSetContains state.failure left right then
             Except.ok (Prod.mk false state)
           else
             psKernelDefEqArgs defeq context state left right
         else
           psKernelDefEqArgs defeq context state left right
       else
         Except.ok (Prod.mk false state)) =
        Except.ok (Prod.mk value nextState)) :
    PsKernelCheckerConfigurationSound context nextState ∧
      ((if shortcut then value else false) = true ->
        PsKernelDefEqJudgment
          context.environment context.localContext left right) := by
  by_cases hShortcut : shortcut = true
  · by_cases hEligible :
        psKernelSemanticPairCacheEligible left right = true
    · by_cases hFailed :
          psKernelExprPairSetContains state.failure left right = true
      · simp [hShortcut, hEligible, hFailed] at hRun
        rcases hRun with ⟨rfl, rfl⟩
        refine ⟨hConfig, ?_⟩
        simp [hShortcut]
      · have hArgs :
            psKernelDefEqArgs defeq context state left right =
              Except.ok (Prod.mk value nextState) := by
          simpa [hShortcut, hEligible, hFailed] using hRun
        have hSound :=
          psKernelDefEqArgs_configuration_sound
            defeq hDefEq
            context state nextState left right value
            (hHead hShortcut) hConfig hArgs
        refine ⟨hSound.1, ?_⟩
        intro hValue
        exact hSound.2 (by simpa [hShortcut] using hValue)
    · have hArgs :
          psKernelDefEqArgs defeq context state left right =
            Except.ok (Prod.mk value nextState) := by
        simpa [hShortcut, hEligible] using hRun
      have hSound :=
        psKernelDefEqArgs_configuration_sound
          defeq hDefEq
          context state nextState left right value
          (hHead hShortcut) hConfig hArgs
      refine ⟨hSound.1, ?_⟩
      intro hValue
      exact hSound.2 (by simpa [hShortcut] using hValue)
  · simp [hShortcut] at hRun
    rcases hRun with ⟨rfl, rfl⟩
    refine ⟨hConfig, ?_⟩
    simp [hShortcut]


theorem psKernelDefEqLazyStep_configuration_sound_of_branches
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
    (hQuick :
      PsKernelOptionalDefEqConfigurationSound
        (psKernelDefEqQuick defeq))
    (hCore : PsKernelWhnfCoreConfigurationSound coreWhnf)
    (hBoth :
      PsKernelDeltaStepBothConfigurationSound defeq coreWhnf) :
    PsKernelDeltaStepConfigurationSound
      (psKernelDefEqLazyStep defeq coreWhnf) := by
  intro context state nextState left right answer hConfig hRun
  cases hLeftDef : psKernelDeltaDefinition context left with
  | none =>
      cases hRightDef : psKernelDeltaDefinition context right with
      | none =>
          simp [
            psKernelDefEqLazyStep,
            hLeftDef,
            hRightDef
          ] at hRun
          rcases hRun with ⟨rfl, rfl⟩
          exact
            ⟨
              hConfig,
              PsKernelReductionClosure.refl left,
              PsKernelReductionClosure.refl right
            ⟩
      | some rightDef =>
          have hBranch :
              psKernelDefEqLazyStepRightOnly
                  defeq coreWhnf context state left right =
                Except.ok (Prod.mk answer nextState) := by
            simpa [
              psKernelDefEqLazyStep,
              hLeftDef,
              hRightDef
            ] using hRun
          exact
            psKernelDefEqLazyStepRightOnly_configuration_sound
              defeq coreWhnf hQuick hCore
              context state nextState left right answer
              hConfig hBranch
  | some leftDef =>
      cases hRightDef : psKernelDeltaDefinition context right with
      | none =>
          have hBranch :
              psKernelDefEqLazyStepLeftOnly
                  defeq coreWhnf context state left right =
                Except.ok (Prod.mk answer nextState) := by
            simpa [
              psKernelDefEqLazyStep,
              hLeftDef,
              hRightDef
            ] using hRun
          exact
            psKernelDefEqLazyStepLeftOnly_configuration_sound
              defeq coreWhnf hQuick hCore
              context state nextState left right answer
              hConfig hBranch
      | some rightDef =>
          have hBranch :
              psKernelDefEqLazyStepBoth
                  defeq coreWhnf context state
                  left right leftDef rightDef =
                Except.ok (Prod.mk answer nextState) := by
            simpa [
              psKernelDefEqLazyStep,
              hLeftDef,
              hRightDef
            ] using hRun
          exact
            hBoth
              context state nextState
              left right leftDef rightDef answer
              hLeftDef hRightDef hConfig hBranch


/-
Fuel induction for projection-sensitive lazy comparison.

A terminal computed-field comparison is justified by projection reduction.
A direct equal result is justified by projection congruence. Recursive or
terminal residual comparisons are transported through *projection-major
reduction closures* and the specific reduceCompare semantic constructor.
No general transitivity of algorithmic DefEq is assumed.
-/
theorem psKernelDefEqLazyProjReductionWithFuel_configuration_sound
    (fuel : Nat)
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
    (hDefEq : PsKernelDefEqConfigurationSound defeq)
    (hStep :
      PsKernelDeltaStepConfigurationSound
        (psKernelDefEqLazyStep defeq coreWhnf))
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (left right : PsKernelExpr)
    (typeName : PsKernelName)
    (index : Nat)
    (value : Bool)
    (hConfig : PsKernelCheckerConfigurationSound context state)
    (hRun :
      psKernelDefEqLazyProjReductionWithFuel
          fuel defeq coreWhnf
          context state left right typeName index =
        Except.ok (Prod.mk value nextState)) :
    PsKernelCheckerConfigurationSound context nextState ∧
      (value = true ->
        PsKernelDefEqJudgment
          context.environment context.localContext
          (PsKernelExpr.proj typeName index left)
          (PsKernelExpr.proj typeName index right)) := by
  induction fuel generalizing state nextState left right with
  | zero =>
      simp [psKernelDefEqLazyProjReductionWithFuel] at hRun
  | succ remaining ih =>
      have liftResult
          (nextLeft nextRight : PsKernelExpr)
          (hLeft :
            PsKernelReductionClosure
              context.environment context.localContext
              left nextLeft)
          (hRight :
            PsKernelReductionClosure
              context.environment context.localContext
              right nextRight)
          (hResult :
            PsKernelCheckerConfigurationSound context nextState ∧
              (value = true ->
                PsKernelDefEqJudgment
                  context.environment context.localContext
                  (PsKernelExpr.proj typeName index nextLeft)
                  (PsKernelExpr.proj typeName index nextRight))) :
          PsKernelCheckerConfigurationSound context nextState ∧
            (value = true ->
              PsKernelDefEqJudgment
                context.environment context.localContext
                (PsKernelExpr.proj typeName index left)
                (PsKernelExpr.proj typeName index right)) := by
        refine ⟨hResult.1, ?_⟩
        intro hTrue
        exact
          PsKernelDefEqJudgment.reduceCompare
            (PsKernelExpr.proj typeName index left)
            (PsKernelExpr.proj typeName index right)
            (PsKernelExpr.proj typeName index nextLeft)
            (PsKernelExpr.proj typeName index nextRight)
            (PsKernelReductionClosure.projectionMajor
              typeName index left nextLeft hLeft)
            (PsKernelReductionClosure.projectionMajor
              typeName index right nextRight hRight)
            (hResult.2 hTrue)
      simp only [psKernelDefEqLazyProjReductionWithFuel] at hRun
      cases hStepRun :
          psKernelDefEqLazyStep
            defeq coreWhnf context state left right with
      | error error =>
          simp only [hStepRun] at hRun
          simp at hRun
      | ok stepRun =>
          simp only [hStepRun] at hRun
          rcases stepRun with ⟨answer, stepState⟩
          have hStepSound :=
            hStep context state stepState left right answer
              hConfig hStepRun
          cases answer with
          | «continue» nextLeft nextRight =>
              exact
                liftResult nextLeft nextRight
                  hStepSound.2.1 hStepSound.2.2
                  (ih stepState nextState nextLeft nextRight
                    hStepSound.1 hRun)
          | equal =>
              simp at hRun
              rcases hRun with ⟨rfl, rfl⟩
              refine ⟨hStepSound.1, ?_⟩
              intro _
              exact
                PsKernelDefEqJudgment.projection
                  typeName index left right hStepSound.2
          | unknown nextLeft nextRight =>
              exact
                liftResult nextLeft nextRight
                  hStepSound.2.1 hStepSound.2.2
                  (psKernelDefEqLazyProjFinish_configuration_sound
                    defeq hDefEq context stepState nextState
                    nextLeft nextRight typeName index value
                    hStepSound.1 hRun)
          | different nextLeft nextRight =>
              exact
                liftResult nextLeft nextRight
                  hStepSound.2.1 hStepSound.2.2
                  (psKernelDefEqLazyProjFinish_configuration_sound
                    defeq hDefEq context stepState nextState
                    nextLeft nextRight typeName index value
                    hStepSound.1 hRun)


/-
Shared fallback when equal-hint argument comparison cannot decide equality.

The executable lazy-delta fallback unfolds both operands in order, carrying
the resulting checker state into each subsequent stage. This theorem composes
two independent delta closures with the terminal quick comparison through
the dedicated reduction-transport judgment.
-/
theorem psKernelLazyDelta_two_sided_fallback_configuration_sound
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
    (hQuick :
      PsKernelOptionalDefEqConfigurationSound
        (psKernelDefEqQuick defeq))
    (hCore : PsKernelWhnfCoreConfigurationSound coreWhnf)
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (left right : PsKernelExpr)
    (answer : PsKernelDeltaStepResult)
    (hConfig : PsKernelCheckerConfigurationSound context state)
    (hRun :
      (match
          psKernelDefEqDeltaOnce
            coreWhnf context state left with
       | Except.error error =>
           Except.error error
       | Except.ok leftRun =>
           match
               psKernelDefEqDeltaOnce
                 coreWhnf context
                 (Prod.snd leftRun)
                 right with
           | Except.error error =>
               Except.error error
           | Except.ok rightRun =>
               psKernelDefEqFinishLazyStep
                 defeq context
                 (Prod.snd rightRun)
                 (Prod.fst leftRun)
                 (Prod.fst rightRun)) =
        Except.ok (Prod.mk answer nextState)) :
    PsKernelDeltaStepPostcondition
      context nextState left right answer := by
  cases hLeft :
      psKernelDefEqDeltaOnce
        coreWhnf context state left with
  | error error =>
      simp only [hLeft] at hRun
      simp at hRun
  | ok leftRun =>
      simp only [hLeft] at hRun
      rcases leftRun with ⟨leftValue, leftState⟩
      have hLeftSound :=
        psKernelDefEqDeltaOnce_configuration_sound
          coreWhnf hCore
          context state leftState left leftValue
          hConfig hLeft
      cases hRight :
          psKernelDefEqDeltaOnce
            coreWhnf context leftState right with
      | error error =>
          simp only [hRight] at hRun
          simp at hRun
      | ok rightRun =>
          simp only [hRight] at hRun
          rcases rightRun with ⟨rightValue, rightState⟩
          have hRightSound :=
            psKernelDefEqDeltaOnce_configuration_sound
              coreWhnf hCore
              context leftState rightState right rightValue
              hLeftSound.2 hRight
          have hFinishSound :=
            psKernelDefEqFinishLazyStep_configuration_sound
              defeq hQuick
              context rightState nextState
              leftValue rightValue answer
              hRightSound.2 hRun
          exact
            psKernelDeltaStepPostcondition_transport
              context nextState
              left right leftValue rightValue answer
              hLeftSound.1 hRightSound.1 hFinishSound


/-
For equal reducibility hints, the optimized argument comparison can decide
positive equality only with proof of the actual constant-head equivalence.
Otherwise the executable continues by unfolding both sides, preserving the
failure-cache state and transporting the terminal result along each reduction.
-/
theorem psKernelDefEqLazyStepBoth_equal_hint_configuration_sound
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
    (hDefEq : PsKernelDefEqConfigurationSound defeq)
    (hQuick :
      PsKernelOptionalDefEqConfigurationSound
        (psKernelDefEqQuick defeq))
    (hCore : PsKernelWhnfCoreConfigurationSound coreWhnf)
    (hString : PsKernelStringEqSoundLaw)
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (left right : PsKernelExpr)
    (leftDef rightDef : PsKernelDefinitionInfo)
    (answer : PsKernelDeltaStepResult)
    (hNoLeft :
      psKernelReducibilityHintsLt leftDef.hints rightDef.hints = false)
    (hNoRight :
      psKernelReducibilityHintsLt rightDef.hints leftDef.hints = false)
    (hLeftDef :
      psKernelDeltaDefinition context left = Option.some leftDef)
    (hRightDef :
      psKernelDeltaDefinition context right = Option.some rightDef)
    (hConfig : PsKernelCheckerConfigurationSound context state)
    (hRun :
      psKernelDefEqLazyStepBoth
          defeq coreWhnf context state
          left right leftDef rightDef =
        Except.ok (Prod.mk answer nextState)) :
    PsKernelDeltaStepPostcondition
      context nextState left right answer := by
  let sameShortcut : Bool :=
    if
        (if psKernelNatGt (psKernelExprGetAppNumArgs left) 0 then
           psKernelNatGt (psKernelExprGetAppNumArgs right) 0
         else
           false) then
      if psKernelSameDeltaDefinition leftDef rightDef then
        if psKernelReducibilityHintsIsRegular leftDef.hints then
          psKernelAppHeadLevelsEquivalent left right
        else
          false
      else
        false
    else
      false
  let argsResult :
      Except String (Prod Bool PsKernelCheckerState) :=
    if sameShortcut then
      if psKernelSemanticPairCacheEligible left right then
        if psKernelExprPairSetContains state.failure left right then
          Except.ok (Prod.mk false state)
        else
          psKernelDefEqArgs defeq context state left right
      else
        psKernelDefEqArgs defeq context state left right
    else
      Except.ok (Prod.mk false state)
  have hHead :
      sameShortcut = true ->
        PsKernelDefEqJudgment
          context.environment context.localContext
          (psKernelExprGetAppFn left)
          (psKernelExprGetAppFn right) := by
    intro hShortcut
    exact
      psKernelLazyDelta_same_shortcut_head_sound
        hString context left right leftDef rightDef
        hLeftDef hRightDef
        (by simpa [sameShortcut] using hShortcut)
  have hMain :
      (match argsResult with
       | Except.error error =>
           Except.error error
       | Except.ok compared =>
           if (if sameShortcut then Prod.fst compared else false) then
             Except.ok
               (Prod.mk
                 PsKernelDeltaStepResult.equal
                 (Prod.snd compared))
           else
             let comparedState := Prod.snd compared
             let afterFailure :=
               if sameShortcut then
                 if psKernelSemanticPairCacheEligible left right then
                   psKernelCheckerStateWithFailure
                     comparedState
                     (psKernelExprPairSetInsert
                       comparedState.failure left right)
                 else
                   comparedState
               else
                 comparedState
             match
                 psKernelDefEqDeltaOnce
                   coreWhnf context afterFailure left with
             | Except.error error =>
                 Except.error error
             | Except.ok leftResult =>
                 match
                     psKernelDefEqDeltaOnce
                       coreWhnf context
                       (Prod.snd leftResult)
                       right with
                 | Except.error error =>
                     Except.error error
                 | Except.ok rightResult =>
                     psKernelDefEqFinishLazyStep
                       defeq context
                       (Prod.snd rightResult)
                       (Prod.fst leftResult)
                       (Prod.fst rightResult)) =
        Except.ok (Prod.mk answer nextState) := by
    cases hLeftArgs :
        psKernelNatGt (psKernelExprGetAppNumArgs left) 0 <;>
      cases hRightArgs :
        psKernelNatGt (psKernelExprGetAppNumArgs right) 0 <;>
      cases hSame :
        psKernelSameDeltaDefinition leftDef rightDef <;>
      cases hRegular :
        psKernelReducibilityHintsIsRegular leftDef.hints <;>
      cases hLevels :
        psKernelAppHeadLevelsEquivalent left right <;>
      simp [
        psKernelDefEqLazyStepBoth,
        hNoLeft, hNoRight,
        sameShortcut, argsResult,
        hLeftArgs, hRightArgs, hSame, hRegular, hLevels
      ] at hRun ⊢ <;> assumption
  cases hArgs :
      argsResult with
  | error error =>
      simp only [hArgs] at hMain
      simp at hMain
  | ok compared =>
      simp only [hArgs] at hMain
      rcases compared with ⟨argValue, argState⟩
      have hArgsSound :=
        psKernelLazyDelta_same_hint_args_configuration_sound
          defeq hDefEq context state argState
          left right sameShortcut argValue hHead hConfig
          (by simpa [argsResult] using hArgs)
      by_cases hDecided :
          (if sameShortcut then argValue else false) = true
      · rw [if_pos hDecided] at hMain
        simp at hMain
        rcases hMain with ⟨rfl, rfl⟩
        exact ⟨hArgsSound.1, hArgsSound.2 hDecided⟩
      · rw [if_neg hDecided] at hMain
        let afterFailure : PsKernelCheckerState :=
          if sameShortcut then
            if psKernelSemanticPairCacheEligible left right then
              psKernelCheckerStateWithFailure
                argState
                (psKernelExprPairSetInsert
                  argState.failure left right)
            else
              argState
          else
            argState
        have hAfterConfig :
            PsKernelCheckerConfigurationSound
              context afterFailure := by
          by_cases hShortcut : sameShortcut = true
          · by_cases hEligible :
                psKernelSemanticPairCacheEligible left right = true
            · simpa [afterFailure, hShortcut, hEligible] using
                (psKernelCheckerStateWithFailure_preserves_configuration
                  context argState
                  (psKernelExprPairSetInsert
                    argState.failure left right)
                  hArgsSound.1)
            · simpa [afterFailure, hShortcut, hEligible] using
                hArgsSound.1
          · simpa [afterFailure, hShortcut] using hArgsSound.1
        exact
          psKernelLazyDelta_two_sided_fallback_configuration_sound
            defeq coreWhnf hQuick hCore
            context afterFailure nextState
            left right answer hAfterConfig
            (by simpa [afterFailure] using hMain)


/-
The complete two-definition lazy-delta step discharges every reducibility-hint
branch, including the equal-hint optimized argument path. The authoritative
lookup premises supplied by the dispatcher are retained in the semantic
contract, and the string comparator is an explicit named soundness law.
-/
theorem psKernelDefEqLazyStepBoth_configuration_sound
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
    (hDefEq : PsKernelDefEqConfigurationSound defeq)
    (hQuick :
      PsKernelOptionalDefEqConfigurationSound
        (psKernelDefEqQuick defeq))
    (hCore : PsKernelWhnfCoreConfigurationSound coreWhnf)
    (hString : PsKernelStringEqSoundLaw) :
    PsKernelDeltaStepBothConfigurationSound
      defeq coreWhnf := by
  intro context state nextState left right
    leftDef rightDef answer hLeftDef hRightDef hConfig hRun
  cases hLeftHint :
      psKernelReducibilityHintsLt leftDef.hints rightDef.hints with
  | true =>
      exact
        psKernelDefEqLazyStepBoth_left_hint_configuration_sound
          defeq coreWhnf hQuick hCore
          context state nextState
          left right leftDef rightDef answer
          hLeftHint hConfig hRun
  | false =>
      cases hRightHint :
          psKernelReducibilityHintsLt rightDef.hints leftDef.hints with
      | true =>
          exact
            psKernelDefEqLazyStepBoth_right_hint_configuration_sound
              defeq coreWhnf hQuick hCore
              context state nextState
              left right leftDef rightDef answer
              hLeftHint hRightHint hConfig hRun
      | false =>
          exact
            psKernelDefEqLazyStepBoth_equal_hint_configuration_sound
              defeq coreWhnf hDefEq hQuick hCore hString
              context state nextState
              left right leftDef rightDef answer
              hLeftHint hRightHint hLeftDef hRightDef
              hConfig hRun


theorem psKernelDefEqLazyStep_configuration_sound
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
    (hDefEq : PsKernelDefEqConfigurationSound defeq)
    (hQuick :
      PsKernelOptionalDefEqConfigurationSound
        (psKernelDefEqQuick defeq))
    (hCore : PsKernelWhnfCoreConfigurationSound coreWhnf)
    (hString : PsKernelStringEqSoundLaw) :
    PsKernelDeltaStepConfigurationSound
      (psKernelDefEqLazyStep defeq coreWhnf) :=
  psKernelDefEqLazyStep_configuration_sound_of_branches
    defeq coreWhnf hQuick hCore
    (psKernelDefEqLazyStepBoth_configuration_sound
      defeq coreWhnf hDefEq hQuick hCore hString)
