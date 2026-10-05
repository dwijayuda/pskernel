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


theorem psKernelAddDefinition_safe_rejects_header_error
    (fuel : Nat)
    (environment : PsKernelEnvironment)
    (value : PsKernelDefinitionInfo)
    (maxRecDepth maxNatSize : Nat)
    (error : String)
    (hSafety : value.safety = PsKernelDefinitionSafety.safe)
    (hHeader :
      psKernelCheckConstantBaseWithSession
          fuel
          (psKernelMkCheckerSession
            environment
            value.base.levelParams
            PsKernelDefinitionSafety.safe
            maxRecDepth
            maxNatSize)
          value.base =
        Except.error error) :
    psKernelAddDefinition
        fuel environment value maxRecDepth maxNatSize =
      Except.error error := by
  simp [psKernelAddDefinition, hSafety, hHeader]

theorem psKernelAddDefinition_safe_rejects_body_error
    (fuel : Nat)
    (environment : PsKernelEnvironment)
    (value : PsKernelDefinitionInfo)
    (maxRecDepth maxNatSize : Nat)
    (afterHeader : PsKernelCheckerSession)
    (error : String)
    (hSafety : value.safety = PsKernelDefinitionSafety.safe)
    (hHeader :
      psKernelCheckConstantBaseWithSession
          fuel
          (psKernelMkCheckerSession
            environment
            value.base.levelParams
            PsKernelDefinitionSafety.safe
            maxRecDepth
            maxNatSize)
          value.base =
        Except.ok afterHeader)
    (hBody :
      psKernelCheckDefinitionBodyWithSession
          fuel
          afterHeader
          value =
        Except.error error) :
    psKernelAddDefinition
        fuel environment value maxRecDepth maxNatSize =
      Except.error error := by
  simp [
    psKernelAddDefinition,
    hSafety,
    hHeader,
    hBody
  ]

theorem psKernelAddDefinition_safe_adds_only_after_checks
    (fuel : Nat)
    (environment : PsKernelEnvironment)
    (value : PsKernelDefinitionInfo)
    (maxRecDepth maxNatSize : Nat)
    (afterHeader afterBody : PsKernelCheckerSession)
    (hSafety : value.safety = PsKernelDefinitionSafety.safe)
    (hHeader :
      psKernelCheckConstantBaseWithSession
          fuel
          (psKernelMkCheckerSession
            environment
            value.base.levelParams
            PsKernelDefinitionSafety.safe
            maxRecDepth
            maxNatSize)
          value.base =
        Except.ok afterHeader)
    (hBody :
      psKernelCheckDefinitionBodyWithSession
          fuel
          afterHeader
          value =
        Except.ok afterBody) :
    psKernelAddDefinition
        fuel environment value maxRecDepth maxNatSize =
      psKernelEnvironmentAdd
        environment
        (PsKernelConstantInfo.defnInfo value) := by
  simp [
    psKernelAddDefinition,
    hSafety,
    hHeader,
    hBody
  ]
