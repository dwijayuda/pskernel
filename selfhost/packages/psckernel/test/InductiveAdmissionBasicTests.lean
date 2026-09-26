import Ps.PSCKernel.Core.InductiveAdmission

structure PsCKernelInductiveAdmissionBasicNamedTest where
  name : String
  passed : Bool

def psCKernelInductiveAdmissionName (text : String) : PsCKernelName :=
  psCKernelNameFromDotted text

def psCKernelInductiveAdmissionType : PsCKernelExpr :=
  PsCKernelExpr.sortE (psCKernelLevelSucc psCKernelLevelZero)

def psCKernelInductiveAdmissionBaseAxiom
    (name : PsCKernelName) : PsCKernelConstantInfo :=
  PsCKernelConstantInfo.axiomInfo {
    base := {
      name := name
      levelParams := []
      declType := psCKernelInductiveAdmissionType
    }
    isUnsafe := false
  }

def psCKernelInductiveAdmissionAddRaw
    (env : PsCKernelEnvironment)
    (info : PsCKernelConstantInfo) : PsCKernelEnvironment :=
  match psCKernelEnvironmentTryAdd env info with
  | some next => next
  | none => env

def psCKernelInductiveAdmissionEnumDecl : PsCKernelInductiveDecl :=
  let color := psCKernelInductiveAdmissionName "Basic.Color"
  let red := psCKernelInductiveAdmissionName "Basic.Color.red"
  let blue := psCKernelInductiveAdmissionName "Basic.Color.blue"
  {
    levelParams := []
    numParams := 0
    types := [{
      name := color
      type := psCKernelInductiveAdmissionType
      ctors := [
        { name := red, type := PsCKernelExpr.constE color [] },
        { name := blue, type := PsCKernelExpr.constE color [] }
      ]
    }]
    isUnsafe := false
    numNested := 0
  }

def psCKernelInductiveAdmissionBoxDecl : PsCKernelInductiveDecl :=
  let box := psCKernelInductiveAdmissionName "Basic.Box"
  let mk := psCKernelInductiveAdmissionName "Basic.Box.mk"
  let alpha := psCKernelInductiveAdmissionName "α"
  let value := psCKernelInductiveAdmissionName "value"
  let type :=
    PsCKernelExpr.forallE
      alpha
      psCKernelInductiveAdmissionType
      psCKernelInductiveAdmissionType
      PsCKernelBinderInfo.default
  let ctorType :=
    PsCKernelExpr.forallE
      alpha
      psCKernelInductiveAdmissionType
      (PsCKernelExpr.forallE
        value
        (PsCKernelExpr.bvar 0)
        (PsCKernelExpr.app
          (PsCKernelExpr.constE box [])
          (PsCKernelExpr.bvar 1))
        PsCKernelBinderInfo.default)
      PsCKernelBinderInfo.default
  {
    levelParams := []
    numParams := 1
    types := [{
      name := box
      type := type
      ctors := [{ name := mk, type := ctorType }]
    }]
    isUnsafe := false
    numNested := 0
  }

def psCKernelInductiveAdmissionTestEnum : Bool :=
  match
      psCKernelValidateOrdinaryInductiveBasic?
        psCKernelEnvironmentEmpty
        psCKernelInductiveAdmissionEnumDecl with
  | none => false
  | some result =>
      Nat.beq result.numIndices 0 &&
      result.constructorFields == [0, 0]

def psCKernelInductiveAdmissionTestParametric : Bool :=
  match
      psCKernelValidateOrdinaryInductiveBasic?
        psCKernelEnvironmentEmpty
        psCKernelInductiveAdmissionBoxDecl with
  | none => false
  | some result =>
      Nat.beq result.numIndices 0 &&
      result.constructorFields == [1]

def psCKernelInductiveAdmissionTestEmptyBlock : Bool :=
  let decl : PsCKernelInductiveDecl := {
    levelParams := []
    numParams := 0
    types := []
    isUnsafe := false
    numNested := 0
  }
  match psCKernelValidateOrdinaryInductiveBasic? psCKernelEnvironmentEmpty decl with
  | none => true
  | some _ => false

def psCKernelInductiveAdmissionTestMutualFailsClosed : Bool :=
  let left := psCKernelInductiveAdmissionName "Basic.Left"
  let right := psCKernelInductiveAdmissionName "Basic.Right"
  let decl : PsCKernelInductiveDecl := {
    levelParams := []
    numParams := 0
    types := [
      { name := left, type := psCKernelInductiveAdmissionType, ctors := [] },
      { name := right, type := psCKernelInductiveAdmissionType, ctors := [] }
    ]
    isUnsafe := false
    numNested := 0
  }
  match psCKernelValidateOrdinaryInductiveBasic? psCKernelEnvironmentEmpty decl with
  | none => true
  | some _ => false

def psCKernelInductiveAdmissionTestNestedFailsClosed : Bool :=
  let decl := { psCKernelInductiveAdmissionEnumDecl with numNested := 1 }
  match psCKernelValidateOrdinaryInductiveBasic? psCKernelEnvironmentEmpty decl with
  | none => true
  | some _ => false

def psCKernelInductiveAdmissionTestDuplicateUniverse : Bool :=
  let u := psCKernelInductiveAdmissionName "u"
  let decl := { psCKernelInductiveAdmissionEnumDecl with levelParams := [u, u] }
  match psCKernelValidateOrdinaryInductiveBasic? psCKernelEnvironmentEmpty decl with
  | none => true
  | some _ => false

def psCKernelInductiveAdmissionTestTypeNameConflict : Bool :=
  let typeName := psCKernelInductiveAdmissionName "Basic.Color"
  let env :=
    psCKernelInductiveAdmissionAddRaw
      psCKernelEnvironmentEmpty
      (psCKernelInductiveAdmissionBaseAxiom typeName)
  match psCKernelValidateOrdinaryInductiveBasic? env psCKernelInductiveAdmissionEnumDecl with
  | none => true
  | some _ => false

def psCKernelInductiveAdmissionTestRecursorNameConflict : Bool :=
  let recName :=
    psCKernelStrName (psCKernelInductiveAdmissionName "Basic.Color") "rec"
  let env :=
    psCKernelInductiveAdmissionAddRaw
      psCKernelEnvironmentEmpty
      (psCKernelInductiveAdmissionBaseAxiom recName)
  match psCKernelValidateOrdinaryInductiveBasic? env psCKernelInductiveAdmissionEnumDecl with
  | none => true
  | some _ => false

def psCKernelInductiveAdmissionTestNumParamsMismatch : Bool :=
  let decl := { psCKernelInductiveAdmissionBoxDecl with numParams := 2 }
  match psCKernelValidateOrdinaryInductiveBasic? psCKernelEnvironmentEmpty decl with
  | none => true
  | some _ => false

def psCKernelInductiveAdmissionTestDuplicateCtor : Bool :=
  let color := psCKernelInductiveAdmissionName "Basic.DuplicateCtor"
  let mk := psCKernelInductiveAdmissionName "Basic.DuplicateCtor.mk"
  let decl : PsCKernelInductiveDecl := {
    levelParams := []
    numParams := 0
    types := [{
      name := color
      type := psCKernelInductiveAdmissionType
      ctors := [
        { name := mk, type := PsCKernelExpr.constE color [] },
        { name := mk, type := PsCKernelExpr.constE color [] }
      ]
    }]
    isUnsafe := false
    numNested := 0
  }
  match psCKernelValidateOrdinaryInductiveBasic? psCKernelEnvironmentEmpty decl with
  | none => true
  | some _ => false

def psCKernelInductiveAdmissionTestWrongCtorResult : Bool :=
  let color := psCKernelInductiveAdmissionName "Basic.BadResult"
  let mk := psCKernelInductiveAdmissionName "Basic.BadResult.mk"
  let decl : PsCKernelInductiveDecl := {
    levelParams := []
    numParams := 0
    types := [{
      name := color
      type := psCKernelInductiveAdmissionType
      ctors := [{ name := mk, type := psCKernelInductiveAdmissionType }]
    }]
    isUnsafe := false
    numNested := 0
  }
  match psCKernelValidateOrdinaryInductiveBasic? psCKernelEnvironmentEmpty decl with
  | none => true
  | some _ => false

def psCKernelInductiveAdmissionTestFreeVarHeader : Bool :=
  let color := psCKernelInductiveAdmissionName "Basic.FreeHeader"
  let fvarId : PsCKernelFVarId := { name := psCKernelInductiveAdmissionName "x" }
  let decl : PsCKernelInductiveDecl := {
    levelParams := []
    numParams := 0
    types := [{
      name := color
      type := PsCKernelExpr.fvar fvarId
      ctors := []
    }]
    isUnsafe := false
    numNested := 0
  }
  match psCKernelValidateOrdinaryInductiveBasic? psCKernelEnvironmentEmpty decl with
  | none => true
  | some _ => false

def psCKernelInductiveAdmissionTestRecursiveFailsClosed : Bool :=
  let natLike := psCKernelInductiveAdmissionName "Basic.NatLike"
  let zero := psCKernelInductiveAdmissionName "Basic.NatLike.zero"
  let succ := psCKernelInductiveAdmissionName "Basic.NatLike.succ"
  let recursiveType :=
    PsCKernelExpr.forallE
      (psCKernelInductiveAdmissionName "n")
      (PsCKernelExpr.constE natLike [])
      (PsCKernelExpr.constE natLike [])
      PsCKernelBinderInfo.default
  let decl : PsCKernelInductiveDecl := {
    levelParams := []
    numParams := 0
    types := [{
      name := natLike
      type := psCKernelInductiveAdmissionType
      ctors := [
        { name := zero, type := PsCKernelExpr.constE natLike [] },
        { name := succ, type := recursiveType }
      ]
    }]
    isUnsafe := false
    numNested := 0
  }
  match psCKernelValidateOrdinaryInductiveBasic? psCKernelEnvironmentEmpty decl with
  | none => true
  | some _ => false

def psCKernelInductiveAdmissionBasicTests : List PsCKernelInductiveAdmissionBasicNamedTest := [
  { name := "simple enum validates", passed := psCKernelInductiveAdmissionTestEnum },
  { name := "single parametric inductive validates and counts fields", passed := psCKernelInductiveAdmissionTestParametric },
  { name := "empty inductive block is rejected", passed := psCKernelInductiveAdmissionTestEmptyBlock },
  { name := "mutual inductive block fails closed in basic slice", passed := psCKernelInductiveAdmissionTestMutualFailsClosed },
  { name := "nested inductive block fails closed in basic slice", passed := psCKernelInductiveAdmissionTestNestedFailsClosed },
  { name := "duplicate universe parameters are rejected", passed := psCKernelInductiveAdmissionTestDuplicateUniverse },
  { name := "existing type former name is rejected", passed := psCKernelInductiveAdmissionTestTypeNameConflict },
  { name := "existing generated recursor name is rejected", passed := psCKernelInductiveAdmissionTestRecursorNameConflict },
  { name := "declared parameter count must match header binders", passed := psCKernelInductiveAdmissionTestNumParamsMismatch },
  { name := "duplicate constructor names are rejected", passed := psCKernelInductiveAdmissionTestDuplicateCtor },
  { name := "constructor must return the declared inductive", passed := psCKernelInductiveAdmissionTestWrongCtorResult },
  { name := "free variable in inductive header is rejected", passed := psCKernelInductiveAdmissionTestFreeVarHeader },
  { name := "recursive fields fail closed until positivity slice lands", passed := psCKernelInductiveAdmissionTestRecursiveFailsClosed }
]

def psCKernelRunInductiveAdmissionBasicTests
    (tests : List PsCKernelInductiveAdmissionBasicNamedTest) : IO Bool :=
  match tests with
  | [] => pure true
  | test :: rest => do
      if test.passed then
        IO.println ("PSCKERNEL_INDUCTIVE_ADMISSION_BASIC_PASS: " ++ test.name)
      else
        IO.println ("PSCKERNEL_INDUCTIVE_ADMISSION_BASIC_FAIL: " ++ test.name)
      let restPassed ← psCKernelRunInductiveAdmissionBasicTests rest
      pure (test.passed && restPassed)

def main : IO Unit := do
  let passed ← psCKernelRunInductiveAdmissionBasicTests psCKernelInductiveAdmissionBasicTests
  if passed then
    IO.println "PSCKERNEL_INDUCTIVE_ADMISSION_BASIC_TESTS: PASS"
  else
    throw (IO.userError "PSCKERNEL_INDUCTIVE_ADMISSION_BASIC_TESTS: FAIL")
