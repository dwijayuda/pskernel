import Ps.BackendWasm.RuntimeNat
import Ps.CompilerIr.Model

def psWasmStringRuntimeCharOfNatName : String :=
  "__ps_char_of_nat"

def psWasmStringRuntimeCharToNatName : String :=
  "__ps_char_to_nat"

def psWasmStringRuntimePushName : String :=
  "__ps_string_push"

def psWasmStringRuntimeSingletonName : String :=
  "__ps_string_singleton"

def psWasmStringRuntimeLengthName : String :=
  "__ps_string_length"

def psWasmStringRuntimeAppendName : String :=
  "__ps_string_append"

def psWasmStringRuntimeUtf8ByteSizeName : String :=
  "__ps_string_utf8_byte_size"

def psWasmStringRuntimeNextName : String :=
  "__ps_string_next"

def psWasmStringRuntimeGetName : String :=
  "__ps_string_get"

def psWasmStringRuntimeAtEndName : String :=
  "__ps_string_at_end"

def psWasmStringRuntimeExtractName : String :=
  "__ps_string_extract"

def psWasmStringRuntimeEqName : String :=
  "__ps_string_eq"

def psWasmStringRuntimeEqFromName : String :=
  "__ps_string_eq_from"

def psWasmStringSemanticType : PsVerifiedIrType :=
  PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.string

def psWasmStringRuntimeByteType : PsVerifiedIrType :=
  PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.uint32

def psWasmStringRuntimeType : PsVerifiedIrType :=
  PsVerifiedIrType.named
    "Array"
    [psWasmStringRuntimeByteType]

def psWasmStringRuntimeNatType : PsVerifiedIrType :=
  PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat

def psWasmStringRuntimeCharType : PsVerifiedIrType :=
  PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.char

def psWasmStringRuntimeBoolType : PsVerifiedIrType :=
  PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.bool

def psWasmStringRuntimeU32Type : PsVerifiedIrType :=
  PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.uint32

def psWasmStringRuntimeNat
    (value : Nat) : PsVerifiedIrExpr :=
  PsVerifiedIrExpr.literal (PsVerifiedIrLiteral.natural value)

def psWasmStringRuntimeU32
    (value : Nat) : PsVerifiedIrExpr :=
  PsVerifiedIrExpr.literal
    (PsVerifiedIrLiteral.machineInteger
      PsVerifiedIrMachineIntegerType.uint32
      (Int.ofNat value))

def psWasmStringRuntimeBool
    (value : Bool) : PsVerifiedIrExpr :=
  PsVerifiedIrExpr.literal (PsVerifiedIrLiteral.bool value)

def psWasmStringRuntimeCall
    (name : String)
    (arguments : List PsVerifiedIrExpr) : PsVerifiedIrExpr :=
  PsVerifiedIrExpr.call
    (PsVerifiedIrExpr.var name)
    []
    arguments

def psWasmStringRuntimeNatCall
    (name : String)
    (arguments : List PsVerifiedIrExpr) : PsVerifiedIrExpr :=
  PsVerifiedIrExpr.call
    (PsVerifiedIrExpr.var name)
    []
    arguments

def psWasmStringRuntimeNatAdd
    (left right : PsVerifiedIrExpr) : PsVerifiedIrExpr :=
  PsVerifiedIrExpr.intrinsic
    PsVerifiedIrIntrinsic.natAdd
    [left, right]

def psWasmStringRuntimeNatDiv
    (left right : PsVerifiedIrExpr) : PsVerifiedIrExpr :=
  PsVerifiedIrExpr.intrinsic
    PsVerifiedIrIntrinsic.natDiv
    [left, right]

def psWasmStringRuntimeNatMod
    (left right : PsVerifiedIrExpr) : PsVerifiedIrExpr :=
  PsVerifiedIrExpr.intrinsic
    PsVerifiedIrIntrinsic.natMod
    [left, right]

def psWasmStringRuntimeNatEq
    (left right : PsVerifiedIrExpr) : PsVerifiedIrExpr :=
  PsVerifiedIrExpr.intrinsic
    PsVerifiedIrIntrinsic.natEq
    [left, right]

def psWasmStringRuntimeNatLe
    (left right : PsVerifiedIrExpr) : PsVerifiedIrExpr :=
  PsVerifiedIrExpr.intrinsic
    PsVerifiedIrIntrinsic.natLe
    [left, right]

def psWasmStringRuntimeNatLt
    (left right : PsVerifiedIrExpr) : PsVerifiedIrExpr :=
  PsVerifiedIrExpr.intrinsic
    PsVerifiedIrIntrinsic.natLt
    [left, right]

def psWasmStringRuntimeU32Binary
    (operation : PsVerifiedIrIntegerBinaryOp)
    (left right : PsVerifiedIrExpr) : PsVerifiedIrExpr :=
  PsVerifiedIrExpr.intrinsic
    (PsVerifiedIrIntrinsic.machineIntBinary
      PsVerifiedIrMachineIntegerType.uint32
      operation)
    [left, right]

def psWasmStringRuntimeU32Compare
    (operation : PsVerifiedIrIntegerCompareOp)
    (left right : PsVerifiedIrExpr) : PsVerifiedIrExpr :=
  PsVerifiedIrExpr.intrinsic
    (PsVerifiedIrIntrinsic.machineIntCompare
      PsVerifiedIrMachineIntegerType.uint32
      operation)
    [left, right]

def psWasmStringRuntimeArrayEmpty
    (capacity : PsVerifiedIrExpr) : PsVerifiedIrExpr :=
  PsVerifiedIrExpr.intrinsic
    (PsVerifiedIrIntrinsic.arrayEmptyWithCapacity
      psWasmStringRuntimeByteType)
    [capacity]

def psWasmStringRuntimeArraySize
    (array : PsVerifiedIrExpr) : PsVerifiedIrExpr :=
  PsVerifiedIrExpr.intrinsic
    (PsVerifiedIrIntrinsic.arraySize
      psWasmStringRuntimeByteType)
    [array]

def psWasmStringRuntimeArrayPush
    (array value : PsVerifiedIrExpr) : PsVerifiedIrExpr :=
  PsVerifiedIrExpr.intrinsic
    (PsVerifiedIrIntrinsic.arrayPush
      psWasmStringRuntimeByteType)
    [array, value]

def psWasmStringRuntimeArrayGet
    (array index : PsVerifiedIrExpr) : PsVerifiedIrExpr :=
  PsVerifiedIrExpr.intrinsic
    (PsVerifiedIrIntrinsic.arrayGet
      psWasmStringRuntimeByteType)
    [array, index]

def psWasmStringRuntimeArrayGetD
    (array index fallback : PsVerifiedIrExpr) : PsVerifiedIrExpr :=
  PsVerifiedIrExpr.intrinsic
    (PsVerifiedIrIntrinsic.arrayGetD
      psWasmStringRuntimeByteType)
    [array, index, fallback]

def psWasmStringRuntimeArrayFold
    (fn init array start stop : PsVerifiedIrExpr) : PsVerifiedIrExpr :=
  PsVerifiedIrExpr.intrinsic
    (PsVerifiedIrIntrinsic.arrayFoldl
      psWasmStringRuntimeByteType
      psWasmStringRuntimeType)
    [fn, init, array, start, stop]

def psWasmStringRuntimeNatToU32
    (value : PsVerifiedIrExpr) : PsVerifiedIrExpr :=
  psWasmStringRuntimeNatCall
    psWasmNatRuntimeToU32BoundedName
    [value]

def psWasmStringRuntimeU32ToNat
    (value : PsVerifiedIrExpr) : PsVerifiedIrExpr :=
  psWasmStringRuntimeNatCall
    psWasmNatRuntimeFromU32Name
    [value]

def psWasmStringRuntimeUtf8Char
    (char : Char) : List Nat :=
  let value := char.toNat
  if value <= 127 then
    [value]
  else if value <= 2047 then
    [
      192 + value / 64,
      128 + value % 64
    ]
  else if value <= 65535 then
    [
      224 + value / 4096,
      128 + (value / 64) % 64,
      128 + value % 64
    ]
  else
    [
      240 + value / 262144,
      128 + (value / 4096) % 64,
      128 + (value / 64) % 64,
      128 + value % 64
    ]

def psWasmStringRuntimeUtf8Chars : List Char -> List Nat
  | [] => []
  | char :: rest =>
      psWasmStringRuntimeUtf8Char char
        ++ psWasmStringRuntimeUtf8Chars rest

def psWasmStringRuntimeNatListLength : List Nat -> Nat
  | [] => 0
  | _ :: rest =>
      1 + psWasmStringRuntimeNatListLength rest

def psWasmStringRuntimePushLiteralBytes :
    PsVerifiedIrExpr -> List Nat -> PsVerifiedIrExpr
  | array, [] => array
  | array, byte :: rest =>
      psWasmStringRuntimePushLiteralBytes
        (psWasmStringRuntimeArrayPush
          array
          (psWasmStringRuntimeU32 byte))
        rest

def psWasmStringLiteralExpr
    (value : String) : PsVerifiedIrExpr :=
  let bytes :=
    psWasmStringRuntimeUtf8Chars (String.toList value)
  psWasmStringRuntimePushLiteralBytes
    (psWasmStringRuntimeArrayEmpty
      (psWasmStringRuntimeNat
        (psWasmStringRuntimeNatListLength bytes)))
    bytes

def psWasmStringRuntimeArrayFromNatBytes
    (bytes : List PsVerifiedIrExpr) : PsVerifiedIrExpr :=
  let capacity :=
    psWasmStringRuntimeNat
      (bytes.length)
  let start :=
    psWasmStringRuntimeArrayEmpty capacity
  bytes.foldl
    (fun array byte =>
      psWasmStringRuntimeArrayPush
        array
        (psWasmStringRuntimeNatToU32 byte))
    start

def psWasmStringRuntimeCharToNatDeclaration :
    PsVerifiedIrDeclaration :=
  {
    name := psWasmStringRuntimeCharToNatName
    typeParameters := []
    parameters := [
      {
        name := "value"
        type := psWasmStringRuntimeCharType
      }
    ]
    resultType := psWasmStringRuntimeNatType
    body :=
      psWasmStringRuntimeU32ToNat
        (PsVerifiedIrExpr.var "value")
  }

def psWasmStringRuntimeCharOfNatDeclaration :
    PsVerifiedIrDeclaration :=
  {
    name := psWasmStringRuntimeCharOfNatName
    typeParameters := []
    parameters := [
      {
        name := "value"
        type := psWasmStringRuntimeNatType
      }
    ]
    resultType := psWasmStringRuntimeCharType
    body :=
      PsVerifiedIrExpr.ifE
        (psWasmStringRuntimeNatLt
          (PsVerifiedIrExpr.var "value")
          (psWasmStringRuntimeNat 55296))
        (psWasmStringRuntimeNatToU32
          (PsVerifiedIrExpr.var "value"))
        (PsVerifiedIrExpr.ifE
          (psWasmStringRuntimeNatLt
            (psWasmStringRuntimeNat 57343)
            (PsVerifiedIrExpr.var "value"))
          (PsVerifiedIrExpr.ifE
            (psWasmStringRuntimeNatLt
              (PsVerifiedIrExpr.var "value")
              (psWasmStringRuntimeNat 1114112))
            (psWasmStringRuntimeNatToU32
              (PsVerifiedIrExpr.var "value"))
            (psWasmStringRuntimeU32 0))
          (psWasmStringRuntimeU32 0))
  }

def psWasmStringRuntimeSingletonDeclaration :
    PsVerifiedIrDeclaration :=
  {
    name := psWasmStringRuntimeSingletonName
    typeParameters := []
    parameters := [
      {
        name := "char"
        type := psWasmStringRuntimeCharType
      }
    ]
    resultType := psWasmStringSemanticType
    body :=
      PsVerifiedIrExpr.letE
        "cp"
        psWasmStringRuntimeNatType
        (psWasmStringRuntimeCall
          psWasmStringRuntimeCharToNatName
          [PsVerifiedIrExpr.var "char"])
        (PsVerifiedIrExpr.ifE
          (psWasmStringRuntimeNatLt
            (PsVerifiedIrExpr.var "cp")
            (psWasmStringRuntimeNat 128))
          (psWasmStringRuntimeArrayFromNatBytes
            [PsVerifiedIrExpr.var "cp"])
          (PsVerifiedIrExpr.ifE
            (psWasmStringRuntimeNatLt
              (PsVerifiedIrExpr.var "cp")
              (psWasmStringRuntimeNat 2048))
            (psWasmStringRuntimeArrayFromNatBytes
              [
                psWasmStringRuntimeNatAdd
                  (psWasmStringRuntimeNat 192)
                  (psWasmStringRuntimeNatDiv
                    (PsVerifiedIrExpr.var "cp")
                    (psWasmStringRuntimeNat 64)),
                psWasmStringRuntimeNatAdd
                  (psWasmStringRuntimeNat 128)
                  (psWasmStringRuntimeNatMod
                    (PsVerifiedIrExpr.var "cp")
                    (psWasmStringRuntimeNat 64))
              ])
            (PsVerifiedIrExpr.ifE
              (psWasmStringRuntimeNatLt
                (PsVerifiedIrExpr.var "cp")
                (psWasmStringRuntimeNat 65536))
              (psWasmStringRuntimeArrayFromNatBytes
                [
                  psWasmStringRuntimeNatAdd
                    (psWasmStringRuntimeNat 224)
                    (psWasmStringRuntimeNatDiv
                      (PsVerifiedIrExpr.var "cp")
                      (psWasmStringRuntimeNat 4096)),
                  psWasmStringRuntimeNatAdd
                    (psWasmStringRuntimeNat 128)
                    (psWasmStringRuntimeNatMod
                      (psWasmStringRuntimeNatDiv
                        (PsVerifiedIrExpr.var "cp")
                        (psWasmStringRuntimeNat 64))
                      (psWasmStringRuntimeNat 64)),
                  psWasmStringRuntimeNatAdd
                    (psWasmStringRuntimeNat 128)
                    (psWasmStringRuntimeNatMod
                      (PsVerifiedIrExpr.var "cp")
                      (psWasmStringRuntimeNat 64))
                ])
              (psWasmStringRuntimeArrayFromNatBytes
                [
                  psWasmStringRuntimeNatAdd
                    (psWasmStringRuntimeNat 240)
                    (psWasmStringRuntimeNatDiv
                      (PsVerifiedIrExpr.var "cp")
                      (psWasmStringRuntimeNat 262144)),
                  psWasmStringRuntimeNatAdd
                    (psWasmStringRuntimeNat 128)
                    (psWasmStringRuntimeNatMod
                      (psWasmStringRuntimeNatDiv
                        (PsVerifiedIrExpr.var "cp")
                        (psWasmStringRuntimeNat 4096))
                      (psWasmStringRuntimeNat 64)),
                  psWasmStringRuntimeNatAdd
                    (psWasmStringRuntimeNat 128)
                    (psWasmStringRuntimeNatMod
                      (psWasmStringRuntimeNatDiv
                        (PsVerifiedIrExpr.var "cp")
                        (psWasmStringRuntimeNat 64))
                      (psWasmStringRuntimeNat 64)),
                  psWasmStringRuntimeNatAdd
                    (psWasmStringRuntimeNat 128)
                    (psWasmStringRuntimeNatMod
                      (PsVerifiedIrExpr.var "cp")
                      (psWasmStringRuntimeNat 64))
                ]))))
  }

def psWasmStringRuntimeAppendDeclaration :
    PsVerifiedIrDeclaration :=
  {
    name := psWasmStringRuntimeAppendName
    typeParameters := []
    parameters := [
      {
        name := "left"
        type := psWasmStringSemanticType
      },
      {
        name := "right"
        type := psWasmStringSemanticType
      }
    ]
    resultType := psWasmStringSemanticType
    body :=
      psWasmStringRuntimeArrayFold
        (PsVerifiedIrExpr.lambda
          [
            {
              name := "out"
              type := psWasmStringSemanticType
            },
            {
              name := "byte"
              type := psWasmStringRuntimeU32Type
            }
          ]
          psWasmStringSemanticType
          (psWasmStringRuntimeArrayPush
            (PsVerifiedIrExpr.var "out")
            (PsVerifiedIrExpr.var "byte")))
        (PsVerifiedIrExpr.var "left")
        (PsVerifiedIrExpr.var "right")
        (psWasmStringRuntimeNat 0)
        (psWasmStringRuntimeArraySize
          (PsVerifiedIrExpr.var "right"))
  }

def psWasmStringRuntimePushDeclaration :
    PsVerifiedIrDeclaration :=
  {
    name := psWasmStringRuntimePushName
    typeParameters := []
    parameters := [
      {
        name := "value"
        type := psWasmStringSemanticType
      },
      {
        name := "char"
        type := psWasmStringRuntimeCharType
      }
    ]
    resultType := psWasmStringSemanticType
    body :=
      psWasmStringRuntimeCall
        psWasmStringRuntimeAppendName
        [
          PsVerifiedIrExpr.var "value",
          psWasmStringRuntimeCall
            psWasmStringRuntimeSingletonName
            [PsVerifiedIrExpr.var "char"]
        ]
  }

def psWasmStringRuntimeLengthDeclaration :
    PsVerifiedIrDeclaration :=
  {
    name := psWasmStringRuntimeLengthName
    typeParameters := []
    parameters := [
      {
        name := "value"
        type := psWasmStringSemanticType
      }
    ]
    resultType := psWasmStringRuntimeNatType
    body :=
      PsVerifiedIrExpr.intrinsic
        (PsVerifiedIrIntrinsic.arrayFoldl
          psWasmStringRuntimeByteType
          psWasmStringRuntimeNatType)
        [
          PsVerifiedIrExpr.lambda
            [
              {
                name := "count"
                type := psWasmStringRuntimeNatType
              },
              {
                name := "byte"
                type := psWasmStringRuntimeU32Type
              }
            ]
            psWasmStringRuntimeNatType
            (PsVerifiedIrExpr.ifE
              (psWasmStringRuntimeU32Compare
                PsVerifiedIrIntegerCompareOp.ne
                (psWasmStringRuntimeU32Binary
                  PsVerifiedIrIntegerBinaryOp.bitAnd
                  (PsVerifiedIrExpr.var "byte")
                  (psWasmStringRuntimeU32 192))
                (psWasmStringRuntimeU32 128))
              (psWasmStringRuntimeNatAdd
                (PsVerifiedIrExpr.var "count")
                (psWasmStringRuntimeNat 1))
              (PsVerifiedIrExpr.var "count")),
          psWasmStringRuntimeNat 0,
          PsVerifiedIrExpr.var "value",
          psWasmStringRuntimeNat 0,
          psWasmStringRuntimeArraySize
            (PsVerifiedIrExpr.var "value")
        ]
  }

def psWasmStringRuntimeUtf8ByteSizeDeclaration :
    PsVerifiedIrDeclaration :=
  {
    name := psWasmStringRuntimeUtf8ByteSizeName
    typeParameters := []
    parameters := [
      {
        name := "value"
        type := psWasmStringSemanticType
      }
    ]
    resultType := psWasmStringRuntimeNatType
    body :=
      psWasmStringRuntimeArraySize
        (PsVerifiedIrExpr.var "value")
  }

def psWasmStringRuntimeAtEndDeclaration :
    PsVerifiedIrDeclaration :=
  {
    name := psWasmStringRuntimeAtEndName
    typeParameters := []
    parameters := [
      {
        name := "value"
        type := psWasmStringSemanticType
      },
      {
        name := "position"
        type := psWasmStringRuntimeNatType
      }
    ]
    resultType := psWasmStringRuntimeBoolType
    body :=
      psWasmStringRuntimeNatLe
        (psWasmStringRuntimeArraySize
          (PsVerifiedIrExpr.var "value"))
        (PsVerifiedIrExpr.var "position")
  }

def psWasmStringRuntimeNextDeclaration :
    PsVerifiedIrDeclaration :=
  {
    name := psWasmStringRuntimeNextName
    typeParameters := []
    parameters := [
      {
        name := "value"
        type := psWasmStringSemanticType
      },
      {
        name := "position"
        type := psWasmStringRuntimeNatType
      }
    ]
    resultType := psWasmStringRuntimeNatType
    body :=
      PsVerifiedIrExpr.ifE
        (psWasmStringRuntimeCall
          psWasmStringRuntimeAtEndName
          [
            PsVerifiedIrExpr.var "value",
            PsVerifiedIrExpr.var "position"
          ])
        (psWasmStringRuntimeNatAdd
          (PsVerifiedIrExpr.var "position")
          (psWasmStringRuntimeNat 1))
        (PsVerifiedIrExpr.letE
          "byte"
          psWasmStringRuntimeU32Type
          (psWasmStringRuntimeArrayGet
            (PsVerifiedIrExpr.var "value")
            (PsVerifiedIrExpr.var "position"))
          (PsVerifiedIrExpr.ifE
            (psWasmStringRuntimeU32Compare
              PsVerifiedIrIntegerCompareOp.eq
              (psWasmStringRuntimeU32Binary
                PsVerifiedIrIntegerBinaryOp.bitAnd
                (PsVerifiedIrExpr.var "byte")
                (psWasmStringRuntimeU32 192))
              (psWasmStringRuntimeU32 128))
            (psWasmStringRuntimeNatAdd
              (PsVerifiedIrExpr.var "position")
              (psWasmStringRuntimeNat 1))
            (PsVerifiedIrExpr.ifE
              (psWasmStringRuntimeU32Compare
                PsVerifiedIrIntegerCompareOp.lt
                (PsVerifiedIrExpr.var "byte")
                (psWasmStringRuntimeU32 128))
              (psWasmStringRuntimeNatAdd
                (PsVerifiedIrExpr.var "position")
                (psWasmStringRuntimeNat 1))
              (PsVerifiedIrExpr.ifE
                (psWasmStringRuntimeU32Compare
                  PsVerifiedIrIntegerCompareOp.lt
                  (PsVerifiedIrExpr.var "byte")
                  (psWasmStringRuntimeU32 224))
                (psWasmStringRuntimeNatAdd
                  (PsVerifiedIrExpr.var "position")
                  (psWasmStringRuntimeNat 2))
                (PsVerifiedIrExpr.ifE
                  (psWasmStringRuntimeU32Compare
                    PsVerifiedIrIntegerCompareOp.lt
                    (PsVerifiedIrExpr.var "byte")
                    (psWasmStringRuntimeU32 240))
                  (psWasmStringRuntimeNatAdd
                    (PsVerifiedIrExpr.var "position")
                    (psWasmStringRuntimeNat 3))
                  (psWasmStringRuntimeNatAdd
                    (PsVerifiedIrExpr.var "position")
                    (psWasmStringRuntimeNat 4)))))))
  }

def psWasmStringRuntimeDecode2
    (b0 b1 : PsVerifiedIrExpr) : PsVerifiedIrExpr :=
  psWasmStringRuntimeU32Binary
    PsVerifiedIrIntegerBinaryOp.add
    (psWasmStringRuntimeU32Binary
      PsVerifiedIrIntegerBinaryOp.mul
      (psWasmStringRuntimeU32Binary
        PsVerifiedIrIntegerBinaryOp.bitAnd
        b0
        (psWasmStringRuntimeU32 31))
      (psWasmStringRuntimeU32 64))
    (psWasmStringRuntimeU32Binary
      PsVerifiedIrIntegerBinaryOp.bitAnd
      b1
      (psWasmStringRuntimeU32 63))

def psWasmStringRuntimeDecode3
    (b0 b1 b2 : PsVerifiedIrExpr) : PsVerifiedIrExpr :=
  psWasmStringRuntimeU32Binary
    PsVerifiedIrIntegerBinaryOp.add
    (psWasmStringRuntimeU32Binary
      PsVerifiedIrIntegerBinaryOp.add
      (psWasmStringRuntimeU32Binary
        PsVerifiedIrIntegerBinaryOp.mul
        (psWasmStringRuntimeU32Binary
          PsVerifiedIrIntegerBinaryOp.bitAnd
          b0
          (psWasmStringRuntimeU32 15))
        (psWasmStringRuntimeU32 4096))
      (psWasmStringRuntimeU32Binary
        PsVerifiedIrIntegerBinaryOp.mul
        (psWasmStringRuntimeU32Binary
          PsVerifiedIrIntegerBinaryOp.bitAnd
          b1
          (psWasmStringRuntimeU32 63))
        (psWasmStringRuntimeU32 64)))
    (psWasmStringRuntimeU32Binary
      PsVerifiedIrIntegerBinaryOp.bitAnd
      b2
      (psWasmStringRuntimeU32 63))

def psWasmStringRuntimeDecode4
    (b0 b1 b2 b3 : PsVerifiedIrExpr) : PsVerifiedIrExpr :=
  psWasmStringRuntimeU32Binary
    PsVerifiedIrIntegerBinaryOp.add
    (psWasmStringRuntimeU32Binary
      PsVerifiedIrIntegerBinaryOp.add
      (psWasmStringRuntimeU32Binary
        PsVerifiedIrIntegerBinaryOp.add
        (psWasmStringRuntimeU32Binary
          PsVerifiedIrIntegerBinaryOp.mul
          (psWasmStringRuntimeU32Binary
            PsVerifiedIrIntegerBinaryOp.bitAnd
            b0
            (psWasmStringRuntimeU32 7))
          (psWasmStringRuntimeU32 262144))
        (psWasmStringRuntimeU32Binary
          PsVerifiedIrIntegerBinaryOp.mul
          (psWasmStringRuntimeU32Binary
            PsVerifiedIrIntegerBinaryOp.bitAnd
            b1
            (psWasmStringRuntimeU32 63))
          (psWasmStringRuntimeU32 4096)))
      (psWasmStringRuntimeU32Binary
        PsVerifiedIrIntegerBinaryOp.mul
        (psWasmStringRuntimeU32Binary
          PsVerifiedIrIntegerBinaryOp.bitAnd
          b2
          (psWasmStringRuntimeU32 63))
        (psWasmStringRuntimeU32 64)))
    (psWasmStringRuntimeU32Binary
      PsVerifiedIrIntegerBinaryOp.bitAnd
      b3
      (psWasmStringRuntimeU32 63))

def psWasmStringRuntimeGetDeclaration :
    PsVerifiedIrDeclaration :=
  {
    name := psWasmStringRuntimeGetName
    typeParameters := []
    parameters := [
      {
        name := "value"
        type := psWasmStringSemanticType
      },
      {
        name := "position"
        type := psWasmStringRuntimeNatType
      }
    ]
    resultType := psWasmStringRuntimeCharType
    body :=
      PsVerifiedIrExpr.ifE
        (psWasmStringRuntimeCall
          psWasmStringRuntimeAtEndName
          [
            PsVerifiedIrExpr.var "value",
            PsVerifiedIrExpr.var "position"
          ])
        (psWasmStringRuntimeU32 65)
        (PsVerifiedIrExpr.letE
          "b0"
          psWasmStringRuntimeU32Type
          (psWasmStringRuntimeArrayGet
            (PsVerifiedIrExpr.var "value")
            (PsVerifiedIrExpr.var "position"))
          (PsVerifiedIrExpr.ifE
            (psWasmStringRuntimeU32Compare
              PsVerifiedIrIntegerCompareOp.eq
              (psWasmStringRuntimeU32Binary
                PsVerifiedIrIntegerBinaryOp.bitAnd
                (PsVerifiedIrExpr.var "b0")
                (psWasmStringRuntimeU32 192))
              (psWasmStringRuntimeU32 128))
            (psWasmStringRuntimeU32 65)
            (PsVerifiedIrExpr.ifE
              (psWasmStringRuntimeU32Compare
                PsVerifiedIrIntegerCompareOp.lt
                (PsVerifiedIrExpr.var "b0")
                (psWasmStringRuntimeU32 128))
              (PsVerifiedIrExpr.var "b0")
              (PsVerifiedIrExpr.ifE
                (psWasmStringRuntimeU32Compare
                  PsVerifiedIrIntegerCompareOp.lt
                  (PsVerifiedIrExpr.var "b0")
                  (psWasmStringRuntimeU32 224))
                (psWasmStringRuntimeDecode2
                  (PsVerifiedIrExpr.var "b0")
                  (psWasmStringRuntimeArrayGetD
                    (PsVerifiedIrExpr.var "value")
                    (psWasmStringRuntimeNatAdd
                      (PsVerifiedIrExpr.var "position")
                      (psWasmStringRuntimeNat 1))
                    (psWasmStringRuntimeU32 0)))
                (PsVerifiedIrExpr.ifE
                  (psWasmStringRuntimeU32Compare
                    PsVerifiedIrIntegerCompareOp.lt
                    (PsVerifiedIrExpr.var "b0")
                    (psWasmStringRuntimeU32 240))
                  (psWasmStringRuntimeDecode3
                    (PsVerifiedIrExpr.var "b0")
                    (psWasmStringRuntimeArrayGetD
                      (PsVerifiedIrExpr.var "value")
                      (psWasmStringRuntimeNatAdd
                        (PsVerifiedIrExpr.var "position")
                        (psWasmStringRuntimeNat 1))
                      (psWasmStringRuntimeU32 0))
                    (psWasmStringRuntimeArrayGetD
                      (PsVerifiedIrExpr.var "value")
                      (psWasmStringRuntimeNatAdd
                        (PsVerifiedIrExpr.var "position")
                        (psWasmStringRuntimeNat 2))
                      (psWasmStringRuntimeU32 0)))
                  (psWasmStringRuntimeDecode4
                    (PsVerifiedIrExpr.var "b0")
                    (psWasmStringRuntimeArrayGetD
                      (PsVerifiedIrExpr.var "value")
                      (psWasmStringRuntimeNatAdd
                        (PsVerifiedIrExpr.var "position")
                        (psWasmStringRuntimeNat 1))
                      (psWasmStringRuntimeU32 0))
                    (psWasmStringRuntimeArrayGetD
                      (PsVerifiedIrExpr.var "value")
                      (psWasmStringRuntimeNatAdd
                        (PsVerifiedIrExpr.var "position")
                        (psWasmStringRuntimeNat 2))
                      (psWasmStringRuntimeU32 0))
                    (psWasmStringRuntimeArrayGetD
                      (PsVerifiedIrExpr.var "value")
                      (psWasmStringRuntimeNatAdd
                        (PsVerifiedIrExpr.var "position")
                        (psWasmStringRuntimeNat 3))
                      (psWasmStringRuntimeU32 0))))))))
  }

def psWasmStringRuntimeEqFromDeclaration :
    PsVerifiedIrDeclaration :=
  {
    name := psWasmStringRuntimeEqFromName
    typeParameters := []
    parameters := [
      {
        name := "left"
        type := psWasmStringSemanticType
      },
      {
        name := "right"
        type := psWasmStringSemanticType
      },
      {
        name := "index"
        type := psWasmStringRuntimeNatType
      }
    ]
    resultType := psWasmStringRuntimeBoolType
    body :=
      PsVerifiedIrExpr.ifE
        (psWasmStringRuntimeNatLt
          (PsVerifiedIrExpr.var "index")
          (psWasmStringRuntimeArraySize
            (PsVerifiedIrExpr.var "left")))
        (PsVerifiedIrExpr.ifE
          (psWasmStringRuntimeU32Compare
            PsVerifiedIrIntegerCompareOp.eq
            (psWasmStringRuntimeArrayGet
              (PsVerifiedIrExpr.var "left")
              (PsVerifiedIrExpr.var "index"))
            (psWasmStringRuntimeArrayGet
              (PsVerifiedIrExpr.var "right")
              (PsVerifiedIrExpr.var "index")))
          (psWasmStringRuntimeCall
            psWasmStringRuntimeEqFromName
            [
              PsVerifiedIrExpr.var "left",
              PsVerifiedIrExpr.var "right",
              psWasmStringRuntimeNatAdd
                (PsVerifiedIrExpr.var "index")
                (psWasmStringRuntimeNat 1)
            ])
          (psWasmStringRuntimeBool false))
        (psWasmStringRuntimeBool true)
  }

def psWasmStringRuntimeEqDeclaration :
    PsVerifiedIrDeclaration :=
  {
    name := psWasmStringRuntimeEqName
    typeParameters := []
    parameters := [
      {
        name := "left"
        type := psWasmStringSemanticType
      },
      {
        name := "right"
        type := psWasmStringSemanticType
      }
    ]
    resultType := psWasmStringRuntimeBoolType
    body :=
      PsVerifiedIrExpr.ifE
        (psWasmStringRuntimeNatEq
          (psWasmStringRuntimeArraySize
            (PsVerifiedIrExpr.var "left"))
          (psWasmStringRuntimeArraySize
            (PsVerifiedIrExpr.var "right")))
        (psWasmStringRuntimeCall
          psWasmStringRuntimeEqFromName
          [
            PsVerifiedIrExpr.var "left",
            PsVerifiedIrExpr.var "right",
            psWasmStringRuntimeNat 0
          ])
        (psWasmStringRuntimeBool false)
  }

def psWasmStringRuntimeExtractDeclaration :
    PsVerifiedIrDeclaration :=
  {
    name := psWasmStringRuntimeExtractName
    typeParameters := []
    parameters := [
      {
        name := "value"
        type := psWasmStringSemanticType
      },
      {
        name := "start"
        type := psWasmStringRuntimeNatType
      },
      {
        name := "stop"
        type := psWasmStringRuntimeNatType
      }
    ]
    resultType := psWasmStringSemanticType
    body :=
      PsVerifiedIrExpr.ifE
        (psWasmStringRuntimeNatLe
          (PsVerifiedIrExpr.var "stop")
          (PsVerifiedIrExpr.var "start"))
        (psWasmStringRuntimeArrayEmpty
          (psWasmStringRuntimeNat 0))
        (psWasmStringRuntimeArrayFold
          (PsVerifiedIrExpr.lambda
            [
              {
                name := "out"
                type := psWasmStringSemanticType
              },
              {
                name := "byte"
                type := psWasmStringRuntimeU32Type
              }
            ]
            psWasmStringSemanticType
            (psWasmStringRuntimeArrayPush
              (PsVerifiedIrExpr.var "out")
              (PsVerifiedIrExpr.var "byte")))
          (psWasmStringRuntimeArrayEmpty
            (psWasmStringRuntimeNat 0))
          (PsVerifiedIrExpr.var "value")
          (PsVerifiedIrExpr.var "start")
          (PsVerifiedIrExpr.var "stop"))
  }

def psWasmStringRuntimeDeclarations :
    List PsVerifiedIrDeclaration :=
  [
    psWasmStringRuntimeCharToNatDeclaration,
    psWasmStringRuntimeCharOfNatDeclaration,
    psWasmStringRuntimeSingletonDeclaration,
    psWasmStringRuntimeAppendDeclaration,
    psWasmStringRuntimePushDeclaration,
    psWasmStringRuntimeLengthDeclaration,
    psWasmStringRuntimeUtf8ByteSizeDeclaration,
    psWasmStringRuntimeAtEndDeclaration,
    psWasmStringRuntimeNextDeclaration,
    psWasmStringRuntimeGetDeclaration,
    psWasmStringRuntimeEqFromDeclaration,
    psWasmStringRuntimeEqDeclaration,
    psWasmStringRuntimeExtractDeclaration
  ]

def psWasmStringIntrinsicName :
    PsVerifiedIrIntrinsic -> Option String
  | .stringPush => some psWasmStringRuntimePushName
  | .stringSingleton => some psWasmStringRuntimeSingletonName
  | .stringLength => some psWasmStringRuntimeLengthName
  | .stringAppend => some psWasmStringRuntimeAppendName
  | .stringUtf8ByteSize => some psWasmStringRuntimeUtf8ByteSizeName
  | .stringNext => some psWasmStringRuntimeNextName
  | .stringGet => some psWasmStringRuntimeGetName
  | .stringAtEnd => some psWasmStringRuntimeAtEndName
  | .stringExtract => some psWasmStringRuntimeExtractName
  | .stringEq => some psWasmStringRuntimeEqName
  | _ => none

def psWasmRewriteStringTypeWithFuel :
    Nat -> PsVerifiedIrType -> PsVerifiedIrType
  | 0, type => type
  | fuel + 1, type =>
      let rewrite := psWasmRewriteStringTypeWithFuel fuel
      match type with
      | .unknown => PsVerifiedIrType.unknown
      | .typeParameter name =>
          PsVerifiedIrType.typeParameter name
      | .primitive .string =>
          psWasmStringRuntimeType
      | .primitive primitive =>
          PsVerifiedIrType.primitive primitive
      | .named name arguments =>
          PsVerifiedIrType.named
            name
            (arguments.map rewrite)
      | .function parameters result =>
          PsVerifiedIrType.function
            (parameters.map rewrite)
            (rewrite result)

def psWasmRewriteStringType
    (type : PsVerifiedIrType) : PsVerifiedIrType :=
  psWasmRewriteStringTypeWithFuel 128 type

def psWasmRewriteStringParameter
    (parameter : PsVerifiedIrParameter) :
    PsVerifiedIrParameter :=
  {
    name := parameter.name
    type := psWasmRewriteStringType parameter.type
  }

def psWasmRewriteStringMatchBinding
    (binding : PsVerifiedIrMatchBinding) :
    PsVerifiedIrMatchBinding :=
  {
    field := binding.field
    name := binding.name
    type := psWasmRewriteStringType binding.type
  }

def psWasmRewriteStringIntrinsic
    (operation : PsVerifiedIrIntrinsic) :
    PsVerifiedIrIntrinsic :=
  match operation with
  | .arrayEmptyWithCapacity elementType =>
      PsVerifiedIrIntrinsic.arrayEmptyWithCapacity
        (psWasmRewriteStringType elementType)
  | .arraySize elementType =>
      PsVerifiedIrIntrinsic.arraySize
        (psWasmRewriteStringType elementType)
  | .arrayPush elementType =>
      PsVerifiedIrIntrinsic.arrayPush
        (psWasmRewriteStringType elementType)
  | .arrayGet elementType =>
      PsVerifiedIrIntrinsic.arrayGet
        (psWasmRewriteStringType elementType)
  | .arrayGetD elementType =>
      PsVerifiedIrIntrinsic.arrayGetD
        (psWasmRewriteStringType elementType)
  | .arraySet elementType =>
      PsVerifiedIrIntrinsic.arraySet
        (psWasmRewriteStringType elementType)
  | .arraySetIfInBounds elementType =>
      PsVerifiedIrIntrinsic.arraySetIfInBounds
        (psWasmRewriteStringType elementType)
  | .arrayMap sourceType resultType =>
      PsVerifiedIrIntrinsic.arrayMap
        (psWasmRewriteStringType sourceType)
        (psWasmRewriteStringType resultType)
  | .arrayFoldl elementType accumulatorType =>
      PsVerifiedIrIntrinsic.arrayFoldl
        (psWasmRewriteStringType elementType)
        (psWasmRewriteStringType accumulatorType)
  | other => other

def psWasmRewriteStringExprWithFuel :
    Nat -> PsVerifiedIrExpr -> PsVerifiedIrExpr
  | 0, expression => expression
  | fuel + 1, expression =>
      let rewrite := psWasmRewriteStringExprWithFuel fuel
      match expression with
      | .literal (.string value) =>
          psWasmStringLiteralExpr value
      | .literal literal =>
          PsVerifiedIrExpr.literal literal
      | .var name =>
          PsVerifiedIrExpr.var name
      | .intrinsic operation arguments =>
          let rewritten := arguments.map rewrite
          match operation with
          | .charOfNat =>
              psWasmStringRuntimeCall
                psWasmStringRuntimeCharOfNatName
                rewritten
          | .charToNat =>
              psWasmStringRuntimeCall
                psWasmStringRuntimeCharToNatName
                rewritten
          | _ =>
              match psWasmStringIntrinsicName operation with
              | some name =>
                  psWasmStringRuntimeCall name rewritten
              | none =>
                  PsVerifiedIrExpr.intrinsic
                    (psWasmRewriteStringIntrinsic operation)
                    rewritten
      | .lambda parameters resultType body =>
          PsVerifiedIrExpr.lambda
            (parameters.map psWasmRewriteStringParameter)
            (psWasmRewriteStringType resultType)
            (rewrite body)
      | .call fn typeArguments arguments =>
          PsVerifiedIrExpr.call
            (rewrite fn)
            (typeArguments.map psWasmRewriteStringType)
            (arguments.map rewrite)
      | .letE name type value body =>
          PsVerifiedIrExpr.letE
            name
            (psWasmRewriteStringType type)
            (rewrite value)
            (rewrite body)
      | .ifE condition thenBranch elseBranch =>
          PsVerifiedIrExpr.ifE
            (rewrite condition)
            (rewrite thenBranch)
            (rewrite elseBranch)
      | .record structureName typeArguments fields =>
          PsVerifiedIrExpr.record
            structureName
            (typeArguments.map psWasmRewriteStringType)
            (fields.map
              (fun field => (field.1, rewrite field.2)))
      | .projection structureName typeArguments target field =>
          PsVerifiedIrExpr.projection
            structureName
            (typeArguments.map psWasmRewriteStringType)
            (rewrite target)
            field
      | .constructor inductiveName constructorName typeArguments fields =>
          PsVerifiedIrExpr.constructor
            inductiveName
            constructorName
            (typeArguments.map psWasmRewriteStringType)
            (fields.map
              (fun field => (field.1, rewrite field.2)))
      | .matchE inductiveName typeArguments scrutinee alternatives =>
          PsVerifiedIrExpr.matchE
            inductiveName
            (typeArguments.map psWasmRewriteStringType)
            (rewrite scrutinee)
            (alternatives.map
              (fun alternative =>
                (
                  alternative.1,
                  alternative.2.1.map
                    psWasmRewriteStringMatchBinding,
                  rewrite alternative.2.2
                )))

def psWasmRewriteStringStructureField
    (field : PsVerifiedIrStructureField) :
    PsVerifiedIrStructureField :=
  {
    name := field.name
    type := psWasmRewriteStringType field.type
  }

def psWasmRewriteStringStructure
    (structureInfo : PsVerifiedIrStructure) :
    PsVerifiedIrStructure :=
  {
    name := structureInfo.name
    typeParameters := structureInfo.typeParameters
    fields :=
      structureInfo.fields.map
        psWasmRewriteStringStructureField
  }

def psWasmRewriteStringConstructorField
    (field : PsVerifiedIrConstructorField) :
    PsVerifiedIrConstructorField :=
  {
    name := field.name
    type := psWasmRewriteStringType field.type
  }

def psWasmRewriteStringConstructor
    (constructorInfo : PsVerifiedIrConstructor) :
    PsVerifiedIrConstructor :=
  {
    name := constructorInfo.name
    fields :=
      constructorInfo.fields.map
        psWasmRewriteStringConstructorField
  }

def psWasmRewriteStringInductive
    (inductiveInfo : PsVerifiedIrInductive) :
    PsVerifiedIrInductive :=
  {
    name := inductiveInfo.name
    typeParameters := inductiveInfo.typeParameters
    constructors :=
      inductiveInfo.constructors.map
        psWasmRewriteStringConstructor
  }

def psWasmRewriteStringImport
    (importInfo : PsVerifiedIrExternalImport) :
    PsVerifiedIrExternalImport :=
  {
    localName := importInfo.localName
    source := importInfo.source
    importedName := importInfo.importedName
    type := psWasmRewriteStringType importInfo.type
  }

def psWasmRewriteStringDeclaration
    (declaration : PsVerifiedIrDeclaration) :
    PsVerifiedIrDeclaration :=
  {
    name := declaration.name
    typeParameters := declaration.typeParameters
    parameters :=
      declaration.parameters.map psWasmRewriteStringParameter
    resultType :=
      psWasmRewriteStringType declaration.resultType
    body :=
      psWasmRewriteStringExprWithFuel
        4096
        declaration.body
  }

def psWasmRewriteStringModule
    (module : PsVerifiedIrModule) : PsVerifiedIrModule :=
  {
    imports := module.imports.map psWasmRewriteStringImport
    structures :=
      module.structures.map psWasmRewriteStringStructure
    inductives :=
      module.inductives.map psWasmRewriteStringInductive
    declarations :=
      module.declarations.map psWasmRewriteStringDeclaration
  }

def psWasmAugmentStringRuntime
    (module : PsVerifiedIrModule) : PsVerifiedIrModule :=
  psWasmRewriteStringModule
    {
      imports := module.imports
      structures := module.structures
      inductives := module.inductives
      declarations :=
        module.declarations ++ psWasmStringRuntimeDeclarations
    }
