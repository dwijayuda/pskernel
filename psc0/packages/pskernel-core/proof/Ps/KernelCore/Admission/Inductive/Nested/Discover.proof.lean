import Ps.KernelCore.Admission.Inductive.Nested.Discover

theorem psKernelSimpleNestedFindFamily_nil
    (template : PsKernelExpr) :
    psKernelSimpleNestedFindFamily template List.nil =
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


theorem psKernelSimpleNestedFindFamily_some_matches
    (template : PsKernelExpr)
    (families : List PsKernelSimpleNestedAuxFamily)
    (family : PsKernelSimpleNestedAuxFamily)
    (h :
      psKernelSimpleNestedFindFamily
          template
          families =
        Option.some family) :
    psKernelExprEq family.nestedTemplate template = true := by
  induction families with
  | nil =>
      simp [psKernelSimpleNestedFindFamily] at h
  | cons head tail ih =>
      cases hEq :
          psKernelExprEq
            head.nestedTemplate
            template with
      | false =>
          simp [psKernelSimpleNestedFindFamily, hEq] at h
          exact ih h
      | true =>
          simp [psKernelSimpleNestedFindFamily, hEq] at h
          subst family
          exact hEq
