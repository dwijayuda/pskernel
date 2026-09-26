import Ps.PSCKernel.Core.Expr

structure PsCKernelExprBasicNamedTest where
  name : String
  passed : Bool

def psCKernelExprBasicNameA : PsCKernelName :=
  psCKernelNameFromDotted "A"

def psCKernelExprBasicNameB : PsCKernelName :=
  psCKernelNameFromDotted "B"

def psCKernelExprBasicNameF : PsCKernelName :=
  psCKernelNameFromDotted "f"

def psCKernelExprBasicNameX : PsCKernelName :=
  psCKernelNameFromDotted "x"

def psCKernelExprBasicNameY : PsCKernelName :=
  psCKernelNameFromDotted "y"

def psCKernelExprBasicTypeA : PsCKernelExpr :=
  PsCKernelExpr.constE psCKernelExprBasicNameA []

def psCKernelExprBasicTypeB : PsCKernelExpr :=
  PsCKernelExpr.constE psCKernelExprBasicNameB []

def psCKernelExprBasicTestBinderInfoPredicates : Bool :=
  psCKernelBinderInfoIsExplicit PsCKernelBinderInfo.default
    && !psCKernelBinderInfoIsExplicit PsCKernelBinderInfo.implicit
    && !psCKernelBinderInfoIsExplicit PsCKernelBinderInfo.strictImplicit
    && !psCKernelBinderInfoIsExplicit PsCKernelBinderInfo.instImplicit
    && psCKernelBinderInfoIsImplicit PsCKernelBinderInfo.implicit
    && psCKernelBinderInfoIsStrictImplicit PsCKernelBinderInfo.strictImplicit
    && psCKernelBinderInfoIsInstImplicit PsCKernelBinderInfo.instImplicit

def psCKernelExprBasicTestIdWrappersUseNames : Bool :=
  let fvarId : PsCKernelFVarId := { name := psCKernelExprBasicNameX }
  let mvarId : PsCKernelMVarId := { name := psCKernelExprBasicNameX }
  psCKernelNameEq fvarId.name mvarId.name

def psCKernelExprBasicTestLiteralStructuralEquality : Bool :=
  psCKernelLiteralEq
    (PsCKernelLiteral.natVal 42)
    (PsCKernelLiteral.natVal 42)
    && !psCKernelLiteralEq
      (PsCKernelLiteral.natVal 42)
      (PsCKernelLiteral.strVal "42")

def psCKernelExprBasicTestStructuralEqualityCoversFields : Bool :=
  let left : PsCKernelExpr :=
    PsCKernelExpr.letE
      psCKernelExprBasicNameX
      psCKernelExprBasicTypeA
      (PsCKernelExpr.lit (PsCKernelLiteral.natVal 1))
      (PsCKernelExpr.bvar 0)
      true
  let same : PsCKernelExpr :=
    PsCKernelExpr.letE
      psCKernelExprBasicNameX
      psCKernelExprBasicTypeA
      (PsCKernelExpr.lit (PsCKernelLiteral.natVal 1))
      (PsCKernelExpr.bvar 0)
      true
  let changedNondep : PsCKernelExpr :=
    PsCKernelExpr.letE
      psCKernelExprBasicNameX
      psCKernelExprBasicTypeA
      (PsCKernelExpr.lit (PsCKernelLiteral.natVal 1))
      (PsCKernelExpr.bvar 0)
      false
  psCKernelExprEqStructural left same
    && !psCKernelExprEqStructural left changedNondep

def psCKernelExprBasicTestEqvIgnoresBinderPresentation : Bool :=
  let left : PsCKernelExpr :=
    PsCKernelExpr.lam
      psCKernelExprBasicNameX
      psCKernelExprBasicTypeA
      (PsCKernelExpr.bvar 0)
      PsCKernelBinderInfo.default
  let right : PsCKernelExpr :=
    PsCKernelExpr.lam
      psCKernelExprBasicNameY
      psCKernelExprBasicTypeA
      (PsCKernelExpr.bvar 0)
      PsCKernelBinderInfo.implicit
  psCKernelExprEqv left right
    && !psCKernelExprEqStructural left right

def psCKernelExprBasicTestEqvKeepsLetNondep : Bool :=
  let left : PsCKernelExpr :=
    PsCKernelExpr.letE
      psCKernelExprBasicNameX
      psCKernelExprBasicTypeA
      psCKernelExprBasicTypeB
      (PsCKernelExpr.bvar 0)
      true
  let right : PsCKernelExpr :=
    PsCKernelExpr.letE
      psCKernelExprBasicNameY
      psCKernelExprBasicTypeA
      psCKernelExprBasicTypeB
      (PsCKernelExpr.bvar 0)
      false
  !psCKernelExprEqv left right

def psCKernelExprBasicTestApplicationSpine : Bool :=
  let fn : PsCKernelExpr :=
    PsCKernelExpr.constE psCKernelExprBasicNameF []
  let arg1 : PsCKernelExpr := PsCKernelExpr.bvar 0
  let arg2 : PsCKernelExpr := PsCKernelExpr.bvar 1
  let application : PsCKernelExpr :=
    psCKernelExprMkAppN fn [arg1, arg2]
  psCKernelExprEqStructural
      (psCKernelExprGetAppFn application)
      fn
    && psCKernelExprListEqStructural
      (psCKernelExprGetAppArgs application)
      [arg1, arg2]

def psCKernelExprBasicTestProjectionFields : Bool :=
  let value : PsCKernelExpr := PsCKernelExpr.bvar 0
  let left : PsCKernelExpr :=
    PsCKernelExpr.proj psCKernelExprBasicNameA 0 value
  let right : PsCKernelExpr :=
    PsCKernelExpr.proj psCKernelExprBasicNameA 1 value
  !psCKernelExprEqStructural left right

def psCKernelExprBasicTestVariableFlags : Bool :=
  let fvarExpr : PsCKernelExpr :=
    PsCKernelExpr.fvar { name := psCKernelExprBasicNameX }
  let mvarExpr : PsCKernelExpr :=
    PsCKernelExpr.mvar { name := psCKernelExprBasicNameY }
  let combined : PsCKernelExpr := PsCKernelExpr.app fvarExpr mvarExpr
  psCKernelExprHasFVar combined
    && psCKernelExprHasExprMVar combined
    && psCKernelExprHasMVar combined

def psCKernelExprBasicTestUniverseMVarFlag : Bool :=
  let universeMVar : PsCKernelLevel :=
    psCKernelLevelMVar psCKernelExprBasicNameX
  let expression : PsCKernelExpr := PsCKernelExpr.sortE universeMVar
  psCKernelExprHasLevelMVar expression
    && psCKernelExprHasMVar expression
    && !psCKernelExprHasExprMVar expression

def psCKernelExprBasicTests : List PsCKernelExprBasicNamedTest := [
  { name := "binder info predicates", passed := psCKernelExprBasicTestBinderInfoPredicates },
  { name := "fvar and mvar ids wrap Names", passed := psCKernelExprBasicTestIdWrappersUseNames },
  { name := "literal structural equality", passed := psCKernelExprBasicTestLiteralStructuralEquality },
  { name := "structural equality covers let fields", passed := psCKernelExprBasicTestStructuralEqualityCoversFields },
  { name := "Expr.eqv ignores binder presentation", passed := psCKernelExprBasicTestEqvIgnoresBinderPresentation },
  { name := "Expr.eqv keeps let nondep", passed := psCKernelExprBasicTestEqvKeepsLetNondep },
  { name := "application spine helpers preserve argument order", passed := psCKernelExprBasicTestApplicationSpine },
  { name := "projection metadata participates in equality", passed := psCKernelExprBasicTestProjectionFields },
  { name := "free and expression metavariable flags", passed := psCKernelExprBasicTestVariableFlags },
  { name := "universe metavariable flag", passed := psCKernelExprBasicTestUniverseMVarFlag }
]

def psCKernelRunExprBasicTests
    (tests : List PsCKernelExprBasicNamedTest) : IO Bool :=
  match tests with
  | [] => pure true
  | test :: rest => do
      if test.passed then
        IO.println ("PSCKERNEL_EXPR_BASIC_PASS: " ++ test.name)
      else
        IO.println ("PSCKERNEL_EXPR_BASIC_FAIL: " ++ test.name)
      let restPassed ← psCKernelRunExprBasicTests rest
      pure (test.passed && restPassed)

def main : IO Unit := do
  let passed ← psCKernelRunExprBasicTests psCKernelExprBasicTests
  if passed then
    IO.println "PSCKERNEL_EXPR_BASIC_TESTS: PASS"
  else
    throw (IO.userError "PSCKERNEL_EXPR_BASIC_TESTS: FAIL")
