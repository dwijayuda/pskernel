import Ps.KernelCore.Metatheory.AdmissionRecursiveArgumentConfiguration
import Ps.KernelCore.Metatheory.AdmissionMutualRecursiveArgumentConfiguration

def psKernelMutualRecursiveFieldHistoryPush
    (revRecursive : List PsKernelSimpleMutualRecursiveField)
    (info : Option PsKernelSimpleMutualRecursiveField) :
    List PsKernelSimpleMutualRecursiveField :=
  match info with
  | none => revRecursive
  | some recursive => recursive :: revRecursive

inductive PsKernelMutualConstructorFieldsValid
    (environment : PsKernelEnvironment)
    (targets : List PsKernelName)
    (shapes : List PsKernelSimpleMutualTypeShape)
    (levels : List PsKernelLevel)
    (params : List PsKernelOpenBinder)
    (resultLevel : PsKernelLevel) :
    PsKernelLocalContext -> PsKernelExpr ->
    List PsKernelOpenBinder -> List PsKernelSimpleMutualRecursiveField ->
    PsKernelLocalContext -> List PsKernelOpenBinder ->
    List PsKernelSimpleMutualRecursiveField -> PsKernelExpr -> Prop
  | done
      (localContext : PsKernelLocalContext) (type : PsKernelExpr)
      (revFields : List PsKernelOpenBinder)
      (revRecursive : List PsKernelSimpleMutualRecursiveField)
      (hTerminal : PsKernelRawConstructorPiHead type = false) :
      PsKernelMutualConstructorFieldsValid environment targets shapes levels params resultLevel localContext type revFields revRecursive
        localContext (psKernelReverseOpenBinders revFields)
        (psKernelReverseMutualRecursiveFields revRecursive) type
  | cons
      (localContext continuation finalContext : PsKernelLocalContext)
      (fresh userName : PsKernelName)
      (domain body residual : PsKernelExpr)
      (binderInfo : PsKernelBinderInfo)
      (fieldLevel : PsKernelLevel)
      (revFields fields : List PsKernelOpenBinder)
      (revRecursive recursiveFields : List PsKernelSimpleMutualRecursiveField)
      (info : Option PsKernelSimpleMutualRecursiveField)
      (hFresh : psKernelLocalContextFind localContext fresh = none)
      (hDomain : PsKernelTypingJudgment environment localContext domain
        (PsKernelExpr.sort fieldLevel))
      (hUniverse : psKernelLevelLe fieldLevel resultLevel = true ∨
        psKernelLevelNormalizesToZero resultLevel = true)
      (hPositive : PsKernelMutualRecursiveArgumentSafe
        environment targets shapes levels params
        (PsKernelOpenBinder.mk fresh userName
          (psKernelExprConsumeTypeAnnotations domain) binderInfo)
        (psKernelLocalContextAddLocal localContext fresh userName
          (psKernelExprConsumeTypeAnnotations domain) binderInfo)
        domain [] (PsKernelExpr.fvar fresh) info)
      (hHistory : PsKernelLocalContextOrdinalHistoryExtends
        (psKernelLocalContextAddLocal localContext fresh userName
          (psKernelExprConsumeTypeAnnotations domain) binderInfo) continuation)
      (hTail : PsKernelMutualConstructorFieldsValid
        environment targets shapes levels params resultLevel continuation
        (psKernelExprInstantiate1 body (PsKernelExpr.fvar fresh))
        (PsKernelOpenBinder.mk fresh userName
          (psKernelExprConsumeTypeAnnotations domain) binderInfo :: revFields)
        (psKernelMutualRecursiveFieldHistoryPush revRecursive info)
        finalContext fields recursiveFields residual) :
      PsKernelMutualConstructorFieldsValid environment targets shapes levels params resultLevel localContext
        (PsKernelExpr.forallE userName domain body binderInfo)
        revFields revRecursive finalContext fields recursiveFields residual

theorem psKernelOpenSimpleMutualConstructorFieldsWithFuel_raw_positive_spine_refines
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
        result.session.context.environment = session.context.environment ∧
        (PsKernelStringEqReflexiveLaw ->
          PsKernelMutualConstructorFieldsValid session.context.environment
            targets shapes levels params resultLevel session.context.localContext type
            revFields revRecursive result.session.context.localContext result.fields
            result.recursiveFields result.result) := by
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
                            hCheck, hSort, hAllowed, opened, field, hAnalysis] at hRun
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
                          let nextRecursive := psKernelMutualRecursiveFieldHistoryPush
                            revRecursive analysis.recursiveInfo
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
                                psKernelMutualRecursiveFieldHistoryPush, hInfo] using hRun
                          rcases ih child targets shapes levels params resultLevel
                            (psKernelExprInstantiate1 body (PsKernelExpr.fvar opened.1))
                            (field :: revFields) nextRecursive result hChildConfig hTailRun
                            with ⟨fields, hFields, hSpine, hFinalConfig, hFinalEnv, hFinalHistory⟩
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
                            Eq.trans hFinalEnv hChildEnv, ?_⟩
                          · exact Eq.trans hFields
                              (psKernelReverseOpenBinders_cons_append field revFields fields)
                          · apply PsKernelRawConstructorFieldSpineValid.cons
                              session.context.localContext result.session.context.localContext
                              opened.1 userName domain body result.result binderInfo
                              fieldSort.1 fields hFreshOriginal hDomain hAllowed
                            simpa [opened, psKernelSessionWithLocal,
                              psKernelCheckerContextWithLocalContext,
                              hSortContext, hCheckContext] using hRest

                          · intro hReflexive
                            have hPositive :=
                              psKernelAnalyzeSimpleMutualRecursiveArgumentWithFuel_semantic_refines
                                (Nat.succ (psKernelExprNodeCount domain)) hNative hString hReflexive
                                remaining opened.2 targets shapes levels params field domain []
                                (PsKernelExpr.fvar field.internalName) analysis hOpenedConfig hAnalysisRun
                            exact PsKernelMutualConstructorFieldsValid.cons
                              session.context.localContext child.context.localContext
                              result.session.context.localContext opened.1 userName
                              domain body result.result binderInfo fieldSort.1
                              revFields result.fields revRecursive result.recursiveFields
                              analysis.recursiveInfo hFreshOriginal hDomain hAllowed
                              (by simpa [opened, field, psKernelSessionWithLocal,
                                psKernelCheckerContextWithLocalContext,
                                hSortContext, hCheckContext] using hPositive)
                              (by simpa [opened, psKernelSessionWithLocal,
                                psKernelCheckerContextWithLocalContext,
                                hSortContext, hCheckContext] using hScopeHistory)
                              (by simpa [hChildEnv, field, nextRecursive]
                                using hFinalHistory hReflexive)

      | _ =>
          simp only [psKernelOpenSimpleMutualConstructorFieldsWithFuel] at hRun
          cases hRun
          exact ⟨[], by simp,
            PsKernelRawConstructorFieldSpineValid.done _ _ (by rfl),
            hConfig, rfl, fun _ =>
              PsKernelMutualConstructorFieldsValid.done _ _ _ _ (by rfl)⟩

/-- Preserve the original raw field-spine configuration interface. -/
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
  intro session targets shapes levels params resultLevel type revFields revRecursive result hConfig hRun
  obtain ⟨fields, hFields, hSpine, hFinalConfig, hEnv, hPositive⟩ :=
    psKernelOpenSimpleMutualConstructorFieldsWithFuel_raw_positive_spine_refines
      fuel hNative hString session targets shapes levels params resultLevel type
      revFields revRecursive result hConfig hRun
  exact ⟨fields, hFields, hSpine, hFinalConfig, hEnv⟩


/--
Independent mutual constructor shape under the caller's owner/header ordinal
invariant. Checked closed-header typing and family-name alignment remain
separate transaction components.
-/
def PsKernelMutualConstructorOpenShapeValid
    (environment : PsKernelEnvironment) (localContext : PsKernelLocalContext)
    (targets : List PsKernelName) (shapes : List PsKernelSimpleMutualTypeShape)
    (levels : List PsKernelLevel) (params : List PsKernelOpenBinder)
    (resultLevel : PsKernelLevel) (typeShape : PsKernelSimpleMutualTypeShape)
    (type : PsKernelExpr) (fields : List PsKernelOpenBinder)
    (recursiveFields : List PsKernelSimpleMutualRecursiveField)
    (indices : List PsKernelExpr) : Prop :=
  ∃ (afterParams residual : PsKernelExpr) (finalContext : PsKernelLocalContext),
    PsKernelRawConstructorParamSpineValid environment localContext params type afterParams ∧
    PsKernelRawConstructorFieldSpineValid environment resultLevel localContext afterParams
      finalContext fields residual ∧
    PsKernelMutualConstructorFieldsValid environment targets shapes levels params resultLevel
      localContext afterParams [] [] finalContext fields recursiveFields residual ∧
    psKernelExprGetAppFn residual = PsKernelExpr.const typeShape.decl.name levels ∧
    PsKernelConstructorResultParamPrefix params (psKernelExprGetAppArgs residual) indices ∧
    psKernelExprListLength indices = psKernelOpenBinderListLength typeShape.indices ∧
    (∀ target : PsKernelName, List.Mem target targets ->
      ∀ index : PsKernelExpr, List.Mem index indices ->
        PsKernelNoTargetConstantOccurrence target index)

theorem psKernelOpenSimpleMutualConstructor_shape_refines
    (fuel : Nat) (hNative : PsKernelNativeReductionSoundLaw)
    (hString : PsKernelStringEqSoundLaw)
    (hReflexive : PsKernelStringEqReflexiveLaw)
    (session : PsKernelCheckerSession)
    (targets : List PsKernelName) (shapes : List PsKernelSimpleMutualTypeShape)
    (levels : List PsKernelLevel) (params : List PsKernelOpenBinder)
    (resultLevel : PsKernelLevel) (typeShape : PsKernelSimpleMutualTypeShape)
    (owner : Nat) (type : PsKernelExpr)
    (afterParams : PsKernelExprSessionResult) (opened : PsKernelMutualOpenFieldsResult)
    (info : PsKernelSimpleMutualAppInfo)
    (hConfig : PsKernelCheckerConfigurationSound session.context session.state)
    (hOwnerShape : psKernelMutualTypeShapeListGet shapes owner = some typeShape)
    (hParams : psKernelOpenSimpleConstructorParams fuel session params type = Except.ok afterParams)
    (hFields : psKernelOpenSimpleMutualConstructorFields fuel afterParams.session targets
      shapes levels params resultLevel afterParams.result = Except.ok opened)
    (hResult : psKernelSimpleMutualAppInfo targets shapes levels params opened.result = some info)
    (hOwner : Nat.beq info.target owner = true) :
    PsKernelMutualConstructorOpenShapeValid session.context.environment session.context.localContext
      targets shapes levels params resultLevel typeShape type opened.fields opened.recursiveFields info.indices ∧
    PsKernelCheckerConfigurationSound opened.session.context opened.session.state ∧
    opened.session.context.environment = session.context.environment := by
  have hParamSound := psKernelOpenSimpleConstructorParams_raw_spine_refines
    fuel session params type afterParams hConfig hNative hString hParams
  have hParamConfig : PsKernelCheckerConfigurationSound
      afterParams.session.context afterParams.session.state := by
    simpa [hParamSound.2.1] using hParamSound.2.2
  obtain ⟨fields, hFieldsEq, hSpine, hFinalConfig, hFinalEnv, hPositive⟩ :=
    psKernelOpenSimpleMutualConstructorFieldsWithFuel_raw_positive_spine_refines
      (Nat.succ fuel) hNative hString afterParams.session targets shapes levels params
      resultLevel afterParams.result [] [] opened hParamConfig
      (by simpa [psKernelOpenSimpleMutualConstructorFields] using hFields)
  have hFieldsCanonical : opened.fields = fields := by
    simpa [psKernelReverseOpenBinders, psKernelReverseOpenBindersWorker] using hFieldsEq
  obtain ⟨selected, hSelected, hHead, hPrefix, hLength, hExcluded⟩ :=
    psKernelSimpleMutualAppInfo_semantic_shape hString hReflexive
      targets shapes levels params opened.result info hResult
  have hOwnerEq : info.target = owner := by simpa using hOwner
  have hSelectedEq : selected = typeShape := Option.some.inj
    (Eq.trans hSelected.symm (by simpa [hOwnerEq] using hOwnerShape))
  subst selected
  refine ⟨?_, hFinalConfig, ?_⟩
  · refine ⟨afterParams.result, opened.result, opened.session.context.localContext,
      hParamSound.1, ?_, ?_, hHead, hPrefix, hLength, hExcluded⟩
    · simpa [hParamSound.2.1, hFieldsCanonical] using hSpine
    · simpa [hParamSound.2.1] using hPositive hReflexive
  · exact Eq.trans hFinalEnv
      (congrArg PsKernelCheckerContext.environment hParamSound.2.1)
