import Ps.BackendRust.Module

def psBackendRustCompileFixture : PsVerifiedIrModule :=
  {
    imports := []
    structures := [
      {
        name := "Pair"
        typeParameters := []
        fields := [
          {
            name := "left"
            type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat
          },
          {
            name := "right"
            type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat
          }
        ]
      }
    ]
    inductives := [
      {
        name := "Maybe"
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
                type := PsVerifiedIrType.typeParameter "A"
              }
            ]
          }
        ]
      }
    ]
    declarations := [
      {
        name := "plusOne"
        typeParameters := []
        parameters := [
          {
            name := "x"
            type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat
          }
        ]
        resultType := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat
        body :=
          PsVerifiedIrExpr.intrinsic
            PsVerifiedIrIntrinsic.natAdd
            [
              PsVerifiedIrExpr.var "x",
              PsVerifiedIrExpr.literal (PsVerifiedIrLiteral.natural 1)
            ]
      },
      {
        name := "makePair"
        typeParameters := []
        parameters := [
          {
            name := "a"
            type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat
          },
          {
            name := "b"
            type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat
          }
        ]
        resultType := PsVerifiedIrType.named "Pair" []
        body :=
          PsVerifiedIrExpr.record
            "Pair"
            [
              ("left", PsVerifiedIrExpr.var "a"),
              ("right", PsVerifiedIrExpr.var "b")
            ]
      },
      {
        name := "wrapNat"
        typeParameters := []
        parameters := [
          {
            name := "x"
            type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat
          }
        ]
        resultType :=
          PsVerifiedIrType.named
            "Maybe"
            [PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat]
        body :=
          PsVerifiedIrExpr.constructor
            "Maybe"
            "some"
            [PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat]
            [
              ("value", PsVerifiedIrExpr.var "x")
            ]
      },
      {
        name := "pushBang"
        typeParameters := []
        parameters := [
          {
            name := "text"
            type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.string
          }
        ]
        resultType := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.string
        body :=
          PsVerifiedIrExpr.intrinsic
            PsVerifiedIrIntrinsic.stringPush
            [
              PsVerifiedIrExpr.var "text",
              PsVerifiedIrExpr.intrinsic
                PsVerifiedIrIntrinsic.charOfNat
                [
                  PsVerifiedIrExpr.literal
                    (PsVerifiedIrLiteral.natural 33)
                ]
            ]
      },
      {
        name := "utf8Size"
        typeParameters := []
        parameters := [
          {
            name := "text"
            type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.string
          }
        ]
        resultType := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat
        body :=
          PsVerifiedIrExpr.intrinsic
            PsVerifiedIrIntrinsic.stringUtf8ByteSize
            [PsVerifiedIrExpr.var "text"]
      },
      {
        name := "genericId"
        typeParameters := [{ name := "A" }]
        parameters := [
          {
            name := "x"
            type := PsVerifiedIrType.typeParameter "A"
          }
        ]
        resultType := PsVerifiedIrType.typeParameter "A"
        body := PsVerifiedIrExpr.var "x"
      },
      {
        name := "genericArrayId"
        typeParameters := [{ name := "A" }]
        parameters := [
          {
            name := "xs"
            type :=
              PsVerifiedIrType.named
                "Array"
                [PsVerifiedIrType.typeParameter "A"]
          }
        ]
        resultType :=
          PsVerifiedIrType.named
            "Array"
            [PsVerifiedIrType.typeParameter "A"]
        body :=
          PsVerifiedIrExpr.intrinsic
            PsVerifiedIrIntrinsic.arrayMap
            [
              PsVerifiedIrExpr.var "genericId",
              PsVerifiedIrExpr.var "xs"
            ]
      },
      {
        name := "arrayIdOnly"
        typeParameters := []
        parameters := [
          {
            name := "x"
            type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat
          }
        ]
        resultType := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat
        body := PsVerifiedIrExpr.var "x"
      },
      {
        name := "arrayMapDemo"
        typeParameters := []
        parameters := [
          {
            name := "xs"
            type :=
              PsVerifiedIrType.named
                "Array"
                [PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat]
          }
        ]
        resultType :=
          PsVerifiedIrType.named
            "Array"
            [PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat]
        body :=
          PsVerifiedIrExpr.intrinsic
            PsVerifiedIrIntrinsic.arrayMap
            [
              PsVerifiedIrExpr.var "arrayIdOnly",
              PsVerifiedIrExpr.var "xs"
            ]
      },
      {
        name := "arrayKeepLeft"
        typeParameters := []
        parameters := [
          {
            name := "acc"
            type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat
          },
          {
            name := "x"
            type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat
          }
        ]
        resultType := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat
        body := PsVerifiedIrExpr.var "acc"
      },
      {
        name := "arrayFoldOnly"
        typeParameters := []
        parameters := [
          {
            name := "xs"
            type :=
              PsVerifiedIrType.named
                "Array"
                [PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat]
          }
        ]
        resultType := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat
        body :=
          PsVerifiedIrExpr.intrinsic
            PsVerifiedIrIntrinsic.arrayFoldl
            [
              PsVerifiedIrExpr.var "arrayKeepLeft",
              PsVerifiedIrExpr.literal (PsVerifiedIrLiteral.natural 0),
              PsVerifiedIrExpr.var "xs",
              PsVerifiedIrExpr.literal (PsVerifiedIrLiteral.natural 0),
              PsVerifiedIrExpr.intrinsic
                PsVerifiedIrIntrinsic.arraySize
                [PsVerifiedIrExpr.var "xs"]
            ]
      },
      {
        name := "arrayDemo"
        typeParameters := []
        parameters := [
          {
            name := "a"
            type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat
          },
          {
            name := "b"
            type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat
          }
        ]
        resultType := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat
        body :=
          PsVerifiedIrExpr.letE
            "xs"
            (PsVerifiedIrExpr.intrinsic
              PsVerifiedIrIntrinsic.arrayPush
              [
                PsVerifiedIrExpr.intrinsic
                  PsVerifiedIrIntrinsic.arrayPush
                  [
                    PsVerifiedIrExpr.intrinsic
                      PsVerifiedIrIntrinsic.arrayEmptyWithCapacity
                      [
                        PsVerifiedIrExpr.literal
                          (PsVerifiedIrLiteral.natural 2)
                      ],
                    PsVerifiedIrExpr.var "a"
                  ],
                PsVerifiedIrExpr.var "b"
              ])
            (PsVerifiedIrExpr.letE
              "ys"
              (PsVerifiedIrExpr.intrinsic
                PsVerifiedIrIntrinsic.arraySetIfInBounds
                [
                  PsVerifiedIrExpr.var "xs",
                  PsVerifiedIrExpr.literal
                    (PsVerifiedIrLiteral.natural 0),
                  PsVerifiedIrExpr.literal
                    (PsVerifiedIrLiteral.natural 10)
                ])
              (PsVerifiedIrExpr.intrinsic
                PsVerifiedIrIntrinsic.arrayGetD
                [
                  PsVerifiedIrExpr.var "ys",
                  PsVerifiedIrExpr.literal
                    (PsVerifiedIrLiteral.natural 1),
                  PsVerifiedIrExpr.literal
                    (PsVerifiedIrLiteral.natural 99)
                ]))
      },
      {
        name := "unwrapOr"
        typeParameters := []
        parameters := [
          {
            name := "value"
            type :=
              PsVerifiedIrType.named
                "Maybe"
                [PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat]
          },
          {
            name := "fallback"
            type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat
          }
        ]
        resultType := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat
        body :=
          PsVerifiedIrExpr.matchE
            "Maybe"
            (PsVerifiedIrExpr.var "value")
            [
              (
                "none",
                [],
                PsVerifiedIrExpr.var "fallback"
              ),
              (
                "some",
                [
                  {
                    field := "value"
                    name := "inner"
                    type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat
                  }
                ],
                PsVerifiedIrExpr.var "inner"
              )
            ]
      }
    ]
  }

def main : IO Unit := do
  match psRustEmitModule psBackendRustCompileFixture with
  | Except.error _ =>
      throw (IO.userError "PSC1_BACKEND_RUST_FIXTURE: emission failed")
  | Except.ok output =>
      IO.print output
