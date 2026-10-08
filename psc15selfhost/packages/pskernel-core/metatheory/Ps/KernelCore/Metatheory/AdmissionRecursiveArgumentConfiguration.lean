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


/--
Independent ordinary strict-positive recursive-argument grammar, modulo
checked reduction. Function domains and recursive indices structurally
exclude the datatype, and opened function-domain names are fresh.
-/
inductive PsKernelOrdinaryRecursiveArgumentSafe
    (environment : PsKernelEnvironment) (target : PsKernelName)
    (levels : List PsKernelLevel) (params : List PsKernelOpenBinder)
    (numIndices : Nat) :
    PsKernelLocalContext -> PsKernelExpr -> List PsKernelOpenBinder ->
    Option (List PsKernelOpenBinder × List PsKernelExpr) -> Prop
  | nonrecursive
      (localContext : PsKernelLocalContext) (type reduced : PsKernelExpr)
      (revArgs : List PsKernelOpenBinder)
      (hReduction : PsKernelReductionClosure environment localContext type reduced)
      (hOriginal : PsKernelNoTargetConstantOccurrence target type)
      (hReduced : PsKernelNoTargetConstantOccurrence target reduced) :
      PsKernelOrdinaryRecursiveArgumentSafe environment target levels params
        numIndices localContext type revArgs none
  | recursive
      (localContext : PsKernelLocalContext) (type reduced : PsKernelExpr)
      (revArgs : List PsKernelOpenBinder) (indices : List PsKernelExpr)
      (hReduction : PsKernelReductionClosure environment localContext type reduced)
      (hHead : psKernelExprGetAppFn reduced = PsKernelExpr.const target levels)
      (hParams : PsKernelConstructorResultParamPrefix
        params (psKernelExprGetAppArgs reduced) indices)
      (hArity : psKernelExprListLength indices = numIndices)
      (hIndices : ∀ expr : PsKernelExpr, List.Mem expr indices ->
        PsKernelNoTargetConstantOccurrence target expr) :
      PsKernelOrdinaryRecursiveArgumentSafe environment target levels params
        numIndices localContext type revArgs
        (some (psKernelReverseOpenBinders revArgs, indices))
  | function
      (localContext : PsKernelLocalContext)
      (type domain domainReduced body : PsKernelExpr)
      (userName fresh : PsKernelName) (binderInfo : PsKernelBinderInfo)
      (level : PsKernelLevel) (revArgs : List PsKernelOpenBinder)
      (info : Option (List PsKernelOpenBinder × List PsKernelExpr))
      (hReduction : PsKernelReductionClosure environment localContext type
        (PsKernelExpr.forallE userName domain body binderInfo))
      (hDomainReduction : PsKernelReductionClosure
        environment localContext domain domainReduced)
      (hDomain : PsKernelTypingJudgment
        environment localContext domain (PsKernelExpr.sort level))
      (hOriginal : PsKernelNoTargetConstantOccurrence target domain)
      (hReduced : PsKernelNoTargetConstantOccurrence target domainReduced)
      (hFresh : psKernelLocalContextFind localContext fresh = none)
      (hBody : PsKernelOrdinaryRecursiveArgumentSafe
        environment target levels params numIndices
        (psKernelLocalContextAddLocal localContext fresh userName
          (psKernelExprConsumeTypeAnnotations domain) binderInfo)
        (psKernelExprInstantiate1 body (PsKernelExpr.fvar fresh))
        (PsKernelOpenBinder.mk fresh userName
          (psKernelExprConsumeTypeAnnotations domain) binderInfo :: revArgs) info) :
      PsKernelOrdinaryRecursiveArgumentSafe environment target levels params
        numIndices localContext type revArgs info

theorem psKernelSessionWithLocal_fresh_absent
    (session : PsKernelCheckerSession) (userName : PsKernelName)
    (type : PsKernelExpr) (binderInfo : PsKernelBinderInfo)
    (hString : PsKernelStringEqSoundLaw)
    (hConfig : PsKernelCheckerConfigurationSound
      session.context session.state) :
    psKernelLocalContextFind session.context.localContext
      (psKernelSessionWithLocal session userName type binderInfo).1 = none := by
  simpa only [psKernelSessionWithLocal, psKernelCheckerStateFreshName] using
    psKernelLocalContextFreshBound_name_absent
      session.context.localContext session.state.nextFresh
      userName hString hConfig.2.1

theorem psKernelNoTargetPairGuard_false_refines_absence
    (hReflexive : PsKernelStringEqReflexiveLaw) (target : PsKernelName)
    (left right : PsKernelExpr)
    (hGuard : (if psKernelExprContainsConst target left then true
      else psKernelExprContainsConst target right) = false) :
    PsKernelNoTargetConstantOccurrence target left ∧
      PsKernelNoTargetConstantOccurrence target right := by
  cases hLeft : psKernelExprContainsConst target left with
  | true => simp [hLeft] at hGuard
  | false =>
      have hRight : psKernelExprContainsConst target right = false := by
        simpa [hLeft] using hGuard
      exact ⟨psKernelExprContainsConst_false_refines_absence
        hReflexive target left hLeft,
        psKernelExprContainsConst_false_refines_absence
          hReflexive target right hRight⟩

theorem psKernelAnalyzeSimpleRecursiveArgumentWithFuel_semantic_refines
    (fuel : Nat)
    (hNative : PsKernelNativeReductionSoundLaw)
    (hString : PsKernelStringEqSoundLaw)
    (hReflexive : PsKernelStringEqReflexiveLaw) :
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
      PsKernelOrdinaryRecursiveArgumentSafe
        session.context.environment target levels params numIndices
        session.context.localContext type revArgs result.recursiveInfo := by
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
                  have hAppValid :=
                    psKernelSimpleInductiveAppIndices_success_refines
                      target levels params numIndices reduced indices hApp
                  rcases hAppValid with
                    ⟨resultName, resultLevels, hHead, hName,
                      hLevels, hParams, hArity⟩
                  have hNameEq := psKernelNameEq_sound_of_string_law
                    hString resultName target hName
                  have hLevelsEq := psKernelLevelListEq_sound_of_string_law
                    hString resultLevels levels hLevels
                  exact PsKernelOrdinaryRecursiveArgumentSafe.recursive
                    session.context.localContext type reduced revArgs indices
                    hReducedSound.1
                    (by simpa [hNameEq, hLevelsEq] using hHead)
                    (psKernelConsumeSimpleResultParams_success_refines_prefix
                      params (psKernelExprGetAppArgs reduced) indices hParams)
                    hArity
                    (psKernelSimpleIndicesContainTarget_false_refines_absence
                      hReflexive target indices hContains)
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
                                  have hNoDomain :=
                                    psKernelNoTargetPairGuard_false_refines_absence
                                      hReflexive target domain domainReduced.1 hNegative
                                  have hDomainReduction : PsKernelReductionClosure
                                      session.context.environment
                                      session.context.localContext
                                      domain domainReduced.1 := by
                                    simpa [hReducedContext] using hDomainSound.1
                                  have hDomainTyping : PsKernelTypingJudgment
                                      session.context.environment
                                      session.context.localContext
                                      domain (PsKernelExpr.sort sortResult.1) := by
                                    apply PsKernelTypingJudgment.convert
                                      domain domainType.1 (PsKernelExpr.sort sortResult.1)
                                    · simpa [hDomainContext, hReducedContext]
                                        using hCheckSound.1
                                    · apply PsKernelDefEqJudgment.reductionClosure
                                      simpa [hCheckContext, hDomainContext,
                                        hReducedContext] using hSortSound.1
                                  have hFresh := psKernelSessionWithLocal_fresh_absent
                                    sortResult.2 userName
                                    (psKernelExprConsumeTypeAnnotations domain)
                                    binderInfo hString hSortConfig
                                  have hFreshOriginal : psKernelLocalContextFind
                                      session.context.localContext opened.1 = none := by
                                    simpa [opened, hSortContext, hCheckContext,
                                      hDomainContext, hReducedContext] using hFresh
                                  have hBody : PsKernelOrdinaryRecursiveArgumentSafe
                                      session.context.environment
                                      target levels params numIndices
                                      (psKernelLocalContextAddLocal
                                        session.context.localContext opened.1 userName
                                        (psKernelExprConsumeTypeAnnotations domain)
                                        binderInfo)
                                      (psKernelExprInstantiate1 body
                                        (PsKernelExpr.fvar opened.1))
                                      (binder :: revArgs) result.recursiveInfo := by
                                    simpa [opened, psKernelSessionWithLocal,
                                      psKernelCheckerContextWithLocalContext, binder,
                                      hSortContext, hCheckContext,
                                      hDomainContext, hReducedContext] using hRest
                                  exact PsKernelOrdinaryRecursiveArgumentSafe.function
                                    session.context.localContext type domain
                                    domainReduced.1 body userName opened.1 binderInfo
                                    sortResult.1 revArgs result.recursiveInfo
                                    (by simpa [hShape] using hReducedSound.1)
                                    hDomainReduction hDomainTyping
                                    hNoDomain.1 hNoDomain.2 hFreshOriginal hBody
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
                      have hBoth := psKernelNoTargetPairGuard_false_refines_absence
                        hReflexive target type reduced
                        (by simpa [hShape] using hContains)
                      exact PsKernelOrdinaryRecursiveArgumentSafe.nonrecursive
                        session.context.localContext type reduced revArgs
                        hReducedSound.1 hBoth.1 hBoth.2
