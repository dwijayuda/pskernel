import Ps.KernelSelfHost.Runtime.EnvironmentIndex
import Ps.KernelSelfHost.Runtime.Capability.Lean434NativeReduction

def psKernelNameListContains
    (needle : PsKernelName)
    (values : List PsKernelName) : Bool :=
  match values with
  | List.nil =>
      false
  | List.cons head tail =>
      if psKernelNameEq needle head then
        true
      else
        psKernelNameListContains
          needle
          tail

def psKernelNameHasDuplicates
    (values : List PsKernelName) : Bool :=
  match values with
  | List.nil =>
      false
  | List.cons head tail =>
      if psKernelNameListContains head tail then
        true
      else
        psKernelNameHasDuplicates tail

def psKernelFindConstantInList
    (name : PsKernelName)
    (values : List PsKernelConstantInfo) :
    Option PsKernelConstantInfo :=
  match values with
  | List.nil =>
      Option.none
  | List.cons info rest =>
      if
          psKernelNameEq
            (psKernelConstantInfoName info)
            name then
        Option.some info
      else
        psKernelFindConstantInList
          name
          rest

def psKernelReplaceEnvironmentConstant
    (target : PsKernelName)
    (replacement : PsKernelConstantInfo)
    (values : List PsKernelConstantInfo) :
    List PsKernelConstantInfo :=
  match values with
  | List.nil =>
      List.nil
  | List.cons info rest =>
      if
          psKernelNameEq
            (psKernelConstantInfoName info)
            target then
        List.cons replacement rest
      else
        List.cons
          info
          (psKernelReplaceEnvironmentConstant
            target
            replacement
            rest)

def psKernelConstantListLength
    (values : List PsKernelConstantInfo) : Nat :=
  match values with
  | List.nil =>
      0
  | List.cons _ rest =>
      Nat.succ
        (psKernelConstantListLength rest)

structure PsKernelEnvironmentRuntime where
  nativeEvaluator : Option PsKernelNativeEvaluator

def psKernelEnvironmentRuntimeEmpty :
    PsKernelEnvironmentRuntime :=
  {
    nativeEvaluator := Option.none
  }

structure PsKernelEnvironment where
  constants : List PsKernelConstantInfo
  index : PsKernelEnvironmentIndex
  quotInitialized : Bool
  runtime : PsKernelEnvironmentRuntime

def psKernelEnvironmentEmpty : PsKernelEnvironment :=
  {
    constants := List.nil
    index := PsKernelEnvironmentIndex.empty
    quotInitialized := false
    runtime := psKernelEnvironmentRuntimeEmpty
  }

def psKernelEnvironmentWithNativeEvaluator
    (environment : PsKernelEnvironment)
    (nativeEvaluator : Option PsKernelNativeEvaluator) :
    PsKernelEnvironment :=
  {
    constants := environment.constants
    index := environment.index
    quotInitialized := environment.quotInitialized
    runtime := {
      nativeEvaluator := nativeEvaluator
    }
  }

def psKernelEnvironmentFind
    (environment : PsKernelEnvironment)
    (name : PsKernelName) :
    Option PsKernelConstantInfo :=
  psKernelFindConstantInList
    name
    (psKernelEnvironmentIndexFind
      environment.index
      name)

def psKernelEnvironmentContains
    (environment : PsKernelEnvironment)
    (name : PsKernelName) : Bool :=
  match psKernelEnvironmentFind environment name with
  | Option.some _ => true
  | Option.none => false

def psKernelEnvironmentGet
    (environment : PsKernelEnvironment)
    (name : PsKernelName) :
    Option PsKernelConstantInfo :=
  psKernelEnvironmentFind
    environment
    name

def psKernelEnvironmentSize
    (environment : PsKernelEnvironment) : Nat :=
  psKernelConstantListLength
    environment.constants

def psKernelEnvironmentIsNonRecStructure
    (environment : PsKernelEnvironment)
    (name : PsKernelName) : Bool :=
  match psKernelEnvironmentFind environment name with
  | Option.some info =>
      match info with
      | PsKernelConstantInfo.inductInfo inductiveInfo =>
          if inductiveInfo.isRec then
            false
          else if Nat.beq inductiveInfo.numIndices 0 then
            Nat.beq
              (psKernelNameListLength inductiveInfo.ctors)
              1
          else
            false
      | _ =>
          false
  | Option.none =>
      false

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
