import Ps.KernelCore.Admission.Inductive.Nested.Commit
import Ps.KernelCore.Metatheory.AdmissionMutualHeaderConfiguration

/-
The nested pipeline's no-auxiliary-family commit has exactly two checked
routes: ordinary inductive admission for one type, and mutual inductive
admission for a bundle.  This theorem transports the independent checked
header / Sort evidence across that dispatch without asserting that the
constructor and recursor stages are already proved.

The actual preprocessed type list is the checked input; it need not be
identical to the original user declaration's list.
-/

theorem psKernelSimpleNestedAddWithoutAux_success_first_header_refines
    (fuel : Nat)
    (environment result : PsKernelEnvironment)
    (decl : PsKernelSimpleMutualInductiveDecl)
    (types : List PsKernelSimpleMutualTypeDecl)
    (maxRecDepth maxNatSize : Nat)
    (hIndex : PsKernelEnvironmentIndexRefines environment)
    (hNative : PsKernelNativeReductionSoundLaw)
    (hString : PsKernelStringEqSoundLaw)
    (hRun :
      psKernelSimpleNestedAddWithoutAux
          fuel environment decl types maxRecDepth maxNatSize =
        Except.ok result) :
    ∃ (first : PsKernelSimpleMutualTypeDecl)
      (rest : List PsKernelSimpleMutualTypeDecl)
      (inferredType : PsKernelExpr)
      (level : PsKernelLevel),
      types = List.cons first rest ∧
        PsKernelTypingJudgment
          environment psKernelLocalContextEmpty
          first.type inferredType ∧
        PsKernelReductionClosure
          environment psKernelLocalContextEmpty
          inferredType (PsKernelExpr.sort level) := by
  cases types with
  | nil =>
      simp [psKernelSimpleNestedAddWithoutAux] at hRun
  | cons first rest =>
      cases rest with
      | nil =>
          have hOrdinary :
              psKernelAddSimpleInductive
                  fuel
                  environment
                  (PsKernelSimpleInductiveDecl.mk
                    decl.levelParams
                    first.name
                    first.type
                    first.ctors
                    decl.isUnsafe
                    decl.numParams)
                  maxRecDepth
                  maxNatSize =
                Except.ok result := by
            simpa [psKernelSimpleNestedAddWithoutAux] using hRun
          obtain ⟨inferredType, level, hTyped, hReduced⟩ :=
            psKernelAddSimpleInductive_success_header_refines
              fuel environment result
              (PsKernelSimpleInductiveDecl.mk
                decl.levelParams
                first.name
                first.type
                first.ctors
                decl.isUnsafe
                decl.numParams)
              maxRecDepth maxNatSize
              hIndex hNative hString hOrdinary
          exact
            ⟨first, List.nil, inferredType, level,
              rfl, hTyped, hReduced⟩
      | cons second tail =>
          let mutualDecl :=
            PsKernelSimpleMutualInductiveDecl.mk
              decl.levelParams
              decl.numParams
              (List.cons first (List.cons second tail))
              decl.isUnsafe
          have hMutual :
              psKernelAddSimpleMutualInductive
                  fuel environment mutualDecl
                  maxRecDepth maxNatSize =
                Except.ok result := by
            simpa [
              psKernelSimpleNestedAddWithoutAux,
              mutualDecl
            ] using hRun
          obtain ⟨header, remaining, inferredType, level,
              hTypes, hTyped, hReduced⟩ :=
            psKernelAddSimpleMutualInductive_success_first_header_refines
              fuel environment result mutualDecl
              maxRecDepth maxNatSize
              hIndex hNative hString hMutual
          exact
            ⟨header, remaining, inferredType, level,
              (by simpa [mutualDecl] using hTypes),
              hTyped, hReduced⟩
