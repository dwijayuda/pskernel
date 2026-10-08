import Ps.KernelCore.Environment.Lookup

def psKernelEnvironmentAddUnchecked
    (environment : PsKernelEnvironment)
    (info : PsKernelConstantInfo) :
    PsKernelEnvironment :=
  {
    constants :=
      List.cons
        info
        environment.constants
    index :=
      psKernelEnvironmentIndexInsert
        environment.index
        info
    quotInitialized := environment.quotInitialized
    runtime := environment.runtime
  }

def psKernelEnvironmentReplaceUnchecked
    (environment : PsKernelEnvironment)
    (info : PsKernelConstantInfo) :
    PsKernelEnvironment :=
  {
    constants :=
      psKernelReplaceEnvironmentConstant
        (psKernelConstantInfoName info)
        info
        environment.constants
    index :=
      psKernelEnvironmentIndexInsert
        environment.index
        info
    quotInitialized := environment.quotInitialized
    runtime := environment.runtime
  }

def psKernelEnvironmentAdd
    (environment : PsKernelEnvironment)
    (info : PsKernelConstantInfo) :
    Except String PsKernelEnvironment :=
  if
      psKernelEnvironmentContains
        environment
        (psKernelConstantInfoName info) then
    Except.error "already declared"
  else if
      psKernelNameHasDuplicates
        (psKernelConstantInfoLevelParams info) then
    Except.error "duplicate universe parameter"
  else
    Except.ok
      (psKernelEnvironmentAddUnchecked
        environment
        info)

def psKernelEnvironmentMarkQuotInitialized
    (environment : PsKernelEnvironment) :
    PsKernelEnvironment :=
  if environment.quotInitialized then
    environment
  else
    {
      constants := environment.constants
      index := environment.index
      quotInitialized := true
      runtime := environment.runtime
    }
