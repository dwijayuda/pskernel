import Ps.KernelCore.Admission.Inductive.Mutual.Header

theorem psKernelMutualNameListAppend_eq_append
    (left right : List PsKernelName) :
    psKernelMutualNameListAppend left right = List.append left right := by
  induction left with
  | nil =>
      rfl
  | cons head tail ih =>
      simp [psKernelMutualNameListAppend, ih]

theorem psKernelMutualConstructorShapeListAppend_eq_append
    (left right : List PsKernelSimpleMutualConstructorShape) :
    psKernelMutualConstructorShapeListAppend left right =
      List.append left right := by
  induction left with
  | nil =>
      rfl
  | cons head tail ih =>
      simp [psKernelMutualConstructorShapeListAppend, ih]

theorem psKernelSimpleMutualTypeCount_eq_length
    (types : List PsKernelSimpleMutualTypeDecl) :
    psKernelSimpleMutualTypeCount types = List.length types := by
  induction types with
  | nil =>
      rfl
  | cons head tail ih =>
      simp [psKernelSimpleMutualTypeCount, ih]
