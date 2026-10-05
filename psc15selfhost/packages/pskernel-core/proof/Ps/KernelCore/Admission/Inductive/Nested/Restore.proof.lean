import Ps.KernelCore.Admission.Inductive.Nested.Restore

theorem psKernelSimpleNestedFamilyListLength_eq_length
    (families : List PsKernelSimpleNestedAuxFamily) :
    psKernelSimpleNestedFamilyListLength families =
      List.length families := by
  induction families with
  | nil =>
      rfl
  | cons head tail ih =>
      simp [psKernelSimpleNestedFamilyListLength, ih]

theorem psKernelSimpleNestedAddCtorCopiesWorker_nil
    (transformed work : PsKernelEnvironment)
    (families : List PsKernelSimpleNestedAuxFamily)
    (renames : List (Prod PsKernelName PsKernelName))
    (canonicalParams : List PsKernelOpenBinder)
    (numParams : Nat) :
    psKernelSimpleNestedAddCtorCopiesWorker
        List.nil transformed work families renames
        canonicalParams numParams =
      Except.ok work := by
  rfl

theorem psKernelSimpleNestedAddOriginalsWorker_nil
    (transformed work : PsKernelEnvironment)
    (originalNames : List PsKernelName)
    (canonicalParams : List PsKernelOpenBinder)
    (numParams : Nat)
    (families : List PsKernelSimpleNestedAuxFamily)
    (renames : List (Prod PsKernelName PsKernelName)) :
    psKernelSimpleNestedAddOriginalsWorker
        List.nil transformed work originalNames canonicalParams
        numParams families renames =
      Except.ok work := by
  rfl

theorem psKernelSimpleNestedAddAuxRecursorsWorker_nil
    (allFamilies : List PsKernelSimpleNestedAuxFamily)
    (transformed work : PsKernelEnvironment)
    (originalNames : List PsKernelName)
    (canonicalParams : List PsKernelOpenBinder)
    (numParams : Nat)
    (renames : List (Prod PsKernelName PsKernelName)) :
    psKernelSimpleNestedAddAuxRecursorsWorker
        List.nil allFamilies transformed work originalNames
        canonicalParams numParams renames =
      Except.ok work := by
  rfl
