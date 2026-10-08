import Ps.KernelCore.Metatheory.AdmissionOrdinaryConfiguration

/-
Nonrecursive ordinary definition admission: the safe and partial branches
validate a header and then the body against the SAME authoritative environment,
before publishing the checked declaration.

This deliberately excludes unsafe recursive definitions.  Those first publish
a work environment and check their bodies under that extended environment;
proving their soundness requires a separate environment-index preservation
and recursive-work-environment refinement theorem.  They must not be silently
treated as ordinary closed-body admission.
-/

theorem psKernelAddDefinition_nonunsafe_configuration_refines
    (fuel : Nat)
    (environment result : PsKernelEnvironment)
    (value : PsKernelDefinitionInfo)
    (maxRecDepth maxNatSize : Nat)
    (hNotUnsafe :
      value.safety ≠ PsKernelDefinitionSafety.unsafeDef)
    (hIndex : PsKernelEnvironmentIndexRefines environment)
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
          environment psKernelLocalContextEmpty
          value.value bodyType ∧
        PsKernelDefEqJudgment
          environment psKernelLocalContextEmpty
          bodyType value.base.type) ∧
      PsKernelDeclarationExtension
        environment result (PsKernelConstantInfo.defnInfo value) := by
  let session :=
    psKernelMkCheckerSession
      environment value.base.levelParams PsKernelDefinitionSafety.safe
      maxRecDepth maxNatSize
  have hInitial :
      PsKernelCheckerConfigurationSound
        session.context session.state :=
    psKernelMkCheckerSession_configuration_sound
      environment value.base.levelParams
      PsKernelDefinitionSafety.safe
      maxRecDepth maxNatSize hIndex
  have hCheckedFlow :
      (match psKernelCheckConstantBaseWithSession
            fuel session value.base with
       | Except.error error => Except.error error
       | Except.ok afterHeader =>
           match psKernelCheckDefinitionBodyWithSession
               fuel afterHeader value with
           | Except.error error => Except.error error
           | Except.ok _ =>
               psKernelEnvironmentAdd
                 environment (PsKernelConstantInfo.defnInfo value)) =
        Except.ok result := by
    cases hSafety : value.safety with
    | unsafeDef =>
        exact False.elim (hNotUnsafe hSafety)
    | safe =>
        simpa [psKernelAddDefinition, hSafety, session] using hRun
    | partialDef =>
        simpa [psKernelAddDefinition, hSafety, session] using hRun
  cases hHeader :
      psKernelCheckConstantBaseWithSession
        fuel session value.base with
  | error error =>
      simp [hHeader] at hCheckedFlow
  | ok afterHeader =>
      obtain ⟨headerType, level, hHeaderTyping, hHeaderSort,
        hHeaderConfig⟩ :=
        psKernelCheckConstantBaseWithSession_configuration_refines
          fuel hNative hString session afterHeader
          value.base hInitial hHeader
      have hHeaderContext :
          afterHeader.context = session.context :=
        psKernelCheckConstantBaseWithSession_success_preserves_context
          fuel session afterHeader value.base hHeader
      have hBodyInitial :
          PsKernelCheckerConfigurationSound
            afterHeader.context afterHeader.state := by
        simpa [hHeaderContext] using hHeaderConfig
      cases hBody :
          psKernelCheckDefinitionBodyWithSession
            fuel afterHeader value with
      | error error =>
          simp [hHeader, hBody] at hCheckedFlow
      | ok afterBody =>
          obtain ⟨bodyType, hBodyTyping, hBodyEq, hBodyConfig⟩ :=
            psKernelCheckDefinitionBodyWithSession_configuration_refines
              fuel hNative hString
              afterHeader afterBody value
              hBodyInitial hBody
          have hAdd :
              psKernelEnvironmentAdd
                  environment (PsKernelConstantInfo.defnInfo value) =
                Except.ok result := by
            simpa [hHeader, hBody] using hCheckedFlow
          constructor
          · refine ⟨headerType, bodyType, level, ?_, ?_, ?_, ?_⟩
            · simpa [
                session, psKernelMkCheckerSession,
                psKernelCheckerContextEmpty
              ] using hHeaderTyping
            · simpa [
                session, psKernelMkCheckerSession,
                psKernelCheckerContextEmpty
              ] using hHeaderSort
            · simpa [
                hHeaderContext, session,
                psKernelMkCheckerSession,
                psKernelCheckerContextEmpty
              ] using hBodyTyping
            · simpa [
                hHeaderContext, session,
                psKernelMkCheckerSession,
                psKernelCheckerContextEmpty
              ] using hBodyEq
          · exact
              psKernelEnvironmentAdd_success_refines_extension
                environment result
                (PsKernelConstantInfo.defnInfo value)
                hAdd
