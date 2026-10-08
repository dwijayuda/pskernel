import Ps.KernelCore.Admission.Inductive.Nested.Admission
import Ps.KernelCore.Metatheory.AdmissionInductiveHeaderConfiguration

/-
Every successful nested-inductive admission first checks the leading user
datatype header in the original environment, before preprocessing or
transformed mutual admission.  This theorem extracts that concrete typed
header and its Sort reduction without assuming anything about later
flattening, restoration, or auxiliary declarations.
-/

theorem psKernelAddSimpleNestedInductive_success_first_header_refines
    (fuel : Nat)
    (environment result : PsKernelEnvironment)
    (decl : PsKernelSimpleMutualInductiveDecl)
    (maxRecDepth maxNatSize : Nat)
    (hIndex : PsKernelEnvironmentIndexRefines environment)
    (hNative : PsKernelNativeReductionSoundLaw)
    (hString : PsKernelStringEqSoundLaw)
    (hRun :
      psKernelAddSimpleNestedInductive
        fuel environment decl maxRecDepth maxNatSize =
        Except.ok result) :
    ∃ (first : PsKernelSimpleMutualTypeDecl)
      (rest : List PsKernelSimpleMutualTypeDecl)
      (inferredType : PsKernelExpr)
      (level : PsKernelLevel),
      decl.types = List.cons first rest ∧
        PsKernelTypingJudgment
          environment psKernelLocalContextEmpty
          first.type inferredType ∧
        PsKernelReductionClosure
          environment psKernelLocalContextEmpty
          inferredType (PsKernelExpr.sort level) := by
  cases hReserved :
      psKernelSimpleNestedCheckReserved decl with
  | error error =>
      simp [psKernelAddSimpleNestedInductive, hReserved] at hRun
  | ok reserved =>
      cases hUniform :
          psKernelSimpleCheckUniformOccurrences
            (psKernelSimpleMutualNames decl.types)
            decl.levelParams
            decl.numParams
            (psKernelSimpleMutualCtorTypes decl.types) with
      | error error =>
          simp [
            psKernelAddSimpleNestedInductive,
            hReserved, hUniform
          ] at hRun
      | ok uniform =>
          cases hTypes : decl.types with
          | nil =>
              simp [
                psKernelAddSimpleNestedInductive,
                hReserved, hUniform, hTypes
              ] at hRun
          | cons first rest =>
              let safety :=
                if decl.isUnsafe then
                  PsKernelDefinitionSafety.unsafeDef
                else
                  PsKernelDefinitionSafety.safe
              let session :=
                psKernelMkCheckerSession environment
                  decl.levelParams safety maxRecDepth maxNatSize
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
              | error error =>
                  simp [
                    psKernelAddSimpleNestedInductive,
                    hReserved, hUniform, hTypes,
                    hChecked
                  ] at hRun
              | ok checked =>
                  cases hSort :
                      psKernelSessionEnsureSort
                        fuel (Prod.snd checked) (Prod.fst checked) with
                  | error error =>
                      simp [
                        psKernelAddSimpleNestedInductive,
                        hReserved, hUniform, hTypes,
                        hChecked, hSort
                      ] at hRun
                  | ok sorted =>
                      rcases checked with ⟨inferredType, checkedSession⟩
                      rcases sorted with ⟨level, sortedSession⟩
                      have hInitial :=
                        psKernelMkCheckerSession_configuration_sound
                          environment decl.levelParams safety
                          maxRecDepth maxNatSize hIndex
                      obtain ⟨hTyped, hReduction, _⟩ :=
                        psKernelCheckedHeaderSort_configuration_refines
                          fuel hNative hString
                          session checkedSession sortedSession
                          first.type inferredType level
                          hInitial hChecked hSort
                      refine ⟨first, rest, inferredType, level, hTypes, ?_, ?_⟩
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
