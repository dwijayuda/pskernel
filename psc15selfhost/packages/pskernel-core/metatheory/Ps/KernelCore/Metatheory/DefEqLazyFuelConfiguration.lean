import Ps.KernelCore.Metatheory.DefEqLazyContinuation
import Ps.KernelCore.Metatheory.PrimitiveNatReduction

/-
Reusable fuel-driven LazyDelta proof infrastructure.

The executable fast Nat-reduction stage is intentionally optional:
an eager comparison invokes the independently proved primitive reducer,
whereas a non-eager comparison returns an unchanged configuration and an
undecided reduction. Both branches refine the same semantic postcondition.
-/

theorem psKernelLazyOptionalNat_configuration_sound
    (eager : Bool)
    (whnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (hWhnf : PsKernelWhnfConfigurationSound whnf)
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (expr : PsKernelExpr)
    (answer : Option PsKernelExpr)
    (hConfig : PsKernelCheckerConfigurationSound context state)
    (hRun :
      (if eager then
         psKernelReduceNatWith whnf context state expr
       else
         Except.ok (Prod.mk Option.none state)) =
        Except.ok (Prod.mk answer nextState)) :
    PsKernelOptionalReductionPostcondition
      context nextState expr answer := by
  cases eager with
  | false =>
      simp at hRun
      rcases hRun with ⟨rfl, rfl⟩
      exact ⟨hConfig, trivial⟩
  | true =>
      exact
        psKernelReduceNatWith_configuration_sound
          whnf hWhnf
          context state nextState expr answer
          hConfig
          (by simpa using hRun)


/-
The eager Nat stage of lazy equality composes exactly one reduction or,
if there is no Nat reduction, delegates to the already verified native and
delta-step continuation. A successful DefEq of Nat-reduced operands is lifted
by reduceCompare rather than general algorithmic transitivity.
-/
theorem psKernelDefEqLazyReductionAfterPred_configuration_sound
    (resume :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String (Prod PsKernelDeltaResult PsKernelCheckerState))
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String (Prod Bool PsKernelCheckerState))
    (whnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (coreWhnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Bool ->
      Bool ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (hResume : PsKernelDeltaResultConfigurationSound resume)
    (hDefEq : PsKernelDefEqConfigurationSound defeq)
    (hWhnf : PsKernelWhnfConfigurationSound whnf)
    (hStep :
      PsKernelDeltaStepConfigurationSound
        (psKernelDefEqLazyStep defeq coreWhnf))
    (hNative : PsKernelNativeReductionSoundLaw) :
    PsKernelDeltaResultConfigurationSound
      (psKernelDefEqLazyReductionAfterPred
        resume defeq whnf coreWhnf) := by
  intro context state nextState left right answer hConfig hRun
  cases hEager :
      (if context.eagerReduce then
         true
       else if psKernelExprHasFVar left then
         false
       else if psKernelExprHasFVar right then
         false
       else
         true) with
  | false =>
      have hNativeRun :
          psKernelDefEqNativeThenLazyStep
              resume defeq coreWhnf context state left right =
            Except.ok (Prod.mk answer nextState) := by
        simpa [psKernelDefEqLazyReductionAfterPred, hEager] using hRun
      exact
        psKernelDefEqNativeThenLazyStep_configuration_sound_of_components
          resume defeq coreWhnf
          hResume hDefEq hStep hNative
          context state nextState left right answer
          hConfig hNativeRun
  | true =>
      cases hLeftNat :
          psKernelReduceNatWith whnf context state left with
      | error error =>
          simp [
            psKernelDefEqLazyReductionAfterPred,
            hEager, hLeftNat
          ] at hRun
      | ok leftRun =>
          rcases leftRun with ⟨leftAnswer, leftState⟩
          have hLeftSound :=
            psKernelReduceNatWith_configuration_sound
              whnf hWhnf
              context state leftState left leftAnswer
              hConfig hLeftNat
          cases leftAnswer with
          | some leftValue =>
              cases hEq :
                  defeq context leftState leftValue right with
              | error error =>
                  simp [
                    psKernelDefEqLazyReductionAfterPred,
                    hEager, hLeftNat, hEq
                  ] at hRun
              | ok eqRun =>
                  rcases eqRun with ⟨eqValue, eqState⟩
                  have hEqSound :=
                    hDefEq
                      context leftState eqState
                      leftValue right eqValue
                      hLeftSound.1 hEq
                  simp [
                    psKernelDefEqLazyReductionAfterPred,
                    hEager, hLeftNat, hEq
                  ] at hRun
                  rcases hRun with ⟨rfl, rfl⟩
                  refine ⟨hEqSound.1, ?_⟩
                  cases eqValue with
                  | false =>
                      trivial
                  | true =>
                      exact
                        PsKernelDefEqJudgment.reduceCompare
                          left right leftValue right
                          hLeftSound.2
                          (PsKernelReductionClosure.refl right)
                          (hEqSound.2 rfl)
          | none =>
              cases hRightNat :
                  psKernelReduceNatWith whnf context leftState right with
              | error error =>
                  simp [
                    psKernelDefEqLazyReductionAfterPred,
                    hEager, hLeftNat, hRightNat
                  ] at hRun
              | ok rightRun =>
                  rcases rightRun with ⟨rightAnswer, rightState⟩
                  have hRightSound :=
                    psKernelReduceNatWith_configuration_sound
                      whnf hWhnf
                      context leftState rightState right rightAnswer
                      hLeftSound.1 hRightNat
                  cases rightAnswer with
                  | some rightValue =>
                      cases hEq :
                          defeq context rightState left rightValue with
                      | error error =>
                          simp [
                            psKernelDefEqLazyReductionAfterPred,
                            hEager, hLeftNat, hRightNat, hEq
                          ] at hRun
                      | ok eqRun =>
                          rcases eqRun with ⟨eqValue, eqState⟩
                          have hEqSound :=
                            hDefEq
                              context rightState eqState
                              left rightValue eqValue
                              hRightSound.1 hEq
                          simp [
                            psKernelDefEqLazyReductionAfterPred,
                            hEager, hLeftNat, hRightNat, hEq
                          ] at hRun
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
                                  hRightSound.2
                                  (hEqSound.2 rfl)
                  | none =>
                      have hNativeRun :
                          psKernelDefEqNativeThenLazyStep
                              resume defeq coreWhnf
                              context rightState left right =
                            Except.ok (Prod.mk answer nextState) := by
                        simpa [
                          psKernelDefEqLazyReductionAfterPred,
                          hEager, hLeftNat, hRightNat
                        ] using hRun
                      exact
                        psKernelDefEqNativeThenLazyStep_configuration_sound_of_components
                          resume defeq coreWhnf
                          hResume hDefEq hStep hNative
                          context rightState nextState
                          left right answer
                          hRightSound.1 hNativeRun
