import Ps.KernelCore.Metatheory.AdmissionDefinitionTransactionConfiguration

/-
Reusable checked value conversion:

A real checked inference followed by successful concrete DefEq establishes
independent typing and comparison evidence, with configuration preserved.
The infer-only checker is deliberately NOT substituted for checked inference.
-/

theorem psKernelSessionCheckThenDefEq_configuration_refines
    (fuel : Nat)
    (hNative : PsKernelNativeReductionSoundLaw)
    (hString : PsKernelStringEqSoundLaw)
    (session checkedSession comparedSession : PsKernelCheckerSession)
    (expr inferredType declaredType : PsKernelExpr)
    (hConfig :
      PsKernelCheckerConfigurationSound
        session.context session.state)
    (hCheck :
      psKernelSessionCheck fuel session expr =
        Except.ok (Prod.mk inferredType checkedSession))
    (hEq :
      psKernelSessionIsDefEq
          fuel checkedSession inferredType declaredType =
        Except.ok (Prod.mk true comparedSession)) :
    PsKernelTypingJudgment
        session.context.environment session.context.localContext
        expr inferredType ∧
      PsKernelDefEqJudgment
        session.context.environment session.context.localContext
        inferredType declaredType ∧
      PsKernelCheckerConfigurationSound
        session.context comparedSession.state := by
  have hChecked :=
    psKernelSessionCheck_concrete_refines_typing
      fuel hNative hString
      session checkedSession expr inferredType
      hConfig hCheck
  have hCheckContext :
      checkedSession.context = session.context :=
    psKernelSessionCheck_success_preserves_context_core
      fuel session checkedSession expr inferredType hCheck
  have hCheckedConfig :
      PsKernelCheckerConfigurationSound
        checkedSession.context checkedSession.state := by
    simpa [hCheckContext] using hChecked.2
  have hCompared :=
    psKernelSessionIsDefEq_concrete_refines_defeq
      fuel hNative hString
      checkedSession comparedSession
      inferredType declaredType
      hCheckedConfig hEq
  refine ⟨hChecked.1, ?_, ?_⟩
  · simpa [hCheckContext] using hCompared.1
  · simpa [hCheckContext] using hCompared.2


/-
Opaque declaration admission runs in the original environment.  The theorem
refines every successful path into header typing, Sort classification, checked
value typing, type DefEq, and authoritative declaration extension.

No unchecked proof artifacts or unverifiable type inference are introduced.
-/
theorem psKernelAddOpaque_configuration_refines
    (fuel : Nat)
    (environment result : PsKernelEnvironment)
    (value : PsKernelOpaqueInfo)
    (maxRecDepth maxNatSize : Nat)
    (hIndex : PsKernelEnvironmentIndexRefines environment)
    (hNative : PsKernelNativeReductionSoundLaw)
    (hString : PsKernelStringEqSoundLaw)
    (hRun :
      psKernelAddOpaque
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
        environment result (PsKernelConstantInfo.opaqueInfo value) := by
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
  cases hHeader :
      psKernelCheckConstantBaseWithSession
        fuel session value.base with
  | error error =>
      simp [psKernelAddOpaque, session, hHeader] at hRun
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
      have hAfterConfig :
          PsKernelCheckerConfigurationSound
            afterHeader.context afterHeader.state := by
        simpa [hHeaderContext] using hHeaderConfig
      cases hFree :
          psKernelCheckNoMVarNoFVar value.value with
      | error error =>
          simp [psKernelAddOpaque, session, hHeader, hFree] at hRun
      | ok noFree =>
          cases hLevels :
              psKernelCheckLevelParams
                value.value value.base.levelParams with
          | error error =>
              simp [
                psKernelAddOpaque, session, hHeader, hFree, hLevels
              ] at hRun
          | ok checkedLevels =>
              cases hCheck :
                  psKernelSessionCheck
                    fuel afterHeader value.value with
              | error error =>
                  simp [
                    psKernelAddOpaque, session,
                    hHeader, hFree, hLevels, hCheck
                  ] at hRun
              | ok checkedRun =>
                  rcases checkedRun with ⟨bodyType, checkedSession⟩
                  cases hEq :
                      psKernelSessionIsDefEq
                        fuel checkedSession bodyType value.base.type with
                  | error error =>
                      simp [
                        psKernelAddOpaque, session,
                        hHeader, hFree, hLevels, hCheck, hEq
                      ] at hRun
                  | ok comparedRun =>
                      rcases comparedRun with ⟨isEqual, comparedSession⟩
                      cases isEqual with
                      | false =>
                          simp [
                            psKernelAddOpaque, session,
                            hHeader, hFree, hLevels, hCheck, hEq
                          ] at hRun
                      | true =>
                          obtain ⟨hBodyTyping, hBodyEq, _⟩ :=
                            psKernelSessionCheckThenDefEq_configuration_refines
                              fuel hNative hString
                              afterHeader checkedSession comparedSession
                              value.value bodyType value.base.type
                              hAfterConfig hCheck hEq
                          have hAdd :
                              psKernelEnvironmentAdd
                                  environment
                                  (PsKernelConstantInfo.opaqueInfo value) =
                                Except.ok result := by
                            simpa [
                              psKernelAddOpaque, session,
                              hHeader, hFree, hLevels, hCheck, hEq
                            ] using hRun
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
                                (PsKernelConstantInfo.opaqueInfo value)
                                hAdd
