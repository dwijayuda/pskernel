import Ps.KernelCore.Admission.Inductive.Nested.Admission

theorem psKernelAddSimpleNestedInductive_reserved_failure
    (fuel : Nat)
    (environment : PsKernelEnvironment)
    (decl : PsKernelSimpleMutualInductiveDecl)
    (maxRecDepth maxNatSize : Nat)
    (error : String)
    (h :
      psKernelSimpleNestedCheckReserved decl =
        Except.error error) :
    psKernelAddSimpleNestedInductive
        fuel environment decl maxRecDepth maxNatSize =
      Except.error error := by
  simp [psKernelAddSimpleNestedInductive, h]
