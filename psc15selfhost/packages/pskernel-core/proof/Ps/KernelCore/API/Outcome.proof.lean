import Ps.KernelCore.API.Outcome

theorem psKernelErrorOutcome_rejected
    (message : String) :
    psKernelErrorOutcome
        (PsKernelError.rejectedInvalid message) =
      PsKernelOutcome.rejectedInvalid := by
  rfl

theorem psKernelErrorOutcome_declined
    (message : String) :
    psKernelErrorOutcome
        (PsKernelError.declinedUnsupported message) =
      PsKernelOutcome.declinedUnsupported := by
  rfl

theorem psKernelErrorOutcome_resource
    (resource : PsKernelResourceError)
    (message : String) :
    psKernelErrorOutcome
        (PsKernelError.resourceExhausted resource message) =
      PsKernelOutcome.resourceExhausted := by
  rfl

theorem psKernelErrorOutcome_internal
    (message : String) :
    psKernelErrorOutcome
        (PsKernelError.internalError message) =
      PsKernelOutcome.internalError := by
  rfl
