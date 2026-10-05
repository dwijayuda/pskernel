import Ps.KernelCore.Admission.Quot.Admission

theorem psKernelAddQuot_idempotent_when_initialized
    (environment : PsKernelEnvironment)
    (h : environment.quotInitialized = true) :
    psKernelAddQuot environment = Except.ok environment := by
  simp [psKernelAddQuot, h]
