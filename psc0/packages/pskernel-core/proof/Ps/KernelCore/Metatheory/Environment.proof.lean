import Ps.KernelCore.Metatheory.Judgments

theorem psKernelEnvironmentEmpty_index_refines :
    PsKernelEnvironmentIndexRefines
      psKernelEnvironmentEmpty := by
  unfold PsKernelEnvironmentIndexRefines
  intro name
  rfl

theorem psKernelEnvironmentIndexRefines_lookup_sound
    (environment : PsKernelEnvironment)
    (hIndex :
      PsKernelEnvironmentIndexRefines environment) :
    PsKernelEnvironmentLookupSound environment := by
  unfold PsKernelEnvironmentLookupSound
  intro name info hFind
  unfold psKernelEnvironmentFind at hFind
  unfold PsKernelEnvironmentIndexRefines at hIndex
  calc
    psKernelFindConstantInList
        name
        environment.constants =
      psKernelFindConstantInList
        name
        (psKernelEnvironmentIndexFind
          environment.index
          name) := (hIndex name).symm
    _ = Option.some info := hFind

theorem psKernelEnvironmentWithNativeEvaluator_index_refines
    (environment : PsKernelEnvironment)
    (nativeEvaluator : Option PsKernelNativeEvaluator)
    (hIndex :
      PsKernelEnvironmentIndexRefines environment) :
    PsKernelEnvironmentIndexRefines
      (psKernelEnvironmentWithNativeEvaluator
        environment
        nativeEvaluator) := by
  unfold PsKernelEnvironmentIndexRefines at hIndex ⊢
  intro name
  simpa [psKernelEnvironmentWithNativeEvaluator] using
    hIndex name
