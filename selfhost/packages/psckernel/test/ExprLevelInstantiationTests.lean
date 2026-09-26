import Ps.PSCKernel.Core.Expr

structure PsCKernelExprLevelInstantiationNamedTest where
  name : String
  passed : Bool

def psCKernelExprLevelInstantiationNameU : PsCKernelName :=
  psCKernelNameFromDotted "u"

def psCKernelExprLevelInstantiationNameV : PsCKernelName :=
  psCKernelNameFromDotted "v"

def psCKernelExprLevelInstantiationNameC : PsCKernelName :=
  psCKernelNameFromDotted "C"

def psCKernelExprLevelInstantiationNameF : PsCKernelName :=
  psCKernelNameFromDotted "f"

def psCKernelExprLevelInstantiationNameP : PsCKernelName :=
  psCKernelNameFromDotted "P"

def psCKernelExprLevelInstantiationNameX : PsCKernelName :=
  psCKernelNameFromDotted "x"

def psCKernelExprLevelInstantiationU : PsCKernelLevel :=
  psCKernelLevelParam psCKernelExprLevelInstantiationNameU

def psCKernelExprLevelInstantiationV : PsCKernelLevel :=
  psCKernelLevelParam psCKernelExprLevelInstantiationNameV

def psCKernelExprLevelInstantiationTestEmptyParams : Bool :=
  let input : PsCKernelExpr :=
    PsCKernelExpr.sortE psCKernelExprLevelInstantiationU
  psCKernelExprEqStructural
    (psCKernelInstantiateExprLevels input [] [])
    input

def psCKernelExprLevelInstantiationTestSort : Bool :=
  let input : PsCKernelExpr :=
    PsCKernelExpr.sortE (psCKernelLevelSucc psCKernelExprLevelInstantiationU)
  let expected : PsCKernelExpr :=
    PsCKernelExpr.sortE (psCKernelLevelSucc psCKernelLevelZero)
  psCKernelExprEqStructural
    (psCKernelInstantiateExprLevels
      input
      [psCKernelExprLevelInstantiationNameU]
      [psCKernelLevelZero])
    expected

def psCKernelExprLevelInstantiationTestConstLevels : Bool :=
  let input : PsCKernelExpr :=
    PsCKernelExpr.constE
      psCKernelExprLevelInstantiationNameC
      [psCKernelExprLevelInstantiationU, psCKernelExprLevelInstantiationV]
  let expected : PsCKernelExpr :=
    PsCKernelExpr.constE
      psCKernelExprLevelInstantiationNameC
      [psCKernelLevelZero, psCKernelLevelSucc psCKernelLevelZero]
  psCKernelExprEqStructural
    (psCKernelInstantiateExprLevels
      input
      [psCKernelExprLevelInstantiationNameU, psCKernelExprLevelInstantiationNameV]
      [psCKernelLevelZero, psCKernelLevelSucc psCKernelLevelZero])
    expected

def psCKernelExprLevelInstantiationTestNestedTraversal : Bool :=
  let input : PsCKernelExpr :=
    PsCKernelExpr.letE
      psCKernelExprLevelInstantiationNameX
      (PsCKernelExpr.sortE psCKernelExprLevelInstantiationU)
      (PsCKernelExpr.constE
        psCKernelExprLevelInstantiationNameC
        [psCKernelExprLevelInstantiationU])
      (PsCKernelExpr.proj
        psCKernelExprLevelInstantiationNameP
        0
        (PsCKernelExpr.app
          (PsCKernelExpr.constE
            psCKernelExprLevelInstantiationNameF
            [psCKernelExprLevelInstantiationU])
          (PsCKernelExpr.sortE psCKernelExprLevelInstantiationV)))
      true
  let expected : PsCKernelExpr :=
    PsCKernelExpr.letE
      psCKernelExprLevelInstantiationNameX
      (PsCKernelExpr.sortE psCKernelLevelZero)
      (PsCKernelExpr.constE
        psCKernelExprLevelInstantiationNameC
        [psCKernelLevelZero])
      (PsCKernelExpr.proj
        psCKernelExprLevelInstantiationNameP
        0
        (PsCKernelExpr.app
          (PsCKernelExpr.constE
            psCKernelExprLevelInstantiationNameF
            [psCKernelLevelZero])
          (PsCKernelExpr.sortE psCKernelExprLevelInstantiationV)))
      true
  psCKernelExprEqStructural
    (psCKernelInstantiateExprLevels
      input
      [psCKernelExprLevelInstantiationNameU]
      [psCKernelLevelZero])
    expected

def psCKernelExprLevelInstantiationTestBinderTraversal : Bool :=
  let input : PsCKernelExpr :=
    PsCKernelExpr.forallE
      psCKernelExprLevelInstantiationNameX
      (PsCKernelExpr.sortE psCKernelExprLevelInstantiationU)
      (PsCKernelExpr.lam
        psCKernelExprLevelInstantiationNameX
        (PsCKernelExpr.sortE psCKernelExprLevelInstantiationV)
        (PsCKernelExpr.constE
          psCKernelExprLevelInstantiationNameC
          [psCKernelExprLevelInstantiationU])
        PsCKernelBinderInfo.implicit)
      PsCKernelBinderInfo.default
  let expected : PsCKernelExpr :=
    PsCKernelExpr.forallE
      psCKernelExprLevelInstantiationNameX
      (PsCKernelExpr.sortE psCKernelLevelZero)
      (PsCKernelExpr.lam
        psCKernelExprLevelInstantiationNameX
        (PsCKernelExpr.sortE psCKernelExprLevelInstantiationV)
        (PsCKernelExpr.constE
          psCKernelExprLevelInstantiationNameC
          [psCKernelLevelZero])
        PsCKernelBinderInfo.implicit)
      PsCKernelBinderInfo.default
  psCKernelExprEqStructural
    (psCKernelInstantiateExprLevels
      input
      [psCKernelExprLevelInstantiationNameU]
      [psCKernelLevelZero])
    expected

def psCKernelExprLevelInstantiationTestMissingParamPreservesShape : Bool :=
  let input : PsCKernelExpr :=
    PsCKernelExpr.constE
      psCKernelExprLevelInstantiationNameC
      [psCKernelExprLevelInstantiationV]
  psCKernelExprEqStructural
    (psCKernelInstantiateExprLevels
      input
      [psCKernelExprLevelInstantiationNameU]
      [psCKernelLevelZero])
    input

def psCKernelExprLevelInstantiationTestFirstDuplicateWins : Bool :=
  let input : PsCKernelExpr :=
    PsCKernelExpr.sortE psCKernelExprLevelInstantiationU
  let expected : PsCKernelExpr :=
    PsCKernelExpr.sortE psCKernelLevelZero
  psCKernelExprEqStructural
    (psCKernelInstantiateExprLevels
      input
      [psCKernelExprLevelInstantiationNameU, psCKernelExprLevelInstantiationNameU]
      [psCKernelLevelZero, psCKernelLevelSucc psCKernelLevelZero])
    expected

def psCKernelExprLevelInstantiationTests : List PsCKernelExprLevelInstantiationNamedTest := [
  { name := "empty params preserve expression", passed := psCKernelExprLevelInstantiationTestEmptyParams },
  { name := "sort levels instantiate", passed := psCKernelExprLevelInstantiationTestSort },
  { name := "constant universe lists instantiate", passed := psCKernelExprLevelInstantiationTestConstLevels },
  { name := "let app projection traversal", passed := psCKernelExprLevelInstantiationTestNestedTraversal },
  { name := "forall and lambda traversal", passed := psCKernelExprLevelInstantiationTestBinderTraversal },
  { name := "missing parameter preserves shape", passed := psCKernelExprLevelInstantiationTestMissingParamPreservesShape },
  { name := "first duplicate parameter wins", passed := psCKernelExprLevelInstantiationTestFirstDuplicateWins }
]

def psCKernelRunExprLevelInstantiationTests
    (tests : List PsCKernelExprLevelInstantiationNamedTest) : IO Bool :=
  match tests with
  | [] => pure true
  | test :: rest => do
      if test.passed then
        IO.println ("PSCKERNEL_EXPR_LEVEL_INSTANTIATION_PASS: " ++ test.name)
      else
        IO.println ("PSCKERNEL_EXPR_LEVEL_INSTANTIATION_FAIL: " ++ test.name)
      let restPassed ← psCKernelRunExprLevelInstantiationTests rest
      pure (test.passed && restPassed)

def main : IO Unit := do
  let passed ←
    psCKernelRunExprLevelInstantiationTests psCKernelExprLevelInstantiationTests
  if passed then
    IO.println "PSCKERNEL_EXPR_LEVEL_INSTANTIATION_TESTS: PASS"
  else
    throw (IO.userError "PSCKERNEL_EXPR_LEVEL_INSTANTIATION_TESTS: FAIL")
