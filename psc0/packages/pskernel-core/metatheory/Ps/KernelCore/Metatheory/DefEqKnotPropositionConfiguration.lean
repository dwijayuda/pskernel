import Ps.KernelCore.Metatheory.DefEqKnotCoreConfiguration
import Ps.KernelCore.Metatheory.DefEqFinalConfiguration

/-
After the second Quick comparison, the concrete checker infers the type of
the reduced left side, asks the proposition classifier about that TYPE, and
branches. The true branch compares inferred types with recursive DefEq.

The non-proposition LazyDelta continuation is an explicit remaining proof
obligation. In the proposition branch the independent algorithmic
proof-irrelevance judgment and original-to-reduced closures justify success.
-/

def PsKernelDefEqKnotAfterNonPropSound (fuel : Nat) : Prop :=
  ∀ (context nextContext : PsKernelCheckerContext)
    (state quickState reflectionState leftCoreState rightCoreState
      coreQuickState leftTypeState propState nextState : PsKernelCheckerState)
    (left right leftCore rightCore leftType : PsKernelExpr)
    (value : Bool),
    PsKernelCheckerConfigurationSound nextContext propState ->
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
    psKernelIsDefEqWithFuel
        (Nat.succ fuel) context state left right =
      Except.ok (Prod.mk value nextState) ->
    PsKernelCheckerConfigurationSound nextContext nextState ∧
      (value = true ->
        PsKernelDefEqJudgment
          nextContext.environment nextContext.localContext left right)


theorem psKernelDefEqKnot_after_core_quick_sound_of_nonprop
    (fuel : Nat)
    (hDefEq :
      PsKernelDefEqConfigurationSound
        (psKernelIsDefEqWithFuel fuel))
    (hBeta : PsKernelBetaSpineSoundLaw)
    (hNative : PsKernelNativeReductionSoundLaw)
    (hAfterNonProp : PsKernelDefEqKnotAfterNonPropSound fuel) :
    PsKernelDefEqKnotAfterCoreQuickSound fuel := by
  intro
    context nextContext
    state quickState reflectionState leftCoreState rightCoreState
    coreQuickState nextState
    left right leftCore rightCore value
    hConfig hLeftReduction hRightReduction
    hEnter hDifferent hNotCached hQuickNone hReflectionNone
    hLeftCore hRightCore hCoreQuickNone hRun
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
  cases hLeftInfer :
      psKernelInferWithRecursorFuel
        fuel (psKernelIsDefEqWithFuel fuel)
        nextContext coreQuickState leftCore with
  | error error =>
      simp [
        psKernelIsDefEqWithFuel,
        hEnter, hDifferent, hNotCached, hQuickNone,
        hReflectionNone, hLeftCore, hRightCore,
        hCoreQuickNone, hLeftInfer
      ] at hRun
  | ok leftTypeRun =>
      rcases leftTypeRun with ⟨leftType, leftTypeState⟩
      have hLeftConfig :=
        hInfer
          nextContext coreQuickState leftTypeState
          leftCore leftType hConfig hLeftInfer
      cases hPropRun :
          psKernelDefEqIsPropWith
            (psKernelInferWithRecursorFuel
              fuel (psKernelIsDefEqWithFuel fuel))
            (psKernelWhnfWithRecursorFuel
              fuel (psKernelIsDefEqWithFuel fuel))
            nextContext leftTypeState leftType with
      | error error =>
          simp [
            psKernelIsDefEqWithFuel,
            hEnter, hDifferent, hNotCached, hQuickNone,
            hReflectionNone, hLeftCore, hRightCore,
            hCoreQuickNone, hLeftInfer, hPropRun
          ] at hRun
      | ok propRun =>
          rcases propRun with ⟨isProp, propState⟩
          have hPropConfig :=
            psKernelDefEqIsPropWith_configuration_preserves
              (psKernelInferWithRecursorFuel
                fuel (psKernelIsDefEqWithFuel fuel))
              (psKernelWhnfWithRecursorFuel
                fuel (psKernelIsDefEqWithFuel fuel))
              hInfer hWhnf
              nextContext leftTypeState propState
              leftType isProp hLeftConfig hPropRun
          cases isProp with
          | false =>
              exact
                hAfterNonProp
                  context nextContext
                  state quickState reflectionState leftCoreState rightCoreState
                  coreQuickState leftTypeState propState nextState
                  left right leftCore rightCore leftType value
                  hPropConfig hLeftReduction hRightReduction
                  hEnter hDifferent hNotCached
                  hQuickNone hReflectionNone hLeftCore hRightCore
                  hCoreQuickNone hLeftInfer hPropRun hRun
          | true =>
              cases hRightInfer :
                  psKernelInferWithRecursorFuel
                    fuel (psKernelIsDefEqWithFuel fuel)
                    nextContext propState rightCore with
              | error error =>
                  simp [
                    psKernelIsDefEqWithFuel,
                    hEnter, hDifferent, hNotCached,
                    hQuickNone, hReflectionNone,
                    hLeftCore, hRightCore, hCoreQuickNone,
                    hLeftInfer, hPropRun, hRightInfer
                  ] at hRun
              | ok rightTypeRun =>
                  rcases rightTypeRun with ⟨rightType, rightTypeState⟩
                  have hRightConfig :=
                    hInfer
                      nextContext propState rightTypeState
                      rightCore rightType hPropConfig hRightInfer
                  cases hCompare :
                      psKernelIsDefEqWithFuel fuel
                        nextContext rightTypeState leftType rightType with
                  | error error =>
                      simp [
                        psKernelIsDefEqWithFuel,
                        hEnter, hDifferent, hNotCached,
                        hQuickNone, hReflectionNone,
                        hLeftCore, hRightCore, hCoreQuickNone,
                        hLeftInfer, hPropRun, hRightInfer, hCompare
                      ] at hRun
                  | ok comparedRun =>
                      rcases comparedRun with ⟨comparison, comparedState⟩
                      have hCompared :=
                        hDefEq
                          nextContext rightTypeState comparedState
                          leftType rightType comparison
                          hRightConfig hCompare
                      have hSemantic :
                          comparison = true ->
                            PsKernelDefEqJudgment
                              nextContext.environment nextContext.localContext
                              left right := by
                        intro hTrue
                        have hCompareTrue :
                            psKernelIsDefEqWithFuel fuel
                                nextContext rightTypeState
                                leftType rightType =
                              Except.ok (Prod.mk true comparedState) := by
                          simpa [hTrue] using hCompare
                        exact
                          (psKernelDefEqKnot_proof_irrelevance_branch
                            (psKernelIsDefEqWithFuel fuel)
                            (psKernelInferWithRecursorFuel
                              fuel (psKernelIsDefEqWithFuel fuel))
                            (psKernelWhnfWithRecursorFuel
                              fuel (psKernelIsDefEqWithFuel fuel))
                            hDefEq hInfer hWhnf
                            nextContext
                            coreQuickState leftTypeState propState
                            rightTypeState comparedState
                            left right leftCore rightCore leftType rightType
                            hConfig hLeftReduction hRightReduction
                            hLeftInfer hPropRun hRightInfer hCompareTrue).2
                      have hFinished :
                          (Except.ok
                              (psKernelDefEqFinish
                                comparedState left right comparison) :
                            Except String (Prod Bool PsKernelCheckerState)) =
                          Except.ok (Prod.mk value nextState) := by
                        simpa [
                          psKernelIsDefEqWithFuel,
                          hEnter, hDifferent, hNotCached,
                          hQuickNone, hReflectionNone,
                          hLeftCore, hRightCore, hCoreQuickNone,
                          hLeftInfer, hPropRun, hRightInfer, hCompare
                        ] using hRun
                      exact
                        psKernelDefEqFinish_result_sound_ok
                          nextContext comparedState nextState
                          left right comparison value
                          hCompared.1 hSemantic hFinished
