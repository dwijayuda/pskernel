import Ps.KernelCore.Environment.Operations

theorem psKernelEnvironmentAddUnchecked_size
    (environment : PsKernelEnvironment)
    (info : PsKernelConstantInfo) :
    psKernelEnvironmentSize
        (psKernelEnvironmentAddUnchecked environment info) =
      Nat.succ (psKernelEnvironmentSize environment) := by
  simp [psKernelEnvironmentAddUnchecked, psKernelEnvironmentSize,
    psKernelConstantListLength]

theorem psKernelEnvironmentAdd_rejects_duplicate_name
    (environment : PsKernelEnvironment)
    (info : PsKernelConstantInfo)
    (h :
      psKernelEnvironmentContains
        environment
        (psKernelConstantInfoName info) =
      true) :
    psKernelEnvironmentAdd environment info =
      Except.error "already declared" := by
  simp [psKernelEnvironmentAdd, h]

theorem psKernelEnvironmentAdd_rejects_duplicate_universe
    (environment : PsKernelEnvironment)
    (info : PsKernelConstantInfo)
    (hContains :
      psKernelEnvironmentContains
        environment
        (psKernelConstantInfoName info) =
      false)
    (hDuplicates :
      psKernelNameHasDuplicates
        (psKernelConstantInfoLevelParams info) =
      true) :
    psKernelEnvironmentAdd environment info =
      Except.error "duplicate universe parameter" := by
  simp [psKernelEnvironmentAdd, hContains, hDuplicates]

theorem psKernelEnvironmentAdd_success
    (environment : PsKernelEnvironment)
    (info : PsKernelConstantInfo)
    (hContains :
      psKernelEnvironmentContains
        environment
        (psKernelConstantInfoName info) =
      false)
    (hDuplicates :
      psKernelNameHasDuplicates
        (psKernelConstantInfoLevelParams info) =
      false) :
    psKernelEnvironmentAdd environment info =
      Except.ok (psKernelEnvironmentAddUnchecked environment info) := by
  simp [psKernelEnvironmentAdd, hContains, hDuplicates]

theorem psKernelEnvironmentMarkQuotInitialized_true
    (environment : PsKernelEnvironment)
    (h : environment.quotInitialized = true) :
    psKernelEnvironmentMarkQuotInitialized environment = environment := by
  simp [psKernelEnvironmentMarkQuotInitialized, h]

theorem psKernelEnvironmentMarkQuotInitialized_sets_true
    (environment : PsKernelEnvironment)
    (h : environment.quotInitialized = false) :
    (psKernelEnvironmentMarkQuotInitialized environment).quotInitialized =
      true := by
  simp [psKernelEnvironmentMarkQuotInitialized, h]


theorem psKernelEnvironmentAddUnchecked_constants
    (environment : PsKernelEnvironment)
    (info : PsKernelConstantInfo) :
    (psKernelEnvironmentAddUnchecked environment info).constants =
      List.cons info environment.constants := by
  rfl

theorem psKernelEnvironmentAddUnchecked_quot
    (environment : PsKernelEnvironment)
    (info : PsKernelConstantInfo) :
    (psKernelEnvironmentAddUnchecked environment info).quotInitialized =
      environment.quotInitialized := by
  rfl

theorem psKernelEnvironmentAddUnchecked_runtime
    (environment : PsKernelEnvironment)
    (info : PsKernelConstantInfo) :
    (psKernelEnvironmentAddUnchecked environment info).runtime =
      environment.runtime := by
  rfl

theorem psKernelEnvironmentAddUnchecked_semantic
    (environment : PsKernelEnvironment)
    (info : PsKernelConstantInfo) :
    psKernelEnvironmentSemantic
        (psKernelEnvironmentAddUnchecked environment info) =
      PsKernelEnvironmentSemantic.mk
        (List.cons info environment.constants)
        environment.quotInitialized := by
  rfl
