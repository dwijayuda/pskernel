import Ps.PSCKernel.Core.ReductionBasic

structure PsCKernelRecursorNatLiteralNamedTest where
  name : String
  passed : Bool

def psCKernelRecursorNatName (text : String) : PsCKernelName :=
  psCKernelNameFromDotted text

def psCKernelRecursorNatConst (text : String) : PsCKernelExpr :=
  PsCKernelExpr.constE (psCKernelRecursorNatName text) []

def psCKernelRecursorNatLit (value : Nat) : PsCKernelExpr :=
  PsCKernelExpr.lit (PsCKernelLiteral.natVal value)

def psCKernelRecursorNatAdd
    (env : PsCKernelEnvironment)
    (info : PsCKernelConstantInfo) : PsCKernelEnvironment :=
  match psCKernelEnvironmentTryAdd env info with
  | none => env
  | some next => next

def psCKernelRecursorNatEnv : PsCKernelEnvironment :=
  let natName := psCKernelRecursorNatName "Nat"
  let zeroName := psCKernelRecursorNatName "Nat.zero"
  let succName := psCKernelRecursorNatName "Nat.succ"
  let recName := psCKernelRecursorNatName "Nat.testRec"
  let sort1 := PsCKernelExpr.sortE (psCKernelLevelSucc psCKernelLevelZero)
  let natType := PsCKernelExpr.constE natName []
  let zeroInfo : PsCKernelConstantInfo := PsCKernelConstantInfo.ctorInfo {
    base := { name := zeroName, levelParams := [], declType := natType }
    induct := natName
    cidx := 0
    numParams := 0
    numFields := 0
    isUnsafe := false
  }
  let succInfo : PsCKernelConstantInfo := PsCKernelConstantInfo.ctorInfo {
    base := {
      name := succName
      levelParams := []
      declType := PsCKernelExpr.forallE
        (psCKernelRecursorNatName "n") natType natType PsCKernelBinderInfo.default
    }
    induct := natName
    cidx := 1
    numParams := 0
    numFields := 1
    isUnsafe := false
  }
  let natInfo : PsCKernelConstantInfo := PsCKernelConstantInfo.inductInfo {
    base := { name := natName, levelParams := [], declType := sort1 }
    numParams := 0
    numIndices := 0
    all := [natName, zeroName, succName]
    ctors := [zeroName, succName]
    numNested := 0
    isRec := true
    isUnsafe := false
    isReflexive := false
  }
  let recInfo : PsCKernelConstantInfo := PsCKernelConstantInfo.recInfo {
    base := { name := recName, levelParams := [], declType := sort1 }
    all := [natName]
    numParams := 0
    numIndices := 0
    numMotives := 0
    numMinors := 0
    rules := [
      { ctor := zeroName, nfields := 0, rhs := psCKernelRecursorNatLit 100 },
      {
        ctor := succName
        nfields := 1
        rhs := PsCKernelExpr.lam
          (psCKernelRecursorNatName "pred") natType
          (PsCKernelExpr.bvar 0) PsCKernelBinderInfo.default
      }
    ]
    k := false
    isUnsafe := false
  }
  let env0 := psCKernelRecursorNatAdd psCKernelEnvironmentEmpty natInfo
  let env1 := psCKernelRecursorNatAdd env0 zeroInfo
  let env2 := psCKernelRecursorNatAdd env1 succInfo
  psCKernelRecursorNatAdd env2 recInfo

def psCKernelRecursorNatTestZeroLiteral : Bool :=
  let expr := PsCKernelExpr.app
    (psCKernelRecursorNatConst "Nat.testRec")
    (psCKernelRecursorNatLit 0)
  psCKernelExprEqStructural
    (psCKernelExprWhnfBasic psCKernelRecursorNatEnv psCKernelLocalContextEmpty expr)
    (psCKernelRecursorNatLit 100)

def psCKernelRecursorNatTestSuccLiteral : Bool :=
  let expr := PsCKernelExpr.app
    (psCKernelRecursorNatConst "Nat.testRec")
    (psCKernelRecursorNatLit 3)
  psCKernelExprEqStructural
    (psCKernelExprWhnfBasic psCKernelRecursorNatEnv psCKernelLocalContextEmpty expr)
    (psCKernelRecursorNatLit 2)

def psCKernelRecursorNatTestOneLiteral : Bool :=
  let expr := PsCKernelExpr.app
    (psCKernelRecursorNatConst "Nat.testRec")
    (psCKernelRecursorNatLit 1)
  psCKernelExprEqStructural
    (psCKernelExprWhnfBasic psCKernelRecursorNatEnv psCKernelLocalContextEmpty expr)
    (psCKernelRecursorNatLit 0)

def psCKernelRecursorNatTestCtorStillReduces : Bool :=
  let expr := PsCKernelExpr.app
    (psCKernelRecursorNatConst "Nat.testRec")
    (PsCKernelExpr.app
      (psCKernelRecursorNatConst "Nat.succ")
      (psCKernelRecursorNatLit 8))
  psCKernelExprEqStructural
    (psCKernelExprWhnfBasic psCKernelRecursorNatEnv psCKernelLocalContextEmpty expr)
    (psCKernelRecursorNatLit 8)

def psCKernelRecursorNatLiteralTests : List PsCKernelRecursorNatLiteralNamedTest := [
  { name := "Nat literal zero selects Nat.zero rule", passed := psCKernelRecursorNatTestZeroLiteral },
  { name := "positive Nat literal selects Nat.succ rule", passed := psCKernelRecursorNatTestSuccLiteral },
  { name := "Nat literal one forwards zero predecessor literal", passed := psCKernelRecursorNatTestOneLiteral },
  { name := "explicit Nat.succ constructor still reduces", passed := psCKernelRecursorNatTestCtorStillReduces }
]

def psCKernelRunRecursorNatLiteralTests
    (tests : List PsCKernelRecursorNatLiteralNamedTest) : IO Bool :=
  match tests with
  | [] => pure true
  | test :: rest => do
      if test.passed then
        IO.println ("PSCKERNEL_RECURSOR_NAT_LITERAL_PASS: " ++ test.name)
      else
        IO.println ("PSCKERNEL_RECURSOR_NAT_LITERAL_FAIL: " ++ test.name)
      let restPassed ← psCKernelRunRecursorNatLiteralTests rest
      pure (test.passed && restPassed)

def main : IO Unit := do
  let passed ← psCKernelRunRecursorNatLiteralTests psCKernelRecursorNatLiteralTests
  if passed then
    IO.println "PSCKERNEL_RECURSOR_NAT_LITERAL_TESTS: PASS"
  else
    throw (IO.userError "PSCKERNEL_RECURSOR_NAT_LITERAL_TESTS: FAIL")
