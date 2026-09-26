import Ps.PSCKernel.Core.InductiveAdmissionUniverse

structure PsCKernelInductiveAdmissionUniverseNamedTest where
  name : String
  passed : Bool

def psCKernelInductiveUniverseName (text : String) : PsCKernelName :=
  psCKernelNameFromDotted text

def psCKernelInductiveUniverseValidationAccepted
    (decl : PsCKernelInductiveDecl) : Bool :=
  match
      psCKernelValidateOrdinaryInductiveUniverse?
        psCKernelEnvironmentEmpty
        decl with
  | none => false
  | some _ => true

def psCKernelInductiveUniverseValidationRejected
    (decl : PsCKernelInductiveDecl) : Bool :=
  !psCKernelInductiveUniverseValidationAccepted decl

def psCKernelInductiveUniverseUnaryDecl
    (typeName ctorName : PsCKernelName)
    (resultLevel fieldDomainLevel : PsCKernelLevel) : PsCKernelInductiveDecl :=
  let fieldName := psCKernelInductiveUniverseName "α"
  let ctorType :=
    PsCKernelExpr.forallE
      fieldName
      (PsCKernelExpr.sortE fieldDomainLevel)
      (PsCKernelExpr.constE typeName [])
      PsCKernelBinderInfo.default
  {
    levelParams := []
    numParams := 0
    types := [{
      name := typeName
      type := PsCKernelExpr.sortE resultLevel
      ctors := [{ name := ctorName, type := ctorType }]
    }]
    isUnsafe := false
    numNested := 0
  }

def psCKernelInductiveUniverseTooLargeFieldDecl : PsCKernelInductiveDecl :=
  psCKernelInductiveUniverseUnaryDecl
    (psCKernelInductiveUniverseName "Universe.Small")
    (psCKernelInductiveUniverseName "Universe.Small.mk")
    (psCKernelLevelSucc psCKernelLevelZero)
    (psCKernelLevelSucc psCKernelLevelZero)

def psCKernelInductiveUniverseBoundedFieldDecl : PsCKernelInductiveDecl :=
  psCKernelInductiveUniverseUnaryDecl
    (psCKernelInductiveUniverseName "Universe.Wide")
    (psCKernelInductiveUniverseName "Universe.Wide.mk")
    (psCKernelLevelSucc (psCKernelLevelSucc psCKernelLevelZero))
    (psCKernelLevelSucc psCKernelLevelZero)

def psCKernelInductiveUniversePropFieldDecl : PsCKernelInductiveDecl :=
  psCKernelInductiveUniverseUnaryDecl
    (psCKernelInductiveUniverseName "Universe.PropLike")
    (psCKernelInductiveUniverseName "Universe.PropLike.mk")
    psCKernelLevelZero
    (psCKernelLevelSucc (psCKernelLevelSucc psCKernelLevelZero))

def psCKernelInductiveAdmissionUniverseTests :
    List PsCKernelInductiveAdmissionUniverseNamedTest := [
  {
    name := "constructor field universe above result universe is rejected"
    passed :=
      psCKernelInductiveUniverseValidationRejected
        psCKernelInductiveUniverseTooLargeFieldDecl
  },
  {
    name := "constructor field universe within result universe is accepted"
    passed :=
      psCKernelInductiveUniverseValidationAccepted
        psCKernelInductiveUniverseBoundedFieldDecl
  },
  {
    name := "Prop result keeps Lean impredicative field-universe exemption"
    passed :=
      psCKernelInductiveUniverseValidationAccepted
        psCKernelInductiveUniversePropFieldDecl
  }
]

def psCKernelRunInductiveAdmissionUniverseTests
    (tests : List PsCKernelInductiveAdmissionUniverseNamedTest) : IO Bool :=
  match tests with
  | [] => pure true
  | test :: rest => do
      if test.passed then
        IO.println ("PSCKERNEL_INDUCTIVE_ADMISSION_UNIVERSE_PASS: " ++ test.name)
      else
        IO.println ("PSCKERNEL_INDUCTIVE_ADMISSION_UNIVERSE_FAIL: " ++ test.name)
      let restPassed ← psCKernelRunInductiveAdmissionUniverseTests rest
      pure (test.passed && restPassed)

def main : IO Unit := do
  let passed ←
    psCKernelRunInductiveAdmissionUniverseTests
      psCKernelInductiveAdmissionUniverseTests
  if passed then
    IO.println "PSCKERNEL_INDUCTIVE_ADMISSION_UNIVERSE_TESTS: PASS"
  else
    throw (IO.userError "PSCKERNEL_INDUCTIVE_ADMISSION_UNIVERSE_TESTS: FAIL")
