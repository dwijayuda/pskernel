import Ps.KernelCore.Metatheory.AdmissionMutualRecursorSemanticConfiguration

theorem psKernelMakeSimpleMutualMotivesWorker_nil
    (levels : List PsKernelLevel)
    (params : List PsKernelOpenBinder)
    (elimLevel : PsKernelLevel)
    (index : Nat) :
    psKernelMakeSimpleMutualMotivesWorker
        List.nil levels params elimLevel index =
      List.nil := by
  rfl

theorem psKernelMakeSimpleMutualRulesWorker_nil
    (recLevelParams : List PsKernelName)
    (typeShapes : List PsKernelSimpleMutualTypeShape)
    (params motives minors ruleBinders : List PsKernelOpenBinder)
    (owner minorIndex : Nat) :
    psKernelMakeSimpleMutualRulesWorker
        List.nil
        recLevelParams
        typeShapes
        params
        motives
        minors
        ruleBinders
        owner
        minorIndex =
      Except.ok List.nil := by
  rfl

theorem psKernelValidateSimpleMutualRulesWorker_nil
    (fuel : Nat)
    (session : PsKernelCheckerSession)
    (levels : List PsKernelLevel)
    (params motives minors ruleBinders : List PsKernelOpenBinder)
    (owner : Nat) :
    psKernelValidateSimpleMutualRulesWorker
        List.nil
        fuel
        session
        levels
        params
        motives
        minors
        ruleBinders
        owner
        List.nil =
      Except.ok session := by
  rfl
