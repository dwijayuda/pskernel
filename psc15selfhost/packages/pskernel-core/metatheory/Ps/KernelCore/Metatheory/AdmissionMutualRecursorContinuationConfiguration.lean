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
  /-
  Normalize both the executable pipeline and its guard witnesses to the same
  checked source family before decomposing the remaining successful path.
  This avoids silently changing the family on only one side of a guard.
  -/
  rw [hTypes] at hRun hMinTypes hUnique
  let allNames : List PsKernelName :=
    psKernelMutualNameListAppend
      (psKernelSimpleMutualNames (first :: remaining))
      (psKernelMutualNameListAppend
        (psKernelSimpleMutualRecNames (first :: remaining))
        (psKernelSimpleMutualCtorNames (first :: remaining)))
  simp only [psKernelAddSimpleMutualInductive, hDuplicate, hMinTypes, hUnique] at hRun
  cases hFresh : psKernelCheckFreshInductiveNames allNames environment with
  | error message =>
      simp only [hFresh] at hRun
      cases hRun
  | ok fresh =>
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
                      simp only [hMinors] at hRun
                      cases hRun
                  | ok minors =>
                      refine ⟨first, remaining, paramResult, indexResult,
                        resultLevel, tailShapes, ctorResult, minors, hTypes, hCtor, ?_⟩
                      simpa [shapes, levels, elimOnlyAtZero, elimLevel, motives]
                        using hMinors
