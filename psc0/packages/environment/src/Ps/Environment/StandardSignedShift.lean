import Ps.Environment.StandardSignedOfInt

/-
Pinned Lean 4.35.0 src/Init/Data/SInt/Basic.lean and
src/Init/Data/BitVec/Basic.lean, eb6cafb7290e8bd5f2937522d8d804f58f02bafc.
Copyright Lean FRO, LLC; Apache-2.0; see THIRD_PARTY_NOTICES.md.

Constructive fixed-width Nat arithmetic for signed shift operations.
Lean's IntN.shiftLeft/shiftRight use (b.toBitVec.smod width) as the shift
count; because width in {8,16,32,64} divides 2^width, that count is
exactly b.toUIntN.toNat % width even for negative b. The left shift
wraps the unsigned bit pattern. Arithmetic right shift divides by
2^count and, for a negative word, fills high bits with
2^width - 2^(width-count). No unchecked proof or native assumption.

Source and runtime equivalence to the official Lean 4.35.0 operation
values are independently checked by the signed native oracle and
JS/TS/Rust/Wasm observation corpus; open-term semantic equivalence
is not claimed to be a separately imported native theorem.
-/

def psStandardSignedShiftDeclarations : List PsDeclaration :=
  [("Int8", "UInt8", 8), ("Int16", "UInt16", 16),
   ("Int32", "UInt32", 32), ("Int64", "UInt64", 64)].flatMap
    fun (owner, unsigned, width) =>
      let signedType : PsExpr := .constE (psRootName owner) []
      let natType : PsExpr := psOrderNat
      let left : PsExpr := .fvar 0
      let right : PsExpr := .fvar 1
      let bits := fun value =>
        psOrderCall (unsigned ++ ".toNat")
          [psOrderCall (owner ++ ".to" ++ unsigned) [value]]
      let a := bits left
      let b := bits right
      let shift := psOrderCall "Nat.mod" [b, .lit (.natural width)]
      let divisor := psOrderCall "Nat.pow" [.lit (.natural 2), shift]
      let leftResult := psOrderCall (owner ++ ".ofNat")
        [psOrderCall "Nat.mul" [a, divisor]]
      let half : PsExpr := .lit (.natural (2 ^ width))
      let nonnegative := psOrderCall "Nat.lt"
        [psOrderCall "Nat.mul" [.lit (.natural 2), a], half]
      let nonnegativeDecision := psOrderCall "Nat.decLt"
        [psOrderCall "Nat.mul" [.lit (.natural 2), a], half]
      let low := psOrderCall "Nat.div" [a, divisor]
      let highBits := psOrderCall "Nat.sub"
        [half, psOrderCall "Nat.pow"
          [.lit (.natural 2),
           psOrderCall "Nat.sub" [.lit (.natural width), shift]]]
      let shiftedBits := psLogicApply
        (.constE (psRootName "ite") [.succ .zero])
        [natType, nonnegative, nonnegativeDecision,
         low, psOrderCall "Nat.add" [low, highBits]]
      let rightResult := psOrderCall (owner ++ ".ofNat") [shiftedBits]
      let signature := psLogicPi 0 "a" signedType
        (psLogicPi 1 "b" signedType signedType)
      let operation := fun name body =>
        PsDeclaration.definitionDecl (psNameAppendStr (psRootName owner) name) []
          signature
          (psLogicLam 0 "a" signedType
            (psLogicLam 1 "b" signedType body))
      [operation "shiftLeft" leftResult,
       operation "shiftRight" rightResult]

def psStandardSignedShiftExtend (environment : PsEnvironment) : PsEnvironment :=
  -- These upstream methods have default semireducible status.
  psStandardSignedShiftDeclarations.foldl psEnvironmentInsert environment

def psStandardSignedShiftRuntimeDeclarations : List PsDeclaration :=
  psStandardSignedShiftDeclarations
