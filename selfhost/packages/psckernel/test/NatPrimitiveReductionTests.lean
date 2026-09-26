import Ps.PSCKernel.Core.ReductionBasic

structure PsCKernelNatPrimitiveNamedTest where
  name : String
  passed : Bool

def psCKernelNatPrimitiveName (text : String) : PsCKernelName :=
  psCKernelNameFromDotted text

def psCKernelNatPrimitiveConst (text : String) : PsCKernelExpr :=
  PsCKernelExpr.constE (psCKernelNatPrimitiveName text) []

def psCKernelNatPrimitiveLit (value : Nat) : PsCKernelExpr :=
  PsCKernelExpr.lit (PsCKernelLiteral.natVal value)

def psCKernelNatPrimitiveUnary
    (name : String)
    (arg : PsCKernelExpr) : PsCKernelExpr :=
  PsCKernelExpr.app (psCKernelNatPrimitiveConst name) arg

def psCKernelNatPrimitiveBinary
    (name : String)
    (left : PsCKernelExpr)
    (right : PsCKernelExpr) : PsCKernelExpr :=
  psCKernelExprMkAppN
    (psCKernelNatPrimitiveConst name)
    [left, right]

def psCKernelNatPrimitiveWhnf (expr : PsCKernelExpr) : PsCKernelExpr :=
  psCKernelExprWhnfBasic
    psCKernelEnvironmentEmpty
    psCKernelLocalContextEmpty
    expr

def psCKernelNatPrimitiveEqLit (expr : PsCKernelExpr) (value : Nat) : Bool :=
  psCKernelExprEqStructural
    (psCKernelNatPrimitiveWhnf expr)
    (psCKernelNatPrimitiveLit value)

def psCKernelNatPrimitiveTestSucc : Bool :=
  psCKernelNatPrimitiveEqLit
    (psCKernelNatPrimitiveUnary "Nat.succ" (psCKernelNatPrimitiveLit 2))
    3

def psCKernelNatPrimitiveTestAdd : Bool :=
  psCKernelNatPrimitiveEqLit
    (psCKernelNatPrimitiveBinary "Nat.add" (psCKernelNatPrimitiveLit 2) (psCKernelNatPrimitiveLit 3))
    5

def psCKernelNatPrimitiveTestSubSaturates : Bool :=
  psCKernelNatPrimitiveEqLit
    (psCKernelNatPrimitiveBinary "Nat.sub" (psCKernelNatPrimitiveLit 2) (psCKernelNatPrimitiveLit 5))
    0

def psCKernelNatPrimitiveTestMul : Bool :=
  psCKernelNatPrimitiveEqLit
    (psCKernelNatPrimitiveBinary "Nat.mul" (psCKernelNatPrimitiveLit 3) (psCKernelNatPrimitiveLit 4))
    12

def psCKernelNatPrimitiveTestPow : Bool :=
  psCKernelNatPrimitiveEqLit
    (psCKernelNatPrimitiveBinary "Nat.pow" (psCKernelNatPrimitiveLit 2) (psCKernelNatPrimitiveLit 5))
    32

def psCKernelNatPrimitiveTestGcd : Bool :=
  psCKernelNatPrimitiveEqLit
    (psCKernelNatPrimitiveBinary "Nat.gcd" (psCKernelNatPrimitiveLit 12) (psCKernelNatPrimitiveLit 18))
    6

def psCKernelNatPrimitiveTestMod : Bool :=
  psCKernelNatPrimitiveEqLit
    (psCKernelNatPrimitiveBinary "Nat.mod" (psCKernelNatPrimitiveLit 17) (psCKernelNatPrimitiveLit 5))
    2

def psCKernelNatPrimitiveTestModZero : Bool :=
  psCKernelNatPrimitiveEqLit
    (psCKernelNatPrimitiveBinary "Nat.mod" (psCKernelNatPrimitiveLit 17) (psCKernelNatPrimitiveLit 0))
    17

def psCKernelNatPrimitiveTestDiv : Bool :=
  psCKernelNatPrimitiveEqLit
    (psCKernelNatPrimitiveBinary "Nat.div" (psCKernelNatPrimitiveLit 17) (psCKernelNatPrimitiveLit 5))
    3

def psCKernelNatPrimitiveTestDivZero : Bool :=
  psCKernelNatPrimitiveEqLit
    (psCKernelNatPrimitiveBinary "Nat.div" (psCKernelNatPrimitiveLit 17) (psCKernelNatPrimitiveLit 0))
    0

def psCKernelNatPrimitiveTestLand : Bool :=
  psCKernelNatPrimitiveEqLit
    (psCKernelNatPrimitiveBinary "Nat.land" (psCKernelNatPrimitiveLit 6) (psCKernelNatPrimitiveLit 3))
    2

def psCKernelNatPrimitiveTestLor : Bool :=
  psCKernelNatPrimitiveEqLit
    (psCKernelNatPrimitiveBinary "Nat.lor" (psCKernelNatPrimitiveLit 4) (psCKernelNatPrimitiveLit 1))
    5

def psCKernelNatPrimitiveTestXor : Bool :=
  psCKernelNatPrimitiveEqLit
    (psCKernelNatPrimitiveBinary "Nat.xor" (psCKernelNatPrimitiveLit 6) (psCKernelNatPrimitiveLit 3))
    5

def psCKernelNatPrimitiveTestShiftLeft : Bool :=
  psCKernelNatPrimitiveEqLit
    (psCKernelNatPrimitiveBinary "Nat.shiftLeft" (psCKernelNatPrimitiveLit 3) (psCKernelNatPrimitiveLit 2))
    12

def psCKernelNatPrimitiveTestShiftRight : Bool :=
  psCKernelNatPrimitiveEqLit
    (psCKernelNatPrimitiveBinary "Nat.shiftRight" (psCKernelNatPrimitiveLit 12) (psCKernelNatPrimitiveLit 2))
    3

def psCKernelNatPrimitiveTestBeq : Bool :=
  psCKernelExprEqStructural
    (psCKernelNatPrimitiveWhnf
      (psCKernelNatPrimitiveBinary "Nat.beq" (psCKernelNatPrimitiveLit 4) (psCKernelNatPrimitiveLit 4)))
    (psCKernelNatPrimitiveConst "Bool.true")

def psCKernelNatPrimitiveTestBle : Bool :=
  psCKernelExprEqStructural
    (psCKernelNatPrimitiveWhnf
      (psCKernelNatPrimitiveBinary "Nat.ble" (psCKernelNatPrimitiveLit 5) (psCKernelNatPrimitiveLit 3)))
    (psCKernelNatPrimitiveConst "Bool.false")

def psCKernelNatPrimitiveTestWhnfOperand : Bool :=
  let left := PsCKernelExpr.letE
    (psCKernelNatPrimitiveName "x")
    (psCKernelNatPrimitiveConst "Nat")
    (psCKernelNatPrimitiveLit 2)
    (PsCKernelExpr.bvar 0)
    false
  psCKernelNatPrimitiveEqLit
    (psCKernelNatPrimitiveBinary "Nat.add" left (psCKernelNatPrimitiveLit 3))
    5

def psCKernelNatPrimitiveTestUnknownOperandStuck : Bool :=
  let expr := psCKernelNatPrimitiveBinary
    "Nat.add"
    (psCKernelNatPrimitiveConst "unknownNat")
    (psCKernelNatPrimitiveLit 3)
  psCKernelExprEqStructural
    (psCKernelNatPrimitiveWhnf expr)
    expr

def psCKernelNatPrimitiveReductionTests : List PsCKernelNatPrimitiveNamedTest := [
  { name := "Nat.succ reduces literal operand", passed := psCKernelNatPrimitiveTestSucc },
  { name := "Nat.add reduces literal operands", passed := psCKernelNatPrimitiveTestAdd },
  { name := "Nat.sub saturates at zero", passed := psCKernelNatPrimitiveTestSubSaturates },
  { name := "Nat.mul reduces literal operands", passed := psCKernelNatPrimitiveTestMul },
  { name := "Nat.pow reduces literal operands", passed := psCKernelNatPrimitiveTestPow },
  { name := "Nat.gcd reduces literal operands", passed := psCKernelNatPrimitiveTestGcd },
  { name := "Nat.mod reduces literal operands", passed := psCKernelNatPrimitiveTestMod },
  { name := "Nat.mod by zero returns dividend", passed := psCKernelNatPrimitiveTestModZero },
  { name := "Nat.div reduces literal operands", passed := psCKernelNatPrimitiveTestDiv },
  { name := "Nat.div by zero returns zero", passed := psCKernelNatPrimitiveTestDivZero },
  { name := "Nat.land reduces literal operands", passed := psCKernelNatPrimitiveTestLand },
  { name := "Nat.lor reduces literal operands", passed := psCKernelNatPrimitiveTestLor },
  { name := "Nat.xor reduces literal operands", passed := psCKernelNatPrimitiveTestXor },
  { name := "Nat.shiftLeft reduces literal operands", passed := psCKernelNatPrimitiveTestShiftLeft },
  { name := "Nat.shiftRight reduces literal operands", passed := psCKernelNatPrimitiveTestShiftRight },
  { name := "Nat.beq returns Bool.true for equal literals", passed := psCKernelNatPrimitiveTestBeq },
  { name := "Nat.ble returns Bool.false for descending literals", passed := psCKernelNatPrimitiveTestBle },
  { name := "Nat primitive operands are weak-head reduced", passed := psCKernelNatPrimitiveTestWhnfOperand },
  { name := "Nat primitive with non-numeral operand stays stuck", passed := psCKernelNatPrimitiveTestUnknownOperandStuck }
]

def psCKernelRunNatPrimitiveReductionTests
    (tests : List PsCKernelNatPrimitiveNamedTest) : IO Bool :=
  match tests with
  | [] => pure true
  | test :: rest => do
      if test.passed then
        IO.println ("PSCKERNEL_NAT_PRIMITIVE_REDUCTION_PASS: " ++ test.name)
      else
        IO.println ("PSCKERNEL_NAT_PRIMITIVE_REDUCTION_FAIL: " ++ test.name)
      let restPassed ← psCKernelRunNatPrimitiveReductionTests rest
      pure (test.passed && restPassed)

def main : IO Unit := do
  let passed ← psCKernelRunNatPrimitiveReductionTests psCKernelNatPrimitiveReductionTests
  if passed then
    IO.println "PSCKERNEL_NAT_PRIMITIVE_REDUCTION_TESTS: PASS"
  else
    throw (IO.userError "PSCKERNEL_NAT_PRIMITIVE_REDUCTION_TESTS: FAIL")
