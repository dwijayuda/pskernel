import Ps.KernelCore.Admission.Inductive.Ordinary.ConstructorAdmission

theorem psKernelAddSimpleConstructorsWithFuel_zero
    (decl : PsKernelSimpleInductiveDecl)
    (safety : PsKernelDefinitionSafety)
    (resultLevel : PsKernelLevel)
    (levels : List PsKernelLevel)
    (params : List PsKernelOpenBinder)
    (numIndices : Nat)
    (headerSession : PsKernelCheckerSession)
    (work : PsKernelEnvironment)
    (index : Nat)
    (ctors : List PsKernelSimpleConstructorDecl) :
    psKernelAddSimpleConstructorsWithFuel
        0 decl safety resultLevel levels params numIndices
        headerSession work index ctors =
      Except.error
        "simple inductive constructor admission budget exhausted" := by
  rfl
