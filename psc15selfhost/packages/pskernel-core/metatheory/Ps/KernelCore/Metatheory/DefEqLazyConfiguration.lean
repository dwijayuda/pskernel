import Ps.KernelCore.Checker.DefEq.LazyDelta
import Ps.KernelCore.Metatheory.CheckerContracts
import Ps.KernelCore.Metatheory.ProjectionReduction
import Ps.KernelCore.Metatheory.Delta
import Ps.KernelCore.Metatheory.Comparator

/-
Independent refinement of the terminal projection comparison used by
lazy-delta.  The concrete worker compares the computed fields only when
*both* projections reduce.  If either field is unavailable it compares the
original major premises and applies projection congruence instead.

No general transitivity of algorithmic DefEq is used.
-/

theorem psKernelDefEqLazyProjFinish_configuration_sound
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
    (typeName : PsKernelName)
    (index : Nat)
    (value : Bool)
    (hConfig : PsKernelCheckerConfigurationSound context state)
    (hSuccess :
      psKernelDefEqLazyProjFinish
          defeq context state left right typeName index =
        Except.ok (Prod.mk value nextState)) :
    PsKernelCheckerConfigurationSound context nextState ∧
      (value = true ->
        PsKernelDefEqJudgment
          context.environment
          context.localContext
          (PsKernelExpr.proj typeName index left)
          (PsKernelExpr.proj typeName index right)) := by
  unfold psKernelDefEqLazyProjFinish at hSuccess
  cases hLeft :
      psKernelReduceProjCore context typeName index left with
  | none =>
      simp only [hLeft] at hSuccess
      have hEq :=
        hDefEq
          context state nextState left right value
          hConfig hSuccess
      refine ⟨hEq.1, ?_⟩
      intro hTrue
      exact
        PsKernelDefEqJudgment.projection
          typeName index left right
          (hEq.2 hTrue)
  | some leftValue =>
      cases hRight :
          psKernelReduceProjCore context typeName index right with
      | none =>
          simp only [hLeft, hRight] at hSuccess
          have hEq :=
            hDefEq
              context state nextState left right value
              hConfig hSuccess
          refine ⟨hEq.1, ?_⟩
          intro hTrue
          exact
            PsKernelDefEqJudgment.projection
              typeName index left right
              (hEq.2 hTrue)
      | some rightValue =>
          simp only [hLeft, hRight] at hSuccess
          have hEq :=
            hDefEq
              context state nextState
              leftValue rightValue value
              hConfig hSuccess
          refine ⟨hEq.1, ?_⟩
          intro hTrue
          exact
            PsKernelDefEqJudgment.reduceCompare
              (PsKernelExpr.proj typeName index left)
              (PsKernelExpr.proj typeName index right)
              leftValue
              rightValue
              (psKernelReduceProjCore_some_refines_closure
                context typeName index left leftValue
                hConfig.1 hLeft)
              (psKernelReduceProjCore_some_refines_closure
                context typeName index right rightValue
                hConfig.1 hRight)
              (hEq.2 hTrue)


/-
The one-step lazy-delta dispatcher preserves reductions for each residual pair.
Its successful equal case carries independent algorithmic DefEq evidence;
negative comparisons and non-decisions do not assert equality.

This is a relational contract (rather than an executable equation) and can be
composed through fuel induction without assuming DefEq transitivity.
-/
def PsKernelDeltaStepPostcondition
    (context : PsKernelCheckerContext)
    (nextState : PsKernelCheckerState)
    (left right : PsKernelExpr)
    (answer : PsKernelDeltaStepResult) : Prop :=
  PsKernelCheckerConfigurationSound context nextState ∧
    match answer with
    | PsKernelDeltaStepResult.equal =>
        PsKernelDefEqJudgment
          context.environment context.localContext left right
    | PsKernelDeltaStepResult.continue nextLeft nextRight =>
        PsKernelReductionClosure
          context.environment context.localContext left nextLeft ∧
        PsKernelReductionClosure
          context.environment context.localContext right nextRight
    | PsKernelDeltaStepResult.unknown nextLeft nextRight =>
        PsKernelReductionClosure
          context.environment context.localContext left nextLeft ∧
        PsKernelReductionClosure
          context.environment context.localContext right nextRight
    | PsKernelDeltaStepResult.different nextLeft nextRight =>
        PsKernelReductionClosure
          context.environment context.localContext left nextLeft ∧
        PsKernelReductionClosure
          context.environment context.localContext right nextRight


theorem psKernelDefEqFinishLazyStep_configuration_sound
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String (Prod Bool PsKernelCheckerState))
    (hQuick :
      PsKernelOptionalDefEqConfigurationSound
        (psKernelDefEqQuick defeq))
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (left right : PsKernelExpr)
    (answer : PsKernelDeltaStepResult)
    (hConfig : PsKernelCheckerConfigurationSound context state)
    (hRun :
      psKernelDefEqFinishLazyStep
          defeq context state left right =
        Except.ok (Prod.mk answer nextState)) :
    PsKernelDeltaStepPostcondition
      context nextState left right answer := by
  simp only [psKernelDefEqFinishLazyStep] at hRun
  cases hQuickRun :
      psKernelDefEqQuick defeq context state left right with
  | error error =>
      simp only [hQuickRun] at hRun
      simp at hRun
  | ok quickRun =>
      simp only [hQuickRun] at hRun
      rcases quickRun with ⟨quickAnswer, quickState⟩
      have hQuickSound :=
        hQuick
          context state quickState left right quickAnswer
          hConfig hQuickRun
      cases quickAnswer with
      | none =>
          simp at hRun
          rcases hRun with ⟨rfl, rfl⟩
          exact
            ⟨
              hQuickSound.1,
              PsKernelReductionClosure.refl left,
              PsKernelReductionClosure.refl right
            ⟩
      | some quickValue =>
          cases quickValue with
          | false =>
              simp at hRun
              rcases hRun with ⟨rfl, rfl⟩
              exact
                ⟨
                  hQuickSound.1,
                  PsKernelReductionClosure.refl left,
                  PsKernelReductionClosure.refl right
                ⟩
          | true =>
              simp at hRun
              rcases hRun with ⟨rfl, rfl⟩
              exact ⟨hQuickSound.1, hQuickSound.2⟩


/-
Transport a complete delta-step result across previously justified reductions.
The equal branch composes by the *specific* reduce-then-compare rule.
Other branches compose reduction closures, not algorithmic DefEq proofs.
-/
theorem psKernelDeltaStepPostcondition_transport
    (context : PsKernelCheckerContext)
    (nextState : PsKernelCheckerState)
    (originalLeft originalRight left right : PsKernelExpr)
    (answer : PsKernelDeltaStepResult)
    (hLeft :
      PsKernelReductionClosure
        context.environment context.localContext
        originalLeft left)
    (hRight :
      PsKernelReductionClosure
        context.environment context.localContext
        originalRight right)
    (hStep :
      PsKernelDeltaStepPostcondition
        context nextState left right answer) :
    PsKernelDeltaStepPostcondition
      context nextState originalLeft originalRight answer := by
  rcases hStep with ⟨hConfig, hResult⟩
  refine ⟨hConfig, ?_⟩
  cases answer with
  | equal =>
      exact
        PsKernelDefEqJudgment.reduceCompare
          originalLeft originalRight left right
          hLeft hRight hResult
  | «continue» nextLeft nextRight =>
      exact
        ⟨
          psKernelReductionClosure_trans
            context.environment context.localContext
            originalLeft left nextLeft
            hLeft hResult.1,
          psKernelReductionClosure_trans
            context.environment context.localContext
            originalRight right nextRight
            hRight hResult.2
        ⟩
  | unknown nextLeft nextRight =>
      exact
        ⟨
          psKernelReductionClosure_trans
            context.environment context.localContext
            originalLeft left nextLeft
            hLeft hResult.1,
          psKernelReductionClosure_trans
            context.environment context.localContext
            originalRight right nextRight
            hRight hResult.2
        ⟩
  | different nextLeft nextRight =>
      exact
        ⟨
          psKernelReductionClosure_trans
            context.environment context.localContext
            originalLeft left nextLeft
            hLeft hResult.1,
          psKernelReductionClosure_trans
            context.environment context.localContext
            originalRight right nextRight
            hRight hResult.2
        ⟩


/-
A projection-headed application is only published as an optional reduction
after the core WHNF callback has supplied an independently certified closure.
Non-projection heads and unchanged projections return no reduction.
-/
theorem psKernelDefEqTryUnfoldProjApp_configuration_sound
    (coreWhnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Bool ->
      Bool ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (hCore : PsKernelWhnfCoreConfigurationSound coreWhnf)
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (expr : PsKernelExpr)
    (answer : Option PsKernelExpr)
    (hConfig : PsKernelCheckerConfigurationSound context state)
    (hRun :
      psKernelDefEqTryUnfoldProjApp
          coreWhnf context state expr =
        Except.ok (Prod.mk answer nextState)) :
    PsKernelOptionalReductionPostcondition
      context nextState expr answer := by
  cases hHead : psKernelExprGetAppFn expr with
  | proj typeName index body =>
      cases hCoreRun :
          coreWhnf context state expr false false with
      | error error =>
          simp [
            psKernelDefEqTryUnfoldProjApp,
            hHead,
            hCoreRun
          ] at hRun
      | ok coreRun =>
          rcases coreRun with ⟨reduced, coreState⟩
          have hCoreSound :=
            hCore
              context state coreState expr reduced
              false false hConfig hCoreRun
          cases hEq : psKernelExprEq reduced expr with
          | true =>
              simp [
                psKernelDefEqTryUnfoldProjApp,
                hHead,
                hCoreRun,
                hEq
              ] at hRun
              rcases hRun with ⟨rfl, rfl⟩
              exact ⟨hCoreSound.2, trivial⟩
          | false =>
              simp [
                psKernelDefEqTryUnfoldProjApp,
                hHead,
                hCoreRun,
                hEq
              ] at hRun
              rcases hRun with ⟨rfl, rfl⟩
              exact ⟨hCoreSound.2, hCoreSound.1⟩
  | _ =>
      simp [
        psKernelDefEqTryUnfoldProjApp,
        hHead
      ] at hRun
      rcases hRun with ⟨rfl, rfl⟩
      exact ⟨hConfig, trivial⟩


/-
DefEq unfolding changes only the semantic unfold cache; it leaves the
authoritative environment index and fresh-local bound untouched.
The semantic-cache refinement is single-owned by Metatheory.Delta.
-/
theorem psKernelDefEqUnfold_configuration_preserves
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (expr : PsKernelExpr)
    (hConfig : PsKernelCheckerConfigurationSound context state) :
    PsKernelCheckerConfigurationSound
      context
      (Prod.snd
        (psKernelDefEqUnfold context state expr)) := by
  rcases hConfig with ⟨hIndex, hFresh, hSemantic⟩
  have hFreshEq :
      (Prod.snd
        (psKernelDefEqUnfold
          context state expr)).nextFresh =
        state.nextFresh := by
    cases hEligible : psKernelSemanticCacheEligible expr <;>
      cases hCache :
          psKernelExprMapGet state.unfold expr <;>
        cases hDirect :
            psKernelUnfoldDefinition context expr <;>
          simp [
            psKernelDefEqUnfold,
            hEligible,
            hCache,
            hDirect,
            psKernelCheckerStateWithUnfold
          ]
  refine ⟨hIndex, ?_, ?_⟩
  · simpa only [hFreshEq] using hFresh
  · exact
      psKernelDefEqUnfold_preserves_semantic_sound
        context state expr
        hIndex
        psKernelReductionCacheInsertLaw_all
        hSemantic


/-
One delta unfolding followed by core WHNF is a genuine reduction closure.
Unfold-cache soundness and the full checker configuration are preserved
through both stages; the delta step never manufactures definitional equality.
-/
theorem psKernelDefEqDeltaOnce_configuration_sound
    (coreWhnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Bool ->
      Bool ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (hCore : PsKernelWhnfCoreConfigurationSound coreWhnf)
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (expr result : PsKernelExpr)
    (hConfig : PsKernelCheckerConfigurationSound context state)
    (hRun :
      psKernelDefEqDeltaOnce
          coreWhnf context state expr =
        Except.ok (Prod.mk result nextState)) :
    PsKernelReductionClosure
        context.environment context.localContext expr result ∧
      PsKernelCheckerConfigurationSound context nextState := by
  let unfolded :=
    psKernelDefEqUnfold context state expr
  have hUnfoldConfig :
      PsKernelCheckerConfigurationSound
        context (Prod.snd unfolded) := by
    simpa [unfolded] using
      (psKernelDefEqUnfold_configuration_preserves
        context state expr hConfig)
  have hUnfoldCache :
      PsKernelReductionCacheSound
        context.environment
        context.localContext
        state.unfold := by
    rcases hConfig.2.2 with
      ⟨_, _, _, _, hCache, _⟩
    exact hCache
  cases hValue : Prod.fst unfolded with
  | none =>
      simp [
        psKernelDefEqDeltaOnce,
        unfolded,
        hValue
      ] at hRun
  | some unfoldedExpr =>
      have hCoreRun :
          coreWhnf
              context
              (Prod.snd unfolded)
              unfoldedExpr
              false
              true =
            Except.ok (Prod.mk result nextState) := by
        simpa [
          psKernelDefEqDeltaOnce,
          unfolded,
          hValue
        ] using hRun
      have hCoreSound :=
        hCore
          context
          (Prod.snd unfolded)
          nextState
          unfoldedExpr
          result
          false
          true
          hUnfoldConfig
          hCoreRun
      have hUnfoldSome :
          Prod.fst
              (psKernelDefEqUnfold
                context state expr) =
            Option.some unfoldedExpr := by
        simpa [unfolded] using hValue
      have hUnfoldReduction :=
        psKernelDefEqUnfold_some_refines_reduction
          context state expr unfoldedExpr
          hConfig.1
          hUnfoldCache
          hUnfoldSome
      exact
        ⟨
          psKernelReductionClosure_trans
            context.environment
            context.localContext
            expr
            unfoldedExpr
            result
            hUnfoldReduction
            hCoreSound.1,
          hCoreSound.2
        ⟩


/-
The one-sided lazy-delta steps are the first consumers of the independent
step-result transport law. A successful projection-unfold or delta-once
operation preserves state soundness and supplies a reduction closure. The
terminal quick comparison is then transported back across that closure.
-/
theorem psKernelDefEqLazyStepRightOnly_configuration_sound
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
      psKernelDefEqLazyStepRightOnly
          defeq coreWhnf context state left right =
        Except.ok (Prod.mk answer nextState)) :
    PsKernelDeltaStepPostcondition
      context nextState left right answer := by
  unfold psKernelDefEqLazyStepRightOnly at hRun
  cases hProj :
      psKernelDefEqTryUnfoldProjApp
        coreWhnf context state left with
  | error error =>
      simp only [hProj] at hRun
      simp at hRun
  | ok projRun =>
      simp only [hProj] at hRun
      rcases projRun with ⟨projAnswer, projState⟩
      have hProjSound :=
        psKernelDefEqTryUnfoldProjApp_configuration_sound
          coreWhnf hCore
          context state projState left projAnswer
          hConfig hProj
      cases projAnswer with
      | some leftValue =>
          have hFinish :=
            psKernelDefEqFinishLazyStep_configuration_sound
              defeq hQuick
              context projState nextState
              leftValue right answer
              hProjSound.1 hRun
          exact
            psKernelDeltaStepPostcondition_transport
              context nextState
              left right leftValue right answer
              hProjSound.2
              (PsKernelReductionClosure.refl right)
              hFinish
      | none =>
          cases hDelta :
              psKernelDefEqDeltaOnce
                coreWhnf context projState right with
          | error error =>
              simp only [hDelta] at hRun
              simp at hRun
          | ok deltaRun =>
              simp only [hDelta] at hRun
              rcases deltaRun with ⟨rightValue, deltaState⟩
              have hDeltaSound :=
                psKernelDefEqDeltaOnce_configuration_sound
                  coreWhnf hCore
                  context projState deltaState
                  right rightValue hProjSound.1 hDelta
              have hFinish :=
                psKernelDefEqFinishLazyStep_configuration_sound
                  defeq hQuick
                  context deltaState nextState
                  left rightValue answer
                  hDeltaSound.2 hRun
              exact
                psKernelDeltaStepPostcondition_transport
                  context nextState
                  left right left rightValue answer
                  (PsKernelReductionClosure.refl left)
                  hDeltaSound.1
                  hFinish


theorem psKernelDefEqLazyStepLeftOnly_configuration_sound
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
      psKernelDefEqLazyStepLeftOnly
          defeq coreWhnf context state left right =
        Except.ok (Prod.mk answer nextState)) :
    PsKernelDeltaStepPostcondition
      context nextState left right answer := by
  unfold psKernelDefEqLazyStepLeftOnly at hRun
  cases hProj :
      psKernelDefEqTryUnfoldProjApp
        coreWhnf context state right with
  | error error =>
      simp only [hProj] at hRun
      simp at hRun
  | ok projRun =>
      simp only [hProj] at hRun
      rcases projRun with ⟨projAnswer, projState⟩
      have hProjSound :=
        psKernelDefEqTryUnfoldProjApp_configuration_sound
          coreWhnf hCore
          context state projState right projAnswer
          hConfig hProj
      cases projAnswer with
      | some rightValue =>
          have hFinish :=
            psKernelDefEqFinishLazyStep_configuration_sound
              defeq hQuick
              context projState nextState
              left rightValue answer
              hProjSound.1 hRun
          exact
            psKernelDeltaStepPostcondition_transport
              context nextState
              left right left rightValue answer
              (PsKernelReductionClosure.refl left)
              hProjSound.2
              hFinish
      | none =>
          cases hDelta :
              psKernelDefEqDeltaOnce
                coreWhnf context projState left with
          | error error =>
              simp only [hDelta] at hRun
              simp at hRun
          | ok deltaRun =>
              simp only [hDelta] at hRun
              rcases deltaRun with ⟨leftValue, deltaState⟩
              have hDeltaSound :=
                psKernelDefEqDeltaOnce_configuration_sound
                  coreWhnf hCore
                  context projState deltaState
                  left leftValue hProjSound.1 hDelta
              have hFinish :=
                psKernelDefEqFinishLazyStep_configuration_sound
                  defeq hQuick
                  context deltaState nextState
                  leftValue right answer
                  hDeltaSound.2 hRun
              exact
                psKernelDeltaStepPostcondition_transport
                  context nextState
                  left right leftValue right answer
                  hDeltaSound.1
                  (PsKernelReductionClosure.refl right)
                  hFinish


/-
When one definition has strictly lower reducibility hints, the executable
lazy-delta step unfolds exactly that side before its terminal comparison.
These laws transport the resulting positive decision back through the
independently certified delta reduction; they do not require transitivity.
-/
theorem psKernelDefEqLazyStepBoth_left_hint_configuration_sound
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
    (leftDef rightDef : PsKernelDefinitionInfo)
    (answer : PsKernelDeltaStepResult)
    (hLeftHint :
      psKernelReducibilityHintsLt
        leftDef.hints rightDef.hints = true)
    (hConfig : PsKernelCheckerConfigurationSound context state)
    (hRun :
      psKernelDefEqLazyStepBoth
          defeq coreWhnf context state
          left right leftDef rightDef =
        Except.ok (Prod.mk answer nextState)) :
    PsKernelDeltaStepPostcondition
      context nextState left right answer := by
  simp [psKernelDefEqLazyStepBoth, hLeftHint] at hRun
  cases hDelta :
      psKernelDefEqDeltaOnce coreWhnf context state left with
  | error error =>
      simp only [hDelta] at hRun
      simp at hRun
  | ok deltaRun =>
      simp only [hDelta] at hRun
      rcases deltaRun with ⟨leftValue, deltaState⟩
      have hDeltaSound :=
        psKernelDefEqDeltaOnce_configuration_sound
          coreWhnf hCore
          context state deltaState left leftValue
          hConfig hDelta
      have hFinish :=
        psKernelDefEqFinishLazyStep_configuration_sound
          defeq hQuick
          context deltaState nextState
          leftValue right answer
          hDeltaSound.2 hRun
      exact
        psKernelDeltaStepPostcondition_transport
          context nextState left right leftValue right answer
          hDeltaSound.1
          (PsKernelReductionClosure.refl right)
          hFinish


theorem psKernelDefEqLazyStepBoth_right_hint_configuration_sound
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
    (leftDef rightDef : PsKernelDefinitionInfo)
    (answer : PsKernelDeltaStepResult)
    (hNoLeft :
      psKernelReducibilityHintsLt
        leftDef.hints rightDef.hints = false)
    (hRightHint :
      psKernelReducibilityHintsLt
        rightDef.hints leftDef.hints = true)
    (hConfig : PsKernelCheckerConfigurationSound context state)
    (hRun :
      psKernelDefEqLazyStepBoth
          defeq coreWhnf context state
          left right leftDef rightDef =
        Except.ok (Prod.mk answer nextState)) :
    PsKernelDeltaStepPostcondition
      context nextState left right answer := by
  simp [psKernelDefEqLazyStepBoth, hNoLeft, hRightHint] at hRun
  cases hDelta :
      psKernelDefEqDeltaOnce coreWhnf context state right with
  | error error =>
      simp only [hDelta] at hRun
      simp at hRun
  | ok deltaRun =>
      simp only [hDelta] at hRun
      rcases deltaRun with ⟨rightValue, deltaState⟩
      have hDeltaSound :=
        psKernelDefEqDeltaOnce_configuration_sound
          coreWhnf hCore
          context state deltaState right rightValue
          hConfig hDelta
      have hFinish :=
        psKernelDefEqFinishLazyStep_configuration_sound
          defeq hQuick
          context deltaState nextState
          left rightValue answer
          hDeltaSound.2 hRun
      exact
        psKernelDeltaStepPostcondition_transport
          context nextState left right left rightValue answer
          (PsKernelReductionClosure.refl left)
          hDeltaSound.1
          hFinish


/-
Same-definition lazy-delta can elide a head comparison only with independent
head-name and universe evidence. The string comparison assumption is explicit:
it is not hidden inside the equality judgment or inferred from an optimized
cache hit.
-/
theorem psKernelLevelListsEquivalent_normalized_sound
    (hString : PsKernelStringEqSoundLaw)
    (left right : List PsKernelLevel)
    (hEquivalent :
      psKernelLevelListsEquivalent left right = true) :
    List.map psKernelLevelNormalize left =
      List.map psKernelLevelNormalize right := by
  induction left generalizing right with
  | nil =>
      cases right with
      | nil => rfl
      | cons head tail =>
          simp [psKernelLevelListsEquivalent] at hEquivalent
  | cons leftHead leftTail ih =>
      cases right with
      | nil =>
          simp [psKernelLevelListsEquivalent] at hEquivalent
      | cons rightHead rightTail =>
          cases hHead :
              psKernelLevelEquivalent leftHead rightHead with
          | false =>
              simp [psKernelLevelListsEquivalent, hHead] at hEquivalent
          | true =>
              have hTail :
                  psKernelLevelListsEquivalent
                      leftTail rightTail = true := by
                simpa [psKernelLevelListsEquivalent, hHead] using hEquivalent
              have hNormalized :=
                psKernelLevelEquivalent_sound_of_string_law
                  hString leftHead rightHead hHead
              have hRest := ih rightTail hTail
              simp [hNormalized, hRest]


theorem psKernelAppHeadLevelsEquivalent_normalized_sound
    (hString : PsKernelStringEqSoundLaw)
    (left right : PsKernelExpr)
    (leftName rightName : PsKernelName)
    (leftLevels rightLevels : List PsKernelLevel)
    (hLeft :
      psKernelExprGetAppFn left =
        PsKernelExpr.const leftName leftLevels)
    (hRight :
      psKernelExprGetAppFn right =
        PsKernelExpr.const rightName rightLevels)
    (hLevels :
      psKernelAppHeadLevelsEquivalent left right = true) :
    List.map psKernelLevelNormalize leftLevels =
      List.map psKernelLevelNormalize rightLevels := by
  unfold psKernelAppHeadLevelsEquivalent at hLevels
  rw [hLeft, hRight] at hLevels
  exact
    psKernelLevelListsEquivalent_normalized_sound
      hString leftLevels rightLevels hLevels


theorem psKernelSameDeltaDefinition_name_sound
    (hString : PsKernelStringEqSoundLaw)
    (left right : PsKernelDefinitionInfo)
    (hSame : psKernelSameDeltaDefinition left right = true) :
    left.base.name = right.base.name := by
  exact
    psKernelNameEq_sound_of_string_law
      hString left.base.name right.base.name
      (by simpa [psKernelSameDeltaDefinition] using hSame)


/-
The only sound way for lazy-delta to omit the head comparison is to connect
both supplied definition descriptors to the actual queried constant heads.
The name and normalized universe comparisons then justify a particular
algorithmic constant-head DefEq judgment.
-/
theorem psKernelLazyDelta_same_definition_head_sound
    (hString : PsKernelStringEqSoundLaw)
    (context : PsKernelCheckerContext)
    (left right : PsKernelExpr)
    (leftDef rightDef : PsKernelDefinitionInfo)
    (hLeftDef :
      psKernelDeltaDefinition context left = Option.some leftDef)
    (hRightDef :
      psKernelDeltaDefinition context right = Option.some rightDef)
    (hSame :
      psKernelSameDeltaDefinition leftDef rightDef = true)
    (hLevels :
      psKernelAppHeadLevelsEquivalent left right = true) :
    PsKernelDefEqJudgment
      context.environment context.localContext
      (psKernelExprGetAppFn left)
      (psKernelExprGetAppFn right) := by
  obtain ⟨leftName, leftLevels, hLeftHead, _, hLeftName⟩ :=
    psKernelDeltaDefinition_some_head_matches
      context left leftDef hLeftDef
  obtain ⟨rightName, rightLevels, hRightHead, _, hRightName⟩ :=
    psKernelDeltaDefinition_some_head_matches
      context right rightDef hRightDef
  have hLeftNameEq :=
    psKernelNameEq_sound_of_string_law
      hString leftDef.base.name leftName hLeftName
  have hRightNameEq :=
    psKernelNameEq_sound_of_string_law
      hString rightDef.base.name rightName hRightName
  have hDefinitionNameEq :=
    psKernelSameDeltaDefinition_name_sound
      hString leftDef rightDef hSame
  have hHeadNameEq : leftName = rightName := by
    calc
      leftName = leftDef.base.name := hLeftNameEq.symm
      _ = rightDef.base.name := hDefinitionNameEq
      _ = rightName := hRightNameEq
  have hNormalized :=
    psKernelAppHeadLevelsEquivalent_normalized_sound
      hString left right
      leftName rightName leftLevels rightLevels
      hLeftHead hRightHead hLevels
  rw [hLeftHead, hRightHead]
  rw [← hHeadNameEq]
  exact
    PsKernelDefEqJudgment.constLevels
      leftName leftLevels rightLevels hNormalized


/-
The full same-definition fast-path guard certifies actual head equality only
when backed by both authoritative lookup results. The nonempty-spine and
regular-hint checks remain explicit control guards; the independent equality
evidence comes from stored declaration names and normalized universes.
-/
theorem psKernelLazyDelta_same_shortcut_head_sound
    (hString : PsKernelStringEqSoundLaw)
    (context : PsKernelCheckerContext)
    (left right : PsKernelExpr)
    (leftDef rightDef : PsKernelDefinitionInfo)
    (hLeftDef :
      psKernelDeltaDefinition context left = Option.some leftDef)
    (hRightDef :
      psKernelDeltaDefinition context right = Option.some rightDef)
    (hShortcut :
      (if
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
         false) = true) :
    PsKernelDefEqJudgment
      context.environment context.localContext
      (psKernelExprGetAppFn left)
      (psKernelExprGetAppFn right) := by
  cases hLeftMore :
      psKernelNatGt (psKernelExprGetAppNumArgs left) 0 with
  | false =>
      simp [hLeftMore] at hShortcut
  | true =>
      cases hRightMore :
          psKernelNatGt (psKernelExprGetAppNumArgs right) 0 with
      | false =>
          simp [hLeftMore, hRightMore] at hShortcut
      | true =>
          cases hSame :
              psKernelSameDeltaDefinition leftDef rightDef with
          | false =>
              simp [hLeftMore, hRightMore, hSame] at hShortcut
          | true =>
              cases hRegular :
                  psKernelReducibilityHintsIsRegular leftDef.hints with
              | false =>
                  simp [
                    hLeftMore, hRightMore, hSame, hRegular
                  ] at hShortcut
              | true =>
                  have hLevels :
                      psKernelAppHeadLevelsEquivalent left right =
                        true := by
                    simpa [
                      hLeftMore, hRightMore, hSame, hRegular
                    ] using hShortcut
                  exact
                    psKernelLazyDelta_same_definition_head_sound
                      hString
                      context left right leftDef rightDef
                      hLeftDef hRightDef hSame hLevels


/-
Semantic/result contract of the fuel-driven lazy-delta engine.

A positive decision must have independent algorithmic DefEq evidence, but a
negative decision is not a completeness theorem. Residuals are justified
through two ordinary reduction closures. The contract deliberately has no
unrestricted DefEq transitivity.
-/
def PsKernelDeltaResultPostcondition
    (context : PsKernelCheckerContext)
    (nextState : PsKernelCheckerState)
    (left right : PsKernelExpr)
    (answer : PsKernelDeltaResult) : Prop :=
  PsKernelCheckerConfigurationSound context nextState ∧
    match answer with
    | PsKernelDeltaResult.decided true =>
        PsKernelDefEqJudgment
          context.environment context.localContext left right
    | PsKernelDeltaResult.decided false =>
        True
    | PsKernelDeltaResult.residual nextLeft nextRight =>
        PsKernelReductionClosure
          context.environment context.localContext left nextLeft ∧
        PsKernelReductionClosure
          context.environment context.localContext right nextRight


theorem psKernelDeltaResultPostcondition_transport
    (context : PsKernelCheckerContext)
    (nextState : PsKernelCheckerState)
    (originalLeft originalRight left right : PsKernelExpr)
    (answer : PsKernelDeltaResult)
    (hLeft :
      PsKernelReductionClosure
        context.environment context.localContext
        originalLeft left)
    (hRight :
      PsKernelReductionClosure
        context.environment context.localContext
        originalRight right)
    (hResult :
      PsKernelDeltaResultPostcondition
        context nextState left right answer) :
    PsKernelDeltaResultPostcondition
      context nextState originalLeft originalRight answer := by
  rcases hResult with ⟨hConfig, hSemantic⟩
  refine ⟨hConfig, ?_⟩
  cases answer with
  | decided value =>
      cases value with
      | false =>
          trivial
      | true =>
          exact
            PsKernelDefEqJudgment.reduceCompare
              originalLeft originalRight left right
              hLeft hRight hSemantic
  | residual nextLeft nextRight =>
      exact
        ⟨
          psKernelReductionClosure_trans
            context.environment context.localContext
            originalLeft left nextLeft
            hLeft hSemantic.1,
          psKernelReductionClosure_trans
            context.environment context.localContext
            originalRight right nextRight
            hRight hSemantic.2
        ⟩
