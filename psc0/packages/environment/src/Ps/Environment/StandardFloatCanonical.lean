import Ps.Environment.StandardUnsignedOperations

/-!
Native portable F1 bit helpers, not Float/Float32 source constructors.
Lean 4.35.0 at eb6cafb7290e8bd5f2937522d8d804f58f02bafc:
  Init/Data/Float/Model/Unpacked/Pack/Basic.lean: pack/unpack/packedNaN
  tests/elab/floatBits.lean: canonical positive quiet NaN, signed zero
These eight pure checked UInt32/UInt64 functions are small semantic units
reusable by a future checked Float source/IR layer. They never assert that a
UInt word is itself a Float, fabricate model.Valid evidence, perform a host
cast, or enable floating arithmetic. Both f32/f64 operations use the same
kernel-checked Boolean recursor, natural equality and selected UInt bitwise
operations; runtime parity is a *separate* mandatory CI gate.
-/

-- This common construction is parameterized over an exact pinned IEEE width.
-- The exponent is all ones and fraction is nonzero exactly for NaN. All NaN
-- signs/payloads map to the positive quiet NaN; all other bits are unchanged.
def psStandardFloatCanonicalPair (owner floatName : String)
    (exponentMask fractionMask canonicalNaN : Nat) : List PsDeclaration :=
  let word : PsExpr := .constE (psRootName owner) []
  let bool : PsExpr := .constE psBoolName []
  let bits : PsExpr := .fvar 0
  let wordOf := fun value : Nat =>
    psOrderCall (owner ++ ".ofNat") [.lit (.natural value)]
  let masked := fun mask : Nat =>
    psOrderCall (owner ++ ".land") [bits, wordOf mask]
  let natWord := fun expr : PsExpr =>
    psOrderCall (owner ++ ".toNat") [expr]
  let equals := fun expr target =>
    psOrderCall "Nat.beq" [natWord expr, .lit (.natural target)]
  let allExponent := equals (masked exponentMask) exponentMask
  let emptyFraction := equals (masked fractionMask) 0
  let select := fun (resultType ifFalse ifTrue condition : PsExpr) =>
    psLogicApply (.constE (psNameAppendStr psBoolName "rec") [.succ .zero])
      [psLogicLam 1 "_flag" bool resultType, ifFalse, ifTrue, condition]
  let yes : PsExpr := .constE psBoolTrueName []
  let no : PsExpr := .constE psBoolFalseName []
  let nanFlag := select bool no (select bool yes no emptyFraction) allExponent
  -- Pinned Lean Float.Model.UnpackedFloat classification:
  -- exp = all-ones + fraction = zero is ±inf, and exp != all-ones
  -- is finite, including both signed zeros and all subnormal numbers.
  -- NaN is exp = all-ones + fraction != zero; the sign is ignored.
  let infFlag := select bool no emptyFraction allExponent
  let finiteFlag := select bool yes no allExponent
  let normalized := select word bits
    (select word (wordOf canonicalNaN) bits emptyFraction) allExponent
  let declare := fun name result body =>
    PsDeclaration.definitionDecl (psDecisionName ("PsStandard." ++ name ++ floatName ++ "Bits")) []
      (psLogicPi 0 "bits" word result)
      (psLogicLam 0 "bits" word body)
  [declare "isNaN" bool nanFlag, declare "isInf" bool infFlag,
   declare "isFinite" bool finiteFlag, declare "canonical" word normalized]

def psStandardFloatCanonicalDeclarations : List PsDeclaration :=
  psStandardFloatCanonicalPair "UInt64" "Float64"
    9218868437227405312 4503599627370495 9221120237041090560 ++
  psStandardFloatCanonicalPair "UInt32" "Float32"
    2139095040 8388607 2143289344

def psStandardFloatCanonicalExtend (environment : PsEnvironment) : PsEnvironment :=
  psStandardFloatCanonicalDeclarations.foldl psEnvironmentInsert environment

def psStandardFloatCanonicalRuntimeDeclarations : List PsDeclaration :=
  psStandardFloatCanonicalDeclarations
