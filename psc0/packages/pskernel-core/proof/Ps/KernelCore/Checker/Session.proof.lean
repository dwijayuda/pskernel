import Ps.KernelCore.Checker.Session
import Ps.KernelCore.Metatheory.Judgments

theorem psKernelMkCheckerSession_recDepth_zero
    (environment : PsKernelEnvironment)
    (levelParams : List PsKernelName)
    (safety : PsKernelDefinitionSafety)
    (maxRecDepth maxNatSize : Nat) :
    (psKernelMkCheckerSession
      environment levelParams safety maxRecDepth maxNatSize).context.recDepth =
      0 := by
  rfl

theorem psKernelMkCheckerSession_state_empty
    (environment : PsKernelEnvironment)
    (levelParams : List PsKernelName)
    (safety : PsKernelDefinitionSafety)
    (maxRecDepth maxNatSize : Nat) :
    (psKernelMkCheckerSession
      environment levelParams safety maxRecDepth maxNatSize).state =
      psKernelCheckerStateEmpty := by
  rfl

theorem psKernelSessionWhnf_error
    (fuel : Nat)
    (session : PsKernelCheckerSession)
    (expr : PsKernelExpr)
    (error : String)
    (h :
      psKernelCheckerWhnf
          fuel session.context session.state expr =
        Except.error error) :
    psKernelSessionWhnf fuel session expr =
      Except.error error := by
  simp [psKernelSessionWhnf, h]

theorem psKernelSessionWhnf_success
    (fuel : Nat)
    (session : PsKernelCheckerSession)
    (expr result : PsKernelExpr)
    (state : PsKernelCheckerState)
    (h :
      psKernelCheckerWhnf
          fuel session.context session.state expr =
        Except.ok (Prod.mk result state)) :
    psKernelSessionWhnf fuel session expr =
      Except.ok
        (Prod.mk
          result
          (PsKernelCheckerSession.mk session.context state)) := by
  simp [psKernelSessionWhnf, h]

theorem psKernelSessionInfer_error
    (fuel : Nat)
    (session : PsKernelCheckerSession)
    (expr : PsKernelExpr)
    (error : String)
    (h :
      psKernelCheckerInfer
          fuel session.context session.state expr =
        Except.error error) :
    psKernelSessionInfer fuel session expr =
      Except.error error := by
  simp [psKernelSessionInfer, h]

theorem psKernelSessionCheck_error
    (fuel : Nat)
    (session : PsKernelCheckerSession)
    (expr : PsKernelExpr)
    (error : String)
    (h :
      psKernelCheckerCheck
          fuel session.context session.state expr =
        Except.error error) :
    psKernelSessionCheck fuel session expr =
      Except.error error := by
  simp [psKernelSessionCheck, h]

theorem psKernelSessionIsDefEq_error
    (fuel : Nat)
    (session : PsKernelCheckerSession)
    (left right : PsKernelExpr)
    (error : String)
    (h :
      psKernelIsDefEq
          fuel session.context session.state left right =
        Except.error error) :
    psKernelSessionIsDefEq fuel session left right =
      Except.error error := by
  simp [psKernelSessionIsDefEq, h]


theorem psKernelSessionInfer_refines_typing
    (fuel : Nat)
    (session nextSession : PsKernelCheckerSession)
    (expr result : PsKernelExpr)
    (hSound :
      PsKernelInferenceSound
        (psKernelCheckerInfer fuel))
    (hSuccess :
      psKernelSessionInfer fuel session expr =
        Except.ok (Prod.mk result nextSession)) :
    PsKernelTypingJudgment
      session.context.environment
      session.context.localContext
      expr
      result := by
  unfold psKernelSessionInfer at hSuccess
  cases hRun :
      psKernelCheckerInfer
        fuel session.context session.state expr with
  | error error =>
      simp [hRun] at hSuccess
  | ok run =>
      cases run with
      | mk inferred nextState =>
          simp [hRun] at hSuccess
          rcases hSuccess with ⟨rfl, rfl⟩
          exact
            hSound
              session.context
              session.state
              nextState
              expr
              inferred
              hRun

theorem psKernelSessionCheck_refines_typing
    (fuel : Nat)
    (session nextSession : PsKernelCheckerSession)
    (expr result : PsKernelExpr)
    (hSound :
      PsKernelInferenceSound
        (psKernelCheckerCheck fuel))
    (hSuccess :
      psKernelSessionCheck fuel session expr =
        Except.ok (Prod.mk result nextSession)) :
    PsKernelTypingJudgment
      session.context.environment
      session.context.localContext
      expr
      result := by
  unfold psKernelSessionCheck at hSuccess
  cases hRun :
      psKernelCheckerCheck
        fuel session.context session.state expr with
  | error error =>
      simp [hRun] at hSuccess
  | ok run =>
      cases run with
      | mk inferred nextState =>
          simp [hRun] at hSuccess
          rcases hSuccess with ⟨rfl, rfl⟩
          exact
            hSound
              session.context
              session.state
              nextState
              expr
              inferred
              hRun

theorem psKernelSessionWhnf_refines_reduction
    (fuel : Nat)
    (session nextSession : PsKernelCheckerSession)
    (expr result : PsKernelExpr)
    (hSound :
      PsKernelWhnfSound
        (psKernelCheckerWhnf fuel))
    (hSuccess :
      psKernelSessionWhnf fuel session expr =
        Except.ok (Prod.mk result nextSession)) :
    PsKernelReductionClosure
      session.context.environment
      session.context.localContext
      expr
      result := by
  unfold psKernelSessionWhnf at hSuccess
  cases hRun :
      psKernelCheckerWhnf
        fuel session.context session.state expr with
  | error error =>
      simp [hRun] at hSuccess
  | ok run =>
      cases run with
      | mk reduced nextState =>
          simp [hRun] at hSuccess
          rcases hSuccess with ⟨rfl, rfl⟩
          exact
            hSound
              session.context
              session.state
              nextState
              expr
              reduced
              hRun

theorem psKernelSessionIsDefEq_refines_defeq
    (fuel : Nat)
    (session nextSession : PsKernelCheckerSession)
    (left right : PsKernelExpr)
    (hSound :
      PsKernelDefEqSound
        (psKernelIsDefEq fuel))
    (hSuccess :
      psKernelSessionIsDefEq fuel session left right =
        Except.ok (Prod.mk true nextSession)) :
    PsKernelDefEqJudgment
      session.context.environment
      session.context.localContext
      left
      right := by
  unfold psKernelSessionIsDefEq at hSuccess
  cases hRun :
      psKernelIsDefEq
        fuel session.context session.state left right with
  | error error =>
      simp [hRun] at hSuccess
  | ok run =>
      cases run with
      | mk value nextState =>
          cases value with
          | false =>
              simp [hRun] at hSuccess
          | true =>
              simp [hRun] at hSuccess
              subst nextSession
              exact
                hSound
                  session.context
                  session.state
                  nextState
                  left
                  right
                  hRun
