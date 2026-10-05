import Ps.KernelCore.Admission.Inductive.Types

theorem psKernelSimpleNameListUnique_nil :
    psKernelSimpleNameListUnique List.nil = true := by
  rfl

theorem psKernelLevelParamsToLevels_nil :
    psKernelLevelParamsToLevels List.nil = List.nil := by
  rfl

theorem psKernelOpenBinderExprs_nil :
    psKernelOpenBinderExprs List.nil = List.nil := by
  rfl
