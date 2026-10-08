import Ps.KernelCore.Metatheory.AdmissionConstructorParamsConfiguration
import Ps.KernelCore.Metatheory.AdmissionNoTargetOccurrenceConfiguration

/-
Recursive-argument analysis preserves sound configuration in the actual
returned local context. Function arguments may extend that context; this
theorem does not incorrectly restore the original scope or infer a typing
certificate from infer-only.
-/
theorem psKernelAnalyzeSimpleRecursiveArgumentWithFuel_configuration_preserves
    (fuel : Nat)
    (hNative : PsKernelNativeReductionSoundLaw)
    (hString : PsKernelStringEqSoundLaw) :
    ∀ (session : PsKernelCheckerSession)
      (target : PsKernelName)
      (levels : List PsKernelLevel)
      (params : List PsKernelOpenBinder)
      (numIndices : Nat)
      (type : PsKernelExpr)
      (revArgs : List PsKernelOpenBinder)
      (result : PsKernelRecursiveArgumentResult),
      PsKernelCheckerConfigurationSound session.context session.state ->
      psKernelAnalyzeSimpleRecursiveArgumentWithFuel
        fuel session target levels params numIndices type revArgs =
          Except.ok result ->
      PsKernelCheckerConfigurationSound
        result.session.context result.session.state ∧
      result.session.context.environment = session.context.environment := by
  induction fuel with
  | zero =>
      intro session target levels params numIndices type revArgs result
        hConfig hRun
      simp [psKernelAnalyzeSimpleRecursiveArgumentWithFuel] at hRun
  | succ remaining ih =>
      intro session target levels params numIndices type revArgs result
        hConfig hRun
      cases hWhnf : psKernelSessionWhnf remaining session type with
      | error message =>
          simp [psKernelAnalyzeSimpleRecursiveArgumentWithFuel, hWhnf] at hRun
      | ok reducedResult =>
          rcases reducedResult with ⟨reduced, reducedSession⟩
          have hReducedSound := psKernelSessionWhnf_concrete_refines_reduction
            remaining hNative hString session reducedSession
            type reduced hConfig hWhnf
          have hReducedContext :=
            psKernelSessionWhnf_success_preserves_context_core
              remaining session reducedSession type reduced hWhnf
          have hReducedConfig : PsKernelCheckerConfigurationSound
              reducedSession.context reducedSession.state := by
            simpa [hReducedContext] using hReducedSound.2
          cases hApp : psKernelSimpleInductiveAppIndices
              target levels params numIndices reduced with
          | some indices =>
              cases hContains : psKernelSimpleIndicesContainTarget
                  target indices with
              | true =>
                  simp [psKernelAnalyzeSimpleRecursiveArgumentWithFuel,
                    hWhnf, hApp, hContains] at hRun
              | false =>
                  have hResult :
                      PsKernelRecursiveArgumentResult.mk reducedSession
                        (some (psKernelReverseOpenBinders revArgs, indices)) =
                          result := by
                    simpa [psKernelAnalyzeSimpleRecursiveArgumentWithFuel,
                      hWhnf, hApp, hContains] using hRun
                  cases hResult
                  exact ⟨hReducedConfig, congrArg
                    PsKernelCheckerContext.environment hReducedContext⟩
          | none =>
              simp only [psKernelAnalyzeSimpleRecursiveArgumentWithFuel,
                hWhnf, hApp] at hRun
              cases hShape : reduced with
              | forallE userName domain body binderInfo =>
                  cases hDomainWhnf :
                      psKernelSessionWhnf remaining reducedSession domain with
                  | error message =>
                      simp [hShape, hDomainWhnf] at hRun
                  | ok domainReduced =>
                      cases hNegative :
                          (if psKernelExprContainsConst target domain then true
                          else psKernelExprContainsConst target domainReduced.1) with
                      | true =>
                          simp [hShape, hDomainWhnf, hNegative] at hRun
                      | false =>
                          cases hCheck : psKernelSessionCheck
                              remaining domainReduced.2 domain with
                          | error message =>
                              simp [hShape, hDomainWhnf, hNegative, hCheck] at hRun
                          | ok domainType =>
                              cases hSort : psKernelSessionEnsureSort
                                  remaining domainType.2 domainType.1 with
                              | error message =>
                                  simp [hShape, hDomainWhnf, hNegative,
                                    hCheck, hSort] at hRun
                              | ok sortResult =>
                                  have hDomainSound :=
                                    psKernelSessionWhnf_concrete_refines_reduction
                                      remaining hNative hString reducedSession
                                      domainReduced.2 domain domainReduced.1
                                      hReducedConfig hDomainWhnf
                                  have hDomainContext :=
                                    psKernelSessionWhnf_success_preserves_context_core
                                      remaining reducedSession domainReduced.2
                                      domain domainReduced.1 hDomainWhnf
                                  have hDomainConfig : PsKernelCheckerConfigurationSound
                                      domainReduced.2.context domainReduced.2.state := by
                                    simpa [hDomainContext] using hDomainSound.2
                                  have hCheckSound :=
                                    psKernelSessionCheck_concrete_refines_typing
                                      remaining hNative hString domainReduced.2
                                      domainType.2 domain domainType.1
                                      hDomainConfig hCheck
                                  have hCheckContext :=
                                    psKernelSessionCheck_success_preserves_context_core
                                      remaining domainReduced.2 domainType.2
                                      domain domainType.1 hCheck
                                  have hCheckConfig : PsKernelCheckerConfigurationSound
                                      domainType.2.context domainType.2.state := by
                                    simpa [hCheckContext] using hCheckSound.2
                                  have hSortSound :=
                                    psKernelSessionEnsureSort_concrete_refines_reduction
                                      remaining hNative hString domainType.2
                                      sortResult.2 domainType.1 sortResult.1
                                      hCheckConfig hSort
                                  have hSortContext :=
                                    psKernelSessionEnsureSort_success_preserves_context_core
                                      remaining domainType.2 sortResult.2
                                      domainType.1 sortResult.1 hSort
                                  have hSortConfig : PsKernelCheckerConfigurationSound
                                      sortResult.2.context sortResult.2.state := by
                                    simpa [hSortContext] using hSortSound.2
                                  let opened := psKernelSessionWithLocal
                                    sortResult.2 userName
                                    (psKernelExprConsumeTypeAnnotations domain)
                                    binderInfo
                                  let binder := PsKernelOpenBinder.mk
                                    opened.1 userName
                                    (psKernelExprConsumeTypeAnnotations domain)
                                    binderInfo
                                  have hOpenedConfig : PsKernelCheckerConfigurationSound
                                      opened.2.context opened.2.state :=
                                    psKernelSessionWithLocal_preserves_configuration
                                      sortResult.2 userName
                                      (psKernelExprConsumeTypeAnnotations domain)
                                      binderInfo hString hSortConfig
                                  have hTailRun :
                                      psKernelAnalyzeSimpleRecursiveArgumentWithFuel
                                        remaining opened.2 target levels params
                                        numIndices
                                        (psKernelExprInstantiate1 body
                                          (PsKernelExpr.fvar opened.1))
                                        (binder :: revArgs) = Except.ok result := by
                                    simpa [psKernelAnalyzeSimpleRecursiveArgumentWithFuel,
                                      hShape, hDomainWhnf, hNegative,
                                      hCheck, hSort, opened, binder] using hRun
                                  have hRest := ih opened.2 target levels params numIndices
                                    (psKernelExprInstantiate1 body
                                      (PsKernelExpr.fvar opened.1))
                                    (binder :: revArgs) result hOpenedConfig hTailRun
                                  have hOpenedEnvironment :
                                      opened.2.context.environment =
                                        session.context.environment := by
                                    simp [opened, psKernelSessionWithLocal,
                                      psKernelCheckerContextWithLocalContext,
                                      hSortContext, hCheckContext,
                                      hDomainContext, hReducedContext]
                                  exact ⟨hRest.1, Eq.trans hRest.2 hOpenedEnvironment⟩
              | _ =>
                  cases hContains :
                      (if psKernelExprContainsConst target type then true
                       else psKernelExprContainsConst target reduced) with
                  | true =>
                      simp only [hShape] at hContains
                      simp [hShape, hContains] at hRun
                  | false =>
                      simp only [hShape] at hContains
                      have hResult :
                          PsKernelRecursiveArgumentResult.mk
                            reducedSession none = result := by
                        simpa [hShape, hContains] using hRun
                      cases hResult
                      exact ⟨hReducedConfig, congrArg
                        PsKernelCheckerContext.environment hReducedContext⟩
