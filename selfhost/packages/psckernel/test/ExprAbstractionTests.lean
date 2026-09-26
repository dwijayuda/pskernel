import Ps.PSCKernel.Core.ExprInstantiation

structure PsCKernelExprAbstractionNamedTest where
  name : String
  passed : Bool

def psCKernelExprAbstractionNameX : PsCKernelName :=
  psCKernelNameFromDotted "x"

def psCKernelExprAbstractionNameY : PsCKernelName :=
  psCKernelNameFromDotted "y"

def psCKernelExprAbstractionNameP : PsCKernelName :=
  psCKernelNameFromDotted "P"

def psCKernelExprAbstractionTarget : PsCKernelFVarId :=
  { name := psCKernelExprAbstractionNameX }

def psCKernelExprAbstractionOther : PsCKernelFVarId :=
  { name := psCKernelExprAbstractionNameY }

def psCKernelExprAbstractionConst (name : String) : PsCKernelExpr :=
  PsCKernelExpr.constE (psCKernelNameFromDotted name) []

def psCKernelExprAbstractionTestNonTarget : Bool :=
  let input : PsCKernelExpr := PsCKernelExpr.fvar psCKernelExprAbstractionOther
  psCKernelExprEqStructural
    (psCKernelExprAbstractFVar input psCKernelExprAbstractionTarget)
    input

def psCKernelExprAbstractionTestTargetAtRoot : Bool :=
  psCKernelExprEqStructural
    (psCKernelExprAbstractFVar
      (PsCKernelExpr.fvar psCKernelExprAbstractionTarget)
      psCKernelExprAbstractionTarget)
    (PsCKernelExpr.bvar 0)

def psCKernelExprAbstractionTestExistingLooseBVarShifts : Bool :=
  psCKernelExprEqStructural
    (psCKernelExprAbstractFVar
      (PsCKernelExpr.bvar 0)
      psCKernelExprAbstractionTarget)
    (PsCKernelExpr.bvar 1)

def psCKernelExprAbstractionTestApplication : Bool :=
  let input : PsCKernelExpr :=
    PsCKernelExpr.app
      (PsCKernelExpr.fvar psCKernelExprAbstractionTarget)
      (PsCKernelExpr.bvar 0)
  let expected : PsCKernelExpr :=
    PsCKernelExpr.app (PsCKernelExpr.bvar 0) (PsCKernelExpr.bvar 1)
  psCKernelExprEqStructural
    (psCKernelExprAbstractFVar input psCKernelExprAbstractionTarget)
    expected

def psCKernelExprAbstractionTestLambdaDepth : Bool :=
  let input : PsCKernelExpr :=
    PsCKernelExpr.lam
      psCKernelExprAbstractionNameY
      (psCKernelExprAbstractionConst "T")
      (PsCKernelExpr.app
        (PsCKernelExpr.fvar psCKernelExprAbstractionTarget)
        (PsCKernelExpr.bvar 0))
      PsCKernelBinderInfo.default
  let expected : PsCKernelExpr :=
    PsCKernelExpr.lam
      psCKernelExprAbstractionNameY
      (psCKernelExprAbstractionConst "T")
      (PsCKernelExpr.app (PsCKernelExpr.bvar 1) (PsCKernelExpr.bvar 0))
      PsCKernelBinderInfo.default
  psCKernelExprEqStructural
    (psCKernelExprAbstractFVar input psCKernelExprAbstractionTarget)
    expected

def psCKernelExprAbstractionTestBinderTypeAndBody : Bool :=
  let input : PsCKernelExpr :=
    PsCKernelExpr.forallE
      psCKernelExprAbstractionNameY
      (PsCKernelExpr.fvar psCKernelExprAbstractionTarget)
      (PsCKernelExpr.fvar psCKernelExprAbstractionTarget)
      PsCKernelBinderInfo.implicit
  let expected : PsCKernelExpr :=
    PsCKernelExpr.forallE
      psCKernelExprAbstractionNameY
      (PsCKernelExpr.bvar 0)
      (PsCKernelExpr.bvar 1)
      PsCKernelBinderInfo.implicit
  psCKernelExprEqStructural
    (psCKernelExprAbstractFVar input psCKernelExprAbstractionTarget)
    expected

def psCKernelExprAbstractionTestLooseBVarUnderBinderShifts : Bool :=
  let input : PsCKernelExpr :=
    PsCKernelExpr.lam
      psCKernelExprAbstractionNameY
      (psCKernelExprAbstractionConst "T")
      (PsCKernelExpr.bvar 1)
      PsCKernelBinderInfo.default
  let expected : PsCKernelExpr :=
    PsCKernelExpr.lam
      psCKernelExprAbstractionNameY
      (psCKernelExprAbstractionConst "T")
      (PsCKernelExpr.bvar 2)
      PsCKernelBinderInfo.default
  psCKernelExprEqStructural
    (psCKernelExprAbstractFVar input psCKernelExprAbstractionTarget)
    expected

def psCKernelExprAbstractionTestLetDepth : Bool :=
  let input : PsCKernelExpr :=
    PsCKernelExpr.letE
      psCKernelExprAbstractionNameY
      (PsCKernelExpr.fvar psCKernelExprAbstractionTarget)
      (PsCKernelExpr.fvar psCKernelExprAbstractionTarget)
      (PsCKernelExpr.app
        (PsCKernelExpr.fvar psCKernelExprAbstractionTarget)
        (PsCKernelExpr.bvar 0))
      true
  let expected : PsCKernelExpr :=
    PsCKernelExpr.letE
      psCKernelExprAbstractionNameY
      (PsCKernelExpr.bvar 0)
      (PsCKernelExpr.bvar 0)
      (PsCKernelExpr.app (PsCKernelExpr.bvar 1) (PsCKernelExpr.bvar 0))
      true
  psCKernelExprEqStructural
    (psCKernelExprAbstractFVar input psCKernelExprAbstractionTarget)
    expected

def psCKernelExprAbstractionTestProjectionTraversal : Bool :=
  let input : PsCKernelExpr :=
    PsCKernelExpr.proj
      psCKernelExprAbstractionNameP
      3
      (PsCKernelExpr.fvar psCKernelExprAbstractionTarget)
  let expected : PsCKernelExpr :=
    PsCKernelExpr.proj
      psCKernelExprAbstractionNameP
      3
      (PsCKernelExpr.bvar 0)
  psCKernelExprEqStructural
    (psCKernelExprAbstractFVar input psCKernelExprAbstractionTarget)
    expected

def psCKernelExprAbstractionTestNestedNonTargetPreserved : Bool :=
  let input : PsCKernelExpr :=
    PsCKernelExpr.app
      (PsCKernelExpr.fvar psCKernelExprAbstractionOther)
      (PsCKernelExpr.fvar psCKernelExprAbstractionTarget)
  let expected : PsCKernelExpr :=
    PsCKernelExpr.app
      (PsCKernelExpr.fvar psCKernelExprAbstractionOther)
      (PsCKernelExpr.bvar 0)
  psCKernelExprEqStructural
    (psCKernelExprAbstractFVar input psCKernelExprAbstractionTarget)
    expected

def psCKernelExprAbstractionTests : List PsCKernelExprAbstractionNamedTest := [
  { name := "non-target free variable is preserved", passed := psCKernelExprAbstractionTestNonTarget },
  { name := "target free variable abstracts at root depth", passed := psCKernelExprAbstractionTestTargetAtRoot },
  { name := "existing loose bound variable shifts", passed := psCKernelExprAbstractionTestExistingLooseBVarShifts },
  { name := "application abstracts target and shifts loose bound variable", passed := psCKernelExprAbstractionTestApplication },
  { name := "lambda body abstraction uses binder depth", passed := psCKernelExprAbstractionTestLambdaDepth },
  { name := "binder type and body abstract at different depths", passed := psCKernelExprAbstractionTestBinderTypeAndBody },
  { name := "loose bound variable under binder shifts above depth", passed := psCKernelExprAbstractionTestLooseBVarUnderBinderShifts },
  { name := "let type value and body use correct depths", passed := psCKernelExprAbstractionTestLetDepth },
  { name := "projection traversal abstracts inner expression", passed := psCKernelExprAbstractionTestProjectionTraversal },
  { name := "non-target free variables survive nested traversal", passed := psCKernelExprAbstractionTestNestedNonTargetPreserved }
]

def psCKernelRunExprAbstractionTests
    (tests : List PsCKernelExprAbstractionNamedTest) : IO Bool :=
  match tests with
  | [] => pure true
  | test :: rest => do
      if test.passed then
        IO.println ("PSCKERNEL_EXPR_ABSTRACTION_PASS: " ++ test.name)
      else
        IO.println ("PSCKERNEL_EXPR_ABSTRACTION_FAIL: " ++ test.name)
      let restPassed ← psCKernelRunExprAbstractionTests rest
      pure (test.passed && restPassed)

def main : IO Unit := do
  let passed ← psCKernelRunExprAbstractionTests psCKernelExprAbstractionTests
  if passed then
    IO.println "PSCKERNEL_EXPR_ABSTRACTION_TESTS: PASS"
  else
    throw (IO.userError "PSCKERNEL_EXPR_ABSTRACTION_TESTS: FAIL")
