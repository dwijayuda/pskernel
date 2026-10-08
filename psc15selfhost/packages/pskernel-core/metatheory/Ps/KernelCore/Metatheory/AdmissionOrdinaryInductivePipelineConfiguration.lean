import Ps.KernelCore.Metatheory.AdmissionConstructorSemanticHistoryConfiguration

/--
Exact successful checked prefix of ordinary admission. This executable
projection is composed with independent semantic contracts below; it is not
itself a well-formed environment certificate.
-/
theorem psKernelAddSimpleInductive_success_constructor_pipeline
    (fuel : Nat) (environment result : PsKernelEnvironment)
    (decl : PsKernelSimpleInductiveDecl) (maxRecDepth maxNatSize : Nat)
    (hRun : psKernelAddSimpleInductive fuel environment decl maxRecDepth maxNatSize =
      Except.ok result) :
    ∃ (headerResult : PsKernelExpr × PsKernelCheckerSession)
      (sortResult : PsKernelLevel × PsKernelCheckerSession)
      (paramResult indexResult : PsKernelOpenBindersResult)
      (resultLevel : PsKernelLevel) (ctorResult : PsKernelAddConstructorsResult),
      psKernelSessionCheck fuel
        (psKernelMkCheckerSession environment decl.levelParams
          (if decl.isUnsafe then PsKernelDefinitionSafety.unsafeDef else PsKernelDefinitionSafety.safe)
          maxRecDepth maxNatSize) decl.type = Except.ok headerResult ∧
      psKernelSessionEnsureSort fuel headerResult.2 headerResult.1 = Except.ok sortResult ∧
      psKernelOpenSimpleHeaderParams fuel sortResult.2 decl.type decl.numParams = Except.ok paramResult ∧
      psKernelOpenSimpleHeaderIndices fuel paramResult.session paramResult.result = Except.ok indexResult ∧
      indexResult.result = PsKernelExpr.sort resultLevel ∧
      psKernelAddSimpleConstructorsWithFuel (Nat.succ fuel) decl
        (if decl.isUnsafe then PsKernelDefinitionSafety.unsafeDef else PsKernelDefinitionSafety.safe)
        resultLevel (psKernelLevelParamsToLevels decl.levelParams) paramResult.binders
        (psKernelOpenBinderListLength indexResult.binders) paramResult.session
        (psKernelEnvironmentAddUnchecked environment (PsKernelConstantInfo.inductInfo
          (psKernelOrdinaryInitialInductiveInfo decl indexResult.binders)))
        0 decl.ctors = Except.ok ctorResult := by
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
                                  cases hParams : psKernelOpenSimpleHeaderParams fuel
                                      sortResult.2 decl.type decl.numParams with
                                  | error message =>
                                      simp [psKernelAddSimpleInductive, hDuplicates, allNames, hUnique,
                                        hFresh, hOccurrences, hClosed, hLevels, hHeader, hSort, hParams] at hRun
                                  | ok paramResult =>
                                      cases hIndices : psKernelOpenSimpleHeaderIndices fuel
                                          paramResult.session paramResult.result with
                                      | error message =>
                                          simp [psKernelAddSimpleInductive, hDuplicates, allNames, hUnique,
                                            hFresh, hOccurrences, hClosed, hLevels, hHeader, hSort,
                                            hParams, hIndices] at hRun
                                      | ok indexResult =>
                                          cases hShape : indexResult.result with
                                          | sort resultLevel =>
                                              cases hCtors : psKernelAddSimpleConstructorsWithFuel
                                                  (Nat.succ fuel) decl safety resultLevel
                                                  (psKernelLevelParamsToLevels decl.levelParams)
                                                  paramResult.binders
                                                  (psKernelOpenBinderListLength indexResult.binders)
                                                  paramResult.session
                                                  (psKernelEnvironmentAddUnchecked environment
                                                    (PsKernelConstantInfo.inductInfo
                                                      (psKernelOrdinaryInitialInductiveInfo decl indexResult.binders)))
                                                  0 decl.ctors with
                                              | error message =>
                                                  simp [psKernelAddSimpleInductive, hDuplicates,
                                                    allNames, hUnique, hFresh, hOccurrences, hClosed,
                                                    hLevels, hHeader, hSort, hParams, hIndices, hShape,
                                                    psKernelOrdinaryInitialInductiveInfo, safety, hCtors] at hRun
                                              | ok ctorResult =>
                                                  exact ⟨headerResult, sortResult, paramResult, indexResult,
                                                    resultLevel, ctorResult, hHeader, hSort, hParams,
                                                    hIndices, hShape, hCtors⟩
                                          | _ =>
                                              simp [psKernelAddSimpleInductive, hDuplicates, allNames, hUnique,
                                                hFresh, hOccurrences, hClosed, hLevels, hHeader, hSort,
                                                hParams, hIndices, hShape] at hRun
