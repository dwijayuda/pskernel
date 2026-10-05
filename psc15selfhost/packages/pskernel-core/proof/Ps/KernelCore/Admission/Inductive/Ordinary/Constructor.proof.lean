import Ps.KernelCore.Admission.Inductive.Ordinary.Constructor

theorem psKernelOpenBinderListAppend_eq_append
    (left right : List PsKernelOpenBinder) :
    psKernelOpenBinderListAppend left right = List.append left right := by
  induction left with
  | nil =>
      rfl
  | cons head tail ih =>
      simp [psKernelOpenBinderListAppend, ih]

theorem psKernelReverseRecursiveFieldsWorker_eq
    (values acc : List PsKernelSimpleRecursiveField) :
    psKernelReverseRecursiveFieldsWorker values acc =
      List.append (List.reverse values) acc := by
  induction values generalizing acc with
  | nil =>
      simp [psKernelReverseRecursiveFieldsWorker]
  | cons head tail ih =>
      simp [psKernelReverseRecursiveFieldsWorker, ih, List.append_assoc]

theorem psKernelOpenSimpleConstructorParamsWithFuel_zero
    (session : PsKernelCheckerSession)
    (params : List PsKernelOpenBinder)
    (type : PsKernelExpr) :
    psKernelOpenSimpleConstructorParamsWithFuel
        0 session params type =
      Except.error
        "simple inductive constructor parameter budget exhausted" := by
  rfl

theorem psKernelOpenSimpleConstructorFieldsWithFuel_zero
    (session : PsKernelCheckerSession)
    (target : PsKernelName)
    (levels : List PsKernelLevel)
    (params : List PsKernelOpenBinder)
    (numIndices : Nat)
    (resultLevel : PsKernelLevel)
    (type : PsKernelExpr)
    (revFields : List PsKernelOpenBinder)
    (revRecursive : List PsKernelSimpleRecursiveField) :
    psKernelOpenSimpleConstructorFieldsWithFuel
        0 session target levels params numIndices resultLevel
        type revFields revRecursive =
      Except.error "simple inductive field budget exhausted" := by
  rfl
