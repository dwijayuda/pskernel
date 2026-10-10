import Ps.KernelCore.Admission.Inductive.Nested.Rebase

theorem psKernelSimpleNestedLookupRebaseWorker_nil
    (name : PsKernelName)
    (targetParams : List PsKernelOpenBinder) :
    psKernelSimpleNestedLookupRebaseWorker
        List.nil name targetParams =
      Option.none := by
  rfl

theorem psKernelSimpleNestedOpenConstructorParamsWithFuel_zero
    (type : PsKernelExpr)
    (count index : Nat)
    (rev : List PsKernelOpenBinder) :
    psKernelSimpleNestedOpenConstructorParamsWithFuel
        0 type count index rev =
      Except.error
        "nested constructor parameter budget exhausted" := by
  rfl

theorem psKernelSimpleNestedOpenRestorationParamsWithFuel_zero
    (expr : PsKernelExpr)
    (count : Nat)
    (kind : Option PsKernelSimpleNestedBinderKind)
    (index : Nat)
    (rev : List PsKernelOpenBinder) :
    psKernelSimpleNestedOpenRestorationParamsWithFuel
        0 expr count kind index rev =
      Except.error
        "nested restoration parameter budget exhausted" := by
  rfl
