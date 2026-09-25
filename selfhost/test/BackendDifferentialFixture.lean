import Ps.BackendTs.Module
import Ps.BackendRust.Module

def psBackendDiffModule : PsVerifiedIrModule :=
  {
    imports := []
    structures := []
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
        name := "applyNat"
        typeParameters := []
        parameters := [
          {
            name := "f"
            type :=
              PsVerifiedIrType.function
                [PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat]
                (PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat)
          },
          {
            name := "x"
            type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat
          }
        ]
        resultType := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat
        body :=
          PsVerifiedIrExpr.call
            (PsVerifiedIrExpr.var "f")
            []
            [PsVerifiedIrExpr.var "x"]
      },
      {
        name := "diffCapture"
        typeParameters := []
        parameters := [
          {
            name := "offset"
            type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat
          },
          {
            name := "x"
            type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat
          }
        ]
        resultType := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat
        body :=
          PsVerifiedIrExpr.call
            (PsVerifiedIrExpr.var "applyNat")
            []
            [
              PsVerifiedIrExpr.lambda
                [
                  {
                    name := "value"
                    type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat
                  }
                ]
                (PsVerifiedIrExpr.intrinsic
                  PsVerifiedIrIntrinsic.natAdd
                  [
                    PsVerifiedIrExpr.var "value",
                    PsVerifiedIrExpr.var "offset"
                  ]),
              PsVerifiedIrExpr.var "x"
            ]
      },
      {
        name := "diffCaptureArray"
        typeParameters := []
        parameters := [
          {
            name := "offset"
            type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat
          }
        ]
        resultType := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat
        body :=
          PsVerifiedIrExpr.letE
            "xs"
            (PsVerifiedIrType.named
              "Array"
              [PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat])
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
                    PsVerifiedIrExpr.literal
                      (PsVerifiedIrLiteral.natural 1)
                  ],
                PsVerifiedIrExpr.literal
                  (PsVerifiedIrLiteral.natural 2)
              ])
            (PsVerifiedIrExpr.letE
              "addOffset"
              (PsVerifiedIrType.function
                [PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat]
                (PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat))
              (PsVerifiedIrExpr.lambda
                [
                  {
                    name := "value"
                    type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat
                  }
                ]
                (PsVerifiedIrExpr.intrinsic
                  PsVerifiedIrIntrinsic.natAdd
                  [
                    PsVerifiedIrExpr.var "value",
                    PsVerifiedIrExpr.var "offset"
                  ]))
              (PsVerifiedIrExpr.letE
                "ys"
                (PsVerifiedIrType.named
                  "Array"
                  [PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat])
                (PsVerifiedIrExpr.intrinsic
                  PsVerifiedIrIntrinsic.arrayMap
                  [
                    PsVerifiedIrExpr.var "addOffset",
                    PsVerifiedIrExpr.var "xs"
                  ])
                (PsVerifiedIrExpr.intrinsic
                  PsVerifiedIrIntrinsic.arrayGetD
                  [
                    PsVerifiedIrExpr.var "ys",
                    PsVerifiedIrExpr.literal
                      (PsVerifiedIrLiteral.natural 1),
                    PsVerifiedIrExpr.literal
                      (PsVerifiedIrLiteral.natural 0)
                  ])))
      },
      {
        name := "diffU8Wrap"
        typeParameters := []
        parameters := [
          {
            name := "x"
            type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.uint8
          },
          {
            name := "y"
            type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.uint8
          }
        ]
        resultType := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.uint8
        body :=
          PsVerifiedIrExpr.intrinsic
            (PsVerifiedIrIntrinsic.machineIntBinary
              PsVerifiedIrMachineIntegerType.uint8
              PsVerifiedIrIntegerBinaryOp.add)
            [
              PsVerifiedIrExpr.var "x",
              PsVerifiedIrExpr.var "y"
            ]
      },
      {
        name := "diffI16Mul"
        typeParameters := []
        parameters := [
          {
            name := "x"
            type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.int16
          },
          {
            name := "y"
            type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.int16
          }
        ]
        resultType := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.int16
        body :=
          PsVerifiedIrExpr.intrinsic
            (PsVerifiedIrIntrinsic.machineIntBinary
              PsVerifiedIrMachineIntegerType.int16
              PsVerifiedIrIntegerBinaryOp.mul)
            [
              PsVerifiedIrExpr.var "x",
              PsVerifiedIrExpr.var "y"
            ]
      },
      {
        name := "diffU32Lt"
        typeParameters := []
        parameters := [
          {
            name := "x"
            type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.uint32
          },
          {
            name := "y"
            type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.uint32
          }
        ]
        resultType := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.bool
        body :=
          PsVerifiedIrExpr.intrinsic
            (PsVerifiedIrIntrinsic.machineIntCompare
              PsVerifiedIrMachineIntegerType.uint32
              PsVerifiedIrIntegerCompareOp.lt)
            [
              PsVerifiedIrExpr.var "x",
              PsVerifiedIrExpr.var "y"
            ]
      },
      {
        name := "diffF32Add"
        typeParameters := []
        parameters := [
          {
            name := "x"
            type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.float32
          },
          {
            name := "y"
            type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.float32
          }
        ]
        resultType := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.float32
        body :=
          PsVerifiedIrExpr.intrinsic
            (PsVerifiedIrIntrinsic.floatBinary
              PsVerifiedIrFloatingType.float32
              PsVerifiedIrFloatBinaryOp.add)
            [
              PsVerifiedIrExpr.var "x",
              PsVerifiedIrExpr.var "y"
            ]
      },
      {
        name := "diffF64Div"
        typeParameters := []
        parameters := [
          {
            name := "x"
            type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.float
          },
          {
            name := "y"
            type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.float
          }
        ]
        resultType := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.float
        body :=
          PsVerifiedIrExpr.intrinsic
            (PsVerifiedIrIntrinsic.floatBinary
              PsVerifiedIrFloatingType.float
              PsVerifiedIrFloatBinaryOp.div)
            [
              PsVerifiedIrExpr.var "x",
              PsVerifiedIrExpr.var "y"
            ]
      },
      {
        name := "diffNat"
        typeParameters := []
        parameters := [
          {
            name := "x"
            type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat
          },
          {
            name := "y"
            type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat
          }
        ]
        resultType := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat
        body :=
          PsVerifiedIrExpr.ifE
            (PsVerifiedIrExpr.intrinsic
              PsVerifiedIrIntrinsic.natLt
              [
                PsVerifiedIrExpr.var "x",
                PsVerifiedIrExpr.var "y"
              ])
            (PsVerifiedIrExpr.intrinsic
              PsVerifiedIrIntrinsic.natAdd
              [
                PsVerifiedIrExpr.var "x",
                PsVerifiedIrExpr.var "y"
              ])
            (PsVerifiedIrExpr.intrinsic
              PsVerifiedIrIntrinsic.natSub
              [
                PsVerifiedIrExpr.var "x",
                PsVerifiedIrExpr.var "y"
              ])
      },
      {
        name := "diffInt"
        typeParameters := []
        parameters := [
          {
            name := "x"
            type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.int
          },
          {
            name := "y"
            type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.int
          }
        ]
        resultType := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.int
        body :=
          PsVerifiedIrExpr.intrinsic
            PsVerifiedIrIntrinsic.intAdd
            [
              PsVerifiedIrExpr.intrinsic
                PsVerifiedIrIntrinsic.intNeg
                [PsVerifiedIrExpr.var "x"],
              PsVerifiedIrExpr.var "y"
            ]
      },
      {
        name := "diffString"
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
            [
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
            ]
      },
      {
        name := "diffArray"
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
            (PsVerifiedIrType.named
              "Array"
              [PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat])
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
              (PsVerifiedIrType.named
                "Array"
                [PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat])
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
        name := "diffMaybe"
        typeParameters := []
        parameters := [
          {
            name := "x"
            type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat
          },
          {
            name := "fallback"
            type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat
          },
          {
            name := "useSome"
            type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.bool
          }
        ]
        resultType := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat
        body :=
          PsVerifiedIrExpr.letE
            "value"
            (PsVerifiedIrType.named
              "Maybe"
              [PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat])
            (PsVerifiedIrExpr.ifE
              (PsVerifiedIrExpr.var "useSome")
              (PsVerifiedIrExpr.constructor
                "Maybe"
                "some"
                [PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat]
                [
                  ("value", PsVerifiedIrExpr.var "x")
                ])
              (PsVerifiedIrExpr.constructor
                "Maybe"
                "none"
                [PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat]
                []))
            (PsVerifiedIrExpr.matchE
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
              ])
      }
    ]
  }

def psBackendDiffEmitTs : Except String String :=
  match psTsEmitModule psBackendDiffModule with
  | Except.error _ =>
      Except.error "TS"
  | Except.ok output =>
      Except.ok output

def psBackendDiffEmitRust : Except String String :=
  match psRustEmitModule psBackendDiffModule with
  | Except.error _ =>
      Except.error "RUST"
  | Except.ok output =>
      Except.ok output

def main (args : List String) : IO Unit := do
  match args with
  | ["ts"] =>
      match psBackendDiffEmitTs with
      | Except.error target =>
          throw (IO.userError ("PSC1_BACKEND_DIFF_EMIT_FAILED: " ++ target))
      | Except.ok output =>
          IO.print output
  | ["rust"] =>
      match psBackendDiffEmitRust with
      | Except.error target =>
          throw (IO.userError ("PSC1_BACKEND_DIFF_EMIT_FAILED: " ++ target))
      | Except.ok output =>
          IO.print output
  | _ =>
      throw
        (IO.userError
          "usage: psc1_backend_diff_fixture <ts|rust>")
