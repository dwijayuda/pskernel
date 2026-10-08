
import Ps.KernelCore.Metatheory.AdmissionOrdinaryInductivePipelineConfiguration
import Ps.KernelCore.Metatheory.AdmissionUniformPreflightConfiguration

/-- Final datatype flags are determined by independently validated constructor shapes. -/
def psKernelOrdinaryFinalInductiveInfo
    (decl : PsKernelSimpleInductiveDecl) (indices : List PsKernelOpenBinder)
    (shapes : List PsKernelSimpleConstructorShape) : PsKernelInductiveInfo :=
  let initial := psKernelOrdinaryInitialInductiveInfo decl indices;
  PsKernelInductiveInfo.mk initial.base initial.numParams initial.numIndices
    initial.all initial.ctors initial.numNested (psKernelSimpleHasRecursiveFields shapes)
    (psKernelSimpleHasReflexiveFields shapes) initial.isUnsafe

/--
Independent full ordinary publication evidence: checked header/constructor/rule
semantics, elimination policy, exact generated recursor publication, canonical
lookup preservation, and runtime/Quot/index invariants.
This certificate does not independently discharge generated recursor universe
parameter freshness, and is not itself a complete environment well-formedness
theorem.
-/
def PsKernelOrdinaryInductiveTransactionValid
    (environment result : PsKernelEnvironment) (decl : PsKernelSimpleInductiveDecl) : Prop :=
  ∃ (headerLevel resultLevel : PsKernelLevel)
    (paramResult indexResult : PsKernelOpenBindersResult)
    (ctorResult : PsKernelAddConstructorsResult) (elimOnlyAtZero : Bool),
    PsKernelTypingJudgment environment psKernelLocalContextEmpty decl.type
      (PsKernelExpr.sort headerLevel) ∧
    PsKernelCheckedHeaderBinderSpine environment psKernelLocalContextEmpty decl.type
      paramResult.binders paramResult.session.context.localContext paramResult.result ∧
    PsKernelCheckedHeaderBinderSpine environment paramResult.session.context.localContext
      paramResult.result indexResult.binders indexResult.session.context.localContext
      (PsKernelExpr.sort resultLevel) ∧
    paramResult.binders.length = decl.numParams ∧
    PsKernelUniformOccurrencesSafe [decl.name] (psKernelLevelParamsToLevels decl.levelParams)
      decl.numParams (psKernelSimpleCtorTypes decl.ctors) ∧
    PsKernelCheckedOrdinaryConstructorHistory decl (psKernelLevelParamsToLevels decl.levelParams)
      paramResult.binders (psKernelOpenBinderListLength indexResult.binders) resultLevel
      paramResult.session.context.localContext
      (psKernelEnvironmentAddUnchecked environment (PsKernelConstantInfo.inductInfo
        (psKernelOrdinaryInitialInductiveInfo decl indexResult.binders)))
      0 decl.ctors ctorResult.shapes ctorResult.environment ∧
    PsKernelOrdinaryRecursorSuffixValid decl paramResult.binders ctorResult.shapes
      (psKernelOrdinaryPrepareRecursor decl paramResult indexResult resultLevel ctorResult
        elimOnlyAtZero) result ∧
    (elimOnlyAtZero = false ->
      PsKernelSimpleLargeEliminationPolicyValid
        (psKernelOrdinaryConstructorFinalEnvironment decl paramResult indexResult ctorResult)
        paramResult.session.context.localContext paramResult.binders resultLevel decl.ctors) ∧
    ((psKernelOrdinaryPrepareRecursor decl paramResult indexResult resultLevel ctorResult
        elimOnlyAtZero).info.k = true ->
      PsKernelSimpleKTargetPolicyValid resultLevel ctorResult.shapes) ∧
    PsKernelEnvironmentSemanticExtends environment result ∧
    result.runtime = environment.runtime ∧
    result.quotInitialized = environment.quotInitialized ∧
    PsKernelEnvironmentIndexRefines result

theorem psKernelAddSimpleInductive_success_transaction_refines
    (fuel : Nat) (environment result : PsKernelEnvironment)
    (decl : PsKernelSimpleInductiveDecl) (maxRecDepth maxNatSize : Nat)
    (hIndex : PsKernelEnvironmentIndexRefines environment)
    (hNative : PsKernelNativeReductionSoundLaw)
    (hString : PsKernelStringEqSoundLaw)
    (hReflexive : PsKernelStringEqReflexiveLaw)
    (hRun : psKernelAddSimpleInductive fuel environment decl maxRecDepth maxNatSize =
      Except.ok result) :
    PsKernelOrdinaryInductiveTransactionValid environment result decl := by
  obtain ⟨headerResult, sortResult, paramResult, indexResult, resultLevel, ctorResult,
    hHeader, hSort, hParams, hIndices, hResult, hCtors, hFinish⟩ :=
    psKernelAddSimpleInductive_success_full_pipeline
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

  have hHistory : PsKernelCheckedOrdinaryConstructorHistory decl
      (psKernelLevelParamsToLevels decl.levelParams) paramResult.binders
      (psKernelOpenBinderListLength indexResult.binders) resultLevel
      paramResult.session.context.localContext
      (psKernelEnvironmentAddUnchecked environment (PsKernelConstantInfo.inductInfo
        (psKernelOrdinaryInitialInductiveInfo decl indexResult.binders)))
      0 decl.ctors ctorResult.shapes ctorResult.environment := by
    simpa [hSortedEnv] using hPipeline.2.2.1
  have hFresh : psKernelFindConstantInList decl.name environment.constants = none ∧
      psKernelFindConstantInList (psKernelSimpleRecName decl.name) environment.constants = none := by
    cases hNames.2.2 with
    | cons _ _ hDecl hTail =>
        cases hTail with
        | cons _ _ hRec hCtors => exact ⟨hDecl, hRec⟩
  let replacement := psKernelOrdinaryFinalInductiveInfo decl indexResult.binders ctorResult.shapes
  have hMetadata := hHistory.final_metadata_refines hString hReflexive environment decl
    indexResult.binders (psKernelLevelParamsToLevels decl.levelParams) paramResult.binders
    resultLevel paramResult.session.context.localContext decl.ctors ctorResult.shapes
    ctorResult.environment replacement rfl hFresh.1 hPipeline.2.2.2.2
  let work1 := psKernelOrdinaryConstructorFinalEnvironment decl paramResult indexResult ctorResult
  have hWorkExt : PsKernelEnvironmentSemanticExtends environment work1 := by
    simpa [work1, psKernelOrdinaryConstructorFinalEnvironment, replacement,
      psKernelOrdinaryFinalInductiveInfo, psKernelOrdinaryInitialInductiveInfo] using hMetadata.1
  have hWorkIndex : PsKernelEnvironmentIndexRefines work1 := by
    simpa [work1, psKernelOrdinaryConstructorFinalEnvironment, replacement,
      psKernelOrdinaryFinalInductiveInfo, psKernelOrdinaryInitialInductiveInfo] using hMetadata.2
  have hParamSound := psKernelOpenSimpleHeaderParams_configuration_refines
    fuel decl.numParams hNative hString sortResult.2 decl.type paramResult hSortedConfig hParams
  have hParamEnv : paramResult.session.context.environment = environment := by
    simpa [hSortedEnv] using hParamSound.2.1
  have hElimConfig := psKernelSessionWithEnvironment_configuration_preserves
    paramResult.session work1 hWorkIndex
    (by simpa [hParamEnv] using hWorkExt) hParamSound.1
  obtain ⟨elimOnlyAtZero, hElim, hSuffix⟩ :=
    psKernelOrdinaryFinishAdmission_success_recursor_semantics fuel environment result decl
      maxRecDepth maxNatSize paramResult indexResult resultLevel ctorResult hWorkIndex
      hNative hString hFinish
  let prepared := psKernelOrdinaryPrepareRecursor decl paramResult indexResult
    resultLevel ctorResult elimOnlyAtZero
  have hPreparedEnv : prepared.environment = work1 :=
    psKernelOrdinaryPrepareRecursor_environment decl paramResult indexResult resultLevel
      ctorResult elimOnlyAtZero
  have hUniqueDecl := psKernelNameHasDuplicates_cons_false_refines decl.name
    (psKernelSimpleRecName decl.name :: psKernelSimpleCtorNames decl.ctors) hUnique
  have hUniqueRec := psKernelNameHasDuplicates_cons_false_refines
    (psKernelSimpleRecName decl.name) (psKernelSimpleCtorNames decl.ctors) hUniqueDecl.2
  have hNamesDifferent := psKernelNameListContains_false_excludes_equal hReflexive decl.name
    (psKernelSimpleRecName decl.name :: psKernelSimpleCtorNames decl.ctors)
    hUniqueDecl.1 (psKernelSimpleRecName decl.name) (List.Mem.head _)
  have hInsertRecFalse : psKernelNameEq decl.name (psKernelSimpleRecName decl.name) = false := by
    cases hEqual : psKernelNameEq decl.name (psKernelSimpleRecName decl.name) with
    | false => rfl
    | true => simp [psKernelNameListContains, hEqual] at hUniqueDecl
  have hRecInitial : psKernelFindConstantInList (psKernelSimpleRecName decl.name)
      (psKernelEnvironmentAddUnchecked environment (PsKernelConstantInfo.inductInfo
        (psKernelOrdinaryInitialInductiveInfo decl indexResult.binders))).constants = none := by
    simpa [psKernelEnvironmentAddUnchecked, psKernelFindConstantInList,
      psKernelConstantInfoName, psKernelConstantInfoBase, psKernelOrdinaryInitialInductiveInfo,
      hInsertRecFalse] using hFresh.2
  have hRecCtor := hHistory.preserves_reserved_name hString hReflexive
    (psKernelSimpleRecName decl.name) hRecInitial hUniqueRec.1
  have hRecWork : psKernelFindConstantInList (psKernelSimpleRecName decl.name) work1.constants = none := by
    change psKernelFindConstantInList (psKernelSimpleRecName decl.name)
      (psKernelReplaceEnvironmentConstant decl.name (PsKernelConstantInfo.inductInfo replacement)
        ctorResult.environment.constants) = none
    have hOther := psKernelReplaceEnvironmentConstant_preserves_other_lookup hString
      (PsKernelConstantInfo.inductInfo replacement) (psKernelSimpleRecName decl.name)
      hNamesDifferent ctorResult.environment.constants
    have hReplacementName :
        psKernelConstantInfoName (PsKernelConstantInfo.inductInfo replacement) = decl.name := rfl
    rw [hReplacementName] at hOther
    rw [hOther]
    exact hRecCtor
  have hResultExt : PsKernelEnvironmentSemanticExtends environment result := by
    rw [hSuffix.1]
    apply PsKernelEnvironmentSemanticExtends.trans environment prepared.environment _ _ _
    · simpa [hPreparedEnv] using hWorkExt
    · apply psKernelEnvironmentAddUnchecked_fresh_semantic_extends _ _ hString
      change psKernelFindConstantInList (psKernelSimpleRecName decl.name)
        prepared.environment.constants = none
      rw [hPreparedEnv]
      exact hRecWork
  have hExact := hHistory.exact_extension
  refine ⟨sortResult.1, resultLevel, paramResult, indexResult, ctorResult, elimOnlyAtZero,
    hHeaderTyping, ?_, ?_, psKernelOpenSimpleHeaderParams_success_length fuel sortResult.2
      decl.type decl.numParams paramResult hParams,
    psKernelAddSimpleInductive_success_uniform_occurrences_refines
      fuel environment result decl maxRecDepth maxNatSize hRun,
    hHistory, hSuffix, ?_, ?_, hResultExt, ?_, ?_, hSuffix.2.2.2.2⟩
  · simpa [hSortedEnv, hSortedLocal] using hPipeline.1
  · simpa [hSortedEnv] using hPipeline.2.1
  · intro hLarge
    have hPolicy := psKernelSimpleElimOnlyAtZero_false_semantic fuel hNative hString
      (psKernelSessionWithEnvironment paramResult.session work1) paramResult.binders
      resultLevel decl.ctors hElimConfig (by simpa [hLarge] using hElim)
    simpa [psKernelSessionWithEnvironment, psKernelCheckerContextWithEnvironment] using hPolicy
  · intro hK
    apply psKernelSimpleKTarget_true_semantic
    simpa [psKernelOrdinaryPrepareRecursor] using hK
  · rw [hSuffix.1]
    simpa [prepared, psKernelOrdinaryPrepareRecursor, psKernelEnvironmentAddUnchecked,
      psKernelEnvironmentReplaceUnchecked, PsKernelEnvironmentExtendsBy] using hExact.1.2
  · rw [hSuffix.1]
    simpa [prepared, psKernelOrdinaryPrepareRecursor, psKernelEnvironmentAddUnchecked,
      psKernelEnvironmentReplaceUnchecked] using hExact.2
