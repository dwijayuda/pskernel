import Ps.PSCKernel.Core.Declaration

structure PsCKernelEnvironment where
  constants : List PsCKernelConstantInfo
  quotInitialized : Bool

def psCKernelEnvironmentEmpty : PsCKernelEnvironment :=
  {
    constants := []
    quotInitialized := false
  }

def psCKernelEnvironmentFindIn
    (constants : List PsCKernelConstantInfo)
    (name : PsCKernelName) : Option PsCKernelConstantInfo :=
  match constants with
  | [] => none
  | info :: rest =>
      if psCKernelNameEq (psCKernelConstantInfoName info) name then
        some info
      else
        psCKernelEnvironmentFindIn rest name

def psCKernelEnvironmentFind?
    (env : PsCKernelEnvironment)
    (name : PsCKernelName) : Option PsCKernelConstantInfo :=
  psCKernelEnvironmentFindIn env.constants name

def psCKernelEnvironmentContains
    (env : PsCKernelEnvironment)
    (name : PsCKernelName) : Bool :=
  match psCKernelEnvironmentFind? env name with
  | none => false
  | some _ => true

def psCKernelEnvironmentSize (env : PsCKernelEnvironment) : Nat :=
  env.constants.length

def psCKernelEnvironmentTryAdd
    (env : PsCKernelEnvironment)
    (info : PsCKernelConstantInfo) : Option PsCKernelEnvironment :=
  let name : PsCKernelName := psCKernelConstantInfoName info
  if psCKernelEnvironmentContains env name then
    none
  else
    some {
      constants := info :: env.constants
      quotInitialized := env.quotInitialized
    }

def psCKernelEnvironmentMarkQuotInitialized
    (env : PsCKernelEnvironment) : PsCKernelEnvironment :=
  {
    constants := env.constants
    quotInitialized := true
  }
