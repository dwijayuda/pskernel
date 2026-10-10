import Ps.KernelCore.Metatheory.AdmissionMutualRecursorTransactionConfiguration

/-- Exact common execution witnesses through recursor generation, checked validation,
and final publication. All success equalities are derived from actual admission. -/
theorem psKernelAddSimpleMutualInductive_success_transaction_pipeline
    (fuel : Nat) (environment result : PsKernelEnvironment)
    (decl : PsKernelSimpleMutualInductiveDecl) (maxRecDepth maxNatSize : Nat)
    (hIndex : PsKernelEnvironmentIndexRefines environment)
    (hRun : psKernelAddSimpleMutualInductive fuel environment decl maxRecDepth maxNatSize =
      Except.ok result) :
    ∃ (first : PsKernelSimpleMutualTypeDecl) (remaining : List PsKernelSimpleMutualTypeDecl)
      (checked : PsKernelExpr × PsKernelCheckerSession)
      (sorted : PsKernelLevel × PsKernelCheckerSession)
      (paramResult indexResult : PsKernelOpenBindersResult)
      (resultLevel : PsKernelLevel) (tailShapes : List PsKernelSimpleMutualTypeShape)
      (ctorResult : PsKernelAddMutualConstructorsResult)
      (minors : List PsKernelOpenBinder) (recInfos : List PsKernelRecursorInfo),
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
          Except.ok tailShapes ∧

      psKernelAddSimpleMutualTypesWorker
        (PsKernelSimpleMutualTypeShape.mk first indexResult.binders :: tailShapes)
        fuel (if decl.isUnsafe then PsKernelDefinitionSafety.unsafeDef
          else PsKernelDefinitionSafety.safe)
        resultLevel (psKernelLevelParamsToLevels decl.levelParams)
        paramResult.binders (psKernelSimpleMutualNames decl.types)
        (PsKernelSimpleMutualTypeShape.mk first indexResult.binders :: tailShapes)
        paramResult.session
        (psKernelAddMutualInductiveInfos
          (psKernelMakeSimpleMutualBaseInfos
            (psKernelSimpleMutualNames decl.types) decl
            (PsKernelSimpleMutualTypeShape.mk first indexResult.binders :: tailShapes))
          environment) 0 = Except.ok ctorResult ∧
      (let shapes := PsKernelSimpleMutualTypeShape.mk first indexResult.binders :: tailShapes
       let levels := psKernelLevelParamsToLevels decl.levelParams
       let elimOnlyAtZero := if psKernelLevelIsNotZero resultLevel then false else true
       let elimName := psKernelSimpleFreshElimName decl.levelParams
       let elimLevel := if elimOnlyAtZero then PsKernelLevel.zero else PsKernelLevel.param elimName
       let recLevelParams := if elimOnlyAtZero then decl.levelParams else elimName :: decl.levelParams
       let motives := psKernelMakeSimpleMutualMotives levels paramResult.binders elimLevel shapes
       let ruleBinders := psKernelOpenBinderListAppend paramResult.binders
         (psKernelOpenBinderListAppend motives minors)
       let work1 := psKernelReplaceMutualInductiveInfos
         (psKernelMakeSimpleMutualBaseInfos (psKernelSimpleMutualNames decl.types) decl shapes)
         (psKernelSimpleMutualHasRecursiveFields ctorResult.shapes)
         (psKernelSimpleMutualHasReflexiveFields ctorResult.shapes) ctorResult.environment
       let work2 := psKernelAddMutualRecursorInfos recInfos work1
       psKernelMakeSimpleMutualMinors levels paramResult.binders motives ctorResult.shapes =
         Except.ok minors ∧
       psKernelBuildSimpleMutualRecInfosFromConstructorsWorker shapes shapes recLevelParams
         (psKernelSimpleMutualNames decl.types) levels paramResult.binders motives minors
         ruleBinders ctorResult.shapes 0 decl.isUnsafe = Except.ok recInfos ∧
       psKernelValidateMutualRecursorInfosWorker recInfos fuel work2 recLevelParams
         (if decl.isUnsafe then PsKernelDefinitionSafety.unsafeDef else PsKernelDefinitionSafety.safe)
         maxRecDepth maxNatSize levels paramResult.binders motives minors ruleBinders
         ctorResult.shapes 0 = Except.ok () ∧
       result = work2) := by
  obtain ⟨first, remaining, checked, sorted, paramResult, indexResult, resultLevel,
    tailShapes, ctorResult, hTypes, hCheck, hSort, hParams, hIndices,
    hResult, hTail, hCtor⟩ :=
    psKernelAddSimpleMutualInductive_success_constructor_pipeline
      fuel environment result decl maxRecDepth maxNatSize hRun
  obtain ⟨hDuplicate, hMinTypes, hUnique, _⟩ :=
    psKernelAddSimpleMutualInductive_success_name_guards
      fuel environment result decl maxRecDepth maxNatSize hIndex hRun
  /-
  Normalize both the executable pipeline and its guard witnesses to the same
  checked source family before decomposing the remaining successful path.
  This avoids silently changing the family on only one side of a guard.
  -/
  unfold psKernelAddSimpleMutualInductive at hRun
  simp only [hTypes] at hRun hMinTypes hUnique
  let allNames : List PsKernelName :=
    psKernelMutualNameListAppend
      (psKernelSimpleMutualNames (first :: remaining))
      (psKernelMutualNameListAppend
        (psKernelSimpleMutualRecNames (first :: remaining))
        (psKernelSimpleMutualCtorNames (first :: remaining)))
  simp only [hDuplicate, hMinTypes, hUnique] at hRun
  cases hFresh : psKernelCheckFreshInductiveNames allNames environment with
  | error message =>
      simp only [allNames] at hFresh
      simp only [hFresh] at hRun
      cases hRun
  | ok fresh =>
      simp only [allNames] at hFresh
      simp only [hFresh] at hRun
      cases hUniform : psKernelSimpleCheckUniformOccurrences
          (psKernelSimpleMutualNames (first :: remaining)) decl.levelParams decl.numParams
          (psKernelSimpleMutualCtorTypes (first :: remaining)) with
      | error message =>
          simp only [hUniform] at hRun
          cases hRun
      | ok uniform =>
          simp only [hUniform] at hRun
          cases hClosed : psKernelCheckNoMVarNoFVar first.type with
          | error message =>
              simp only [hClosed] at hRun
              cases hRun
          | ok closed =>
              simp only [hClosed] at hRun
              cases hLevels : psKernelCheckLevelParams first.type decl.levelParams with
              | error message =>
                  simp only [hLevels] at hRun
                  cases hRun
              | ok checkedLevels =>
                  simp only [hLevels] at hRun
                  have hCtorTypes := hCtor
                  rw [hTypes] at hCtorTypes
                  let shapes : List PsKernelSimpleMutualTypeShape :=
                    PsKernelSimpleMutualTypeShape.mk first indexResult.binders :: tailShapes
                  let levels := psKernelLevelParamsToLevels decl.levelParams
                  let elimOnlyAtZero := if psKernelLevelIsNotZero resultLevel then false else true
                  let elimLevel := if elimOnlyAtZero then PsKernelLevel.zero else
                    PsKernelLevel.param (psKernelSimpleFreshElimName decl.levelParams)
                  let motives := psKernelMakeSimpleMutualMotives
                    levels paramResult.binders elimLevel shapes
                  simp only [hCheck, hSort, hParams, hIndices, hResult,
                    hTail, hCtorTypes] at hRun
                  cases hMinors : psKernelMakeSimpleMutualMinors
                      levels paramResult.binders motives ctorResult.shapes with
                  | error message =>
                      simp only [shapes, levels, elimOnlyAtZero, elimLevel, motives] at hMinors
                      rw [hMinors] at hRun
                      cases hRun
                  | ok minors =>
                      simp only [shapes, levels, elimOnlyAtZero, elimLevel, motives] at hMinors
                      rw [hMinors] at hRun
                      let recLevelParams := if elimOnlyAtZero then decl.levelParams else
                        psKernelSimpleFreshElimName decl.levelParams :: decl.levelParams
                      let ruleBinders := psKernelOpenBinderListAppend paramResult.binders
                        (psKernelOpenBinderListAppend motives minors)
                      let work1 := psKernelReplaceMutualInductiveInfos
                        (psKernelMakeSimpleMutualBaseInfos
                          (psKernelSimpleMutualNames (first :: remaining)) decl shapes)
                        (psKernelSimpleMutualHasRecursiveFields ctorResult.shapes)
                        (psKernelSimpleMutualHasReflexiveFields ctorResult.shapes) ctorResult.environment
                      cases hBuild : psKernelBuildSimpleMutualRecInfosFromConstructorsWorker
                          shapes shapes recLevelParams
                          (psKernelSimpleMutualNames (first :: remaining)) levels
                          paramResult.binders motives minors ruleBinders
                          ctorResult.shapes 0 decl.isUnsafe with
                      | error message =>
                          simp only [shapes, levels, elimOnlyAtZero, elimLevel, motives,
                            recLevelParams, ruleBinders] at hBuild
                          simp only [hBuild] at hRun
                          cases hRun
                      | ok recInfos =>
                          simp only [shapes, levels, elimOnlyAtZero, elimLevel, motives,
                            recLevelParams, ruleBinders] at hBuild
                          simp only [hBuild] at hRun
                          let work2 := psKernelAddMutualRecursorInfos recInfos work1
                          cases hValidate : psKernelValidateMutualRecursorInfosWorker
                              recInfos fuel work2 recLevelParams
                              (if decl.isUnsafe then PsKernelDefinitionSafety.unsafeDef
                                else PsKernelDefinitionSafety.safe)
                              maxRecDepth maxNatSize levels paramResult.binders motives minors
                              ruleBinders ctorResult.shapes 0 with
                          | error message =>
                              simp only [shapes, levels, elimOnlyAtZero, elimLevel, motives,
                                recLevelParams, ruleBinders, work1, work2] at hValidate
                              simp only [hValidate] at hRun
                              cases hRun
                          | ok validated =>
                              cases validated
                              simp only [shapes, levels, elimOnlyAtZero, elimLevel, motives,
                                recLevelParams, ruleBinders, work1, work2] at hValidate
                              simp only [hValidate] at hRun
                              have hFinal : result = work2 := by
                                simpa using hRun.symm
                              refine ⟨first, remaining, checked, sorted, paramResult, indexResult,
                                resultLevel, tailShapes, ctorResult, minors, recInfos,
                                hTypes, hCheck, hSort, hParams, hIndices, hResult, hTail, hCtor, ?_⟩
                              simpa only [hTypes, shapes, levels, elimOnlyAtZero, elimLevel,
                                motives, recLevelParams, ruleBinders, work1, work2]
                                using And.intro hMinors (And.intro hBuild (And.intro hValidate hFinal))


/--
The actual successful mutual-admission continuation must first construct all
minor binders. This certificate uses the already-proved exact successful
constructor prefix, rather than restating its typing or indexing premises.
It extracts the next executable success event, not an inferred-only assertion.
-/
theorem psKernelAddSimpleMutualInductive_success_minors_stage
    (fuel : Nat) (environment result : PsKernelEnvironment)
    (decl : PsKernelSimpleMutualInductiveDecl) (maxRecDepth maxNatSize : Nat)
    (hIndex : PsKernelEnvironmentIndexRefines environment)
    (hRun : psKernelAddSimpleMutualInductive fuel environment decl
      maxRecDepth maxNatSize = Except.ok result) :
    ∃ (first : PsKernelSimpleMutualTypeDecl)
      (remaining : List PsKernelSimpleMutualTypeDecl)
      (paramResult indexResult : PsKernelOpenBindersResult)
      (resultLevel : PsKernelLevel)
      (tailShapes : List PsKernelSimpleMutualTypeShape)
      (ctorResult : PsKernelAddMutualConstructorsResult)
      (minors : List PsKernelOpenBinder),
      decl.types = first :: remaining ∧
      psKernelAddSimpleMutualTypesWorker
        (PsKernelSimpleMutualTypeShape.mk first indexResult.binders :: tailShapes)
        fuel (if decl.isUnsafe then PsKernelDefinitionSafety.unsafeDef
          else PsKernelDefinitionSafety.safe)
        resultLevel (psKernelLevelParamsToLevels decl.levelParams)
        paramResult.binders (psKernelSimpleMutualNames decl.types)
        (PsKernelSimpleMutualTypeShape.mk first indexResult.binders :: tailShapes)
        paramResult.session
        (psKernelAddMutualInductiveInfos
          (psKernelMakeSimpleMutualBaseInfos
            (psKernelSimpleMutualNames decl.types) decl
            (PsKernelSimpleMutualTypeShape.mk first indexResult.binders :: tailShapes))
          environment) 0 = Except.ok ctorResult ∧
      (let shapes := PsKernelSimpleMutualTypeShape.mk first indexResult.binders :: tailShapes
       let levels := psKernelLevelParamsToLevels decl.levelParams
       let elimOnlyAtZero := if psKernelLevelIsNotZero resultLevel then false else true
       let elimLevel := if elimOnlyAtZero then PsKernelLevel.zero else
         PsKernelLevel.param (psKernelSimpleFreshElimName decl.levelParams)
       let motives := psKernelMakeSimpleMutualMotives
         levels paramResult.binders elimLevel shapes
       psKernelMakeSimpleMutualMinors levels paramResult.binders
         motives ctorResult.shapes = Except.ok minors) := by
  obtain ⟨first, remaining, checked, sorted, paramResult, indexResult, resultLevel,
    tailShapes, ctorResult, minors, recInfos, hTypes, hCheck, hSort, hParams,
    hIndices, hResult, hTail, hCtor, hContinuation⟩ :=
    psKernelAddSimpleMutualInductive_success_transaction_pipeline
      fuel environment result decl maxRecDepth maxNatSize hIndex hRun
  exact ⟨first, remaining, paramResult, indexResult, resultLevel, tailShapes,
    ctorResult, minors, hTypes, hCtor, hContinuation.1⟩
