import Ps.KernelCore.Metatheory.AdmissionIndexConfiguration
import Ps.KernelCore.Metatheory.AdmissionHeaderConfiguration
import Ps.KernelCore.Metatheory.AdmissionDefinitionConfiguration

/-
The mutual-declaration transaction checks every header in the *original*
environment and every body in the completed recursive work environment.
This file records those two distinct independently checked facts. Neither
infer-only callbacks nor environment extension alone are used as typing
certificates.  Native-reduction and StringEq laws remain explicit.
-/

def PsKernelMutualHeaderEvidence
    (environment : PsKernelEnvironment)
    (value : PsKernelDefinitionInfo) : Prop :=
  ∃ (inferredType : PsKernelExpr) (level : PsKernelLevel),
    PsKernelTypingJudgment
      environment psKernelLocalContextEmpty
      value.base.type inferredType ∧
    PsKernelReductionClosure
      environment psKernelLocalContextEmpty
      inferredType (PsKernelExpr.sort level)

def PsKernelMutualBodyEvidence
    (environment : PsKernelEnvironment)
    (value : PsKernelDefinitionInfo) : Prop :=
  ∃ inferredType : PsKernelExpr,
    PsKernelTypingJudgment
      environment psKernelLocalContextEmpty
      value.value inferredType ∧
    PsKernelDefEqJudgment
      environment psKernelLocalContextEmpty
      inferredType value.base.type


theorem psKernelCheckMutualHeaders_configuration_refines
    (values : List PsKernelDefinitionInfo) :
    ∀ (fuel : Nat)
      (environment : PsKernelEnvironment)
      (first : PsKernelDefinitionInfo)
      (maxRecDepth maxNatSize : Nat)
      (seen : List PsKernelName),
      PsKernelEnvironmentIndexRefines environment ->
      PsKernelNativeReductionSoundLaw ->
      PsKernelStringEqSoundLaw ->
      psKernelCheckMutualHeaders
          values fuel environment first
          maxRecDepth maxNatSize seen =
        Except.ok () ->
      List.Forall (PsKernelMutualHeaderEvidence environment) values := by
  induction values with
  | nil =>
      intro fuel environment first maxRecDepth maxNatSize
        seen hIndex hNative hString hRun
      exact List.Forall.nil
  | cons value rest ih =>
      intro fuel environment first maxRecDepth maxNatSize
        seen hIndex hNative hString hRun
      cases hSafety :
          psKernelSafetyEq value.safety first.safety with
      | false =>
          simp [psKernelCheckMutualHeaders, hSafety] at hRun
      | true =>
          cases hLevels :
              psKernelNameListsEq
                value.base.levelParams
                first.base.levelParams with
          | false =>
              simp [
                psKernelCheckMutualHeaders,
                hSafety, hLevels
              ] at hRun
          | true =>
              cases hSeen :
                  psKernelNameMember value.base.name seen with
              | true =>
                  simp [
                    psKernelCheckMutualHeaders,
                    hSafety, hLevels, hSeen
                  ] at hRun
              | false =>
                  let session :=
                    psKernelMkCheckerSession
                      environment
                      value.base.levelParams
                      first.safety
                      maxRecDepth
                      maxNatSize
                  have hInitial :
                      PsKernelCheckerConfigurationSound
                        session.context session.state :=
                    psKernelMkCheckerSession_configuration_sound
                      environment value.base.levelParams
                      first.safety maxRecDepth maxNatSize hIndex
                  cases hHeader :
                      psKernelCheckConstantBaseWithSession
                        fuel session value.base with
                  | error error =>
                      simp [
                        psKernelCheckMutualHeaders,
                        hSafety, hLevels, hSeen,
                        session, hHeader
                      ] at hRun
                  | ok afterHeader =>
                      obtain ⟨inferredType, level, hTyped, hSort, _⟩ :=
                        psKernelCheckConstantBaseWithSession_configuration_refines
                          fuel hNative hString
                          session afterHeader value.base
                          hInitial hHeader
                      have hRestRun :
                          psKernelCheckMutualHeaders
                              rest fuel environment first
                              maxRecDepth maxNatSize
                              (List.cons value.base.name seen) =
                            Except.ok () := by
                        simpa [
                          psKernelCheckMutualHeaders,
                          hSafety, hLevels, hSeen,
                          session, hHeader
                        ] using hRun
                      refine List.Forall.cons ?_ ?_
                      · refine ⟨inferredType, level, ?_, ?_⟩
                        · simpa [
                            session, psKernelMkCheckerSession,
                            psKernelCheckerContextEmpty
                          ] using hTyped
                        · simpa [
                            session, psKernelMkCheckerSession,
                            psKernelCheckerContextEmpty
                          ] using hSort
                      · exact
                          ih fuel environment first
                            maxRecDepth maxNatSize
                            (List.cons value.base.name seen)
                            hIndex hNative hString hRestRun


theorem psKernelCheckMutualBodies_configuration_refines
    (values : List PsKernelDefinitionInfo) :
    ∀ (fuel : Nat)
      (environment : PsKernelEnvironment)
      (safety : PsKernelDefinitionSafety)
      (maxRecDepth maxNatSize : Nat),
      PsKernelEnvironmentIndexRefines environment ->
      PsKernelNativeReductionSoundLaw ->
      PsKernelStringEqSoundLaw ->
      psKernelCheckMutualBodies
          values fuel environment safety
          maxRecDepth maxNatSize =
        Except.ok () ->
      List.Forall (PsKernelMutualBodyEvidence environment) values := by
  induction values with
  | nil =>
      intro fuel environment safety maxRecDepth maxNatSize
        hIndex hNative hString hRun
      exact List.Forall.nil
  | cons value rest ih =>
      intro fuel environment safety maxRecDepth maxNatSize
        hIndex hNative hString hRun
      let session :=
        psKernelMkCheckerSession
          environment
          value.base.levelParams
          safety
          maxRecDepth
          maxNatSize
      have hInitial :
          PsKernelCheckerConfigurationSound
            session.context session.state :=
        psKernelMkCheckerSession_configuration_sound
          environment value.base.levelParams safety
          maxRecDepth maxNatSize hIndex
      cases hBody :
          psKernelCheckDefinitionBodyWithSession
            fuel session value with
      | error error =>
          simp [
            psKernelCheckMutualBodies, session, hBody
          ] at hRun
      | ok afterBody =>
          obtain ⟨bodyType, hBodyTyping, hBodyEq, _⟩ :=
            psKernelCheckDefinitionBodyWithSession_configuration_refines
              fuel hNative hString
              session afterBody value
              hInitial hBody
          have hRestRun :
              psKernelCheckMutualBodies
                  rest fuel environment safety
                  maxRecDepth maxNatSize =
                Except.ok () := by
            simpa [
              psKernelCheckMutualBodies,
              session, hBody
            ] using hRun
          refine List.Forall.cons ?_ ?_
          · refine ⟨bodyType, ?_, ?_⟩
            · simpa [
                session, psKernelMkCheckerSession,
                psKernelCheckerContextEmpty
              ] using hBodyTyping
            · simpa [
                session, psKernelMkCheckerSession,
                psKernelCheckerContextEmpty
              ] using hBodyEq
          · exact
              ih fuel environment safety
                maxRecDepth maxNatSize
                hIndex hNative hString hRestRun


theorem psKernelAddMutualDefinitions_configuration_refines
    (fuel : Nat)
    (environment result : PsKernelEnvironment)
    (values : List PsKernelDefinitionInfo)
    (maxRecDepth maxNatSize : Nat)
    (hIndex : PsKernelEnvironmentIndexRefines environment)
    (hNative : PsKernelNativeReductionSoundLaw)
    (hString : PsKernelStringEqSoundLaw)
    (hRun :
      psKernelAddMutualDefinitions
          fuel environment values maxRecDepth maxNatSize =
        Except.ok result) :
    PsKernelEnvironmentIndexRefines result ∧
      List.Forall
        (PsKernelMutualHeaderEvidence environment) values ∧
      List.Forall
        (PsKernelMutualBodyEvidence result) values := by
  cases values with
  | nil =>
      simp [psKernelAddMutualDefinitions] at hRun
  | cons first rest =>
      cases hSafe :
          psKernelDefinitionSafetyIsSafe first.safety with
      | true =>
          simp [psKernelAddMutualDefinitions, hSafe] at hRun
      | false =>
          cases hHeaders :
              psKernelCheckMutualHeaders
                (List.cons first rest)
                fuel environment first
                maxRecDepth maxNatSize List.nil with
          | error error =>
              simp [
                psKernelAddMutualDefinitions,
                hSafe, hHeaders
              ] at hRun
          | ok headerResult =>
              cases headerResult
              let work :=
                psKernelMutualWorkEnvironment
                  (List.cons first rest) environment
              have hWorkIndex :
                  PsKernelEnvironmentIndexRefines work :=
                psKernelMutualWorkEnvironment_index_refines
                  (List.cons first rest) environment hIndex
              cases hBodies :
                  psKernelCheckMutualBodies
                    (List.cons first rest)
                    fuel work first.safety
                    maxRecDepth maxNatSize with
              | error error =>
                  simp [
                    psKernelAddMutualDefinitions,
                    hSafe, hHeaders, work, hBodies
                  ] at hRun
              | ok bodyResult =>
                  cases bodyResult
                  have hResult :
                      work = result := by
                    simpa [
                      psKernelAddMutualDefinitions,
                      hSafe, hHeaders, work, hBodies
                    ] using hRun
                  subst result
                  refine ⟨hWorkIndex, ?_, ?_⟩
                  · exact
                      psKernelCheckMutualHeaders_configuration_refines
                        (List.cons first rest)
                        fuel environment first
                        maxRecDepth maxNatSize List.nil
                        hIndex hNative hString hHeaders
                  · exact
                      psKernelCheckMutualBodies_configuration_refines
                        (List.cons first rest)
                        fuel work first.safety
                        maxRecDepth maxNatSize
                        hWorkIndex hNative hString hBodies
