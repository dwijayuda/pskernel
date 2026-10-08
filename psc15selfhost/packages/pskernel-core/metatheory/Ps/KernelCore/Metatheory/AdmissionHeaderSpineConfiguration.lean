import Ps.KernelCore.Metatheory.AdmissionRecursiveArgumentConfiguration

/--
One independently checked header binder, after valid reduction to a Pi.
Header opening may reduce its outer type; constructor opening remains raw.
-/
inductive PsKernelCheckedHeaderBinderStep
    (environment : PsKernelEnvironment) :
    PsKernelLocalContext -> PsKernelExpr -> PsKernelLocalContext ->
    PsKernelOpenBinder -> PsKernelExpr -> Prop
  | intro
      (localContext : PsKernelLocalContext)
      (type domain body : PsKernelExpr)
      (userName fresh : PsKernelName)
      (binderInfo : PsKernelBinderInfo)
      (domainLevel : PsKernelLevel)
      (hReduction : PsKernelReductionClosure environment localContext type
        (PsKernelExpr.forallE userName domain body binderInfo))
      (hDomain : PsKernelTypingJudgment environment localContext domain
        (PsKernelExpr.sort domainLevel))
      (hFresh : psKernelLocalContextFind localContext fresh = none) :
      PsKernelCheckedHeaderBinderStep environment localContext type
        (psKernelLocalContextAddLocal localContext fresh userName
          (psKernelExprConsumeTypeAnnotations domain) binderInfo)
        (PsKernelOpenBinder.mk fresh userName
          (psKernelExprConsumeTypeAnnotations domain) binderInfo)
        (psKernelExprInstantiate1 body (PsKernelExpr.fvar fresh))

inductive PsKernelCheckedHeaderBinderSpine
    (environment : PsKernelEnvironment) :
    PsKernelLocalContext -> PsKernelExpr -> List PsKernelOpenBinder ->
    PsKernelLocalContext -> PsKernelExpr -> Prop
  | done
      (localContext : PsKernelLocalContext)
      (type residual : PsKernelExpr)
      (hReduction : PsKernelReductionClosure
        environment localContext type residual) :
      PsKernelCheckedHeaderBinderSpine
        environment localContext type [] localContext residual
  | cons
      (localContext nextContext finalContext : PsKernelLocalContext)
      (type opened residual : PsKernelExpr)
      (binder : PsKernelOpenBinder) (binders : List PsKernelOpenBinder)
      (hStep : PsKernelCheckedHeaderBinderStep
        environment localContext type nextContext binder opened)
      (hTail : PsKernelCheckedHeaderBinderSpine
        environment nextContext opened binders finalContext residual) :
      PsKernelCheckedHeaderBinderSpine
        environment localContext type (binder :: binders) finalContext residual

theorem psKernelOpenSimpleHeaderParamStep_configuration_refines
    (fuel : Nat)
    (hNative : PsKernelNativeReductionSoundLaw)
    (hString : PsKernelStringEqSoundLaw)
    (session : PsKernelCheckerSession)
    (type : PsKernelExpr)
    (step : (PsKernelCheckerSession × PsKernelOpenBinder) × PsKernelExpr)
    (hConfig : PsKernelCheckerConfigurationSound session.context session.state)
    (hRun : psKernelOpenSimpleHeaderParamStep fuel session type = Except.ok step) :
    PsKernelCheckerConfigurationSound step.1.1.context step.1.1.state ∧
    step.1.1.context.environment = session.context.environment ∧
    session.context.localContext.nextIndex ≤ step.1.1.context.localContext.nextIndex ∧
    PsKernelCheckedHeaderBinderStep session.context.environment
      session.context.localContext type step.1.1.context.localContext step.1.2 step.2 := by
  cases hWhnf : psKernelSessionWhnf fuel session type with
  | error message =>
      simp [psKernelOpenSimpleHeaderParamStep, hWhnf] at hRun
  | ok reduced =>
      rcases reduced with ⟨reducedType, reducedSession⟩
      cases reducedType with
      | forallE userName domain body binderInfo =>
          cases hCheck : psKernelSessionCheck fuel reducedSession domain with
          | error message =>
              simp [psKernelOpenSimpleHeaderParamStep, hWhnf, hCheck] at hRun
          | ok domainType =>
              cases hSort : psKernelSessionEnsureSort fuel domainType.2 domainType.1 with
              | error message =>
                  simp [psKernelOpenSimpleHeaderParamStep, hWhnf, hCheck, hSort] at hRun
              | ok sorted =>
                  have hReducedSound := psKernelSessionWhnf_concrete_refines_reduction
                    fuel hNative hString session reducedSession type
                    (PsKernelExpr.forallE userName domain body binderInfo) hConfig hWhnf
                  have hReducedContext := psKernelSessionWhnf_success_preserves_context_core
                    fuel session reducedSession type
                    (PsKernelExpr.forallE userName domain body binderInfo) hWhnf
                  have hReducedConfig : PsKernelCheckerConfigurationSound
                      reducedSession.context reducedSession.state := by
                    simpa [hReducedContext] using hReducedSound.2
                  have hCheckSound := psKernelSessionCheck_concrete_refines_typing
                    fuel hNative hString reducedSession domainType.2
                    domain domainType.1 hReducedConfig hCheck
                  have hCheckContext := psKernelSessionCheck_success_preserves_context_core
                    fuel reducedSession domainType.2 domain domainType.1 hCheck
                  have hCheckConfig : PsKernelCheckerConfigurationSound
                      domainType.2.context domainType.2.state := by
                    simpa [hCheckContext] using hCheckSound.2
                  have hSortSound := psKernelSessionEnsureSort_concrete_refines_reduction
                    fuel hNative hString domainType.2 sorted.2
                    domainType.1 sorted.1 hCheckConfig hSort
                  have hSortContext := psKernelSessionEnsureSort_success_preserves_context_core
                    fuel domainType.2 sorted.2 domainType.1 sorted.1 hSort
                  have hSortConfig : PsKernelCheckerConfigurationSound
                      sorted.2.context sorted.2.state := by
                    simpa [hSortContext] using hSortSound.2
                  let opened := psKernelSessionWithLocal sorted.2 userName
                    (psKernelExprConsumeTypeAnnotations domain) binderInfo
                  let binder := PsKernelOpenBinder.mk opened.1 userName
                    (psKernelExprConsumeTypeAnnotations domain) binderInfo
                  have hResult :
                      ((opened.2, binder),
                        psKernelExprInstantiate1 body (PsKernelExpr.fvar opened.1)) = step := by
                    simpa [psKernelOpenSimpleHeaderParamStep,
                      hWhnf, hCheck, hSort, opened, binder] using hRun
                  cases hResult
                  have hDomain : PsKernelTypingJudgment session.context.environment
                      session.context.localContext domain (PsKernelExpr.sort sorted.1) := by
                    apply PsKernelTypingJudgment.convert domain domainType.1
                      (PsKernelExpr.sort sorted.1)
                    · simpa [hReducedContext] using hCheckSound.1
                    · apply PsKernelDefEqJudgment.reductionClosure
                      simpa [hCheckContext, hReducedContext] using hSortSound.1
                  have hFresh := psKernelSessionWithLocal_fresh_absent sorted.2 userName
                    (psKernelExprConsumeTypeAnnotations domain) binderInfo hString hSortConfig
                  have hFreshOriginal : psKernelLocalContextFind
                      session.context.localContext opened.1 = none := by
                    simpa [opened, hSortContext, hCheckContext, hReducedContext] using hFresh
                  refine ⟨psKernelSessionWithLocal_preserves_configuration
                    sorted.2 userName (psKernelExprConsumeTypeAnnotations domain)
                    binderInfo hString hSortConfig, ?_, ?_, ?_⟩
                  · simp [opened, psKernelSessionWithLocal,
                      psKernelCheckerContextWithLocalContext,
                      hSortContext, hCheckContext, hReducedContext]
                  · simp [opened, psKernelSessionWithLocal,
                      psKernelCheckerContextWithLocalContext, psKernelLocalContextAddLocal,
                      hSortContext, hCheckContext, hReducedContext]
                  · simpa [opened, binder, psKernelSessionWithLocal,
                      psKernelCheckerContextWithLocalContext,
                      hSortContext, hCheckContext, hReducedContext] using
                      PsKernelCheckedHeaderBinderStep.intro
                        session.context.localContext type domain body userName opened.1
                        binderInfo sorted.1 hReducedSound.1 hDomain hFreshOriginal
      | _ =>
          simp [psKernelOpenSimpleHeaderParamStep, hWhnf] at hRun

theorem psKernelOpenSimpleHeaderParamsWorker_configuration_refines
    (remainingParams : Nat)
    (fuel : Nat)
    (hNative : PsKernelNativeReductionSoundLaw)
    (hString : PsKernelStringEqSoundLaw) :
    ∀ (session : PsKernelCheckerSession) (type : PsKernelExpr)
      (revParams : List PsKernelOpenBinder) (result : PsKernelOpenBindersResult),
      PsKernelCheckerConfigurationSound session.context session.state ->
      psKernelOpenSimpleHeaderParamsWorker
        remainingParams fuel session type revParams = Except.ok result ->
      PsKernelCheckerConfigurationSound result.session.context result.session.state ∧
      result.session.context.environment = session.context.environment ∧
      session.context.localContext.nextIndex ≤ result.session.context.localContext.nextIndex ∧
      ∃ binders : List PsKernelOpenBinder,
        result.binders = psKernelReverseOpenBinders revParams ++ binders ∧
        PsKernelCheckedHeaderBinderSpine session.context.environment
          session.context.localContext type binders
          result.session.context.localContext result.result := by
  induction remainingParams with
  | zero =>
      intro session type revParams result hConfig hRun
      cases hWhnf : psKernelSessionWhnf fuel session type with
      | error message =>
          simp [psKernelOpenSimpleHeaderParamsWorker,
            psKernelFinishOpenBindersWithWhnf, hWhnf] at hRun
      | ok reduced =>
          have hSound := psKernelSessionWhnf_concrete_refines_reduction
            fuel hNative hString session reduced.2 type reduced.1 hConfig hWhnf
          have hContext := psKernelSessionWhnf_success_preserves_context_core
            fuel session reduced.2 type reduced.1 hWhnf
          have hResult : PsKernelOpenBindersResult.mk
              reduced.2 (psKernelReverseOpenBinders revParams) reduced.1 = result := by
            simpa [psKernelOpenSimpleHeaderParamsWorker,
              psKernelFinishOpenBindersWithWhnf, psKernelOpenBindersResult, hWhnf] using hRun
          cases hResult
          refine ⟨?_, congrArg PsKernelCheckerContext.environment hContext,
            ?_, [], by simp, ?_⟩
          · simpa [hContext] using hSound.2
          · simp [hContext]
          · simpa [hContext] using PsKernelCheckedHeaderBinderSpine.done
              session.context.localContext type reduced.1 hSound.1
  | succ remaining ih =>
      intro session type revParams result hConfig hRun
      cases hStep : psKernelOpenSimpleHeaderParamStep fuel session type with
      | error message =>
          simp [psKernelOpenSimpleHeaderParamsWorker, hStep] at hRun
      | ok step =>
          have hStepSound := psKernelOpenSimpleHeaderParamStep_configuration_refines
            fuel hNative hString session type step hConfig hStep
          have hTailRun : psKernelOpenSimpleHeaderParamsWorker
              remaining fuel step.1.1 step.2 (step.1.2 :: revParams) = Except.ok result := by
            simpa [psKernelOpenSimpleHeaderParamsWorker, hStep] using hRun
          rcases ih step.1.1 step.2 (step.1.2 :: revParams) result
            hStepSound.1 hTailRun with
            ⟨hFinalConfig, hFinalEnv, hOrdinal, binders, hBinders, hSpine⟩
          refine ⟨hFinalConfig, Eq.trans hFinalEnv hStepSound.2.1,
            Nat.le_trans hStepSound.2.2.1 hOrdinal, step.1.2 :: binders, ?_, ?_⟩
          · exact Eq.trans hBinders
              (psKernelReverseOpenBinders_cons_append step.1.2 revParams binders)
          · exact PsKernelCheckedHeaderBinderSpine.cons
              session.context.localContext step.1.1.context.localContext
              result.session.context.localContext type step.2 result.result
              step.1.2 binders hStepSound.2.2.2
              (by simpa [hStepSound.2.1] using hSpine)
