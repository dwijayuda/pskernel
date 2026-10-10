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


/--
Exact old allocation mismatch: context allocation installs x.0 while the
unchanged state still allocates x.0. This is a historical model of the former
implementation, kept only in the regression companion.
-/
theorem psKernelAdmission_old_context_state_fresh_collision
    (environment : PsKernelEnvironment)
    (userName : PsKernelName)
    (type : PsKernelExpr)
    (binderInfo : PsKernelBinderInfo) :
    let session := psKernelMkCheckerSession environment [] 
      PsKernelDefinitionSafety.safe 100 100
    let opened := psKernelCheckerContextWithLocal
      session.context userName type binderInfo
    Prod.fst opened =
      Prod.fst (psKernelCheckerStateFreshName session.state userName) := by
  rfl

/-- Admission opening reserves its name before further checker allocation. -/
theorem psKernelAdmission_local_checker_names_distinct
    (environment : PsKernelEnvironment)
    (userName : PsKernelName)
    (type : PsKernelExpr)
    (binderInfo : PsKernelBinderInfo) :
    let session := psKernelMkCheckerSession environment []
      PsKernelDefinitionSafety.safe 100 100
    let opened := psKernelSessionWithLocal session userName type binderInfo
    psKernelNameEq (Prod.fst opened)
      (Prod.fst (psKernelCheckerStateFreshName
        (Prod.snd opened).state userName)) = false := by
  rfl
