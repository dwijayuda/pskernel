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
-- Shared, checked Bool recursor. All callers have a genuine Bool
-- condition; no Boolean test fabricates a proof of a proposition.
def psStandardFloatBitSelect (resultType ifFalse ifTrue condition : PsExpr) : PsExpr :=
  psLogicApply (.constE (psNameAppendStr psBoolName "rec") [.succ .zero])
    [psLogicLam 1 "_flag" (.constE psBoolName []) resultType,
     ifFalse, ifTrue, condition]

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
  let select := psStandardFloatBitSelect
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

-- Pinned Lean 4.35.0 Float.Model.UnpackedFloat.Compare defines IEEE BEq
-- through compare == some eq: NaNs never compare equal and signed zeros do.
-- The proof-carrying Float/Float32.Model structures instead have canonical
-- bit identity: both NaNs normalize first, signed zeros remain distinct.
-- These are Bool-valued *bit model functions*, not Eq proof constructors
-- or BEq/DecidableEq instances for source-level Float types.
def psStandardFloatBitEqualityPair (owner floatName : String)
    (magnitudeMask : Nat) : List PsDeclaration :=
  let word : PsExpr := .constE (psRootName owner) []
  let bool : PsExpr := .constE psBoolName []
  let left : PsExpr := .fvar 0
  let right : PsExpr := .fvar 1
  let no : PsExpr := .constE psBoolFalseName []
  let yes : PsExpr := .constE psBoolTrueName []
  let natValue := fun value : PsExpr =>
    psOrderCall (owner ++ ".toNat") [value]
  let eqNat := fun a b =>
    psOrderCall "Nat.beq" [a, b]
  let signless := fun value : PsExpr =>
    psOrderCall (owner ++ ".land")
      [value, psOrderCall (owner ++ ".ofNat") [.lit (.natural magnitudeMask)]]
  let isZero := fun value =>
    eqNat (natValue (signless value)) (.lit (.natural 0))
  let rawEqual := eqNat (natValue left) (natValue right)
  let bothZeroEqual := psStandardFloatBitSelect bool rawEqual
    (psStandardFloatBitSelect bool rawEqual yes (isZero right))
    (isZero left)
  let noNaNRight := psStandardFloatBitSelect bool bothZeroEqual no
    (psOrderCall ("PsStandard.isNaN" ++ floatName ++ "Bits") [right])
  let ieeeEqual := psStandardFloatBitSelect bool noNaNRight no
    (psOrderCall ("PsStandard.isNaN" ++ floatName ++ "Bits") [left])
  let canonical := fun value =>
    psOrderCall ("PsStandard.canonical" ++ floatName ++ "Bits") [value]
  let logicalEqual := eqNat (natValue (canonical left))
    (natValue (canonical right))
  let declare := fun name body =>
    PsDeclaration.definitionDecl
      (psDecisionName ("PsStandard." ++ name ++ floatName ++ "Bits")) []
      (psLogicPi 0 "left" word (psLogicPi 1 "right" word bool))
      (psLogicLam 0 "left" word (psLogicLam 1 "right" word body))
  [declare "beq" ieeeEqual, declare "logicalEq" logicalEqual]

def psStandardFloatCanonicalDeclarations : List PsDeclaration :=
  psStandardFloatCanonicalPair "UInt64" "Float64"
    9218868437227405312 4503599627370495 9221120237041090560 ++
  psStandardFloatCanonicalPair "UInt32" "Float32"
    2139095040 8388607 2143289344 ++
  psStandardFloatBitEqualityPair "UInt64" "Float64"
    9223372036854775807 ++
  psStandardFloatBitEqualityPair "UInt32" "Float32"
    2147483647

def psStandardFloatCanonicalExtend (environment : PsEnvironment) : PsEnvironment :=
  psStandardFloatCanonicalDeclarations.foldl psEnvironmentInsert environment

def psStandardFloatCanonicalRuntimeDeclarations : List PsDeclaration :=
  psStandardFloatCanonicalDeclarations
