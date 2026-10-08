import Ps.KernelCore.Metatheory.AdmissionPropositionConfiguration

/-
Theorem admission: successful checked theorem insertion is justified by
independent header, proposition-classifier, and proof-value evidence.

The infer-only proposition classifier is not asserted to be an independent
typing certificate; the separately checked header supplies that evidence.
Both the native reduction and String comparison TCB laws stay explicit.
-/
theorem psKernelAddTheorem_configuration_refines
    (fuel : Nat)
    (environment result : PsKernelEnvironment)
    (value : PsKernelTheoremInfo)
    (maxRecDepth maxNatSize : Nat)
    (hIndex : PsKernelEnvironmentIndexRefines environment)
    (hNative : PsKernelNativeReductionSoundLaw)
    (hString : PsKernelStringEqSoundLaw)
    (hRun :
      psKernelAddTheorem
          fuel environment value maxRecDepth maxNatSize =
        Except.ok result) :
    (∃ (headerType bodyType propInferredType : PsKernelExpr)
      (headerLevel propLevel : PsKernelLevel),
      PsKernelTypingJudgment
          environment psKernelLocalContextEmpty
          value.base.type headerType ∧
        PsKernelReductionClosure
          environment psKernelLocalContextEmpty
          headerType (PsKernelExpr.sort headerLevel) ∧
        PsKernelReductionClosure
          environment psKernelLocalContextEmpty
          propInferredType (PsKernelExpr.sort propLevel) ∧
        psKernelLevelNormalizesToZero propLevel = true ∧
        PsKernelTypingJudgment
          environment psKernelLocalContextEmpty
          value.value bodyType ∧
        PsKernelDefEqJudgment
          environment psKernelLocalContextEmpty
          bodyType value.base.type) ∧
      PsKernelDeclarationExtension
        environment result (PsKernelConstantInfo.thmInfo value) := by
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
      psKernelCheckConstantBaseWithSession fuel session value.base with
  | error error =>
      simp [psKernelAddTheorem, session, hHeader] at hRun
  | ok afterHeader =>
      obtain ⟨headerType, headerLevel, hHeaderTyping, hHeaderSort,
        hHeaderConfig⟩ :=
        psKernelCheckConstantBaseWithSession_configuration_refines
          fuel hNative hString
          session afterHeader value.base hInitial hHeader
      have hHeaderContext :
          afterHeader.context = session.context :=
        psKernelCheckConstantBaseWithSession_success_preserves_context
          fuel session afterHeader value.base hHeader
      have hAfterHeaderConfig :
          PsKernelCheckerConfigurationSound
            afterHeader.context afterHeader.state := by
        simpa [hHeaderContext] using hHeaderConfig
      cases hProp :
          psKernelSessionIsProp fuel afterHeader value.base.type with
      | error error =>
          simp [psKernelAddTheorem, session, hHeader, hProp] at hRun
      | ok propRun =>
          rcases propRun with ⟨isProp, propSession⟩
          cases isProp with
          | false =>
              simp [psKernelAddTheorem, session, hHeader, hProp] at hRun
          | true =>
              obtain ⟨propInferredType, propLevel, hPropReduction,
                hPropZero, hPropConfig, hPropContext⟩ :=
                psKernelSessionIsProp_true_configuration_refines
                  fuel hNative hString
                  afterHeader propSession value.base.type
                  hAfterHeaderConfig hProp
              have hFullContext :
                  propSession.context = session.context :=
                hPropContext.trans hHeaderContext
              have hPropSessionConfig :
                  PsKernelCheckerConfigurationSound
                    propSession.context propSession.state := by
                simpa [hPropContext] using hPropConfig
              cases hFree :
                  psKernelCheckNoMVarNoFVar value.value with
              | error error =>
                  simp [
                    psKernelAddTheorem, session,
                    hHeader, hProp, hFree
                  ] at hRun
              | ok noFree =>
                  cases hLevels :
                      psKernelCheckLevelParams
                        value.value value.base.levelParams with
                  | error error =>
                      simp [
                        psKernelAddTheorem, session,
                        hHeader, hProp, hFree, hLevels
                      ] at hRun
                  | ok checkedLevels =>
                      cases hCheck :
                          psKernelSessionCheck
                            fuel propSession value.value with
                      | error error =>
                          simp [
                            psKernelAddTheorem, session,
                            hHeader, hProp, hFree, hLevels, hCheck
                          ] at hRun
                      | ok checkedRun =>
                          rcases checkedRun with ⟨bodyType, checkedSession⟩
                          cases hEq :
                              psKernelSessionIsDefEq
                                fuel checkedSession
                                bodyType value.base.type with
                          | error error =>
                              simp [
                                psKernelAddTheorem, session,
                                hHeader, hProp, hFree, hLevels,
                                hCheck, hEq
                              ] at hRun
                          | ok comparedRun =>
                              rcases comparedRun with
                                ⟨isEqual, comparedSession⟩
                              cases isEqual with
                              | false =>
                                  simp [
                                    psKernelAddTheorem, session,
                                    hHeader, hProp, hFree, hLevels,
                                    hCheck, hEq
                                  ] at hRun
                              | true =>
                                  obtain ⟨hBodyTyping, hBodyEq, _⟩ :=
                                    psKernelSessionCheckThenDefEq_configuration_refines
                                      fuel hNative hString
                                      propSession checkedSession comparedSession
                                      value.value bodyType value.base.type
                                      hPropSessionConfig hCheck hEq
                                  have hAdd :
                                      psKernelEnvironmentAdd
                                          environment
                                          (PsKernelConstantInfo.thmInfo value) =
                                        Except.ok result := by
                                    simpa [
                                      psKernelAddTheorem, session,
                                      hHeader, hProp, hFree, hLevels,
                                      hCheck, hEq
                                    ] using hRun
                                  constructor
                                  · refine
                                      ⟨headerType, bodyType, propInferredType,
                                        headerLevel, propLevel,
                                        ?_, ?_, ?_, hPropZero, ?_, ?_⟩
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
                                      ] using hPropReduction
                                    · simpa [
                                        hFullContext, session,
                                        psKernelMkCheckerSession,
                                        psKernelCheckerContextEmpty
                                      ] using hBodyTyping
                                    · simpa [
                                        hFullContext, session,
                                        psKernelMkCheckerSession,
                                        psKernelCheckerContextEmpty
                                      ] using hBodyEq
                                  · exact
                                      psKernelEnvironmentAdd_success_refines_extension
                                        environment result
                                        (PsKernelConstantInfo.thmInfo value)
                                        hAdd
