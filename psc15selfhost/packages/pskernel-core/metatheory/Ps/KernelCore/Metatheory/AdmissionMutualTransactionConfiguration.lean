import Ps.KernelCore.Metatheory.AdmissionMutualConstructorSemanticHistoryConfiguration
import Ps.KernelCore.Metatheory.AdmissionMutualInductiveIndexConfiguration

/-- Replacement composition for fixed source-shape and constructor witnesses.
This form lets the complete transaction share the exact executable witnesses. -/
theorem psKernelMutualConstructorReplacement_semantic_refines
    (fuel : Nat) (environment result : PsKernelEnvironment)
    (decl : PsKernelSimpleMutualInductiveDecl) (maxRecDepth maxNatSize : Nat)
    (shapes : List PsKernelSimpleMutualTypeShape)
    (ctorResult : PsKernelAddMutualConstructorsResult)
    (hIndex : PsKernelEnvironmentIndexRefines environment)
    (hString : PsKernelStringEqSoundLaw)
    (hRun : psKernelAddSimpleMutualInductive fuel environment decl
      maxRecDepth maxNatSize = Except.ok result)
    (hShapeDecls : shapes.map PsKernelSimpleMutualTypeShape.decl = decl.types)
    (hWork0Semantic : PsKernelEnvironmentSemanticExtends environment
      (psKernelAddMutualInductiveInfos
        (psKernelMakeSimpleMutualBaseInfos
          (psKernelSimpleMutualNames decl.types) decl shapes) environment))
    (hCtorSemantic : PsKernelEnvironmentSemanticExtends
      (psKernelAddMutualInductiveInfos
        (psKernelMakeSimpleMutualBaseInfos
          (psKernelSimpleMutualNames decl.types) decl shapes) environment)
      ctorResult.environment)
    (hCtorIndex : PsKernelEnvironmentIndexRefines ctorResult.environment)
    (hReserved : PsKernelInductiveNamesAbsent ctorResult.environment
      (shapes.map (fun shape : PsKernelSimpleMutualTypeShape =>
        psKernelSimpleRecName shape.decl.name))) :
      PsKernelEnvironmentSemanticExtends environment
        (psKernelReplaceMutualInductiveInfos
          (psKernelMakeSimpleMutualBaseInfos
            (psKernelSimpleMutualNames decl.types) decl shapes)
          (psKernelSimpleMutualHasRecursiveFields ctorResult.shapes)
          (psKernelSimpleMutualHasReflexiveFields ctorResult.shapes)
          ctorResult.environment) ∧
      PsKernelEnvironmentIndexRefines
        (psKernelReplaceMutualInductiveInfos
          (psKernelMakeSimpleMutualBaseInfos
            (psKernelSimpleMutualNames decl.types) decl shapes)
          (psKernelSimpleMutualHasRecursiveFields ctorResult.shapes)
          (psKernelSimpleMutualHasReflexiveFields ctorResult.shapes)
          ctorResult.environment) ∧
      PsKernelInductiveNamesAbsent
        (psKernelReplaceMutualInductiveInfos
          (psKernelMakeSimpleMutualBaseInfos
            (psKernelSimpleMutualNames decl.types) decl shapes)
          (psKernelSimpleMutualHasRecursiveFields ctorResult.shapes)
          (psKernelSimpleMutualHasReflexiveFields ctorResult.shapes)
          ctorResult.environment)
        (shapes.map (fun shape : PsKernelSimpleMutualTypeShape =>
          psKernelSimpleRecName shape.decl.name)) := by
  obtain ⟨hTypeAbsent, _, _, _, _, _, hTypeRecCross, _⟩ :=
    psKernelAddSimpleMutualInductive_success_partitioned_name_guards
      fuel environment result decl maxRecDepth maxNatSize hIndex hRun
  have hShapeNames :=
    psKernelMutualShapes_source_name_provenance shapes decl.types hShapeDecls
  have hOriginalAbsent : PsKernelInductiveNamesAbsent environment
      (shapes.map (fun shape : PsKernelSimpleMutualTypeShape => shape.decl.name)) := by
    simpa only [hShapeNames] using hTypeAbsent
  obtain ⟨hReplacedSemantic, hReplacedIndex⟩ :=
    psKernelPreparedMutualHeaderReplacement_semantic_refines
      (psKernelSimpleMutualNames decl.types) decl shapes
      environment ctorResult.environment
      (psKernelSimpleMutualHasRecursiveFields ctorResult.shapes)
      (psKernelSimpleMutualHasReflexiveFields ctorResult.shapes)
      hOriginalAbsent hString psKernelStringEq_reflexive
      hWork0Semantic hCtorSemantic hCtorIndex
  have hRecNames : shapes.map
      (fun shape : PsKernelSimpleMutualTypeShape =>
        psKernelSimpleRecName shape.decl.name) =
      psKernelSimpleMutualRecNames decl.types := by
    rw [psKernelMutualShapeRecursorNames_source, hShapeDecls]
  have hDisjoint : ∀ info : PsKernelInductiveInfo,
      List.Mem info
        (psKernelMakeSimpleMutualBaseInfos
          (psKernelSimpleMutualNames decl.types) decl shapes) ->
      ∀ recName : PsKernelName,
        List.Mem recName (shapes.map (fun shape : PsKernelSimpleMutualTypeShape =>
          psKernelSimpleRecName shape.decl.name)) ->
        recName ≠ info.base.name := by
    intro info hInfo recName hRec
    have hInfoName : List.Mem info.base.name
        (psKernelSimpleMutualNames decl.types) := by
      have hMember := psKernelMakeSimpleMutualBaseInfos_name_member
        (psKernelSimpleMutualNames decl.types) decl shapes info hInfo
      simpa only [hShapeNames] using hMember
    have hNotRec : psKernelNameListContains info.base.name
        (psKernelSimpleMutualRecNames decl.types) = false :=
      ((psKernelNameListContains_append_false info.base.name
        (psKernelSimpleMutualRecNames decl.types)
        (psKernelSimpleMutualCtorNames decl.types)).1
        (hTypeRecCross info.base.name hInfoName)).1
    exact (psKernelNameListContains_false_excludes_equal
      psKernelStringEq_reflexive info.base.name
        (psKernelSimpleMutualRecNames decl.types) hNotRec)
      recName (by simpa only [hRecNames] using hRec)
  have hRecAbsentAfter :=
    psKernelReplaceMutualInductiveInfos_preserves_absent_names
      (psKernelMakeSimpleMutualBaseInfos
        (psKernelSimpleMutualNames decl.types) decl shapes)
      (psKernelSimpleMutualHasRecursiveFields ctorResult.shapes)
      (psKernelSimpleMutualHasReflexiveFields ctorResult.shapes)
      hString (shapes.map (fun shape : PsKernelSimpleMutualTypeShape =>
        psKernelSimpleRecName shape.decl.name))
      ctorResult.environment hReserved hDisjoint
  exact ⟨hReplacedSemantic, hReplacedIndex, hRecAbsentAfter⟩

/--
The real successful mutual-admission constructor transaction supports safe
replacement of provisional datatype metadata.  The proof combines exact
checked constructor history, source-level type-name freshness, provisional
semantic extension, and canonical index refinement.  It retains only the
already specified native-reduction and positive StringEq laws and does not
assert the remaining recursor publication or complete environment typing.
-/
theorem psKernelAddSimpleMutualInductive_success_replacement_semantic_refines
    (fuel : Nat) (environment result : PsKernelEnvironment)
    (decl : PsKernelSimpleMutualInductiveDecl) (maxRecDepth maxNatSize : Nat)
    (hIndex : PsKernelEnvironmentIndexRefines environment)
    (hNative : PsKernelNativeReductionSoundLaw)
    (hString : PsKernelStringEqSoundLaw)
    (hRun : psKernelAddSimpleMutualInductive fuel environment decl
      maxRecDepth maxNatSize = Except.ok result) :
    ∃ (shapes : List PsKernelSimpleMutualTypeShape)
      (ctorResult : PsKernelAddMutualConstructorsResult),
      shapes.map PsKernelSimpleMutualTypeShape.decl = decl.types ∧
      PsKernelEnvironmentSemanticExtends environment
        (psKernelReplaceMutualInductiveInfos
          (psKernelMakeSimpleMutualBaseInfos
            (psKernelSimpleMutualNames decl.types) decl shapes)
          (psKernelSimpleMutualHasRecursiveFields ctorResult.shapes)
          (psKernelSimpleMutualHasReflexiveFields ctorResult.shapes)
          ctorResult.environment) ∧
      PsKernelEnvironmentIndexRefines
        (psKernelReplaceMutualInductiveInfos
          (psKernelMakeSimpleMutualBaseInfos
            (psKernelSimpleMutualNames decl.types) decl shapes)
          (psKernelSimpleMutualHasRecursiveFields ctorResult.shapes)
          (psKernelSimpleMutualHasReflexiveFields ctorResult.shapes)
          ctorResult.environment) ∧
      PsKernelInductiveNamesAbsent
        (psKernelReplaceMutualInductiveInfos
          (psKernelMakeSimpleMutualBaseInfos
            (psKernelSimpleMutualNames decl.types) decl shapes)
          (psKernelSimpleMutualHasRecursiveFields ctorResult.shapes)
          (psKernelSimpleMutualHasReflexiveFields ctorResult.shapes)
          ctorResult.environment)
        (shapes.map (fun shape : PsKernelSimpleMutualTypeShape =>
          psKernelSimpleRecName shape.decl.name)) := by
  obtain ⟨shapes, headerSession, params, resultLevel, ctorResult, added,
    hShapeDecls, hHeaderConfig, hHeaderEnv, hPrepared, hCtorRun,
    hHistory, hSemantic, hCtorIndex, hReserved, hAdded, hQuot, hNames⟩ :=
    psKernelAddSimpleMutualInductive_success_constructor_stage_refines
      fuel environment result decl maxRecDepth maxNatSize
      hIndex hNative hString hRun
  obtain ⟨hSemantic, hIndexAfter, hReservedAfter⟩ :=
    psKernelMutualConstructorReplacement_semantic_refines
      fuel environment result decl maxRecDepth maxNatSize shapes ctorResult
      hIndex hString hRun hShapeDecls hPrepared.2.1
      (hHistory.semantic_extension hString) hCtorIndex hReserved
  exact ⟨shapes, ctorResult, hShapeDecls, hSemantic, hIndexAfter, hReservedAfter⟩

/--
Provisional datatype-header insertion is structurally runtime- and
quotient-transparent, independent of the index representation and semantic
lookup assumptions.
-/
theorem psKernelAddMutualInductiveInfos_preserves_runtime_quot
    (infos : List PsKernelInductiveInfo) :
    ∀ environment : PsKernelEnvironment,
      (psKernelAddMutualInductiveInfos infos environment).runtime =
        environment.runtime ∧
      (psKernelAddMutualInductiveInfos infos environment).quotInitialized =
        environment.quotInitialized := by
  induction infos with
  | nil => intro environment; exact ⟨rfl, rfl⟩
  | cons info rest ih =>
      intro environment
      have hTail := ih (psKernelEnvironmentAddUnchecked environment
        (PsKernelConstantInfo.inductInfo info))
      simpa [psKernelAddMutualInductiveInfos, psKernelEnvironmentAddUnchecked] using hTail

/--
Updating datatype metadata never mutates runtime capabilities or initialized
Quot semantics. This is proved over every actual replacement step, not assumed
from generic environment extension.
-/
theorem psKernelReplaceMutualInductiveInfos_preserves_runtime_quot
    (infos : List PsKernelInductiveInfo) (isRecursive isReflexive : Bool) :
    ∀ environment : PsKernelEnvironment,
      (psKernelReplaceMutualInductiveInfos infos isRecursive isReflexive environment).runtime =
        environment.runtime ∧
      (psKernelReplaceMutualInductiveInfos infos isRecursive isReflexive environment).quotInitialized =
        environment.quotInitialized := by
  induction infos with
  | nil => intro environment; exact ⟨rfl, rfl⟩
  | cons info rest ih =>
      intro environment
      let finalInfo := PsKernelInductiveInfo.mk info.base info.numParams info.numIndices
        info.all info.ctors info.numNested isRecursive isReflexive info.isUnsafe
      have hTail := ih (psKernelEnvironmentReplaceUnchecked environment
        (PsKernelConstantInfo.inductInfo finalInfo))
      simpa [psKernelReplaceMutualInductiveInfos, psKernelEnvironmentReplaceUnchecked,
        finalInfo] using hTail

/--
Successful actual mutual constructor admission and metadata replacement
preserves runtime and quotient initialization exactly. Checked constructor
publication supplies the intermediate runtime/Quot equalities.
-/
theorem psKernelAddSimpleMutualInductive_success_replacement_runtime_quot
    (fuel : Nat) (environment result : PsKernelEnvironment)
    (decl : PsKernelSimpleMutualInductiveDecl) (maxRecDepth maxNatSize : Nat)
    (hIndex : PsKernelEnvironmentIndexRefines environment)
    (hNative : PsKernelNativeReductionSoundLaw)
    (hString : PsKernelStringEqSoundLaw)
    (hRun : psKernelAddSimpleMutualInductive fuel environment decl
      maxRecDepth maxNatSize = Except.ok result) :
    ∃ (shapes : List PsKernelSimpleMutualTypeShape)
      (ctorResult : PsKernelAddMutualConstructorsResult),
      shapes.map PsKernelSimpleMutualTypeShape.decl = decl.types ∧
      (psKernelReplaceMutualInductiveInfos
        (psKernelMakeSimpleMutualBaseInfos
          (psKernelSimpleMutualNames decl.types) decl shapes)
        (psKernelSimpleMutualHasRecursiveFields ctorResult.shapes)
        (psKernelSimpleMutualHasReflexiveFields ctorResult.shapes)
        ctorResult.environment).runtime = environment.runtime ∧
      (psKernelReplaceMutualInductiveInfos
        (psKernelMakeSimpleMutualBaseInfos
          (psKernelSimpleMutualNames decl.types) decl shapes)
        (psKernelSimpleMutualHasRecursiveFields ctorResult.shapes)
        (psKernelSimpleMutualHasReflexiveFields ctorResult.shapes)
        ctorResult.environment).quotInitialized = environment.quotInitialized := by
  obtain ⟨shapes, headerSession, params, resultLevel, ctorResult, added,
    hShapeDecls, hHeaderConfig, hHeaderEnv, hPrepared, hCtorRun,
    hHistory, hSemantic, hCtorIndex, hReserved, hAdded, hQuot, hNames⟩ :=
    psKernelAddSimpleMutualInductive_success_constructor_stage_refines
      fuel environment result decl maxRecDepth maxNatSize
      hIndex hNative hString hRun
  let infos := psKernelMakeSimpleMutualBaseInfos
    (psKernelSimpleMutualNames decl.types) decl shapes
  have hHeaderFold := psKernelAddMutualInductiveInfos_preserves_runtime_quot
    infos environment
  have hReplaceFold := psKernelReplaceMutualInductiveInfos_preserves_runtime_quot
    infos (psKernelSimpleMutualHasRecursiveFields ctorResult.shapes)
    (psKernelSimpleMutualHasReflexiveFields ctorResult.shapes) ctorResult.environment
  exact ⟨shapes, ctorResult, hShapeDecls,
    hReplaceFold.1.trans (hAdded.2.trans hHeaderFold.1),
    hReplaceFold.2.trans (hQuot.trans hHeaderFold.2)⟩
