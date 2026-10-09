import Ps.KernelCore.Metatheory.AdmissionMutualRecursorTransactionConfiguration

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
    tailShapes, ctorResult, hTypes, hCheck, hSort, hParams, hIndices,
    hResult, hTail, hCtor⟩ :=
    psKernelAddSimpleMutualInductive_success_constructor_pipeline
      fuel environment result decl maxRecDepth maxNatSize hRun
  obtain ⟨hDuplicate, hMinTypes, hUnique, _⟩ :=
    psKernelAddSimpleMutualInductive_success_name_guards
      fuel environment result decl maxRecDepth maxNatSize hIndex hRun
  let allNames : List PsKernelName :=
    psKernelMutualNameListAppend
      (psKernelSimpleMutualNames decl.types)
      (psKernelMutualNameListAppend
        (psKernelSimpleMutualRecNames decl.types)
        (psKernelSimpleMutualCtorNames decl.types))
  cases hFresh : psKernelCheckFreshInductiveNames allNames environment with
  | error message =>
      simp [psKernelAddSimpleMutualInductive, hDuplicate, hMinTypes,
        allNames, hUnique, hFresh] at hRun
  | ok fresh =>
      cases hUniform : psKernelSimpleCheckUniformOccurrences
          (psKernelSimpleMutualNames decl.types) decl.levelParams decl.numParams
          (psKernelSimpleMutualCtorTypes decl.types) with
      | error message =>
          simp [psKernelAddSimpleMutualInductive, hDuplicate, hMinTypes,
            allNames, hUnique, hFresh, hUniform] at hRun
      | ok uniform =>
          cases hClosed : psKernelCheckNoMVarNoFVar first.type with
          | error message =>
              simp [psKernelAddSimpleMutualInductive, hDuplicate, hMinTypes,
                allNames, hUnique, hFresh, hUniform, hTypes, hClosed] at hRun
          | ok closed =>
              cases hLevels : psKernelCheckLevelParams first.type decl.levelParams with
              | error message =>
                  simp [psKernelAddSimpleMutualInductive, hDuplicate, hMinTypes,
                    allNames, hUnique, hFresh, hUniform, hTypes,
                    hClosed, hLevels] at hRun
              | ok checkedLevels =>
                  let shapes : List PsKernelSimpleMutualTypeShape :=
                    PsKernelSimpleMutualTypeShape.mk first indexResult.binders :: tailShapes
                  let levels := psKernelLevelParamsToLevels decl.levelParams
                  let elimOnlyAtZero := if psKernelLevelIsNotZero resultLevel then false else true
                  let elimLevel := if elimOnlyAtZero then PsKernelLevel.zero else
                    PsKernelLevel.param (psKernelSimpleFreshElimName decl.levelParams)
                  let motives := psKernelMakeSimpleMutualMotives
                    levels paramResult.binders elimLevel shapes
                  simp only [psKernelAddSimpleMutualInductive, hDuplicate, hMinTypes,
                    allNames, hUnique, hFresh, hUniform, hTypes,
                    hClosed, hLevels, hCheck, hSort, hParams,
                    hIndices, hResult, hTail, hCtor] at hRun
                  cases hMinors : psKernelMakeSimpleMutualMinors
                      levels paramResult.binders motives ctorResult.shapes with
                  | error message =>
                      simp only [hMinors] at hRun
                      cases hRun
                  | ok minors =>
                      refine ⟨first, remaining, paramResult, indexResult,
                        resultLevel, tailShapes, ctorResult, minors, hTypes, hCtor, ?_⟩
                      simpa [shapes, levels, elimOnlyAtZero, elimLevel, motives]
                        using hMinors
