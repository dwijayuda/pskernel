import Ps.KernelCore.Admission.Inductive.Nested.Admission
import Ps.KernelCore.Metatheory.AdmissionInductiveHeaderConfiguration

/-
Every successful nested-inductive admission first checks the leading user
datatype header in the original environment, before preprocessing or
transformed mutual admission.  This theorem extracts that concrete typed
header and its Sort reduction without assuming anything about later
flattening, restoration, or auxiliary declarations.
-/

theorem psKernelAddSimpleNestedInductive_success_header_params_refines
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
      (level : PsKernelLevel)
      (checkedSession sortedSession : PsKernelCheckerSession)
      (openedParams : PsKernelOpenBindersResult),
      decl.types = List.cons first rest ∧
        psKernelSessionCheck
            fuel
            (psKernelMkCheckerSession
              environment decl.levelParams
              (if decl.isUnsafe then
                PsKernelDefinitionSafety.unsafeDef
               else
                PsKernelDefinitionSafety.safe)
              maxRecDepth maxNatSize)
            first.type =
          Except.ok (Prod.mk inferredType checkedSession) ∧
        psKernelSessionEnsureSort
            fuel checkedSession inferredType =
          Except.ok (Prod.mk level sortedSession) ∧
        psKernelOpenSimpleHeaderParams
            fuel sortedSession first.type decl.numParams =
          Except.ok openedParams ∧
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
              simp only [hTypes] at hUniform
              simp [
                psKernelAddSimpleNestedInductive,
                hReserved, hUniform, hTypes
              ] at hRun
          | cons first rest =>
              simp only [hTypes] at hUniform
              let safety :=
                if decl.isUnsafe then
                  PsKernelDefinitionSafety.unsafeDef
                else
                  PsKernelDefinitionSafety.safe
              let session :=
                psKernelMkCheckerSession environment
                  decl.levelParams safety maxRecDepth maxNatSize
              cases hChecked :
                  psKernelSessionCheck fuel session first.type with
              | error error =>
                  simp [
                    psKernelAddSimpleNestedInductive,
                    hReserved, hUniform, hTypes,
                    session, safety, hChecked
                  ] at hRun
              | ok checked =>
                  cases hSort :
                      psKernelSessionEnsureSort
                        fuel (Prod.snd checked) (Prod.fst checked) with
                  | error error =>
                      simp [
                        psKernelAddSimpleNestedInductive,
                        hReserved, hUniform, hTypes,
                        session, safety, hChecked, hSort
                      ] at hRun
                  | ok sorted =>
                      cases hParams :
                          psKernelOpenSimpleHeaderParams
                            fuel (Prod.snd sorted)
                            first.type decl.numParams with
                      | error error =>
                          simp [
                            psKernelAddSimpleNestedInductive,
                            hReserved, hUniform, hTypes,
                            session, safety,
                            hChecked, hSort, hParams
                          ] at hRun
                      | ok openedParams =>
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
                          refine
                            ⟨first, rest, inferredType, level,
                             checkedSession, sortedSession, openedParams,
                             rfl, ?_, hSort, hParams, ?_, ?_⟩
                          · simpa [session, safety] using hChecked
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
  obtain
      ⟨first, rest, inferredType, level,
       checkedSession, sortedSession, openedParams,
       hTypes, _, _, _, hTyped, hReduction⟩ :=
    psKernelAddSimpleNestedInductive_success_header_params_refines
      fuel environment result decl maxRecDepth maxNatSize
      hIndex hNative hString hRun
  exact ⟨first, rest, inferredType, level,
    hTypes, hTyped, hReduction⟩
