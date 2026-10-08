import Ps.KernelCore.Metatheory.EnvironmentSemanticTransport
import Ps.KernelCore.Admission.Inductive.Ordinary.Admission
import Ps.KernelCore.Admission.Inductive.Mutual.Admission
import Ps.KernelCore.Metatheory.AdmissionIndexConfiguration

/-
Canonical freshness of names before ordinary and mutual inductive admission.

The executable checker consults the accelerated environment.  This
independent predicate records absence from the authoritative declaration list,
not mere absence from the mutable hash index.  It is intentionally separate
from the bundle's internal-name uniqueness guard.
-/

inductive PsKernelInductiveNamesAbsent
    (environment : PsKernelEnvironment) :
    List PsKernelName -> Prop where
  | nil :
      PsKernelInductiveNamesAbsent environment List.nil
  | cons
      (name : PsKernelName)
      (rest : List PsKernelName)
      (hAbsent :
        psKernelFindConstantInList name environment.constants =
          Option.none)
      (hRest : PsKernelInductiveNamesAbsent environment rest) :
      PsKernelInductiveNamesAbsent
        environment (List.cons name rest)


theorem psKernelCheckFreshInductiveNames_refines_canonical
    (names : List PsKernelName) :
    ∀ (environment : PsKernelEnvironment),
      PsKernelEnvironmentIndexRefines environment ->
      psKernelCheckFreshInductiveNames names environment =
        Except.ok () ->
      PsKernelInductiveNamesAbsent environment names := by
  induction names with
  | nil =>
      intro environment hIndex hRun
      exact PsKernelInductiveNamesAbsent.nil
  | cons name rest ih =>
      intro environment hIndex hRun
      cases hPresent :
          psKernelEnvironmentContains environment name with
      | true =>
          simp [
            psKernelCheckFreshInductiveNames,
            hPresent
          ] at hRun
      | false =>
          have hLookupNone :
              psKernelEnvironmentFind environment name =
                Option.none := by
            cases hFind :
                psKernelEnvironmentFind environment name with
            | none =>
                rfl
            | some declaration =>
                simp [
                  psKernelEnvironmentContains,
                  hFind
                ] at hPresent
          have hCanonicalNone :
              psKernelFindConstantInList
                  name environment.constants =
                Option.none := by
            calc
              psKernelFindConstantInList
                  name environment.constants =
                psKernelFindConstantInList
                  name
                  (psKernelEnvironmentIndexFind
                    environment.index name) :=
                (hIndex name).symm
              _ = Option.none := by
                simpa [psKernelEnvironmentFind] using
                  hLookupNone
          have hRestRun :
              psKernelCheckFreshInductiveNames
                  rest environment =
                Except.ok () := by
            simpa [
              psKernelCheckFreshInductiveNames,
              hPresent
            ] using hRun
          exact
            PsKernelInductiveNamesAbsent.cons
              name rest hCanonicalNone
              (ih environment hIndex hRestRun)


theorem psKernelSimpleNameListUnique_true_no_duplicates
    (names : List PsKernelName)
    (hUnique : psKernelSimpleNameListUnique names = true) :
    psKernelNameHasDuplicates names = false := by
  cases hDuplicates :
      psKernelNameHasDuplicates names with
  | false =>
      rfl
  | true =>
      simp [
        psKernelSimpleNameListUnique,
        hDuplicates
      ] at hUnique


/-
Only the early naming guards are projected from successful top-level admission.
The deeper constructor, recursor and positivity checks are not claimed closed
by these theorems; those require separate transaction refinement.
-/
theorem psKernelAddSimpleInductive_success_name_guards
    (fuel : Nat)
    (environment result : PsKernelEnvironment)
    (decl : PsKernelSimpleInductiveDecl)
    (maxRecDepth maxNatSize : Nat)
    (hIndex : PsKernelEnvironmentIndexRefines environment)
    (hRun :
      psKernelAddSimpleInductive
          fuel environment decl maxRecDepth maxNatSize =
        Except.ok result) :
    psKernelNameHasDuplicates decl.levelParams = false ∧
      psKernelSimpleNameListUnique
        (List.cons decl.name
          (List.cons
            (psKernelSimpleRecName decl.name)
            (psKernelSimpleCtorNames decl.ctors))) = true ∧
      PsKernelInductiveNamesAbsent
        environment
        (List.cons decl.name
          (List.cons
            (psKernelSimpleRecName decl.name)
            (psKernelSimpleCtorNames decl.ctors))) := by
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
          | ok witness =>
              cases witness
              have hAbsent :=
                psKernelCheckFreshInductiveNames_refines_canonical
                  allNames environment hIndex hFresh
              exact ⟨rfl, rfl, hAbsent⟩


theorem psKernelAddSimpleMutualInductive_success_name_guards
    (fuel : Nat)
    (environment result : PsKernelEnvironment)
    (decl : PsKernelSimpleMutualInductiveDecl)
    (maxRecDepth maxNatSize : Nat)
    (hIndex : PsKernelEnvironmentIndexRefines environment)
    (hRun :
      psKernelAddSimpleMutualInductive
          fuel environment decl maxRecDepth maxNatSize =
        Except.ok result) :
    psKernelNameHasDuplicates decl.levelParams = false ∧
      psKernelNatLt
        (psKernelSimpleMutualTypeCount decl.types) 2 = false ∧
      psKernelSimpleNameListUnique
        (psKernelMutualNameListAppend
          (psKernelSimpleMutualNames decl.types)
          (psKernelMutualNameListAppend
            (psKernelSimpleMutualRecNames decl.types)
            (psKernelSimpleMutualCtorNames decl.types))) = true ∧
      PsKernelInductiveNamesAbsent
        environment
        (psKernelMutualNameListAppend
          (psKernelSimpleMutualNames decl.types)
          (psKernelMutualNameListAppend
            (psKernelSimpleMutualRecNames decl.types)
            (psKernelSimpleMutualCtorNames decl.types))) := by
  let allNames : List PsKernelName :=
    psKernelMutualNameListAppend
      (psKernelSimpleMutualNames decl.types)
      (psKernelMutualNameListAppend
        (psKernelSimpleMutualRecNames decl.types)
        (psKernelSimpleMutualCtorNames decl.types))
  cases hDuplicates :
      psKernelNameHasDuplicates decl.levelParams with
  | true =>
      simp [
        psKernelAddSimpleMutualInductive, hDuplicates
      ] at hRun
  | false =>
      cases hMinTypes :
          psKernelNatLt
            (psKernelSimpleMutualTypeCount decl.types) 2 with
      | true =>
          simp [
            psKernelAddSimpleMutualInductive,
            hDuplicates, hMinTypes
          ] at hRun
      | false =>
          cases hUnique :
              psKernelSimpleNameListUnique allNames with
          | false =>
              simp [
                psKernelAddSimpleMutualInductive,
                hDuplicates, hMinTypes, allNames, hUnique
              ] at hRun
          | true =>
              cases hFresh :
                  psKernelCheckFreshInductiveNames
                    allNames environment with
              | error message =>
                  simp [
                    psKernelAddSimpleMutualInductive,
                    hDuplicates, hMinTypes, allNames,
                    hUnique, hFresh
                  ] at hRun
              | ok witness =>
                  cases witness
                  have hAbsent :=
                    psKernelCheckFreshInductiveNames_refines_canonical
                      allNames environment hIndex hFresh
                  exact ⟨rfl, rfl, rfl, hAbsent⟩


theorem psKernelNameHasDuplicates_cons_false_refines
    (head : PsKernelName) (tail : List PsKernelName)
    (hUnique : psKernelNameHasDuplicates (head :: tail) = false) :
    psKernelNameListContains head tail = false ∧
      psKernelNameHasDuplicates tail = false := by
  cases hMember : psKernelNameListContains head tail with
  | true => simp [psKernelNameHasDuplicates, hMember] at hUnique
  | false =>
      exact ⟨rfl, by simpa [psKernelNameHasDuplicates, hMember] using hUnique⟩

/--
Fresh remaining names stay absent when a disjoint declaration is inserted.
This derives every progressive constructor work-environment freshness
obligation from the existing naming guards rather than assuming it afresh.
-/
theorem psKernelInductiveNamesAbsent_add_disjoint
    (environment : PsKernelEnvironment)
    (added : PsKernelConstantInfo)
    (names : List PsKernelName)
    (hAbsent : PsKernelInductiveNamesAbsent environment names)
    (hDisjoint : psKernelNameListContains (psKernelConstantInfoName added) names = false) :
    PsKernelInductiveNamesAbsent
      (psKernelEnvironmentAddUnchecked environment added) names := by
  revert hDisjoint
  induction hAbsent with
  | nil =>
      intro hDisjoint
      exact PsKernelInductiveNamesAbsent.nil
  | cons name rest hNameAbsent hRestAbsent ih =>
      intro hDisjoint
      cases hEqual : psKernelNameEq (psKernelConstantInfoName added) name with
      | true =>
          simp [psKernelNameListContains, hEqual] at hDisjoint
      | false =>
          have hTail : psKernelNameListContains
              (psKernelConstantInfoName added) rest = false := by
            simpa [psKernelNameListContains, hEqual] using hDisjoint
          exact PsKernelInductiveNamesAbsent.cons name rest
            (by simpa [psKernelEnvironmentAddUnchecked,
              psKernelFindConstantInList, hEqual] using hNameAbsent)
            (ih hTail)

/--
Negative membership implies syntactic name exclusion only with comparator
reflexivity. This obligation is explicit and is not derived from positive
StringEq soundness.
-/
theorem psKernelNameListContains_false_excludes_equal
    (hReflexive : PsKernelStringEqReflexiveLaw)
    (needle : PsKernelName) (names : List PsKernelName)
    (hAbsent : psKernelNameListContains needle names = false) :
    ∀ name : PsKernelName, List.Mem name names -> name ≠ needle := by
  revert hAbsent
  induction names with
  | nil =>
      intro hAbsent name hMember
      cases hMember
  | cons head tail ih =>
      intro hAbsent name hMember hEqual
      cases hHead : psKernelNameEq needle head with
      | true =>
          simp [psKernelNameListContains, hHead] at hAbsent
      | false =>
          have hTail : psKernelNameListContains needle tail = false := by
            simpa [psKernelNameListContains, hHead] using hAbsent
          cases hMember with
          | head =>
              have hSelf := psKernelNameEq_refl_of_string_law hReflexive needle
              simpa [hEqual, hSelf] using hHead
          | tail =>
              exact ih hTail name (by assumption) hEqual

/-- Metadata replacement for a disjoint transaction name preserves absence. -/
theorem psKernelInductiveNamesAbsent_replace_disjoint
    (hString : PsKernelStringEqSoundLaw)
    (environment : PsKernelEnvironment) (replacement : PsKernelConstantInfo)
    (names : List PsKernelName)
    (hAbsent : PsKernelInductiveNamesAbsent environment names)
    (hDisjoint : ∀ name : PsKernelName, List.Mem name names ->
      name ≠ psKernelConstantInfoName replacement) :
    PsKernelInductiveNamesAbsent
      (psKernelEnvironmentReplaceUnchecked environment replacement) names := by
  revert hDisjoint
  induction hAbsent with
  | nil =>
      intro hDisjoint
      exact PsKernelInductiveNamesAbsent.nil
  | cons name rest hName hRest ih =>
      intro hDisjoint
      have hHead := hDisjoint name (List.Mem.head rest)
      have hTail : ∀ other : PsKernelName, List.Mem other rest ->
          other ≠ psKernelConstantInfoName replacement :=
        fun other hMem => hDisjoint other (List.Mem.tail name hMem)
      refine PsKernelInductiveNamesAbsent.cons name rest ?_ (ih hTail)
      change psKernelFindConstantInList name
        (psKernelReplaceEnvironmentConstant (psKernelConstantInfoName replacement)
          replacement environment.constants) = none
      rw [psKernelReplaceEnvironmentConstant_preserves_other_lookup
        hString replacement name hHead environment.constants]
      exact hName
