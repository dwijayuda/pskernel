import Ps.KernelCore.Metatheory.AdmissionMutualConstructorSemanticHistoryConfiguration
import Ps.KernelCore.Metatheory.AdmissionMutualInductiveIndexConfiguration

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
  obtain ⟨hTypeAbsent, _, _, _, _, _, hTypeRecCross, _⟩ :=
    psKernelAddSimpleMutualInductive_success_partitioned_name_guards
      fuel environment result decl maxRecDepth maxNatSize hIndex hRun
  have hShapeNames :=
    psKernelMutualShapes_source_name_provenance shapes decl.types hShapeDecls
  have hOriginalAbsent : PsKernelInductiveNamesAbsent environment
      (shapes.map (fun shape : PsKernelSimpleMutualTypeShape => shape.decl.name)) := by
    simpa only [hShapeNames] using hTypeAbsent
  have hWork0Semantic : PsKernelEnvironmentSemanticExtends environment
      (psKernelAddMutualInductiveInfos
        (psKernelMakeSimpleMutualBaseInfos
          (psKernelSimpleMutualNames decl.types) decl shapes) environment) :=
    hPrepared.2.1
  have hCtorSemantic : PsKernelEnvironmentSemanticExtends
      (psKernelAddMutualInductiveInfos
        (psKernelMakeSimpleMutualBaseInfos
          (psKernelSimpleMutualNames decl.types) decl shapes) environment)
      ctorResult.environment :=
    hHistory.semantic_extension hString
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
  exact ⟨shapes, ctorResult, hShapeDecls,
    hReplacedSemantic, hReplacedIndex, hRecAbsentAfter⟩
