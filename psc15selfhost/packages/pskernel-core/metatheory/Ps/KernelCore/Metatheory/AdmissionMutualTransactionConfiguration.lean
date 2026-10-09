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
          ctorResult.environment) := by
  obtain ⟨shapes, headerSession, params, resultLevel, ctorResult, added,
    hShapeDecls, hHeaderConfig, hHeaderEnv, hPrepared, hCtorRun,
    hHistory, hSemantic, hCtorIndex, hReserved, hAdded, hQuot, hNames⟩ :=
    psKernelAddSimpleMutualInductive_success_constructor_stage_refines
      fuel environment result decl maxRecDepth maxNatSize
      hIndex hNative hString hRun
  obtain ⟨hTypeAbsent, _, _, _, _, _, _, _⟩ :=
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
  exact ⟨shapes, ctorResult, hShapeDecls,
    hReplacedSemantic, hReplacedIndex⟩
