import Ps.KernelCore.Metatheory.AdmissionMutualConstructorSemanticHistoryConfiguration
import Ps.KernelCore.Metatheory.AdmissionMutualInductiveIndexConfiguration
import Ps.KernelCore.Admission.Inductive.Mutual.Admission

theorem psKernelAddSimpleMutualInductive_empty_bundle
    (fuel : Nat)
    (environment : PsKernelEnvironment)
    (maxRecDepth maxNatSize : Nat) :
    psKernelAddSimpleMutualInductive
        fuel
        environment
        (PsKernelSimpleMutualInductiveDecl.mk
          List.nil
          0
          List.nil
          false)
        maxRecDepth
        maxNatSize =
      Except.error
        "mutual inductive admission requires at least two datatypes" := by
  rfl

theorem psKernelAddSimpleMutualInductive_rejects_duplicate_universes
    (fuel : Nat)
    (environment : PsKernelEnvironment)
    (decl : PsKernelSimpleMutualInductiveDecl)
    (maxRecDepth maxNatSize : Nat)
    (h : psKernelNameHasDuplicates decl.levelParams = true) :
    psKernelAddSimpleMutualInductive
        fuel environment decl maxRecDepth maxNatSize =
      Except.error "duplicate universe parameter" := by
  simp [psKernelAddSimpleMutualInductive, h]

#print axioms PsKernelCheckedMutualFamilyConstructorHistory.exact_extension
#print axioms PsKernelCheckedMutualFamilyConstructorHistory.preserves_absent_names
#print axioms psKernelReplaceMutualInductiveInfos_semantic_refines
