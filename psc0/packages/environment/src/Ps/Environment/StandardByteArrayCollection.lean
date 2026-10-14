import Ps.Environment.StandardByteArray
import Ps.Environment.StandardClass
import Ps.Environment.StandardCollectionEquality

/-
Lean 4.35.0 source reference: Init/Data/ByteArray/Basic.lean, pinned
commit eb6cafb7290e8bd5f2937522d8d804f58f02bafc.
Copyright (c) 2019 Microsoft Corporation, Apache-2.0; see
psc0/THIRD_PARTY_NOTICES.md.

ByteArray is a distinct checked one-field structure over Array UInt8.
Reuse the selected checked Array.get!Internal/Array.setIfInBounds,
List.beq and primitive Nat/BEq/Inhabited mechanisms, not a second
byte-buffer implementation. Exact outside-bounds behavior is inherited
from the existing Array model and must be qualified on every backend.
-/

def psStandardByteArrayCoreOperations : List PsDeclaration :=
  let byteArray := psStandardByteArrayType
  let uint8 := psStandardByteArrayElement
  let nat := psOrderNat
  let a : PsExpr := .fvar 0
  let i : PsExpr := .fvar 1
  let b : PsExpr := .fvar 2
  let data := psStandardByteArrayData a
  let inhabited : PsExpr :=
    .constE (psDecisionName "PsStandard.instInhabitedUInt8") []
  let getBang : PsDeclaration := .definitionDecl
    (psNameAppendStr psStandardByteArrayName "get!") []
    (psLogicPi 0 "bytes" byteArray
      (psLogicPi 1 "index" nat uint8))
    (psLogicLam 0 "bytes" byteArray
      (psLogicLam 1 "index" nat
        (psOrderCall "Array.get!Internal" [uint8, inhabited, data, i])))
  let setBang : PsDeclaration := .definitionDecl
    (psNameAppendStr psStandardByteArrayName "set!") []
    (psLogicPi 0 "bytes" byteArray
      (psLogicPi 1 "index" nat
        (psLogicPi 2 "byte" uint8 byteArray)))
    (psLogicLam 0 "bytes" byteArray
      (psLogicLam 1 "index" nat
        (psLogicLam 2 "byte" uint8
          (psStandardByteArrayMk
            (psOrderCall "Array.setIfInBounds" [uint8, data, i, b])))))
  let isEmpty : PsDeclaration := .definitionDecl
    (psNameAppendStr psStandardByteArrayName "isEmpty") []
    (psLogicPi 0 "bytes" byteArray (.constE psBoolName []))
    (psLogicLam 0 "bytes" byteArray
      (psOrderCall "Nat.beq"
        [psOrderCall "ByteArray.size" [a], .lit (.natural 0)]))
  [getBang, setBang, isEmpty]

-- Lean's native ByteArray.beq delegates to Array UInt8 equality.
-- Compare the canonical checked list representation with the selected
-- ordinary List.beq UInt8 dictionary. No host-side byte-array shortcut.
def psStandardByteArrayBeqDeclaration : PsDeclaration :=
  let byteArray := psStandardByteArrayType
  let uint8 := psStandardByteArrayElement
  let getList := fun (v : PsExpr) =>
    psOrderCall "Array.toList" [uint8, psStandardByteArrayData v]
  let dictionary : PsExpr :=
    .constE (psDecisionName "PsStandard.instBEqUInt8") []
  let compare := psLogicApply (.constE psStandardBEqListName [.zero])
    [uint8, dictionary, getList (.fvar 0), getList (.fvar 1)]
  let method := psLogicLam 0 "left" byteArray
    (psLogicLam 1 "right" byteArray compare)
  psStandardBEqInstance "ByteArray" byteArray method

def psStandardByteArrayInhabitedDeclaration : PsDeclaration :=
  psStandardInhabitedGround "ByteArray" psStandardByteArrayType
    (psOrderCall "ByteArray.empty" [])

def psStandardByteArrayCollectionDeclarations : List PsDeclaration :=
  psStandardByteArrayCoreOperations ++
    [psStandardByteArrayBeqDeclaration,
     psStandardByteArrayInhabitedDeclaration]

def psStandardByteArrayCollectionExtend
    (environment : PsEnvironment) : PsEnvironment :=
  let environment := psStandardByteArrayCollectionDeclarations.foldl
    psEnvironmentInsert environment
  let environment := psStandardRegisterInstances environment "BEq"
    [psStandardByteArrayBeqDeclaration]
  psStandardRegisterInstances environment "Inhabited"
    [psStandardByteArrayInhabitedDeclaration]

def psStandardByteArrayCollectionRuntimeDeclarations : List PsDeclaration :=
  psStandardByteArrayCollectionDeclarations
