import PsKernel.Name
import PSC1Kernel.Name

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

def main : IO Unit :=
  if psKernelSelfHostNameTests then
    IO.println "PSC1_KERNEL_SELFHOST_NAME_DIFFERENTIAL: PASS"
  else
    throw
      (IO.userError
        "PSC1_KERNEL_SELFHOST_NAME_DIFFERENTIAL: FAIL")
