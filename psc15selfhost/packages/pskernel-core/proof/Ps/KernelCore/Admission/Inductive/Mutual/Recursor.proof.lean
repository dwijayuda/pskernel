import Ps.KernelCore.Admission.Inductive.Mutual.Recursor

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
    (recNames : List PsKernelName)
    (recLevels : List PsKernelLevel)
    (params motives allMinors ruleBinders minors : List PsKernelOpenBinder) :
    psKernelMakeSimpleMutualRulesWorker
        List.nil recNames recLevels params motives
        allMinors ruleBinders minors =
      Except.ok List.nil := by
  rfl
