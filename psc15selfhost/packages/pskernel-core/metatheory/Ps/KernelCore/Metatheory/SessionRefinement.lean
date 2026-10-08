import Ps.KernelCore.Checker.Session
import Ps.KernelCore.Metatheory.Judgments

theorem psKernelSessionInfer_refines_typing_core
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

theorem psKernelSessionCheck_refines_typing_core
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

theorem psKernelSessionWhnf_refines_reduction_core
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

theorem psKernelSessionIsDefEq_refines_defeq_core
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

theorem psKernelSessionCheck_success_preserves_context_core
    (fuel : Nat)
    (session nextSession : PsKernelCheckerSession)
    (expr result : PsKernelExpr)
    (hSuccess :
      psKernelSessionCheck fuel session expr =
        Except.ok (Prod.mk result nextSession)) :
    nextSession.context = session.context := by
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
          rfl


/-
The executable session wrappers preserve their context.  These structural
facts matter when composing header and body validation: a successful check
can update caches/freshness, but must not switch environments or local scopes.
-/
theorem psKernelSessionWhnf_success_preserves_context_core
    (fuel : Nat)
    (session nextSession : PsKernelCheckerSession)
    (expr result : PsKernelExpr)
    (hSuccess :
      psKernelSessionWhnf fuel session expr =
        Except.ok (Prod.mk result nextSession)) :
    nextSession.context = session.context := by
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
          rfl

theorem psKernelSessionEnsureSort_success_preserves_context_core
    (fuel : Nat)
    (session nextSession : PsKernelCheckerSession)
    (expr : PsKernelExpr)
    (level : PsKernelLevel)
    (hSuccess :
      psKernelSessionEnsureSort fuel session expr =
        Except.ok (Prod.mk level nextSession)) :
    nextSession.context = session.context := by
  cases hWhnf :
      psKernelSessionWhnf fuel session expr with
  | error error =>
      simp [psKernelSessionEnsureSort, hWhnf] at hSuccess
  | ok whnfRun =>
      rcases whnfRun with ⟨reduced, whnfSession⟩
      have hContext :=
        psKernelSessionWhnf_success_preserves_context_core
          fuel session whnfSession expr reduced hWhnf
      cases reduced with
      | sort sortLevel =>
          simp [psKernelSessionEnsureSort, hWhnf] at hSuccess
          rcases hSuccess with ⟨rfl, rfl⟩
          exact hContext
      | _ =>
          simp [psKernelSessionEnsureSort, hWhnf] at hSuccess


theorem psKernelSessionInfer_success_preserves_context_core
    (fuel : Nat)
    (session nextSession : PsKernelCheckerSession)
    (expr result : PsKernelExpr)
    (hSuccess :
      psKernelSessionInfer fuel session expr =
        Except.ok (Prod.mk result nextSession)) :
    nextSession.context = session.context := by
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
          rfl
