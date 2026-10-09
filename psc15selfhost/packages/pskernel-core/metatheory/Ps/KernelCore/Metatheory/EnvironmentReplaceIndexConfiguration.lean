import Ps.KernelCore.Metatheory.AdmissionIndexConfiguration
import Ps.KernelCore.Metatheory.Comparator

/-
An inductive transaction temporarily inserts a declaration and later replaces
that *existing* declaration with its validated constructor/recursor metadata.

Index insertion alone is not enough to prove replacement sound: the canonical
declaration history replaces its first matching entry in place, whereas the
accelerated index inserts a new head entry for that name.  Both must agree on
all lookup queries.  These proofs require an existing authoritative match;
replacement of an absent name is not claimed sound.
-/

theorem psKernelFindConstantInList_some_name_reflexive
    (name : PsKernelName)
    (values : List PsKernelConstantInfo) :
    ∀ (found : PsKernelConstantInfo),
      psKernelFindConstantInList name values =
        Option.some found ->
      psKernelNameEq name name = true := by
  induction values with
  | nil =>
      intro found hFound
      simp [psKernelFindConstantInList] at hFound
  | cons info rest ih =>
      intro found hFound
      cases hMatch :
          psKernelNameEq
            (psKernelConstantInfoName info) name with
      | true =>
          have hSymm :
              psKernelNameEq
                  name
                  (psKernelConstantInfoName info) =
                true := by
            rw [← psKernelNameEq_symm_core
              (psKernelConstantInfoName info) name]
            exact hMatch
          exact
            psKernelNameEq_trans_core
              name
              (psKernelConstantInfoName info)
              name hSymm hMatch
      | false =>
          have hRestFound :
              psKernelFindConstantInList name rest =
                Option.some found := by
            simpa [psKernelFindConstantInList, hMatch] using hFound
          exact ih found hRestFound


theorem psKernelFindConstantInList_replace_matches_insert
    (target : PsKernelName)
    (replacement : PsKernelConstantInfo)
    (values : List PsKernelConstantInfo)
    (hName :
      psKernelNameEq
        (psKernelConstantInfoName replacement) target = true) :
    ∀ (query : PsKernelName)
      (old : PsKernelConstantInfo),
      psKernelFindConstantInList target values =
        Option.some old ->
      psKernelFindConstantInList
          query
          (psKernelReplaceEnvironmentConstant
            target replacement values) =
        psKernelFindConstantInList
          query (List.cons replacement values) := by
  induction values with
  | nil =>
      intro query old hFound
      simp [psKernelFindConstantInList] at hFound
  | cons head rest ih =>
      intro query old hFound
      cases hHeadTarget :
          psKernelNameEq
            (psKernelConstantInfoName head) target with
      | true =>
          cases hReplacementQuery :
              psKernelNameEq
                (psKernelConstantInfoName replacement)
                query with
          | true =>
              simp [
                psKernelReplaceEnvironmentConstant,
                psKernelFindConstantInList,
                hHeadTarget, hReplacementQuery
              ]
          | false =>
              have hHeadQueryFalse :
                  psKernelNameEq
                      (psKernelConstantInfoName head)
                      query =
                    false := by
                cases hHeadQuery :
                    psKernelNameEq
                      (psKernelConstantInfoName head)
                      query with
                | false =>
                    rfl
                | true =>
                    have hTargetHead :
                        psKernelNameEq
                            target
                            (psKernelConstantInfoName head) =
                          true := by
                      rw [← psKernelNameEq_symm_core
                        (psKernelConstantInfoName head) target]
                      exact hHeadTarget
                    have hReplacementHead :=
                      psKernelNameEq_trans_core
                        (psKernelConstantInfoName replacement)
                        target
                        (psKernelConstantInfoName head)
                        hName hTargetHead
                    have hReplacementQueryTrue :=
                      psKernelNameEq_trans_core
                        (psKernelConstantInfoName replacement)
                        (psKernelConstantInfoName head)
                        query
                        hReplacementHead hHeadQuery
                    rw [hReplacementQuery] at hReplacementQueryTrue
                    cases hReplacementQueryTrue
              simp [
                psKernelReplaceEnvironmentConstant,
                psKernelFindConstantInList,
                hHeadTarget, hReplacementQuery,
                hHeadQueryFalse
              ]
      | false =>
          have hRestFound :
              psKernelFindConstantInList target rest =
                Option.some old := by
            simpa [psKernelFindConstantInList, hHeadTarget]
              using hFound
          have hRest := ih query old hRestFound
          cases hHeadQuery :
              psKernelNameEq
                (psKernelConstantInfoName head) query with
          | true =>
              have hReplacementQueryFalse :
                  psKernelNameEq
                      (psKernelConstantInfoName replacement)
                      query =
                    false := by
                cases hReplacementQuery :
                    psKernelNameEq
                      (psKernelConstantInfoName replacement)
                      query with
                | false =>
                    rfl
                | true =>
                    have hQueryHead :
                        psKernelNameEq
                            query
                            (psKernelConstantInfoName head) =
                          true := by
                      rw [← psKernelNameEq_symm_core
                        (psKernelConstantInfoName head) query]
                      exact hHeadQuery
                    have hReplacementHead :=
                      psKernelNameEq_trans_core
                        (psKernelConstantInfoName replacement)
                        query
                        (psKernelConstantInfoName head)
                        hReplacementQuery hQueryHead
                    have hHeadReplacement :
                        psKernelNameEq
                            (psKernelConstantInfoName head)
                            (psKernelConstantInfoName replacement) =
                          true := by
                      rw [← psKernelNameEq_symm_core
                        (psKernelConstantInfoName replacement)
                        (psKernelConstantInfoName head)]
                      exact hReplacementHead
                    have hHeadTargetTrue :=
                      psKernelNameEq_trans_core
                        (psKernelConstantInfoName head)
                        (psKernelConstantInfoName replacement)
                        target
                        hHeadReplacement hName
                    rw [hHeadTarget] at hHeadTargetTrue
                    cases hHeadTargetTrue
              simp [
                psKernelReplaceEnvironmentConstant,
                psKernelFindConstantInList,
                hHeadTarget, hHeadQuery,
                hReplacementQueryFalse
              ]
          | false =>
              simpa [
                psKernelReplaceEnvironmentConstant,
                psKernelFindConstantInList,
                hHeadTarget, hHeadQuery
              ] using hRest


theorem psKernelEnvironmentReplaceUnchecked_index_refines
    (environment : PsKernelEnvironment)
    (replacement old : PsKernelConstantInfo)
    (hIndex : PsKernelEnvironmentIndexRefines environment)
    (hExisting :
      psKernelFindConstantInList
          (psKernelConstantInfoName replacement)
          environment.constants =
        Option.some old) :
    PsKernelEnvironmentIndexRefines
      (psKernelEnvironmentReplaceUnchecked
        environment replacement) := by
  let target := psKernelConstantInfoName replacement
  have hName :
      psKernelNameEq target target = true :=
    psKernelFindConstantInList_some_name_reflexive
      target environment.constants old hExisting
  intro query
  change
    psKernelFindConstantInList
        query
        (psKernelEnvironmentIndexFind
          (psKernelEnvironmentIndexInsert
            environment.index replacement)
          query) =
      psKernelFindConstantInList
        query
        (psKernelReplaceEnvironmentConstant
          target replacement environment.constants)
  calc
    psKernelFindConstantInList
        query
        (psKernelEnvironmentIndexFind
          (psKernelEnvironmentIndexInsert
            environment.index replacement)
          query) =
      psKernelFindConstantInList
        query
        (List.cons replacement environment.constants) :=
      psKernelEnvironmentIndexInsert_refines_authoritative
        environment.index
        environment.constants
        replacement
        hIndex
        query
    _ = psKernelFindConstantInList
          query
          (psKernelReplaceEnvironmentConstant
            target replacement environment.constants) :=
      (psKernelFindConstantInList_replace_matches_insert
        target replacement environment.constants hName
        query old hExisting).symm


theorem psKernelEnvironmentReplaceUnchecked_index_refines_from_lookup
    (environment : PsKernelEnvironment)
    (replacement old : PsKernelConstantInfo)
    (hIndex : PsKernelEnvironmentIndexRefines environment)
    (hLookup :
      psKernelEnvironmentFind
          environment
          (psKernelConstantInfoName replacement) =
        Option.some old) :
    PsKernelEnvironmentIndexRefines
      (psKernelEnvironmentReplaceUnchecked
        environment replacement) := by
  apply
    psKernelEnvironmentReplaceUnchecked_index_refines
      environment replacement old hIndex
  calc
    psKernelFindConstantInList
        (psKernelConstantInfoName replacement)
        environment.constants =
      psKernelFindConstantInList
        (psKernelConstantInfoName replacement)
        (psKernelEnvironmentIndexFind
          environment.index
          (psKernelConstantInfoName replacement)) :=
      (hIndex (psKernelConstantInfoName replacement)).symm
    _ = Option.some old := by
      simpa [psKernelEnvironmentFind] using hLookup

/-- Replacing an existing declaration preserves existence of every resolved name. -/
theorem psKernelEnvironmentReplaceUnchecked_preserves_present
    (environment : PsKernelEnvironment) (replacement old : PsKernelConstantInfo)
    (hExisting : psKernelFindConstantInList
      (psKernelConstantInfoName replacement) environment.constants = some old)
    (query : PsKernelName) (found : PsKernelConstantInfo)
    (hFound : psKernelFindConstantInList query environment.constants = some found) :
    ∃ updated : PsKernelConstantInfo,
      psKernelFindConstantInList query
        (psKernelEnvironmentReplaceUnchecked environment replacement).constants = some updated := by
  let target := psKernelConstantInfoName replacement
  have hRefl := psKernelFindConstantInList_some_name_reflexive
    target environment.constants old hExisting
  change ∃ updated, psKernelFindConstantInList query
    (psKernelReplaceEnvironmentConstant target replacement environment.constants) = some updated
  rw [psKernelFindConstantInList_replace_matches_insert
    target replacement environment.constants hRefl query old hExisting]
  cases hMatch : psKernelNameEq (psKernelConstantInfoName replacement) query with
  | true =>
      exact ⟨replacement, by simp [psKernelFindConstantInList, hMatch]⟩
  | false =>
      exact ⟨found, by simpa [psKernelFindConstantInList, hMatch] using hFound⟩
