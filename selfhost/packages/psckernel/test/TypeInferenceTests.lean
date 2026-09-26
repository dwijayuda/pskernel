import Ps.PSCKernel.Core.TypeInference

structure PsCKernelTypeInferenceNamedTest where
  name : String
  passed : Bool

def psCKernelTypeInferenceName (text : String) : PsCKernelName :=
  psCKernelNameFromDotted text

def psCKernelTypeInferenceConst (text : String) : PsCKernelExpr :=
  PsCKernelExpr.constE (psCKernelTypeInferenceName text) []

def psCKernelTypeInferenceAxiom
    (name : String)
    (declType : PsCKernelExpr) : PsCKernelConstantInfo :=
  PsCKernelConstantInfo.axiomInfo {
    base := {
      name := psCKernelTypeInferenceName name
      levelParams := []
      declType := declType
    }
    isUnsafe := false
  }

def psCKernelTypeInferenceAdd
    (env : PsCKernelEnvironment)
    (info : PsCKernelConstantInfo) : PsCKernelEnvironment :=
  match psCKernelEnvironmentTryAdd env info with
  | none => env
  | some next => next

def psCKernelTypeInferenceEnv : PsCKernelEnvironment :=
  let sort0 := PsCKernelExpr.sortE psCKernelLevelZero
  let aType := psCKernelTypeInferenceConst "A"
  let bType := psCKernelTypeInferenceConst "B"
  let pType := PsCKernelExpr.forallE
    (psCKernelTypeInferenceName "x") aType sort0 PsCKernelBinderInfo.default
  let pOfX := PsCKernelExpr.app (psCKernelTypeInferenceConst "P") (PsCKernelExpr.bvar 0)
  let gType := PsCKernelExpr.forallE
    (psCKernelTypeInferenceName "x") aType pOfX PsCKernelBinderInfo.default
  let env0 := psCKernelTypeInferenceAdd
    psCKernelEnvironmentEmpty (psCKernelTypeInferenceAxiom "A" sort0)
  let env1 := psCKernelTypeInferenceAdd
    env0 (psCKernelTypeInferenceAxiom "a" aType)
  let env2 := psCKernelTypeInferenceAdd
    env1 (psCKernelTypeInferenceAxiom "B" sort0)
  let env3 := psCKernelTypeInferenceAdd
    env2 (psCKernelTypeInferenceAxiom "b" bType)
  let env4 := psCKernelTypeInferenceAdd
    env3 (psCKernelTypeInferenceAxiom "P" pType)
  psCKernelTypeInferenceAdd env4 (psCKernelTypeInferenceAxiom "g" gType)

def psCKernelTypeInferenceEqOption
    (actual : Option PsCKernelExpr)
    (expected : Option PsCKernelExpr) : Bool :=
  match actual, expected with
  | none, none => true
  | some left, some right => psCKernelExprEqStructural left right
  | _, _ => false

def psCKernelTypeInferenceTestIdentityLambda : Bool :=
  let aType := psCKernelTypeInferenceConst "A"
  let expr := PsCKernelExpr.lam
    (psCKernelTypeInferenceName "x") aType (PsCKernelExpr.bvar 0)
    PsCKernelBinderInfo.default
  let expected := PsCKernelExpr.forallE
    (psCKernelTypeInferenceName "x") aType aType PsCKernelBinderInfo.default
  psCKernelTypeInferenceEqOption
    (psCKernelInfer? psCKernelTypeInferenceEnv psCKernelLocalContextEmpty expr)
    (some expected)

def psCKernelTypeInferenceTestLambdaSkipsDomainValidation : Bool :=
  let badDomain := psCKernelTypeInferenceConst "a"
  let expr := PsCKernelExpr.lam
    (psCKernelTypeInferenceName "x") badDomain (PsCKernelExpr.bvar 0)
    PsCKernelBinderInfo.default
  let expected := PsCKernelExpr.forallE
    (psCKernelTypeInferenceName "x") badDomain badDomain PsCKernelBinderInfo.default
  psCKernelTypeInferenceEqOption
    (psCKernelInfer? psCKernelTypeInferenceEnv psCKernelLocalContextEmpty expr)
    (some expected)

def psCKernelTypeInferenceTestNestedLambda : Bool :=
  let aType := psCKernelTypeInferenceConst "A"
  let bType := psCKernelTypeInferenceConst "B"
  let expr := PsCKernelExpr.lam
    (psCKernelTypeInferenceName "x") aType
    (PsCKernelExpr.lam
      (psCKernelTypeInferenceName "y") bType
      (PsCKernelExpr.bvar 1)
      PsCKernelBinderInfo.default)
    PsCKernelBinderInfo.default
  let expected := PsCKernelExpr.forallE
    (psCKernelTypeInferenceName "x") aType
    (PsCKernelExpr.forallE
      (psCKernelTypeInferenceName "y") bType aType PsCKernelBinderInfo.default)
    PsCKernelBinderInfo.default
  psCKernelTypeInferenceEqOption
    (psCKernelInfer? psCKernelTypeInferenceEnv psCKernelLocalContextEmpty expr)
    (some expected)

def psCKernelTypeInferenceTestDependentLambda : Bool :=
  let aType := psCKernelTypeInferenceConst "A"
  let pOfX := PsCKernelExpr.app (psCKernelTypeInferenceConst "P") (PsCKernelExpr.bvar 0)
  let expr := PsCKernelExpr.lam
    (psCKernelTypeInferenceName "x") aType
    (PsCKernelExpr.app (psCKernelTypeInferenceConst "g") (PsCKernelExpr.bvar 0))
    PsCKernelBinderInfo.default
  let expected := PsCKernelExpr.forallE
    (psCKernelTypeInferenceName "x") aType pOfX PsCKernelBinderInfo.default
  psCKernelTypeInferenceEqOption
    (psCKernelInfer? psCKernelTypeInferenceEnv psCKernelLocalContextEmpty expr)
    (some expected)

def psCKernelTypeInferenceTestPiImpredicativeProp : Bool :=
  let sort0 := PsCKernelExpr.sortE psCKernelLevelZero
  let expr := PsCKernelExpr.forallE
    (psCKernelTypeInferenceName "p") sort0 (PsCKernelExpr.bvar 0)
    PsCKernelBinderInfo.default
  psCKernelTypeInferenceEqOption
    (psCKernelInfer? psCKernelTypeInferenceEnv psCKernelLocalContextEmpty expr)
    (some sort0)

def psCKernelTypeInferenceTestPiTypeLevel : Bool :=
  let sort0 := PsCKernelExpr.sortE psCKernelLevelZero
  let sort1 := PsCKernelExpr.sortE (psCKernelLevelSucc psCKernelLevelZero)
  let expr := PsCKernelExpr.forallE
    (psCKernelTypeInferenceName "p") sort0 sort0 PsCKernelBinderInfo.default
  psCKernelTypeInferenceEqOption
    (psCKernelInfer? psCKernelTypeInferenceEnv psCKernelLocalContextEmpty expr)
    (some sort1)

def psCKernelTypeInferenceTestPiRejectsNonSortDomain : Bool :=
  let expr := PsCKernelExpr.forallE
    (psCKernelTypeInferenceName "x")
    (psCKernelTypeInferenceConst "a")
    (psCKernelTypeInferenceConst "A")
    PsCKernelBinderInfo.default
  psCKernelTypeInferenceEqOption
    (psCKernelInfer? psCKernelTypeInferenceEnv psCKernelLocalContextEmpty expr)
    none

def psCKernelTypeInferenceTestDependentLetClosesResult : Bool :=
  let aType := psCKernelTypeInferenceConst "A"
  let pOfX := PsCKernelExpr.app (psCKernelTypeInferenceConst "P") (PsCKernelExpr.bvar 0)
  let expr := PsCKernelExpr.letE
    (psCKernelTypeInferenceName "x") aType
    (psCKernelTypeInferenceConst "a")
    (PsCKernelExpr.app (psCKernelTypeInferenceConst "g") (PsCKernelExpr.bvar 0))
    false
  let expected := PsCKernelExpr.letE
    (psCKernelTypeInferenceName "x") aType
    (psCKernelTypeInferenceConst "a") pOfX false
  psCKernelTypeInferenceEqOption
    (psCKernelInfer? psCKernelTypeInferenceEnv psCKernelLocalContextEmpty expr)
    (some expected)

def psCKernelTypeInferenceTestNondependentLetDropsBinder : Bool :=
  let expr := PsCKernelExpr.letE
    (psCKernelTypeInferenceName "x")
    (psCKernelTypeInferenceConst "A")
    (psCKernelTypeInferenceConst "a")
    (psCKernelTypeInferenceConst "b")
    false
  psCKernelTypeInferenceEqOption
    (psCKernelInfer? psCKernelTypeInferenceEnv psCKernelLocalContextEmpty expr)
    (some (psCKernelTypeInferenceConst "B"))

def psCKernelTypeInferenceTestLambdaApplication : Bool :=
  let aType := psCKernelTypeInferenceConst "A"
  let lambda := PsCKernelExpr.lam
    (psCKernelTypeInferenceName "x") aType (PsCKernelExpr.bvar 0)
    PsCKernelBinderInfo.default
  let expr := PsCKernelExpr.app lambda (psCKernelTypeInferenceConst "a")
  psCKernelTypeInferenceEqOption
    (psCKernelInfer? psCKernelTypeInferenceEnv psCKernelLocalContextEmpty expr)
    (some aType)

def psCKernelTypeInferenceTests : List PsCKernelTypeInferenceNamedTest := [
  { name := "identity lambda infers Pi type", passed := psCKernelTypeInferenceTestIdentityLambda },
  { name := "infer-only lambda skips domain validation", passed := psCKernelTypeInferenceTestLambdaSkipsDomainValidation },
  { name := "nested lambda closes both binders", passed := psCKernelTypeInferenceTestNestedLambda },
  { name := "dependent lambda abstracts result type", passed := psCKernelTypeInferenceTestDependentLambda },
  { name := "Pi inference preserves Prop impredicativity", passed := psCKernelTypeInferenceTestPiImpredicativeProp },
  { name := "Pi inference computes imax universe", passed := psCKernelTypeInferenceTestPiTypeLevel },
  { name := "Pi inference rejects non-sort domain", passed := psCKernelTypeInferenceTestPiRejectsNonSortDomain },
  { name := "dependent let closes result with let binder", passed := psCKernelTypeInferenceTestDependentLetClosesResult },
  { name := "nondependent let drops unused binder", passed := psCKernelTypeInferenceTestNondependentLetDropsBinder },
  { name := "application can infer a lambda head", passed := psCKernelTypeInferenceTestLambdaApplication }
]

def psCKernelRunTypeInferenceTests
    (tests : List PsCKernelTypeInferenceNamedTest) : IO Bool :=
  match tests with
  | [] => pure true
  | test :: rest => do
      if test.passed then
        IO.println ("PSCKERNEL_TYPE_INFERENCE_PASS: " ++ test.name)
      else
        IO.println ("PSCKERNEL_TYPE_INFERENCE_FAIL: " ++ test.name)
      let restPassed ← psCKernelRunTypeInferenceTests rest
      pure (test.passed && restPassed)

def main : IO Unit := do
  let passed ← psCKernelRunTypeInferenceTests psCKernelTypeInferenceTests
  if passed then
    IO.println "PSCKERNEL_TYPE_INFERENCE_TESTS: PASS"
  else
    throw (IO.userError "PSCKERNEL_TYPE_INFERENCE_TESTS: FAIL")
