import Ps.KernelCore.Metatheory.AdmissionHeaderSpineConfiguration
import Ps.KernelCore.Admission.Inductive.Mutual.Header
import Ps.KernelCore.Metatheory.AdmissionMutualOccurrenceConfiguration

/--
Independent remaining mutual header history. Remaining types consume raw
parameter Pi spines, as the executable path requires, then open their index
spines by checked reduction. Normalized universe equality and exact shape
provenance are recorded separately from later environment publication.
-/
inductive PsKernelCheckedMutualRemainingHeaderHistory
    (environment : PsKernelEnvironment) (headerLocal : PsKernelLocalContext)
    (params : List PsKernelOpenBinder) (resultLevel : PsKernelLevel) :
    List PsKernelSimpleMutualTypeDecl -> List PsKernelSimpleMutualTypeShape -> Prop where
  | nil : PsKernelCheckedMutualRemainingHeaderHistory environment headerLocal
      params resultLevel [] []
  | cons (decl : PsKernelSimpleMutualTypeDecl) (rest : List PsKernelSimpleMutualTypeDecl)
      (tail : List PsKernelSimpleMutualTypeShape)
      (headerLevel level : PsKernelLevel) (afterParams : PsKernelExpr)
      (indices : List PsKernelOpenBinder) (finalLocal : PsKernelLocalContext)
      (hTyping : PsKernelTypingJudgment environment psKernelLocalContextEmpty
        decl.type (PsKernelExpr.sort headerLevel))
      (hParams : PsKernelRawConstructorParamSpineValid environment headerLocal
        params decl.type afterParams)
      (hIndices : PsKernelCheckedHeaderBinderSpine environment headerLocal
        afterParams indices finalLocal (PsKernelExpr.sort level))
      (hLevel : psKernelLevelNormalize level = psKernelLevelNormalize resultLevel)
      (hRest : PsKernelCheckedMutualRemainingHeaderHistory environment headerLocal
        params resultLevel rest tail) :
      PsKernelCheckedMutualRemainingHeaderHistory environment headerLocal params resultLevel
        (decl :: rest) (PsKernelSimpleMutualTypeShape.mk decl indices :: tail)

theorem PsKernelCheckedMutualRemainingHeaderHistory.shape_provenance
    {environment : PsKernelEnvironment} {headerLocal : PsKernelLocalContext}
    {params : List PsKernelOpenBinder} {resultLevel : PsKernelLevel}
    {decls : List PsKernelSimpleMutualTypeDecl} {shapes : List PsKernelSimpleMutualTypeShape}
    (hHistory : PsKernelCheckedMutualRemainingHeaderHistory environment headerLocal
      params resultLevel decls shapes) :
    shapes.map PsKernelSimpleMutualTypeShape.decl = decls := by
  induction hHistory with
  | nil => rfl
  | cons decl rest tail headerLevel level afterParams indices finalLocal hTyping
      hParams hIndices hLevel hRest ih =>
      simpa using congrArg (List.cons decl) ih

theorem psKernelOpenSimpleMutualRemainingTypesWorker_header_history
    (types : List PsKernelSimpleMutualTypeDecl) :
    ∀ (fuel : Nat) (environment : PsKernelEnvironment)
      (levelParams : List PsKernelName) (safety : PsKernelDefinitionSafety)
      (maxRecDepth maxNatSize : Nat) (headerSession : PsKernelCheckerSession)
      (params : List PsKernelOpenBinder) (resultLevel : PsKernelLevel)
      (shapes : List PsKernelSimpleMutualTypeShape),
      PsKernelEnvironmentIndexRefines environment ->
      PsKernelCheckerConfigurationSound headerSession.context headerSession.state ->
      headerSession.context.environment = environment ->
      PsKernelNativeReductionSoundLaw -> PsKernelStringEqSoundLaw ->
      psKernelOpenSimpleMutualRemainingTypesWorker types fuel environment levelParams safety
        maxRecDepth maxNatSize headerSession params resultLevel = Except.ok shapes ->
      PsKernelCheckedMutualRemainingHeaderHistory environment headerSession.context.localContext
        params resultLevel types shapes := by
  induction types with
  | nil =>
      intro fuel environment levelParams safety maxRecDepth maxNatSize headerSession
        params resultLevel shapes hIndex hConfig hEnv hNative hString hRun
      simp [psKernelOpenSimpleMutualRemainingTypesWorker] at hRun
      cases hRun
      exact PsKernelCheckedMutualRemainingHeaderHistory.nil
  | cons typeDecl rest ih =>
      intro fuel environment levelParams safety maxRecDepth maxNatSize headerSession
        params resultLevel shapes hIndex hConfig hEnv hNative hString hRun
      simp only [psKernelOpenSimpleMutualRemainingTypesWorker] at hRun
      cases hClosed : psKernelCheckNoMVarNoFVar typeDecl.type with
      | error message => simp [hClosed] at hRun
      | ok closed =>
          simp only [hClosed] at hRun
          cases hLevels : psKernelCheckLevelParams typeDecl.type levelParams with
          | error message => simp [hLevels] at hRun
          | ok checkedLevels =>
              simp only [hLevels] at hRun
              let closedSession := psKernelMkCheckerSession environment levelParams safety
                maxRecDepth maxNatSize
              cases hCheck : psKernelSessionCheck fuel closedSession typeDecl.type with
              | error message =>
                  simp only [closedSession] at hCheck
                  simp [hCheck] at hRun
              | ok checked =>
                  simp only [closedSession] at hCheck
                  simp only [hCheck] at hRun
                  cases hSort : psKernelSessionEnsureSort fuel checked.2 checked.1 with
                  | error message => simp [hSort] at hRun
                  | ok sorted =>
                      simp only [hSort] at hRun
                      cases hParams : psKernelOpenSimpleConstructorParams fuel headerSession
                          params typeDecl.type with
                      | error message => simp [hParams] at hRun
                      | ok afterParams =>
                          simp only [hParams] at hRun
                          cases hIndices : psKernelOpenSimpleHeaderIndices fuel afterParams.session
                              afterParams.result with
                          | error message => simp [hIndices] at hRun
                          | ok indexResult =>
                              simp only [hIndices] at hRun
                              cases hShape : indexResult.result with
                              | sort level =>
                                  simp only [hShape] at hRun
                                  cases hLevel : psKernelLevelEquivalent level resultLevel with
                                  | false => simp [hLevel] at hRun
                                  | true =>
                                      simp only [hLevel] at hRun
                                      cases hTail : psKernelOpenSimpleMutualRemainingTypesWorker
                                          rest fuel environment levelParams safety maxRecDepth maxNatSize
                                          headerSession params resultLevel with
                                      | error message => simp [hTail] at hRun
                                      | ok tail =>
                                          simp only [hTail] at hRun
                                          have hInitial := psKernelMkCheckerSession_configuration_sound
                                            environment levelParams safety maxRecDepth maxNatSize hIndex
                                          have hTyping := psKernelSessionCheck_concrete_refines_typing
                                            fuel hNative hString closedSession checked.2 typeDecl.type checked.1
                                            hInitial hCheck
                                          have hCheckedContext := psKernelSessionCheck_success_preserves_context_core
                                            fuel closedSession checked.2 typeDecl.type checked.1 hCheck
                                          have hCheckedConfig : PsKernelCheckerConfigurationSound
                                              checked.2.context checked.2.state := by
                                            simpa [hCheckedContext] using hTyping.2
                                          have hSorted := psKernelSessionEnsureSort_concrete_refines_reduction
                                            fuel hNative hString checked.2 sorted.2 checked.1 sorted.1
                                            hCheckedConfig hSort
                                          have hHeaderTyping : PsKernelTypingJudgment environment psKernelLocalContextEmpty
                                              typeDecl.type (PsKernelExpr.sort sorted.1) := by
                                            apply PsKernelTypingJudgment.convert typeDecl.type checked.1
                                              (PsKernelExpr.sort sorted.1)
                                            · simpa [closedSession, psKernelMkCheckerSession,
                                                psKernelCheckerContextEmpty] using hTyping.1
                                            · apply PsKernelDefEqJudgment.reductionClosure
                                              simpa [hCheckedContext, closedSession, psKernelMkCheckerSession,
                                                psKernelCheckerContextEmpty] using hSorted.1
                                          have hParameterSound := psKernelOpenSimpleConstructorParams_raw_spine_refines
                                            fuel headerSession params typeDecl.type afterParams hConfig hNative hString hParams
                                          have hParameterConfig : PsKernelCheckerConfigurationSound
                                              afterParams.session.context afterParams.session.state := by
                                            simpa [hParameterSound.2.1] using hParameterSound.2.2
                                          have hIndexSound := psKernelOpenSimpleHeaderIndices_configuration_refines
                                            fuel hNative hString afterParams.session afterParams.result indexResult
                                            hParameterConfig hIndices
                                          have hNormalized := psKernelLevelEquivalent_sound_of_string_law
                                            hString level resultLevel hLevel
                                          have hRest := ih fuel environment levelParams safety maxRecDepth maxNatSize
                                            headerSession params resultLevel tail hIndex hConfig hEnv hNative hString hTail
                                          cases hRun
                                          exact PsKernelCheckedMutualRemainingHeaderHistory.cons typeDecl rest tail
                                            sorted.1 level afterParams.result indexResult.binders
                                            indexResult.session.context.localContext hHeaderTyping
                                            (by simpa [hEnv] using hParameterSound.1)
                                            (by simpa [hParameterSound.2.1, hEnv, hShape] using hIndexSound.2.2)
                                            hNormalized hRest
                              | _ => simp [hShape] at hRun

/-- Opened header shape names preserve the actual source declaration order. -/
theorem PsKernelCheckedMutualRemainingHeaderHistory.family_alignment
    {environment : PsKernelEnvironment} {headerLocal : PsKernelLocalContext}
    {params : List PsKernelOpenBinder} {resultLevel : PsKernelLevel}
    {decls : List PsKernelSimpleMutualTypeDecl} {shapes : List PsKernelSimpleMutualTypeShape}
    (hHistory : PsKernelCheckedMutualRemainingHeaderHistory environment headerLocal
      params resultLevel decls shapes) :
    PsKernelMutualFamilyNamesAligned (psKernelSimpleMutualNames decls) shapes := by
  induction hHistory with
  | nil => rfl
  | cons decl rest tail headerLevel level afterParams indices finalLocal hTyping
      hParams hIndices hLevel hRest ih =>
      simpa [PsKernelMutualFamilyNamesAligned, psKernelSimpleMutualNames]
        using congrArg (List.cons decl.name) ih

/-- The checked remaining-header shapes preserve all source type names in order. -/
theorem PsKernelCheckedMutualRemainingHeaderHistory.source_name_provenance
    {environment : PsKernelEnvironment} {headerLocal : PsKernelLocalContext}
    {params : List PsKernelOpenBinder} {resultLevel : PsKernelLevel}
    {decls : List PsKernelSimpleMutualTypeDecl}
    {shapes : List PsKernelSimpleMutualTypeShape}
    (hHistory : PsKernelCheckedMutualRemainingHeaderHistory environment headerLocal
      params resultLevel decls shapes) :
    shapes.map (fun shape : PsKernelSimpleMutualTypeShape => shape.decl.name) =
      psKernelSimpleMutualNames decls := by
  induction hHistory with
  | nil => rfl
  | cons decl rest tail headerLevel level afterParams indices finalLocal
      hTyping hParams hIndices hLevel hRest ih =>
      simpa [psKernelSimpleMutualNames] using congrArg (List.cons decl.name) ih
