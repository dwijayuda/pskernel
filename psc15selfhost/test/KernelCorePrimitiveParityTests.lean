import Ps.KernelCore.Primitive
import PSC1Kernel.TypeChecker

partial def psKernelCorePrimitiveNameMatches
    (left : PsKernelCoreName)
    (right : PSC1Kernel.Name) : Bool :=
  match left, right with
  | PsKernelCoreName.anonymous, PSC1Kernel.Name.anonymous => true
  | PsKernelCoreName.str lp ls, PSC1Kernel.Name.str rp rs =>
      psKernelCorePrimitiveNameMatches lp rp && ls == rs
  | PsKernelCoreName.num lp ln, PSC1Kernel.Name.num rp rn =>
      psKernelCorePrimitiveNameMatches lp rp && ln == rn
  | _, _ => false

def psKernelCorePrimitiveExprMatches
    (left : PsKernelCoreExpr)
    (right : PSC1Kernel.Expr) : Bool :=
  match left, right with
  | PsKernelCoreExpr.lit (PsKernelCoreLiteral.nat l),
      PSC1Kernel.Expr.lit (PSC1Kernel.Literal.nat r) => l == r
  | PsKernelCoreExpr.const ln ll, PSC1Kernel.Expr.const rn rl =>
      psKernelCorePrimitiveNameMatches ln rn &&
        match ll, rl with
        | PsKernelCoreList.nil, [] => true
        | _, _ => false
  | _, _ => false

def psKernelCorePrimitiveOptionNatMatches
    (left : PsKernelCoreOption Nat)
    (right : Option Nat) : Bool :=
  match left, right with
  | PsKernelCoreOption.none, none => true
  | PsKernelCoreOption.some l, some r => l == r
  | _, _ => false

def psKernelCorePrimitiveOptionExprMatches
    (left : PsKernelCoreOption PsKernelCoreExpr)
    (right : Option PSC1Kernel.Expr) : Bool :=
  match left, right with
  | PsKernelCoreOption.none, none => true
  | PsKernelCoreOption.some l, some r =>
      psKernelCorePrimitiveExprMatches l r
  | _, _ => false

def psKernelCorePrimitiveResultMatches
    (left : PsKernelCoreResult String (PsKernelCoreOption PsKernelCoreExpr))
    (right : Except String (Option PSC1Kernel.Expr)) : Bool :=
  match left, right with
  | PsKernelCoreResult.error l, Except.error r => l == r
  | PsKernelCoreResult.ok l, Except.ok r =>
      psKernelCorePrimitiveOptionExprMatches l r
  | _, _ => false

def psKernelCorePrimitiveExpectedResult
    (left : PsKernelCoreResult String (PsKernelCoreOption PsKernelCoreExpr))
    (expected : PsKernelCoreExpr) : Bool :=
  match left with
  | PsKernelCoreResult.ok (PsKernelCoreOption.some actual) =>
      psKernelCoreExprEq actual expected
  | _ => false

def psKernelCorePrimitiveExpectedError
    (left : PsKernelCoreResult String (PsKernelCoreOption PsKernelCoreExpr))
    (expected : String) : Bool :=
  match left with
  | PsKernelCoreResult.error actual => actual == expected
  | _ => false

def psKernelCorePrimitiveResultIsNone
    (left : PsKernelCoreResult String (PsKernelCoreOption PsKernelCoreExpr)) : Bool :=
  match left with
  | PsKernelCoreResult.ok PsKernelCoreOption.none => true
  | _ => false

def psKernelCorePrimitiveReferenceBinary
    (resources : PsKernelCoreResourceConfig)
    (kernelName : PsKernelCoreName)
    (referenceName : PSC1Kernel.Name)
    (left right : Nat) : Bool :=
  psKernelCorePrimitiveResultMatches
    (psKernelCoreReduceNatBinary resources kernelName left right)
    (PSC1Kernel.reduceNatBinary resources.maxNatSize referenceName left right)

def psKernelCorePrimitiveUnaryParity
    (resources : PsKernelCoreResourceConfig)
    (value : Nat) : Bool :=
  let referenceCtx := {
    PSC1Kernel.CheckerContext.empty PSC1Kernel.Environment.empty with
    maxNatSize := resources.maxNatSize
  }
  let referenceExpr :=
    PSC1Kernel.Expr.app
      (PSC1Kernel.Expr.const PSC1Kernel.kernelNatSuccName [])
      (PSC1Kernel.Expr.lit (PSC1Kernel.Literal.nat value))
  psKernelCorePrimitiveResultMatches
    (psKernelCoreReduceNatUnary
      resources psKernelCorePrimitiveNatSuccName value)
    (PSC1Kernel.reduceNat referenceCtx referenceExpr)

def psKernelCorePrimitiveNamesParity : Bool :=
  psKernelCorePrimitiveNameMatches
      psKernelCorePrimitiveNatName PSC1Kernel.kernelNatName &&
  psKernelCorePrimitiveNameMatches
      psKernelCorePrimitiveBoolName PSC1Kernel.kernelBoolName &&
  psKernelCorePrimitiveNameMatches
      psKernelCorePrimitiveBoolTrueName PSC1Kernel.kernelBoolTrueName &&
  psKernelCorePrimitiveNameMatches
      psKernelCorePrimitiveBoolFalseName PSC1Kernel.kernelBoolFalseName &&
  psKernelCorePrimitiveNameMatches
      psKernelCorePrimitiveNatZeroName PSC1Kernel.kernelNatZeroName &&
  psKernelCorePrimitiveNameMatches
      psKernelCorePrimitiveNatSuccName PSC1Kernel.kernelNatSuccName &&
  psKernelCorePrimitiveNameMatches
      psKernelCorePrimitiveNatAddName PSC1Kernel.kernelNatAddName &&
  psKernelCorePrimitiveNameMatches
      psKernelCorePrimitiveNatSubName PSC1Kernel.kernelNatSubName &&
  psKernelCorePrimitiveNameMatches
      psKernelCorePrimitiveNatMulName PSC1Kernel.kernelNatMulName &&
  psKernelCorePrimitiveNameMatches
      psKernelCorePrimitiveNatPowName PSC1Kernel.kernelNatPowName &&
  psKernelCorePrimitiveNameMatches
      psKernelCorePrimitiveNatGcdName PSC1Kernel.kernelNatGcdName &&
  psKernelCorePrimitiveNameMatches
      psKernelCorePrimitiveNatModName PSC1Kernel.kernelNatModName &&
  psKernelCorePrimitiveNameMatches
      psKernelCorePrimitiveNatDivName PSC1Kernel.kernelNatDivName &&
  psKernelCorePrimitiveNameMatches
      psKernelCorePrimitiveNatBeqName PSC1Kernel.kernelNatBeqName &&
  psKernelCorePrimitiveNameMatches
      psKernelCorePrimitiveNatBleName PSC1Kernel.kernelNatBleName

def psKernelCorePrimitiveRecognitionParity : Bool :=
  let klit0 := PsKernelCoreExpr.lit (PsKernelCoreLiteral.nat 0)
  let klit7 := PsKernelCoreExpr.lit (PsKernelCoreLiteral.nat 7)
  let kzero :=
    PsKernelCoreExpr.const
      psKernelCorePrimitiveNatZeroName PsKernelCoreList.nil
  let ksucc7 :=
    PsKernelCoreExpr.app
      (PsKernelCoreExpr.const
        psKernelCorePrimitiveNatSuccName PsKernelCoreList.nil)
      klit7
  let kother := PsKernelCoreExpr.sort PsKernelCoreLevel.zero
  let rlit0 := PSC1Kernel.Expr.lit (PSC1Kernel.Literal.nat 0)
  let rlit7 := PSC1Kernel.Expr.lit (PSC1Kernel.Literal.nat 7)
  let rzero := PSC1Kernel.Expr.const PSC1Kernel.kernelNatZeroName []
  let rsucc7 :=
    PSC1Kernel.Expr.app
      (PSC1Kernel.Expr.const PSC1Kernel.kernelNatSuccName [])
      rlit7
  let rother := PSC1Kernel.Expr.sort PSC1Kernel.Level.zero
  psKernelCorePrimitiveOptionNatMatches
      (psKernelCoreNatLiteralValue? klit0)
      (PSC1Kernel.natLiteralValue? rlit0) &&
  psKernelCorePrimitiveOptionNatMatches
      (psKernelCoreNatLiteralValue? klit7)
      (PSC1Kernel.natLiteralValue? rlit7) &&
  psKernelCorePrimitiveOptionNatMatches
      (psKernelCoreNatLiteralValue? kzero)
      (PSC1Kernel.natLiteralValue? rzero) &&
  psKernelCoreIsNatZeroExpr klit0 == PSC1Kernel.isNatZeroExpr rlit0 &&
  psKernelCoreIsNatZeroExpr kzero == PSC1Kernel.isNatZeroExpr rzero &&
  psKernelCoreIsNatZeroExpr klit7 == PSC1Kernel.isNatZeroExpr rlit7 &&
  psKernelCorePrimitiveOptionExprMatches
      (psKernelCoreNatPredExpr? klit7)
      (PSC1Kernel.natPredExpr? rlit7) &&
  psKernelCorePrimitiveOptionExprMatches
      (psKernelCoreNatPredExpr? ksucc7)
      (PSC1Kernel.natPredExpr? rsucc7) &&
  psKernelCorePrimitiveOptionExprMatches
      (psKernelCoreNatPredExpr? kother)
      (PSC1Kernel.natPredExpr? rother)

def psKernelCorePrimitiveOrdinaryParity : Bool :=
  let resources := psKernelCoreResourceConfigDefault
  psKernelCorePrimitiveUnaryParity resources 0 &&
  psKernelCorePrimitiveUnaryParity resources 7 &&
  psKernelCorePrimitiveReferenceBinary
      resources psKernelCorePrimitiveNatAddName PSC1Kernel.kernelNatAddName 7 5 &&
  psKernelCorePrimitiveReferenceBinary
      resources psKernelCorePrimitiveNatSubName PSC1Kernel.kernelNatSubName 5 7 &&
  psKernelCorePrimitiveReferenceBinary
      resources psKernelCorePrimitiveNatSubName PSC1Kernel.kernelNatSubName 9 4 &&
  psKernelCorePrimitiveReferenceBinary
      resources psKernelCorePrimitiveNatMulName PSC1Kernel.kernelNatMulName 7 6 &&
  psKernelCorePrimitiveReferenceBinary
      resources psKernelCorePrimitiveNatPowName PSC1Kernel.kernelNatPowName 3 5 &&
  psKernelCorePrimitiveReferenceBinary
      resources psKernelCorePrimitiveNatGcdName PSC1Kernel.kernelNatGcdName 84 30 &&
  psKernelCorePrimitiveReferenceBinary
      resources psKernelCorePrimitiveNatModName PSC1Kernel.kernelNatModName 17 5 &&
  psKernelCorePrimitiveReferenceBinary
      resources psKernelCorePrimitiveNatModName PSC1Kernel.kernelNatModName 17 0 &&
  psKernelCorePrimitiveReferenceBinary
      resources psKernelCorePrimitiveNatDivName PSC1Kernel.kernelNatDivName 17 5 &&
  psKernelCorePrimitiveReferenceBinary
      resources psKernelCorePrimitiveNatDivName PSC1Kernel.kernelNatDivName 17 0 &&
  psKernelCorePrimitiveReferenceBinary
      resources psKernelCorePrimitiveNatBeqName PSC1Kernel.kernelNatBeqName 7 7 &&
  psKernelCorePrimitiveReferenceBinary
      resources psKernelCorePrimitiveNatBeqName PSC1Kernel.kernelNatBeqName 7 8 &&
  psKernelCorePrimitiveReferenceBinary
      resources psKernelCorePrimitiveNatBleName PSC1Kernel.kernelNatBleName 7 8 &&
  psKernelCorePrimitiveReferenceBinary
      resources psKernelCorePrimitiveNatBleName PSC1Kernel.kernelNatBleName 9 8

def psKernelCorePrimitiveUnknownIsResidual : Bool :=
  let unknown :=
    PsKernelCoreName.str PsKernelCoreName.anonymous "notAPrimitive"
  psKernelCorePrimitiveResultIsNone
    (psKernelCoreReduceNatBinary
      psKernelCoreResourceConfigDefault unknown 2 3)

def psKernelCorePrimitiveResourceBoundaries : Bool :=
  let tiny : PsKernelCoreResourceConfig := { maxNatSize := 8 }
  let two32 := 2 ^ 32
  let two64 := 2 ^ 64
  let maxOneWord := two64 - 1
  let sizeError :=
    "the kernel refused a Nat numeral because its size exceeds the maximum"
  psKernelCorePrimitiveExpectedResult
      (psKernelCoreReduceNatUnary
        tiny psKernelCorePrimitiveNatSuccName (maxOneWord - 1))
      (PsKernelCoreExpr.lit (PsKernelCoreLiteral.nat maxOneWord)) &&
  psKernelCorePrimitiveExpectedError
      (psKernelCoreReduceNatUnary
        tiny psKernelCorePrimitiveNatSuccName maxOneWord)
      sizeError &&
  psKernelCorePrimitiveExpectedResult
      (psKernelCoreReduceNatBinary
        tiny psKernelCorePrimitiveNatAddName (maxOneWord - 1) 1)
      (PsKernelCoreExpr.lit (PsKernelCoreLiteral.nat maxOneWord)) &&
  psKernelCorePrimitiveExpectedError
      (psKernelCoreReduceNatBinary
        tiny psKernelCorePrimitiveNatAddName maxOneWord 1)
      sizeError &&
  psKernelCorePrimitiveExpectedResult
      (psKernelCoreReduceNatBinary
        tiny psKernelCorePrimitiveNatMulName (two32 - 1) (two32 - 1))
      (PsKernelCoreExpr.lit
        (PsKernelCoreLiteral.nat ((two32 - 1) * (two32 - 1)))) &&
  psKernelCorePrimitiveExpectedError
      (psKernelCoreReduceNatBinary
        tiny psKernelCorePrimitiveNatMulName two32 two32)
      sizeError

def psKernelCorePrimitivePowOrdering : Bool :=
  let resources := psKernelCoreResourceConfigDefault
  let tooLarge := psKernelCoreLeanUInt32Max + 1
  let countError :=
    "the kernel refused to evaluate Nat.pow because its second argument does not fit in a 32-bit unsigned integer"
  let tiny : PsKernelCoreResourceConfig := { maxNatSize := 8 }
  let growthError :=
    "the kernel refused to evaluate Nat.pow because the result would exceed the maximum numeral size"
  psKernelCorePrimitiveExpectedResult
      (psKernelCoreReduceNatBinary
        resources psKernelCorePrimitiveNatPowName 1 psKernelCoreLeanUInt32Max)
      (PsKernelCoreExpr.lit (PsKernelCoreLiteral.nat 1)) &&
  psKernelCorePrimitiveExpectedError
      (psKernelCoreReduceNatBinary
        resources psKernelCorePrimitiveNatPowName 0 tooLarge)
      countError &&
  psKernelCorePrimitiveExpectedError
      (psKernelCoreReduceNatBinary
        resources psKernelCorePrimitiveNatPowName 1 tooLarge)
      countError &&
  psKernelCorePrimitiveExpectedError
      (psKernelCoreReduceNatBinary
        tiny psKernelCorePrimitiveNatPowName (2 ^ 64) 1)
      growthError

def psKernelCorePrimitiveParity : Bool :=
  psKernelCorePrimitiveNamesParity &&
  psKernelCorePrimitiveRecognitionParity &&
  psKernelCorePrimitiveOrdinaryParity &&
  psKernelCorePrimitiveUnknownIsResidual &&
  psKernelCorePrimitiveResourceBoundaries &&
  psKernelCorePrimitivePowOrdering

def main : IO Unit := do
  if !psKernelCorePrimitiveParity then
    throw (IO.userError "PSC2_KERNEL_CORE_PRIMITIVE_PARITY: FAIL")
  IO.println "PSC2_KERNEL_CORE_PRIMITIVE_PARITY: PASS"
