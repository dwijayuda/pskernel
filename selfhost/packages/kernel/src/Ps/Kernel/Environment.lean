import Ps.Kernel.Model

structure PsKernelEnvironment where
  constants : List PsKernelConstantInfo

def psKernelEnvironmentEmpty : PsKernelEnvironment :=
  { constants := [] }

def psKernelEnvironmentFindInList
    (name : PsName) : List PsKernelConstantInfo -> Option PsKernelConstantInfo
  | [] => none
  | info :: rest =>
      if psNameEq name (psKernelConstantName info) then
        some info
      else
        psKernelEnvironmentFindInList name rest

def psKernelEnvironmentFind
    (environment : PsKernelEnvironment)
    (name : PsName) : Option PsKernelConstantInfo :=
  psKernelEnvironmentFindInList name environment.constants

def psKernelEnvironmentContains
    (environment : PsKernelEnvironment)
    (name : PsName) : Bool :=
  match psKernelEnvironmentFind environment name with
  | none => false
  | some _ => true

def psKernelEnvironmentAddRaw
    (environment : PsKernelEnvironment)
    (info : PsKernelConstantInfo) : Option PsKernelEnvironment :=
  if psKernelEnvironmentContains environment (psKernelConstantName info) then
    none
  else
    some { constants := info :: environment.constants }
