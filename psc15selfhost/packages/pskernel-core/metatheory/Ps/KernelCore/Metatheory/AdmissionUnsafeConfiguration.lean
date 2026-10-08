import Ps.KernelCore.Metatheory.AdmissionDefinitionTransactionConfiguration

/-
Unsafe recursive definition admission is a two-environment transaction.

The header is checked against the original environment.  The body is checked
against the *work* environment that already contains the recursive definition.

The work environment's accelerated index must independently refine its
authoritative constants.  This theorem exposes that premise explicitly;
closing index preservation under psKernelEnvironmentAdd is a separate proof
obligation, not a silently trusted theorem or an invented typing certificate.
-/

theorem psKernelAddDefinition_unsafe_configuration_refines_of_work_index
    (fuel : Nat)
    (environment result : PsKernelEnvironment)
    (value : PsKernelDefinitionInfo)
    (maxRecDepth maxNatSize : Nat)
    (hUnsafe : value.safety = PsKernelDefinitionSafety.unsafeDef)
    (hIndex : PsKernelEnvironmentIndexRefines environment)
    (hWorkIndex : PsKernelEnvironmentIndexRefines result)
    (hNative : PsKernelNativeReductionSoundLaw)
    (hString : PsKernelStringEqSoundLaw)
    (hRun :
      psKernelAddDefinition
          fuel environment value maxRecDepth maxNatSize =
        Except.ok result) :
    (∃ (headerType bodyType : PsKernelExpr) (level : PsKernelLevel),
      PsKernelTypingJudgment
          environment psKernelLocalContextEmpty
          value.base.type headerType ∧
        PsKernelReductionClosure
          environment psKernelLocalContextEmpty
          headerType (PsKernelExpr.sort level) ∧
        PsKernelTypingJudgment
          result psKernelLocalContextEmpty
          value.value bodyType ∧
        PsKernelDefEqJudgment
          result psKernelLocalContextEmpty
          bodyType value.base.type) ∧
      PsKernelDeclarationExtension
        environment result (PsKernelConstantInfo.defnInfo value) := by
  let headerSession :=
    psKernelMkCheckerSession
      environment value.base.levelParams
      PsKernelDefinitionSafety.unsafeDef
      maxRecDepth maxNatSize
  have hHeaderInitial :
      PsKernelCheckerConfigurationSound
        headerSession.context headerSession.state :=
    psKernelMkCheckerSession_configuration_sound
      environment value.base.levelParams
      PsKernelDefinitionSafety.unsafeDef
      maxRecDepth maxNatSize hIndex
  unfold psKernelAddDefinition at hRun
  rw [hUnsafe] at hRun
  cases hHeader :
      psKernelCheckConstantBaseWithSession
        fuel headerSession value.base with
  | error error =>
      simp [headerSession, hHeader] at hRun
  | ok afterHeader =>
      obtain ⟨headerType, level, hHeaderTyping, hHeaderSort, _⟩ :=
        psKernelCheckConstantBaseWithSession_configuration_refines
          fuel hNative hString
          headerSession afterHeader value.base
          hHeaderInitial hHeader
      cases hAdd :
          psKernelEnvironmentAdd
            environment (PsKernelConstantInfo.defnInfo value) with
      | error error =>
          simp [headerSession, hHeader, hAdd] at hRun
      | ok work =>
          let bodySession :=
            psKernelMkCheckerSession
              work value.base.levelParams
              PsKernelDefinitionSafety.unsafeDef
              maxRecDepth maxNatSize
          cases hBody :
              psKernelCheckDefinitionBodyWithSession
                fuel bodySession value with
          | error error =>
              simp [
                headerSession, hHeader, hAdd, bodySession, hBody
              ] at hRun
          | ok afterBody =>
              have hWorkResult : work = result := by
                simpa [
                  headerSession, hHeader, hAdd, bodySession, hBody
                ] using hRun
              subst result
              have hBodyInitial :
                  PsKernelCheckerConfigurationSound
                    bodySession.context bodySession.state :=
                psKernelMkCheckerSession_configuration_sound
                  work value.base.levelParams
                  PsKernelDefinitionSafety.unsafeDef
                  maxRecDepth maxNatSize hWorkIndex
              obtain ⟨bodyType, hBodyTyping, hBodyEq, _⟩ :=
                psKernelCheckDefinitionBodyWithSession_configuration_refines
                  fuel hNative hString
                  bodySession afterBody value
                  hBodyInitial hBody
              constructor
              · refine ⟨headerType, bodyType, level, ?_, ?_, ?_, ?_⟩
                · simpa [
                    headerSession, psKernelMkCheckerSession,
                    psKernelCheckerContextEmpty
                  ] using hHeaderTyping
                · simpa [
                    headerSession, psKernelMkCheckerSession,
                    psKernelCheckerContextEmpty
                  ] using hHeaderSort
                · simpa [
                    bodySession, psKernelMkCheckerSession,
                    psKernelCheckerContextEmpty
                  ] using hBodyTyping
                · simpa [
                    bodySession, psKernelMkCheckerSession,
                    psKernelCheckerContextEmpty
                  ] using hBodyEq
              · exact
                  psKernelEnvironmentAdd_success_refines_extension
                    environment work
                    (PsKernelConstantInfo.defnInfo value)
                    hAdd
