import Ps.KernelCore.Metatheory.CheckerKnotConfiguration
import Ps.KernelCore.Checker.Session

/-
Concrete, configuration-aware checker-session refinement.

These proofs consume the actual executable checker-knot contracts rather than
the abstract unconditioned PsKernelInferenceSound / PsKernelDefEqSound inputs.

IMPORTANT: infer-only deliberately skips validation. Its session result
preserves configuration but must NOT be treated as a typing certificate.
A successful checked session does carry an independent typing judgment.
-/

theorem psKernelSessionCheck_concrete_refines_typing
    (fuel : Nat)
    (hNative : PsKernelNativeReductionSoundLaw)
    (hString : PsKernelStringEqSoundLaw)
    (session nextSession : PsKernelCheckerSession)
    (expr result : PsKernelExpr)
    (hConfig :
      PsKernelCheckerConfigurationSound
        session.context session.state)
    (hRun :
      psKernelSessionCheck fuel session expr =
        Except.ok (Prod.mk result nextSession)) :
    PsKernelTypingJudgment
        session.context.environment session.context.localContext
        expr result ∧
      PsKernelCheckerConfigurationSound
        session.context nextSession.state := by
  have hCheck :=
    (psKernelConcreteChecker_configuration_sound
      fuel hNative hString).1
  unfold psKernelSessionCheck at hRun
  cases hChecked :
      psKernelCheckerCheck
        fuel session.context session.state expr with
  | error error =>
      simp [hChecked] at hRun
  | ok checked =>
      rcases checked with ⟨type, checkedState⟩
      simp [hChecked] at hRun
      rcases hRun with ⟨rfl, rfl⟩
      exact
        hCheck
          session.context session.state checkedState
          expr type hConfig hChecked


theorem psKernelSessionInfer_concrete_preserves_configuration
    (fuel : Nat)
    (hNative : PsKernelNativeReductionSoundLaw)
    (hString : PsKernelStringEqSoundLaw)
    (session nextSession : PsKernelCheckerSession)
    (expr result : PsKernelExpr)
    (hConfig :
      PsKernelCheckerConfigurationSound
        session.context session.state)
    (hRun :
      psKernelSessionInfer fuel session expr =
        Except.ok (Prod.mk result nextSession)) :
    PsKernelCheckerConfigurationSound
      session.context nextSession.state := by
  have hInfer :=
    (psKernelConcreteChecker_configuration_sound
      fuel hNative hString).2.1
  unfold psKernelSessionInfer at hRun
  cases hInferred :
      psKernelCheckerInfer
        fuel session.context session.state expr with
  | error error =>
      simp [hInferred] at hRun
  | ok inferred =>
      rcases inferred with ⟨type, inferredState⟩
      simp [hInferred] at hRun
      rcases hRun with ⟨rfl, rfl⟩
      exact
        hInfer
          session.context session.state inferredState
          expr type hConfig hInferred


theorem psKernelSessionWhnf_concrete_refines_reduction
    (fuel : Nat)
    (hNative : PsKernelNativeReductionSoundLaw)
    (hString : PsKernelStringEqSoundLaw)
    (session nextSession : PsKernelCheckerSession)
    (expr result : PsKernelExpr)
    (hConfig :
      PsKernelCheckerConfigurationSound
        session.context session.state)
    (hRun :
      psKernelSessionWhnf fuel session expr =
        Except.ok (Prod.mk result nextSession)) :
    PsKernelReductionClosure
        session.context.environment session.context.localContext
        expr result ∧
      PsKernelCheckerConfigurationSound
        session.context nextSession.state := by
  have hWhnf :=
    (psKernelConcreteChecker_configuration_sound
      fuel hNative hString).2.2.1
  unfold psKernelSessionWhnf at hRun
  cases hReduced :
      psKernelCheckerWhnf
        fuel session.context session.state expr with
  | error error =>
      simp [hReduced] at hRun
  | ok reduced =>
      rcases reduced with ⟨value, reducedState⟩
      simp [hReduced] at hRun
      rcases hRun with ⟨rfl, rfl⟩
      exact
        hWhnf
          session.context session.state reducedState
          expr value hConfig hReduced


theorem psKernelSessionIsDefEq_concrete_refines_defeq
    (fuel : Nat)
    (hNative : PsKernelNativeReductionSoundLaw)
    (hString : PsKernelStringEqSoundLaw)
    (session nextSession : PsKernelCheckerSession)
    (left right : PsKernelExpr)
    (hConfig :
      PsKernelCheckerConfigurationSound
        session.context session.state)
    (hRun :
      psKernelSessionIsDefEq fuel session left right =
        Except.ok (Prod.mk true nextSession)) :
    PsKernelDefEqJudgment
        session.context.environment session.context.localContext
        left right ∧
      PsKernelCheckerConfigurationSound
        session.context nextSession.state := by
  have hDefEq :=
    (psKernelConcreteChecker_configuration_sound
      fuel hNative hString).2.2.2
  unfold psKernelSessionIsDefEq at hRun
  cases hCompared :
      psKernelIsDefEq
        fuel session.context session.state left right with
  | error error =>
      simp [hCompared] at hRun
  | ok compared =>
      rcases compared with ⟨value, comparedState⟩
      cases value with
      | false =>
          simp [hCompared] at hRun
      | true =>
          simp [hCompared] at hRun
          rcases hRun with ⟨rfl, rfl⟩
          have hSound :=
            hDefEq
              session.context session.state comparedState
              left right true hConfig hCompared
          exact ⟨hSound.2 rfl, hSound.1⟩


/-
Sort checking is a WHNF computation over an already inferred type. The
successful result carries the reduction to the actual Sort returned by the
executable session, plus preservation of checker configuration.
-/
theorem psKernelSessionEnsureSort_concrete_refines_reduction
    (fuel : Nat)
    (hNative : PsKernelNativeReductionSoundLaw)
    (hString : PsKernelStringEqSoundLaw)
    (session nextSession : PsKernelCheckerSession)
    (expr : PsKernelExpr)
    (level : PsKernelLevel)
    (hConfig :
      PsKernelCheckerConfigurationSound
        session.context session.state)
    (hRun :
      psKernelSessionEnsureSort fuel session expr =
        Except.ok (Prod.mk level nextSession)) :
    PsKernelReductionClosure
        session.context.environment session.context.localContext
        expr (PsKernelExpr.sort level) ∧
      PsKernelCheckerConfigurationSound
        session.context nextSession.state := by
  unfold psKernelSessionEnsureSort at hRun
  cases hWhnf : psKernelSessionWhnf fuel session expr with
  | error error =>
      simp [hWhnf] at hRun
  | ok whnfRun =>
      rcases whnfRun with ⟨reduced, whnfSession⟩
      cases reduced with
      | sort sortLevel =>
          have hSound :=
            psKernelSessionWhnf_concrete_refines_reduction
              fuel hNative hString
              session whnfSession
              expr (PsKernelExpr.sort sortLevel)
              hConfig hWhnf
          simp [hWhnf] at hRun
          rcases hRun with ⟨rfl, rfl⟩
          exact hSound
      | _ =>
          simp [hWhnf] at hRun
