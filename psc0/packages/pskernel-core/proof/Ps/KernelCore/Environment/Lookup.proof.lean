import Ps.KernelCore.Environment.Lookup
import Ps.KernelCore.Metatheory.Judgments

theorem psKernelEnvironmentGet_is_find
    (environment : PsKernelEnvironment)
    (name : PsKernelName) :
    psKernelEnvironmentGet environment name =
      psKernelEnvironmentFind environment name := by
  rfl

theorem psKernelEnvironmentSize_empty :
    psKernelEnvironmentSize psKernelEnvironmentEmpty = 0 := by
  rfl

theorem psKernelEnvironmentContains_of_find_none
    (environment : PsKernelEnvironment)
    (name : PsKernelName)
    (h : psKernelEnvironmentFind environment name = Option.none) :
    psKernelEnvironmentContains environment name = false := by
  simp [psKernelEnvironmentContains, h]

theorem psKernelEnvironmentContains_of_find_some
    (environment : PsKernelEnvironment)
    (name : PsKernelName)
    (info : PsKernelConstantInfo)
    (h : psKernelEnvironmentFind environment name = Option.some info) :
    psKernelEnvironmentContains environment name = true := by
  simp [psKernelEnvironmentContains, h]


theorem psKernelEnvironmentFind_refines_authoritative
    (environment : PsKernelEnvironment)
    (name : PsKernelName)
    (hIndex :
      PsKernelEnvironmentIndexRefines environment) :
    psKernelEnvironmentFind environment name =
      psKernelFindConstantInList
        name
        environment.constants := by
  unfold psKernelEnvironmentFind
  exact hIndex name
