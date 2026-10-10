import Ps.KernelCore.Metatheory.DefEqBinderConfiguration
import Ps.KernelCore.Metatheory.DefEqEtaConfiguration
import Ps.KernelCore.Metatheory.DefEqApplicationConfiguration
import Ps.KernelCore.Metatheory.DefEqFinalConfiguration

/-
Configuration-aware refinement for the full-shape DefEq phase.

This theorem deliberately composes the independent helper contracts:
- lambda/forall binder spines;
- symmetric function eta in both orientations;
- flattened application congruence;
- direct Sort/literal comparison.

A negative or undecided answer carries only configuration preservation.  A
positive answer additionally carries the independent algorithmic DefEq
judgment.
-/

theorem psKernelDefEqFullShapeWith_configuration_sound
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
    (hDefEq :
      PsKernelDefEqConfigurationSound defeq)
    (hInfer :
      PsKernelInferOnlyConfigurationPreserves inferType)
    (hWhnf :
      PsKernelWhnfConfigurationSound whnf)
    (hString :
      PsKernelStringEqSoundLaw) :
    PsKernelOptionalDefEqConfigurationSound
      (psKernelDefEqFullShapeWith
        defeq inferType whnf) := by
  intro
    context state nextState left right answer
    hConfig hSuccess
  have etaLeft :
      ∀
        (name : PsKernelName)
        (domain body other : PsKernelExpr)
        (binderInfo : PsKernelBinderInfo),
        PsKernelExprIsLambdaView other = false ->
        psKernelDefEqFullShapeWith
            defeq inferType whnf context state
            (PsKernelExpr.lam name domain body binderInfo)
            other =
          Except.ok (Prod.mk answer nextState) ->
        PsKernelOptionalDefEqPostcondition
          context
          nextState
          (PsKernelExpr.lam name domain body binderInfo)
          other
          answer := by
    intro name domain body other binderInfo hOther hRun
    rw [
      psKernelDefEqFullShape_lambda_nonlambda_uses_eta_left
        defeq inferType whnf context state
        name domain body other binderInfo hOther
    ] at hRun
    exact
      psKernelDefEqLambdaEtaLeftWith_optional_configuration_sound
        defeq inferType whnf
        hDefEq hInfer hWhnf
        context state nextState
        (PsKernelExpr.lam name domain body binderInfo)
        other
        answer
        hConfig
        hRun
  have etaRight :
      ∀
        (other : PsKernelExpr)
        (name : PsKernelName)
        (domain body : PsKernelExpr)
        (binderInfo : PsKernelBinderInfo),
        PsKernelExprIsLambdaView other = false ->
        psKernelDefEqFullShapeWith
            defeq inferType whnf context state
            other
            (PsKernelExpr.lam name domain body binderInfo) =
          Except.ok (Prod.mk answer nextState) ->
        PsKernelOptionalDefEqPostcondition
          context
          nextState
          other
          (PsKernelExpr.lam name domain body binderInfo)
          answer := by
    intro other name domain body binderInfo hOther hRun
    rw [
      psKernelDefEqFullShape_nonlambda_lambda_uses_eta_right
        defeq inferType whnf context state
        other name domain body binderInfo hOther
    ] at hRun
    exact
      psKernelDefEqLambdaEtaRightWith_optional_configuration_sound
        defeq inferType whnf
        hDefEq hInfer hWhnf
        context state nextState
        other
        (PsKernelExpr.lam name domain body binderInfo)
        answer
        hConfig
        hRun
  cases left with
  | lam leftName leftDomain leftBody leftInfo =>
      cases right with
      | lam rightName rightDomain rightBody rightInfo =>
          cases hRun :
              psKernelDefEqLambdaSpine
                defeq
                context
                state
                (PsKernelExpr.lam
                  leftName leftDomain leftBody leftInfo)
                (PsKernelExpr.lam
                  rightName rightDomain rightBody rightInfo) with
          | error error =>
              simp [
                psKernelDefEqFullShapeWith,
                hRun
              ] at hSuccess
          | ok run =>
              rcases run with ⟨value, runState⟩
              have hSemantic :=
                psKernelDefEqLambdaSpine_configuration_sound
                  defeq
                  hDefEq
                  hString
                  context
                  state
                  runState
                  (PsKernelExpr.lam
                    leftName leftDomain leftBody leftInfo)
                  (PsKernelExpr.lam
                    rightName rightDomain rightBody rightInfo)
                  value
                  hConfig
                  hRun
              cases value with
              | false =>
                  simp [
                    psKernelDefEqFullShapeWith,
                    hRun
                  ] at hSuccess
                  rcases hSuccess with ⟨rfl, rfl⟩
                  exact ⟨hSemantic.1, trivial⟩
              | true =>
                  simp [
                    psKernelDefEqFullShapeWith,
                    hRun
                  ] at hSuccess
                  rcases hSuccess with ⟨rfl, rfl⟩
                  exact ⟨hSemantic.1, hSemantic.2 rfl⟩
      | bvar index =>
          exact etaLeft leftName leftDomain leftBody
            (PsKernelExpr.bvar index) leftInfo rfl hSuccess
      | fvar name =>
          exact etaLeft leftName leftDomain leftBody
            (PsKernelExpr.fvar name) leftInfo rfl hSuccess
      | mvar name =>
          exact etaLeft leftName leftDomain leftBody
            (PsKernelExpr.mvar name) leftInfo rfl hSuccess
      | sort level =>
          exact etaLeft leftName leftDomain leftBody
            (PsKernelExpr.sort level) leftInfo rfl hSuccess
      | const name levels =>
          exact etaLeft leftName leftDomain leftBody
            (PsKernelExpr.const name levels) leftInfo rfl hSuccess
      | app fn arg =>
          exact etaLeft leftName leftDomain leftBody
            (PsKernelExpr.app fn arg) leftInfo rfl hSuccess
      | forallE name type body info =>
          exact etaLeft leftName leftDomain leftBody
            (PsKernelExpr.forallE name type body info) leftInfo rfl hSuccess
      | letE name type value body nondep =>
          exact etaLeft leftName leftDomain leftBody
            (PsKernelExpr.letE name type value body nondep)
            leftInfo rfl hSuccess
      | lit literal =>
          exact etaLeft leftName leftDomain leftBody
            (PsKernelExpr.lit literal) leftInfo rfl hSuccess
      | mdata metadata body =>
          exact etaLeft leftName leftDomain leftBody
            (PsKernelExpr.mdata metadata body) leftInfo rfl hSuccess
      | proj typeName index body =>
          exact etaLeft leftName leftDomain leftBody
            (PsKernelExpr.proj typeName index body)
            leftInfo rfl hSuccess
  | sort leftLevel =>
      cases right with
      | lam name domain body binderInfo =>
          exact etaRight
            (PsKernelExpr.sort leftLevel)
            name domain body binderInfo rfl hSuccess
      | sort rightLevel =>
          cases hLevel :
              psKernelLevelEquivalent
                leftLevel
                rightLevel with
          | false =>
              simp [
                psKernelDefEqFullShapeWith,
                hLevel
              ] at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              exact ⟨hConfig, trivial⟩
          | true =>
              simp [
                psKernelDefEqFullShapeWith,
                hLevel
              ] at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              exact
                ⟨
                  hConfig,
                  PsKernelDefEqJudgment.sort
                    leftLevel
                    rightLevel
                    hLevel
                ⟩
      | _ =>
          simp [psKernelDefEqFullShapeWith] at hSuccess
          rcases hSuccess with ⟨rfl, rfl⟩
          exact ⟨hConfig, trivial⟩
  | lit leftLiteral =>
      cases right with
      | lam name domain body binderInfo =>
          exact etaRight
            (PsKernelExpr.lit leftLiteral)
            name domain body binderInfo rfl hSuccess
      | lit rightLiteral =>
          cases hLiteral :
              psKernelLiteralEq
                leftLiteral
                rightLiteral with
          | false =>
              simp [
                psKernelDefEqFullShapeWith,
                hLiteral
              ] at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              exact ⟨hConfig, trivial⟩
          | true =>
              simp [
                psKernelDefEqFullShapeWith,
                hLiteral
              ] at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              exact
                ⟨
                  hConfig,
                  PsKernelDefEqJudgment.literal
                    leftLiteral
                    rightLiteral
                    hLiteral
                ⟩
      | _ =>
          simp [psKernelDefEqFullShapeWith] at hSuccess
          rcases hSuccess with ⟨rfl, rfl⟩
          exact ⟨hConfig, trivial⟩
  | app leftFn leftArg =>
      cases right with
      | lam name domain body binderInfo =>
          exact etaRight
            (PsKernelExpr.app leftFn leftArg)
            name domain body binderInfo rfl hSuccess
      | app rightFn rightArg =>
          cases hRun :
              psKernelDefEqApp
                defeq
                context
                state
                (PsKernelExpr.app leftFn leftArg)
                (PsKernelExpr.app rightFn rightArg) with
          | error error =>
              simp [
                psKernelDefEqFullShapeWith,
                hRun
              ] at hSuccess
          | ok run =>
              rcases run with ⟨value, runState⟩
              have hSemantic :=
                psKernelDefEqApp_configuration_sound
                  defeq
                  hDefEq
                  context
                  state
                  runState
                  (PsKernelExpr.app leftFn leftArg)
                  (PsKernelExpr.app rightFn rightArg)
                  value
                  hConfig
                  hRun
              cases value with
              | false =>
                  simp [
                    psKernelDefEqFullShapeWith,
                    hRun
                  ] at hSuccess
                  rcases hSuccess with ⟨rfl, rfl⟩
                  exact ⟨hSemantic.1, trivial⟩
              | true =>
                  simp [
                    psKernelDefEqFullShapeWith,
                    hRun
                  ] at hSuccess
                  rcases hSuccess with ⟨rfl, rfl⟩
                  exact ⟨hSemantic.1, hSemantic.2 rfl⟩
      | _ =>
          simp [psKernelDefEqFullShapeWith] at hSuccess
          rcases hSuccess with ⟨rfl, rfl⟩
          exact ⟨hConfig, trivial⟩
  | forallE leftName leftDomain leftBody leftInfo =>
      cases right with
      | lam name domain body binderInfo =>
          exact etaRight
            (PsKernelExpr.forallE
              leftName leftDomain leftBody leftInfo)
            name domain body binderInfo rfl hSuccess
      | forallE rightName rightDomain rightBody rightInfo =>
          cases hRun :
              psKernelDefEqForallSpine
                defeq
                context
                state
                (PsKernelExpr.forallE
                  leftName leftDomain leftBody leftInfo)
                (PsKernelExpr.forallE
                  rightName rightDomain rightBody rightInfo) with
          | error error =>
              simp [
                psKernelDefEqFullShapeWith,
                hRun
              ] at hSuccess
          | ok run =>
              rcases run with ⟨value, runState⟩
              have hSemantic :=
                psKernelDefEqForallSpine_configuration_sound
                  defeq
                  hDefEq
                  hString
                  context
                  state
                  runState
                  (PsKernelExpr.forallE
                    leftName leftDomain leftBody leftInfo)
                  (PsKernelExpr.forallE
                    rightName rightDomain rightBody rightInfo)
                  value
                  hConfig
                  hRun
              cases value with
              | false =>
                  simp [
                    psKernelDefEqFullShapeWith,
                    hRun
                  ] at hSuccess
                  rcases hSuccess with ⟨rfl, rfl⟩
                  exact ⟨hSemantic.1, trivial⟩
              | true =>
                  simp [
                    psKernelDefEqFullShapeWith,
                    hRun
                  ] at hSuccess
                  rcases hSuccess with ⟨rfl, rfl⟩
                  exact ⟨hSemantic.1, hSemantic.2 rfl⟩
      | _ =>
          simp [psKernelDefEqFullShapeWith] at hSuccess
          rcases hSuccess with ⟨rfl, rfl⟩
          exact ⟨hConfig, trivial⟩
  | bvar index =>
      cases right with
      | lam name domain body binderInfo =>
          exact etaRight
            (PsKernelExpr.bvar index)
            name domain body binderInfo rfl hSuccess
      | _ =>
          simp [psKernelDefEqFullShapeWith] at hSuccess
          rcases hSuccess with ⟨rfl, rfl⟩
          exact ⟨hConfig, trivial⟩
  | fvar fvarName =>
      cases right with
      | lam name domain body binderInfo =>
          exact etaRight
            (PsKernelExpr.fvar fvarName)
            name domain body binderInfo rfl hSuccess
      | _ =>
          simp [psKernelDefEqFullShapeWith] at hSuccess
          rcases hSuccess with ⟨rfl, rfl⟩
          exact ⟨hConfig, trivial⟩
  | mvar mvarName =>
      cases right with
      | lam name domain body binderInfo =>
          exact etaRight
            (PsKernelExpr.mvar mvarName)
            name domain body binderInfo rfl hSuccess
      | _ =>
          simp [psKernelDefEqFullShapeWith] at hSuccess
          rcases hSuccess with ⟨rfl, rfl⟩
          exact ⟨hConfig, trivial⟩
  | const constName levels =>
      cases right with
      | lam name domain body binderInfo =>
          exact etaRight
            (PsKernelExpr.const constName levels)
            name domain body binderInfo rfl hSuccess
      | _ =>
          simp [psKernelDefEqFullShapeWith] at hSuccess
          rcases hSuccess with ⟨rfl, rfl⟩
          exact ⟨hConfig, trivial⟩
  | letE letName type value body nondep =>
      cases right with
      | lam name domain etaBody binderInfo =>
          exact etaRight
            (PsKernelExpr.letE letName type value body nondep)
            name domain etaBody binderInfo rfl hSuccess
      | _ =>
          simp [psKernelDefEqFullShapeWith] at hSuccess
          rcases hSuccess with ⟨rfl, rfl⟩
          exact ⟨hConfig, trivial⟩
  | mdata metadata body =>
      cases right with
      | lam name domain etaBody binderInfo =>
          exact etaRight
            (PsKernelExpr.mdata metadata body)
            name domain etaBody binderInfo rfl hSuccess
      | _ =>
          simp [psKernelDefEqFullShapeWith] at hSuccess
          rcases hSuccess with ⟨rfl, rfl⟩
          exact ⟨hConfig, trivial⟩
  | proj typeName index body =>
      cases right with
      | lam name domain etaBody binderInfo =>
          exact etaRight
            (PsKernelExpr.proj typeName index body)
            name domain etaBody binderInfo rfl hSuccess
      | _ =>
          simp [psKernelDefEqFullShapeWith] at hSuccess
          rcases hSuccess with ⟨rfl, rfl⟩
          exact ⟨hConfig, trivial⟩

/-
Configuration-aware composition for the final phase after both sides have
reached the full-shape comparison point.

The explicit reduction closures from the original pair to the full-shape pair
are essential: positive final-rule evidence is lifted with `reduceCompare`,
not with general DefEq transitivity.  This is also the evidence required to
soundly publish the original pair in the success cache.
-/
theorem psKernelIsDefEqAfterFullShape_configuration_sound
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
    (state nextState : PsKernelCheckerState)
    (originalLeft originalRight left right : PsKernelExpr)
    (value : Bool)
    (hConfig : PsKernelCheckerConfigurationSound context state)
    (hLeft :
      PsKernelReductionClosure
        context.environment
        context.localContext
        originalLeft
        left)
    (hRight :
      PsKernelReductionClosure
        context.environment
        context.localContext
        originalRight
        right)
    (hSuccess :
      psKernelIsDefEqAfterFullShape
          defeq inferType whnf
          context state
          originalLeft originalRight
          left right =
        Except.ok (Prod.mk value nextState)) :
    PsKernelCheckerConfigurationSound context nextState ∧
      (value = true ->
        PsKernelDefEqJudgment
          context.environment
          context.localContext
          originalLeft
          originalRight) := by
  have liftSemantic :
      PsKernelDefEqJudgment
          context.environment
          context.localContext
          left
          right ->
        PsKernelDefEqJudgment
          context.environment
          context.localContext
          originalLeft
          originalRight := by
    intro hCore
    exact
      PsKernelDefEqJudgment.reduceCompare
        originalLeft
        originalRight
        left
        right
        hLeft
        hRight
        hCore
  simp only [psKernelIsDefEqAfterFullShape] at hSuccess
  cases hEta :
      psKernelDefEqEtaStructWith
        defeq inferType
        context state left right with
  | error error =>
      simp only [hEta] at hSuccess
      simp at hSuccess
  | ok etaRun =>
      simp only [hEta] at hSuccess
      rcases etaRun with ⟨etaValue, etaState⟩
      have hEtaSound :=
        psKernelDefEqEtaStructWith_configuration_sound
          defeq
          inferType
          hDefEq
          hInfer
          context
          state
          etaState
          left
          right
          etaValue
          hConfig
          hEta
      by_cases hEtaTrue : etaValue = true
      · rw [if_pos hEtaTrue] at hSuccess
        have hOriginal :=
          liftSemantic (hEtaSound.2 hEtaTrue)
        exact
          psKernelDefEqFinish_result_sound_ok
            context
            etaState
            nextState
            originalLeft
            originalRight
            true
            value
            hEtaSound.1
            (fun _ => hOriginal)
            (by simpa using hSuccess)
      · rw [if_neg hEtaTrue] at hSuccess
        cases hString :
            psKernelDefEqStringLitExpansionWith
              defeq
              whnf
              context
              etaState
              left
              right with
        | error error =>
            simp only [hString] at hSuccess
            simp at hSuccess
        | ok stringRun =>
            simp only [hString] at hSuccess
            rcases stringRun with ⟨stringAnswer, stringState⟩
            have hStringSound :=
              psKernelDefEqStringLitExpansionWith_optional_configuration_sound
                defeq
                whnf
                hDefEq
                hWhnf
                context
                etaState
                stringState
                left
                right
                stringAnswer
                hEtaSound.1
                hString
            cases stringAnswer with
            | some stringValue =>
                cases stringValue with
                | false =>
                    exact
                      psKernelDefEqFinish_result_sound_ok
                        context
                        stringState
                        nextState
                        originalLeft
                        originalRight
                        false
                        value
                        hStringSound.1
                        (by
                          intro hFalse
                          simp at hFalse)
                        (by simpa using hSuccess)
                | true =>
                    have hOriginal :=
                      liftSemantic hStringSound.2
                    exact
                      psKernelDefEqFinish_result_sound_ok
                        context
                        stringState
                        nextState
                        originalLeft
                        originalRight
                        true
                        value
                        hStringSound.1
                        (fun _ => hOriginal)
                        (by simpa using hSuccess)
            | none =>
                cases hUnit :
                    psKernelDefEqUnitLikeWith
                      defeq
                      inferType
                      whnf
                      context
                      stringState
                      left
                      right with
                | error error =>
                    simp only [hUnit] at hSuccess
                    simp at hSuccess
                | ok unitRun =>
                    simp only [hUnit] at hSuccess
                    rcases unitRun with ⟨unitValue, unitState⟩
                    have hUnitSound :=
                      psKernelDefEqUnitLikeWith_configuration_sound
                        defeq
                        inferType
                        whnf
                        hDefEq
                        hInfer
                        hWhnf
                        context
                        stringState
                        unitState
                        left
                        right
                        unitValue
                        hStringSound.1
                        hUnit
                    exact
                      psKernelDefEqFinish_result_sound_ok
                        context
                        unitState
                        nextState
                        originalLeft
                        originalRight
                        unitValue
                        value
                        hUnitSound.1
                        (fun hValue =>
                          liftSemantic (hUnitSound.2 hValue))
                        (by simpa using hSuccess)

