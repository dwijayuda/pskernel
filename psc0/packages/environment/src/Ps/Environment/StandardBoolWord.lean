import Ps.Environment.StandardSignedNumeric

/-
Pinned Lean 4.35.0 Init/Data/SInt/Basic.lean and Init/Data/UInt/Basic.lean
at eb6cafb7290e8bd5f2937522d8d804f58f02bafc.
Copyright Lean FRO, LLC; Apache-2.0; see THIRD_PARTY_NOTICES.md.

Bool.toUInt{8,16,32,64} and Bool.toInt{8,16,32,64} map
false to 0 and true to 1. The upstream `if b then 1 else 0`
is exactly the Bool recursor with false/true branches. Reuse the
selected genuine Bool.rec and checked fixed-width ofNat methods.
This adds no new runtime primitive, search rule or trusted axiom.
-/

def psStandardBoolWordDeclarations : List PsDeclaration :=
  (["UInt8", "UInt16", "UInt32", "UInt64"] ++
   ["Int8", "Int16", "Int32", "Int64"]).map fun owner =>
    let bool : PsExpr := .constE psBoolName []
    let output : PsExpr := .constE (psRootName owner) []
    let ofNat := fun (value : Nat) =>
      psOrderCall (owner ++ ".ofNat") [.lit (.natural value)]
    let recursor : PsExpr :=
      .constE (psNameAppendStr psBoolName "rec") [.succ .zero]
    let result := psLogicApply recursor
      [psLogicLam 1 "_" bool output, ofNat 0, ofNat 1, .fvar 0]
    .definitionDecl (psNameAppendStr psBoolName ("to" ++ owner)) []
      (psLogicPi 0 "value" bool output)
      (psLogicLam 0 "value" bool result)

def psStandardBoolWordExtend (environment : PsEnvironment) : PsEnvironment :=
  psStandardBoolWordDeclarations.foldl psEnvironmentInsert environment

def psStandardBoolWordRuntimeDeclarations : List PsDeclaration :=
  psStandardBoolWordDeclarations
