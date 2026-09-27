import Ps.KernelCore.Declaration

structure PsKernelCoreEnvironment where
  constants : PsKernelCoreList PsKernelCoreConstantInfo
  quotInitialized : Bool

def psKernelCoreEnvironmentFindInConstants
    (name : PsKernelCoreName)
    (constants : PsKernelCoreList PsKernelCoreConstantInfo) :
    PsKernelCoreOption PsKernelCoreConstantInfo :=
  match constants with
  | PsKernelCoreList.nil => PsKernelCoreOption.none
  | PsKernelCoreList.cons info rest =>
      if psKernelCoreNameEq (psKernelCoreConstantInfoName info) name then
        PsKernelCoreOption.some info
      else
        psKernelCoreEnvironmentFindInConstants name rest

def psKernelCoreEnvironmentConstantListSize
    (constants : PsKernelCoreList PsKernelCoreConstantInfo) : Nat :=
  match constants with
  | PsKernelCoreList.nil => Nat.zero
  | PsKernelCoreList.cons _ rest =>
      Nat.succ (psKernelCoreEnvironmentConstantListSize rest)

def psKernelCoreEnvironmentReplaceConstant
    (target : PsKernelCoreName)
    (replacement : PsKernelCoreConstantInfo)
    (constants : PsKernelCoreList PsKernelCoreConstantInfo) :
    PsKernelCoreList PsKernelCoreConstantInfo :=
  match constants with
  | PsKernelCoreList.nil => PsKernelCoreList.nil
  | PsKernelCoreList.cons info rest =>
      if psKernelCoreNameEq (psKernelCoreConstantInfoName info) target then
        PsKernelCoreList.cons replacement rest
      else
        PsKernelCoreList.cons info
          (psKernelCoreEnvironmentReplaceConstant target replacement rest)

def psKernelCoreEnvironmentEmpty : PsKernelCoreEnvironment :=
  {
    constants := PsKernelCoreList.nil
    quotInitialized := false
  }

def psKernelCoreEnvironmentFind?
    (env : PsKernelCoreEnvironment)
    (name : PsKernelCoreName) :
    PsKernelCoreOption PsKernelCoreConstantInfo :=
  psKernelCoreEnvironmentFindInConstants name env.constants

def psKernelCoreEnvironmentContains
    (env : PsKernelCoreEnvironment)
    (name : PsKernelCoreName) : Bool :=
  match psKernelCoreEnvironmentFind? env name with
  | PsKernelCoreOption.none => false
  | PsKernelCoreOption.some _ => true

def psKernelCoreEnvironmentSize
    (env : PsKernelCoreEnvironment) : Nat :=
  psKernelCoreEnvironmentConstantListSize env.constants

def psKernelCoreEnvironmentAddUnchecked
    (env : PsKernelCoreEnvironment)
    (info : PsKernelCoreConstantInfo) : PsKernelCoreEnvironment :=
  {
    constants := PsKernelCoreList.cons info env.constants
    quotInitialized := env.quotInitialized
  }

def psKernelCoreEnvironmentReplaceUnchecked
    (env : PsKernelCoreEnvironment)
    (info : PsKernelCoreConstantInfo) : PsKernelCoreEnvironment :=
  {
    constants :=
      psKernelCoreEnvironmentReplaceConstant
        (psKernelCoreConstantInfoName info)
        info
        env.constants
    quotInitialized := env.quotInitialized
  }

def psKernelCoreEnvironmentAdd
    (env : PsKernelCoreEnvironment)
    (info : PsKernelCoreConstantInfo) :
    PsKernelCoreResult String PsKernelCoreEnvironment :=
  if psKernelCoreEnvironmentContains env (psKernelCoreConstantInfoName info) then
    PsKernelCoreResult.error "already declared"
  else if psKernelCoreNameHasDuplicates (psKernelCoreConstantInfoLevelParams info) then
    PsKernelCoreResult.error "duplicate universe parameter"
  else
    PsKernelCoreResult.ok (psKernelCoreEnvironmentAddUnchecked env info)

def psKernelCoreEnvironmentMarkQuotInitialized
    (env : PsKernelCoreEnvironment) : PsKernelCoreEnvironment :=
  if env.quotInitialized then
    env
  else
    {
      constants := env.constants
      quotInitialized := true
    }
