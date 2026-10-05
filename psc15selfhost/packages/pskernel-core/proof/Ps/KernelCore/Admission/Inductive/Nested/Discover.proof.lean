import Ps.KernelCore.Admission.Inductive.Nested.Discover

theorem psKernelSimpleNestedFindFamily_nil
    (name : PsKernelName) :
    psKernelSimpleNestedFindFamily name List.nil =
      Option.none := by
  rfl

theorem psKernelSimpleNestedFamilyListAppend_eq_append
    (left right : List PsKernelSimpleNestedAuxFamily) :
    psKernelSimpleNestedFamilyListAppend left right =
      List.append left right := by
  induction left with
  | nil =>
      rfl
  | cons head tail ih =>
      simp [psKernelSimpleNestedFamilyListAppend, ih]

theorem psKernelSimpleNestedTypeDeclListAppend_eq_append
    (left right : List PsKernelSimpleMutualTypeDecl) :
    psKernelSimpleNestedTypeDeclListAppend left right =
      List.append left right := by
  induction left with
  | nil =>
      rfl
  | cons head tail ih =>
      simp [psKernelSimpleNestedTypeDeclListAppend, ih]
