import Ps.KernelCore.Metatheory.DefEqProjectionShortcutConfiguration
import Ps.KernelCore.Metatheory.ExprEq
import Ps.KernelCore.Metatheory.ContextState
import Ps.KernelCore.Metatheory.DefEqFinalConfiguration
import Ps.KernelCore.Metatheory.DefEqLazyConfiguration

/-
Reusable concrete DefEq knot boundaries.

These small facts are shared by the concrete fuel induction: exhaustion
cannot report success; a successful structural comparison and a successful
cache hit have independently justified DefEq evidence; and publication
of a reduced comparison is justified by explicit reduction closures.

None of these rules introduces general DefEq transitivity.
-/

theorem psKernelDefEqKnot_zero_configuration_sound :
    PsKernelDefEqConfigurationSound
      (psKernelIsDefEqWithFuel 0) := by
  intro context state nextState left right value hConfig hRun
  simp [psKernelIsDefEqWithFuel] at hRun


theorem psKernelDefEqKnot_structural_branch_sound
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (left right : PsKernelExpr)
    (hConfig :
      PsKernelCheckerConfigurationSound context state)
    (hEq : psKernelExprEq left right = true)
    (hRun :
      (Except.ok
          (psKernelDefEqFinish state left right true) :
        Except String (Prod Bool PsKernelCheckerState)) =
      Except.ok (Prod.mk true nextState)) :
    PsKernelCheckerConfigurationSound context nextState ∧
      PsKernelDefEqJudgment
        context.environment context.localContext left right := by
  have hSemantic :=
    psKernelExprEq_true_implies_defeq
      context.environment context.localContext left right hEq
  have hResult :=
    psKernelDefEqFinish_result_sound_ok
      context state nextState left right true true
      hConfig (fun _ => hSemantic) hRun
  exact ⟨hResult.1, hResult.2 rfl⟩


theorem psKernelDefEqKnot_success_cache_sound
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (left right : PsKernelExpr)
    (hConfig :
      PsKernelCheckerConfigurationSound context state)
    (hHit :
      psKernelDefEqSuccessCacheHit state left right = true) :
    PsKernelCheckerConfigurationSound context state ∧
      PsKernelDefEqJudgment
        context.environment context.localContext left right := by
  have hCache :
      PsKernelDefEqCacheSound
        context.environment context.localContext state.success := by
    rcases hConfig.2.2 with
      ⟨_, _, _, _, _, hSuccessCache⟩
    exact hSuccessCache
  have hRaw : psKernelExprPairSetContains state.success left right = true := by
    cases hEligible : psKernelSemanticPairCacheEligible left right with
    | false => simp [psKernelDefEqSuccessCacheHit, psKernelCachedCacheContains_eq, PsKernelSemanticCachePolicy.enabled, psKernelCachedCachePolicy, hEligible] at hHit
    | true => simpa [psKernelDefEqSuccessCacheHit, psKernelCachedCacheContains_eq, PsKernelSemanticCachePolicy.enabled, psKernelCachedCachePolicy, hEligible] using hHit
  exact ⟨hConfig, hCache left right hRaw⟩


theorem psKernelDefEqKnot_lift_optional
    (context : PsKernelCheckerContext)
    (nextState : PsKernelCheckerState)
    (originalLeft originalRight left right : PsKernelExpr)
    (answer : Option Bool)
    (hLeft :
      PsKernelReductionClosure
        context.environment context.localContext originalLeft left)
    (hRight :
      PsKernelReductionClosure
        context.environment context.localContext originalRight right)
    (hPost :
      PsKernelOptionalDefEqPostcondition
        context nextState left right answer) :
    PsKernelCheckerConfigurationSound context nextState ∧
      (answer = Option.some true ->
        PsKernelDefEqJudgment
          context.environment context.localContext
          originalLeft originalRight) := by
  refine ⟨hPost.1, ?_⟩
  cases answer with
  | none =>
      intro hImpossible
      cases hImpossible
  | some value =>
      cases value with
      | false =>
          intro hImpossible
          cases hImpossible
      | true =>
          intro _
          exact
            PsKernelDefEqJudgment.reduceCompare
              originalLeft originalRight left right
              hLeft hRight hPost.2


theorem psKernelDefEqKnot_finish_after_reduction
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (originalLeft originalRight left right : PsKernelExpr)
    (inputValue outputValue : Bool)
    (hConfig :
      PsKernelCheckerConfigurationSound context state)
    (hLeft :
      PsKernelReductionClosure
        context.environment context.localContext originalLeft left)
    (hRight :
      PsKernelReductionClosure
        context.environment context.localContext originalRight right)
    (hSemantic :
      inputValue = true ->
        PsKernelDefEqJudgment
          context.environment context.localContext left right)
    (hRun :
      (Except.ok
          (psKernelDefEqFinish
            state originalLeft originalRight inputValue) :
        Except String (Prod Bool PsKernelCheckerState)) =
      Except.ok (Prod.mk outputValue nextState)) :
    PsKernelCheckerConfigurationSound context nextState ∧
      (outputValue = true ->
        PsKernelDefEqJudgment
          context.environment context.localContext
          originalLeft originalRight) := by
  exact
    psKernelDefEqFinish_result_sound_ok
      context state nextState
      originalLeft originalRight inputValue outputValue
      hConfig
      (fun hTrue =>
        PsKernelDefEqJudgment.reduceCompare
          originalLeft originalRight left right
          hLeft hRight (hSemantic hTrue))
      hRun

/-
Algorithmic proof-irrelevance phase in the concrete checker knot.

It classifies the *inferred type* of the left type as a proposition, then
compares the two inferred types using the recursive DefEq callback.  This
establishes the independent algorithmic DefEq judgment, not yet the stronger
typed proof-irrelevance theorem needed for final admission soundness.
-/
theorem psKernelDefEqKnot_proof_irrelevance_branch
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String (Prod Bool PsKernelCheckerState))
    (inferType whnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (hDefEq : PsKernelDefEqConfigurationSound defeq)
    (hInfer : PsKernelInferOnlyConfigurationPreserves inferType)
    (hWhnf : PsKernelWhnfConfigurationSound whnf)
    (context : PsKernelCheckerContext)
    (state leftState propState rightState finalState : PsKernelCheckerState)
    (originalLeft originalRight left right leftType rightType : PsKernelExpr)
    (hConfig : PsKernelCheckerConfigurationSound context state)
    (hLeft :
      PsKernelReductionClosure
        context.environment context.localContext originalLeft left)
    (hRight :
      PsKernelReductionClosure
        context.environment context.localContext originalRight right)
    (hLeftInfer :
      inferType context state left =
        Except.ok (Prod.mk leftType leftState))
    (hProp :
      psKernelDefEqIsPropWith
          inferType whnf context leftState leftType =
        Except.ok (Prod.mk true propState))
    (hRightInfer :
      inferType context propState right =
        Except.ok (Prod.mk rightType rightState))
    (hEqual :
      defeq context rightState leftType rightType =
        Except.ok (Prod.mk true finalState)) :
    PsKernelCheckerConfigurationSound context finalState ∧
      PsKernelDefEqJudgment
        context.environment context.localContext
        originalLeft originalRight := by
  have hLeftConfig :=
    hInfer context state leftState left leftType hConfig hLeftInfer
  have hPropConfig :=
    psKernelDefEqIsPropWith_configuration_preserves
      inferType whnf hInfer hWhnf
      context leftState propState leftType true
      hLeftConfig hProp
  obtain ⟨leftTypeType, level, hTypeSort, hLevelZero⟩ :=
    psKernelDefEqIsPropWith_true_refines
      inferType whnf hInfer hWhnf
      context leftState propState leftType
      hLeftConfig hProp
  have hRightConfig :=
    hInfer
      context propState rightState
      right rightType hPropConfig hRightInfer
  have hTypes :=
    hDefEq
      context rightState finalState
      leftType rightType true
      hRightConfig hEqual
  have hCore :
      PsKernelDefEqJudgment
        context.environment context.localContext left right :=
    PsKernelDefEqJudgment.proofIrrelevanceAlgorithmic
      left right leftType rightType leftTypeType level
      hTypeSort hLevelZero (hTypes.2 rfl)
  exact
    ⟨hTypes.1,
      PsKernelDefEqJudgment.reduceCompare
        originalLeft originalRight left right
        hLeft hRight hCore⟩


/-
Three reusable publication bridges for the knot's final stages.  The
implementation writes a success-cache entry for the *original* pair.  Such
publication is sound only after the positive intermediate result has been
transported back through actual reduction closures.
-/
theorem psKernelDefEqKnot_publish_optional
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (originalLeft originalRight left right : PsKernelExpr)
    (inputValue outputValue : Bool)
    (hLeft :
      PsKernelReductionClosure
        context.environment context.localContext originalLeft left)
    (hRight :
      PsKernelReductionClosure
        context.environment context.localContext originalRight right)
    (hPost :
      PsKernelOptionalDefEqPostcondition
        context state left right (Option.some inputValue))
    (hRun :
      (Except.ok
          (psKernelDefEqFinish
            state originalLeft originalRight inputValue) :
        Except String (Prod Bool PsKernelCheckerState)) =
      Except.ok (Prod.mk outputValue nextState)) :
    PsKernelCheckerConfigurationSound context nextState ∧
      (outputValue = true ->
        PsKernelDefEqJudgment
          context.environment context.localContext
          originalLeft originalRight) := by
  have hLift :=
    psKernelDefEqKnot_lift_optional
      context state originalLeft originalRight
      left right (Option.some inputValue)
      hLeft hRight hPost
  exact
    psKernelDefEqFinish_result_sound_ok
      context state nextState
      originalLeft originalRight inputValue outputValue
      hLift.1
      (fun hTrue =>
        hLift.2 (congrArg Option.some hTrue))
      hRun


theorem psKernelDefEqKnot_publish_recursive_comparison
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String (Prod Bool PsKernelCheckerState))
    (hDefEq : PsKernelDefEqConfigurationSound defeq)
    (context : PsKernelCheckerContext)
    (state comparedState nextState : PsKernelCheckerState)
    (originalLeft originalRight left right : PsKernelExpr)
    (inputValue outputValue : Bool)
    (hConfig :
      PsKernelCheckerConfigurationSound context state)
    (hLeft :
      PsKernelReductionClosure
        context.environment context.localContext originalLeft left)
    (hRight :
      PsKernelReductionClosure
        context.environment context.localContext originalRight right)
    (hCompare :
      defeq context state left right =
        Except.ok (Prod.mk inputValue comparedState))
    (hRun :
      (Except.ok
          (psKernelDefEqFinish
            comparedState originalLeft originalRight inputValue) :
        Except String (Prod Bool PsKernelCheckerState)) =
      Except.ok (Prod.mk outputValue nextState)) :
    PsKernelCheckerConfigurationSound context nextState ∧
      (outputValue = true ->
        PsKernelDefEqJudgment
          context.environment context.localContext
          originalLeft originalRight) := by
  have hCompared :=
    hDefEq
      context state comparedState left right inputValue
      hConfig hCompare
  exact
    psKernelDefEqKnot_finish_after_reduction
      context comparedState nextState
      originalLeft originalRight left right
      inputValue outputValue
      hCompared.1 hLeft hRight hCompared.2 hRun


theorem psKernelDefEqKnot_publish_delta_decision
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (originalLeft originalRight left right : PsKernelExpr)
    (inputValue outputValue : Bool)
    (hLeft :
      PsKernelReductionClosure
        context.environment context.localContext originalLeft left)
    (hRight :
      PsKernelReductionClosure
        context.environment context.localContext originalRight right)
    (hDelta :
      PsKernelDeltaResultPostcondition
        context state left right
        (PsKernelDeltaResult.decided inputValue))
    (hRun :
      (Except.ok
          (psKernelDefEqFinish
            state originalLeft originalRight inputValue) :
        Except String (Prod Bool PsKernelCheckerState)) =
      Except.ok (Prod.mk outputValue nextState)) :
    PsKernelCheckerConfigurationSound context nextState ∧
      (outputValue = true ->
        PsKernelDefEqJudgment
          context.environment context.localContext
          originalLeft originalRight) := by
  have hOriginal :=
    psKernelDeltaResultPostcondition_transport
      context state
      originalLeft originalRight left right
      (PsKernelDeltaResult.decided inputValue)
      hLeft hRight hDelta
  have hSemantic :
      inputValue = true ->
        PsKernelDefEqJudgment
          context.environment context.localContext
          originalLeft originalRight := by
    cases inputValue with
    | false =>
        intro hFalse
        cases hFalse
    | true =>
        intro _
        exact hOriginal.2
  exact
    psKernelDefEqFinish_result_sound_ok
      context state nextState
      originalLeft originalRight inputValue outputValue
      hOriginal.1 hSemantic hRun
