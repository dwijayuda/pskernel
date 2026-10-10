import Ps.KernelCore.Admission.Inductive.Nested.RestoreExpr

theorem psKernelSimpleNestedFindAuxByName_nil
    (name : PsKernelName) :
    psKernelSimpleNestedFindAuxByName name List.nil =
      Option.none := by
  rfl

theorem psKernelSimpleNestedFindRename_nil
    (name : PsKernelName) :
    psKernelSimpleNestedFindRename name List.nil =
      Option.none := by
  rfl

theorem psKernelSimpleNestedMapExprList_nil
    (transform : PsKernelExpr -> PsKernelExpr) :
    psKernelSimpleNestedMapExprList transform List.nil =
      List.nil := by
  rfl

theorem psKernelSimpleNestedRestoreOpenWithFuel_zero
    (families : List PsKernelSimpleNestedAuxFamily)
    (renames : List (Prod PsKernelName PsKernelName))
    (canonicalParams currentParams : List PsKernelOpenBinder)
    (numParams : Nat)
    (expr : PsKernelExpr) :
    psKernelSimpleNestedRestoreOpenWithFuel
        0 families renames canonicalParams currentParams numParams expr =
      expr := by
  rfl
