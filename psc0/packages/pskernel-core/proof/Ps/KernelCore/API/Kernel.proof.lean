import Ps.KernelCore.API.Kernel
import Ps.KernelCore.Metatheory.Judgments

/-!
KernelContract-v1 wrapper proofs.

These establish fail-closed orchestration at the public API boundary. They do
not yet prove the semantic correctness of inference, reduction, defeq or
admission; those deeper proofs live under their matching source modules.
-/

theorem psKernelEnvironmentOutcome_ok
    (environment : PsKernelEnvironment) :
    psKernelV1EnvironmentOutcome (Except.ok environment) =
      Except.ok environment := by
  rfl

theorem psKernelEnvironmentOutcome_error
    (message : String) :
    psKernelV1EnvironmentOutcome (Except.error message) =
      Except.error (psKernelErrorFromMessage message) := by
  rfl

theorem psKernelDispatch_unsupported_declines
    (session : PsKernelKernelSession)
    (feature : String) :
    psKernelV1DispatchDeclaration
        session
        (PsKernelDeclarationRequest.unsupported feature) =
      Except.error (PsKernelError.declinedUnsupported feature) := by
  rfl

theorem psKernelCheckedEnvironment_preflight_failure
    (session : PsKernelKernelSession)
    (request : PsKernelDeclarationRequest)
    (error : PsKernelError)
    (h :
      psKernelKernelSessionPreflight session =
        Except.error error) :
    psKernelV1CheckedEnvironment session request =
      Except.error error := by
  simp [psKernelV1CheckedEnvironment, h]

theorem psKernelCheckedEnvironment_dispatch_failure
    (session : PsKernelKernelSession)
    (request : PsKernelDeclarationRequest)
    (error : PsKernelError)
    (hPreflight :
      psKernelKernelSessionPreflight session =
        Except.ok Unit.unit)
    (hDispatch :
      psKernelV1DispatchDeclaration session request =
        Except.error error) :
    psKernelV1CheckedEnvironment session request =
      Except.error error := by
  simp [psKernelV1CheckedEnvironment, hPreflight, hDispatch]

theorem psKernelCheckDeclaration_failure
    (session : PsKernelKernelSession)
    (request : PsKernelDeclarationRequest)
    (error : PsKernelError)
    (h :
      psKernelV1CheckedEnvironment session request =
        Except.error error) :
    psKernelV1CheckDeclaration session request =
      Except.error error := by
  simp [psKernelV1CheckDeclaration, h]

theorem psKernelAdmitDeclaration_failure
    (session : PsKernelKernelSession)
    (request : PsKernelDeclarationRequest)
    (error : PsKernelError)
    (h :
      psKernelV1CheckedEnvironment session request =
        Except.error error) :
    psKernelV1AdmitDeclaration session request =
      Except.error error := by
  simp [psKernelV1AdmitDeclaration, h]

theorem psKernelAdmitChecked_rechecks_request
    (session : PsKernelKernelSession)
    (checked : PsKernelCheckedDeclaration) :
    psKernelV1AdmitChecked session checked =
      psKernelV1AdmitDeclaration session checked.request := by
  rfl

theorem psKernelCheckExpression_preflight_failure
    (session : PsKernelKernelSession)
    (levelParams : List PsKernelName)
    (safety : PsKernelDefinitionSafety)
    (expression : PsKernelExpr)
    (error : PsKernelError)
    (h :
      psKernelKernelSessionPreflight session =
        Except.error error) :
    psKernelV1CheckExpression
        session levelParams safety expression =
      Except.error error := by
  simp [psKernelV1CheckExpression, h]

theorem psKernelWhnf_requires_successful_check
    (session : PsKernelKernelSession)
    (levelParams : List PsKernelName)
    (safety : PsKernelDefinitionSafety)
    (expression : PsKernelExpr)
    (error : PsKernelError)
    (h :
      psKernelV1CheckExpression
          session levelParams safety expression =
        Except.error error) :
    psKernelV1Whnf session levelParams safety expression =
      Except.error error := by
  simp [psKernelV1Whnf, h]

theorem psKernelDefEq_requires_left_check
    (session : PsKernelKernelSession)
    (levelParams : List PsKernelName)
    (safety : PsKernelDefinitionSafety)
    (left right : PsKernelExpr)
    (error : PsKernelError)
    (h :
      psKernelV1CheckExpression
          session levelParams safety left =
        Except.error error) :
    psKernelV1IsDefEq
        session levelParams safety left right =
      Except.error error := by
  simp [psKernelV1IsDefEq, h]

theorem psKernelDefEq_requires_right_check
    (session : PsKernelKernelSession)
    (levelParams : List PsKernelName)
    (safety : PsKernelDefinitionSafety)
    (left right : PsKernelExpr)
    (leftChecked : PsKernelCheckedExpression)
    (error : PsKernelError)
    (hLeft :
      psKernelV1CheckExpression
          session levelParams safety left =
        Except.ok leftChecked)
    (hRight :
      psKernelV1CheckExpression
          session levelParams safety right =
        Except.error error) :
    psKernelV1IsDefEq
        session levelParams safety left right =
      Except.error error := by
  simp [psKernelV1IsDefEq, hLeft, hRight]


theorem psKernelV1CheckExpression_refines_typing
    (session : PsKernelKernelSession)
    (levelParams : List PsKernelName)
    (safety : PsKernelDefinitionSafety)
    (expression : PsKernelExpr)
    (checked : PsKernelCheckedExpression)
    (hSound :
      PsKernelInferenceSound
        (psKernelCheckerCheck
          session.resources.fuel))
    (hSuccess :
      psKernelV1CheckExpression
          session
          levelParams
          safety
          expression =
        Except.ok checked) :
    PsKernelTypingJudgment
      (psKernelKernelSessionEnvironment session)
      psKernelLocalContextEmpty
      expression
      checked.type := by
  cases hPreflight :
      psKernelKernelSessionPreflight session with
  | error error =>
      simp [
        psKernelV1CheckExpression,
        hPreflight
      ] at hSuccess
  | ok preflight =>
      cases preflight
      let checker :=
        psKernelKernelSessionChecker
          session
          levelParams
          safety
      cases hRun :
          psKernelCheckerCheck
            session.resources.fuel
            checker.context
            checker.state
            expression with
      | error error =>
          simp [
            psKernelV1CheckExpression,
            hPreflight,
            psKernelSessionCheck,
            checker,
            hRun
          ] at hSuccess
      | ok run =>
          cases run with
          | mk inferred nextState =>
              simp [
                psKernelV1CheckExpression,
                hPreflight,
                psKernelSessionCheck,
                checker,
                hRun
              ] at hSuccess
              subst checked
              have hTyping :=
                hSound
                  checker.context
                  checker.state
                  nextState
                  expression
                  inferred
                  hRun
              simpa [
                checker,
                psKernelKernelSessionChecker,
                psKernelMkCheckerSession,
                psKernelCheckerContextEmpty
              ] using hTyping

theorem psKernelV1Whnf_refines_reduction
    (session : PsKernelKernelSession)
    (levelParams : List PsKernelName)
    (safety : PsKernelDefinitionSafety)
    (expression result : PsKernelExpr)
    (hSound :
      PsKernelWhnfSound
        (psKernelCheckerWhnf
          session.resources.fuel))
    (hSuccess :
      psKernelV1Whnf
          session
          levelParams
          safety
          expression =
        Except.ok result) :
    PsKernelReductionClosure
      (psKernelKernelSessionEnvironment session)
      psKernelLocalContextEmpty
      expression
      result := by
  cases hCheck :
      psKernelV1CheckExpression
        session
        levelParams
        safety
        expression with
  | error error =>
      simp [psKernelV1Whnf, hCheck] at hSuccess
  | ok checked =>
      let checker :=
        psKernelKernelSessionChecker
          session
          levelParams
          safety
      cases hRun :
          psKernelCheckerWhnf
            session.resources.fuel
            checker.context
            checker.state
            expression with
      | error error =>
          simp [
            psKernelV1Whnf,
            hCheck,
            psKernelSessionWhnf,
            checker,
            hRun
          ] at hSuccess
      | ok run =>
          cases run with
          | mk reduced nextState =>
              simp [
                psKernelV1Whnf,
                hCheck,
                psKernelSessionWhnf,
                checker,
                hRun
              ] at hSuccess
              subst result
              have hReduction :=
                hSound
                  checker.context
                  checker.state
                  nextState
                  expression
                  reduced
                  hRun
              simpa [
                checker,
                psKernelKernelSessionChecker,
                psKernelMkCheckerSession,
                psKernelCheckerContextEmpty
              ] using hReduction

theorem psKernelV1IsDefEq_true_refines_defeq
    (session : PsKernelKernelSession)
    (levelParams : List PsKernelName)
    (safety : PsKernelDefinitionSafety)
    (left right : PsKernelExpr)
    (hSound :
      PsKernelDefEqSound
        (psKernelIsDefEq
          session.resources.fuel))
    (hSuccess :
      psKernelV1IsDefEq
          session
          levelParams
          safety
          left
          right =
        Except.ok true) :
    PsKernelDefEqJudgment
      (psKernelKernelSessionEnvironment session)
      psKernelLocalContextEmpty
      left
      right := by
  cases hLeft :
      psKernelV1CheckExpression
        session
        levelParams
        safety
        left with
  | error error =>
      simp [psKernelV1IsDefEq, hLeft] at hSuccess
  | ok leftChecked =>
      cases hRight :
          psKernelV1CheckExpression
            session
            levelParams
            safety
            right with
      | error error =>
          simp [
            psKernelV1IsDefEq,
            hLeft,
            hRight
          ] at hSuccess
      | ok rightChecked =>
          let checker :=
            psKernelKernelSessionChecker
              session
              levelParams
              safety
          cases hRun :
              psKernelIsDefEq
                session.resources.fuel
                checker.context
                checker.state
                left
                right with
          | error error =>
              simp [
                psKernelV1IsDefEq,
                hLeft,
                hRight,
                psKernelSessionIsDefEq,
                checker,
                hRun
              ] at hSuccess
          | ok run =>
              cases run with
              | mk value nextState =>
                  cases value with
                  | false =>
                      simp [
                        psKernelV1IsDefEq,
                        hLeft,
                        hRight,
                        psKernelSessionIsDefEq,
                        checker,
                        hRun
                      ] at hSuccess
                  | true =>
                      have hDefEq :=
                        hSound
                          checker.context
                          checker.state
                          nextState
                          left
                          right
                          hRun
                      simpa [
                        checker,
                        psKernelKernelSessionChecker,
                        psKernelMkCheckerSession,
                        psKernelCheckerContextEmpty
                      ] using hDefEq
