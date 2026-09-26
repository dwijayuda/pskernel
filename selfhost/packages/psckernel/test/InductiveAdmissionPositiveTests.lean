import Ps.PSCKernel.Core.InductiveAdmissionPositive

structure PsCKernelInductivePositiveNamedTest where
  name : String
  passed : Bool

def psCKernelInductivePositiveName (text : String) : PsCKernelName :=
  psCKernelNameFromDotted text

def psCKernelInductivePositiveType : PsCKernelExpr :=
  PsCKernelExpr.sortE (psCKernelLevelSucc psCKernelLevelZero)

def psCKernelInductivePositiveDirectDecl : PsCKernelInductiveDecl :=
  let target := psCKernelInductivePositiveName "Positive.NatLike"
  let zero := psCKernelInductivePositiveName "Positive.NatLike.zero"
  let succ := psCKernelInductivePositiveName "Positive.NatLike.succ"
  let succType :=
    PsCKernelExpr.forallE
      (psCKernelInductivePositiveName "n")
      (PsCKernelExpr.constE target [])
      (PsCKernelExpr.constE target [])
      PsCKernelBinderInfo.default
  {
    levelParams := []
    numParams := 0
    types := [{
      name := target
      type := psCKernelInductivePositiveType
      ctors := [
        { name := zero, type := PsCKernelExpr.constE target [] },
        { name := succ, type := succType }
      ]
    }]
    isUnsafe := false
    numNested := 0
  }

def psCKernelInductivePositiveHigherOrderDecl : PsCKernelInductiveDecl :=
  let target := psCKernelInductivePositiveName "Positive.Higher"
  let mk := psCKernelInductivePositiveName "Positive.Higher.mk"
  let callbackType :=
    PsCKernelExpr.forallE
      (psCKernelInductivePositiveName "p")
      (PsCKernelExpr.sortE psCKernelLevelZero)
      (PsCKernelExpr.constE target [])
      PsCKernelBinderInfo.default
  let ctorType :=
    PsCKernelExpr.forallE
      (psCKernelInductivePositiveName "f")
      callbackType
      (PsCKernelExpr.constE target [])
      PsCKernelBinderInfo.default
  {
    levelParams := []
    numParams := 0
    types := [{
      name := target
      type := psCKernelInductivePositiveType
      ctors := [{ name := mk, type := ctorType }]
    }]
    isUnsafe := false
    numNested := 0
  }

def psCKernelInductivePositiveNegativeDecl : PsCKernelInductiveDecl :=
  let target := psCKernelInductivePositiveName "Positive.Negative"
  let mk := psCKernelInductivePositiveName "Positive.Negative.mk"
  let badFieldType :=
    PsCKernelExpr.forallE
      (psCKernelInductivePositiveName "x")
      (PsCKernelExpr.constE target [])
      (PsCKernelExpr.sortE psCKernelLevelZero)
      PsCKernelBinderInfo.default
  let ctorType :=
    PsCKernelExpr.forallE
      (psCKernelInductivePositiveName "f")
      badFieldType
      (PsCKernelExpr.constE target [])
      PsCKernelBinderInfo.default
  {
    levelParams := []
    numParams := 0
    types := [{
      name := target
      type := psCKernelInductivePositiveType
      ctors := [{ name := mk, type := ctorType }]
    }]
    isUnsafe := false
    numNested := 0
  }

def psCKernelInductivePositiveNonrecursiveDecl : PsCKernelInductiveDecl :=
  let target := psCKernelInductivePositiveName "Positive.Color"
  let red := psCKernelInductivePositiveName "Positive.Color.red"
  let blue := psCKernelInductivePositiveName "Positive.Color.blue"
  {
    levelParams := []
    numParams := 0
    types := [{
      name := target
      type := psCKernelInductivePositiveType
      ctors := [
        { name := red, type := PsCKernelExpr.constE target [] },
        { name := blue, type := PsCKernelExpr.constE target [] }
      ]
    }]
    isUnsafe := false
    numNested := 0
  }

def psCKernelInductivePositiveUniverseViolationDecl : PsCKernelInductiveDecl :=
  let target := psCKernelInductivePositiveName "Positive.UniverseViolation"
  let mk := psCKernelInductivePositiveName "Positive.UniverseViolation.mk"
  let ctorType :=
    PsCKernelExpr.forallE
      (psCKernelInductivePositiveName "α")
      (PsCKernelExpr.sortE (psCKernelLevelSucc psCKernelLevelZero))
      (PsCKernelExpr.constE target [])
      PsCKernelBinderInfo.default
  {
    levelParams := []
    numParams := 0
    types := [{
      name := target
      type := psCKernelInductivePositiveType
      ctors := [{ name := mk, type := ctorType }]
    }]
    isUnsafe := false
    numNested := 0
  }

def psCKernelInductivePositiveUnsafeDecl : PsCKernelInductiveDecl :=
  { psCKernelInductivePositiveDirectDecl with isUnsafe := true }

def psCKernelInductivePositiveTestDirect : Bool :=
  match
      psCKernelValidateOrdinaryInductivePositive?
        psCKernelEnvironmentEmpty
        psCKernelInductivePositiveDirectDecl with
  | none => false
  | some result =>
      result.isRec &&
      !result.isReflexive &&
      result.constructorFields == [0, 1]

def psCKernelInductivePositiveTestHigherOrder : Bool :=
  match
      psCKernelValidateOrdinaryInductivePositive?
        psCKernelEnvironmentEmpty
        psCKernelInductivePositiveHigherOrderDecl with
  | none => false
  | some result =>
      result.isRec &&
      result.isReflexive &&
      result.constructorFields == [1]

def psCKernelInductivePositiveTestNegative : Bool :=
  match
      psCKernelValidateOrdinaryInductivePositive?
        psCKernelEnvironmentEmpty
        psCKernelInductivePositiveNegativeDecl with
  | none => true
  | some _ => false

def psCKernelInductivePositiveTestNonrecursive : Bool :=
  match
      psCKernelValidateOrdinaryInductivePositive?
        psCKernelEnvironmentEmpty
        psCKernelInductivePositiveNonrecursiveDecl with
  | none => false
  | some result =>
      !result.isRec &&
      !result.isReflexive &&
      result.constructorFields == [0, 0]

def psCKernelInductivePositiveTestUniverseInherited : Bool :=
  match
      psCKernelValidateOrdinaryInductivePositive?
        psCKernelEnvironmentEmpty
        psCKernelInductivePositiveUniverseViolationDecl with
  | none => true
  | some _ => false

def psCKernelInductivePositiveTestUnsafeFailsClosed : Bool :=
  match
      psCKernelValidateOrdinaryInductivePositive?
        psCKernelEnvironmentEmpty
        psCKernelInductivePositiveUnsafeDecl with
  | none => true
  | some _ => false

def psCKernelInductivePositiveTests : List PsCKernelInductivePositiveNamedTest := [
  {
    name := "direct recursive constructor is strictly positive"
    passed := psCKernelInductivePositiveTestDirect
  },
  {
    name := "higher-order recursive codomain is strictly positive"
    passed := psCKernelInductivePositiveTestHigherOrder
  },
  {
    name := "recursive occurrence in function domain is rejected"
    passed := psCKernelInductivePositiveTestNegative
  },
  {
    name := "nonrecursive family remains accepted"
    passed := psCKernelInductivePositiveTestNonrecursive
  },
  {
    name := "constructor field universe bound remains enforced"
    passed := psCKernelInductivePositiveTestUniverseInherited
  },
  {
    name := "unsafe positivity remains fail-closed in safe slice"
    passed := psCKernelInductivePositiveTestUnsafeFailsClosed
  }
]

def psCKernelRunInductivePositiveTests
    (tests : List PsCKernelInductivePositiveNamedTest) : IO Bool :=
  match tests with
  | [] => pure true
  | test :: rest => do
      if test.passed then
        IO.println ("PSCKERNEL_INDUCTIVE_ADMISSION_POSITIVE_PASS: " ++ test.name)
      else
        IO.println ("PSCKERNEL_INDUCTIVE_ADMISSION_POSITIVE_FAIL: " ++ test.name)
      let restPassed ← psCKernelRunInductivePositiveTests rest
      pure (test.passed && restPassed)

def main : IO Unit := do
  let passed ← psCKernelRunInductivePositiveTests psCKernelInductivePositiveTests
  if passed then
    IO.println "PSCKERNEL_INDUCTIVE_ADMISSION_POSITIVE_TESTS: PASS"
  else
    throw (IO.userError "PSCKERNEL_INDUCTIVE_ADMISSION_POSITIVE_TESTS: FAIL")
