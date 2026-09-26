import Ps.PSCKernel.Core.ReductionBasic

structure PsCKernelReductionBasicNamedTest where
  name : String
  passed : Bool

def psCKernelReductionBasicName (text : String) : PsCKernelName :=
  psCKernelNameFromDotted text

def psCKernelReductionBasicConst (text : String) : PsCKernelExpr :=
  PsCKernelExpr.constE (psCKernelReductionBasicName text) []

def psCKernelReductionBasicDefinition
    (name : String)
    (levelParams : List PsCKernelName)
    (value : PsCKernelExpr) : PsCKernelConstantInfo :=
  PsCKernelConstantInfo.defnInfo {
    base := {
      name := psCKernelReductionBasicName name
      levelParams := levelParams
      declType := psCKernelReductionBasicConst "Type"
    }
    value := value
    hints := PsCKernelReducibilityHints.regular 1
    safety := PsCKernelDefinitionSafety.safe
    all := [psCKernelReductionBasicName name]
  }

def psCKernelReductionBasicTheorem
    (name : String)
    (value : PsCKernelExpr) : PsCKernelConstantInfo :=
  PsCKernelConstantInfo.thmInfo {
    base := {
      name := psCKernelReductionBasicName name
      levelParams := []
      declType := psCKernelReductionBasicConst "Prop"
    }
    value := value
    all := [psCKernelReductionBasicName name]
  }

def psCKernelReductionBasicEnvWith
    (info : PsCKernelConstantInfo) : PsCKernelEnvironment :=
  match psCKernelEnvironmentTryAdd psCKernelEnvironmentEmpty info with
  | none => psCKernelEnvironmentEmpty
  | some env => env

def psCKernelReductionBasicTestEasyConst : Bool :=
  let expr := psCKernelReductionBasicConst "A"
  psCKernelExprEqStructural
    (psCKernelExprWhnfBasic psCKernelEnvironmentEmpty psCKernelLocalContextEmpty expr)
    expr

def psCKernelReductionBasicTestLet : Bool :=
  let value := psCKernelReductionBasicConst "A"
  let expr := PsCKernelExpr.letE
    (psCKernelReductionBasicName "x")
    (psCKernelReductionBasicConst "T")
    value
    (PsCKernelExpr.bvar 0)
    false
  psCKernelExprEqStructural
    (psCKernelExprWhnfBasic psCKernelEnvironmentEmpty psCKernelLocalContextEmpty expr)
    value

def psCKernelReductionBasicTestBeta : Bool :=
  let value := psCKernelReductionBasicConst "A"
  let fn := PsCKernelExpr.lam
    (psCKernelReductionBasicName "x")
    (psCKernelReductionBasicConst "T")
    (PsCKernelExpr.bvar 0)
    PsCKernelBinderInfo.default
  psCKernelExprEqStructural
    (psCKernelExprWhnfBasic
      psCKernelEnvironmentEmpty
      psCKernelLocalContextEmpty
      (PsCKernelExpr.app fn value))
    value

def psCKernelReductionBasicTestNestedBeta : Bool :=
  let valueA := psCKernelReductionBasicConst "A"
  let valueB := psCKernelReductionBasicConst "B"
  let fn := PsCKernelExpr.lam
    (psCKernelReductionBasicName "x")
    (psCKernelReductionBasicConst "T")
    (PsCKernelExpr.lam
      (psCKernelReductionBasicName "y")
      (psCKernelReductionBasicConst "T")
      (PsCKernelExpr.bvar 1)
      PsCKernelBinderInfo.default)
    PsCKernelBinderInfo.default
  let applied := PsCKernelExpr.app (PsCKernelExpr.app fn valueA) valueB
  psCKernelExprEqStructural
    (psCKernelExprWhnfBasic psCKernelEnvironmentEmpty psCKernelLocalContextEmpty applied)
    valueA

def psCKernelReductionBasicTestLocalLet : Bool :=
  let fvarId : PsCKernelFVarId := { name := psCKernelReductionBasicName "xId" }
  let value := psCKernelReductionBasicConst "A"
  let ctx := psCKernelLocalContextMkLetDecl
    psCKernelLocalContextEmpty
    fvarId
    (psCKernelReductionBasicName "x")
    (psCKernelReductionBasicConst "T")
    value
    false
    PsCKernelLocalDeclKind.default
  psCKernelExprEqStructural
    (psCKernelExprWhnfBasic
      psCKernelEnvironmentEmpty
      ctx
      (PsCKernelExpr.fvar fvarId))
    value

def psCKernelReductionBasicTestNondepLocalLetStuck : Bool :=
  let fvarId : PsCKernelFVarId := { name := psCKernelReductionBasicName "xId" }
  let value := psCKernelReductionBasicConst "A"
  let ctx := psCKernelLocalContextMkLetDecl
    psCKernelLocalContextEmpty
    fvarId
    (psCKernelReductionBasicName "x")
    (psCKernelReductionBasicConst "T")
    value
    true
    PsCKernelLocalDeclKind.default
  let expr := PsCKernelExpr.fvar fvarId
  psCKernelExprEqStructural
    (psCKernelExprWhnfBasic psCKernelEnvironmentEmpty ctx expr)
    expr

def psCKernelReductionBasicTestDelta : Bool :=
  let body := psCKernelReductionBasicConst "A"
  let env := psCKernelReductionBasicEnvWith
    (psCKernelReductionBasicDefinition "d" [] body)
  psCKernelExprEqStructural
    (psCKernelExprWhnfBasic
      env
      psCKernelLocalContextEmpty
      (psCKernelReductionBasicConst "d"))
    body

def psCKernelReductionBasicTestDeltaThenBeta : Bool :=
  let fn := PsCKernelExpr.lam
    (psCKernelReductionBasicName "x")
    (psCKernelReductionBasicConst "T")
    (PsCKernelExpr.bvar 0)
    PsCKernelBinderInfo.default
  let env := psCKernelReductionBasicEnvWith
    (psCKernelReductionBasicDefinition "id" [] fn)
  let value := psCKernelReductionBasicConst "A"
  psCKernelExprEqStructural
    (psCKernelExprWhnfBasic
      env
      psCKernelLocalContextEmpty
      (PsCKernelExpr.app (psCKernelReductionBasicConst "id") value))
    value

def psCKernelReductionBasicTestTheoremDoesNotDelta : Bool :=
  let expr := psCKernelReductionBasicConst "thm"
  let env := psCKernelReductionBasicEnvWith
    (psCKernelReductionBasicTheorem "thm" (psCKernelReductionBasicConst "proof"))
  psCKernelExprEqStructural
    (psCKernelExprWhnfBasic env psCKernelLocalContextEmpty expr)
    expr

def psCKernelReductionBasicTestUniverseDelta : Bool :=
  let u := psCKernelReductionBasicName "u"
  let body := PsCKernelExpr.sortE (psCKernelLevelParam u)
  let env := psCKernelReductionBasicEnvWith
    (psCKernelReductionBasicDefinition "poly" [u] body)
  let expr := PsCKernelExpr.constE
    (psCKernelReductionBasicName "poly")
    [psCKernelLevelZero]
  psCKernelExprEqStructural
    (psCKernelExprWhnfBasic env psCKernelLocalContextEmpty expr)
    (PsCKernelExpr.sortE psCKernelLevelZero)

def psCKernelReductionBasicTestBadUniverseArityStuck : Bool :=
  let u := psCKernelReductionBasicName "u"
  let env := psCKernelReductionBasicEnvWith
    (psCKernelReductionBasicDefinition
      "poly"
      [u]
      (PsCKernelExpr.sortE (psCKernelLevelParam u)))
  let expr := psCKernelReductionBasicConst "poly"
  psCKernelExprEqStructural
    (psCKernelExprWhnfBasic env psCKernelLocalContextEmpty expr)
    expr

def psCKernelReductionBasicTestReducibleHeadFromLet : Bool :=
  let value := psCKernelReductionBasicConst "A"
  let lambda := PsCKernelExpr.lam
    (psCKernelReductionBasicName "x")
    (psCKernelReductionBasicConst "T")
    (PsCKernelExpr.bvar 0)
    PsCKernelBinderInfo.default
  let head := PsCKernelExpr.letE
    (psCKernelReductionBasicName "f")
    (psCKernelReductionBasicConst "Fn")
    lambda
    (PsCKernelExpr.bvar 0)
    false
  psCKernelExprEqStructural
    (psCKernelExprWhnfBasic
      psCKernelEnvironmentEmpty
      psCKernelLocalContextEmpty
      (PsCKernelExpr.app head value))
    value

def psCKernelReductionBasicTests : List PsCKernelReductionBasicNamedTest := [
  { name := "easy constants remain in weak-head form", passed := psCKernelReductionBasicTestEasyConst },
  { name := "let expressions zeta-reduce", passed := psCKernelReductionBasicTestLet },
  { name := "lambda applications beta-reduce", passed := psCKernelReductionBasicTestBeta },
  { name := "nested lambda applications consume arguments", passed := psCKernelReductionBasicTestNestedBeta },
  { name := "dependent local lets zeta-reduce", passed := psCKernelReductionBasicTestLocalLet },
  { name := "nondep local lets remain opaque to kernel reduction", passed := psCKernelReductionBasicTestNondepLocalLetStuck },
  { name := "definitions delta-reduce", passed := psCKernelReductionBasicTestDelta },
  { name := "delta reduction exposes beta-redexes", passed := psCKernelReductionBasicTestDeltaThenBeta },
  { name := "theorems do not delta-reduce", passed := psCKernelReductionBasicTestTheoremDoesNotDelta },
  { name := "delta reduction instantiates universe parameters", passed := psCKernelReductionBasicTestUniverseDelta },
  { name := "wrong universe arity blocks delta reduction", passed := psCKernelReductionBasicTestBadUniverseArityStuck },
  { name := "application heads can reduce through lets", passed := psCKernelReductionBasicTestReducibleHeadFromLet }
]

def psCKernelRunReductionBasicTests
    (tests : List PsCKernelReductionBasicNamedTest) : IO Bool :=
  match tests with
  | [] => pure true
  | test :: rest => do
      if test.passed then
        IO.println ("PSCKERNEL_REDUCTION_BASIC_PASS: " ++ test.name)
      else
        IO.println ("PSCKERNEL_REDUCTION_BASIC_FAIL: " ++ test.name)
      let restPassed ← psCKernelRunReductionBasicTests rest
      pure (test.passed && restPassed)

def main : IO Unit := do
  let passed ← psCKernelRunReductionBasicTests psCKernelReductionBasicTests
  if passed then
    IO.println "PSCKERNEL_REDUCTION_BASIC_TESTS: PASS"
  else
    throw (IO.userError "PSCKERNEL_REDUCTION_BASIC_TESTS: FAIL")
