import Ps.KernelCore.Admission.Inductive.Mutual.AdmissionLoops

theorem psKernelAddSimpleMutualTypesWorker_nil
    (fuel : Nat)
    (safety : PsKernelDefinitionSafety)
    (resultLevel : PsKernelLevel)
    (levels : List PsKernelLevel)
    (params : List PsKernelOpenBinder)
    (typeNames : List PsKernelName)
    (allShapes : List PsKernelSimpleMutualTypeShape)
    (headerSession : PsKernelCheckerSession)
    (work : PsKernelEnvironment)
    (owner : Nat) :
    psKernelAddSimpleMutualTypesWorker
        List.nil fuel safety resultLevel levels params
        typeNames allShapes headerSession work owner =
      Except.ok
        (PsKernelAddMutualConstructorsResult.mk
          work
          List.nil) := by
  rfl
