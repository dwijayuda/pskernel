import Ps.KernelCore.Environment.Environment

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

