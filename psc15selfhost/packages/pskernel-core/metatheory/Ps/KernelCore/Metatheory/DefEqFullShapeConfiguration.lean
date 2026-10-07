import Ps.KernelCore.Metatheory.DefEqBinderConfiguration
import Ps.KernelCore.Metatheory.DefEqEtaConfiguration
import Ps.KernelCore.Metatheory.DefEqApplicationConfiguration

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
