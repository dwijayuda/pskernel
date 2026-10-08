import Ps.KernelCore.Metatheory.AdmissionParameterConfiguration
import Ps.KernelCore.Metatheory.AdmissionConstructorSemanticHistoryConfiguration

/--
Exact successful checked prefix of ordinary admission. This executable
projection is composed with independent semantic contracts below; it is not
itself a well-formed environment certificate.
-/
theorem psKernelAddSimpleInductive_success_constructor_pipeline
    (fuel : Nat) (environment result : PsKernelEnvironment)
    (decl : PsKernelSimpleInductiveDecl) (maxRecDepth maxNatSize : Nat)
    (hRun : psKernelAddSimpleInductive fuel environment decl maxRecDepth maxNatSize =
      Except.ok result) :
    ∃ (headerResult : PsKernelExpr × PsKernelCheckerSession)
      (sortResult : PsKernelLevel × PsKernelCheckerSession)
      (paramResult indexResult : PsKernelOpenBindersResult)
      (resultLevel : PsKernelLevel) (ctorResult : PsKernelAddConstructorsResult),
      psKernelSessionCheck fuel
        (psKernelMkCheckerSession environment decl.levelParams
          (if decl.isUnsafe then PsKernelDefinitionSafety.unsafeDef else PsKernelDefinitionSafety.safe)
          maxRecDepth maxNatSize) decl.type = Except.ok headerResult ∧
      psKernelSessionEnsureSort fuel headerResult.2 headerResult.1 = Except.ok sortResult ∧
      psKernelOpenSimpleHeaderParams fuel sortResult.2 decl.type decl.numParams = Except.ok paramResult ∧
      psKernelOpenSimpleHeaderIndices fuel paramResult.session paramResult.result = Except.ok indexResult ∧
      indexResult.result = PsKernelExpr.sort resultLevel ∧
      psKernelAddSimpleConstructorsWithFuel (Nat.succ fuel) decl
        (if decl.isUnsafe then PsKernelDefinitionSafety.unsafeDef else PsKernelDefinitionSafety.safe)
        resultLevel (psKernelLevelParamsToLevels decl.levelParams) paramResult.binders
        (psKernelOpenBinderListLength indexResult.binders) paramResult.session
        (psKernelEnvironmentAddUnchecked environment (PsKernelConstantInfo.inductInfo
          (psKernelOrdinaryInitialInductiveInfo decl indexResult.binders)))
        0 decl.ctors = Except.ok ctorResult := by
  let allNames : List PsKernelName :=
    List.cons decl.name
      (List.cons
        (psKernelSimpleRecName decl.name)
        (psKernelSimpleCtorNames decl.ctors))
  cases hDuplicates :
      psKernelNameHasDuplicates decl.levelParams with
  | true =>
      simp [psKernelAddSimpleInductive, hDuplicates] at hRun
  | false =>
      cases hUnique :
          psKernelSimpleNameListUnique allNames with
      | false =>
          simp [
            psKernelAddSimpleInductive,
            hDuplicates, allNames, hUnique
          ] at hRun
      | true =>
          cases hFresh :
              psKernelCheckFreshInductiveNames
                allNames environment with
          | error message =>
              simp [
                psKernelAddSimpleInductive,
                hDuplicates, allNames, hUnique, hFresh
              ] at hRun
          | ok fresh =>
              cases hOccurrences :
                  psKernelSimpleCheckUniformOccurrences
                    (List.cons decl.name List.nil)
                    decl.levelParams
                    decl.numParams
                    (psKernelSimpleCtorTypes decl.ctors) with
              | error message =>
                  simp [
                    psKernelAddSimpleInductive,
                    hDuplicates, allNames, hUnique,
                    hFresh, hOccurrences
                  ] at hRun
              | ok checkedOccurrences =>
                  cases hClosed :
                      psKernelCheckNoMVarNoFVar decl.type with
                  | error message =>
                      simp [
                        psKernelAddSimpleInductive,
                        hDuplicates, allNames, hUnique,
                        hFresh, hOccurrences, hClosed
                      ] at hRun
                  | ok closed =>
                      cases hLevels :
                          psKernelCheckLevelParams
                            decl.type decl.levelParams with
                      | error message =>
                          simp [
                            psKernelAddSimpleInductive,
                            hDuplicates, allNames, hUnique,
                            hFresh, hOccurrences,
                            hClosed, hLevels
                          ] at hRun
                      | ok checkedLevels =>
                          let safety :=
                            if decl.isUnsafe then
                              PsKernelDefinitionSafety.unsafeDef
                            else
                              PsKernelDefinitionSafety.safe
                          let headerSession :=
                            psKernelMkCheckerSession
                              environment decl.levelParams
                              safety maxRecDepth maxNatSize
                          cases hHeader :
                              psKernelSessionCheck
                                fuel
                                (psKernelMkCheckerSession
                                  environment decl.levelParams
                                  (if decl.isUnsafe then
                                    PsKernelDefinitionSafety.unsafeDef
                                   else
                                    PsKernelDefinitionSafety.safe)
                                  maxRecDepth maxNatSize)
                                decl.type with
                          | error message =>
                              simp [
                                psKernelAddSimpleInductive,
                                hDuplicates, allNames, hUnique,
                                hFresh, hOccurrences,
                                hClosed, hLevels, hHeader
                              ] at hRun
                          | ok headerResult =>
                              cases hSort :
                                  psKernelSessionEnsureSort
                                    fuel
                                    (Prod.snd headerResult)
                                    (Prod.fst headerResult) with
                              | error message =>
                                  simp [
                                    psKernelAddSimpleInductive,
                                    hDuplicates, allNames, hUnique,
                                    hFresh, hOccurrences,
                                    hClosed, hLevels, hHeader,
                                    hSort
                                  ] at hRun
                              | ok sortResult =>
                                  cases hParams : psKernelOpenSimpleHeaderParams fuel
                                      sortResult.2 decl.type decl.numParams with
                                  | error message =>
                                      simp [psKernelAddSimpleInductive, hDuplicates, allNames, hUnique,
                                        hFresh, hOccurrences, hClosed, hLevels, hHeader, hSort, hParams] at hRun
                                  | ok paramResult =>
                                      cases hIndices : psKernelOpenSimpleHeaderIndices fuel
                                          paramResult.session paramResult.result with
                                      | error message =>
                                          simp [psKernelAddSimpleInductive, hDuplicates, allNames, hUnique,
                                            hFresh, hOccurrences, hClosed, hLevels, hHeader, hSort,
                                            hParams, hIndices] at hRun
                                      | ok indexResult =>
                                          cases hShape : indexResult.result with
                                          | sort resultLevel =>
                                              cases hCtors : psKernelAddSimpleConstructorsWithFuel
                                                  (Nat.succ fuel) decl safety resultLevel
                                                  (psKernelLevelParamsToLevels decl.levelParams)
                                                  paramResult.binders
                                                  (psKernelOpenBinderListLength indexResult.binders)
                                                  paramResult.session
                                                  (psKernelEnvironmentAddUnchecked environment
                                                    (PsKernelConstantInfo.inductInfo
                                                      (psKernelOrdinaryInitialInductiveInfo decl indexResult.binders)))
                                                  0 decl.ctors with
                                              | error message =>
                                                  simp only [safety, psKernelOrdinaryInitialInductiveInfo,
                                                    Nat.succ_eq_add_one] at hCtors
                                                  simp [psKernelAddSimpleInductive, hDuplicates,
                                                    allNames, hUnique, hFresh, hOccurrences, hClosed,
                                                    hLevels, hHeader, hSort, hParams, hIndices, hShape,
                                                    psKernelOrdinaryInitialInductiveInfo, safety, hCtors] at hRun
                                              | ok ctorResult =>
                                                  exact ⟨headerResult, sortResult, paramResult, indexResult,
                                                    resultLevel, ctorResult, rfl, rfl, rfl,
                                                    rfl, rfl, hCtors⟩
                                          | _ =>
                                              simp [psKernelAddSimpleInductive, hDuplicates, allNames, hUnique,
                                                hFresh, hOccurrences, hClosed, hLevels, hHeader, hSort,
                                                hParams, hIndices, hShape] at hRun


/--
Independent ordinary inductive header/constructor certificate. It records
semantic typing, binder spines, strict-positive constructor publication history,
and canonical environment preservation. Recursor/final metadata publication is
a separate remaining transaction obligation.
-/
def PsKernelOrdinaryInductiveConstructorPrefixValid
    (environment : PsKernelEnvironment) (decl : PsKernelSimpleInductiveDecl) : Prop :=
  ∃ (headerLevel resultLevel : PsKernelLevel)
    (params indices : List PsKernelOpenBinder)
    (parameterLocal indexLocal : PsKernelLocalContext)
    (afterParams : PsKernelExpr)
    (ctorEnvironment : PsKernelEnvironment)
    (shapes : List PsKernelSimpleConstructorShape),
    PsKernelTypingJudgment environment psKernelLocalContextEmpty decl.type
      (PsKernelExpr.sort headerLevel) ∧
    PsKernelCheckedHeaderBinderSpine environment psKernelLocalContextEmpty decl.type
      params parameterLocal afterParams ∧
    PsKernelCheckedHeaderBinderSpine environment parameterLocal afterParams
      indices indexLocal (PsKernelExpr.sort resultLevel) ∧
    params.length = decl.numParams ∧
    PsKernelCheckedOrdinaryConstructorHistory decl
      (psKernelLevelParamsToLevels decl.levelParams) params
      (psKernelOpenBinderListLength indices) resultLevel parameterLocal
      (psKernelEnvironmentAddUnchecked environment (PsKernelConstantInfo.inductInfo
        (psKernelOrdinaryInitialInductiveInfo decl indices)))
      0 decl.ctors shapes ctorEnvironment ∧
    PsKernelEnvironmentSemanticExtends environment ctorEnvironment ∧
    PsKernelEnvironmentIndexRefines ctorEnvironment

theorem psKernelAddSimpleInductive_success_constructor_semantics
    (fuel : Nat) (environment result : PsKernelEnvironment)
    (decl : PsKernelSimpleInductiveDecl) (maxRecDepth maxNatSize : Nat)
    (hIndex : PsKernelEnvironmentIndexRefines environment)
    (hNative : PsKernelNativeReductionSoundLaw)
    (hString : PsKernelStringEqSoundLaw)
    (hReflexive : PsKernelStringEqReflexiveLaw)
    (hRun : psKernelAddSimpleInductive fuel environment decl maxRecDepth maxNatSize =
      Except.ok result) :
    PsKernelOrdinaryInductiveConstructorPrefixValid environment decl := by
  obtain ⟨headerResult, sortResult, paramResult, indexResult, resultLevel, ctorResult,
    hHeader, hSort, hParams, hIndices, hResult, hCtors⟩ :=
    psKernelAddSimpleInductive_success_constructor_pipeline
      fuel environment result decl maxRecDepth maxNatSize hRun
  have hNames := psKernelAddSimpleInductive_success_name_guards
    fuel environment result decl maxRecDepth maxNatSize hIndex hRun
  have hUnique := psKernelSimpleNameListUnique_true_no_duplicates _ hNames.2.1
  let safety := if decl.isUnsafe then PsKernelDefinitionSafety.unsafeDef
    else PsKernelDefinitionSafety.safe
  let initial := psKernelMkCheckerSession environment decl.levelParams safety maxRecDepth maxNatSize
  have hInitial := psKernelMkCheckerSession_configuration_sound
    environment decl.levelParams safety maxRecDepth maxNatSize hIndex
  have hTyped := psKernelSessionCheck_concrete_refines_typing
    fuel hNative hString initial headerResult.2 decl.type headerResult.1 hInitial hHeader
  have hCheckedContext := psKernelSessionCheck_success_preserves_context_core
    fuel initial headerResult.2 decl.type headerResult.1 hHeader
  have hCheckedConfig : PsKernelCheckerConfigurationSound
      headerResult.2.context headerResult.2.state := by
    simpa [hCheckedContext] using hTyped.2
  have hSorted := psKernelSessionEnsureSort_concrete_refines_reduction
    fuel hNative hString headerResult.2 sortResult.2 headerResult.1 sortResult.1
    hCheckedConfig hSort
  have hSortedContext := psKernelSessionEnsureSort_success_preserves_context_core
    fuel headerResult.2 sortResult.2 headerResult.1 sortResult.1 hSort
  have hFinalContext : sortResult.2.context = initial.context :=
    Eq.trans hSortedContext hCheckedContext
  have hSortedConfig : PsKernelCheckerConfigurationSound sortResult.2.context sortResult.2.state := by
    simpa [hSortedContext] using hSorted.2
  have hSortedEnv : sortResult.2.context.environment = environment := by
    simp [hFinalContext, initial, psKernelMkCheckerSession, psKernelCheckerContextEmpty]
  have hSortedLocal : sortResult.2.context.localContext = psKernelLocalContextEmpty := by
    simp [hFinalContext, initial, psKernelMkCheckerSession, psKernelCheckerContextEmpty]
  have hPipeline := psKernelOrdinaryHeaderConstructorPipeline_configuration_refines
    fuel hNative hString hReflexive decl safety sortResult.2 paramResult indexResult
    resultLevel ctorResult hSortedConfig
    (by simpa [hSortedEnv] using hNames.2.2)
    hUnique hParams hIndices hResult
    (by simpa [hSortedEnv] using hCtors)
  have hHeaderTyping : PsKernelTypingJudgment environment psKernelLocalContextEmpty
      decl.type (PsKernelExpr.sort sortResult.1) := by
    apply PsKernelTypingJudgment.convert decl.type headerResult.1 (PsKernelExpr.sort sortResult.1)
    · simpa [initial, psKernelMkCheckerSession, psKernelCheckerContextEmpty] using hTyped.1
    · apply PsKernelDefEqJudgment.reductionClosure
      simpa [hCheckedContext, initial, psKernelMkCheckerSession, psKernelCheckerContextEmpty]
        using hSorted.1
  refine ⟨sortResult.1, resultLevel, paramResult.binders, indexResult.binders,
    paramResult.session.context.localContext, indexResult.session.context.localContext,
    paramResult.result, ctorResult.environment, ctorResult.shapes, hHeaderTyping, ?_, ?_,
    psKernelOpenSimpleHeaderParams_success_length fuel sortResult.2 decl.type decl.numParams
      paramResult hParams, ?_, ?_, hPipeline.2.2.2.2⟩
  · simpa [hSortedEnv, hSortedLocal] using hPipeline.1
  · simpa [hSortedEnv] using hPipeline.2.1
  · simpa [hSortedEnv] using hPipeline.2.2.1
  · simpa [hSortedEnv] using hPipeline.2.2.2.1
