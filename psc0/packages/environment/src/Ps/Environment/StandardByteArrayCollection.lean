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
-- A recursive worker with an explicit Nat major is required: the source
-- recursor is executable only when its predecessor/IH are the actual changing
-- parameter of a checked recursive function. Capturing a computed size in a
-- Nat.rec directly under ByteArray.beq incorrectly erases its runtime IH.
-- This is the same architectural normalization used by signed/unsigned pow.
def psStandardByteArrayBeqWorkerDeclaration : PsDeclaration :=
  let bytes := psStandardByteArrayType
  let uint8 := psStandardByteArrayElement
  let bool : PsExpr := .constE psBoolName []
  let left : PsExpr := .fvar 0
  let right : PsExpr := .fvar 1
  let count : PsExpr := .fvar 2
  let index : PsExpr := .fvar 3
  let previousEqual : PsExpr := .fvar 4
  let leftData := psStandardByteArrayData left
  let rightData := psStandardByteArrayData right
  let falseValue : PsExpr := .constE psBoolFalseName []
  let trueValue : PsExpr := .constE psBoolTrueName []
  let boolAnd := fun (a b : PsExpr) =>
    psLogicApply (.constE (psNameAppendStr psBoolName "rec") [.succ .zero])
      [psLogicLam 19 "_" bool bool, falseValue, b, a]
  let zero := psOrderCall "UInt8.ofNat" [.lit (.natural 0)]
  let byteAt := fun data =>
    psOrderCall "UInt8.toNat"
      [psOrderCall "Array.getD" [uint8, data, index, zero]]
  let equalByte := psOrderCall "Nat.beq"
    [byteAt leftData, byteAt rightData]
  let step := psLogicLam 3 "index" psOrderNat
    (psLogicLam 4 "previousEqual" bool
      (boolAnd previousEqual equalByte))
  let body := psOrderNatRec (.succ .zero)
    (psLogicLam 5 "_" psOrderNat bool) trueValue step count
  .definitionDecl (psDecisionName "ByteArray.beq.go") []
    (psLogicPi 0 "left" bytes
      (psLogicPi 1 "right" bytes
        (psLogicPi 2 "count" psOrderNat bool)))
    (psLogicLam 0 "left" bytes
      (psLogicLam 1 "right" bytes
        (psLogicLam 2 "count" psOrderNat body)))

def psStandardByteArrayBeqModelDeclaration : PsDeclaration :=
  let bytes := psStandardByteArrayType
  let bool : PsExpr := .constE psBoolName []
  let left : PsExpr := .fvar 0
  let right : PsExpr := .fvar 1
  let leftSize := psOrderCall "ByteArray.size" [left]
  let rightSize := psOrderCall "ByteArray.size" [right]
  let sameLength := psOrderCall "Nat.beq" [leftSize, rightSize]
  let allBytes := psOrderCall "ByteArray.beq.go" [left, right, leftSize]
  let falseValue : PsExpr := .constE psBoolFalseName []
  let guarded := psLogicApply
    (.constE (psNameAppendStr psBoolName "rec") [.succ .zero])
    [psLogicLam 19 "_" bool bool, falseValue, allBytes, sameLength]
  .definitionDecl (psNameAppendStr psStandardByteArrayName "beq") []
    (psLogicPi 0 "left" bytes (psLogicPi 1 "right" bytes bool))
    (psLogicLam 0 "left" bytes
      (psLogicLam 1 "right" bytes guarded))

-- Ordinary dictionary forwarding to the checked native-named ByteArray.beq.
def psStandardByteArrayBeqDeclaration : PsDeclaration :=
  let bytes := psStandardByteArrayType
  let method := psLogicLam 0 "left" bytes
    (psLogicLam 1 "right" bytes
      (psOrderCall "ByteArray.beq" [.fvar 0, .fvar 1]))
  psStandardBEqInstance "ByteArray" bytes method

def psStandardByteArrayInhabitedDeclaration : PsDeclaration :=
  psStandardInhabitedGround "ByteArray" psStandardByteArrayType
    (psOrderCall "ByteArray.empty" [])

def psStandardByteArrayCollectionDeclarations : List PsDeclaration :=
  psStandardByteArrayCoreOperations ++
    [psStandardByteArrayBeqWorkerDeclaration,
     psStandardByteArrayBeqModelDeclaration,
     psStandardByteArrayBeqDeclaration,
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
