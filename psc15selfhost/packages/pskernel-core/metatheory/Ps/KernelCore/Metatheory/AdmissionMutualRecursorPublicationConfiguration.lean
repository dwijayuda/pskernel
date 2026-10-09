import Ps.KernelCore.Metatheory.AdmissionMutualRecursorSemanticConfiguration
import Ps.KernelCore.Metatheory.AdmissionMutualInductiveIndexConfiguration
import Ps.KernelCore.Metatheory.AdmissionInductiveNamesConfiguration

/--
Fresh recursor insertion preserves all previous canonical lookups. The
remaining-name invariant is maintained through the actual insertion order.
-/
theorem psKernelAddMutualRecursorInfos_semantic_extends
    (infos : List PsKernelRecursorInfo) (environment : PsKernelEnvironment)
    (hString : PsKernelStringEqSoundLaw)
    (hAbsent : PsKernelInductiveNamesAbsent environment (infos.map (fun info => info.base.name)))
    (hUnique : psKernelNameHasDuplicates (infos.map (fun info => info.base.name)) = false) :
    PsKernelEnvironmentSemanticExtends environment (psKernelAddMutualRecursorInfos infos environment) := by
  induction infos generalizing environment with
  | nil => exact PsKernelEnvironmentSemanticExtends.refl environment
  | cons info rest ih =>
      cases hAbsent with
      | cons _ _ hFresh hRest =>
          simp only [List.map_cons] at hUnique
          have hUniqueTail := psKernelNameHasDuplicates_cons_false_refines
            info.base.name (rest.map (fun value : PsKernelRecursorInfo => value.base.name)) hUnique
          let next := psKernelEnvironmentAddUnchecked environment (PsKernelConstantInfo.recInfo info)
          have hStep := psKernelEnvironmentAddUnchecked_fresh_semantic_extends
            environment (PsKernelConstantInfo.recInfo info) hString
            (by simpa [psKernelConstantInfoName, psKernelConstantInfoBase] using hFresh)
          have hRemaining := psKernelInductiveNamesAbsent_add_disjoint environment
            (PsKernelConstantInfo.recInfo info) (rest.map (fun value : PsKernelRecursorInfo => value.base.name)) hRest
            (by simpa [psKernelConstantInfoName, psKernelConstantInfoBase] using hUniqueTail.1)
          exact PsKernelEnvironmentSemanticExtends.trans environment next
            (psKernelAddMutualRecursorInfos rest next) hStep
            (ih next hRemaining hUniqueTail.2)

/--
Publication and checked validation composition. Freshness/uniqueness of the
recursor names is an explicit input invariant supplied by the enclosing
transaction's naming guards. This certificate does not assert complete
well-formedness or generated-universe freshness.
-/
def PsKernelMutualRecursorPublicationValid
    (original result : PsKernelEnvironment) (levels : List PsKernelLevel)
    (params motives ruleBinders : List PsKernelOpenBinder)
    (shapes : List PsKernelSimpleMutualConstructorShape)
    (owner : Nat) (infos : List PsKernelRecursorInfo) : Prop :=
  PsKernelEnvironmentExtendsBy original result
    ((infos.map PsKernelConstantInfo.recInfo).reverse) ∧
  PsKernelEnvironmentSemanticExtends original result ∧
  PsKernelEnvironmentIndexRefines result ∧
  PsKernelMutualRecursorInfosTyped result levels params motives ruleBinders shapes owner infos

theorem psKernelMutualRecursorPublication_refines
    (infos : List PsKernelRecursorInfo) (fuel : Nat)
    (environment : PsKernelEnvironment) (recLevelParams : List PsKernelName)
    (safety : PsKernelDefinitionSafety) (maxRecDepth maxNatSize : Nat)
    (levels : List PsKernelLevel) (params motives minors ruleBinders : List PsKernelOpenBinder)
    (shapes : List PsKernelSimpleMutualConstructorShape) (owner : Nat)
    (hIndex : PsKernelEnvironmentIndexRefines environment)
    (hAbsent : PsKernelInductiveNamesAbsent environment (infos.map (fun info => info.base.name)))
    (hUnique : psKernelNameHasDuplicates (infos.map (fun info => info.base.name)) = false)
    (hNative : PsKernelNativeReductionSoundLaw) (hString : PsKernelStringEqSoundLaw)
    (hRun : psKernelValidateMutualRecursorInfosWorker infos fuel
      (psKernelAddMutualRecursorInfos infos environment) recLevelParams safety maxRecDepth maxNatSize
      levels params motives minors ruleBinders shapes owner = Except.ok ()) :
    PsKernelMutualRecursorPublicationValid environment
      (psKernelAddMutualRecursorInfos infos environment) levels params motives ruleBinders shapes owner infos := by
  have hFinalIndex := psKernelAddMutualRecursorInfos_index_refines infos environment hIndex
  exact ⟨psKernelAddMutualRecursorInfos_refines_extension infos environment,
    psKernelAddMutualRecursorInfos_semantic_extends infos environment hString hAbsent hUnique,
    hFinalIndex, psKernelValidateMutualRecursorInfosWorker_independent_typing infos fuel
      (psKernelAddMutualRecursorInfos infos environment) recLevelParams safety maxRecDepth maxNatSize
      levels params motives minors ruleBinders shapes owner hFinalIndex hNative hString hRun⟩

/-- Generated metadata carries the exact recursor-name sequence needed by publication. -/
theorem PsKernelMutualRecursorInfosMetadataMatches.name_provenance
    {recLevelParams typeNames : List PsKernelName}
    {params motives minors : List PsKernelOpenBinder}
    {ctorShapes : List PsKernelSimpleMutualConstructorShape} {isUnsafe : Bool}
    {owner : Nat} {shapes : List PsKernelSimpleMutualTypeShape} {infos : List PsKernelRecursorInfo}
    (hMetadata : PsKernelMutualRecursorInfosMetadataMatches recLevelParams typeNames params
      motives minors ctorShapes isUnsafe owner shapes infos) :
    infos.map (fun info => info.base.name) =
      (shapes.map (fun shape => psKernelSimpleRecName shape.decl.name)) := by
  induction hMetadata with
  | nil => rfl
  | cons owner shape rest info infos hName hLevels hAll hParams hIndices hMotives
      hMinors hK hUnsafe hRules hTail ih =>
      simp only [List.map_cons, hName, ih]

/--
Composition for actual generated and validated recursors. Name freshness is
stated on the input datatype shapes and transported through proved generator
provenance, rather than assumed independently for opaque generated metadata.
-/
theorem psKernelGeneratedMutualRecursorPublication_refines
    (typeShapes allShapes : List PsKernelSimpleMutualTypeShape)
    (recLevelParams typeNames : List PsKernelName) (levels : List PsKernelLevel)
    (params motives minors ruleBinders : List PsKernelOpenBinder)
    (ctorShapes : List PsKernelSimpleMutualConstructorShape)
    (owner : Nat) (isUnsafe : Bool) (infos : List PsKernelRecursorInfo)
    (fuel : Nat) (environment : PsKernelEnvironment)
    (safety : PsKernelDefinitionSafety) (maxRecDepth maxNatSize : Nat)
    (hIndex : PsKernelEnvironmentIndexRefines environment)
    (hAbsent : PsKernelInductiveNamesAbsent environment
      (typeShapes.map (fun shape => psKernelSimpleRecName shape.decl.name)))
    (hUnique : psKernelNameHasDuplicates
      (typeShapes.map (fun shape => psKernelSimpleRecName shape.decl.name)) = false)
    (hNative : PsKernelNativeReductionSoundLaw) (hString : PsKernelStringEqSoundLaw)
    (hBuild : psKernelBuildSimpleMutualRecInfosFromConstructorsWorker typeShapes allShapes
      recLevelParams typeNames levels params motives minors ruleBinders ctorShapes owner
      isUnsafe = Except.ok infos)
    (hValidate : psKernelValidateMutualRecursorInfosWorker infos fuel
      (psKernelAddMutualRecursorInfos infos environment) recLevelParams safety maxRecDepth maxNatSize
      levels params motives minors ruleBinders ctorShapes owner = Except.ok ()) :
    PsKernelMutualRecursorInfosMetadataMatches recLevelParams typeNames params motives minors
      ctorShapes isUnsafe owner typeShapes infos ∧
    PsKernelMutualRecursorPublicationValid environment
      (psKernelAddMutualRecursorInfos infos environment) levels params motives ruleBinders
      ctorShapes owner infos := by
  have hMetadata := psKernelBuildSimpleMutualRecInfosFromConstructorsWorker_metadata
    typeShapes allShapes recLevelParams typeNames levels params motives minors ruleBinders
    ctorShapes owner isUnsafe infos hBuild
  refine ⟨hMetadata, psKernelMutualRecursorPublication_refines infos fuel environment recLevelParams
    safety maxRecDepth maxNatSize levels params motives minors ruleBinders ctorShapes owner
    hIndex ?_ ?_ hNative hString hValidate⟩
  · simpa only [hMetadata.name_provenance] using hAbsent
  · simpa only [hMetadata.name_provenance] using hUnique
