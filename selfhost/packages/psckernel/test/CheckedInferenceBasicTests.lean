import Ps.PSCKernel.Core.CheckedInferenceBasic

structure PsCKernelCheckedInferenceBasicNamedTest where
  name : String
  passed : Bool

def psCKernelCheckedInferenceBasicName (text : String) : PsCKernelName :=
  psCKernelNameFromDotted text

def psCKernelCheckedInferenceBasicConst (text : String) : PsCKernelExpr :=
  PsCKernelExpr.constE (psCKernelCheckedInferenceBasicName text) []

def psCKernelCheckedInferenceBasicAxiom
    (name : String)
    (declType : PsCKernelExpr) : PsCKernelConstantInfo :=
  PsCKernelConstantInfo.axiomInfo {
    base := {
      name := psCKernelCheckedInferenceBasicName name
      levelParams := []
      declType := declType
    }
    isUnsafe := false
  }

def psCKernelCheckedInferenceBasicDefinition
    (name : String)
    (declType : PsCKernelExpr)
    (value : PsCKernelExpr) : PsCKernelConstantInfo :=
  PsCKernelConstantInfo.defnInfo {
    base := {
      name := psCKernelCheckedInferenceBasicName name
      levelParams := []
      declType := declType
    }
    value := value
    hints := PsCKernelReducibilityHints.regular 0
    safety := PsCKernelDefinitionSafety.safe
    all := []
  }

def psCKernelCheckedInferenceBasicAdd
    (env : PsCKernelEnvironment)
    (info : PsCKernelConstantInfo) : PsCKernelEnvironment :=
  match psCKernelEnvironmentTryAdd env info with
  | none => env
  | some next => next

def psCKernelCheckedInferenceBasicEnv : PsCKernelEnvironment :=
  let sort0 := PsCKernelExpr.sortE psCKernelLevelZero
  let aType := psCKernelCheckedInferenceBasicConst "A"
  let bType := psCKernelCheckedInferenceBasicConst "B"
  let aliasType := psCKernelCheckedInferenceBasicConst "AliasType"
  let fType := PsCKernelExpr.forallE
    (psCKernelCheckedInferenceBasicName "x") aType aType PsCKernelBinderInfo.default
  let env0 := psCKernelCheckedInferenceBasicAdd
    psCKernelEnvironmentEmpty
    (psCKernelCheckedInferenceBasicAxiom "A" sort0)
  let env1 := psCKernelCheckedInferenceBasicAdd
    env0 (psCKernelCheckedInferenceBasicAxiom "a" aType)
  let env2 := psCKernelCheckedInferenceBasicAdd
    env1 (psCKernelCheckedInferenceBasicAxiom "B" sort0)
  let env3 := psCKernelCheckedInferenceBasicAdd
    env2 (psCKernelCheckedInferenceBasicAxiom "b" bType)
  let env4 := psCKernelCheckedInferenceBasicAdd
    env3 (psCKernelCheckedInferenceBasicDefinition "AliasType" sort0 aType)
  let env5 := psCKernelCheckedInferenceBasicAdd
    env4 (psCKernelCheckedInferenceBasicAxiom "aa" aliasType)
  psCKernelCheckedInferenceBasicAdd
    env5 (psCKernelCheckedInferenceBasicAxiom "f" fType)

def psCKernelCheckedInferenceBasicEqOption
    (actual : Option PsCKernelExpr)
    (expected : Option PsCKernelExpr) : Bool :=
  match actual, expected with
  | none, none => true
  | some left, some right => psCKernelExprEqStructural left right
  | _, _ => false

def psCKernelCheckedInferenceBasicTestSort : Bool :=
  psCKernelCheckedInferenceBasicEqOption
    (psCKernelCheckBasic?
      psCKernelCheckedInferenceBasicEnv psCKernelLocalContextEmpty
      (PsCKernelExpr.sortE psCKernelLevelZero))
    (some (PsCKernelExpr.sortE (psCKernelLevelSucc psCKernelLevelZero)))

def psCKernelCheckedInferenceBasicTestConst : Bool :=
  psCKernelCheckedInferenceBasicEqOption
    (psCKernelCheckBasic?
      psCKernelCheckedInferenceBasicEnv psCKernelLocalContextEmpty
      (psCKernelCheckedInferenceBasicConst "a"))
    (some (psCKernelCheckedInferenceBasicConst "A"))

def psCKernelCheckedInferenceBasicTestValidApp : Bool :=
  let expr := PsCKernelExpr.app
    (psCKernelCheckedInferenceBasicConst "f")
    (psCKernelCheckedInferenceBasicConst "a")
  psCKernelCheckedInferenceBasicEqOption
    (psCKernelCheckBasic?
      psCKernelCheckedInferenceBasicEnv psCKernelLocalContextEmpty expr)
    (some (psCKernelCheckedInferenceBasicConst "A"))

def psCKernelCheckedInferenceBasicTestDefEqApp : Bool :=
  let expr := PsCKernelExpr.app
    (psCKernelCheckedInferenceBasicConst "f")
    (psCKernelCheckedInferenceBasicConst "aa")
  psCKernelCheckedInferenceBasicEqOption
    (psCKernelCheckBasic?
      psCKernelCheckedInferenceBasicEnv psCKernelLocalContextEmpty expr)
    (some (psCKernelCheckedInferenceBasicConst "A"))

def psCKernelCheckedInferenceBasicTestBadApp : Bool :=
  let expr := PsCKernelExpr.app
    (psCKernelCheckedInferenceBasicConst "f")
    (psCKernelCheckedInferenceBasicConst "b")
  psCKernelCheckedInferenceBasicEqOption
    (psCKernelCheckBasic?
      psCKernelCheckedInferenceBasicEnv psCKernelLocalContextEmpty expr)
    none

def psCKernelCheckedInferenceBasicTestValidLambda : Bool :=
  let aType := psCKernelCheckedInferenceBasicConst "A"
  let expr := PsCKernelExpr.lam
    (psCKernelCheckedInferenceBasicName "x") aType (PsCKernelExpr.bvar 0)
    PsCKernelBinderInfo.default
  let expected := PsCKernelExpr.forallE
    (psCKernelCheckedInferenceBasicName "x") aType aType PsCKernelBinderInfo.default
  psCKernelCheckedInferenceBasicEqOption
    (psCKernelCheckBasic?
      psCKernelCheckedInferenceBasicEnv psCKernelLocalContextEmpty expr)
    (some expected)

def psCKernelCheckedInferenceBasicTestBadLambdaDomain : Bool :=
  let expr := PsCKernelExpr.lam
    (psCKernelCheckedInferenceBasicName "x")
    (psCKernelCheckedInferenceBasicConst "a")
    (PsCKernelExpr.bvar 0)
    PsCKernelBinderInfo.default
  psCKernelCheckedInferenceBasicEqOption
    (psCKernelCheckBasic?
      psCKernelCheckedInferenceBasicEnv psCKernelLocalContextEmpty expr)
    none

def psCKernelCheckedInferenceBasicTestValidPi : Bool :=
  let sort0 := PsCKernelExpr.sortE psCKernelLevelZero
  let expr := PsCKernelExpr.forallE
    (psCKernelCheckedInferenceBasicName "p") sort0 sort0 PsCKernelBinderInfo.default
  psCKernelCheckedInferenceBasicEqOption
    (psCKernelCheckBasic?
      psCKernelCheckedInferenceBasicEnv psCKernelLocalContextEmpty expr)
    (some (PsCKernelExpr.sortE (psCKernelLevelSucc psCKernelLevelZero)))

def psCKernelCheckedInferenceBasicTestBadPiDomain : Bool :=
  let expr := PsCKernelExpr.forallE
    (psCKernelCheckedInferenceBasicName "x")
    (psCKernelCheckedInferenceBasicConst "a")
    (psCKernelCheckedInferenceBasicConst "A")
    PsCKernelBinderInfo.default
  psCKernelCheckedInferenceBasicEqOption
    (psCKernelCheckBasic?
      psCKernelCheckedInferenceBasicEnv psCKernelLocalContextEmpty expr)
    none

def psCKernelCheckedInferenceBasicTestValidLet : Bool :=
  let aType := psCKernelCheckedInferenceBasicConst "A"
  let expr := PsCKernelExpr.letE
    (psCKernelCheckedInferenceBasicName "x") aType
    (psCKernelCheckedInferenceBasicConst "a")
    (PsCKernelExpr.bvar 0)
    false
  psCKernelCheckedInferenceBasicEqOption
    (psCKernelCheckBasic?
      psCKernelCheckedInferenceBasicEnv psCKernelLocalContextEmpty expr)
    (some aType)

def psCKernelCheckedInferenceBasicTestBadLetType : Bool :=
  let expr := PsCKernelExpr.letE
    (psCKernelCheckedInferenceBasicName "x")
    (psCKernelCheckedInferenceBasicConst "a")
    (psCKernelCheckedInferenceBasicConst "a")
    (PsCKernelExpr.bvar 0)
    false
  psCKernelCheckedInferenceBasicEqOption
    (psCKernelCheckBasic?
      psCKernelCheckedInferenceBasicEnv psCKernelLocalContextEmpty expr)
    none

def psCKernelCheckedInferenceBasicTestBadLetValue : Bool :=
  let aType := psCKernelCheckedInferenceBasicConst "A"
  let expr := PsCKernelExpr.letE
    (psCKernelCheckedInferenceBasicName "x") aType
    (psCKernelCheckedInferenceBasicConst "b")
    (PsCKernelExpr.bvar 0)
    false
  psCKernelCheckedInferenceBasicEqOption
    (psCKernelCheckBasic?
      psCKernelCheckedInferenceBasicEnv psCKernelLocalContextEmpty expr)
    none

def psCKernelCheckedInferenceBasicTestDefEqLetValue : Bool :=
  let aType := psCKernelCheckedInferenceBasicConst "A"
  let expr := PsCKernelExpr.letE
    (psCKernelCheckedInferenceBasicName "x") aType
    (psCKernelCheckedInferenceBasicConst "aa")
    (PsCKernelExpr.bvar 0)
    false
  psCKernelCheckedInferenceBasicEqOption
    (psCKernelCheckBasic?
      psCKernelCheckedInferenceBasicEnv psCKernelLocalContextEmpty expr)
    (some aType)

def psCKernelCheckedInferenceBasicTestUnknownConst : Bool :=
  psCKernelCheckedInferenceBasicEqOption
    (psCKernelCheckBasic?
      psCKernelCheckedInferenceBasicEnv psCKernelLocalContextEmpty
      (psCKernelCheckedInferenceBasicConst "missing"))
    none

def psCKernelCheckedInferenceBasicTests : List PsCKernelCheckedInferenceBasicNamedTest := [
  { name := "checked sort succeeds", passed := psCKernelCheckedInferenceBasicTestSort },
  { name := "checked known constant succeeds", passed := psCKernelCheckedInferenceBasicTestConst },
  { name := "checked application accepts exact argument type", passed := psCKernelCheckedInferenceBasicTestValidApp },
  { name := "checked application accepts definitionally equal type", passed := psCKernelCheckedInferenceBasicTestDefEqApp },
  { name := "checked application rejects mismatched type", passed := psCKernelCheckedInferenceBasicTestBadApp },
  { name := "checked lambda validates a proper domain", passed := psCKernelCheckedInferenceBasicTestValidLambda },
  { name := "checked lambda rejects non-sort domain", passed := psCKernelCheckedInferenceBasicTestBadLambdaDomain },
  { name := "checked Pi validates domain and body sorts", passed := psCKernelCheckedInferenceBasicTestValidPi },
  { name := "checked Pi rejects non-sort domain", passed := psCKernelCheckedInferenceBasicTestBadPiDomain },
  { name := "checked let accepts matching value", passed := psCKernelCheckedInferenceBasicTestValidLet },
  { name := "checked let rejects non-sort declared type", passed := psCKernelCheckedInferenceBasicTestBadLetType },
  { name := "checked let rejects mismatched value", passed := psCKernelCheckedInferenceBasicTestBadLetValue },
  { name := "checked let accepts definitionally equal value type", passed := psCKernelCheckedInferenceBasicTestDefEqLetValue },
  { name := "checked unknown constant fails closed", passed := psCKernelCheckedInferenceBasicTestUnknownConst }
]

def psCKernelRunCheckedInferenceBasicTests
    (tests : List PsCKernelCheckedInferenceBasicNamedTest) : IO Bool :=
  match tests with
  | [] => pure true
  | test :: rest => do
      if test.passed then
        IO.println ("PSCKERNEL_CHECKED_INFERENCE_BASIC_PASS: " ++ test.name)
      else
        IO.println ("PSCKERNEL_CHECKED_INFERENCE_BASIC_FAIL: " ++ test.name)
      let restPassed ← psCKernelRunCheckedInferenceBasicTests rest
      pure (test.passed && restPassed)

def main : IO Unit := do
  let passed ← psCKernelRunCheckedInferenceBasicTests psCKernelCheckedInferenceBasicTests
  if passed then
    IO.println "PSCKERNEL_CHECKED_INFERENCE_BASIC_TESTS: PASS"
  else
    throw (IO.userError "PSCKERNEL_CHECKED_INFERENCE_BASIC_TESTS: FAIL")
