import Ps.Environment.StandardSignedShift

/-
Pinned Lean 4.35.0 src/Init/Data/SInt/Basic.lean, commit
eb6cafb7290e8bd5f2937522d8d804f58f02bafc.
Copyright Lean FRO, LLC; Apache-2.0; see THIRD_PARTY_NOTICES.md.

Each fixed signed width defines toNatClampNeg by composing its
already kernel-checked signed-to-Int conversion with checked Int.toNat.
Negative values clamp to zero; nonnegative values are preserved.
No new trusted assumption, native primitive or platform-width model.
-/

def psStandardSignedClampDeclarations : List PsDeclaration :=
  ["Int8", "Int16", "Int32", "Int64"].map fun owner =>
    let signedType : PsExpr := .constE (psRootName owner) []
    let value : PsExpr := .fvar 0
    let result : PsExpr := psOrderCall "Int.toNat"
      [psOrderCall (owner ++ ".toInt") [value]]
    .definitionDecl (psNameAppendStr (psRootName owner) "toNatClampNeg") []
      (psLogicPi 0 "value" signedType psOrderNat)
      (psLogicLam 0 "value" signedType result)

def psStandardSignedClampExtend (environment : PsEnvironment) : PsEnvironment :=
  let environment := psStandardSignedClampDeclarations.foldl
    psEnvironmentInsert environment
  -- Native method is [inline, implicit_reducible].
  psStandardSignedClampDeclarations.foldl (fun env declaration =>
    psEnvironmentSetReducibility env (psDeclarationName declaration)
      .implicitReducible) environment

def psStandardSignedClampRuntimeDeclarations : List PsDeclaration :=
  psStandardSignedClampDeclarations
