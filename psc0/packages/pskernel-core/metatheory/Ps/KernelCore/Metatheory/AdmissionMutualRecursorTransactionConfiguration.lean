import Ps.KernelCore.Metatheory.AdmissionMutualTransactionConfiguration
import Ps.KernelCore.Metatheory.AdmissionMutualRecursorPublicationConfiguration

/--
Every successful source mutual admission has independently unique universe
parameters for either generated elimination policy.  In the nonzero
elimination policy the generated name is fresh by the specified string
comparator/candidate proof; no extra primitive or reflexivity law is assumed.
-/
theorem psKernelAddSimpleMutualInductive_success_recursor_universes_nodup
    (fuel : Nat) (environment result : PsKernelEnvironment)
    (decl : PsKernelSimpleMutualInductiveDecl)
    (maxRecDepth maxNatSize : Nat) (elimOnlyAtZero : Bool)
    (hIndex : PsKernelEnvironmentIndexRefines environment)
    (hString : PsKernelStringEqSoundLaw)
    (hRun : psKernelAddSimpleMutualInductive fuel environment decl
      maxRecDepth maxNatSize = Except.ok result) :
    (if elimOnlyAtZero then decl.levelParams else
      psKernelSimpleFreshElimName decl.levelParams :: decl.levelParams).Nodup := by
  have hLevelNames := (psKernelAddSimpleMutualInductive_success_name_guards
    fuel environment result decl maxRecDepth maxNatSize hIndex hRun).1
  exact psKernelFreshEliminationUniverses_nodup
    hString decl.levelParams hLevelNames elimOnlyAtZero

/--
Post-replacement generated mutual recursor publication. The proof composes
exact source-shape provenance, actual generated rule/recursor metadata,
independent checked recursor typing, existing canonical environment semantics,
and preserved indexes.

The executable-build and validation equalities are deliberately explicit:
the enclosing final mutual transaction must extract them from successful
top-level admission. This theorem does not assume a new trusted typing law.
-/
theorem psKernelMutualPostReplacementRecursor_semantic_refines
    (fuel : Nat) (original final : PsKernelEnvironment)
    (decl : PsKernelSimpleMutualInductiveDecl)
    (shapes : List PsKernelSimpleMutualTypeShape)
    (ctorShapes : List PsKernelSimpleMutualConstructorShape)
    (work1 : PsKernelEnvironment)
    (recLevelParams : List PsKernelName)
    (levels : List PsKernelLevel)
    (params motives minors ruleBinders : List PsKernelOpenBinder)
    (infos : List PsKernelRecursorInfo)
    (safety : PsKernelDefinitionSafety)
    (maxRecDepth maxNatSize : Nat)
    (hIndexOriginal : PsKernelEnvironmentIndexRefines original)
    (hSource : shapes.map PsKernelSimpleMutualTypeShape.decl = decl.types)
    (hExt : PsKernelEnvironmentSemanticExtends original work1)
    (hIndex : PsKernelEnvironmentIndexRefines work1)
    (hReserved : PsKernelInductiveNamesAbsent work1
      (shapes.map (fun shape : PsKernelSimpleMutualTypeShape =>
        psKernelSimpleRecName shape.decl.name)))
    (hNative : PsKernelNativeReductionSoundLaw)
    (hString : PsKernelStringEqSoundLaw)
    (hRun : psKernelAddSimpleMutualInductive fuel original decl
      maxRecDepth maxNatSize = Except.ok final)
    (hBuild : psKernelBuildSimpleMutualRecInfosFromConstructorsWorker
      shapes shapes recLevelParams (psKernelSimpleMutualNames decl.types)
      levels params motives minors ruleBinders ctorShapes 0
      decl.isUnsafe = Except.ok infos)
    (hValidate : psKernelValidateMutualRecursorInfosWorker
      infos fuel (psKernelAddMutualRecursorInfos infos work1)
      recLevelParams safety maxRecDepth maxNatSize
      levels params motives minors ruleBinders ctorShapes 0 = Except.ok ()) :
    PsKernelMutualRecursorInfosMetadataMatches
      recLevelParams (psKernelSimpleMutualNames decl.types)
      params motives minors ctorShapes decl.isUnsafe 0 shapes infos ∧
    PsKernelMutualRecursorPublicationValid work1
      (psKernelAddMutualRecursorInfos infos work1)
      levels params motives ruleBinders ctorShapes 0 infos ∧
    PsKernelEnvironmentSemanticExtends original
      (psKernelAddMutualRecursorInfos infos work1) := by
  obtain ⟨_, _, _, _, hUniqueRec, _, _, _⟩ :=
    psKernelAddSimpleMutualInductive_success_partitioned_name_guards
      fuel original final decl maxRecDepth maxNatSize hIndexOriginal hRun
  have hNames : shapes.map
      (fun shape : PsKernelSimpleMutualTypeShape =>
        psKernelSimpleRecName shape.decl.name) =
      psKernelSimpleMutualRecNames decl.types := by
    rw [psKernelMutualShapeRecursorNames_source, hSource]
  obtain ⟨hMetadata, hPublished⟩ :=
    psKernelGeneratedMutualRecursorPublication_refines
      shapes shapes recLevelParams (psKernelSimpleMutualNames decl.types)
      levels params motives minors ruleBinders ctorShapes 0
      decl.isUnsafe infos fuel work1 safety maxRecDepth maxNatSize
      hIndex hReserved
      (by simpa only [hNames] using hUniqueRec)
      hNative hString hBuild hValidate
  exact ⟨hMetadata, hPublished,
    PsKernelEnvironmentSemanticExtends.trans original work1
      (psKernelAddMutualRecursorInfos infos work1)
      hExt hPublished.2.1⟩

/--
Generated recursor publication cannot modify runtime capabilities or
quotient-initialization state. This structural invariant complements the
independent recursor typing and authoritative-lookup preservation certificate.
-/
theorem psKernelAddMutualRecursorInfos_preserves_runtime_quot
    (infos : List PsKernelRecursorInfo) :
    ∀ environment : PsKernelEnvironment,
      (psKernelAddMutualRecursorInfos infos environment).runtime =
        environment.runtime ∧
      (psKernelAddMutualRecursorInfos infos environment).quotInitialized =
        environment.quotInitialized := by
  induction infos with
  | nil => intro environment; exact ⟨rfl, rfl⟩
  | cons info rest ih =>
      intro environment
      have hTail := ih (psKernelEnvironmentAddUnchecked environment
        (PsKernelConstantInfo.recInfo info))
      simpa [psKernelAddMutualRecursorInfos, psKernelEnvironmentAddUnchecked] using hTail
