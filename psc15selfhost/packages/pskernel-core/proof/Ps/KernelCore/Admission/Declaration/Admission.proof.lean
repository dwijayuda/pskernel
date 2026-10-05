import Ps.KernelCore.Admission.Declaration.Admission

theorem psKernelMutualWorkEnvironment_nil
    (environment : PsKernelEnvironment) :
    psKernelMutualWorkEnvironment List.nil environment = environment := by
  rfl

theorem psKernelCheckMutualHeaders_nil
    (fuel : Nat)
    (environment : PsKernelEnvironment)
    (first : PsKernelDefinitionInfo)
    (maxRecDepth maxNatSize : Nat)
    (seen : List PsKernelName) :
    psKernelCheckMutualHeaders
        List.nil fuel environment first
        maxRecDepth maxNatSize seen =
      Except.ok Unit.unit := by
  rfl

theorem psKernelCheckMutualBodies_nil
    (fuel : Nat)
    (environment : PsKernelEnvironment)
    (safety : PsKernelDefinitionSafety)
    (maxRecDepth maxNatSize : Nat) :
    psKernelCheckMutualBodies
        List.nil fuel environment safety
        maxRecDepth maxNatSize =
      Except.ok Unit.unit := by
  rfl

theorem psKernelAddMutualDefinitions_empty
    (fuel : Nat)
    (environment : PsKernelEnvironment)
    (maxRecDepth maxNatSize : Nat) :
    psKernelAddMutualDefinitions
        fuel environment List.nil maxRecDepth maxNatSize =
      Except.error "invalid empty mutual definition" := by
  rfl
