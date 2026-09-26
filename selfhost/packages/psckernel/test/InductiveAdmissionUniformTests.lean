import Ps.PSCKernel.Core.InductiveAdmissionUniform

structure PsCKernelInductiveUniformNamedTest where
  name : String
  passed : Bool

def psCKernelInductiveUniformName (text : String) : PsCKernelName :=
  psCKernelNameFromDotted text

def psCKernelInductiveUniformType : PsCKernelExpr :=
  PsCKernelExpr.sortE (psCKernelLevelSucc psCKernelLevelZero)

def psCKernelInductiveUniformListType
    (target : PsCKernelName) : PsCKernelExpr :=
  PsCKernelExpr.forallE
    (psCKernelInductiveUniformName "α")
    psCKernelInductiveUniformType
    psCKernelInductiveUniformType
    PsCKernelBinderInfo.default

def psCKernelInductiveUniformDirectDecl : PsCKernelInductiveDecl :=
  let target := psCKernelInductiveUniformName "Uniform.ListLike"
  let nilName := psCKernelInductiveUniformName "Uniform.ListLike.nil"
  let consName := psCKernelInductiveUniformName "Uniform.ListLike.cons"
  let nilType :=
    PsCKernelExpr.forallE
      (psCKernelInductiveUniformName "α")
      psCKernelInductiveUniformType
      (PsCKernelExpr.app
        (PsCKernelExpr.constE target [])
        (PsCKernelExpr.bvar 0))
      PsCKernelBinderInfo.default
  let consType :=
    PsCKernelExpr.forallE
      (psCKernelInductiveUniformName "α")
      psCKernelInductiveUniformType
      (PsCKernelExpr.forallE
        (psCKernelInductiveUniformName "x")
        (PsCKernelExpr.bvar 0)
        (PsCKernelExpr.forallE
          (psCKernelInductiveUniformName "xs")
          (PsCKernelExpr.app
            (PsCKernelExpr.constE target [])
            (PsCKernelExpr.bvar 1))
          (PsCKernelExpr.app
            (PsCKernelExpr.constE target [])
            (PsCKernelExpr.bvar 2))
          PsCKernelBinderInfo.default)
        PsCKernelBinderInfo.default)
      PsCKernelBinderInfo.default
  {
    levelParams := []
    numParams := 1
    types := [{
      name := target
      type := psCKernelInductiveUniformListType target
      ctors := [
        { name := nilName, type := nilType },
        { name := consName, type := consType }
      ]
    }]
    isUnsafe := false
    numNested := 0
  }

def psCKernelInductiveUniformErasedDecl
    (validParameter : Bool) : PsCKernelInductiveDecl :=
  let target := psCKernelInductiveUniformName "Uniform.Erased"
  let mk := psCKernelInductiveUniformName "Uniform.Erased.mk"
  let recursiveArgument :=
    if validParameter then
      PsCKernelExpr.bvar 0
    else
      PsCKernelExpr.sortE psCKernelLevelZero
  let recursiveOccurrence :=
    PsCKernelExpr.app
      (PsCKernelExpr.constE target [])
      recursiveArgument
  let eraser :=
    PsCKernelExpr.lam
      (psCKernelInductiveUniformName "ignored")
      psCKernelInductiveUniformType
      (PsCKernelExpr.sortE psCKernelLevelZero)
      PsCKernelBinderInfo.default
  let erasedFieldType := PsCKernelExpr.app eraser recursiveOccurrence
  let ctorType :=
    PsCKernelExpr.forallE
      (psCKernelInductiveUniformName "α")
      psCKernelInductiveUniformType
      (PsCKernelExpr.forallE
        (psCKernelInductiveUniformName "ghost")
        erasedFieldType
        (PsCKernelExpr.app
          (PsCKernelExpr.constE target [])
          (PsCKernelExpr.bvar 1))
        PsCKernelBinderInfo.default)
      PsCKernelBinderInfo.default
  {
    levelParams := []
    numParams := 1
    types := [{
      name := target
      type := psCKernelInductiveUniformListType target
      ctors := [{ name := mk, type := ctorType }]
    }]
    isUnsafe := false
    numNested := 0
  }

def psCKernelInductiveUniformAccepted
    (decl : PsCKernelInductiveDecl) : Bool :=
  match
      psCKernelValidateOrdinaryInductiveUniform?
        psCKernelEnvironmentEmpty
        decl with
  | none => false
  | some _ => true

def psCKernelInductivePositiveAcceptedForUniformTest
    (decl : PsCKernelInductiveDecl) : Bool :=
  match
      psCKernelValidateOrdinaryInductivePositive?
        psCKernelEnvironmentEmpty
        decl with
  | none => false
  | some _ => true

def psCKernelInductiveUniformTests : List PsCKernelInductiveUniformNamedTest := [
  {
    name := "parameterized direct recursion keeps the shared parameter"
    passed :=
      psCKernelInductiveUniformAccepted
        psCKernelInductiveUniformDirectDecl
  },
  {
    name := "syntactically uniform occurrence may be erased by reduction"
    passed :=
      psCKernelInductiveUniformAccepted
        (psCKernelInductiveUniformErasedDecl true)
  },
  {
    name := "nonuniform occurrence erased by reduction is still rejected"
    passed :=
      psCKernelInductivePositiveAcceptedForUniformTest
          (psCKernelInductiveUniformErasedDecl false) &&
      !psCKernelInductiveUniformAccepted
          (psCKernelInductiveUniformErasedDecl false)
  }
]

def psCKernelRunInductiveUniformTests
    (tests : List PsCKernelInductiveUniformNamedTest) : IO Bool :=
  match tests with
  | [] => pure true
  | test :: rest => do
      if test.passed then
        IO.println ("PSCKERNEL_INDUCTIVE_ADMISSION_UNIFORM_PASS: " ++ test.name)
      else
        IO.println ("PSCKERNEL_INDUCTIVE_ADMISSION_UNIFORM_FAIL: " ++ test.name)
      let restPassed ← psCKernelRunInductiveUniformTests rest
      pure (test.passed && restPassed)

def main : IO Unit := do
  let passed ← psCKernelRunInductiveUniformTests psCKernelInductiveUniformTests
  if passed then
    IO.println "PSCKERNEL_INDUCTIVE_ADMISSION_UNIFORM_TESTS: PASS"
  else
    throw (IO.userError "PSCKERNEL_INDUCTIVE_ADMISSION_UNIFORM_TESTS: FAIL")
