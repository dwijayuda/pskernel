import Ps.KernelCore.Checker.DefEq.FullShape
import Ps.KernelCore.Metatheory.CheckerContracts

/-
Lean-compatible symmetric function-eta refinement.

Lean 4.34 reaches function eta after the relevant WHNF/full-shape phase in
both orientations.  The production checker must therefore route

  lambda =?= non-lambda

through the left eta helper and

  non-lambda =?= lambda

through the right eta helper.  This module records that behavior independently
of the concrete Arena examples and connects successful eta decisions to the
algorithmic DefEq judgment.
-/

def PsKernelExprIsLambdaView : PsKernelExpr -> Bool
  | PsKernelExpr.lam _ _ _ _ => true
  | _ => false


theorem psKernelDefEqLambdaEtaLeftWith_configuration_sound
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
    (lambdaValue other : PsKernelExpr)
    (hConfig : PsKernelCheckerConfigurationSound context state)
    (hSuccess :
      psKernelDefEqLambdaEtaLeftWith
          defeq inferType whnf
          context state lambdaValue other =
        Except.ok
          (Prod.mk (Option.some true) nextState)) :
    PsKernelCheckerConfigurationSound context nextState ∧
      PsKernelDefEqJudgment
        context.environment
        context.localContext
        lambdaValue
        other := by
  cases hInferRun :
      inferType context state other with
  | error error =>
      simp [
        psKernelDefEqLambdaEtaLeftWith,
        hInferRun
      ] at hSuccess
  | ok typeRun =>
      rcases typeRun with
        ⟨otherType, typeState⟩
      have hTypeConfig :=
        hInfer
          context state typeState
          other otherType
          hConfig hInferRun
      cases hWhnfRun :
          whnf context typeState otherType with
      | error error =>
          simp [
            psKernelDefEqLambdaEtaLeftWith,
            hInferRun,
            hWhnfRun
          ] at hSuccess
      | ok reducedRun =>
          rcases reducedRun with
            ⟨reducedType, reducedState⟩
          have hReduced :=
            hWhnf
              context typeState reducedState
              otherType reducedType
              hTypeConfig hWhnfRun
          cases reducedType with
          | forallE name domain body binderInfo =>
              let eta :=
                PsKernelExpr.lam
                  name
                  domain
                  (PsKernelExpr.app
                    other
                    (PsKernelExpr.bvar 0))
                  binderInfo
              cases hEqRun :
                  defeq
                    context
                    reducedState
                    lambdaValue
                    eta with
              | error error =>
                  simp [
                    psKernelDefEqLambdaEtaLeftWith,
                    hInferRun,
                    hWhnfRun,
                    eta,
                    hEqRun
                  ] at hSuccess
              | ok eqRun =>
                  rcases eqRun with
                    ⟨eqValue, eqState⟩
                  have hEqSemantic :=
                    hDefEq
                      context reducedState eqState
                      lambdaValue eta eqValue
                      hReduced.2 hEqRun
                  cases eqValue with
                  | false =>
                      simp [
                        psKernelDefEqLambdaEtaLeftWith,
                        hInferRun,
                        hWhnfRun,
                        eta,
                        hEqRun
                      ] at hSuccess
                  | true =>
                      simp [
                        psKernelDefEqLambdaEtaLeftWith,
                        hInferRun,
                        hWhnfRun,
                        eta,
                        hEqRun
                      ] at hSuccess
                      rcases hSuccess with ⟨rfl, rfl⟩
                      exact
                        ⟨
                          hEqSemantic.1,
                          PsKernelDefEqJudgment.functionEtaLeft
                            lambdaValue
                            other
                            name
                            domain
                            body
                            binderInfo
                            (hEqSemantic.2 rfl)
                        ⟩
          | bvar index =>
              simp [psKernelDefEqLambdaEtaLeftWith, hInferRun, hWhnfRun] at hSuccess
          | fvar name =>
              simp [psKernelDefEqLambdaEtaLeftWith, hInferRun, hWhnfRun] at hSuccess
          | mvar name =>
              simp [psKernelDefEqLambdaEtaLeftWith, hInferRun, hWhnfRun] at hSuccess
          | sort level =>
              simp [psKernelDefEqLambdaEtaLeftWith, hInferRun, hWhnfRun] at hSuccess
          | const name levels =>
              simp [psKernelDefEqLambdaEtaLeftWith, hInferRun, hWhnfRun] at hSuccess
          | app fn arg =>
              simp [psKernelDefEqLambdaEtaLeftWith, hInferRun, hWhnfRun] at hSuccess
          | lam name type body binderInfo =>
              simp [psKernelDefEqLambdaEtaLeftWith, hInferRun, hWhnfRun] at hSuccess
          | letE name type value body nondep =>
              simp [psKernelDefEqLambdaEtaLeftWith, hInferRun, hWhnfRun] at hSuccess
          | lit literal =>
              simp [psKernelDefEqLambdaEtaLeftWith, hInferRun, hWhnfRun] at hSuccess
          | mdata metadata body =>
              simp [psKernelDefEqLambdaEtaLeftWith, hInferRun, hWhnfRun] at hSuccess
          | proj typeName index body =>
              simp [psKernelDefEqLambdaEtaLeftWith, hInferRun, hWhnfRun] at hSuccess


theorem psKernelDefEqLambdaEtaRightWith_configuration_sound
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
    (other lambdaValue : PsKernelExpr)
    (hConfig : PsKernelCheckerConfigurationSound context state)
    (hSuccess :
      psKernelDefEqLambdaEtaRightWith
          defeq inferType whnf
          context state other lambdaValue =
        Except.ok
          (Prod.mk (Option.some true) nextState)) :
    PsKernelCheckerConfigurationSound context nextState ∧
      PsKernelDefEqJudgment
        context.environment
        context.localContext
        other
        lambdaValue := by
  cases hInferRun :
      inferType context state other with
  | error error =>
      simp [
        psKernelDefEqLambdaEtaRightWith,
        hInferRun
      ] at hSuccess
  | ok typeRun =>
      rcases typeRun with
        ⟨otherType, typeState⟩
      have hTypeConfig :=
        hInfer
          context state typeState
          other otherType
          hConfig hInferRun
      cases hWhnfRun :
          whnf context typeState otherType with
      | error error =>
          simp [
            psKernelDefEqLambdaEtaRightWith,
            hInferRun,
            hWhnfRun
          ] at hSuccess
      | ok reducedRun =>
          rcases reducedRun with
            ⟨reducedType, reducedState⟩
          have hReduced :=
            hWhnf
              context typeState reducedState
              otherType reducedType
              hTypeConfig hWhnfRun
          cases reducedType with
          | forallE name domain body binderInfo =>
              let eta :=
                PsKernelExpr.lam
                  name
                  domain
                  (PsKernelExpr.app
                    other
                    (PsKernelExpr.bvar 0))
                  binderInfo
              cases hEqRun :
                  defeq
                    context
                    reducedState
                    eta
                    lambdaValue with
              | error error =>
                  simp [
                    psKernelDefEqLambdaEtaRightWith,
                    hInferRun,
                    hWhnfRun,
                    eta,
                    hEqRun
                  ] at hSuccess
              | ok eqRun =>
                  rcases eqRun with
                    ⟨eqValue, eqState⟩
                  have hEqSemantic :=
                    hDefEq
                      context reducedState eqState
                      eta lambdaValue eqValue
                      hReduced.2 hEqRun
                  cases eqValue with
                  | false =>
                      simp [
                        psKernelDefEqLambdaEtaRightWith,
                        hInferRun,
                        hWhnfRun,
                        eta,
                        hEqRun
                      ] at hSuccess
                  | true =>
                      simp [
                        psKernelDefEqLambdaEtaRightWith,
                        hInferRun,
                        hWhnfRun,
                        eta,
                        hEqRun
                      ] at hSuccess
                      rcases hSuccess with ⟨rfl, rfl⟩
                      exact
                        ⟨
                          hEqSemantic.1,
                          PsKernelDefEqJudgment.functionEtaRight
                            other
                            lambdaValue
                            name
                            domain
                            body
                            binderInfo
                            (hEqSemantic.2 rfl)
                        ⟩
          | bvar index =>
              simp [psKernelDefEqLambdaEtaRightWith, hInferRun, hWhnfRun] at hSuccess
          | fvar name =>
              simp [psKernelDefEqLambdaEtaRightWith, hInferRun, hWhnfRun] at hSuccess
          | mvar name =>
              simp [psKernelDefEqLambdaEtaRightWith, hInferRun, hWhnfRun] at hSuccess
          | sort level =>
              simp [psKernelDefEqLambdaEtaRightWith, hInferRun, hWhnfRun] at hSuccess
          | const name levels =>
              simp [psKernelDefEqLambdaEtaRightWith, hInferRun, hWhnfRun] at hSuccess
          | app fn arg =>
              simp [psKernelDefEqLambdaEtaRightWith, hInferRun, hWhnfRun] at hSuccess
          | lam name type body binderInfo =>
              simp [psKernelDefEqLambdaEtaRightWith, hInferRun, hWhnfRun] at hSuccess
          | letE name type value body nondep =>
              simp [psKernelDefEqLambdaEtaRightWith, hInferRun, hWhnfRun] at hSuccess
          | lit literal =>
              simp [psKernelDefEqLambdaEtaRightWith, hInferRun, hWhnfRun] at hSuccess
          | mdata metadata body =>
              simp [psKernelDefEqLambdaEtaRightWith, hInferRun, hWhnfRun] at hSuccess
          | proj typeName index body =>
              simp [psKernelDefEqLambdaEtaRightWith, hInferRun, hWhnfRun] at hSuccess


theorem psKernelDefEqFullShape_lambda_nonlambda_uses_eta_left
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
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (name : PsKernelName)
    (domain body other : PsKernelExpr)
    (binderInfo : PsKernelBinderInfo)
    (hOther : PsKernelExprIsLambdaView other = false) :
    psKernelDefEqFullShapeWith
        defeq inferType whnf context state
        (PsKernelExpr.lam name domain body binderInfo)
        other =
      psKernelDefEqLambdaEtaLeftWith
        defeq inferType whnf context state
        (PsKernelExpr.lam name domain body binderInfo)
        other := by
  cases other <;>
    simp [
      PsKernelExprIsLambdaView,
      psKernelDefEqFullShapeWith
    ] at hOther ⊢


theorem psKernelDefEqFullShape_nonlambda_lambda_uses_eta_right
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
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (other : PsKernelExpr)
    (name : PsKernelName)
    (domain body : PsKernelExpr)
    (binderInfo : PsKernelBinderInfo)
    (hOther : PsKernelExprIsLambdaView other = false) :
    psKernelDefEqFullShapeWith
        defeq inferType whnf context state
        other
        (PsKernelExpr.lam name domain body binderInfo) =
      psKernelDefEqLambdaEtaRightWith
        defeq inferType whnf context state
        other
        (PsKernelExpr.lam name domain body binderInfo) := by
  cases other <;>
    simp [
      PsKernelExprIsLambdaView,
      psKernelDefEqFullShapeWith
    ] at hOther ⊢


theorem psKernelDefEqFullShape_lambda_nonlambda_eta_configuration_sound
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
    (name : PsKernelName)
    (domain body other : PsKernelExpr)
    (binderInfo : PsKernelBinderInfo)
    (hOther : PsKernelExprIsLambdaView other = false)
    (hConfig : PsKernelCheckerConfigurationSound context state)
    (hSuccess :
      psKernelDefEqFullShapeWith
          defeq inferType whnf context state
          (PsKernelExpr.lam name domain body binderInfo)
          other =
        Except.ok
          (Prod.mk (Option.some true) nextState)) :
    PsKernelCheckerConfigurationSound context nextState ∧
      PsKernelDefEqJudgment
        context.environment
        context.localContext
        (PsKernelExpr.lam name domain body binderInfo)
        other := by
  rw [
    psKernelDefEqFullShape_lambda_nonlambda_uses_eta_left
      defeq inferType whnf context state
      name domain body other binderInfo hOther
  ] at hSuccess
  exact
    psKernelDefEqLambdaEtaLeftWith_configuration_sound
      defeq inferType whnf
      hDefEq hInfer hWhnf
      context state nextState
      (PsKernelExpr.lam name domain body binderInfo)
      other
      hConfig
      hSuccess


theorem psKernelDefEqFullShape_nonlambda_lambda_eta_configuration_sound
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
    (other : PsKernelExpr)
    (name : PsKernelName)
    (domain body : PsKernelExpr)
    (binderInfo : PsKernelBinderInfo)
    (hOther : PsKernelExprIsLambdaView other = false)
    (hConfig : PsKernelCheckerConfigurationSound context state)
    (hSuccess :
      psKernelDefEqFullShapeWith
          defeq inferType whnf context state
          other
          (PsKernelExpr.lam name domain body binderInfo) =
        Except.ok
          (Prod.mk (Option.some true) nextState)) :
    PsKernelCheckerConfigurationSound context nextState ∧
      PsKernelDefEqJudgment
        context.environment
        context.localContext
        other
        (PsKernelExpr.lam name domain body binderInfo) := by
  rw [
    psKernelDefEqFullShape_nonlambda_lambda_uses_eta_right
      defeq inferType whnf context state
      other name domain body binderInfo hOther
  ] at hSuccess
  exact
    psKernelDefEqLambdaEtaRightWith_configuration_sound
      defeq inferType whnf
      hDefEq hInfer hWhnf
      context state nextState
      other
      (PsKernelExpr.lam name domain body binderInfo)
      hConfig
      hSuccess


theorem psKernelDefEqLambdaEtaLeftWith_configuration_preserves
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
    (lambdaValue other : PsKernelExpr)
    (answer : Option Bool)
    (hConfig : PsKernelCheckerConfigurationSound context state)
    (hSuccess :
      psKernelDefEqLambdaEtaLeftWith
          defeq inferType whnf
          context state lambdaValue other =
        Except.ok (Prod.mk answer nextState)) :
    PsKernelCheckerConfigurationSound context nextState := by
  cases hInferRun :
      inferType context state other with
  | error error =>
      simp [psKernelDefEqLambdaEtaLeftWith, hInferRun] at hSuccess
  | ok typeRun =>
      rcases typeRun with ⟨otherType, typeState⟩
      have hTypeConfig :=
        hInfer
          context state typeState
          other otherType
          hConfig hInferRun
      cases hWhnfRun :
          whnf context typeState otherType with
      | error error =>
          simp [
            psKernelDefEqLambdaEtaLeftWith,
            hInferRun,
            hWhnfRun
          ] at hSuccess
      | ok reducedRun =>
          rcases reducedRun with ⟨reducedType, reducedState⟩
          have hReduced :=
            hWhnf
              context typeState reducedState
              otherType reducedType
              hTypeConfig hWhnfRun
          cases reducedType with
          | forallE name domain body binderInfo =>
              let eta :=
                PsKernelExpr.lam
                  name
                  domain
                  (PsKernelExpr.app
                    other
                    (PsKernelExpr.bvar 0))
                  binderInfo
              cases hEqRun :
                  defeq context reducedState lambdaValue eta with
              | error error =>
                  simp [
                    psKernelDefEqLambdaEtaLeftWith,
                    hInferRun,
                    hWhnfRun,
                    eta,
                    hEqRun
                  ] at hSuccess
              | ok eqRun =>
                  rcases eqRun with ⟨eqValue, eqState⟩
                  have hEqSemantic :=
                    hDefEq
                      context reducedState eqState
                      lambdaValue eta eqValue
                      hReduced.2 hEqRun
                  cases eqValue <;>
                    simp [
                      psKernelDefEqLambdaEtaLeftWith,
                      hInferRun,
                      hWhnfRun,
                      eta,
                      hEqRun
                    ] at hSuccess <;>
                    rcases hSuccess with ⟨rfl, rfl⟩ <;>
                    exact hEqSemantic.1
          | bvar index =>
              simp [psKernelDefEqLambdaEtaLeftWith, hInferRun, hWhnfRun] at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              exact hReduced.2
          | fvar name =>
              simp [psKernelDefEqLambdaEtaLeftWith, hInferRun, hWhnfRun] at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              exact hReduced.2
          | mvar name =>
              simp [psKernelDefEqLambdaEtaLeftWith, hInferRun, hWhnfRun] at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              exact hReduced.2
          | sort level =>
              simp [psKernelDefEqLambdaEtaLeftWith, hInferRun, hWhnfRun] at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              exact hReduced.2
          | const name levels =>
              simp [psKernelDefEqLambdaEtaLeftWith, hInferRun, hWhnfRun] at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              exact hReduced.2
          | app fn arg =>
              simp [psKernelDefEqLambdaEtaLeftWith, hInferRun, hWhnfRun] at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              exact hReduced.2
          | lam name type body binderInfo =>
              simp [psKernelDefEqLambdaEtaLeftWith, hInferRun, hWhnfRun] at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              exact hReduced.2
          | letE name type value body nondep =>
              simp [psKernelDefEqLambdaEtaLeftWith, hInferRun, hWhnfRun] at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              exact hReduced.2
          | lit literal =>
              simp [psKernelDefEqLambdaEtaLeftWith, hInferRun, hWhnfRun] at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              exact hReduced.2
          | mdata metadata body =>
              simp [psKernelDefEqLambdaEtaLeftWith, hInferRun, hWhnfRun] at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              exact hReduced.2
          | proj typeName index body =>
              simp [psKernelDefEqLambdaEtaLeftWith, hInferRun, hWhnfRun] at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              exact hReduced.2


theorem psKernelDefEqLambdaEtaRightWith_configuration_preserves
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
    (other lambdaValue : PsKernelExpr)
    (answer : Option Bool)
    (hConfig : PsKernelCheckerConfigurationSound context state)
    (hSuccess :
      psKernelDefEqLambdaEtaRightWith
          defeq inferType whnf
          context state other lambdaValue =
        Except.ok (Prod.mk answer nextState)) :
    PsKernelCheckerConfigurationSound context nextState := by
  cases hInferRun :
      inferType context state other with
  | error error =>
      simp [psKernelDefEqLambdaEtaRightWith, hInferRun] at hSuccess
  | ok typeRun =>
      rcases typeRun with ⟨otherType, typeState⟩
      have hTypeConfig :=
        hInfer
          context state typeState
          other otherType
          hConfig hInferRun
      cases hWhnfRun :
          whnf context typeState otherType with
      | error error =>
          simp [
            psKernelDefEqLambdaEtaRightWith,
            hInferRun,
            hWhnfRun
          ] at hSuccess
      | ok reducedRun =>
          rcases reducedRun with ⟨reducedType, reducedState⟩
          have hReduced :=
            hWhnf
              context typeState reducedState
              otherType reducedType
              hTypeConfig hWhnfRun
          cases reducedType with
          | forallE name domain body binderInfo =>
              let eta :=
                PsKernelExpr.lam
                  name
                  domain
                  (PsKernelExpr.app
                    other
                    (PsKernelExpr.bvar 0))
                  binderInfo
              cases hEqRun :
                  defeq context reducedState eta lambdaValue with
              | error error =>
                  simp [
                    psKernelDefEqLambdaEtaRightWith,
                    hInferRun,
                    hWhnfRun,
                    eta,
                    hEqRun
                  ] at hSuccess
              | ok eqRun =>
                  rcases eqRun with ⟨eqValue, eqState⟩
                  have hEqSemantic :=
                    hDefEq
                      context reducedState eqState
                      eta lambdaValue eqValue
                      hReduced.2 hEqRun
                  cases eqValue <;>
                    simp [
                      psKernelDefEqLambdaEtaRightWith,
                      hInferRun,
                      hWhnfRun,
                      eta,
                      hEqRun
                    ] at hSuccess <;>
                    rcases hSuccess with ⟨rfl, rfl⟩ <;>
                    exact hEqSemantic.1
          | bvar index =>
              simp [psKernelDefEqLambdaEtaRightWith, hInferRun, hWhnfRun] at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              exact hReduced.2
          | fvar name =>
              simp [psKernelDefEqLambdaEtaRightWith, hInferRun, hWhnfRun] at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              exact hReduced.2
          | mvar name =>
              simp [psKernelDefEqLambdaEtaRightWith, hInferRun, hWhnfRun] at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              exact hReduced.2
          | sort level =>
              simp [psKernelDefEqLambdaEtaRightWith, hInferRun, hWhnfRun] at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              exact hReduced.2
          | const name levels =>
              simp [psKernelDefEqLambdaEtaRightWith, hInferRun, hWhnfRun] at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              exact hReduced.2
          | app fn arg =>
              simp [psKernelDefEqLambdaEtaRightWith, hInferRun, hWhnfRun] at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              exact hReduced.2
          | lam name type body binderInfo =>
              simp [psKernelDefEqLambdaEtaRightWith, hInferRun, hWhnfRun] at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              exact hReduced.2
          | letE name type value body nondep =>
              simp [psKernelDefEqLambdaEtaRightWith, hInferRun, hWhnfRun] at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              exact hReduced.2
          | lit literal =>
              simp [psKernelDefEqLambdaEtaRightWith, hInferRun, hWhnfRun] at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              exact hReduced.2
          | mdata metadata body =>
              simp [psKernelDefEqLambdaEtaRightWith, hInferRun, hWhnfRun] at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              exact hReduced.2
          | proj typeName index body =>
              simp [psKernelDefEqLambdaEtaRightWith, hInferRun, hWhnfRun] at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              exact hReduced.2


theorem psKernelDefEqLambdaEtaLeftWith_optional_configuration_sound
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
    (lambdaValue other : PsKernelExpr)
    (answer : Option Bool)
    (hConfig : PsKernelCheckerConfigurationSound context state)
    (hSuccess :
      psKernelDefEqLambdaEtaLeftWith
          defeq inferType whnf
          context state lambdaValue other =
        Except.ok (Prod.mk answer nextState)) :
    PsKernelOptionalDefEqPostcondition
      context nextState lambdaValue other answer := by
  have hPreserve :=
    psKernelDefEqLambdaEtaLeftWith_configuration_preserves
      defeq inferType whnf
      hDefEq hInfer hWhnf
      context state nextState
      lambdaValue other answer
      hConfig hSuccess
  refine ⟨hPreserve, ?_⟩
  cases answer with
  | none =>
      trivial
  | some value =>
      cases value with
      | false =>
          trivial
      | true =>
          exact
            (psKernelDefEqLambdaEtaLeftWith_configuration_sound
              defeq inferType whnf
              hDefEq hInfer hWhnf
              context state nextState
              lambdaValue other
              hConfig hSuccess).2


theorem psKernelDefEqLambdaEtaRightWith_optional_configuration_sound
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
    (other lambdaValue : PsKernelExpr)
    (answer : Option Bool)
    (hConfig : PsKernelCheckerConfigurationSound context state)
    (hSuccess :
      psKernelDefEqLambdaEtaRightWith
          defeq inferType whnf
          context state other lambdaValue =
        Except.ok (Prod.mk answer nextState)) :
    PsKernelOptionalDefEqPostcondition
      context nextState other lambdaValue answer := by
  have hPreserve :=
    psKernelDefEqLambdaEtaRightWith_configuration_preserves
      defeq inferType whnf
      hDefEq hInfer hWhnf
      context state nextState
      other lambdaValue answer
      hConfig hSuccess
  refine ⟨hPreserve, ?_⟩
  cases answer with
  | none =>
      trivial
  | some value =>
      cases value with
      | false =>
          trivial
      | true =>
          exact
            (psKernelDefEqLambdaEtaRightWith_configuration_sound
              defeq inferType whnf
              hDefEq hInfer hWhnf
              context state nextState
              other lambdaValue
              hConfig hSuccess).2
