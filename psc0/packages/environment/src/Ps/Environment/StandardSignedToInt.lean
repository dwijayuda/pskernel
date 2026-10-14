import Ps.Environment.StandardSignedScalar

/-
A constructive portable Core image of Lean 4.35.0's Int8/16/32/64.toInt.
Pinned Lean sources: Init/Data/SInt/Basic.lean, Init/Data/BitVec/Basic.lean.
Copyright Lean FRO, LLC; Apache-2.0; see THIRD_PARTY_NOTICES.md.

The original native definitions were compared by four `rfl` theorems
in Pscv0NativeTests.lean (commit fe88e7f). Thus the sign predicate,
boundaries and Int subtraction below are EXACT native representations,
not guessed numeric conversions. No new proof axiom or unsafe cast.
-/

def psStandardSignedToIntDeclarations : List PsDeclaration :=
  [("Int8", "UInt8", 8), ("Int16", "UInt16", 16),
   ("Int32", "UInt32", 32), ("Int64", "UInt64", 64)].map fun (owner, unsigned, width) =>
    let signedType : PsExpr := .constE (psRootName owner) []
    let intType : PsExpr := .constE psIntName []
    let value : PsExpr := .fvar 0
    let bits : PsExpr := psOrderCall (unsigned ++ ".toNat")
      [psOrderCall (owner ++ ".to" ++ unsigned) [value]]
    let twice : PsExpr := psOrderCall "Nat.mul" [.lit (.natural 2), bits]
    let maxBits : PsExpr := .lit (.natural (2 ^ width))
    let proposition : PsExpr := psOrderCall "Nat.lt" [twice, maxBits]
    let decision : PsExpr := psOrderCall "Nat.decLt" [twice, maxBits]
    let nonnegative : PsExpr := .app (.constE psIntOfNatName []) bits
    let negative : PsExpr := psOrderCall "Int.sub"
      [nonnegative, .app (.constE psIntOfNatName []) maxBits]
    let result : PsExpr := psLogicApply (.constE (psRootName "ite") [.succ .zero])
      [intType, proposition, decision, nonnegative, negative]
    .definitionDecl (psNameAppendStr (psRootName owner) "toInt") []
      (psLogicPi 0 "value" signedType intType)
      (psLogicLam 0 "value" signedType result)

def psStandardSignedToIntExtend (environment : PsEnvironment) : PsEnvironment :=
  psStandardSignedToIntDeclarations.foldl psEnvironmentInsert environment

def psStandardSignedToIntRuntimeDeclarations : List PsDeclaration :=
  psStandardSignedToIntDeclarations
