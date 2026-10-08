import Ps.KernelCore.Metatheory.AdmissionConstructorParamsConfiguration
import Ps.KernelCore.Metatheory.AdmissionNoTargetOccurrenceConfiguration

/-
Recursive-argument analysis preserves sound configuration in the actual
returned local context. Function arguments may extend that context; this
theorem does not incorrectly restore the original scope or infer a typing
certificate from infer-only.
-/
theorem psKernelAnalyzeSimpleRecursiveArgumentWithFuel_configuration_history_preserves
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
      result.session.context.environment = session.context.environment ∧
      session.context.localContext.nextIndex ≤
        result.session.context.localContext.nextIndex := by
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
                    PsKernelCheckerContext.environment hReducedContext,
                    by simp [hReducedContext]⟩
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
                                  have hOpenedOrdinal :
                                      session.context.localContext.nextIndex ≤
                                        opened.2.context.localContext.nextIndex := by
                                    simp [opened, psKernelSessionWithLocal,
                                      psKernelCheckerContextWithLocalContext,
                                      psKernelLocalContextAddLocal,
                                      hSortContext, hCheckContext,
                                      hDomainContext, hReducedContext]
                                  exact ⟨hRest.1,
                                    Eq.trans hRest.2.1 hOpenedEnvironment,
                                    Nat.le_trans hOpenedOrdinal hRest.2.2⟩
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
                        PsKernelCheckerContext.environment hReducedContext,
                        by simp [hReducedContext]⟩



/-- Public configuration contract, retaining its original interface. -/
theorem psKernelAnalyzeSimpleRecursiveArgumentWithFuel_configuration_preserves
    (fuel : Nat)
    (hNative : PsKernelNativeReductionSoundLaw)
    (hString : PsKernelStringEqSoundLaw)
    (session : PsKernelCheckerSession)
    (target : PsKernelName)
    (levels : List PsKernelLevel)
    (params : List PsKernelOpenBinder)
    (numIndices : Nat)
    (type : PsKernelExpr)
    (revArgs : List PsKernelOpenBinder)
    (result : PsKernelRecursiveArgumentResult)
    (hConfig : PsKernelCheckerConfigurationSound session.context session.state)
    (hRun : psKernelAnalyzeSimpleRecursiveArgumentWithFuel
      fuel session target levels params numIndices type revArgs =
        Except.ok result) :
    PsKernelCheckerConfigurationSound
      result.session.context result.session.state ∧
    result.session.context.environment = session.context.environment := by
  have h := psKernelAnalyzeSimpleRecursiveArgumentWithFuel_configuration_history_preserves
    fuel hNative hString session target levels params numIndices type revArgs
    result hConfig hRun
  exact ⟨h.1, h.2.1⟩

/-- Scope restoration exposes a lookup-preserving, monotone ordinal handoff. -/
theorem psKernelSessionRestoreLocalScope_ordinal_history
    (parent child : PsKernelCheckerSession)
    (hOrdinal : parent.context.localContext.nextIndex ≤
      child.context.localContext.nextIndex) :
    PsKernelLocalContextOrdinalHistoryExtends parent.context.localContext
      (psKernelSessionRestoreLocalScope parent child).context.localContext := by
  exact ⟨rfl, hOrdinal⟩

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


theorem psKernelReverseOpenBindersWorker_eq_reverse_append
    (values : List PsKernelOpenBinder) :
    ∀ (acc : List PsKernelOpenBinder),
      psKernelReverseOpenBindersWorker values acc = values.reverse ++ acc := by
  induction values with
  | nil => intro acc; rfl
  | cons head tail ih =>
      intro acc
      simp [psKernelReverseOpenBindersWorker, ih,
        List.reverse_cons, List.append_assoc]

theorem psKernelReverseOpenBinders_cons_append
    (field : PsKernelOpenBinder) (revFields fields : List PsKernelOpenBinder) :
    psKernelReverseOpenBinders (field :: revFields) ++ fields =
      psKernelReverseOpenBinders revFields ++ (field :: fields) := by
  simp [psKernelReverseOpenBinders,
    psKernelReverseOpenBindersWorker_eq_reverse_append,
    List.reverse_cons, List.append_assoc]

/--
Raw field-spine typing and exact residual refinement. Recursive analysis may
allocate temporary function arguments; its monotone ordinal history is kept,
while the parent's semantic caches and active declarations are restored.
-/
theorem psKernelOpenSimpleConstructorFieldsWithFuel_raw_spine_refines
    (fuel : Nat)
    (hNative : PsKernelNativeReductionSoundLaw)
    (hString : PsKernelStringEqSoundLaw) :
    ∀ (session : PsKernelCheckerSession)
      (target : PsKernelName)
      (levels : List PsKernelLevel)
      (params : List PsKernelOpenBinder)
      (numIndices : Nat)
      (resultLevel : PsKernelLevel)
      (type : PsKernelExpr)
      (revFields : List PsKernelOpenBinder)
      (revRecursive : List PsKernelSimpleRecursiveField)
      (result : PsKernelOpenFieldsResult),
      PsKernelCheckerConfigurationSound session.context session.state ->
      psKernelOpenSimpleConstructorFieldsWithFuel fuel session target levels
        params numIndices resultLevel type revFields revRecursive =
          Except.ok result ->
      ∃ fields : List PsKernelOpenBinder,
        result.fields = psKernelReverseOpenBinders revFields ++ fields ∧
        PsKernelRawConstructorFieldSpineValid session.context.environment
          resultLevel session.context.localContext type
          result.session.context.localContext fields result.result ∧
        PsKernelCheckerConfigurationSound
          result.session.context result.session.state ∧
        result.session.context.environment = session.context.environment := by
  induction fuel with
  | zero =>
      intro session target levels params numIndices resultLevel type revFields
        revRecursive result hConfig hRun
      simp [psKernelOpenSimpleConstructorFieldsWithFuel] at hRun
  | succ remaining ih =>
      intro session target levels params numIndices resultLevel type revFields
        revRecursive result hConfig hRun
      cases type with
      | forallE userName domain body binderInfo =>
          cases hCheck : psKernelSessionCheck remaining session domain with
          | error message =>
              simp [psKernelOpenSimpleConstructorFieldsWithFuel, hCheck] at hRun
          | ok domainType =>
              cases hSort : psKernelSessionEnsureSort
                  remaining domainType.2 domainType.1 with
              | error message =>
                  simp [psKernelOpenSimpleConstructorFieldsWithFuel,
                    hCheck, hSort] at hRun
              | ok fieldSort =>
                  cases hUniverse :
                      (if psKernelLevelLe fieldSort.1 resultLevel then true
                       else psKernelLevelNormalizesToZero resultLevel) with
                  | false =>
                      simp [psKernelOpenSimpleConstructorFieldsWithFuel,
                        hCheck, hSort, hUniverse] at hRun
                  | true =>
                      let opened := psKernelSessionWithLocal fieldSort.2
                        userName (psKernelExprConsumeTypeAnnotations domain)
                        binderInfo
                      let field := PsKernelOpenBinder.mk opened.1 userName
                        (psKernelExprConsumeTypeAnnotations domain) binderInfo
                      cases hAnalysis : psKernelAnalyzeSimpleRecursiveArgument
                          remaining opened.2 target levels params numIndices domain with
                      | error message =>
                          simp [psKernelOpenSimpleConstructorFieldsWithFuel,
                            hCheck, hSort, hUniverse, opened, hAnalysis] at hRun
                      | ok analysis =>
                          have hCheckSound :=
                            psKernelSessionCheck_concrete_refines_typing
                              remaining hNative hString session domainType.2
                              domain domainType.1 hConfig hCheck
                          have hCheckContext :=
                            psKernelSessionCheck_success_preserves_context_core
                              remaining session domainType.2 domain domainType.1 hCheck
                          have hCheckConfig : PsKernelCheckerConfigurationSound
                              domainType.2.context domainType.2.state := by
                            simpa [hCheckContext] using hCheckSound.2
                          have hSortSound :=
                            psKernelSessionEnsureSort_concrete_refines_reduction
                              remaining hNative hString domainType.2 fieldSort.2
                              domainType.1 fieldSort.1 hCheckConfig hSort
                          have hSortContext :=
                            psKernelSessionEnsureSort_success_preserves_context_core
                              remaining domainType.2 fieldSort.2
                              domainType.1 fieldSort.1 hSort
                          have hSortConfig : PsKernelCheckerConfigurationSound
                              fieldSort.2.context fieldSort.2.state := by
                            simpa [hSortContext] using hSortSound.2
                          have hOpenedConfig : PsKernelCheckerConfigurationSound
                              opened.2.context opened.2.state :=
                            psKernelSessionWithLocal_preserves_configuration
                              fieldSort.2 userName
                              (psKernelExprConsumeTypeAnnotations domain)
                              binderInfo hString hSortConfig
                          have hAnalysisRun :
                              psKernelAnalyzeSimpleRecursiveArgumentWithFuel
                                (Nat.succ remaining) opened.2 target levels params
                                numIndices domain [] = Except.ok analysis := by
                            simpa [psKernelAnalyzeSimpleRecursiveArgument] using hAnalysis
                          have hHistory :=
                            psKernelAnalyzeSimpleRecursiveArgumentWithFuel_configuration_history_preserves
                              (Nat.succ remaining) hNative hString opened.2
                              target levels params numIndices domain [] analysis
                              hOpenedConfig hAnalysisRun
                          let child := psKernelSessionRestoreLocalScope
                            opened.2 analysis.session
                          let nextRecursive := match analysis.recursiveInfo with
                            | none => revRecursive
                            | some info =>
                                PsKernelSimpleRecursiveField.mk field info.1 info.2 ::
                                  revRecursive
                          have hChildConfig : PsKernelCheckerConfigurationSound
                              child.context child.state :=
                            psKernelSessionRestoreLocalScope_preserves_configuration
                              opened.2 analysis.session hOpenedConfig
                          have hTailRun :
                              psKernelOpenSimpleConstructorFieldsWithFuel
                                remaining child target levels params numIndices
                                resultLevel
                                (psKernelExprInstantiate1 body (PsKernelExpr.fvar opened.1))
                                (field :: revFields) nextRecursive = Except.ok result := by
                            simpa [psKernelOpenSimpleConstructorFieldsWithFuel,
                              hCheck, hSort, hUniverse, opened, field,
                              hAnalysis, child, nextRecursive] using hRun
                          rcases ih child target levels params numIndices resultLevel
                            (psKernelExprInstantiate1 body (PsKernelExpr.fvar opened.1))
                            (field :: revFields) nextRecursive result hChildConfig hTailRun
                            with ⟨fields, hFields, hSpine, hFinalConfig, hFinalEnv⟩
                          have hChildEnv :
                              child.context.environment = session.context.environment := by
                            simp [child, psKernelSessionRestoreLocalScope,
                              opened, psKernelSessionWithLocal,
                              psKernelCheckerContextWithLocalContext,
                              hSortContext, hCheckContext]
                          have hScopeHistory :
                              PsKernelLocalContextOrdinalHistoryExtends
                                opened.2.context.localContext child.context.localContext :=
                            psKernelSessionRestoreLocalScope_ordinal_history
                              opened.2 analysis.session hHistory.2.2
                          have hRest : PsKernelRawConstructorFieldSpineValid
                              session.context.environment resultLevel
                              opened.2.context.localContext
                              (psKernelExprInstantiate1 body (PsKernelExpr.fvar opened.1))
                              result.session.context.localContext fields result.result := by
                            apply PsKernelRawConstructorFieldSpineValid.ordinalHistory
                              opened.2.context.localContext child.context.localContext
                              result.session.context.localContext
                              (psKernelExprInstantiate1 body (PsKernelExpr.fvar opened.1))
                              result.result fields hScopeHistory
                            simpa [hChildEnv] using hSpine
                          have hDomain : PsKernelTypingJudgment
                              session.context.environment session.context.localContext
                              domain (PsKernelExpr.sort fieldSort.1) := by
                            apply PsKernelTypingJudgment.convert
                              domain domainType.1 (PsKernelExpr.sort fieldSort.1)
                            · exact hCheckSound.1
                            · apply PsKernelDefEqJudgment.reductionClosure
                              simpa [hCheckContext] using hSortSound.1
                          have hFresh := psKernelSessionWithLocal_fresh_absent
                            fieldSort.2 userName
                            (psKernelExprConsumeTypeAnnotations domain)
                            binderInfo hString hSortConfig
                          have hFreshOriginal : psKernelLocalContextFind
                              session.context.localContext opened.1 = none := by
                            simpa [opened, hSortContext, hCheckContext] using hFresh
                          have hAllowed :
                              psKernelLevelLe fieldSort.1 resultLevel = true ∨
                                psKernelLevelNormalizesToZero resultLevel = true := by
                            cases hLe : psKernelLevelLe fieldSort.1 resultLevel with
                            | true => exact Or.inl hLe
                            | false => exact Or.inr (by simpa [hLe] using hUniverse)
                          refine ⟨field :: fields, ?_, ?_, hFinalConfig,
                            Eq.trans hFinalEnv hChildEnv⟩
                          · exact Eq.trans hFields
                              (psKernelReverseOpenBinders_cons_append field revFields fields)
                          · apply PsKernelRawConstructorFieldSpineValid.cons
                              session.context.localContext result.session.context.localContext
                              opened.1 userName domain body result.result binderInfo
                              fieldSort.1 fields hFreshOriginal hDomain hAllowed
                            simpa [opened, psKernelSessionWithLocal,
                              psKernelCheckerContextWithLocalContext,
                              hSortContext, hCheckContext] using hRest
      | _ =>
          simp only [psKernelOpenSimpleConstructorFieldsWithFuel] at hRun
          cases hRun
          exact ⟨[], by simp,
            PsKernelRawConstructorFieldSpineValid.done _ _ (by rfl),
            hConfig, rfl⟩
