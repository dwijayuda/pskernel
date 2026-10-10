import Ps.KernelCore.Admission.Inductive.Nested.ReservedNames

theorem psKernelSimpleNestedExprUsesReserved_bvar
    (index : Nat) :
    psKernelSimpleNestedExprUsesReserved
        (PsKernelExpr.bvar index) =
      false := by
  rfl

theorem psKernelSimpleNestedCheckCtorReserved_nil :
    psKernelSimpleNestedCheckCtorReserved List.nil =
      Except.ok Unit.unit := by
  rfl

theorem psKernelSimpleNestedCheckTypeReserved_nil :
    psKernelSimpleNestedCheckTypeReserved List.nil =
      Except.ok Unit.unit := by
  rfl
