import Ps.KernelCore.Admission.Declaration.Admission
import Ps.KernelCore.Metatheory.AdmissionMutualConfiguration
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


theorem psKernelAddAxiom_adds_only_after_check
    (fuel : Nat)
    (environment : PsKernelEnvironment)
    (value : PsKernelAxiomInfo)
    (maxRecDepth maxNatSize : Nat)
    (afterHeader : PsKernelCheckerSession)
    (hHeader :
      psKernelCheckConstantBaseWithSession
          fuel
          (psKernelMkCheckerSession
            environment
            value.base.levelParams
            (if value.isUnsafe then
              PsKernelDefinitionSafety.unsafeDef
             else
              PsKernelDefinitionSafety.safe)
            maxRecDepth
            maxNatSize)
          value.base =
        Except.ok afterHeader) :
    psKernelAddAxiom
        fuel environment value maxRecDepth maxNatSize =
      psKernelEnvironmentAdd
        environment
        (PsKernelConstantInfo.axiomInfo value) := by
  simp [
    psKernelAddAxiom,
    hHeader
  ]

theorem psKernelAddAxiom_success_refines_extension
    (fuel : Nat)
    (environment result : PsKernelEnvironment)
    (value : PsKernelAxiomInfo)
    (maxRecDepth maxNatSize : Nat)
    (afterHeader : PsKernelCheckerSession)
    (hHeader :
      psKernelCheckConstantBaseWithSession
          fuel
          (psKernelMkCheckerSession
            environment
            value.base.levelParams
            (if value.isUnsafe then
              PsKernelDefinitionSafety.unsafeDef
             else
              PsKernelDefinitionSafety.safe)
            maxRecDepth
            maxNatSize)
          value.base =
        Except.ok afterHeader)
    (hSuccess :
      psKernelAddAxiom
          fuel environment value maxRecDepth maxNatSize =
        Except.ok result) :
    PsKernelDeclarationExtension
      environment
      result
      (PsKernelConstantInfo.axiomInfo value) := by
  have hGate :=
    psKernelAddAxiom_adds_only_after_check
      fuel environment value maxRecDepth maxNatSize
      afterHeader hHeader
  rw [hGate] at hSuccess
  exact
    psKernelEnvironmentAdd_success_refines_extension
      environment
      result
      (PsKernelConstantInfo.axiomInfo value)
      hSuccess

theorem psKernelAddDefinition_partial_adds_only_after_checks
    (fuel : Nat)
    (environment : PsKernelEnvironment)
    (value : PsKernelDefinitionInfo)
    (maxRecDepth maxNatSize : Nat)
    (afterHeader afterBody : PsKernelCheckerSession)
    (hSafety :
      value.safety = PsKernelDefinitionSafety.partialDef)
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

theorem psKernelAddDefinition_partial_success_refines_extension
    (fuel : Nat)
    (environment result : PsKernelEnvironment)
    (value : PsKernelDefinitionInfo)
    (maxRecDepth maxNatSize : Nat)
    (afterHeader afterBody : PsKernelCheckerSession)
    (hSafety :
      value.safety = PsKernelDefinitionSafety.partialDef)
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
    psKernelAddDefinition_partial_adds_only_after_checks
      fuel environment value maxRecDepth maxNatSize
      afterHeader afterBody hSafety hHeader hBody
  rw [hGate] at hSuccess
  exact
    psKernelEnvironmentAdd_success_refines_extension
      environment result
      (PsKernelConstantInfo.defnInfo value)
      hSuccess

theorem psKernelAddDefinition_unsafe_success_refines_extension
    (fuel : Nat)
    (environment work : PsKernelEnvironment)
    (value : PsKernelDefinitionInfo)
    (maxRecDepth maxNatSize : Nat)
    (afterHeader afterBody : PsKernelCheckerSession)
    (hSafety :
      value.safety = PsKernelDefinitionSafety.unsafeDef)
    (hHeader :
      psKernelCheckConstantBaseWithSession
          fuel
          (psKernelMkCheckerSession
            environment
            value.base.levelParams
            PsKernelDefinitionSafety.unsafeDef
            maxRecDepth
            maxNatSize)
          value.base =
        Except.ok afterHeader)
    (hAdd :
      psKernelEnvironmentAdd
          environment
          (PsKernelConstantInfo.defnInfo value) =
        Except.ok work)
    (hBody :
      psKernelCheckDefinitionBodyWithSession
          fuel
          (psKernelMkCheckerSession
            work
            value.base.levelParams
            PsKernelDefinitionSafety.unsafeDef
            maxRecDepth
            maxNatSize)
          value =
        Except.ok afterBody) :
    psKernelAddDefinition
        fuel environment value maxRecDepth maxNatSize =
      Except.ok work ∧
    PsKernelDeclarationExtension
      environment
      work
      (PsKernelConstantInfo.defnInfo value) := by
  constructor
  · simp [
      psKernelAddDefinition,
      hSafety,
      hHeader,
      hAdd,
      hBody
    ]
  · exact
      psKernelEnvironmentAdd_success_refines_extension
        environment work
        (PsKernelConstantInfo.defnInfo value)
        hAdd

theorem psKernelAddOpaque_adds_only_after_checks
    (fuel : Nat)
    (environment : PsKernelEnvironment)
    (value : PsKernelOpaqueInfo)
    (maxRecDepth maxNatSize : Nat)
    (afterHeader checkedSession finalSession :
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
          afterHeader
          value.value =
        Except.ok
          (Prod.mk inferredType checkedSession))
    (hDefEq :
      psKernelSessionIsDefEq
          fuel
          checkedSession
          inferredType
          value.base.type =
        Except.ok (Prod.mk true finalSession)) :
    psKernelAddOpaque
        fuel environment value maxRecDepth maxNatSize =
      psKernelEnvironmentAdd
        environment
        (PsKernelConstantInfo.opaqueInfo value) := by
  simp [
    psKernelAddOpaque,
    hHeader,
    hClosed,
    hLevels,
    hCheck,
    hDefEq
  ]

theorem psKernelAddOpaque_success_refines_extension
    (fuel : Nat)
    (environment result : PsKernelEnvironment)
    (value : PsKernelOpaqueInfo)
    (maxRecDepth maxNatSize : Nat)
    (afterHeader checkedSession finalSession :
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
          afterHeader
          value.value =
        Except.ok
          (Prod.mk inferredType checkedSession))
    (hDefEq :
      psKernelSessionIsDefEq
          fuel
          checkedSession
          inferredType
          value.base.type =
        Except.ok (Prod.mk true finalSession))
    (hSuccess :
      psKernelAddOpaque
          fuel environment value maxRecDepth maxNatSize =
        Except.ok result) :
    PsKernelDeclarationExtension
      environment
      result
      (PsKernelConstantInfo.opaqueInfo value) := by
  have hGate :=
    psKernelAddOpaque_adds_only_after_checks
      fuel environment value maxRecDepth maxNatSize
      afterHeader checkedSession finalSession inferredType
      hHeader hClosed hLevels hCheck hDefEq
  rw [hGate] at hSuccess
  exact
    psKernelEnvironmentAdd_success_refines_extension
      environment result
      (PsKernelConstantInfo.opaqueInfo value)
      hSuccess


theorem psKernelAddMutualDefinitions_success_refines_extension
    (fuel : Nat)
    (environment result : PsKernelEnvironment)
    (values : List PsKernelDefinitionInfo)
    (maxRecDepth maxNatSize : Nat)
    (hSuccess :
      psKernelAddMutualDefinitions
          fuel
          environment
          values
          maxRecDepth
          maxNatSize =
        Except.ok result) :
    PsKernelEnvironmentExtendsBy
      environment
      result
      (List.reverse
        (List.map
          (fun value : PsKernelDefinitionInfo =>
            PsKernelConstantInfo.defnInfo value)
          values)) := by
  cases values with
  | nil =>
      simp [psKernelAddMutualDefinitions] at hSuccess
  | cons first rest =>
      cases hSafe :
          psKernelDefinitionSafetyIsSafe first.safety with
      | true =>
          simp [
            psKernelAddMutualDefinitions,
            hSafe
          ] at hSuccess
      | false =>
          cases hHeaders :
              psKernelCheckMutualHeaders
                (List.cons first rest)
                fuel
                environment
                first
                maxRecDepth
                maxNatSize
                List.nil with
          | error error =>
              simp [
                psKernelAddMutualDefinitions,
                hSafe,
                hHeaders
              ] at hSuccess
          | ok headerResult =>
              cases headerResult
              let work :=
                psKernelMutualWorkEnvironment
                  (List.cons first rest)
                  environment
              cases hBodies :
                  psKernelCheckMutualBodies
                    (List.cons first rest)
                    fuel
                    work
                    first.safety
                    maxRecDepth
                    maxNatSize with
              | error error =>
                  simp [
                    psKernelAddMutualDefinitions,
                    hSafe,
                    hHeaders,
                    work,
                    hBodies
                  ] at hSuccess
              | ok bodyResult =>
                  cases bodyResult
                  simp [
                    psKernelAddMutualDefinitions,
                    hSafe,
                    hHeaders,
                    work,
                    hBodies
                  ] at hSuccess
                  subst result
                  exact
                    psKernelMutualWorkEnvironment_refines_extension
                      (List.cons first rest)
                      environment
