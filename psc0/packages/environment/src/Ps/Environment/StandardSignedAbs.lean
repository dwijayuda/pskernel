import Ps.Environment.StandardSignedClamp

/-
Pinned Lean 4.35.0 Init/Data/SInt/Basic.lean and
Init/Data/BitVec/Basic.lean at
eb6cafb7290e8bd5f2937522d8d804f58f02bafc.
Copyright Lean FRO, LLC; Apache-2.0; see THIRD_PARTY_NOTICES.md.

The native signed-word absolute value is BitVec.abs:
if the sign bit is set, negate the fixed-width carrier; otherwise keep it.
For width in {8,16,32,64}, the sign is exactly (2 * rawBits < 2^width).
The construction below preserves wrapping of the minimum signed word.
Only existing Nat comparison/decision and signed negation are used.
No new axiom or target-specific operator is introduced.
-/

def psStandardSignedAbsDeclarations : List PsDeclaration :=
  [("Int8", "UInt8", 8), ("Int16", "UInt16", 16),
   ("Int32", "UInt32", 32), ("Int64", "UInt64", 64)].map
    fun (owner, unsigned, width) =>
      let signedType : PsExpr := .constE (psRootName owner) []
      let value : PsExpr := .fvar 0
      let bits : PsExpr := psOrderCall (unsigned ++ ".toNat")
        [psOrderCall (owner ++ ".to" ++ unsigned) [value]]
      let twice := psOrderCall "Nat.mul" [.lit (.natural 2), bits]
      let boundary : PsExpr := .lit (.natural (2 ^ width))
      let nonnegative := psOrderCall "Nat.lt" [twice, boundary]
      let decision := psOrderCall "Nat.decLt" [twice, boundary]
      let result := psLogicApply
        (.constE (psRootName "ite") [.succ .zero])
        [signedType, nonnegative, decision, value,
         psOrderCall (owner ++ ".neg") [value]]
      .definitionDecl (psNameAppendStr (psRootName owner) "abs") []
        (psLogicPi 0 "value" signedType signedType)
        (psLogicLam 0 "value" signedType result)

def psStandardSignedAbsExtend (environment : PsEnvironment) : PsEnvironment :=
  -- The upstream IntN.abs definitions are semireducible.
  psStandardSignedAbsDeclarations.foldl psEnvironmentInsert environment

def psStandardSignedAbsRuntimeDeclarations : List PsDeclaration :=
  psStandardSignedAbsDeclarations
