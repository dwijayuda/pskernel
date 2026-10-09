import Ps.KernelCore.Metatheory.EnvironmentReplaceIndexConfiguration
import Ps.KernelCore.Metatheory.AdmissionInductiveNamesConfiguration
import Ps.KernelCore.Admission.Inductive.Mutual.AdmissionLoops
import Ps.KernelCore.Metatheory.AdmissionIndexConfiguration

/-
The mutual-inductive transaction adds a checked group of inductive headers
before checking constructors, and later adds the resulting recursor metadata.
Both passes are pure folds over the canonical environment insertion operation.

Each step preserves authoritative index refinement for *arbitrary* public
index roots; no assumption of an initially empty/trie-shaped index is made.
These lemmas do not claim constructor or recursor typing soundness.
-/

theorem psKernelAddMutualInductiveInfos_index_refines
    (infos : List PsKernelInductiveInfo) :
    ∀ (environment : PsKernelEnvironment),
      PsKernelEnvironmentIndexRefines environment ->
      PsKernelEnvironmentIndexRefines
        (psKernelAddMutualInductiveInfos infos environment) := by
  induction infos with
  | nil =>
      intro environment hIndex
      simpa [psKernelAddMutualInductiveInfos] using hIndex
  | cons info rest ih =>
      intro environment hIndex
      change
        PsKernelEnvironmentIndexRefines
          (psKernelAddMutualInductiveInfos
            rest
            (psKernelEnvironmentAddUnchecked
              environment
              (PsKernelConstantInfo.inductInfo info)))
      exact
        ih
          (psKernelEnvironmentAddUnchecked
            environment
            (PsKernelConstantInfo.inductInfo info))
          (psKernelEnvironmentAddUnchecked_index_refines
            environment (PsKernelConstantInfo.inductInfo info) hIndex)


theorem psKernelAddMutualRecursorInfos_index_refines
    (infos : List PsKernelRecursorInfo) :
    ∀ (environment : PsKernelEnvironment),
      PsKernelEnvironmentIndexRefines environment ->
      PsKernelEnvironmentIndexRefines
        (psKernelAddMutualRecursorInfos infos environment) := by
  induction infos with
  | nil =>
      intro environment hIndex
      simpa [psKernelAddMutualRecursorInfos] using hIndex
  | cons info rest ih =>
      intro environment hIndex
      change
        PsKernelEnvironmentIndexRefines
          (psKernelAddMutualRecursorInfos
            rest
            (psKernelEnvironmentAddUnchecked
              environment
              (PsKernelConstantInfo.recInfo info)))
      exact
        ih
          (psKernelEnvironmentAddUnchecked
            environment
            (PsKernelConstantInfo.recInfo info))
          (psKernelEnvironmentAddUnchecked_index_refines
            environment (PsKernelConstantInfo.recInfo info) hIndex)


theorem psKernelAddMutualInductiveInfos_refines_extension
    (infos : List PsKernelInductiveInfo)
    (environment : PsKernelEnvironment) :
    PsKernelEnvironmentExtendsBy
      environment
      (psKernelAddMutualInductiveInfos infos environment)
      (List.reverse
        (List.map
          (fun info : PsKernelInductiveInfo =>
            PsKernelConstantInfo.inductInfo info)
          infos)) := by
  induction infos generalizing environment with
  | nil =>
      exact psKernelEnvironmentExtendsBy_refl environment
  | cons info rest ih =>
      have hTail :=
        ih (psKernelEnvironmentAddUnchecked
          environment (PsKernelConstantInfo.inductInfo info))
      simpa [
        psKernelAddMutualInductiveInfos,
        PsKernelEnvironmentExtendsBy,
        psKernelEnvironmentAddUnchecked,
        List.map,
        List.reverse_cons,
        List.append_assoc
      ] using hTail


theorem psKernelAddMutualRecursorInfos_refines_extension
    (infos : List PsKernelRecursorInfo)
    (environment : PsKernelEnvironment) :
    PsKernelEnvironmentExtendsBy
      environment
      (psKernelAddMutualRecursorInfos infos environment)
      (List.reverse
        (List.map
          (fun info : PsKernelRecursorInfo =>
            PsKernelConstantInfo.recInfo info)
          infos)) := by
  induction infos generalizing environment with
  | nil =>
      exact psKernelEnvironmentExtendsBy_refl environment
  | cons info rest ih =>
      have hTail :=
        ih (psKernelEnvironmentAddUnchecked
          environment (PsKernelConstantInfo.recInfo info))
      simpa [
        psKernelAddMutualRecursorInfos,
        PsKernelEnvironmentExtendsBy,
        psKernelEnvironmentAddUnchecked,
        List.map,
        List.reverse_cons,
        List.append_assoc
      ] using hTail

/-- Fresh provisional family insertion preserves original canonical lookups. -/
theorem psKernelAddMutualInductiveInfos_semantic_extends
    (infos : List PsKernelInductiveInfo) (environment : PsKernelEnvironment)
    (hString : PsKernelStringEqSoundLaw)
    (hAbsent : PsKernelInductiveNamesAbsent environment (infos.map (fun info => info.base.name)))
    (hUnique : psKernelNameHasDuplicates (infos.map (fun info => info.base.name)) = false) :
    PsKernelEnvironmentSemanticExtends environment (psKernelAddMutualInductiveInfos infos environment) := by
  induction infos generalizing environment with
  | nil => exact PsKernelEnvironmentSemanticExtends.refl environment
  | cons info rest ih =>
      cases hAbsent with
      | cons _ _ hFresh hRest =>
          simp only [List.map_cons] at hUnique
          have hUniqueTail := psKernelNameHasDuplicates_cons_false_refines
            info.base.name (rest.map (fun value : PsKernelInductiveInfo => value.base.name)) hUnique
          let next := psKernelEnvironmentAddUnchecked environment (PsKernelConstantInfo.inductInfo info)
          have hStep := psKernelEnvironmentAddUnchecked_fresh_semantic_extends
            environment (PsKernelConstantInfo.inductInfo info) hString
            (by simpa [psKernelConstantInfoName, psKernelConstantInfoBase] using hFresh)
          have hRemaining := psKernelInductiveNamesAbsent_add_disjoint environment
            (PsKernelConstantInfo.inductInfo info) (rest.map (fun value : PsKernelInductiveInfo => value.base.name)) hRest
            (by simpa [psKernelConstantInfoName, psKernelConstantInfoBase] using hUniqueTail.1)
          exact PsKernelEnvironmentSemanticExtends.trans environment next
            (psKernelAddMutualInductiveInfos rest next) hStep
            (ih next hRemaining hUniqueTail.2)

/--
Provisional mutual-header insertion preserves the canonical absence of a
disjoint reserved-name family.  The disjointness is an explicit executable
name-list fact; no comparator reflexivity is inferred here.
-/
theorem psKernelAddMutualInductiveInfos_preserves_absent_names
    (infos : List PsKernelInductiveInfo) (environment : PsKernelEnvironment)
    (names : List PsKernelName)
    (hAbsent : PsKernelInductiveNamesAbsent environment names)
    (hDisjoint : ∀ info : PsKernelInductiveInfo, info ∈ infos ->
      psKernelNameListContains info.base.name names = false) :
    PsKernelInductiveNamesAbsent
      (psKernelAddMutualInductiveInfos infos environment) names := by
  induction infos generalizing environment with
  | nil =>
      simpa [psKernelAddMutualInductiveInfos] using hAbsent
  | cons info rest ih =>
      let next :=
        psKernelEnvironmentAddUnchecked
          environment (PsKernelConstantInfo.inductInfo info)
      have hStep : PsKernelInductiveNamesAbsent next names := by
        apply psKernelInductiveNamesAbsent_add_disjoint
          environment (PsKernelConstantInfo.inductInfo info) names hAbsent
        simpa [next, psKernelConstantInfoName, psKernelConstantInfoBase] using
          hDisjoint info (List.Mem.head rest)
      have hTail : ∀ other : PsKernelInductiveInfo, other ∈ rest ->
          psKernelNameListContains other.base.name names = false := by
        intro other hMem
        exact hDisjoint other (List.Mem.tail info hMem)
      have hRemaining := ih next hStep hTail
      simpa [psKernelAddMutualInductiveInfos, next] using hRemaining


/--
Every replacement is justified by current canonical presence. Presence survives
earlier replacements, so the loop needs no repeated unchecked lookup premise.
Original declarations are protected by absence of each replacement name there.
-/
theorem psKernelReplaceMutualInductiveInfos_semantic_refines
    (infos : List PsKernelInductiveInfo)
    (isRecursive isReflexive : Bool)
    (original : PsKernelEnvironment) (hString : PsKernelStringEqSoundLaw) :
    ∀ work : PsKernelEnvironment,
      PsKernelEnvironmentIndexRefines work ->
      PsKernelEnvironmentSemanticExtends original work ->
      (∀ info : PsKernelInductiveInfo, info ∈ infos ->
        psKernelFindConstantInList info.base.name original.constants = none) ->
      (∀ info : PsKernelInductiveInfo, info ∈ infos ->
        ∃ old : PsKernelConstantInfo,
          psKernelFindConstantInList info.base.name work.constants = some old) ->
      PsKernelEnvironmentSemanticExtends original
        (psKernelReplaceMutualInductiveInfos infos isRecursive isReflexive work) ∧
      PsKernelEnvironmentIndexRefines
        (psKernelReplaceMutualInductiveInfos infos isRecursive isReflexive work) := by
  induction infos with
  | nil =>
      intro work hIndex hExt hFresh hPresent
      exact ⟨hExt, hIndex⟩
  | cons info rest ih =>
      intro work hIndex hExt hFresh hPresent
      let finalInfo := PsKernelInductiveInfo.mk info.base info.numParams info.numIndices
        info.all info.ctors info.numNested isRecursive isReflexive info.isUnsafe
      let replacement := PsKernelConstantInfo.inductInfo finalInfo
      let next := psKernelEnvironmentReplaceUnchecked work replacement
      obtain ⟨old, hOld⟩ := hPresent info (List.Mem.head rest)
      have hExisting : psKernelFindConstantInList
          (psKernelConstantInfoName replacement) work.constants = some old := hOld
      have hNextIndex := psKernelEnvironmentReplaceUnchecked_index_refines
        work replacement old hIndex hExisting
      have hNextExt := psKernelEnvironmentReplaceUnchecked_fresh_origin_semantic_extends
        original work replacement hString hExt (hFresh info (List.Mem.head rest))
      have hRestFresh : ∀ other : PsKernelInductiveInfo, other ∈ rest ->
          psKernelFindConstantInList other.base.name original.constants = none :=
        fun other hMem => hFresh other (List.Mem.tail info hMem)
      have hRestPresent : ∀ other : PsKernelInductiveInfo, other ∈ rest ->
          ∃ old : PsKernelConstantInfo,
            psKernelFindConstantInList other.base.name next.constants = some old := by
        intro other hMem
        obtain ⟨found, hFound⟩ := hPresent other (List.Mem.tail info hMem)
        exact psKernelEnvironmentReplaceUnchecked_preserves_present
          work replacement old hExisting other.base.name found hFound
      exact ih next hNextIndex hNextExt hRestFresh hRestPresent

/-- Reserved names remain absent throughout the metadata replacement loop. -/
theorem psKernelReplaceMutualInductiveInfos_preserves_absent_names
    (infos : List PsKernelInductiveInfo)
    (isRecursive isReflexive : Bool) (hString : PsKernelStringEqSoundLaw)
    (names : List PsKernelName) :
    ∀ work : PsKernelEnvironment,
      PsKernelInductiveNamesAbsent work names ->
      (∀ info : PsKernelInductiveInfo, info ∈ infos ->
        ∀ name : PsKernelName, name ∈ names -> name ≠ info.base.name) ->
      PsKernelInductiveNamesAbsent
        (psKernelReplaceMutualInductiveInfos infos isRecursive isReflexive work) names := by
  induction infos with
  | nil => intro work hAbsent _; exact hAbsent
  | cons info rest ih =>
      intro work hAbsent hDisjoint
      let finalInfo := PsKernelInductiveInfo.mk info.base info.numParams info.numIndices
        info.all info.ctors info.numNested isRecursive isReflexive info.isUnsafe
      apply ih (psKernelEnvironmentReplaceUnchecked work (PsKernelConstantInfo.inductInfo finalInfo))
      · apply psKernelInductiveNamesAbsent_replace_disjoint hString work
          (PsKernelConstantInfo.inductInfo finalInfo) names hAbsent
        exact hDisjoint info (List.Mem.head rest)
      · intro other hMem
        exact hDisjoint other (List.Mem.tail info hMem)

/--
The provisional inductive declaration names are exactly the source header
shape names. This is a source-order provenance fact, not a lookup assumption.
-/
theorem psKernelMakeSimpleMutualBaseInfos_name_provenance
    (typeNames : List PsKernelName)
    (decl : PsKernelSimpleMutualInductiveDecl)
    (shapes : List PsKernelSimpleMutualTypeShape) :
    (psKernelMakeSimpleMutualBaseInfos typeNames decl shapes).map
      (fun info : PsKernelInductiveInfo => info.base.name) =
    shapes.map (fun shape : PsKernelSimpleMutualTypeShape => shape.decl.name) := by
  induction shapes with
  | nil => rfl
  | cons shape rest ih =>
      simp [psKernelMakeSimpleMutualBaseInfos, ih]

/--
The actual provisional mutual-header publication preserves canonical prior
declarations, executable environment indexes and exact insertion provenance.
Its only naming premises are about the source header shapes. The enclosing
transaction must derive these from its checked preflight guards.
-/
theorem psKernelPreparedMutualHeaders_semantic_refines
    (typeNames : List PsKernelName)
    (decl : PsKernelSimpleMutualInductiveDecl)
    (shapes : List PsKernelSimpleMutualTypeShape)
    (environment : PsKernelEnvironment)
    (hIndex : PsKernelEnvironmentIndexRefines environment)
    (hString : PsKernelStringEqSoundLaw)
    (hAbsent : PsKernelInductiveNamesAbsent environment
      (shapes.map (fun shape : PsKernelSimpleMutualTypeShape => shape.decl.name)))
    (hUnique : psKernelNameHasDuplicates
      (shapes.map (fun shape : PsKernelSimpleMutualTypeShape => shape.decl.name)) = false) :
    PsKernelEnvironmentSemanticExtends environment
      (psKernelAddMutualInductiveInfos
        (psKernelMakeSimpleMutualBaseInfos typeNames decl shapes) environment) ∧
    PsKernelEnvironmentIndexRefines
      (psKernelAddMutualInductiveInfos
        (psKernelMakeSimpleMutualBaseInfos typeNames decl shapes) environment) ∧
    PsKernelEnvironmentExtendsBy environment
      (psKernelAddMutualInductiveInfos
        (psKernelMakeSimpleMutualBaseInfos typeNames decl shapes) environment)
      ((psKernelMakeSimpleMutualBaseInfos typeNames decl shapes).map
        (fun info : PsKernelInductiveInfo => PsKernelConstantInfo.inductInfo info)).reverse := by
  have hNames := psKernelMakeSimpleMutualBaseInfos_name_provenance typeNames decl shapes
  refine ⟨psKernelAddMutualInductiveInfos_semantic_extends
    (psKernelMakeSimpleMutualBaseInfos typeNames decl shapes) environment
    hString ?_ ?_,
    psKernelAddMutualInductiveInfos_index_refines
      (psKernelMakeSimpleMutualBaseInfos typeNames decl shapes) environment hIndex,
    psKernelAddMutualInductiveInfos_refines_extension
      (psKernelMakeSimpleMutualBaseInfos typeNames decl shapes) environment⟩
  · simpa only [hNames] using hAbsent
  · simpa only [hNames] using hUnique

/--
Every metadata name produced by the provisional mutual-header builder comes
from an actual checked source shape. This transfers the transaction's global
reserved-name exclusion to the exact generated metadata list.
-/
theorem psKernelMakeSimpleMutualBaseInfos_name_member
    (typeNames : List PsKernelName)
    (decl : PsKernelSimpleMutualInductiveDecl)
    (shapes : List PsKernelSimpleMutualTypeShape)
    (info : PsKernelInductiveInfo)
    (hMember : List.Mem info (psKernelMakeSimpleMutualBaseInfos typeNames decl shapes)) :
    List.Mem info.base.name
      (shapes.map (fun shape : PsKernelSimpleMutualTypeShape => shape.decl.name)) := by
  have hMapped : List.Mem info.base.name
      ((psKernelMakeSimpleMutualBaseInfos typeNames decl shapes).map
        (fun entry : PsKernelInductiveInfo => entry.base.name)) :=
    List.mem_map_of_mem (f := fun entry : PsKernelInductiveInfo => entry.base.name) hMember
  simpa only [psKernelMakeSimpleMutualBaseInfos_name_provenance] using hMapped

/--
Provisional publication preserves the complete reserved-name family if its
source-header names are disjoint from those reservations. The premise is the
executable negative-membership invariant that the global name guard proves.
-/
theorem psKernelPreparedMutualHeaders_preserves_reserved_names
    (typeNames : List PsKernelName)
    (decl : PsKernelSimpleMutualInductiveDecl)
    (shapes : List PsKernelSimpleMutualTypeShape)
    (environment : PsKernelEnvironment)
    (reserved : List PsKernelName)
    (hAbsent : PsKernelInductiveNamesAbsent environment reserved)
    (hDisjoint : ∀ name : PsKernelName,
      List.Mem name (shapes.map
        (fun shape : PsKernelSimpleMutualTypeShape => shape.decl.name)) ->
      psKernelNameListContains name reserved = false) :
    PsKernelInductiveNamesAbsent
      (psKernelAddMutualInductiveInfos
        (psKernelMakeSimpleMutualBaseInfos typeNames decl shapes) environment)
      reserved := by
  apply psKernelAddMutualInductiveInfos_preserves_absent_names
    (psKernelMakeSimpleMutualBaseInfos typeNames decl shapes)
    environment reserved hAbsent
  intro info hMember
  exact hDisjoint info.base.name
    (psKernelMakeSimpleMutualBaseInfos_name_member typeNames decl shapes info hMember)

/--
The actual provisional family-insertion loop cannot erase a previously
present canonical name. Even when a later inserted datatype shadows a lookup,
some actual declaration continues to answer it. This is a structural fold
fact and requires neither index assumptions nor new trusted name laws.
-/
theorem psKernelAddMutualInductiveInfos_preserves_present
    (infos : List PsKernelInductiveInfo) :
    ∀ (environment : PsKernelEnvironment) (name : PsKernelName)
      (found : PsKernelConstantInfo),
      psKernelFindConstantInList name environment.constants = some found ->
      ∃ newer : PsKernelConstantInfo,
        psKernelFindConstantInList name
          (psKernelAddMutualInductiveInfos infos environment).constants = some newer := by
  induction infos with
  | nil =>
      intro environment name found hPresent
      exact ⟨found, by simpa [psKernelAddMutualInductiveInfos] using hPresent⟩
  | cons info rest ih =>
      intro environment name found hPresent
      let next := psKernelEnvironmentAddUnchecked
        environment (PsKernelConstantInfo.inductInfo info)
      cases hEqual : psKernelNameEq info.base.name name with
      | true =>
          have hNext : psKernelFindConstantInList name next.constants =
              some (PsKernelConstantInfo.inductInfo info) := by
            simp [next, psKernelEnvironmentAddUnchecked, psKernelFindConstantInList,
              psKernelConstantInfoName, psKernelConstantInfoBase, hEqual]
          simpa [psKernelAddMutualInductiveInfos, next] using
            ih next name (PsKernelConstantInfo.inductInfo info) hNext
      | false =>
          have hNext : psKernelFindConstantInList name next.constants = some found := by
            simpa [next, psKernelEnvironmentAddUnchecked, psKernelFindConstantInList,
              psKernelConstantInfoName, psKernelConstantInfoBase, hEqual] using hPresent
          simpa [psKernelAddMutualInductiveInfos, next] using
            ih next name found hNext

/--
Every member of the actual provisional inductive metadata list remains
canonically present after the complete insertion fold. Comparator reflexivity
is explicit here and discharged from the specified implementation by callers;
the theorem cannot be misread as a fresh source-level trusted premise.
-/
theorem psKernelAddMutualInductiveInfos_member_present
    (infos : List PsKernelInductiveInfo)
    (hReflexive : PsKernelStringEqReflexiveLaw) :
    ∀ (environment : PsKernelEnvironment) (info : PsKernelInductiveInfo),
      List.Mem info infos ->
      ∃ found : PsKernelConstantInfo,
        psKernelFindConstantInList info.base.name
          (psKernelAddMutualInductiveInfos infos environment).constants = some found := by
  induction infos with
  | nil =>
      intro environment info hMember
      cases hMember
  | cons head rest ih =>
      intro environment info hMember
      let next := psKernelEnvironmentAddUnchecked
        environment (PsKernelConstantInfo.inductInfo head)
      cases hMember with
      | head =>
          have hSelf := psKernelNameEq_refl_of_string_law hReflexive head.base.name
          have hPresent : psKernelFindConstantInList head.base.name next.constants =
              some (PsKernelConstantInfo.inductInfo head) := by
            simp [next, psKernelEnvironmentAddUnchecked, psKernelFindConstantInList,
              psKernelConstantInfoName, psKernelConstantInfoBase, hSelf]
          simpa [psKernelAddMutualInductiveInfos, next] using
            psKernelAddMutualInductiveInfos_preserves_present rest next
              head.base.name (PsKernelConstantInfo.inductInfo head) hPresent
      | tail =>
          simpa [psKernelAddMutualInductiveInfos, next] using
            ih next info (by assumption)
