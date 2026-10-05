import Ps.KernelCore.Runtime.Acceleration.EnvironmentIndex

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
      simp [
        psKernelEnvironmentIndexSetWorker,
        psKernelEnvironmentIndexFindWorker,
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
      simp [
        psKernelEnvironmentIndexRemoveNameWorker,
        psKernelFindConstantInList,
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
  change
    psKernelEnvironmentIndexFindWorker
        16
        (psKernelEnvironmentIndexSetWorker
          16
          index
          (psKernelEnvironmentNameHash name)
          constants)
        (psKernelEnvironmentNameHash name) =
      constants
  exact
    psKernelEnvironmentIndexFindWorker_setWorker_same
      16
      index
      (psKernelEnvironmentNameHash name)
      constants

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
