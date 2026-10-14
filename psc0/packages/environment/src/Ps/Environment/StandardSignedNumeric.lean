import Ps.Environment.StandardSignedOrder

/-
Pinned Lean 4.35.0 src/Init/Data/SInt/Basic.lean,
commit eb6cafb7290e8bd5f2937522d8d804f58f02bafc.
Copyright Lean FRO, LLC; Apache-2.0; see THIRD_PARTY_NOTICES.md.

Finite signed size, minimum/maximum values and wrapping power for
Int8/Int16/Int32/Int64. Lean's IntN.pow is primitive recursion on Nat:
  pow x 0 = 1
  pow x (n+1) = mul (pow x n) x
and the extrema are the two's-complement residues of 2^(w-1)-1
and 2^(w-1), respectively. Nat.rec and each IntN method were selected
and checked earlier. Avoid host-width assumptions, new primitives or
unchecked semantic shortcuts. Native/original source and targets must be
qualified independently before these methods are a release capability.
-/

def psStandardSignedNumericWidths : List (String × Nat) :=
  [("Int8", 8), ("Int16", 16), ("Int32", 32), ("Int64", 64)]

def psStandardSignedNumericDeclarations : List PsDeclaration :=
  psStandardSignedNumericWidths.flatMap fun (owner, width) =>
    let name := psRootName owner
    let signedType : PsExpr := .constE name []
    let ofNat := fun (n : Nat) =>
      psOrderCall (owner ++ ".ofNat") [.lit (.natural n)]
    let cardinality := 2 ^ width
    let half := 2 ^ (width - 1)
    let size : PsDeclaration := .definitionDecl
      (psNameAppendStr name "size") [] psOrderNat (.lit (.natural cardinality))
    let minimum : PsDeclaration := .definitionDecl
      (psNameAppendStr name "minValue") [] signedType (ofNat half)
    let maximum : PsDeclaration := .definitionDecl
      (psNameAppendStr name "maxValue") [] signedType (ofNat (half - 1))
    let result := psOrderNatRec (.succ .zero)
      (psLogicLam 4 "_" psOrderNat signedType)
      (ofNat 1)
      (psLogicLam 2 "previous" psOrderNat
        (psLogicLam 3 "ih" signedType
          (psOrderCall (owner ++ ".mul") [.fvar 3, .fvar 0])))
      (.fvar 1)
    let pow : PsDeclaration := .definitionDecl
      (psNameAppendStr name "pow") []
      (psLogicPi 0 "value" signedType
        (psLogicPi 1 "exponent" psOrderNat signedType))
      (psLogicLam 0 "value" signedType
        (psLogicLam 1 "exponent" psOrderNat result))
    [size, minimum, maximum, pow]

def psStandardSignedNumericExtend (environment : PsEnvironment) : PsEnvironment :=
  psStandardSignedNumericDeclarations.foldl psEnvironmentInsert environment

def psStandardSignedNumericRuntimeDeclarations : List PsDeclaration :=
  psStandardSignedNumericDeclarations
