import Ps.PSCKernel.Core.ExprInstantiation

structure PsCKernelExprInstantiationNamedTest where
  name : String
  passed : Bool

def psCKernelExprInstantiationNameX : PsCKernelName :=
  psCKernelNameFromDotted "x"

def psCKernelExprInstantiationNameP : PsCKernelName :=
  psCKernelNameFromDotted "P"

def psCKernelExprInstantiationConst (name : String) : PsCKernelExpr :=
  PsCKernelExpr.constE (psCKernelNameFromDotted name) []

def psCKernelExprInstantiationTestLiftZero : Bool :=
  let input : PsCKernelExpr := PsCKernelExpr.bvar 2
  psCKernelExprEqStructural
    (psCKernelExprLiftLooseBVars input 0 0)
    input

def psCKernelExprInstantiationTestLiftCutoff : Bool :=
  let input : PsCKernelExpr :=
    PsCKernelExpr.app (PsCKernelExpr.bvar 0) (PsCKernelExpr.bvar 1)
  let expected : PsCKernelExpr :=
    PsCKernelExpr.app (PsCKernelExpr.bvar 0) (PsCKernelExpr.bvar 3)
  psCKernelExprEqStructural
    (psCKernelExprLiftLooseBVars input 1 2)
    expected

def psCKernelExprInstantiationTestLiftBinderDepth : Bool :=
  let input : PsCKernelExpr :=
    PsCKernelExpr.lam
      psCKernelExprInstantiationNameX
      (PsCKernelExpr.bvar 0)
      (PsCKernelExpr.app (PsCKernelExpr.bvar 0) (PsCKernelExpr.bvar 1))
      PsCKernelBinderInfo.default
  let expected : PsCKernelExpr :=
    PsCKernelExpr.lam
      psCKernelExprInstantiationNameX
      (PsCKernelExpr.bvar 1)
      (PsCKernelExpr.app (PsCKernelExpr.bvar 0) (PsCKernelExpr.bvar 2))
      PsCKernelBinderInfo.default
  psCKernelExprEqStructural
    (psCKernelExprLiftLooseBVars input 0 1)
    expected

def psCKernelExprInstantiationTestEmpty : Bool :=
  let input : PsCKernelExpr :=
    PsCKernelExpr.app (PsCKernelExpr.bvar 0) (PsCKernelExpr.bvar 2)
  psCKernelExprEqStructural
    (psCKernelExprInstantiate input [])
    input

def psCKernelExprInstantiationTestSingle : Bool :=
  let input : PsCKernelExpr :=
    PsCKernelExpr.app (PsCKernelExpr.bvar 0) (PsCKernelExpr.bvar 1)
  let expected : PsCKernelExpr :=
    PsCKernelExpr.app
      (psCKernelExprInstantiationConst "A")
      (PsCKernelExpr.bvar 0)
  psCKernelExprEqStructural
    (psCKernelExprInstantiate1 input (psCKernelExprInstantiationConst "A"))
    expected

def psCKernelExprInstantiationTestOrderAndShift : Bool :=
  let input : PsCKernelExpr :=
    PsCKernelExpr.app
      (PsCKernelExpr.app (PsCKernelExpr.bvar 0) (PsCKernelExpr.bvar 1))
      (PsCKernelExpr.bvar 2)
  let expected : PsCKernelExpr :=
    PsCKernelExpr.app
      (PsCKernelExpr.app
        (psCKernelExprInstantiationConst "A")
        (psCKernelExprInstantiationConst "B"))
      (PsCKernelExpr.bvar 0)
  psCKernelExprEqStructural
    (psCKernelExprInstantiate
      input
      [psCKernelExprInstantiationConst "A", psCKernelExprInstantiationConst "B"])
    expected

def psCKernelExprInstantiationTestSubstitutionLiftedUnderBinder : Bool :=
  let input : PsCKernelExpr :=
    PsCKernelExpr.lam
      psCKernelExprInstantiationNameX
      (psCKernelExprInstantiationConst "T")
      (PsCKernelExpr.app (PsCKernelExpr.bvar 0) (PsCKernelExpr.bvar 1))
      PsCKernelBinderInfo.default
  let expected : PsCKernelExpr :=
    PsCKernelExpr.lam
      psCKernelExprInstantiationNameX
      (psCKernelExprInstantiationConst "T")
      (PsCKernelExpr.app (PsCKernelExpr.bvar 0) (PsCKernelExpr.bvar 1))
      PsCKernelBinderInfo.default
  psCKernelExprEqStructural
    (psCKernelExprInstantiate input [PsCKernelExpr.bvar 0])
    expected

def psCKernelExprInstantiationTestBinderTypeAndBody : Bool :=
  let input : PsCKernelExpr :=
    PsCKernelExpr.forallE
      psCKernelExprInstantiationNameX
      (PsCKernelExpr.bvar 0)
      (PsCKernelExpr.app (PsCKernelExpr.bvar 0) (PsCKernelExpr.bvar 1))
      PsCKernelBinderInfo.implicit
  let expected : PsCKernelExpr :=
    PsCKernelExpr.forallE
      psCKernelExprInstantiationNameX
      (psCKernelExprInstantiationConst "A")
      (PsCKernelExpr.app
        (PsCKernelExpr.bvar 0)
        (psCKernelExprInstantiationConst "A"))
      PsCKernelBinderInfo.implicit
  psCKernelExprEqStructural
    (psCKernelExprInstantiate input [psCKernelExprInstantiationConst "A"])
    expected

def psCKernelExprInstantiationTestLetDepth : Bool :=
  let input : PsCKernelExpr :=
    PsCKernelExpr.letE
      psCKernelExprInstantiationNameX
      (PsCKernelExpr.bvar 0)
      (PsCKernelExpr.bvar 0)
      (PsCKernelExpr.app (PsCKernelExpr.bvar 0) (PsCKernelExpr.bvar 1))
      true
  let expected : PsCKernelExpr :=
    PsCKernelExpr.letE
      psCKernelExprInstantiationNameX
      (psCKernelExprInstantiationConst "A")
      (psCKernelExprInstantiationConst "A")
      (PsCKernelExpr.app
        (PsCKernelExpr.bvar 0)
        (psCKernelExprInstantiationConst "A"))
      true
  psCKernelExprEqStructural
    (psCKernelExprInstantiate input [psCKernelExprInstantiationConst "A"])
    expected

def psCKernelExprInstantiationTestProjectionTraversal : Bool :=
  let input : PsCKernelExpr :=
    PsCKernelExpr.proj
      psCKernelExprInstantiationNameP
      2
      (PsCKernelExpr.app (PsCKernelExpr.bvar 0) (PsCKernelExpr.bvar 1))
  let expected : PsCKernelExpr :=
    PsCKernelExpr.proj
      psCKernelExprInstantiationNameP
      2
      (PsCKernelExpr.app
        (psCKernelExprInstantiationConst "A")
        (PsCKernelExpr.bvar 0))
  psCKernelExprEqStructural
    (psCKernelExprInstantiate1 input (psCKernelExprInstantiationConst "A"))
    expected

def psCKernelExprInstantiationTests : List PsCKernelExprInstantiationNamedTest := [
  { name := "lift amount zero preserves expression", passed := psCKernelExprInstantiationTestLiftZero },
  { name := "lift respects cutoff", passed := psCKernelExprInstantiationTestLiftCutoff },
  { name := "lift accounts for binder depth", passed := psCKernelExprInstantiationTestLiftBinderDepth },
  { name := "empty substitution preserves expression", passed := psCKernelExprInstantiationTestEmpty },
  { name := "instantiate1 replaces zero and shifts higher variables", passed := psCKernelExprInstantiationTestSingle },
  { name := "multi substitution preserves index order and shifts tail", passed := psCKernelExprInstantiationTestOrderAndShift },
  { name := "substitution loose variables are lifted under binders", passed := psCKernelExprInstantiationTestSubstitutionLiftedUnderBinder },
  { name := "binder type and body use different depths", passed := psCKernelExprInstantiationTestBinderTypeAndBody },
  { name := "let type and value stay outside body binder", passed := psCKernelExprInstantiationTestLetDepth },
  { name := "projection traversal instantiates inner expression", passed := psCKernelExprInstantiationTestProjectionTraversal }
]

def psCKernelRunExprInstantiationTests
    (tests : List PsCKernelExprInstantiationNamedTest) : IO Bool :=
  match tests with
  | [] => pure true
  | test :: rest => do
      if test.passed then
        IO.println ("PSCKERNEL_EXPR_INSTANTIATION_PASS: " ++ test.name)
      else
        IO.println ("PSCKERNEL_EXPR_INSTANTIATION_FAIL: " ++ test.name)
      let restPassed ← psCKernelRunExprInstantiationTests rest
      pure (test.passed && restPassed)

def main : IO Unit := do
  let passed ← psCKernelRunExprInstantiationTests psCKernelExprInstantiationTests
  if passed then
    IO.println "PSCKERNEL_EXPR_INSTANTIATION_TESTS: PASS"
  else
    throw (IO.userError "PSCKERNEL_EXPR_INSTANTIATION_TESTS: FAIL")
