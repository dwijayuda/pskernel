import Ps.KernelCore.Admission.Inductive.Common.Parameters

theorem psKernelReverseOpenBindersWorker_eq
    (values acc : List PsKernelOpenBinder) :
    psKernelReverseOpenBindersWorker values acc =
      List.append (List.reverse values) acc := by
  induction values generalizing acc with
  | nil =>
      simp [psKernelReverseOpenBindersWorker]
  | cons head tail ih =>
      simp [psKernelReverseOpenBindersWorker, ih, List.append_assoc]

theorem psKernelReverseOpenBinders_eq_reverse
    (values : List PsKernelOpenBinder) :
    psKernelReverseOpenBinders values = List.reverse values := by
  simp [psKernelReverseOpenBinders, psKernelReverseOpenBindersWorker_eq]

theorem psKernelOpenSimpleHeaderIndicesWithFuel_zero
    (session : PsKernelCheckerSession)
    (type : PsKernelExpr)
    (revIndices : List PsKernelOpenBinder) :
    psKernelOpenSimpleHeaderIndicesWithFuel
        0 session type revIndices =
      Except.error "simple inductive index budget exhausted" := by
  rfl
