import Ps.KernelCore.Core.Declaration

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

/- Only declarations and Quot initialization are semantic history. -/
structure PsKernelEnvironmentSemantic where
  constants : List PsKernelConstantInfo
  quotInitialized : Bool
