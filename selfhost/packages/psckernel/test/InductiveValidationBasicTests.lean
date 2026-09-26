import Ps.PSCKernel.Core.InductiveValidationBasic

structure PsCKernelInductiveValidationBasicNamedTest where
  name : String
  passed : Bool

def psCKernelInductiveValidationTestName (text : String) : PsCKernelName :=
  psCKernelNameFromDotted text

def psCKernelInductiveValidationCtor
    (name : String)
    (declType : PsCKernelExpr) : PsCKernelConstructorDecl := {
  name := psCKernelInductiveValidationTestName name
  declType := declType
}

def psCKernelInductiveValidationType
    (name : String)
    (declType : PsCKernelExpr)
    (ctors : List PsCKernelConstructorDecl) : PsCKernelInductiveTypeDecl := {
  name := psCKernelInductiveValidationTestName name
  declType := declType
  ctors := ctors
}

def psCKernelInductiveValidationDecl
    (types : List PsCKernelInductiveTypeDecl)
    (levelParams : List PsCKernelName := [])
    (numParams : Nat := 0)
    (numNested : Nat := 0) : PsCKernelInductiveDecl := {
  levelParams := levelParams
  numParams := numParams
  types := types
  isUnsafe := false
  numNested := numNested
}

def psCKernelInductiveValidationSimple
    (name : String := "P")
    (ctorNames : List String := ["P.intro"]) : PsCKernelInductiveDecl :=
  let indName := psCKernelInductiveValidationTestName name
  let result := PsCKernelExpr.constE indName []
  let ctors := ctorNames.map fun ctorName =>
    psCKernelInductiveValidationCtor ctorName result
  psCKernelInductiveValidationDecl [
    psCKernelInductiveValidationType
      name
      (PsCKernelExpr.sortE psCKernelLevelZero)
      ctors
  ]

def psCKernelInductiveValidationSeed : PsCKernelEnvironment :=
  let base : PsCKernelConstantVal := {
    name := psCKernelInductiveValidationTestName "Existing"
    levelParams := []
    declType := PsCKernelExpr.sortE psCKernelLevelZero
  }
  let info := PsCKernelConstantInfo.axiomInfo { base := base, isUnsafe := false }
  match psCKernelEnvironmentTryAdd psCKernelEnvironmentEmpty info with
  | some env => env
  | none => psCKernelEnvironmentEmpty

def psCKernelInductiveValidationAccepted
    (env : PsCKernelEnvironment)
    (decl : PsCKernelInductiveDecl) : Bool :=
  match psCKernelStageInductiveBasic? env decl with
  | some _ => true
  | none => false

def psCKernelInductiveValidationTestSimple : Bool :=
  psCKernelInductiveValidationAccepted
    psCKernelEnvironmentEmpty
    psCKernelInductiveValidationSimple

def psCKernelInductiveValidationTestEmptyConstructors : Bool :=
  psCKernelInductiveValidationAccepted
    psCKernelEnvironmentEmpty
    (psCKernelInductiveValidationSimple (ctorNames := []))

def psCKernelInductiveValidationTestTwoConstructors : Bool :=
  psCKernelInductiveValidationAccepted
    psCKernelEnvironmentEmpty
    (psCKernelInductiveValidationSimple
      (ctorNames := ["P.left", "P.right"]))

def psCKernelInductiveValidationTestMetadata : Bool :=
  match psCKernelStageInductiveBasic?
      psCKernelEnvironmentEmpty
      (psCKernelInductiveValidationSimple
        (ctorNames := ["P.left", "P.right"])) with
  | none => false
  | some staged =>
      match psCKernelEnvironmentFind?
        staged
        (psCKernelInductiveValidationTestName "P") with
      | some (PsCKernelConstantInfo.inductInfo value) =>
          Nat.beq value.numParams 0 &&
          Nat.beq value.numIndices 0 &&
          Nat.beq value.numNested 0 &&
          !value.isRec &&
          !value.isUnsafe &&
          !value.isReflexive &&
          psCKernelNameListEq
            value.ctors
            [
              psCKernelInductiveValidationTestName "P.left",
              psCKernelInductiveValidationTestName "P.right"
            ]
      | _ => false

def psCKernelInductiveValidationTestConstructorMetadata : Bool :=
  match psCKernelStageInductiveBasic?
      psCKernelEnvironmentEmpty
      psCKernelInductiveValidationSimple with
  | none => false
  | some staged =>
      match psCKernelEnvironmentFind?
        staged
        (psCKernelInductiveValidationTestName "P.intro") with
      | some (PsCKernelConstantInfo.ctorInfo value) =>
          psCKernelNameEq
            value.induct
            (psCKernelInductiveValidationTestName "P") &&
          Nat.beq value.cidx 0 &&
          Nat.beq value.numParams 0 &&
          Nat.beq value.numFields 0 &&
          !value.isUnsafe
      | _ => false

def psCKernelInductiveValidationTestEmptyBlock : Bool :=
  !psCKernelInductiveValidationAccepted
    psCKernelEnvironmentEmpty
    (psCKernelInductiveValidationDecl [])

def psCKernelInductiveValidationTestParamsFailClosed : Bool :=
  !psCKernelInductiveValidationAccepted
    psCKernelEnvironmentEmpty
    (psCKernelInductiveValidationSimple |>.withNumParams 1)

def psCKernelInductiveValidationTestNestedFailClosed : Bool :=
  !psCKernelInductiveValidationAccepted
    psCKernelEnvironmentEmpty
    (psCKernelInductiveValidationSimple |>.withNumNested 1)

def psCKernelInductiveValidationTestDuplicateLevels : Bool :=
  let u := psCKernelInductiveValidationTestName "u"
  let decl := psCKernelInductiveValidationDecl
    [psCKernelInductiveValidationType
      "P"
      (PsCKernelExpr.sortE (PsCKernelLevel.param u))
      []]
    (levelParams := [u, u])
  !psCKernelInductiveValidationAccepted psCKernelEnvironmentEmpty decl

def psCKernelInductiveValidationTestDuplicateTypes : Bool :=
  let p := psCKernelInductiveValidationType
    "P" (PsCKernelExpr.sortE psCKernelLevelZero) []
  !psCKernelInductiveValidationAccepted
    psCKernelEnvironmentEmpty
    (psCKernelInductiveValidationDecl [p, p])

def psCKernelInductiveValidationTestExistingTypeName : Bool :=
  let decl := psCKernelInductiveValidationDecl [
    psCKernelInductiveValidationType
      "Existing"
      (PsCKernelExpr.sortE psCKernelLevelZero)
      []
  ]
  !psCKernelInductiveValidationAccepted psCKernelInductiveValidationSeed decl

def psCKernelInductiveValidationTestHeaderFreeVar : Bool :=
  let id : PsCKernelFVarId := { name := psCKernelInductiveValidationTestName "free" }
  let decl := psCKernelInductiveValidationDecl [
    psCKernelInductiveValidationType "P" (PsCKernelExpr.fvar id) []
  ]
  !psCKernelInductiveValidationAccepted psCKernelEnvironmentEmpty decl

def psCKernelInductiveValidationTestMutualSameUniverse : Bool :=
  let pName := psCKernelInductiveValidationTestName "P"
  let qName := psCKernelInductiveValidationTestName "Q"
  let decl := psCKernelInductiveValidationDecl [
    psCKernelInductiveValidationType
      "P"
      (PsCKernelExpr.sortE psCKernelLevelZero)
      [psCKernelInductiveValidationCtor "P.intro" (PsCKernelExpr.constE pName [])],
    psCKernelInductiveValidationType
      "Q"
      (PsCKernelExpr.sortE psCKernelLevelZero)
      [psCKernelInductiveValidationCtor "Q.intro" (PsCKernelExpr.constE qName [])]
  ]
  psCKernelInductiveValidationAccepted psCKernelEnvironmentEmpty decl

def psCKernelInductiveValidationTestMutualUniverseMismatch : Bool :=
  let decl := psCKernelInductiveValidationDecl [
    psCKernelInductiveValidationType
      "P" (PsCKernelExpr.sortE psCKernelLevelZero) [],
    psCKernelInductiveValidationType
      "Q" (PsCKernelExpr.sortE (psCKernelLevelSucc psCKernelLevelZero)) []
  ]
  !psCKernelInductiveValidationAccepted psCKernelEnvironmentEmpty decl

def psCKernelInductiveValidationTestDuplicateConstructor : Bool :=
  let pName := psCKernelInductiveValidationTestName "P"
  let result := PsCKernelExpr.constE pName []
  let ctor := psCKernelInductiveValidationCtor "P.intro" result
  let decl := psCKernelInductiveValidationDecl [
    psCKernelInductiveValidationType
      "P" (PsCKernelExpr.sortE psCKernelLevelZero) [ctor, ctor]
  ]
  !psCKernelInductiveValidationAccepted psCKernelEnvironmentEmpty decl

def psCKernelInductiveValidationTestCtorConflictsType : Bool :=
  let pName := psCKernelInductiveValidationTestName "P"
  let decl := psCKernelInductiveValidationDecl [
    psCKernelInductiveValidationType
      "P"
      (PsCKernelExpr.sortE psCKernelLevelZero)
      [psCKernelInductiveValidationCtor "P" (PsCKernelExpr.constE pName [])]
  ]
  !psCKernelInductiveValidationAccepted psCKernelEnvironmentEmpty decl

def psCKernelInductiveValidationTestCtorConflictsExisting : Bool :=
  let pName := psCKernelInductiveValidationTestName "P"
  let decl := psCKernelInductiveValidationDecl [
    psCKernelInductiveValidationType
      "P"
      (PsCKernelExpr.sortE psCKernelLevelZero)
      [psCKernelInductiveValidationCtor
        "Existing"
        (PsCKernelExpr.constE pName [])]
  ]
  !psCKernelInductiveValidationAccepted psCKernelInductiveValidationSeed decl

def psCKernelInductiveValidationTestCtorWrongResult : Bool :=
  let qName := psCKernelInductiveValidationTestName "Q"
  let decl := psCKernelInductiveValidationDecl [
    psCKernelInductiveValidationType
      "P"
      (PsCKernelExpr.sortE psCKernelLevelZero)
      [psCKernelInductiveValidationCtor "P.intro" (PsCKernelExpr.constE qName [])]
  ]
  !psCKernelInductiveValidationAccepted psCKernelEnvironmentEmpty decl

def psCKernelInductiveValidationTestCtorFieldFailClosed : Bool :=
  let pName := psCKernelInductiveValidationTestName "P"
  let fieldType := PsCKernelExpr.sortE psCKernelLevelZero
  let ctorType := PsCKernelExpr.forallE
    (psCKernelInductiveValidationTestName "x")
    fieldType
    (PsCKernelExpr.constE pName [])
    PsCKernelBinderInfo.default
  let decl := psCKernelInductiveValidationDecl [
    psCKernelInductiveValidationType
      "P"
      (PsCKernelExpr.sortE psCKernelLevelZero)
      [psCKernelInductiveValidationCtor "P.intro" ctorType]
  ]
  !psCKernelInductiveValidationAccepted psCKernelEnvironmentEmpty decl

def psCKernelInductiveValidationTestWrongUniverseArgs : Bool :=
  let u := psCKernelInductiveValidationTestName "u"
  let v := psCKernelInductiveValidationTestName "v"
  let pName := psCKernelInductiveValidationTestName "P"
  let decl := psCKernelInductiveValidationDecl
    [psCKernelInductiveValidationType
      "P"
      (PsCKernelExpr.sortE (PsCKernelLevel.param u))
      [psCKernelInductiveValidationCtor
        "P.intro"
        (PsCKernelExpr.constE pName [PsCKernelLevel.param v])]]
    (levelParams := [u, v])
  !psCKernelInductiveValidationAccepted psCKernelEnvironmentEmpty decl

def psCKernelInductiveValidationTestPersistentFailure : Bool :=
  let before := psCKernelEnvironmentSize psCKernelInductiveValidationSeed
  let bad := psCKernelInductiveValidationDecl []
  let _ := psCKernelStageInductiveBasic? psCKernelInductiveValidationSeed bad
  Nat.beq before (psCKernelEnvironmentSize psCKernelInductiveValidationSeed) &&
  psCKernelEnvironmentContains
    psCKernelInductiveValidationSeed
    (psCKernelInductiveValidationTestName "Existing")

def psCKernelInductiveValidationBasicTests : List PsCKernelInductiveValidationBasicNamedTest := [
  { name := "simple nullary Prop inductive stages", passed := psCKernelInductiveValidationTestSimple },
  { name := "constructor-free Prop inductive stages", passed := psCKernelInductiveValidationTestEmptyConstructors },
  { name := "two nullary constructors stage", passed := psCKernelInductiveValidationTestTwoConstructors },
  { name := "staged inductive metadata is exact", passed := psCKernelInductiveValidationTestMetadata },
  { name := "staged constructor metadata is exact", passed := psCKernelInductiveValidationTestConstructorMetadata },
  { name := "empty block is rejected", passed := psCKernelInductiveValidationTestEmptyBlock },
  { name := "parameterized declarations fail closed in basic slice", passed := psCKernelInductiveValidationTestParamsFailClosed },
  { name := "nested declarations fail closed in basic slice", passed := psCKernelInductiveValidationTestNestedFailClosed },
  { name := "duplicate universe parameters are rejected", passed := psCKernelInductiveValidationTestDuplicateLevels },
  { name := "duplicate inductive type names are rejected", passed := psCKernelInductiveValidationTestDuplicateTypes },
  { name := "existing inductive type name is rejected", passed := psCKernelInductiveValidationTestExistingTypeName },
  { name := "free variable in inductive header is rejected", passed := psCKernelInductiveValidationTestHeaderFreeVar },
  { name := "basic mutual block in same universe stages", passed := psCKernelInductiveValidationTestMutualSameUniverse },
  { name := "mutual block universe mismatch is rejected", passed := psCKernelInductiveValidationTestMutualUniverseMismatch },
  { name := "duplicate constructor name is rejected", passed := psCKernelInductiveValidationTestDuplicateConstructor },
  { name := "constructor name cannot collide with inductive type", passed := psCKernelInductiveValidationTestCtorConflictsType },
  { name := "constructor name cannot collide with environment", passed := psCKernelInductiveValidationTestCtorConflictsExisting },
  { name := "constructor must return its owning inductive", passed := psCKernelInductiveValidationTestCtorWrongResult },
  { name := "field-bearing constructor fails closed in basic slice", passed := psCKernelInductiveValidationTestCtorFieldFailClosed },
  { name := "constructor must use declaration universe vector exactly", passed := psCKernelInductiveValidationTestWrongUniverseArgs },
  { name := "failed staging preserves original persistent environment", passed := psCKernelInductiveValidationTestPersistentFailure }
]

def psCKernelRunInductiveValidationBasicTests
    (tests : List PsCKernelInductiveValidationBasicNamedTest) : IO Bool :=
  match tests with
  | [] => pure true
  | test :: rest => do
      if test.passed then
        IO.println ("PSCKERNEL_INDUCTIVE_VALIDATION_BASIC_PASS: " ++ test.name)
      else
        IO.println ("PSCKERNEL_INDUCTIVE_VALIDATION_BASIC_FAIL: " ++ test.name)
      let restPassed ← psCKernelRunInductiveValidationBasicTests rest
      pure (test.passed && restPassed)

def main : IO Unit := do
  let passed ← psCKernelRunInductiveValidationBasicTests psCKernelInductiveValidationBasicTests
  if passed then
    IO.println "PSCKERNEL_INDUCTIVE_VALIDATION_BASIC_TESTS: PASS"
  else
    throw (IO.userError "PSCKERNEL_INDUCTIVE_VALIDATION_BASIC_TESTS: FAIL")
