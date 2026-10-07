import Ps.KernelCore.Checker.DefEq.Shortcuts
import Ps.KernelCore.Metatheory.CheckerContracts

theorem psKernelDefEqReflectionWith_disabled_for_fvar
    (whnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (left right : PsKernelExpr)
    (hFVar : psKernelExprHasFVar left = true)
    (hEager : context.eagerReduce = false) :
    psKernelDefEqReflectionWith
        whnf context state left right =
      Except.ok (Prod.mk Option.none state) := by
  simp [psKernelDefEqReflectionWith, hFVar, hEager]


theorem psKernelDefEqLambdaEtaLeftWith_configuration_refines
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
              simp [
                psKernelDefEqLambdaEtaLeftWith,
                hInferRun,
                hWhnfRun
              ] at hSuccess
          | fvar name =>
              simp [
                psKernelDefEqLambdaEtaLeftWith,
                hInferRun,
                hWhnfRun
              ] at hSuccess
          | mvar name =>
              simp [
                psKernelDefEqLambdaEtaLeftWith,
                hInferRun,
                hWhnfRun
              ] at hSuccess
          | sort level =>
              simp [
                psKernelDefEqLambdaEtaLeftWith,
                hInferRun,
                hWhnfRun
              ] at hSuccess
          | const name levels =>
              simp [
                psKernelDefEqLambdaEtaLeftWith,
                hInferRun,
                hWhnfRun
              ] at hSuccess
          | app fn arg =>
              simp [
                psKernelDefEqLambdaEtaLeftWith,
                hInferRun,
                hWhnfRun
              ] at hSuccess
          | lam name type body binderInfo =>
              simp [
                psKernelDefEqLambdaEtaLeftWith,
                hInferRun,
                hWhnfRun
              ] at hSuccess
          | letE name type value body nondep =>
              simp [
                psKernelDefEqLambdaEtaLeftWith,
                hInferRun,
                hWhnfRun
              ] at hSuccess
          | lit literal =>
              simp [
                psKernelDefEqLambdaEtaLeftWith,
                hInferRun,
                hWhnfRun
              ] at hSuccess
          | mdata metadata body =>
              simp [
                psKernelDefEqLambdaEtaLeftWith,
                hInferRun,
                hWhnfRun
              ] at hSuccess
          | proj typeName index body =>
              simp [
                psKernelDefEqLambdaEtaLeftWith,
                hInferRun,
                hWhnfRun
              ] at hSuccess


theorem psKernelDefEqLambdaEtaRightWith_configuration_refines
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
              simp [
                psKernelDefEqLambdaEtaRightWith,
                hInferRun,
                hWhnfRun
              ] at hSuccess
          | fvar name =>
              simp [
                psKernelDefEqLambdaEtaRightWith,
                hInferRun,
                hWhnfRun
              ] at hSuccess
          | mvar name =>
              simp [
                psKernelDefEqLambdaEtaRightWith,
                hInferRun,
                hWhnfRun
              ] at hSuccess
          | sort level =>
              simp [
                psKernelDefEqLambdaEtaRightWith,
                hInferRun,
                hWhnfRun
              ] at hSuccess
          | const name levels =>
              simp [
                psKernelDefEqLambdaEtaRightWith,
                hInferRun,
                hWhnfRun
              ] at hSuccess
          | app fn arg =>
              simp [
                psKernelDefEqLambdaEtaRightWith,
                hInferRun,
                hWhnfRun
              ] at hSuccess
          | lam name type body binderInfo =>
              simp [
                psKernelDefEqLambdaEtaRightWith,
                hInferRun,
                hWhnfRun
              ] at hSuccess
          | letE name type value body nondep =>
              simp [
                psKernelDefEqLambdaEtaRightWith,
                hInferRun,
                hWhnfRun
              ] at hSuccess
          | lit literal =>
              simp [
                psKernelDefEqLambdaEtaRightWith,
                hInferRun,
                hWhnfRun
              ] at hSuccess
          | mdata metadata body =>
              simp [
                psKernelDefEqLambdaEtaRightWith,
                hInferRun,
                hWhnfRun
              ] at hSuccess
          | proj typeName index body =>
              simp [
                psKernelDefEqLambdaEtaRightWith,
                hInferRun,
                hWhnfRun
              ] at hSuccess
