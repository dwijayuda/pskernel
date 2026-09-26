import Ps.PSCKernel.Core.DefEq

structure PsCKernelDefEqEtaNamedTest where
  name : String
  passed : Bool

def psCKernelDefEqEtaName (text : String) : PsCKernelName :=
  psCKernelNameFromDotted text

def psCKernelDefEqEtaConst (text : String) : PsCKernelExpr :=
  PsCKernelExpr.constE (psCKernelDefEqEtaName text) []

def psCKernelDefEqEtaAxiom
    (name : String)
    (declType : PsCKernelExpr) : PsCKernelConstantInfo :=
  PsCKernelConstantInfo.axiomInfo {
    base := {
      name := psCKernelDefEqEtaName name
      levelParams := []
      declType := declType
    }
    isUnsafe := false
  }

def psCKernelDefEqEtaDefinition
    (name : String)
    (declType : PsCKernelExpr)
    (value : PsCKernelExpr) : PsCKernelConstantInfo :=
  PsCKernelConstantInfo.defnInfo {
    base := {
      name := psCKernelDefEqEtaName name
      levelParams := []
      declType := declType
    }
    value := value
    hints := PsCKernelReducibilityHints.regular 0
    safety := PsCKernelDefinitionSafety.safe
    all := []
  }

def psCKernelDefEqEtaAdd
    (env : PsCKernelEnvironment)
    (info : PsCKernelConstantInfo) : PsCKernelEnvironment :=
  match psCKernelEnvironmentTryAdd env info with
  | none => env
  | some next => next

def psCKernelDefEqEtaEnv : PsCKernelEnvironment :=
  let sort1 := PsCKernelExpr.sortE (psCKernelLevelSucc psCKernelLevelZero)
  let aType := psCKernelDefEqEtaConst "A"
  let bType := psCKernelDefEqEtaConst "B"
  let fnType :=
    PsCKernelExpr.forallE
      (psCKernelDefEqEtaName "x") aType bType PsCKernelBinderInfo.default
  let aliasFn := psCKernelDefEqEtaConst "AliasFn"
  let env0 := psCKernelDefEqEtaAdd psCKernelEnvironmentEmpty
    (psCKernelDefEqEtaAxiom "A" sort1)
  let env1 := psCKernelDefEqEtaAdd env0
    (psCKernelDefEqEtaAxiom "B" sort1)
  let env2 := psCKernelDefEqEtaAdd env1
    (psCKernelDefEqEtaAxiom "a" aType)
  let env3 := psCKernelDefEqEtaAdd env2
    (psCKernelDefEqEtaAxiom "f" fnType)
  let env4 := psCKernelDefEqEtaAdd env3
    (psCKernelDefEqEtaAxiom "g" fnType)
  let env5 := psCKernelDefEqEtaAdd env4
    (psCKernelDefEqEtaDefinition "AliasFn" sort1 fnType)
  psCKernelDefEqEtaAdd env5
    (psCKernelDefEqEtaAxiom "h" aliasFn)

def psCKernelDefEqEtaOf (fn : PsCKernelExpr) : PsCKernelExpr :=
  PsCKernelExpr.lam
    (psCKernelDefEqEtaName "x")
    (psCKernelDefEqEtaConst "A")
    (PsCKernelExpr.app fn (PsCKernelExpr.bvar 0))
    PsCKernelBinderInfo.default

def psCKernelDefEqEtaTestForward : Bool :=
  psCKernelIsDefEq
    psCKernelDefEqEtaEnv psCKernelLocalContextEmpty
    (psCKernelDefEqEtaOf (psCKernelDefEqEtaConst "f"))
    (psCKernelDefEqEtaConst "f")

def psCKernelDefEqEtaTestSymmetric : Bool :=
  psCKernelIsDefEq
    psCKernelDefEqEtaEnv psCKernelLocalContextEmpty
    (psCKernelDefEqEtaConst "f")
    (psCKernelDefEqEtaOf (psCKernelDefEqEtaConst "f"))

def psCKernelDefEqEtaTestReducibleType : Bool :=
  let etaH :=
    PsCKernelExpr.lam
      (psCKernelDefEqEtaName "x")
      (psCKernelDefEqEtaConst "A")
      (PsCKernelExpr.app
        (psCKernelDefEqEtaConst "h")
        (PsCKernelExpr.bvar 0))
      PsCKernelBinderInfo.default
  psCKernelIsDefEq
    psCKernelDefEqEtaEnv psCKernelLocalContextEmpty etaH
    (psCKernelDefEqEtaConst "h")

def psCKernelDefEqEtaTestDifferentFunction : Bool :=
  !(psCKernelIsDefEq
    psCKernelDefEqEtaEnv psCKernelLocalContextEmpty
    (psCKernelDefEqEtaOf (psCKernelDefEqEtaConst "g"))
    (psCKernelDefEqEtaConst "f"))

def psCKernelDefEqEtaTestNonFunction : Bool :=
  !(psCKernelIsDefEq
    psCKernelDefEqEtaEnv psCKernelLocalContextEmpty
    (psCKernelDefEqEtaOf (psCKernelDefEqEtaConst "f"))
    (psCKernelDefEqEtaConst "a"))

def psCKernelDefEqEtaTestBasicFunctionEquality : Bool :=
  psCKernelIsDefEq
    psCKernelDefEqEtaEnv psCKernelLocalContextEmpty
    (psCKernelDefEqEtaConst "f")
    (psCKernelDefEqEtaConst "f")

def psCKernelDefEqEtaTests : List PsCKernelDefEqEtaNamedTest := [
  { name := "lambda eta contracts to function", passed := psCKernelDefEqEtaTestForward },
  { name := "function eta equality is symmetric", passed := psCKernelDefEqEtaTestSymmetric },
  { name := "eta sees through reducible function types", passed := psCKernelDefEqEtaTestReducibleType },
  { name := "eta does not equate different functions", passed := psCKernelDefEqEtaTestDifferentFunction },
  { name := "eta probe on a non-function fails closed", passed := psCKernelDefEqEtaTestNonFunction },
  { name := "full defeq preserves ordinary function reflexivity", passed := psCKernelDefEqEtaTestBasicFunctionEquality }
]

def psCKernelRunDefEqEtaTests
    (tests : List PsCKernelDefEqEtaNamedTest) : IO Bool :=
  match tests with
  | [] => pure true
  | test :: rest => do
      if test.passed then
        IO.println ("PSCKERNEL_DEFEQ_ETA_PASS: " ++ test.name)
      else
        IO.println ("PSCKERNEL_DEFEQ_ETA_FAIL: " ++ test.name)
      let restPassed ← psCKernelRunDefEqEtaTests rest
      pure (test.passed && restPassed)

def main : IO Unit := do
  let passed ← psCKernelRunDefEqEtaTests psCKernelDefEqEtaTests
  if passed then
    IO.println "PSCKERNEL_DEFEQ_ETA_TESTS: PASS"
  else
    throw (IO.userError "PSCKERNEL_DEFEQ_ETA_TESTS: FAIL")
