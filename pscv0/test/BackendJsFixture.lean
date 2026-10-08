import Ps.CompilerIr.Interface

def psBackendJsNatType : PsVerifiedIrType :=
  PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat

def psBackendJsArrayNatType : PsVerifiedIrType :=
  PsVerifiedIrType.named "Array" [psBackendJsNatType]

def psBackendJsNatUnaryFunctionType : PsVerifiedIrType :=
  PsVerifiedIrType.function
    [psBackendJsNatType]
    psBackendJsNatType

def psBackendJsNatBinaryFunctionType : PsVerifiedIrType :=
  PsVerifiedIrType.function
    [psBackendJsNatType, psBackendJsNatType]
    psBackendJsNatType

def psBackendJsTypeA : PsVerifiedIrType :=
  PsVerifiedIrType.typeParameter "A"

def psBackendJsPointType : PsVerifiedIrType :=
  PsVerifiedIrType.named "Point" []

def psBackendJsBoxNatType : PsVerifiedIrType :=
  PsVerifiedIrType.named "Box" [psBackendJsNatType]

def psBackendJsMaybeNatType : PsVerifiedIrType :=
  PsVerifiedIrType.named "MaybeNat" []

def psBackendJsOptionNatType : PsVerifiedIrType :=
  PsVerifiedIrType.named "Option" [psBackendJsNatType]

def psBackendJsFixtureModule : PsVerifiedIrModule :=
  {
    imports := [
      {
        localName := "externalAdd"
        source := "./support.js"
        importedName := "importedAdd"
        type := psBackendJsNatBinaryFunctionType
      },
      {
        localName := "namedIdentity"
        source := "./support.js"
        importedName := "namedIdentity"
        type := psBackendJsNatUnaryFunctionType
      },
      {
        localName := "externalDefault"
        source := "./support.js"
        importedName := "default"
        type := psBackendJsNatUnaryFunctionType
      }
    ]
    structures := [
      {
        name := "Point"
        typeParameters := []
        fields := [
          {
            name := "x"
            type := psBackendJsNatType
          },
          {
            name := "y"
            type := psBackendJsNatType
          }
        ]
      },
      {
        name := "Box"
        typeParameters := [{ name := "A" }]
        fields := [
          {
            name := "value"
            type := psBackendJsTypeA
          }
        ]
      }
    ]
    inductives := [
      {
        name := "MaybeNat"
        typeParameters := []
        constructors := [
          {
            name := "none"
            fields := []
          },
          {
            name := "some"
            fields := [
              {
                name := "value"
                type := psBackendJsNatType
              }
            ]
          }
        ]
      },
      {
        name := "Option"
        typeParameters := [{ name := "A" }]
        constructors := [
          {
            name := "none"
            fields := []
          },
          {
            name := "some"
            fields := [
              {
                name := "value"
                type := psBackendJsTypeA
              }
            ]
          }
        ]
      }
    ]
    declarations := [
      {
        name := "answer"
        typeParameters := []
        parameters := []
        resultType :=
          PsVerifiedIrType.primitive
            PsVerifiedIrPrimitiveType.nat
        body :=
          PsVerifiedIrExpr.literal
            (PsVerifiedIrLiteral.natural 42)
      },
      {
        name := "idNat"
        typeParameters := []
        parameters := [
          {
            name := "x"
            type :=
              PsVerifiedIrType.primitive
                PsVerifiedIrPrimitiveType.nat
          }
        ]
        resultType :=
          PsVerifiedIrType.primitive
            PsVerifiedIrPrimitiveType.nat
        body := PsVerifiedIrExpr.var "x"
      },
      {
        name := "plusOne"
        typeParameters := []
        parameters := [
          {
            name := "x"
            type :=
              PsVerifiedIrType.primitive
                PsVerifiedIrPrimitiveType.nat
          }
        ]
        resultType :=
          PsVerifiedIrType.primitive
            PsVerifiedIrPrimitiveType.nat
        body :=
          PsVerifiedIrExpr.intrinsic
            PsVerifiedIrIntrinsic.natAdd
            []
            [
              PsVerifiedIrExpr.var "x",
              PsVerifiedIrExpr.literal
                (PsVerifiedIrLiteral.natural 1)
            ]
      },
      {
        name := "choose"
        typeParameters := []
        parameters := [
          {
            name := "flag"
            type :=
              PsVerifiedIrType.primitive
                PsVerifiedIrPrimitiveType.bool
          },
          {
            name := "left"
            type :=
              PsVerifiedIrType.primitive
                PsVerifiedIrPrimitiveType.nat
          },
          {
            name := "right"
            type :=
              PsVerifiedIrType.primitive
                PsVerifiedIrPrimitiveType.nat
          }
        ]
        resultType :=
          PsVerifiedIrType.primitive
            PsVerifiedIrPrimitiveType.nat
        body :=
          PsVerifiedIrExpr.ifE
            (PsVerifiedIrExpr.var "flag")
            (PsVerifiedIrExpr.var "left")
            (PsVerifiedIrExpr.var "right")
      },
      {
        name := "callPlusOne"
        typeParameters := []
        parameters := [
          {
            name := "x"
            type :=
              PsVerifiedIrType.primitive
                PsVerifiedIrPrimitiveType.nat
          }
        ]
        resultType :=
          PsVerifiedIrType.primitive
            PsVerifiedIrPrimitiveType.nat
        body :=
          PsVerifiedIrExpr.call
            (PsVerifiedIrExpr.var "plusOne")
            []
            [PsVerifiedIrExpr.var "x"]
      },
      {
        name := "greeting"
        typeParameters := []
        parameters := []
        resultType :=
          PsVerifiedIrType.primitive
            PsVerifiedIrPrimitiveType.string
        body :=
          PsVerifiedIrExpr.literal
            (PsVerifiedIrLiteral.string "hello")
      },
      {
        name := "truth"
        typeParameters := []
        parameters := []
        resultType :=
          PsVerifiedIrType.primitive
            PsVerifiedIrPrimitiveType.bool
        body :=
          PsVerifiedIrExpr.literal
            (PsVerifiedIrLiteral.bool true)
      },
      {
        name := "unitValue"
        typeParameters := []
        parameters := []
        resultType :=
          PsVerifiedIrType.primitive
            PsVerifiedIrPrimitiveType.unit
        body :=
          PsVerifiedIrExpr.literal
            PsVerifiedIrLiteral.unit
      },
      {
        name := "natSubDemo"
        typeParameters := []
        parameters := [
          {
            name := "left"
            type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat
          },
          {
            name := "right"
            type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat
          }
        ]
        resultType := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat
        body :=
          PsVerifiedIrExpr.intrinsic
            PsVerifiedIrIntrinsic.natSub
            []
            [PsVerifiedIrExpr.var "left", PsVerifiedIrExpr.var "right"]
      },
      {
        name := "natDivDemo"
        typeParameters := []
        parameters := [
          {
            name := "left"
            type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat
          },
          {
            name := "right"
            type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat
          }
        ]
        resultType := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat
        body :=
          PsVerifiedIrExpr.intrinsic
            PsVerifiedIrIntrinsic.natDiv
            []
            [PsVerifiedIrExpr.var "left", PsVerifiedIrExpr.var "right"]
      },
      {
        name := "natModDemo"
        typeParameters := []
        parameters := [
          {
            name := "left"
            type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat
          },
          {
            name := "right"
            type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat
          }
        ]
        resultType := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat
        body :=
          PsVerifiedIrExpr.intrinsic
            PsVerifiedIrIntrinsic.natMod
            []
            [PsVerifiedIrExpr.var "left", PsVerifiedIrExpr.var "right"]
      },
      {
        name := "intNegDemo"
        typeParameters := []
        parameters := [
          {
            name := "value"
            type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.int
          }
        ]
        resultType := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.int
        body :=
          PsVerifiedIrExpr.intrinsic
            PsVerifiedIrIntrinsic.intNeg
            []
            [PsVerifiedIrExpr.var "value"]
      },
      {
        name := "boolAndDemo"
        typeParameters := []
        parameters := [
          {
            name := "left"
            type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.bool
          },
          {
            name := "right"
            type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.bool
          }
        ]
        resultType := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.bool
        body :=
          PsVerifiedIrExpr.intrinsic
            PsVerifiedIrIntrinsic.boolAnd
            []
            [PsVerifiedIrExpr.var "left", PsVerifiedIrExpr.var "right"]
      },
      {
        name := "stringLengthDemo"
        typeParameters := []
        parameters := [
          {
            name := "value"
            type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.string
          }
        ]
        resultType := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat
        body :=
          PsVerifiedIrExpr.intrinsic
            PsVerifiedIrIntrinsic.stringLength
            []
            [PsVerifiedIrExpr.var "value"]
      },
      {
        name := "stringUtf8ByteSizeDemo"
        typeParameters := []
        parameters := [
          {
            name := "value"
            type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.string
          }
        ]
        resultType := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat
        body :=
          PsVerifiedIrExpr.intrinsic
            PsVerifiedIrIntrinsic.stringUtf8ByteSize
            []
            [PsVerifiedIrExpr.var "value"]
      },
      {
        name := "stringNextDemo"
        typeParameters := []
        parameters := [
          {
            name := "value"
            type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.string
          },
          {
            name := "position"
            type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat
          }
        ]
        resultType := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat
        body :=
          PsVerifiedIrExpr.intrinsic
            PsVerifiedIrIntrinsic.stringNext
            []
            [
              PsVerifiedIrExpr.var "value",
              PsVerifiedIrExpr.var "position"
            ]
      },
      {
        name := "stringGetDemo"
        typeParameters := []
        parameters := [
          {
            name := "value"
            type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.string
          },
          {
            name := "position"
            type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat
          }
        ]
        resultType := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.char
        body :=
          PsVerifiedIrExpr.intrinsic
            PsVerifiedIrIntrinsic.stringGet
            []
            [
              PsVerifiedIrExpr.var "value",
              PsVerifiedIrExpr.var "position"
            ]
      },
      {
        name := "stringAtEndDemo"
        typeParameters := []
        parameters := [
          {
            name := "value"
            type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.string
          },
          {
            name := "position"
            type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat
          }
        ]
        resultType := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.bool
        body :=
          PsVerifiedIrExpr.intrinsic
            PsVerifiedIrIntrinsic.stringAtEnd
            []
            [
              PsVerifiedIrExpr.var "value",
              PsVerifiedIrExpr.var "position"
            ]
      },
      {
        name := "stringExtractDemo"
        typeParameters := []
        parameters := [
          {
            name := "value"
            type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.string
          },
          {
            name := "start"
            type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat
          },
          {
            name := "stop"
            type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat
          }
        ]
        resultType := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.string
        body :=
          PsVerifiedIrExpr.intrinsic
            PsVerifiedIrIntrinsic.stringExtract
            []
            [
              PsVerifiedIrExpr.var "value",
              PsVerifiedIrExpr.var "start",
              PsVerifiedIrExpr.var "stop"
            ]
      },
      {
        name := "arrayEmptyDemo"
        typeParameters := []
        parameters := [
          {
            name := "capacity"
            type := psBackendJsNatType
          }
        ]
        resultType := psBackendJsArrayNatType
        body :=
          PsVerifiedIrExpr.intrinsic
            PsVerifiedIrIntrinsic.arrayEmptyWithCapacity
            [psBackendJsNatType]
            [PsVerifiedIrExpr.var "capacity"]
      },
      {
        name := "arraySizeDemo"
        typeParameters := []
        parameters := [
          {
            name := "array"
            type := psBackendJsArrayNatType
          }
        ]
        resultType := psBackendJsNatType
        body :=
          PsVerifiedIrExpr.intrinsic
            PsVerifiedIrIntrinsic.arraySize
            [psBackendJsNatType]
            [PsVerifiedIrExpr.var "array"]
      },
      {
        name := "arrayPushDemo"
        typeParameters := []
        parameters := [
          {
            name := "array"
            type := psBackendJsArrayNatType
          },
          {
            name := "value"
            type := psBackendJsNatType
          }
        ]
        resultType := psBackendJsArrayNatType
        body :=
          PsVerifiedIrExpr.intrinsic
            PsVerifiedIrIntrinsic.arrayPush
            [psBackendJsNatType]
            [
              PsVerifiedIrExpr.var "array",
              PsVerifiedIrExpr.var "value"
            ]
      },
      {
        name := "arrayGetDemo"
        typeParameters := []
        parameters := [
          {
            name := "array"
            type := psBackendJsArrayNatType
          },
          {
            name := "index"
            type := psBackendJsNatType
          }
        ]
        resultType := psBackendJsNatType
        body :=
          PsVerifiedIrExpr.intrinsic
            PsVerifiedIrIntrinsic.arrayGet
            [psBackendJsNatType]
            [
              PsVerifiedIrExpr.var "array",
              PsVerifiedIrExpr.var "index"
            ]
      },
      {
        name := "arrayGetDDemo"
        typeParameters := []
        parameters := [
          {
            name := "array"
            type := psBackendJsArrayNatType
          },
          {
            name := "index"
            type := psBackendJsNatType
          },
          {
            name := "fallback"
            type := psBackendJsNatType
          }
        ]
        resultType := psBackendJsNatType
        body :=
          PsVerifiedIrExpr.intrinsic
            PsVerifiedIrIntrinsic.arrayGetD
            [psBackendJsNatType]
            [
              PsVerifiedIrExpr.var "array",
              PsVerifiedIrExpr.var "index",
              PsVerifiedIrExpr.var "fallback"
            ]
      },
      {
        name := "arraySetDemo"
        typeParameters := []
        parameters := [
          {
            name := "array"
            type := psBackendJsArrayNatType
          },
          {
            name := "index"
            type := psBackendJsNatType
          },
          {
            name := "value"
            type := psBackendJsNatType
          }
        ]
        resultType := psBackendJsArrayNatType
        body :=
          PsVerifiedIrExpr.intrinsic
            PsVerifiedIrIntrinsic.arraySet
            [psBackendJsNatType]
            [
              PsVerifiedIrExpr.var "array",
              PsVerifiedIrExpr.var "index",
              PsVerifiedIrExpr.var "value"
            ]
      },
      {
        name := "arraySetIfInBoundsDemo"
        typeParameters := []
        parameters := [
          {
            name := "array"
            type := psBackendJsArrayNatType
          },
          {
            name := "index"
            type := psBackendJsNatType
          },
          {
            name := "value"
            type := psBackendJsNatType
          }
        ]
        resultType := psBackendJsArrayNatType
        body :=
          PsVerifiedIrExpr.intrinsic
            PsVerifiedIrIntrinsic.arraySetIfInBounds
            [psBackendJsNatType]
            [
              PsVerifiedIrExpr.var "array",
              PsVerifiedIrExpr.var "index",
              PsVerifiedIrExpr.var "value"
            ]
      },
      {
        name := "arrayMapDemo"
        typeParameters := []
        parameters := [
          {
            name := "fn"
            type := psBackendJsNatUnaryFunctionType
          },
          {
            name := "array"
            type := psBackendJsArrayNatType
          }
        ]
        resultType := psBackendJsArrayNatType
        body :=
          PsVerifiedIrExpr.intrinsic
            PsVerifiedIrIntrinsic.arrayMap
            [psBackendJsNatType, psBackendJsNatType]
            [
              PsVerifiedIrExpr.var "fn",
              PsVerifiedIrExpr.var "array"
            ]
      },
      {
        name := "arrayFoldDemo"
        typeParameters := []
        parameters := [
          {
            name := "fn"
            type := psBackendJsNatBinaryFunctionType
          },
          {
            name := "init"
            type := psBackendJsNatType
          },
          {
            name := "array"
            type := psBackendJsArrayNatType
          },
          {
            name := "start"
            type := psBackendJsNatType
          },
          {
            name := "stop"
            type := psBackendJsNatType
          }
        ]
        resultType := psBackendJsNatType
        body :=
          PsVerifiedIrExpr.intrinsic
            PsVerifiedIrIntrinsic.arrayFoldl
            [psBackendJsNatType, psBackendJsNatType]
            [
              PsVerifiedIrExpr.var "fn",
              PsVerifiedIrExpr.var "init",
              PsVerifiedIrExpr.var "array",
              PsVerifiedIrExpr.var "start",
              PsVerifiedIrExpr.var "stop"
            ]
      },
      {
        name := "externalAddDemo"
        typeParameters := []
        parameters := [
          {
            name := "left"
            type := psBackendJsNatType
          },
          {
            name := "right"
            type := psBackendJsNatType
          }
        ]
        resultType := psBackendJsNatType
        body :=
          PsVerifiedIrExpr.call
            (PsVerifiedIrExpr.var "externalAdd")
            []
            [
              PsVerifiedIrExpr.var "left",
              PsVerifiedIrExpr.var "right"
            ]
      },
      {
        name := "externalNamedDemo"
        typeParameters := []
        parameters := [
          {
            name := "value"
            type := psBackendJsNatType
          }
        ]
        resultType := psBackendJsNatType
        body :=
          PsVerifiedIrExpr.call
            (PsVerifiedIrExpr.var "namedIdentity")
            []
            [PsVerifiedIrExpr.var "value"]
      },
      {
        name := "externalDefaultDemo"
        typeParameters := []
        parameters := [
          {
            name := "value"
            type := psBackendJsNatType
          }
        ]
        resultType := psBackendJsNatType
        body :=
          PsVerifiedIrExpr.call
            (PsVerifiedIrExpr.var "externalDefault")
            []
            [PsVerifiedIrExpr.var "value"]
      },
      {
        name := "genericId"
        typeParameters := [{ name := "A" }]
        parameters := [
          {
            name := "x"
            type := psBackendJsTypeA
          }
        ]
        resultType := psBackendJsTypeA
        body := PsVerifiedIrExpr.var "x"
      },
      {
        name := "genericIdNat"
        typeParameters := []
        parameters := [
          {
            name := "value"
            type := psBackendJsNatType
          }
        ]
        resultType := psBackendJsNatType
        body :=
          PsVerifiedIrExpr.call
            (PsVerifiedIrExpr.var "genericId")
            [psBackendJsNatType]
            [PsVerifiedIrExpr.var "value"]
      },
      {
        name := "pointSum"
        typeParameters := []
        parameters := [
          {
            name := "left"
            type := psBackendJsNatType
          },
          {
            name := "right"
            type := psBackendJsNatType
          }
        ]
        resultType := psBackendJsNatType
        body :=
          PsVerifiedIrExpr.letE
            "point"
            psBackendJsPointType
            (PsVerifiedIrExpr.record
              "Point"
              []
              [
                ("x", PsVerifiedIrExpr.var "left"),
                ("y", PsVerifiedIrExpr.var "right")
              ])
            (PsVerifiedIrExpr.intrinsic
              PsVerifiedIrIntrinsic.natAdd
              []
              [
                PsVerifiedIrExpr.projection
                  "Point"
                  []
                  (PsVerifiedIrExpr.var "point")
                  "x",
                PsVerifiedIrExpr.projection
                  "Point"
                  []
                  (PsVerifiedIrExpr.var "point")
                  "y"
              ])
      },
      {
        name := "boxNatGet"
        typeParameters := []
        parameters := [
          {
            name := "value"
            type := psBackendJsNatType
          }
        ]
        resultType := psBackendJsNatType
        body :=
          PsVerifiedIrExpr.letE
            "box"
            psBackendJsBoxNatType
            (PsVerifiedIrExpr.record
              "Box"
              [psBackendJsNatType]
              [
                ("value", PsVerifiedIrExpr.var "value")
              ])
            (PsVerifiedIrExpr.projection
              "Box"
              [psBackendJsNatType]
              (PsVerifiedIrExpr.var "box")
              "value")
      },
      {
        name := "maybeSomeOrZero"
        typeParameters := []
        parameters := [
          {
            name := "value"
            type := psBackendJsNatType
          }
        ]
        resultType := psBackendJsNatType
        body :=
          PsVerifiedIrExpr.matchE
            "MaybeNat"
            []
            (PsVerifiedIrExpr.constructor
              "MaybeNat"
              "some"
              []
              [
                ("value", PsVerifiedIrExpr.var "value")
              ])
            [
              ("none", [], PsVerifiedIrExpr.literal
                (PsVerifiedIrLiteral.natural 0)),
              ("some",
                [
                  {
                    field := "value"
                    name := "payload"
                    type := psBackendJsNatType
                  }
                ],
                PsVerifiedIrExpr.var "payload")
            ]
      },
      {
        name := "maybeNoneOr"
        typeParameters := []
        parameters := [
          {
            name := "fallback"
            type := psBackendJsNatType
          }
        ]
        resultType := psBackendJsNatType
        body :=
          PsVerifiedIrExpr.matchE
            "MaybeNat"
            []
            (PsVerifiedIrExpr.constructor
              "MaybeNat"
              "none"
              []
              [])
            [
              ("none", [], PsVerifiedIrExpr.var "fallback"),
              ("some",
                [
                  {
                    field := "value"
                    name := "payload"
                    type := psBackendJsNatType
                  }
                ],
                PsVerifiedIrExpr.var "payload")
            ]
      },
      {
        name := "optionNatSome"
        typeParameters := []
        parameters := [
          {
            name := "value"
            type := psBackendJsNatType
          }
        ]
        resultType := psBackendJsNatType
        body :=
          PsVerifiedIrExpr.matchE
            "Option"
            [psBackendJsNatType]
            (PsVerifiedIrExpr.constructor
              "Option"
              "some"
              [psBackendJsNatType]
              [
                ("value", PsVerifiedIrExpr.var "value")
              ])
            [
              ("none", [], PsVerifiedIrExpr.literal
                (PsVerifiedIrLiteral.natural 0)),
              ("some",
                [
                  {
                    field := "value"
                    name := "payload"
                    type := psBackendJsNatType
                  }
                ],
                PsVerifiedIrExpr.var "payload")
            ]
      },
      {
        name := "matchTempCollision"
        typeParameters := []
        parameters := [
          {
            name := "__ps$match$0"
            type := psBackendJsNatType
          },
          {
            name := "value"
            type := psBackendJsNatType
          }
        ]
        resultType := psBackendJsNatType
        body :=
          PsVerifiedIrExpr.matchE
            "MaybeNat"
            []
            (PsVerifiedIrExpr.constructor
              "MaybeNat"
              "some"
              []
              [
                ("value", PsVerifiedIrExpr.var "value")
              ])
            [
              ("none", [], PsVerifiedIrExpr.var "__ps$match$0"),
              ("some",
                [
                  {
                    field := "value"
                    name := "payload"
                    type := psBackendJsNatType
                  }
                ],
                PsVerifiedIrExpr.intrinsic
                  PsVerifiedIrIntrinsic.natAdd
                  []
                  [
                    PsVerifiedIrExpr.var "__ps$match$0",
                    PsVerifiedIrExpr.var "payload"
                  ])
            ]
      },
      {
        name := "u8AddWrap"
        typeParameters := []
        parameters := [
          {
            name := "left"
            type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.uint8
          },
          {
            name := "right"
            type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.uint8
          }
        ]
        resultType := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.uint8
        body :=
          PsVerifiedIrExpr.intrinsic
            (PsVerifiedIrIntrinsic.machineIntBinary
              PsVerifiedIrMachineIntegerType.uint8
              PsVerifiedIrIntegerBinaryOp.add)
            []
            [PsVerifiedIrExpr.var "left", PsVerifiedIrExpr.var "right"]
      },
      {
        name := "i8MulWrap"
        typeParameters := []
        parameters := [
          {
            name := "left"
            type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.int8
          },
          {
            name := "right"
            type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.int8
          }
        ]
        resultType := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.int8
        body :=
          PsVerifiedIrExpr.intrinsic
            (PsVerifiedIrIntrinsic.machineIntBinary
              PsVerifiedIrMachineIntegerType.int8
              PsVerifiedIrIntegerBinaryOp.mul)
            []
            [PsVerifiedIrExpr.var "left", PsVerifiedIrExpr.var "right"]
      },
      {
        name := "u64Xor"
        typeParameters := []
        parameters := [
          {
            name := "left"
            type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.uint64
          },
          {
            name := "right"
            type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.uint64
          }
        ]
        resultType := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.uint64
        body :=
          PsVerifiedIrExpr.intrinsic
            (PsVerifiedIrIntrinsic.machineIntBinary
              PsVerifiedIrMachineIntegerType.uint64
              PsVerifiedIrIntegerBinaryOp.bitXor)
            []
            [PsVerifiedIrExpr.var "left", PsVerifiedIrExpr.var "right"]
      },
      {
        name := "u16Lt"
        typeParameters := []
        parameters := [
          {
            name := "left"
            type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.uint16
          },
          {
            name := "right"
            type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.uint16
          }
        ]
        resultType := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.bool
        body :=
          PsVerifiedIrExpr.intrinsic
            (PsVerifiedIrIntrinsic.machineIntCompare
              PsVerifiedIrMachineIntegerType.uint16
              PsVerifiedIrIntegerCompareOp.lt)
            []
            [PsVerifiedIrExpr.var "left", PsVerifiedIrExpr.var "right"]
      },
      {
        name := "u8FromNat"
        typeParameters := []
        parameters := [
          {
            name := "value"
            type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat
          }
        ]
        resultType := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.uint8
        body :=
          PsVerifiedIrExpr.intrinsic
            PsVerifiedIrIntrinsic.uint8OfNat
            []
            [PsVerifiedIrExpr.var "value"]
      },
      {
        name := "u8Literal44"
        typeParameters := []
        parameters := []
        resultType := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.uint8
        body :=
          PsVerifiedIrExpr.literal
            (PsVerifiedIrLiteral.machineInteger
              PsVerifiedIrMachineIntegerType.uint8
              44)
      },
      {
        name := "float32Mul"
        typeParameters := []
        parameters := [
          {
            name := "left"
            type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.float32
          },
          {
            name := "right"
            type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.float32
          }
        ]
        resultType := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.float32
        body :=
          PsVerifiedIrExpr.intrinsic
            (PsVerifiedIrIntrinsic.floatBinary
              PsVerifiedIrFloatingType.float32
              PsVerifiedIrFloatBinaryOp.mul)
            []
            [PsVerifiedIrExpr.var "left", PsVerifiedIrExpr.var "right"]
      },
      {
        name := "floatDiv"
        typeParameters := []
        parameters := [
          {
            name := "left"
            type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.float
          },
          {
            name := "right"
            type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.float
          }
        ]
        resultType := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.float
        body :=
          PsVerifiedIrExpr.intrinsic
            (PsVerifiedIrIntrinsic.floatBinary
              PsVerifiedIrFloatingType.float
              PsVerifiedIrFloatBinaryOp.div)
            []
            [PsVerifiedIrExpr.var "left", PsVerifiedIrExpr.var "right"]
      },
      {
        name := "letNatDemo"
        typeParameters := []
        parameters := [
          {
            name := "x"
            type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat
          }
        ]
        resultType := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat
        body :=
          PsVerifiedIrExpr.letE
            "y"
            (PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat)
            (PsVerifiedIrExpr.intrinsic
              PsVerifiedIrIntrinsic.natAdd
              []
              [
                PsVerifiedIrExpr.var "x",
                PsVerifiedIrExpr.literal (PsVerifiedIrLiteral.natural 1)
              ])
            (PsVerifiedIrExpr.intrinsic
              PsVerifiedIrIntrinsic.natMul
              []
              [
                PsVerifiedIrExpr.var "y",
                PsVerifiedIrExpr.literal (PsVerifiedIrLiteral.natural 2)
              ])
      },
      {
        name := "applyLambda"
        typeParameters := []
        parameters := [
          {
            name := "x"
            type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat
          }
        ]
        resultType := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat
        body :=
          PsVerifiedIrExpr.call
            (PsVerifiedIrExpr.lambda
              [
                {
                  name := "y"
                  type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat
                }
              ]
              (PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat)
              (PsVerifiedIrExpr.intrinsic
                PsVerifiedIrIntrinsic.natAdd
                []
                [
                  PsVerifiedIrExpr.var "y",
                  PsVerifiedIrExpr.literal (PsVerifiedIrLiteral.natural 2)
                ]))
            []
            [PsVerifiedIrExpr.var "x"]
      }
    ]
  }

-- Explicit host contract for scripts/backend-js-corpus support.js. The runtime
-- corpus checks its behavior; the interface checker checks the declared ABI.
def psBackendJsFixtureSupport : PsInterfaceIrContract :=
  PsInterfaceIrContract.mk "./support.js"
    "psc-runtime-semantics/1" "psc-runtime-values/1" ["javascript"]
    ["fixture-support"] (PsInterfaceIrOrigin.host "backend-js-corpus/support")
    List.nil List.nil
    [PsInterfaceIrExport.mk "importedAdd" psBackendJsNatBinaryFunctionType,
      PsInterfaceIrExport.mk "namedIdentity" psBackendJsNatUnaryFunctionType,
      PsInterfaceIrExport.mk "default" psBackendJsNatUnaryFunctionType]

def psBackendJsFixtureValidated :
    Except String PsValidatedIrModule :=
  match
      psValidateErasedIrModuleWithInterfaces
        (PsInterfaceIrPolicy.mk "javascript" ["fixture-support"])
        [psBackendJsFixtureSupport]
        (PsErasedIrModule.mk
          psBackendJsFixtureModule) with
  | Except.error _ =>
      Except.error "VALIDATION"
  | Except.ok validated =>
      Except.ok validated
