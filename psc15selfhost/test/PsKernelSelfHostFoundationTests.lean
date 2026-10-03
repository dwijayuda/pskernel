import Ps.KernelSelfHost.Level
import PSC1Kernel.Level

def psKernelNameToReference
    (name : PsKernelName) : PSC1Kernel.Name :=
  match name with
  | PsKernelName.anonymous =>
      PSC1Kernel.Name.anonymous
  | PsKernelName.str parent value =>
      PSC1Kernel.Name.str
        (psKernelNameToReference parent)
        value
  | PsKernelName.num parent value =>
      PSC1Kernel.Name.num
        (psKernelNameToReference parent)
        value

def psKernelNameOptionToReference
    (value : Option PsKernelName) :
    Option PSC1Kernel.Name :=
  match value with
  | Option.none =>
      Option.none
  | Option.some name =>
      Option.some (psKernelNameToReference name)

def psKernelReferenceNameOptionEq
    (left right : Option PSC1Kernel.Name) : Bool :=
  match left with
  | Option.none =>
      match right with
      | Option.none => true
      | Option.some _ => false
  | Option.some leftName =>
      match right with
      | Option.none => false
      | Option.some rightName =>
          PSC1Kernel.Name.eq leftName rightName

def psKernelNameDifferentialCase
    (left right : PsKernelName) : Bool :=
  Bool.and
    ((psKernelNameEq left right) ==
      (PSC1Kernel.Name.eq
        (psKernelNameToReference left)
        (psKernelNameToReference right)))
    (psKernelNameCmp left right ==
      PSC1Kernel.Name.cmp
        (psKernelNameToReference left)
        (psKernelNameToReference right))

def psKernelNamePrefixDifferentialCase
    (needle candidate : PsKernelName) : Bool :=
  (psKernelNameIsPrefixOf needle candidate) ==
    (PSC1Kernel.Name.isPrefixOf
      (psKernelNameToReference needle)
      (psKernelNameToReference candidate))

def psKernelNameReplaceDifferentialCase
    (name oldPrefix newPrefix : PsKernelName) : Bool :=
  psKernelReferenceNameOptionEq
    (psKernelNameOptionToReference
      (psKernelNameReplacePrefix
        name
        oldPrefix
        newPrefix))
    (PSC1Kernel.Name.replacePrefix
      (psKernelNameToReference name)
      (psKernelNameToReference oldPrefix)
      (psKernelNameToReference newPrefix))

def psKernelNameTestRoot : PsKernelName :=
  PsKernelName.str
    (PsKernelName.str
      PsKernelName.anonymous
      "PSC1Kernel")
    "Expr"

def psKernelNameTestNested : PsKernelName :=
  PsKernelName.num
    (PsKernelName.str
      psKernelNameTestRoot
      "field")
    3

def psKernelNameTestReplacement : PsKernelName :=
  PsKernelName.str
    PsKernelName.anonymous
    "Portable"

def psKernelSelfHostNameTests : Bool :=
  Bool.and
    (psKernelNameDifferentialCase
      PsKernelName.anonymous
      PsKernelName.anonymous)
    (Bool.and
      (psKernelNameDifferentialCase
        psKernelNameTestRoot
        psKernelNameTestNested)
      (Bool.and
        (psKernelNamePrefixDifferentialCase
          psKernelNameTestRoot
          psKernelNameTestNested)
        (psKernelNameReplaceDifferentialCase
          psKernelNameTestNested
          psKernelNameTestRoot
          psKernelNameTestReplacement)))

def psKernelLevelToReference
    (level : PsKernelLevel) : PSC1Kernel.Level :=
  match level with
  | PsKernelLevel.zero =>
      PSC1Kernel.Level.zero
  | PsKernelLevel.succ inner =>
      PSC1Kernel.Level.succ
        (psKernelLevelToReference inner)
  | PsKernelLevel.max left right =>
      PSC1Kernel.Level.max
        (psKernelLevelToReference left)
        (psKernelLevelToReference right)
  | PsKernelLevel.imax left right =>
      PSC1Kernel.Level.imax
        (psKernelLevelToReference left)
        (psKernelLevelToReference right)
  | PsKernelLevel.param name =>
      PSC1Kernel.Level.param
        (psKernelNameToReference name)
  | PsKernelLevel.mvar name =>
      PSC1Kernel.Level.mvar
        (psKernelNameToReference name)

def psKernelLevelDifferentialCase
    (left right : PsKernelLevel) : Bool :=
  let referenceLeft :=
    psKernelLevelToReference left
  let referenceRight :=
    psKernelLevelToReference right
  let normalizedPortable :=
    psKernelLevelToReference
      (psKernelLevelNormalize left)
  let normalizedReference :=
    PSC1Kernel.Level.normalize referenceLeft
  Bool.and
    ((psKernelLevelEquivalent left right) ==
      (PSC1Kernel.Level.equivalent
        referenceLeft
        referenceRight))
    (Bool.and
      ((psKernelLevelLe left right) ==
        (PSC1Kernel.Level.le
          referenceLeft
          referenceRight))
      (PSC1Kernel.Level.eq
        normalizedPortable
        normalizedReference))

def psKernelLevelParamU : PsKernelLevel :=
  PsKernelLevel.param
    (PsKernelName.str
      PsKernelName.anonymous
      "u")

def psKernelLevelParamV : PsKernelLevel :=
  PsKernelLevel.param
    (PsKernelName.str
      PsKernelName.anonymous
      "v")

def psKernelSelfHostLevelTests : Bool :=
  let explicitTwo :=
    PsKernelLevel.succ
      (PsKernelLevel.succ
        PsKernelLevel.zero)
  let left :=
    PsKernelLevel.max
      (PsKernelLevel.succ psKernelLevelParamU)
      explicitTwo
  let right :=
    PsKernelLevel.imax
      psKernelLevelParamV
      (PsKernelLevel.succ PsKernelLevel.zero)
  Bool.and
    (psKernelLevelDifferentialCase
      PsKernelLevel.zero
      PsKernelLevel.zero)
    (Bool.and
      (psKernelLevelDifferentialCase
        left
        left)
      (psKernelLevelDifferentialCase
        left
        right))

def main : IO Unit :=
  if !psKernelSelfHostNameTests then
    throw
      (IO.userError
        "PSC1_KERNEL_SELFHOST_NAME_DIFFERENTIAL: FAIL")
  else if !psKernelSelfHostLevelTests then
    throw
      (IO.userError
        "PSC1_KERNEL_SELFHOST_LEVEL_DIFFERENTIAL: FAIL")
  else
    IO.println
      "PSC1_KERNEL_SELFHOST_FOUNDATION_DIFFERENTIAL: PASS"
