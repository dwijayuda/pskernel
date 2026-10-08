import Ps.KernelCore.Admission.Inductive.Mutual.Admission
import Ps.KernelCore.Metatheory.AdmissionInductiveHeaderConfiguration

/-
Successful mutual-inductive admission includes a checked first datatype
header in the original environment.  This validates the seed for the shared
remaining-header and constructor transactions.  It does not yet assert that
the remaining headers, positivity, or generated recursors are sound.
-/

theorem psKernelAddSimpleMutualInductive_success_first_header_refines
    (fuel : Nat)
    (environment result : PsKernelEnvironment)
    (decl : PsKernelSimpleMutualInductiveDecl)
    (maxRecDepth maxNatSize : Nat)
    (hIndex : PsKernelEnvironmentIndexRefines environment)
    (hNative : PsKernelNativeReductionSoundLaw)
    (hString : PsKernelStringEqSoundLaw)
    (hRun :
      psKernelAddSimpleMutualInductive
        fuel environment decl maxRecDepth maxNatSize =
        Except.ok result) :
    ∃ (first : PsKernelSimpleMutualTypeDecl)
      (remaining : List PsKernelSimpleMutualTypeDecl)
      (inferredType : PsKernelExpr)
      (level : PsKernelLevel),
      decl.types = List.cons first remaining ∧
        PsKernelTypingJudgment
          environment psKernelLocalContextEmpty
          first.type inferredType ∧
        PsKernelReductionClosure
          environment psKernelLocalContextEmpty
          inferredType (PsKernelExpr.sort level) := by
  let allNames : List PsKernelName :=
    psKernelMutualNameListAppend
      (psKernelSimpleMutualNames decl.types)
      (psKernelMutualNameListAppend
        (psKernelSimpleMutualRecNames decl.types)
        (psKernelSimpleMutualCtorNames decl.types))
  cases hDuplicates :
      psKernelNameHasDuplicates decl.levelParams with
  | true =>
      simp [
        psKernelAddSimpleMutualInductive, hDuplicates
      ] at hRun
  | false =>
      cases hMinTypes :
          psKernelNatLt
            (psKernelSimpleMutualTypeCount decl.types) 2 with
      | true =>
          simp [
            psKernelAddSimpleMutualInductive,
            hDuplicates, hMinTypes
          ] at hRun
      | false =>
          cases hUnique :
              psKernelSimpleNameListUnique allNames with
          | false =>
              simp [
                psKernelAddSimpleMutualInductive,
                hDuplicates, hMinTypes, allNames, hUnique
              ] at hRun
          | true =>
              cases hFresh :
                  psKernelCheckFreshInductiveNames
                    allNames environment with
              | error message =>
                  simp [
                    psKernelAddSimpleMutualInductive,
                    hDuplicates, hMinTypes, allNames,
                    hUnique, hFresh
                  ] at hRun
              | ok fresh =>
                  cases hUniform :
                      psKernelSimpleCheckUniformOccurrences
                        (psKernelSimpleMutualNames decl.types)
                        decl.levelParams
                        decl.numParams
                        (psKernelSimpleMutualCtorTypes decl.types) with
                  | error message =>
                      simp [
                        psKernelAddSimpleMutualInductive,
                        hDuplicates, hMinTypes, allNames,
                        hUnique, hFresh, hUniform
                      ] at hRun
                  | ok uniform =>
                      cases hTypes : decl.types with
                      | nil =>
                          simp [
                            psKernelAddSimpleMutualInductive,
                            hDuplicates, hMinTypes, allNames,
                            hUnique, hFresh, hUniform, hTypes
                          ] at hRun
                      | cons first remaining =>
                          cases hClosed :
                              psKernelCheckNoMVarNoFVar first.type with
                          | error message =>
                              simp [
                                psKernelAddSimpleMutualInductive,
                                hDuplicates, hMinTypes, allNames,
                                hUnique, hFresh, hUniform,
                                hTypes, hClosed
                              ] at hRun
                          | ok closed =>
                              cases hLevels :
                                  psKernelCheckLevelParams
                                    first.type decl.levelParams with
                              | error message =>
                                  simp [
                                    psKernelAddSimpleMutualInductive,
                                    hDuplicates, hMinTypes, allNames,
                                    hUnique, hFresh, hUniform,
                                    hTypes, hClosed, hLevels
                                  ] at hRun
                              | ok checkedLevels =>
                                  let safety :=
                                    if decl.isUnsafe then
                                      PsKernelDefinitionSafety.unsafeDef
                                    else
                                      PsKernelDefinitionSafety.safe
                                  let session :=
                                    psKernelMkCheckerSession
                                      environment decl.levelParams
                                      safety maxRecDepth maxNatSize
                                  cases hChecked :
                                      psKernelSessionCheck
                                        fuel
                                        (psKernelMkCheckerSession
                                          environment decl.levelParams
                                          (if decl.isUnsafe then
                                            PsKernelDefinitionSafety.unsafeDef
                                           else
                                            PsKernelDefinitionSafety.safe)
                                          maxRecDepth maxNatSize)
                                        first.type with
                                  | error message =>
                                      simp [
                                        psKernelAddSimpleMutualInductive,
                                        hDuplicates, hMinTypes, allNames,
                                        hUnique, hFresh, hUniform,
                                        hTypes, hClosed, hLevels, hChecked
                                      ] at hRun
                                  | ok checked =>
                                      cases hSort :
                                          psKernelSessionEnsureSort
                                            fuel
                                            (Prod.snd checked)
                                            (Prod.fst checked) with
                                      | error message =>
                                          simp [
                                            psKernelAddSimpleMutualInductive,
                                            hDuplicates, hMinTypes, allNames,
                                            hUnique, hFresh, hUniform,
                                            hTypes, hClosed, hLevels,
                                            hChecked, hSort
                                          ] at hRun
                                      | ok sorted =>
                                          rcases checked with
                                            ⟨inferredType, checkedSession⟩
                                          rcases sorted with
                                            ⟨level, sortedSession⟩
                                          have hInitial :=
                                            psKernelMkCheckerSession_configuration_sound
                                              environment decl.levelParams
                                              safety maxRecDepth maxNatSize
                                              hIndex
                                          obtain ⟨hTyped, hReduction, _⟩ :=
                                            psKernelCheckedHeaderSort_configuration_refines
                                              fuel hNative hString
                                              session checkedSession sortedSession
                                              first.type inferredType level
                                              hInitial hChecked hSort
                                          refine ⟨first, remaining, inferredType,
                                            level, hTypes, ?_, ?_⟩
                                          · simpa [
                                              session, safety,
                                              psKernelMkCheckerSession,
                                              psKernelCheckerContextEmpty
                                            ] using hTyped
                                          · simpa [
                                              session, safety,
                                              psKernelMkCheckerSession,
                                              psKernelCheckerContextEmpty
                                            ] using hReduction
