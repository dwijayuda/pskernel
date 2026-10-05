import Ps.KernelCore.Admission.Declaration.Validation

theorem psKernelNameListsEq_nil :
    psKernelNameListsEq List.nil List.nil = true := by
  rfl

theorem psKernelNameMember_nil
    (name : PsKernelName) :
    psKernelNameMember name List.nil = false := by
  rfl

theorem psKernelLevelsHaveMVar_nil :
    psKernelLevelsHaveMVar List.nil = false := by
  rfl

theorem psKernelExprHasMVar_bvar
    (index : Nat) :
    psKernelExprHasMVar (PsKernelExpr.bvar index) = false := by
  rfl
