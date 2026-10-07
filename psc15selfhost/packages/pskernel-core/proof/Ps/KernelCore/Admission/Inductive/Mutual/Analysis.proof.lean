import Ps.KernelCore.Admission.Inductive.Mutual.Analysis

theorem psKernelSimpleMutualNames_nil :
    psKernelSimpleMutualNames List.nil = List.nil := by
  rfl

theorem psKernelSimpleMutualContainsConst_bvar
    (targets : List PsKernelName)
    (index : Nat) :
    psKernelSimpleMutualContainsConst
        targets
        (PsKernelExpr.bvar index) =
      false := by
  rfl

theorem psKernelSimpleMutualTargetIndexWorker_nil
    (name : PsKernelName)
    (index : Nat) :
    psKernelSimpleMutualTargetIndexWorker
        name List.nil index =
      Option.none := by
  rfl

theorem psKernelMutualTypeShapeListGet_nil
    (index : Nat) :
    psKernelMutualTypeShapeListGet
        List.nil index =
      Option.none := by
  rfl

theorem psKernelReverseMutualRecursiveFieldsWorker_eq
    (values acc : List PsKernelSimpleMutualRecursiveField) :
    psKernelReverseMutualRecursiveFieldsWorker values acc =
      List.append (List.reverse values) acc := by
  induction values generalizing acc with
  | nil =>
      simp [psKernelReverseMutualRecursiveFieldsWorker]
  | cons head tail ih =>
      simp [psKernelReverseMutualRecursiveFieldsWorker, ih, List.append_assoc]

theorem psKernelAnalyzeSimpleMutualRecursiveArgumentWithFuel_zero
    (checkerFuel : Nat)
    (session : PsKernelCheckerSession)
    (targets : List PsKernelName)
    (shapes : List PsKernelSimpleMutualTypeShape)
    (levels : List PsKernelLevel)
    (params : List PsKernelOpenBinder)
    (field : PsKernelOpenBinder)
    (domain : PsKernelExpr)
    (revArgs : List PsKernelOpenBinder)
    (applied : PsKernelExpr) :
    psKernelAnalyzeSimpleMutualRecursiveArgumentWithFuel
        0 checkerFuel session targets shapes levels params field domain revArgs applied =
      Except.error "mutual recursive-argument budget exhausted" := by
  rfl

theorem psKernelOpenSimpleMutualConstructorFieldsWithFuel_app_preserves_raw
    (fuel : Nat)
    (session : PsKernelCheckerSession)
    (targets : List PsKernelName)
    (shapes : List PsKernelSimpleMutualTypeShape)
    (levels : List PsKernelLevel)
    (params : List PsKernelOpenBinder)
    (resultLevel : PsKernelLevel)
    (fn arg : PsKernelExpr)
    (revFields : List PsKernelOpenBinder)
    (revRecursive : List PsKernelSimpleMutualRecursiveField) :
    psKernelOpenSimpleMutualConstructorFieldsWithFuel
        (Nat.succ fuel)
        session
        targets
        shapes
        levels
        params
        resultLevel
        (PsKernelExpr.app fn arg)
        revFields
        revRecursive =
      Except.ok
        (PsKernelMutualOpenFieldsResult.mk
          session
          (psKernelReverseOpenBinders revFields)
          (psKernelReverseMutualRecursiveFields revRecursive)
          (PsKernelExpr.app fn arg)) := by
  rfl
