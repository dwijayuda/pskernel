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
