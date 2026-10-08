import Ps.KernelCore.Metatheory.AdmissionRecursiveArgumentConfiguration
import Ps.KernelCore.Metatheory.AdmissionMutualOccurrenceConfiguration

/--
Mutual raw constructor fields carry independent checked domain typing, universe
guards, fresh allocation, scope restoration, and exact returned residuals.
Recursive-argument positivity is a separate semantic judgment.
-/
theorem psKernelOpenSimpleMutualConstructorFieldsWithFuel_raw_spine_refines
    (fuel : Nat)
    (hNative : PsKernelNativeReductionSoundLaw)
    (hString : PsKernelStringEqSoundLaw) :
    ∀ (session : PsKernelCheckerSession)
      (targets : List PsKernelName)
      (shapes : List PsKernelSimpleMutualTypeShape)
      (levels : List PsKernelLevel)
      (params : List PsKernelOpenBinder)
      (resultLevel : PsKernelLevel)
      (type : PsKernelExpr)
      (revFields : List PsKernelOpenBinder)
      (revRecursive : List PsKernelSimpleMutualRecursiveField)
      (result : PsKernelMutualOpenFieldsResult),
      PsKernelCheckerConfigurationSound session.context session.state ->
      psKernelOpenSimpleMutualConstructorFieldsWithFuel fuel session targets shapes levels
        params resultLevel type revFields revRecursive =
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
      intro session targets shapes levels params resultLevel type revFields
        revRecursive result hConfig hRun
      simp [psKernelOpenSimpleMutualConstructorFieldsWithFuel] at hRun
  | succ remaining ih =>
      intro session targets shapes levels params resultLevel type revFields
        revRecursive result hConfig hRun
      cases type with
      | forallE userName domain body binderInfo =>
          cases hCheck : psKernelSessionCheck remaining session domain with
          | error message =>
              simp [psKernelOpenSimpleMutualConstructorFieldsWithFuel, hCheck] at hRun
          | ok domainType =>
              cases hSort : psKernelSessionEnsureSort
                  remaining domainType.2 domainType.1 with
              | error message =>
                  simp [psKernelOpenSimpleMutualConstructorFieldsWithFuel,
                    hCheck, hSort] at hRun
              | ok fieldSort =>
                  cases hUniverse :
                      (if psKernelLevelLe fieldSort.1 resultLevel then true
                       else psKernelLevelNormalizesToZero resultLevel) with
                  | false =>
                      have hRejected := (psKernelBoolOrGuard_false_iff
                        (psKernelLevelLe fieldSort.1 resultLevel)
                        (psKernelLevelNormalizesToZero resultLevel)).mp hUniverse
                      simp [psKernelOpenSimpleMutualConstructorFieldsWithFuel,
                        hCheck, hSort, hRejected] at hRun
                  | true =>
                      have hAllowed := (psKernelBoolOrGuard_true_iff
                        (psKernelLevelLe fieldSort.1 resultLevel)
                        (psKernelLevelNormalizesToZero resultLevel)).mp hUniverse
                      let opened := psKernelSessionWithLocal fieldSort.2
                        userName (psKernelExprConsumeTypeAnnotations domain)
                        binderInfo
                      let field := PsKernelOpenBinder.mk opened.1 userName
                        (psKernelExprConsumeTypeAnnotations domain) binderInfo
                      cases hAnalysis : psKernelAnalyzeSimpleMutualRecursiveArgument
                          remaining opened.2 targets shapes levels params field domain with
                      | error message =>
                          simp [psKernelOpenSimpleMutualConstructorFieldsWithFuel,
                            hCheck, hSort, hAllowed, opened, hAnalysis] at hRun
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
                              psKernelAnalyzeSimpleMutualRecursiveArgumentWithFuel
                                (Nat.succ (psKernelExprNodeCount domain)) remaining
                                opened.2 targets shapes levels params field domain []
                                (PsKernelExpr.fvar field.internalName) = Except.ok analysis := by
                            simpa [psKernelAnalyzeSimpleMutualRecursiveArgument] using hAnalysis
                          have hHistory :=
                            psKernelAnalyzeSimpleMutualRecursiveArgumentWithFuel_configuration_history_preserves
                              (Nat.succ (psKernelExprNodeCount domain)) hNative hString remaining opened.2
                              targets shapes levels params field domain []
                              (PsKernelExpr.fvar field.internalName) analysis
                              hOpenedConfig hAnalysisRun
                          let child := psKernelSessionRestoreLocalScope
                            opened.2 analysis.session
                          let nextRecursive := match analysis.recursiveInfo with
                            | none => revRecursive
                            | some recursive => recursive :: revRecursive
                          have hChildConfig : PsKernelCheckerConfigurationSound
                              child.context child.state :=
                            psKernelSessionRestoreLocalScope_preserves_configuration
                              opened.2 analysis.session hOpenedConfig
                          have hTailRun :
                              psKernelOpenSimpleMutualConstructorFieldsWithFuel
                                remaining child targets shapes levels params
                                resultLevel
                                (psKernelExprInstantiate1 body (PsKernelExpr.fvar opened.1))
                                (field :: revFields) nextRecursive = Except.ok result := by
                            cases hInfo : analysis.recursiveInfo <;>
                              simpa [psKernelOpenSimpleMutualConstructorFieldsWithFuel,
                                hCheck, hSort, hAllowed, opened, field,
                                hAnalysis, child, nextRecursive,
                                hInfo] using hRun
                          rcases ih child targets shapes levels params resultLevel
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
          simp only [psKernelOpenSimpleMutualConstructorFieldsWithFuel] at hRun
          cases hRun
          exact ⟨[], by simp,
            PsKernelRawConstructorFieldSpineValid.done _ _ (by rfl),
            hConfig, rfl⟩
