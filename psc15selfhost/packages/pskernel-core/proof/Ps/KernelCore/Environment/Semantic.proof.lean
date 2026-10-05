import Ps.KernelCore.Environment.Semantic

theorem psKernelNameListContains_nil
    (needle : PsKernelName) :
    psKernelNameListContains needle List.nil = false := by
  rfl

theorem psKernelNameHasDuplicates_nil :
    psKernelNameHasDuplicates List.nil = false := by
  rfl

theorem psKernelFindConstantInList_nil
    (name : PsKernelName) :
    psKernelFindConstantInList name List.nil = Option.none := by
  rfl

theorem psKernelReplaceEnvironmentConstant_nil
    (target : PsKernelName)
    (replacement : PsKernelConstantInfo) :
    psKernelReplaceEnvironmentConstant
      target replacement List.nil =
      List.nil := by
  rfl

theorem psKernelConstantListLength_eq_length
    (values : List PsKernelConstantInfo) :
    psKernelConstantListLength values = List.length values := by
  induction values with
  | nil =>
      rfl
  | cons head tail ih =>
      simp [psKernelConstantListLength, ih]
