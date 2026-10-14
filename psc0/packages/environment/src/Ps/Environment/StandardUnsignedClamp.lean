import Ps.Environment.StandardUnsignedOfInt

/-
Pinned Lean 4.35.0 Init/Data/UInt/BasicAux.lean and
Init/Data/BitVec/BasicAux.lean, commit
eb6cafb7290e8bd5f2937522d8d804f58f02bafc.
Copyright Lean FRO, LLC; Apache-2.0; see THIRD_PARTY_NOTICES.md.

UIntN.ofNatClamp n preserves n below 2^N and returns 2^N-1
otherwise. The checked Nat.lt/decLt and UIntN.ofNat models suffice
for the complete computation, including very large input Nats.
UIntN.ofNatTruncate is a deprecated synonym in the pinned Lean source.
Both are ordinary checked definitions with no new axiom, primitive or
backend-specific behavior.
-/

def psStandardUnsignedClampWidths : List (String × Nat) :=
  [("UInt8", 8), ("UInt16", 16),
   ("UInt32", 32), ("UInt64", 64)]

def psStandardUnsignedClampDeclarations : List PsDeclaration :=
  psStandardUnsignedClampWidths.flatMap fun (owner, width) =>
    let ty : PsExpr := .constE (psRootName owner) []
    let n : PsExpr := .fvar 0
    let limit : PsExpr := .lit (.natural (2 ^ width))
    let bound := psOrderCall "Nat.lt" [n, limit]
    let decBound := psOrderCall "Nat.decLt" [n, limit]
    let ofNat := fun val => psOrderCall (owner ++ ".ofNat") [val]
    let clamped := psLogicApply (.constE (psRootName "ite") [.succ .zero])
      [ty, bound, decBound, ofNat n, ofNat (.lit (.natural (2 ^ width - 1)))]
    let clamp : PsDeclaration := .definitionDecl
      (psNameAppendStr (psRootName owner) "ofNatClamp") []
      (psLogicPi 0 "n" psOrderNat ty)
      (psLogicLam 0 "n" psOrderNat clamped)
    let oldAlias : PsDeclaration := .definitionDecl
      (psNameAppendStr (psRootName owner) "ofNatTruncate") []
      (psLogicPi 0 "n" psOrderNat ty)
      (psLogicLam 0 "n" psOrderNat
        (psOrderCall (owner ++ ".ofNatClamp") [n]))
    [clamp, oldAlias]

def psStandardUnsignedClampExtend (environment : PsEnvironment) : PsEnvironment :=
  psStandardUnsignedClampDeclarations.foldl psEnvironmentInsert environment

def psStandardUnsignedClampRuntimeDeclarations : List PsDeclaration :=
  psStandardUnsignedClampDeclarations
