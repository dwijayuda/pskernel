import Ps.KernelCore.Runtime.Acceleration.EnvironmentIndex
import Ps.KernelCore.Environment.Semantic
import Ps.KernelCore.Metatheory.EnvironmentIndexRefinement

theorem psKernelEnvironmentIndexFind_empty
    (name : PsKernelName) :
    psKernelEnvironmentIndexFind
        PsKernelEnvironmentIndex.empty
        name =
      List.nil := by
  rfl

theorem psKernelEnvironmentIndexFind_small
    (constants : List PsKernelConstantInfo)
    (name : PsKernelName) :
    psKernelEnvironmentIndexFind
        (PsKernelEnvironmentIndex.small constants)
        name =
      constants := by
  rfl

theorem psKernelEnvironmentIndexFind_bucket
    (constants : List PsKernelConstantInfo)
    (name : PsKernelName) :
    psKernelEnvironmentIndexFind
        (PsKernelEnvironmentIndex.bucket constants)
        name =
      constants := by
  rfl

theorem psKernelEnvironmentIndexInsert_empty
    (info : PsKernelConstantInfo) :
    psKernelEnvironmentIndexInsert
        PsKernelEnvironmentIndex.empty
        info =
      PsKernelEnvironmentIndex.small
        (List.cons info List.nil) := by
  rfl

theorem psKernelEnvironmentIndexListLength_eq_length
    (constants : List PsKernelConstantInfo) :
    psKernelEnvironmentIndexListLength constants =
      List.length constants := by
  induction constants with
  | nil =>
      rfl
  | cons head tail ih =>
      simp [psKernelEnvironmentIndexListLength, ih]

theorem psKernelEnvironmentIndexFindWorker_setWorker_same
    (fuel : Nat)
    (index : PsKernelEnvironmentIndex)
    (hash : Nat)
    (constants : List PsKernelConstantInfo) :
    psKernelEnvironmentIndexFindWorker
        fuel
        (psKernelEnvironmentIndexSetWorker
          fuel
          index
          hash
          constants)
        hash =
      constants := by
  induction fuel generalizing index hash with
  | zero =>
      rfl
  | succ remaining ih =>
      cases index <;>
        by_cases hParity : Nat.mod hash 2 = 0 <;>
        simp [
          psKernelEnvironmentIndexSetWorker,
          psKernelEnvironmentIndexFindWorker,
          hParity,
          ih
        ]

theorem psKernelEnvironmentIndexRemoveNameWorker_find_none
    (constants : List PsKernelConstantInfo)
    (name : PsKernelName) :
    psKernelFindConstantInList
        name
        (psKernelEnvironmentIndexRemoveNameWorker
          constants
          name) =
      Option.none := by
  induction constants with
  | nil =>
      rfl
  | cons info rest ih =>
      cases hName :
          psKernelNameEq
            (psKernelConstantInfoName info)
            name <;>
        simp [
          psKernelEnvironmentIndexRemoveNameWorker,
          psKernelFindConstantInList,
          hName,
          ih
        ]

theorem psKernelEnvironmentIndexRemoveName_find_none
    (name : PsKernelName)
    (constants : List PsKernelConstantInfo) :
    psKernelFindConstantInList
        name
        (psKernelEnvironmentIndexRemoveName
          name
          constants) =
      Option.none := by
  simpa [psKernelEnvironmentIndexRemoveName] using
    psKernelEnvironmentIndexRemoveNameWorker_find_none
      constants
      name


theorem psKernelEnvironmentIndexSetWorker_succ_is_branch
    (remaining : Nat)
    (index : PsKernelEnvironmentIndex)
    (hash : Nat)
    (constants : List PsKernelConstantInfo) :
    ∃ left right : PsKernelEnvironmentIndex,
      psKernelEnvironmentIndexSetWorker
          (Nat.succ remaining)
          index
          hash
          constants =
        PsKernelEnvironmentIndex.branch left right := by
  cases index <;>
    by_cases hParity : Nat.mod hash 2 = 0 <;>
    simp [
      psKernelEnvironmentIndexSetWorker,
      hParity
    ]

theorem psKernelEnvironmentIndexFind_setWorker_same_name
    (index : PsKernelEnvironmentIndex)
    (name : PsKernelName)
    (constants : List PsKernelConstantInfo) :
    psKernelEnvironmentIndexFind
        (psKernelEnvironmentIndexSetWorker
          16
          index
          (psKernelEnvironmentNameHash name)
          constants)
        name =
      constants := by
  obtain ⟨left, right, hSet⟩ :=
    psKernelEnvironmentIndexSetWorker_succ_is_branch
      15
      index
      (psKernelEnvironmentNameHash name)
      constants
  have hWorker :=
    psKernelEnvironmentIndexFindWorker_setWorker_same
      16
      index
      (psKernelEnvironmentNameHash name)
      constants
  rw [hSet] at hWorker ⊢
  exact hWorker

theorem psKernelEnvironmentIndexFind_build_cons
    (info : PsKernelConstantInfo)
    (rest : List PsKernelConstantInfo) :
    psKernelEnvironmentIndexFind
        (psKernelEnvironmentIndexBuild
          (List.cons info rest))
        (psKernelConstantInfoName info) =
      List.cons
        info
        (psKernelEnvironmentIndexRemoveName
          (psKernelConstantInfoName info)
          (psKernelEnvironmentIndexFindWorker
            16
            (psKernelEnvironmentIndexBuild rest)
            (psKernelEnvironmentNameHash
              (psKernelConstantInfoName info)))) := by
  change
    psKernelEnvironmentIndexFind
        (psKernelEnvironmentIndexSetWorker
          16
          (psKernelEnvironmentIndexBuild rest)
          (psKernelEnvironmentNameHash
            (psKernelConstantInfoName info))
          (List.cons
            info
            (psKernelEnvironmentIndexRemoveName
              (psKernelConstantInfoName info)
              (psKernelEnvironmentIndexFindWorker
                16
                (psKernelEnvironmentIndexBuild rest)
                (psKernelEnvironmentNameHash
                  (psKernelConstantInfoName info))))))
        (psKernelConstantInfoName info) =
      List.cons
        info
        (psKernelEnvironmentIndexRemoveName
          (psKernelConstantInfoName info)
          (psKernelEnvironmentIndexFindWorker
            16
            (psKernelEnvironmentIndexBuild rest)
            (psKernelEnvironmentNameHash
              (psKernelConstantInfoName info))))
  exact
    psKernelEnvironmentIndexFind_setWorker_same_name
      (psKernelEnvironmentIndexBuild rest)
      (psKernelConstantInfoName info)
      (List.cons
        info
        (psKernelEnvironmentIndexRemoveName
          (psKernelConstantInfoName info)
          (psKernelEnvironmentIndexFindWorker
            16
            (psKernelEnvironmentIndexBuild rest)
            (psKernelEnvironmentNameHash
              (psKernelConstantInfoName info)))))


theorem psKernelEnvironmentIndexFind_insert_has_head
    (index : PsKernelEnvironmentIndex)
    (info : PsKernelConstantInfo) :
    ∃ rest : List PsKernelConstantInfo,
      psKernelEnvironmentIndexFind
          (psKernelEnvironmentIndexInsert index info)
          (psKernelConstantInfoName info) =
        List.cons info rest := by
  cases index with
  | empty =>
      exact ⟨List.nil, rfl⟩
  | small constants =>
      cases h :
          Nat.ble
            (psKernelEnvironmentIndexListLength
              (List.cons
                info
                (psKernelEnvironmentIndexRemoveName
                  (psKernelConstantInfoName info)
                  constants)))
            psKernelEnvironmentIndexSmallLimit with
      | false =>
          refine ⟨
            psKernelEnvironmentIndexRemoveName
              (psKernelConstantInfoName info)
              (psKernelEnvironmentIndexFindWorker
                16
                (psKernelEnvironmentIndexBuild
                  (psKernelEnvironmentIndexRemoveName
                    (psKernelConstantInfoName info)
                    constants))
                (psKernelEnvironmentNameHash
                  (psKernelConstantInfoName info))),
            ?_⟩
          simpa [psKernelEnvironmentIndexInsert, h] using
            psKernelEnvironmentIndexFind_build_cons
              info
              (psKernelEnvironmentIndexRemoveName
                (psKernelConstantInfoName info)
                constants)
      | true =>
          refine ⟨
            psKernelEnvironmentIndexRemoveName
              (psKernelConstantInfoName info)
              constants,
            ?_⟩
          simp [
            psKernelEnvironmentIndexInsert,
            h,
            psKernelEnvironmentIndexFind
          ]
  | bucket constants =>
      refine ⟨
        psKernelEnvironmentIndexRemoveName
          (psKernelConstantInfoName info)
          (psKernelEnvironmentIndexFindWorker
            16
            (psKernelEnvironmentIndexBuild
              (psKernelEnvironmentIndexRemoveName
                (psKernelConstantInfoName info)
                constants))
            (psKernelEnvironmentNameHash
              (psKernelConstantInfoName info))),
        ?_⟩
      simpa [psKernelEnvironmentIndexInsert] using
        psKernelEnvironmentIndexFind_build_cons
          info
          (psKernelEnvironmentIndexRemoveName
            (psKernelConstantInfoName info)
            constants)
  | branch left right =>
      refine ⟨
        psKernelEnvironmentIndexRemoveName
          (psKernelConstantInfoName info)
          (psKernelEnvironmentIndexFindWorker
            16
            (PsKernelEnvironmentIndex.branch left right)
            (psKernelEnvironmentNameHash
              (psKernelConstantInfoName info))),
        ?_⟩
      simpa [psKernelEnvironmentIndexInsert] using
        psKernelEnvironmentIndexFind_setWorker_same_name
          (PsKernelEnvironmentIndex.branch left right)
          (psKernelConstantInfoName info)
          (List.cons
            info
            (psKernelEnvironmentIndexRemoveName
              (psKernelConstantInfoName info)
              (psKernelEnvironmentIndexFindWorker
                16
                (PsKernelEnvironmentIndex.branch left right)
                (psKernelEnvironmentNameHash
                  (psKernelConstantInfoName info)))))


theorem psKernelEnvironmentIndexRemoveName_find_other
    (constants : List PsKernelConstantInfo)
    (removed query : PsKernelName)
    (hDifferent :
      psKernelNameEq removed query = false) :
    psKernelFindConstantInList
        query
        (psKernelEnvironmentIndexRemoveName
          removed
          constants) =
      psKernelFindConstantInList
        query
        constants := by
  unfold psKernelEnvironmentIndexRemoveName
  induction constants with
  | nil =>
      rfl
  | cons info rest ih =>
      cases hRemoved :
          psKernelNameEq
            (psKernelConstantInfoName info)
            removed with
      | false =>
          simp [
            psKernelEnvironmentIndexRemoveNameWorker,
            psKernelFindConstantInList,
            hRemoved,
            ih
          ]
      | true =>
          have hInfoQuery :
              psKernelNameEq
                  (psKernelConstantInfoName info)
                  query =
                false := by
            cases hQuery :
                psKernelNameEq
                  (psKernelConstantInfoName info)
                  query with
            | false =>
                rfl
            | true =>
                have hRemovedSymm :
                    psKernelNameEq
                        removed
                        (psKernelConstantInfoName info) =
                      true := by
                  rw [
                    ← psKernelNameEq_symm_core
                      (psKernelConstantInfoName info)
                      removed
                  ]
                  exact hRemoved
                have hTrans :
                    psKernelNameEq removed query = true :=
                  psKernelNameEq_trans_core
                    removed
                    (psKernelConstantInfoName info)
                    query
                    hRemovedSymm
                    hQuery
                rw [hDifferent] at hTrans
                cases hTrans
          simp [
            psKernelEnvironmentIndexRemoveNameWorker,
            psKernelFindConstantInList,
            hRemoved,
            hInfoQuery,
            ih
          ]

theorem psKernelEnvironmentIndexFind_build_eq_worker
    (constants : List PsKernelConstantInfo)
    (name : PsKernelName) :
    psKernelEnvironmentIndexFind
        (psKernelEnvironmentIndexBuild constants)
        name =
      psKernelEnvironmentIndexFindWorker
        16
        (psKernelEnvironmentIndexBuild constants)
        (psKernelEnvironmentNameHash name) := by
  cases constants with
  | nil =>
      rfl
  | cons info rest =>
      let infoName :=
        psKernelConstantInfoName info
      let bucket :=
        psKernelEnvironmentIndexFindWorker
          16
          (psKernelEnvironmentIndexBuild rest)
          (psKernelEnvironmentNameHash infoName)
      let next :=
        List.cons
          info
          (psKernelEnvironmentIndexRemoveName
            infoName
            bucket)
      have hSetShape :=
        psKernelEnvironmentIndexSetWorker_succ_is_branch
          15
          (psKernelEnvironmentIndexBuild rest)
          (psKernelEnvironmentNameHash infoName)
          next
      rcases hSetShape with ⟨left, right, hSet⟩
      change
        psKernelEnvironmentIndexFind
            (psKernelEnvironmentIndexSetWorker
              16
              (psKernelEnvironmentIndexBuild rest)
              (psKernelEnvironmentNameHash infoName)
              next)
            name =
          psKernelEnvironmentIndexFindWorker
            16
            (psKernelEnvironmentIndexSetWorker
              16
              (psKernelEnvironmentIndexBuild rest)
              (psKernelEnvironmentNameHash infoName)
              next)
            (psKernelEnvironmentNameHash name)
      rw [hSet]
      rfl

theorem psKernelEnvironmentIndexFind_setWorker_eq_worker
    (index : PsKernelEnvironmentIndex)
    (setHash : Nat)
    (constants : List PsKernelConstantInfo)
    (name : PsKernelName) :
    psKernelEnvironmentIndexFind
        (psKernelEnvironmentIndexSetWorker
          16
          index
          setHash
          constants)
        name =
      psKernelEnvironmentIndexFindWorker
        16
        (psKernelEnvironmentIndexSetWorker
          16
          index
          setHash
          constants)
        (psKernelEnvironmentNameHash name) := by
  have hSetShape :=
    psKernelEnvironmentIndexSetWorker_succ_is_branch
      15
      index
      setHash
      constants
  rcases hSetShape with ⟨left, right, hSet⟩
  rw [hSet]
  rfl

theorem psKernelEnvironmentIndexBuild_refines_authoritative
    (constants : List PsKernelConstantInfo)
    (query : PsKernelName) :
    psKernelFindConstantInList
        query
        (psKernelEnvironmentIndexFind
          (psKernelEnvironmentIndexBuild constants)
          query) =
      psKernelFindConstantInList
        query
        constants := by
  induction constants generalizing query with
  | nil =>
      rfl
  | cons info rest ih =>
      let infoName :=
        psKernelConstantInfoName info
      let oldIndex :=
        psKernelEnvironmentIndexBuild rest
      let oldBucket :=
        psKernelEnvironmentIndexFindWorker
          16
          oldIndex
          (psKernelEnvironmentNameHash infoName)
      let newBucket :=
        List.cons
          info
          (psKernelEnvironmentIndexRemoveName
            infoName
            oldBucket)
      change
        psKernelFindConstantInList
            query
            (psKernelEnvironmentIndexFind
              (psKernelEnvironmentIndexSetWorker
                16
                oldIndex
                (psKernelEnvironmentNameHash infoName)
                newBucket)
              query) =
          psKernelFindConstantInList
            query
            (List.cons info rest)
      cases hSame :
          psKernelNameEq infoName query with
      | true =>
          have hHash :
              psKernelEnvironmentNameHash infoName =
                psKernelEnvironmentNameHash query :=
            psKernelEnvironmentNameHash_of_nameEq_true
              infoName
              query
              hSame
          have hCandidates :
              psKernelEnvironmentIndexFind
                  (psKernelEnvironmentIndexSetWorker
                    16
                    oldIndex
                    (psKernelEnvironmentNameHash infoName)
                    newBucket)
                  query =
                newBucket := by
            rw [hHash]
            exact
              psKernelEnvironmentIndexFind_setWorker_same_name
                oldIndex
                query
                newBucket
          have hSameRaw :
              psKernelNameEq
                  (psKernelConstantInfoName info)
                  query =
                true := by
            simpa [infoName] using hSame
          rw [hCandidates]
          simp [
            newBucket,
            psKernelFindConstantInList,
            hSameRaw
          ]
      | false =>
          have hRight :
              psKernelFindConstantInList
                  query
                  (List.cons info rest) =
                psKernelFindConstantInList query rest := by
            simp [
              psKernelFindConstantInList,
              infoName,
              hSame
            ]
          rw [hRight]
          by_cases hHash :
              psKernelEnvironmentNameHash infoName =
                psKernelEnvironmentNameHash query
          · have hCandidates :
                psKernelEnvironmentIndexFind
                    (psKernelEnvironmentIndexSetWorker
                      16
                      oldIndex
                      (psKernelEnvironmentNameHash infoName)
                      newBucket)
                    query =
                  newBucket := by
              rw [hHash]
              exact
                psKernelEnvironmentIndexFind_setWorker_same_name
                  oldIndex
                  query
                  newBucket
            rw [hCandidates]
            simp [
              newBucket,
              psKernelFindConstantInList,
              infoName,
              hSame
            ]
            rw [
              psKernelEnvironmentIndexRemoveName_find_other
                oldBucket
                infoName
                query
                hSame
            ]
            have hOldBucket :
                oldBucket =
                  psKernelEnvironmentIndexFind
                    oldIndex
                    query := by
              unfold oldBucket
              rw [hHash]
              exact
                (psKernelEnvironmentIndexFind_build_eq_worker
                  rest
                  query).symm
            rw [hOldBucket]
            exact ih query
          · rw [
              psKernelEnvironmentIndexFind_setWorker_eq_worker
                oldIndex
                (psKernelEnvironmentNameHash infoName)
                newBucket
                query
            ]
            rw [
              psKernelEnvironmentIndexFindWorker_setWorker_other_name_hash
                oldIndex
                infoName
                query
                newBucket
                hHash
            ]
            rw [
              ← psKernelEnvironmentIndexFind_build_eq_worker
                rest
                query
            ]
            exact ih query


/-
Regression for the public root-bucket index representation.  A root bucket
is readable by psKernelEnvironmentIndexFind, so insertion must retain all
existing authoritative name lookups, including for differently-named
declarations.  Previously the positive-fuel worker discarded this bucket.
-/
theorem psKernelEnvironmentIndexInsert_bucket_refines_authoritative
    (constants : List PsKernelConstantInfo)
    (info : PsKernelConstantInfo)
    (query : PsKernelName) :
    psKernelFindConstantInList
        query
        (psKernelEnvironmentIndexFind
          (psKernelEnvironmentIndexInsert
            (PsKernelEnvironmentIndex.bucket constants)
            info)
          query) =
      psKernelFindConstantInList
        query
        (List.cons info constants) := by
  have hBuild :=
    psKernelEnvironmentIndexBuild_refines_authoritative
      (List.cons
        info
        (psKernelEnvironmentIndexRemoveName
          (psKernelConstantInfoName info)
          constants))
      query
  calc
    psKernelFindConstantInList
        query
        (psKernelEnvironmentIndexFind
          (psKernelEnvironmentIndexInsert
            (PsKernelEnvironmentIndex.bucket constants)
            info)
          query) =
      psKernelFindConstantInList
        query
        (List.cons
          info
          (psKernelEnvironmentIndexRemoveName
            (psKernelConstantInfoName info)
            constants)) := by
          simpa [psKernelEnvironmentIndexInsert] using hBuild
    _ = psKernelFindConstantInList
          query
          (List.cons info constants) := by
      cases hSame :
          psKernelNameEq
            (psKernelConstantInfoName info)
            query with
      | true =>
          simp [psKernelFindConstantInList, hSame]
      | false =>
          simpa [psKernelFindConstantInList, hSame] using
            psKernelEnvironmentIndexRemoveName_find_other
              constants
              (psKernelConstantInfoName info)
              query
              hSame
