import Ps.Environment.StandardSum

/-
Lean 4.35.0 src/Init/Prelude.lean, pinned
eb6cafb7290e8bd5f2937522d8d804f58f02bafc.
Copyright Microsoft Corporation, Apache-2.0; THIRD_PARTY_NOTICES.md.

ByteArray is a distinct checked one-field structure containing
Array UInt8. This selected logical model shares the already checked
generic Array operations. Lean's native packed byte buffer is an
optimized representation, not a separate logical datatype or proof
assumption. Runtime packing/ABI optimization is a distinct qualification
problem; do not silently reinterpret a raw Array UInt8 as ByteArray.
-/

def psStandardByteArrayName : PsName := psRootName "ByteArray"
def psStandardByteArrayMkName : PsName :=
  psNameAppendStr psStandardByteArrayName "mk"
def psStandardByteArrayRecName : PsName :=
  psNameAppendStr psStandardByteArrayName "rec"
def psStandardByteArrayDataName : PsName :=
  psNameAppendStr psStandardByteArrayName "data"

def psStandardByteArrayType : PsExpr :=
  .constE psStandardByteArrayName []

def psStandardByteArrayElement : PsExpr :=
  .constE psUInt8Name []

def psStandardByteArrayStorage : PsExpr :=
  psPreludeArrayOf psStandardByteArrayElement

def psStandardByteArrayMk (value : PsExpr) : PsExpr :=
  .app (.constE psStandardByteArrayMkName []) value

def psStandardByteArrayData (value : PsExpr) : PsExpr :=
  .app (.constE psStandardByteArrayDataName []) value

def psStandardByteArrayDataDeclarations : List PsDeclaration :=
  let u := psRootName "u"
  let byteArray := psStandardByteArrayType
  let storage := psStandardByteArrayStorage
  let motive := PsExpr.fvar 0
  let result := PsExpr.fvar 2
  let recType := psLogicPi 0 "motive"
    (psLogicPi 2 "value" byteArray (.sortE (.param u)))
    (psLogicPi 1 "mk"
      (psLogicPi 3 "data" storage
        (.app motive (psStandardByteArrayMk (.fvar 3))))
      (psLogicPi 2 "value" byteArray (.app motive result)))
    .implicit
  [ .inductiveDecl (.mk psStandardByteArrayName [] psPreludeTypeType
      0 0 [psStandardByteArrayMkName] true),
    .constructorDecl (.mk psStandardByteArrayMkName []
      (psLogicPi 0 "data" storage byteArray)
      psStandardByteArrayName 0 0 1 []),
    .recursorDecl (.mk psStandardByteArrayRecName [u] recType
      [psStandardByteArrayName] 0 0 1 1),
    .definitionDecl psStandardByteArrayDataName []
      (psLogicPi 0 "self" byteArray storage)
      (psLogicLam 0 "self" byteArray
        (.proj psStandardByteArrayName 0 (.fvar 0))) ]

def psStandardByteArrayOperationDeclarations : List PsDeclaration :=
  let byteArray := psStandardByteArrayType
  let uint8 := psStandardByteArrayElement
  let nat := psOrderNat
  let emptyStorage := psOrderCall "Array.emptyWithCapacity"
    [uint8, .lit (.natural 0)]
  let emptyWithCapacity : PsDeclaration := .definitionDecl
    (psNameAppendStr psStandardByteArrayName "emptyWithCapacity") []
    (psLogicPi 0 "capacity" nat byteArray)
    (psLogicLam 0 "capacity" nat
      (psStandardByteArrayMk emptyStorage))
  let empty : PsDeclaration := .definitionDecl
    (psNameAppendStr psStandardByteArrayName "empty") []
    byteArray
    (psOrderCall "ByteArray.emptyWithCapacity" [.lit (.natural 0)])
  let push : PsDeclaration := .definitionDecl
    (psNameAppendStr psStandardByteArrayName "push") []
    (psLogicPi 0 "bytes" byteArray
      (psLogicPi 1 "byte" uint8 byteArray))
    (psLogicLam 0 "bytes" byteArray
      (psLogicLam 1 "byte" uint8
        (psStandardByteArrayMk
          (psOrderCall "Array.push"
            [uint8, psStandardByteArrayData (.fvar 0), .fvar 1]))))
  let size : PsDeclaration := .definitionDecl
    (psNameAppendStr psStandardByteArrayName "size") []
    (psLogicPi 0 "bytes" byteArray nat)
    (psLogicLam 0 "bytes" byteArray
      (psOrderCall "Array.size"
        [uint8, psStandardByteArrayData (.fvar 0)]))
  [emptyWithCapacity, empty, push, size]

def psStandardByteArrayDeclarations : List PsDeclaration :=
  psStandardByteArrayDataDeclarations ++
    psStandardByteArrayOperationDeclarations

def psStandardByteArrayExtend (environment : PsEnvironment) : PsEnvironment :=
  let environment := psStandardByteArrayDeclarations.foldl
    psEnvironmentInsert environment
  (["emptyWithCapacity", "empty", "push", "size"]).foldl
    (fun env method =>
      psEnvironmentSetReducibility env
        (psNameAppendStr psStandardByteArrayName method)
        .implicitReducible) environment

def psStandardByteArrayRuntimeDeclarations : List PsDeclaration :=
  psStandardByteArrayDeclarations
