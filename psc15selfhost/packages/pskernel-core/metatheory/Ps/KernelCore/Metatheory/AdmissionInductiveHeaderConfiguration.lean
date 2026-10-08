import Ps.KernelCore.Metatheory.AdmissionInductiveNamesConfiguration
import Ps.KernelCore.Metatheory.SessionConcreteRefinement
import Ps.KernelCore.Metatheory.SessionRefinement
import Ps.KernelCore.Metatheory.CheckerInitialConfiguration

/-
Successful ordinary inductive admission implies a concrete, independently
checked type header in the original environment.

The proof uses the real checked-session/EnsureSort sequence; it never treats
infer-only as a typing certificate.  It extracts the successful prefix of the
larger inductive admission transaction without pretending that positivity,
constructor checking, or recursor admission are already established.
Native and string equality laws remain explicit premises.
-/

theorem psKernelAddSimpleInductive_success_header_refines
    (fuel : Nat)
    (environment result : PsKernelEnvironment)
    (decl : PsKernelSimpleInductiveDecl)
    (maxRecDepth maxNatSize : Nat)
    (hIndex : PsKernelEnvironmentIndexRefines environment)
    (hNative : PsKernelNativeReductionSoundLaw)
    (hString : PsKernelStringEqSoundLaw)
    (hRun :
      psKernelAddSimpleInductive
          fuel environment decl maxRecDepth maxNatSize =
        Except.ok result) :
    ∃ (inferredType : PsKernelExpr) (level : PsKernelLevel),
      PsKernelTypingJudgment
        environment psKernelLocalContextEmpty
        decl.type inferredType ∧
      PsKernelReductionClosure
        environment psKernelLocalContextEmpty
        inferredType (PsKernelExpr.sort level) := by
  let allNames : List PsKernelName :=
    List.cons decl.name
      (List.cons
        (psKernelSimpleRecName decl.name)
        (psKernelSimpleCtorNames decl.ctors))
  cases hDuplicates :
      psKernelNameHasDuplicates decl.levelParams with
  | true =>
      simp [psKernelAddSimpleInductive, hDuplicates] at hRun
  | false =>
      cases hUnique :
          psKernelSimpleNameListUnique allNames with
      | false =>
          simp [
            psKernelAddSimpleInductive,
            hDuplicates, allNames, hUnique
          ] at hRun
      | true =>
          cases hFresh :
              psKernelCheckFreshInductiveNames
                allNames environment with
          | error message =>
              simp [
                psKernelAddSimpleInductive,
                hDuplicates, allNames, hUnique, hFresh
              ] at hRun
          | ok fresh =>
              cases hOccurrences :
                  psKernelSimpleCheckUniformOccurrences
                    (List.cons decl.name List.nil)
                    decl.levelParams
                    decl.numParams
                    (psKernelSimpleCtorTypes decl.ctors) with
              | error message =>
                  simp [
                    psKernelAddSimpleInductive,
                    hDuplicates, allNames, hUnique,
                    hFresh, hOccurrences
                  ] at hRun
              | ok checkedOccurrences =>
                  cases hClosed :
                      psKernelCheckNoMVarNoFVar decl.type with
                  | error message =>
                      simp [
                        psKernelAddSimpleInductive,
                        hDuplicates, allNames, hUnique,
                        hFresh, hOccurrences, hClosed
                      ] at hRun
                  | ok closed =>
                      cases hLevels :
                          psKernelCheckLevelParams
                            decl.type decl.levelParams with
                      | error message =>
                          simp [
                            psKernelAddSimpleInductive,
                            hDuplicates, allNames, hUnique,
                            hFresh, hOccurrences,
                            hClosed, hLevels
                          ] at hRun
                      | ok checkedLevels =>
                          let safety :=
                            if decl.isUnsafe then
                              PsKernelDefinitionSafety.unsafeDef
                            else
                              PsKernelDefinitionSafety.safe
                          let headerSession :=
                            psKernelMkCheckerSession
                              environment decl.levelParams
                              safety maxRecDepth maxNatSize
                          cases hHeader :
                              psKernelSessionCheck
                                fuel
                                (psKernelMkCheckerSession
                                  environment decl.levelParams
                                  (if decl.isUnsafe then
                                    PsKernelDefinitionSafety.unsafeDef
                                   else
                                    PsKernelDefinitionSafety.safe)
                                  maxRecDepth maxNatSize)
                                decl.type with
                          | error message =>
                              simp [
                                psKernelAddSimpleInductive,
                                hDuplicates, allNames, hUnique,
                                hFresh, hOccurrences,
                                hClosed, hLevels, hHeader
                              ] at hRun
                          | ok headerResult =>
                              cases hSort :
                                  psKernelSessionEnsureSort
                                    fuel
                                    (Prod.snd headerResult)
                                    (Prod.fst headerResult) with
                              | error message =>
                                  simp [
                                    psKernelAddSimpleInductive,
                                    hDuplicates, allNames, hUnique,
                                    hFresh, hOccurrences,
                                    hClosed, hLevels, hHeader,
                                    hSort
                                  ] at hRun
                              | ok sortResult =>
                                  rcases headerResult with
                                    ⟨inferredType, nextSession⟩
                                  rcases sortResult with
                                    ⟨level, finalSession⟩
                                  have hInitial :
                                      PsKernelCheckerConfigurationSound
                                        headerSession.context
                                        headerSession.state := by
                                    exact
                                      psKernelMkCheckerSession_configuration_sound
                                        environment decl.levelParams safety
                                        maxRecDepth maxNatSize hIndex
                                  have hTyped :=
                                    psKernelSessionCheck_concrete_refines_typing
                                      fuel hNative hString
                                      headerSession nextSession
                                      decl.type inferredType
                                      hInitial hHeader
                                  have hContext :=
                                    psKernelSessionCheck_success_preserves_context_core
                                      fuel headerSession nextSession
                                      decl.type inferredType hHeader
                                  have hNextConfig :
                                      PsKernelCheckerConfigurationSound
                                        nextSession.context
                                        nextSession.state := by
                                    simpa [hContext] using hTyped.2
                                  have hReduced :=
                                    psKernelSessionEnsureSort_concrete_refines_reduction
                                      fuel hNative hString
                                      nextSession finalSession
                                      inferredType level
                                      hNextConfig hSort
                                  refine ⟨inferredType, level, ?_, ?_⟩
                                  · simpa [
                                      headerSession, safety,
                                      psKernelMkCheckerSession,
                                      psKernelCheckerContextEmpty
                                    ] using hTyped.1
                                  · simpa [
                                      hContext, headerSession, safety,
                                      psKernelMkCheckerSession,
                                      psKernelCheckerContextEmpty
                                    ] using hReduced.1
