import Ps.KernelCore.Admission.Inductive.Nested.Commit

theorem psKernelSimpleNestedMakeRenamesWorker_nil
    (mainRec : PsKernelName)
    (index : Nat) :
    psKernelSimpleNestedMakeRenamesWorker
        List.nil mainRec index =
      List.nil := by
  rfl

theorem psKernelSimpleNestedAddWithoutAux_empty
    (fuel : Nat)
    (environment : PsKernelEnvironment)
    (decl : PsKernelSimpleMutualInductiveDecl)
    (maxRecDepth maxNatSize : Nat) :
    psKernelSimpleNestedAddWithoutAux
        fuel environment decl List.nil maxRecDepth maxNatSize =
      Except.error "empty nested inductive declaration" := by
  rfl
