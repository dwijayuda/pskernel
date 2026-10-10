import Ps.KernelCore.API.Kernel
import Ps.KernelCore.Metatheory.CheckerInitialConfiguration
import Ps.KernelCore.Metatheory.SessionConcreteRefinement

/-
Public KernelContract-v1 expression operations, grounded in the concrete
checker-knot theorem rather than abstract, unchecked callbacks.

The environment index must refine the authoritative declarations.  Native
reduction and StringEq remain explicitly named trusted laws.  The public
preflight and expression-check gates cannot be bypassed on a successful path.
-/

theorem psKernelKernelSessionChecker_initial_configuration
    (session : PsKernelKernelSession)
    (levelParams : List PsKernelName)
    (safety : PsKernelDefinitionSafety)
    (hIndex : PsKernelEnvironmentIndexRefines session.environment) :
    PsKernelCheckerConfigurationSound
      (psKernelKernelSessionChecker session levelParams safety).context
      (psKernelKernelSessionChecker session levelParams safety).state := by
  have hWithNative :
      PsKernelEnvironmentIndexRefines
        (psKernelKernelSessionEnvironment session) := by
    intro name
    simpa [
      psKernelKernelSessionEnvironment,
      psKernelEnvironmentWithNativeEvaluator
    ] using hIndex name
  simpa [psKernelKernelSessionChecker] using
    (psKernelMkCheckerSession_configuration_sound
      (psKernelKernelSessionEnvironment session)
      levelParams safety
      session.resources.maxRecDepth
      session.resources.maxNatSize
      hWithNative)


theorem psKernelV1CheckExpression_concrete_refines_typing
    (session : PsKernelKernelSession)
    (levelParams : List PsKernelName)
    (safety : PsKernelDefinitionSafety)
    (expression : PsKernelExpr)
    (checked : PsKernelCheckedExpression)
    (hIndex : PsKernelEnvironmentIndexRefines session.environment)
    (hNative : PsKernelNativeReductionSoundLaw)
    (hString : PsKernelStringEqSoundLaw)
    (hSuccess :
      psKernelV1CheckExpression
          session levelParams safety expression =
        Except.ok checked) :
    PsKernelTypingJudgment
      (psKernelKernelSessionEnvironment session)
      psKernelLocalContextEmpty
      expression
      checked.type := by
  cases hPreflight :
      psKernelKernelSessionPreflight session with
  | error error =>
      simp [psKernelV1CheckExpression, hPreflight] at hSuccess
  | ok preflight =>
      cases preflight
      let checker :=
        psKernelKernelSessionChecker session levelParams safety
      have hInitial :
          PsKernelCheckerConfigurationSound
            checker.context checker.state :=
        psKernelKernelSessionChecker_initial_configuration
          session levelParams safety hIndex
      cases hCheck :
          psKernelSessionCheck
            session.resources.fuel checker expression with
      | error message =>
          simp [
            psKernelV1CheckExpression, hPreflight,
            hCheck, checker
          ] at hSuccess
      | ok checkedRun =>
          rcases checkedRun with ⟨inferredType, nextChecker⟩
          have hConcrete :=
            psKernelSessionCheck_concrete_refines_typing
              session.resources.fuel hNative hString
              checker nextChecker
              expression inferredType hInitial hCheck
          simp [
            psKernelV1CheckExpression, hPreflight,
            hCheck, checker
          ] at hSuccess
          subst checked
          simpa [
            checker, psKernelKernelSessionChecker,
            psKernelMkCheckerSession,
            psKernelCheckerContextEmpty
          ] using hConcrete.1


theorem psKernelV1Whnf_concrete_refines_reduction
    (session : PsKernelKernelSession)
    (levelParams : List PsKernelName)
    (safety : PsKernelDefinitionSafety)
    (expression result : PsKernelExpr)
    (hIndex : PsKernelEnvironmentIndexRefines session.environment)
    (hNative : PsKernelNativeReductionSoundLaw)
    (hString : PsKernelStringEqSoundLaw)
    (hSuccess :
      psKernelV1Whnf
          session levelParams safety expression =
        Except.ok result) :
    PsKernelReductionClosure
      (psKernelKernelSessionEnvironment session)
      psKernelLocalContextEmpty
      expression result := by
  cases hCheck :
      psKernelV1CheckExpression
        session levelParams safety expression with
  | error error =>
      simp [psKernelV1Whnf, hCheck] at hSuccess
  | ok checked =>
      let checker :=
        psKernelKernelSessionChecker session levelParams safety
      have hInitial :
          PsKernelCheckerConfigurationSound
            checker.context checker.state :=
        psKernelKernelSessionChecker_initial_configuration
          session levelParams safety hIndex
      cases hWhnf :
          psKernelSessionWhnf
            session.resources.fuel checker expression with
      | error error =>
          simp [
            psKernelV1Whnf, hCheck, hWhnf, checker
          ] at hSuccess
      | ok whnfRun =>
          rcases whnfRun with ⟨reduced, nextChecker⟩
          have hConcrete :=
            psKernelSessionWhnf_concrete_refines_reduction
              session.resources.fuel hNative hString
              checker nextChecker
              expression reduced hInitial hWhnf
          simp [
            psKernelV1Whnf, hCheck, hWhnf, checker
          ] at hSuccess
          subst result
          simpa [
            checker, psKernelKernelSessionChecker,
            psKernelMkCheckerSession,
            psKernelCheckerContextEmpty
          ] using hConcrete.1


theorem psKernelV1IsDefEq_true_concrete_refines_defeq
    (session : PsKernelKernelSession)
    (levelParams : List PsKernelName)
    (safety : PsKernelDefinitionSafety)
    (left right : PsKernelExpr)
    (hIndex : PsKernelEnvironmentIndexRefines session.environment)
    (hNative : PsKernelNativeReductionSoundLaw)
    (hString : PsKernelStringEqSoundLaw)
    (hSuccess :
      psKernelV1IsDefEq
          session levelParams safety left right =
        Except.ok true) :
    PsKernelDefEqJudgment
      (psKernelKernelSessionEnvironment session)
      psKernelLocalContextEmpty
      left right := by
  cases hLeft :
      psKernelV1CheckExpression
        session levelParams safety left with
  | error error =>
      simp [psKernelV1IsDefEq, hLeft] at hSuccess
  | ok leftChecked =>
      cases hRight :
          psKernelV1CheckExpression
            session levelParams safety right with
      | error error =>
          simp [psKernelV1IsDefEq, hLeft, hRight] at hSuccess
      | ok rightChecked =>
          let checker :=
            psKernelKernelSessionChecker session levelParams safety
          have hInitial :
              PsKernelCheckerConfigurationSound
                checker.context checker.state :=
            psKernelKernelSessionChecker_initial_configuration
              session levelParams safety hIndex
          cases hCompared :
              psKernelSessionIsDefEq
                session.resources.fuel checker left right with
          | error error =>
              simp [
                psKernelV1IsDefEq, hLeft, hRight,
                hCompared, checker
              ] at hSuccess
          | ok comparedRun =>
              rcases comparedRun with ⟨value, nextChecker⟩
              cases value with
              | false =>
                  simp [
                    psKernelV1IsDefEq, hLeft, hRight,
                    hCompared, checker
                  ] at hSuccess
              | true =>
                  have hConcrete :=
                    psKernelSessionIsDefEq_concrete_refines_defeq
                      session.resources.fuel hNative hString
                      checker nextChecker
                      left right hInitial hCompared
                  simpa [
                    checker, psKernelKernelSessionChecker,
                    psKernelMkCheckerSession,
                    psKernelCheckerContextEmpty
                  ] using hConcrete.1
