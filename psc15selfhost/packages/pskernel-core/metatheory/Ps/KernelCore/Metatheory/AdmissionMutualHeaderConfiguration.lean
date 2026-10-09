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
                          simp only [hTypes] at hMinTypes hUniform
                          simp only [allNames, hTypes] at hUnique hFresh
                          simp [
                            psKernelAddSimpleMutualInductive,
                            hDuplicates, hMinTypes, allNames,
                            hUnique, hFresh, hUniform, hTypes
                          ] at hRun
                      | cons first remaining =>
                          simp only [hTypes] at hMinTypes hUniform
                          simp only [allNames, hTypes] at hUnique hFresh
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
                                            level, rfl, ?_, ?_⟩
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


/-- Exact checked prefix of successful mutual admission, before constructor publication. -/
theorem psKernelAddSimpleMutualInductive_success_header_pipeline
    (fuel : Nat) (environment result : PsKernelEnvironment)
    (decl : PsKernelSimpleMutualInductiveDecl) (maxRecDepth maxNatSize : Nat)
    (hRun : psKernelAddSimpleMutualInductive fuel environment decl maxRecDepth maxNatSize =
      Except.ok result) :
    ∃ (first : PsKernelSimpleMutualTypeDecl) (remaining : List PsKernelSimpleMutualTypeDecl)
      (checked : PsKernelExpr × PsKernelCheckerSession)
      (sorted : PsKernelLevel × PsKernelCheckerSession)
      (paramResult indexResult : PsKernelOpenBindersResult)
      (resultLevel : PsKernelLevel) (tailShapes : List PsKernelSimpleMutualTypeShape),
      decl.types = first :: remaining ∧
      psKernelSessionCheck fuel
        (psKernelMkCheckerSession environment decl.levelParams
          (if decl.isUnsafe then PsKernelDefinitionSafety.unsafeDef else PsKernelDefinitionSafety.safe)
          maxRecDepth maxNatSize) first.type = Except.ok checked ∧
      psKernelSessionEnsureSort fuel checked.2 checked.1 = Except.ok sorted ∧
      psKernelOpenSimpleHeaderParams fuel sorted.2 first.type decl.numParams = Except.ok paramResult ∧
      psKernelOpenSimpleHeaderIndices fuel paramResult.session paramResult.result = Except.ok indexResult ∧
      indexResult.result = PsKernelExpr.sort resultLevel ∧
      psKernelOpenSimpleMutualRemainingTypesWorker remaining fuel environment decl.levelParams
        (if decl.isUnsafe then PsKernelDefinitionSafety.unsafeDef else PsKernelDefinitionSafety.safe)
        maxRecDepth maxNatSize paramResult.session paramResult.binders resultLevel =
          Except.ok tailShapes := by
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
                          simp only [hTypes] at hMinTypes hUniform
                          simp only [allNames, hTypes] at hUnique hFresh
                          simp [
                            psKernelAddSimpleMutualInductive,
                            hDuplicates, hMinTypes, allNames,
                            hUnique, hFresh, hUniform, hTypes
                          ] at hRun
                      | cons first remaining =>
                          simp only [hTypes] at hMinTypes hUniform
                          simp only [allNames, hTypes] at hUnique hFresh
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
                                          simp only [psKernelAddSimpleMutualInductive,
                                            hDuplicates, hMinTypes, allNames, hUnique, hFresh,
                                            hUniform, hTypes, hClosed, hLevels, hChecked, hSort] at hRun
                                          cases hParams : psKernelOpenSimpleHeaderParams
                                              fuel sorted.2 first.type decl.numParams with
                                          | error message => simp only [hParams] at hRun; cases hRun
                                          | ok paramResult =>
                                              simp only [hParams] at hRun
                                              cases hIndices : psKernelOpenSimpleHeaderIndices
                                                  fuel paramResult.session paramResult.result with
                                              | error message => simp only [hIndices] at hRun; cases hRun
                                              | ok indexResult =>
                                                  simp only [hIndices] at hRun
                                                  cases hResult : indexResult.result with
                                                  | sort resultLevel =>
                                                      simp only [hResult] at hRun
                                                      cases hTail : psKernelOpenSimpleMutualRemainingTypesWorker
                                                          remaining fuel environment decl.levelParams safety
                                                          maxRecDepth maxNatSize paramResult.session
                                                          paramResult.binders resultLevel with
                                                      | error message =>
                                                          simp only [safety] at hTail
                                                          simp only [hTail] at hRun
                                                          cases hRun
                                                      | ok tailShapes =>
                                                          exact ⟨first, remaining, checked, sorted, paramResult,
                                                            indexResult, resultLevel, tailShapes, rfl,
                                                            hChecked, hSort, hParams, hIndices, hResult, hTail⟩
                                                  | _ => simp only [hResult] at hRun; cases hRun
