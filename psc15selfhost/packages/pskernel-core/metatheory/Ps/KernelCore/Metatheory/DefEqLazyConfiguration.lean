import Ps.KernelCore.Checker.DefEq.LazyDelta
import Ps.KernelCore.Metatheory.CheckerContracts
import Ps.KernelCore.Metatheory.ProjectionReduction
import Ps.KernelCore.Metatheory.Delta

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
