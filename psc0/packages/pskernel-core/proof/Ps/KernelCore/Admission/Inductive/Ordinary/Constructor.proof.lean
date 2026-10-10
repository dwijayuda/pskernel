import Ps.KernelCore.Admission.Inductive.Ordinary.Constructor
import Ps.KernelCore.Metatheory.Inductive
import Ps.KernelCore.Metatheory.AdmissionConstructorParamsConfiguration

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

theorem psKernelOpenSimpleConstructorParamsWithFuel_app_rejects
    (fuel : Nat)
    (session : PsKernelCheckerSession)
    (param : PsKernelOpenBinder)
    (rest : List PsKernelOpenBinder)
    (fn arg : PsKernelExpr) :
    psKernelOpenSimpleConstructorParamsWithFuel
        (Nat.succ fuel)
        session
        (List.cons param rest)
        (PsKernelExpr.app fn arg) =
      Except.error
        "simple inductive constructor has fewer parameters than the datatype" := by
  rfl

theorem psKernelOpenSimpleConstructorFieldsWithFuel_app_preserves_raw
    (fuel : Nat)
    (session : PsKernelCheckerSession)
    (target : PsKernelName)
    (levels : List PsKernelLevel)
    (params : List PsKernelOpenBinder)
    (numIndices : Nat)
    (resultLevel : PsKernelLevel)
    (fn arg : PsKernelExpr)
    (revFields : List PsKernelOpenBinder)
    (revRecursive : List PsKernelSimpleRecursiveField) :
    psKernelOpenSimpleConstructorFieldsWithFuel
        (Nat.succ fuel)
        session
        target
        levels
        params
        numIndices
        resultLevel
        (PsKernelExpr.app fn arg)
        revFields
        revRecursive =
      Except.ok
        (PsKernelOpenFieldsResult.mk
          session
          (psKernelReverseOpenBinders revFields)
          (psKernelReverseRecursiveFields revRecursive)
          (PsKernelExpr.app fn arg)) := by
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



theorem psKernelSimpleRecursiveOccurrenceDiagnostic_stuck_recursor
    (environment : PsKernelEnvironment)
    (target name : PsKernelName)
    (reduced : PsKernelExpr)
    (levels : List PsKernelLevel)
    (info : PsKernelRecursorInfo)
    (hContains : psKernelExprContainsConst target reduced = true)
    (hHead : psKernelExprGetAppFn reduced = PsKernelExpr.const name levels)
    (hRecursor : psKernelEnvironmentFind environment name =
      Option.some (PsKernelConstantInfo.recInfo info)) :
    psKernelSimpleRecursiveOccurrenceDiagnostic environment target reduced =
      "recursive argument contains the datatype under a stuck recursor" := by
  simp [psKernelSimpleRecursiveOccurrenceDiagnostic, hContains, hHead, hRecursor]
