import Ps.Environment.StandardSignedToInt

/-
Lean 4.35.0, src/Init/Data/SInt/Basic.lean and
src/Init/Data/BitVec/Basic.lean, pinned eb6cafb7290e8bd5f2937522d8d804f58f02bafc.
Copyright Lean FRO, LLC; Apache-2.0; see THIRD_PARTY_NOTICES.md.

An ordinary, constructive Int-recursive implementation of wrapping
Int8/16/32/64.ofInt. For Int.ofNat n it reduces to IntN.ofNat n; for
Int.negSucc n it reduces to IntN.neg (IntN.ofNat (Nat.succ n)).
Both branches compute the same two's-complement residue as the pinned
BitVec.ofInt model, reusing the already kernel-checked Int constructors
and signed fixed-width arithmetic. This adds no assumption, unsafe cast
or trusted primitive; runtime equivalence is checked separately.
-/

-- Signed and unsigned fixed-width ofInt both wrap the Int constructors
-- through the same checked modular arithmetic. Keep one binder-exact Core
-- construction and let each family choose its native reducibility metadata.
def psStandardWrappingOfIntDeclaration (owner : String) : PsDeclaration :=
  let resultType : PsExpr := .constE (psRootName owner) []
  let inputType : PsExpr := .constE psIntName []
  let input : PsExpr := .fvar 0
  let natural : PsExpr := .fvar 1
  let positive : PsExpr :=
    psLogicLam 1 "n" psOrderNat
      (psOrderCall (owner ++ ".ofNat") [natural])
  let negative : PsExpr :=
    psLogicLam 1 "n" psOrderNat
      (psOrderCall (owner ++ ".neg")
        [psOrderCall (owner ++ ".ofNat") [psOrderSucc natural]])
  let body : PsExpr :=
    psLogicApply (.constE (psNameAppendStr psIntName "rec") [.succ .zero])
      [psLogicLam 4 "_" inputType resultType,
       positive, negative, input]
  .definitionDecl (psNameAppendStr (psRootName owner) "ofInt") []
    (psLogicPi 0 "value" inputType resultType)
    (psLogicLam 0 "value" inputType body)

def psStandardSignedOfIntDeclarations : List PsDeclaration :=
  ["Int8", "Int16", "Int32", "Int64"].map psStandardWrappingOfIntDeclaration

def psStandardSignedOfIntExtend (environment : PsEnvironment) : PsEnvironment :=
  let environment := psStandardSignedOfIntDeclarations.foldl
    psEnvironmentInsert environment
  -- Pinned native IntN.ofInt is [implicit_reducible].
  psStandardSignedOfIntDeclarations.foldl (fun env declaration =>
    psEnvironmentSetReducibility env (psDeclarationName declaration)
      .implicitReducible) environment

def psStandardSignedOfIntRuntimeDeclarations : List PsDeclaration :=
  psStandardSignedOfIntDeclarations
