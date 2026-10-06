import Ps.KernelCore.Admission.Declaration.Admission
import Ps.KernelCore.Metatheory.AdmissionRefinement

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


theorem psKernelAddTheorem_rejects_non_prop
    (fuel : Nat)
    (environment : PsKernelEnvironment)
    (value : PsKernelTheoremInfo)
    (maxRecDepth maxNatSize : Nat)
    (afterHeader propSession : PsKernelCheckerSession)
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
    (hProp :
      psKernelSessionIsProp
          fuel
          afterHeader
          value.base.type =
        Except.ok (Prod.mk false propSession)) :
    psKernelAddTheorem
        fuel environment value maxRecDepth maxNatSize =
      Except.error "theorem type is not a proposition" := by
  simp [
    psKernelAddTheorem,
    hHeader,
    hProp
  ]

theorem psKernelAddTheorem_rejects_proof_type_mismatch
    (fuel : Nat)
    (environment : PsKernelEnvironment)
    (value : PsKernelTheoremInfo)
    (maxRecDepth maxNatSize : Nat)
    (afterHeader propSession checkedSession finalSession :
      PsKernelCheckerSession)
    (inferredType : PsKernelExpr)
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
    (hProp :
      psKernelSessionIsProp
          fuel
          afterHeader
          value.base.type =
        Except.ok (Prod.mk true propSession))
    (hClosed :
      psKernelCheckNoMVarNoFVar value.value =
        Except.ok Unit.unit)
    (hLevels :
      psKernelCheckLevelParams
          value.value
          value.base.levelParams =
        Except.ok Unit.unit)
    (hCheck :
      psKernelSessionCheck
          fuel
          propSession
          value.value =
        Except.ok (Prod.mk inferredType checkedSession))
    (hDefEq :
      psKernelSessionIsDefEq
          fuel
          checkedSession
          inferredType
          value.base.type =
        Except.ok (Prod.mk false finalSession)) :
    psKernelAddTheorem
        fuel environment value maxRecDepth maxNatSize =
      Except.error "theorem proof type mismatch" := by
  simp [
    psKernelAddTheorem,
    hHeader,
    hProp,
    hClosed,
    hLevels,
    hCheck,
    hDefEq
  ]

theorem psKernelAddTheorem_adds_only_after_proof_checks
    (fuel : Nat)
    (environment : PsKernelEnvironment)
    (value : PsKernelTheoremInfo)
    (maxRecDepth maxNatSize : Nat)
    (afterHeader propSession checkedSession finalSession :
      PsKernelCheckerSession)
    (inferredType : PsKernelExpr)
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
    (hProp :
      psKernelSessionIsProp
          fuel
          afterHeader
          value.base.type =
        Except.ok (Prod.mk true propSession))
    (hClosed :
      psKernelCheckNoMVarNoFVar value.value =
        Except.ok Unit.unit)
    (hLevels :
      psKernelCheckLevelParams
          value.value
          value.base.levelParams =
        Except.ok Unit.unit)
    (hCheck :
      psKernelSessionCheck
          fuel
          propSession
          value.value =
        Except.ok (Prod.mk inferredType checkedSession))
    (hDefEq :
      psKernelSessionIsDefEq
          fuel
          checkedSession
          inferredType
          value.base.type =
        Except.ok (Prod.mk true finalSession)) :
    psKernelAddTheorem
        fuel environment value maxRecDepth maxNatSize =
      psKernelEnvironmentAdd
        environment
        (PsKernelConstantInfo.thmInfo value) := by
  simp [
    psKernelAddTheorem,
    hHeader,
    hProp,
    hClosed,
    hLevels,
    hCheck,
    hDefEq
  ]


theorem psKernelAddDefinition_safe_success_refines_extension
    (fuel : Nat)
    (environment result : PsKernelEnvironment)
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
        Except.ok afterBody)
    (hSuccess :
      psKernelAddDefinition
          fuel environment value maxRecDepth maxNatSize =
        Except.ok result) :
    PsKernelDeclarationExtension
      environment
      result
      (PsKernelConstantInfo.defnInfo value) := by
  have hGate :=
    psKernelAddDefinition_safe_adds_only_after_checks
      fuel
      environment
      value
      maxRecDepth
      maxNatSize
      afterHeader
      afterBody
      hSafety
      hHeader
      hBody
  rw [hGate] at hSuccess
  exact
    psKernelEnvironmentAdd_success_refines_extension
      environment
      result
      (PsKernelConstantInfo.defnInfo value)
      hSuccess

theorem psKernelAddTheorem_success_refines_extension
    (fuel : Nat)
    (environment result : PsKernelEnvironment)
    (value : PsKernelTheoremInfo)
    (maxRecDepth maxNatSize : Nat)
    (afterHeader propSession checkedSession finalSession :
      PsKernelCheckerSession)
    (inferredType : PsKernelExpr)
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
    (hProp :
      psKernelSessionIsProp
          fuel
          afterHeader
          value.base.type =
        Except.ok (Prod.mk true propSession))
    (hClosed :
      psKernelCheckNoMVarNoFVar value.value =
        Except.ok Unit.unit)
    (hLevels :
      psKernelCheckLevelParams
          value.value
          value.base.levelParams =
        Except.ok Unit.unit)
    (hCheck :
      psKernelSessionCheck
          fuel
          propSession
          value.value =
        Except.ok (Prod.mk inferredType checkedSession))
    (hDefEq :
      psKernelSessionIsDefEq
          fuel
          checkedSession
          inferredType
          value.base.type =
        Except.ok (Prod.mk true finalSession))
    (hSuccess :
      psKernelAddTheorem
          fuel environment value maxRecDepth maxNatSize =
        Except.ok result) :
    PsKernelDeclarationExtension
      environment
      result
      (PsKernelConstantInfo.thmInfo value) := by
  have hGate :=
    psKernelAddTheorem_adds_only_after_proof_checks
      fuel
      environment
      value
      maxRecDepth
      maxNatSize
      afterHeader
      propSession
      checkedSession
      finalSession
      inferredType
      hHeader
      hProp
      hClosed
      hLevels
      hCheck
      hDefEq
  rw [hGate] at hSuccess
  exact
    psKernelEnvironmentAdd_success_refines_extension
      environment
      result
      (PsKernelConstantInfo.thmInfo value)
      hSuccess
