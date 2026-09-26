import Ps.PSCKernel.Core.ReductionBasic

structure PsCKernelQuotReductionNamedTest where
  name : String
  passed : Bool

def psCKernelQuotName (text : String) : PsCKernelName :=
  psCKernelNameFromDotted text

def psCKernelQuotConst (text : String) : PsCKernelExpr :=
  PsCKernelExpr.constE (psCKernelQuotName text) []

def psCKernelQuotAppN
    (fn : PsCKernelExpr)
    (args : List PsCKernelExpr) : PsCKernelExpr :=
  psCKernelExprMkAppN fn args

def psCKernelQuotMk (value : PsCKernelExpr) : PsCKernelExpr :=
  psCKernelQuotAppN
    (psCKernelQuotConst "Quot.mk")
    [
      psCKernelQuotConst "A",
      psCKernelQuotConst "r",
      value
    ]

def psCKernelQuotLiftExpr
    (major : PsCKernelExpr)
    (trailing : List PsCKernelExpr := []) : PsCKernelExpr :=
  psCKernelQuotAppN
    (psCKernelQuotConst "Quot.lift")
    (
      [
        psCKernelQuotConst "A",
        psCKernelQuotConst "r",
        psCKernelQuotConst "B",
        psCKernelQuotConst "f",
        psCKernelQuotConst "h",
        major
      ] ++ trailing
    )

def psCKernelQuotIndExpr
    (major : PsCKernelExpr)
    (trailing : List PsCKernelExpr := []) : PsCKernelExpr :=
  psCKernelQuotAppN
    (psCKernelQuotConst "Quot.ind")
    (
      [
        psCKernelQuotConst "A",
        psCKernelQuotConst "r",
        psCKernelQuotConst "motive",
        psCKernelQuotConst "proof",
        major
      ] ++ trailing
    )

def psCKernelQuotEnv : PsCKernelEnvironment :=
  psCKernelEnvironmentMarkQuotInitialized psCKernelEnvironmentEmpty

def psCKernelQuotPayload : PsCKernelExpr := psCKernelQuotConst "x"

def psCKernelQuotTail : PsCKernelExpr := psCKernelQuotConst "tail"

def psCKernelQuotTestLiftReduces : Bool :=
  let expr := psCKernelQuotLiftExpr (psCKernelQuotMk psCKernelQuotPayload)
  let expected := PsCKernelExpr.app (psCKernelQuotConst "f") psCKernelQuotPayload
  psCKernelExprEqStructural
    (psCKernelExprWhnfBasic psCKernelQuotEnv psCKernelLocalContextEmpty expr)
    expected

def psCKernelQuotTestIndReduces : Bool :=
  let expr := psCKernelQuotIndExpr (psCKernelQuotMk psCKernelQuotPayload)
  let expected := PsCKernelExpr.app (psCKernelQuotConst "proof") psCKernelQuotPayload
  psCKernelExprEqStructural
    (psCKernelExprWhnfBasic psCKernelQuotEnv psCKernelLocalContextEmpty expr)
    expected

def psCKernelQuotTestLiftTrailing : Bool :=
  let expr := psCKernelQuotLiftExpr
    (psCKernelQuotMk psCKernelQuotPayload)
    [psCKernelQuotTail]
  let expected := psCKernelQuotAppN
    (psCKernelQuotConst "f")
    [psCKernelQuotPayload, psCKernelQuotTail]
  psCKernelExprEqStructural
    (psCKernelExprWhnfBasic psCKernelQuotEnv psCKernelLocalContextEmpty expr)
    expected

def psCKernelQuotTestIndTrailing : Bool :=
  let expr := psCKernelQuotIndExpr
    (psCKernelQuotMk psCKernelQuotPayload)
    [psCKernelQuotTail]
  let expected := psCKernelQuotAppN
    (psCKernelQuotConst "proof")
    [psCKernelQuotPayload, psCKernelQuotTail]
  psCKernelExprEqStructural
    (psCKernelExprWhnfBasic psCKernelQuotEnv psCKernelLocalContextEmpty expr)
    expected

def psCKernelQuotTestMajorWhnf : Bool :=
  let major := PsCKernelExpr.letE
    (psCKernelQuotName "q")
    (psCKernelQuotConst "QuotType")
    (psCKernelQuotMk psCKernelQuotPayload)
    (PsCKernelExpr.bvar 0)
    false
  let expr := psCKernelQuotLiftExpr major
  let expected := PsCKernelExpr.app (psCKernelQuotConst "f") psCKernelQuotPayload
  psCKernelExprEqStructural
    (psCKernelExprWhnfBasic psCKernelQuotEnv psCKernelLocalContextEmpty expr)
    expected

def psCKernelQuotTestUninitializedStuck : Bool :=
  let expr := psCKernelQuotLiftExpr (psCKernelQuotMk psCKernelQuotPayload)
  psCKernelExprEqStructural
    (psCKernelExprWhnfBasic psCKernelEnvironmentEmpty psCKernelLocalContextEmpty expr)
    expr

def psCKernelQuotTestWrongMajorStuck : Bool :=
  let expr := psCKernelQuotLiftExpr (psCKernelQuotConst "notQuot")
  psCKernelExprEqStructural
    (psCKernelExprWhnfBasic psCKernelQuotEnv psCKernelLocalContextEmpty expr)
    expr

def psCKernelQuotTestWrongMkArityStuck : Bool :=
  let malformed := psCKernelQuotAppN
    (psCKernelQuotConst "Quot.mk")
    [psCKernelQuotConst "A", psCKernelQuotPayload]
  let expr := psCKernelQuotLiftExpr malformed
  psCKernelExprEqStructural
    (psCKernelExprWhnfBasic psCKernelQuotEnv psCKernelLocalContextEmpty expr)
    expr

def psCKernelQuotTestLiftTooFewArgsStuck : Bool :=
  let expr := psCKernelQuotAppN
    (psCKernelQuotConst "Quot.lift")
    [
      psCKernelQuotConst "A",
      psCKernelQuotConst "r",
      psCKernelQuotConst "B",
      psCKernelQuotConst "f",
      psCKernelQuotConst "h"
    ]
  psCKernelExprEqStructural
    (psCKernelExprWhnfBasic psCKernelQuotEnv psCKernelLocalContextEmpty expr)
    expr

def psCKernelQuotReductionTests : List PsCKernelQuotReductionNamedTest := [
  { name := "Quot.lift reduces a Quot.mk major", passed := psCKernelQuotTestLiftReduces },
  { name := "Quot.ind reduces a Quot.mk major", passed := psCKernelQuotTestIndReduces },
  { name := "Quot.lift preserves trailing arguments", passed := psCKernelQuotTestLiftTrailing },
  { name := "Quot.ind preserves trailing arguments", passed := psCKernelQuotTestIndTrailing },
  { name := "quotient reduction weak-head reduces the major", passed := psCKernelQuotTestMajorWhnf },
  { name := "quotient reduction requires initialized quotient support", passed := psCKernelQuotTestUninitializedStuck },
  { name := "non-Quot.mk major stays stuck", passed := psCKernelQuotTestWrongMajorStuck },
  { name := "malformed Quot.mk arity stays stuck", passed := psCKernelQuotTestWrongMkArityStuck },
  { name := "partial Quot.lift application stays stuck", passed := psCKernelQuotTestLiftTooFewArgsStuck }
]

def psCKernelRunQuotReductionTests
    (tests : List PsCKernelQuotReductionNamedTest) : IO Bool :=
  match tests with
  | [] => pure true
  | test :: rest => do
      if test.passed then
        IO.println ("PSCKERNEL_QUOT_REDUCTION_PASS: " ++ test.name)
      else
        IO.println ("PSCKERNEL_QUOT_REDUCTION_FAIL: " ++ test.name)
      let restPassed ← psCKernelRunQuotReductionTests rest
      pure (test.passed && restPassed)

def main : IO Unit := do
  let passed ← psCKernelRunQuotReductionTests psCKernelQuotReductionTests
  if passed then
    IO.println "PSCKERNEL_QUOT_REDUCTION_TESTS: PASS"
  else
    throw (IO.userError "PSCKERNEL_QUOT_REDUCTION_TESTS: FAIL")
