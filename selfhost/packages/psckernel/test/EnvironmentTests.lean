import Ps.PSCKernel.Core.Environment

structure PsCKernelEnvironmentNamedTest where
  name : String
  passed : Bool

def psCKernelEnvironmentTestName (text : String) : PsCKernelName :=
  psCKernelNameFromDotted text

def psCKernelEnvironmentTestExpr (text : String) : PsCKernelExpr :=
  PsCKernelExpr.constE (psCKernelEnvironmentTestName text) []

def psCKernelEnvironmentTestAxiom (text : String) : PsCKernelConstantInfo :=
  PsCKernelConstantInfo.axiomInfo {
    base := {
      name := psCKernelEnvironmentTestName text
      levelParams := []
      declType := psCKernelEnvironmentTestExpr "Type"
    }
    isUnsafe := false
  }

def psCKernelEnvironmentOptionNameEq
    (value : Option PsCKernelConstantInfo)
    (expected : PsCKernelName) : Bool :=
  match value with
  | none => false
  | some info => psCKernelNameEq (psCKernelConstantInfoName info) expected

def psCKernelEnvironmentTestEmpty : Bool :=
  Nat.beq (psCKernelEnvironmentSize psCKernelEnvironmentEmpty) 0 &&
    !psCKernelEnvironmentContains
      psCKernelEnvironmentEmpty
      (psCKernelEnvironmentTestName "A") &&
    match psCKernelEnvironmentFind?
      psCKernelEnvironmentEmpty
      (psCKernelEnvironmentTestName "A") with
    | none => true
    | some _ => false

def psCKernelEnvironmentTestAddFind : Bool :=
  match psCKernelEnvironmentTryAdd
      psCKernelEnvironmentEmpty
      (psCKernelEnvironmentTestAxiom "A") with
  | none => false
  | some env =>
      Nat.beq (psCKernelEnvironmentSize env) 1 &&
        psCKernelEnvironmentContains env (psCKernelEnvironmentTestName "A") &&
        psCKernelEnvironmentOptionNameEq
          (psCKernelEnvironmentFind? env (psCKernelEnvironmentTestName "A"))
          (psCKernelEnvironmentTestName "A")

def psCKernelEnvironmentTestPersistentAdd : Bool :=
  match psCKernelEnvironmentTryAdd
      psCKernelEnvironmentEmpty
      (psCKernelEnvironmentTestAxiom "A") with
  | none => false
  | some env =>
      Nat.beq (psCKernelEnvironmentSize psCKernelEnvironmentEmpty) 0 &&
        Nat.beq (psCKernelEnvironmentSize env) 1

def psCKernelEnvironmentTestDuplicateRejected : Bool :=
  match psCKernelEnvironmentTryAdd
      psCKernelEnvironmentEmpty
      (psCKernelEnvironmentTestAxiom "A") with
  | none => false
  | some env =>
      match psCKernelEnvironmentTryAdd env (psCKernelEnvironmentTestAxiom "A") with
      | none => true
      | some _ => false

def psCKernelEnvironmentTestTwoConstants : Bool :=
  match psCKernelEnvironmentTryAdd
      psCKernelEnvironmentEmpty
      (psCKernelEnvironmentTestAxiom "A") with
  | none => false
  | some envA =>
      match psCKernelEnvironmentTryAdd envA (psCKernelEnvironmentTestAxiom "B") with
      | none => false
      | some envB =>
          Nat.beq (psCKernelEnvironmentSize envB) 2 &&
            psCKernelEnvironmentContains envB (psCKernelEnvironmentTestName "A") &&
            psCKernelEnvironmentContains envB (psCKernelEnvironmentTestName "B")

def psCKernelEnvironmentTestExactNameIdentity : Bool :=
  match psCKernelEnvironmentTryAdd
      psCKernelEnvironmentEmpty
      (psCKernelEnvironmentTestAxiom "A.B") with
  | none => false
  | some env =>
      psCKernelEnvironmentContains env (psCKernelEnvironmentTestName "A.B") &&
        !psCKernelEnvironmentContains env (psCKernelEnvironmentTestName "B")

def psCKernelEnvironmentTestQuotInitiallyFalse : Bool :=
  !psCKernelEnvironmentEmpty.quotInitialized

def psCKernelEnvironmentTestMarkQuot : Bool :=
  let env := psCKernelEnvironmentMarkQuotInitialized psCKernelEnvironmentEmpty
  env.quotInitialized

def psCKernelEnvironmentTestMarkQuotPreservesConstants : Bool :=
  match psCKernelEnvironmentTryAdd
      psCKernelEnvironmentEmpty
      (psCKernelEnvironmentTestAxiom "A") with
  | none => false
  | some env =>
      let marked := psCKernelEnvironmentMarkQuotInitialized env
      marked.quotInitialized &&
        Nat.beq (psCKernelEnvironmentSize marked) 1 &&
        psCKernelEnvironmentContains marked (psCKernelEnvironmentTestName "A")

def psCKernelEnvironmentTestMarkQuotPersistent : Bool :=
  let marked := psCKernelEnvironmentMarkQuotInitialized psCKernelEnvironmentEmpty
  !psCKernelEnvironmentEmpty.quotInitialized && marked.quotInitialized

def psCKernelEnvironmentTestMarkQuotIdempotent : Bool :=
  let once := psCKernelEnvironmentMarkQuotInitialized psCKernelEnvironmentEmpty
  let twice := psCKernelEnvironmentMarkQuotInitialized once
  once.quotInitialized && twice.quotInitialized &&
    Nat.beq (psCKernelEnvironmentSize once) (psCKernelEnvironmentSize twice)

def psCKernelEnvironmentTests : List PsCKernelEnvironmentNamedTest := [
  { name := "empty environment has no constants", passed := psCKernelEnvironmentTestEmpty },
  { name := "adding a declaration makes it findable", passed := psCKernelEnvironmentTestAddFind },
  { name := "adding preserves the previous environment value", passed := psCKernelEnvironmentTestPersistentAdd },
  { name := "duplicate declaration names are rejected", passed := psCKernelEnvironmentTestDuplicateRejected },
  { name := "multiple unique constants remain available", passed := psCKernelEnvironmentTestTwoConstants },
  { name := "constant lookup uses exact structural Name identity", passed := psCKernelEnvironmentTestExactNameIdentity },
  { name := "quotient support starts uninitialized", passed := psCKernelEnvironmentTestQuotInitiallyFalse },
  { name := "quotient initialization flag can be marked", passed := psCKernelEnvironmentTestMarkQuot },
  { name := "marking quotient initialization preserves constants", passed := psCKernelEnvironmentTestMarkQuotPreservesConstants },
  { name := "marking quotient initialization is persistent", passed := psCKernelEnvironmentTestMarkQuotPersistent },
  { name := "marking quotient initialization is idempotent", passed := psCKernelEnvironmentTestMarkQuotIdempotent }
]

def psCKernelRunEnvironmentTests
    (tests : List PsCKernelEnvironmentNamedTest) : IO Bool :=
  match tests with
  | [] => pure true
  | test :: rest => do
      if test.passed then
        IO.println ("PSCKERNEL_ENVIRONMENT_PASS: " ++ test.name)
      else
        IO.println ("PSCKERNEL_ENVIRONMENT_FAIL: " ++ test.name)
      let restPassed ← psCKernelRunEnvironmentTests rest
      pure (test.passed && restPassed)

def main : IO Unit := do
  let passed ← psCKernelRunEnvironmentTests psCKernelEnvironmentTests
  if passed then
    IO.println "PSCKERNEL_ENVIRONMENT_TESTS: PASS"
  else
    throw (IO.userError "PSCKERNEL_ENVIRONMENT_TESTS: FAIL")
