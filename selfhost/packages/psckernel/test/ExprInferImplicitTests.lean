import Ps.PSCKernel.Core.ExprInferImplicit

structure PsCKernelExprInferImplicitNamedTest where
  name : String
  passed : Bool

def psCKernelExprInferImplicitName (text : String) : PsCKernelName :=
  psCKernelNameFromDotted text

def psCKernelExprInferImplicitType : PsCKernelExpr :=
  PsCKernelExpr.sortE (psCKernelLevelSucc psCKernelLevelZero)

def psCKernelExprInferImplicitBinderInfo?
    (expr : PsCKernelExpr)
    (index : Nat) : Option PsCKernelBinderInfo :=
  match index, expr with
  | 0, PsCKernelExpr.forallE _ _ _ binderInfo => some binderInfo
  | Nat.succ rest, PsCKernelExpr.forallE _ _ body _ =>
      psCKernelExprInferImplicitBinderInfo? body rest
  | _, _ => none

def psCKernelExprInferImplicitBinderIs
    (expr : PsCKernelExpr)
    (index : Nat)
    (expected : PsCKernelBinderInfo) : Bool :=
  match psCKernelExprInferImplicitBinderInfo? expr index with
  | none => false
  | some actual => psCKernelBinderInfoEq actual expected

def psCKernelExprInferImplicitNondependent : PsCKernelExpr :=
  PsCKernelExpr.forallE
    (psCKernelExprInferImplicitName "A")
    psCKernelExprInferImplicitType
    (PsCKernelExpr.forallE
      (psCKernelExprInferImplicitName "B")
      psCKernelExprInferImplicitType
      psCKernelExprInferImplicitType
      PsCKernelBinderInfo.default)
    PsCKernelBinderInfo.default

def psCKernelExprInferImplicitDirectDependency : PsCKernelExpr :=
  PsCKernelExpr.forallE
    (psCKernelExprInferImplicitName "A")
    psCKernelExprInferImplicitType
    (PsCKernelExpr.forallE
      (psCKernelExprInferImplicitName "x")
      (PsCKernelExpr.bvar 0)
      psCKernelExprInferImplicitType
      PsCKernelBinderInfo.default)
    PsCKernelBinderInfo.default

def psCKernelExprInferImplicitRangeOnly : PsCKernelExpr :=
  PsCKernelExpr.forallE
    (psCKernelExprInferImplicitName "A")
    psCKernelExprInferImplicitType
    (PsCKernelExpr.bvar 0)
    PsCKernelBinderInfo.default

def psCKernelExprInferImplicitTransitive : PsCKernelExpr :=
  PsCKernelExpr.forallE
    (psCKernelExprInferImplicitName "A")
    psCKernelExprInferImplicitType
    (PsCKernelExpr.forallE
      (psCKernelExprInferImplicitName "B")
      (PsCKernelExpr.bvar 0)
      (PsCKernelExpr.forallE
        (psCKernelExprInferImplicitName "x")
        (PsCKernelExpr.bvar 0)
        psCKernelExprInferImplicitType
        PsCKernelBinderInfo.default)
      PsCKernelBinderInfo.implicit)
    PsCKernelBinderInfo.default

def psCKernelExprInferImplicitPrefix : PsCKernelExpr :=
  PsCKernelExpr.forallE
    (psCKernelExprInferImplicitName "A")
    psCKernelExprInferImplicitType
    (PsCKernelExpr.forallE
      (psCKernelExprInferImplicitName "B")
      psCKernelExprInferImplicitType
      (PsCKernelExpr.forallE
        (psCKernelExprInferImplicitName "x")
        (PsCKernelExpr.bvar 0)
        psCKernelExprInferImplicitType
        PsCKernelBinderInfo.default)
      PsCKernelBinderInfo.default)
    PsCKernelBinderInfo.default

def psCKernelExprInferImplicitTests : List PsCKernelExprInferImplicitNamedTest := [
  {
    name := "nondependent binders remain explicit"
    passed :=
      let result :=
        psCKernelExprInferImplicitAll
          psCKernelExprInferImplicitNondependent
          true
      psCKernelExprInferImplicitBinderIs
        result 0 PsCKernelBinderInfo.default &&
      psCKernelExprInferImplicitBinderIs
        result 1 PsCKernelBinderInfo.default
  },
  {
    name := "explicit dependent domain makes earlier binder implicit"
    passed :=
      let result :=
        psCKernelExprInferImplicitAll
          psCKernelExprInferImplicitDirectDependency
          true
      psCKernelExprInferImplicitBinderIs
        result 0 PsCKernelBinderInfo.implicit &&
      psCKernelExprInferImplicitBinderIs
        result 1 PsCKernelBinderInfo.default
  },
  {
    name := "strict inference ignores dependency only in final range"
    passed :=
      let result :=
        psCKernelExprInferImplicitAll
          psCKernelExprInferImplicitRangeOnly
          true
      psCKernelExprInferImplicitBinderIs
        result 0 PsCKernelBinderInfo.default
  },
  {
    name := "nonstrict inference considers dependency in final range"
    passed :=
      let result :=
        psCKernelExprInferImplicitAll
          psCKernelExprInferImplicitRangeOnly
          false
      psCKernelExprInferImplicitBinderIs
        result 0 PsCKernelBinderInfo.implicit
  },
  {
    name := "dependency propagates through an implicit binder"
    passed :=
      let result :=
        psCKernelExprInferImplicitAll
          psCKernelExprInferImplicitTransitive
          true
      psCKernelExprInferImplicitBinderIs
        result 0 PsCKernelBinderInfo.implicit &&
      psCKernelExprInferImplicitBinderIs
        result 1 PsCKernelBinderInfo.implicit &&
      psCKernelExprInferImplicitBinderIs
        result 2 PsCKernelBinderInfo.default
  },
  {
    name := "bounded inference only updates requested prefix"
    passed :=
      let result :=
        psCKernelExprInferImplicit
          psCKernelExprInferImplicitPrefix
          true
          1
      psCKernelExprInferImplicitBinderIs
        result 0 PsCKernelBinderInfo.default &&
      psCKernelExprInferImplicitBinderIs
        result 1 PsCKernelBinderInfo.default &&
      psCKernelExprInferImplicitBinderIs
        result 2 PsCKernelBinderInfo.default
  }
]

def psCKernelRunExprInferImplicitTests
    (tests : List PsCKernelExprInferImplicitNamedTest) : IO Bool :=
  match tests with
  | [] => pure true
  | test :: rest => do
      if test.passed then
        IO.println ("PSCKERNEL_EXPR_INFER_IMPLICIT_PASS: " ++ test.name)
      else
        IO.println ("PSCKERNEL_EXPR_INFER_IMPLICIT_FAIL: " ++ test.name)
      let restPassed ← psCKernelRunExprInferImplicitTests rest
      pure (test.passed && restPassed)

def main : IO Unit := do
  let passed ← psCKernelRunExprInferImplicitTests psCKernelExprInferImplicitTests
  if passed then
    IO.println "PSCKERNEL_EXPR_INFER_IMPLICIT_TESTS: PASS"
  else
    throw (IO.userError "PSCKERNEL_EXPR_INFER_IMPLICIT_TESTS: FAIL")
