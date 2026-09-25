import Ps.BackendWasm.Lower

def psWasmSmokeProfile : PsWasmTargetProfile :=
  { wordSize := PsWasmWordSize.wasm32 }

def psWasmSmokeU32Type : PsVerifiedIrType :=
  PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.uint32

def psWasmSmokeU32FunctionType : PsVerifiedIrType :=
  PsVerifiedIrType.function
    [psWasmSmokeU32Type]
    psWasmSmokeU32Type

def psWasmSmokeTypeA : PsVerifiedIrType :=
  PsVerifiedIrType.typeParameter "A"

def psWasmSmokeGenericListA : PsVerifiedIrType :=
  PsVerifiedIrType.named "GenericList" [psWasmSmokeTypeA]

def psWasmSmokeIrModule : PsVerifiedIrModule :=
  {
    imports := []
    structures := [
      {
        name := "Point"
        typeParameters := []
        fields := [
          {
            name := "x"
            type :=
              PsVerifiedIrType.primitive
                PsVerifiedIrPrimitiveType.uint32
          },
          {
            name := "y"
            type :=
              PsVerifiedIrType.primitive
                PsVerifiedIrPrimitiveType.uint32
          }
        ]
      },
      {
        name := "SmallSigned"
        typeParameters := []
        fields := [
          {
            name := "value"
            type :=
              PsVerifiedIrType.primitive
                PsVerifiedIrPrimitiveType.int16
          }
        ]
      }
,
      {
        name := "SmallUnsigned"
        typeParameters := []
        fields := [
          {
            name := "value"
            type :=
              PsVerifiedIrType.primitive
                PsVerifiedIrPrimitiveType.uint16
          }
        ]
      }
,
      {
        name := "GenericBox"
        typeParameters := [{ name := "A" }]
        fields := [
          {
            name := "value"
            type := psWasmSmokeTypeA
          }
        ]
      }
    ]
    inductives := [
      {
        name := "MaybeU32"
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
                type :=
                  PsVerifiedIrType.primitive
                    PsVerifiedIrPrimitiveType.uint32
              }
            ]
          }
        ]
      }
,
      {
        name := "U32List"
        typeParameters := []
        constructors := [
          {
            name := "nil"
            fields := []
          },
          {
            name := "cons"
            fields := [
              {
                name := "head"
                type :=
                  PsVerifiedIrType.primitive
                    PsVerifiedIrPrimitiveType.uint32
              },
              {
                name := "tail"
                type := PsVerifiedIrType.named "U32List" []
              }
            ]
          }
        ]
      }
,
      {
        name := "GenericList"
        typeParameters := [{ name := "A" }]
        constructors := [
          {
            name := "nil"
            fields := []
          },
          {
            name := "cons"
            fields := [
              {
                name := "head"
                type := psWasmSmokeTypeA
              },
              {
                name := "tail"
                type := psWasmSmokeGenericListA
              }
            ]
          }
        ]
      }
    ]
    declarations := [
      {
        name := "addU32"
        typeParameters := []
        parameters := [
          {
            name := "left"
            type :=
              PsVerifiedIrType.primitive
                PsVerifiedIrPrimitiveType.uint32
          },
          {
            name := "right"
            type :=
              PsVerifiedIrType.primitive
                PsVerifiedIrPrimitiveType.uint32
          }
        ]
        resultType :=
          PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.uint32
        body :=
          PsVerifiedIrExpr.intrinsic
            (PsVerifiedIrIntrinsic.machineIntBinary
              PsVerifiedIrMachineIntegerType.uint32
              PsVerifiedIrIntegerBinaryOp.add)
            []
            [
              PsVerifiedIrExpr.var "left",
              PsVerifiedIrExpr.var "right"
            ]
      }
,
      {
        name := "addF32"
        typeParameters := []
        parameters := [
          {
            name := "left"
            type :=
              PsVerifiedIrType.primitive
                PsVerifiedIrPrimitiveType.float32
          },
          {
            name := "right"
            type :=
              PsVerifiedIrType.primitive
                PsVerifiedIrPrimitiveType.float32
          }
        ]
        resultType :=
          PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.float32
        body :=
          PsVerifiedIrExpr.intrinsic
            (PsVerifiedIrIntrinsic.floatBinary
              PsVerifiedIrFloatingType.float32
              PsVerifiedIrFloatBinaryOp.add)
            []
            [
              PsVerifiedIrExpr.var "left",
              PsVerifiedIrExpr.var "right"
            ]
      }
,
      {
        name := "addThenOne"
        typeParameters := []
        parameters := [
          {
            name := "left"
            type :=
              PsVerifiedIrType.primitive
                PsVerifiedIrPrimitiveType.uint32
          },
          {
            name := "right"
            type :=
              PsVerifiedIrType.primitive
                PsVerifiedIrPrimitiveType.uint32
          }
        ]
        resultType :=
          PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.uint32
        body :=
          PsVerifiedIrExpr.intrinsic
            (PsVerifiedIrIntrinsic.machineIntBinary
              PsVerifiedIrMachineIntegerType.uint32
              PsVerifiedIrIntegerBinaryOp.add)
            []
            [
              PsVerifiedIrExpr.call
                (PsVerifiedIrExpr.var "addU32")
                []
                [
                  PsVerifiedIrExpr.var "left",
                  PsVerifiedIrExpr.var "right"
                ],
              PsVerifiedIrExpr.literal
                (PsVerifiedIrLiteral.machineInteger
                  PsVerifiedIrMachineIntegerType.uint32
                  1)
            ]
      }
,
      {
        name := "selectU32"
        typeParameters := []
        parameters := [
          {
            name := "flag"
            type :=
              PsVerifiedIrType.primitive
                PsVerifiedIrPrimitiveType.bool
          },
          {
            name := "whenTrue"
            type :=
              PsVerifiedIrType.primitive
                PsVerifiedIrPrimitiveType.uint32
          },
          {
            name := "whenFalse"
            type :=
              PsVerifiedIrType.primitive
                PsVerifiedIrPrimitiveType.uint32
          }
        ]
        resultType :=
          PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.uint32
        body :=
          PsVerifiedIrExpr.ifE
            (PsVerifiedIrExpr.var "flag")
            (PsVerifiedIrExpr.var "whenTrue")
            (PsVerifiedIrExpr.var "whenFalse")
      }
,
      {
        name := "letPlusOne"
        typeParameters := []
        parameters := [
          {
            name := "value"
            type :=
              PsVerifiedIrType.primitive
                PsVerifiedIrPrimitiveType.uint32
          }
        ]
        resultType :=
          PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.uint32
        body :=
          PsVerifiedIrExpr.letE
            "saved"
            (PsVerifiedIrType.primitive
              PsVerifiedIrPrimitiveType.uint32)
            (PsVerifiedIrExpr.var "value")
            (PsVerifiedIrExpr.intrinsic
              (PsVerifiedIrIntrinsic.machineIntBinary
                PsVerifiedIrMachineIntegerType.uint32
                PsVerifiedIrIntegerBinaryOp.add)
              []
              [
                PsVerifiedIrExpr.var "saved",
                PsVerifiedIrExpr.literal
                  (PsVerifiedIrLiteral.machineInteger
                    PsVerifiedIrMachineIntegerType.uint32
                    1)
              ])
      }
,
      {
        name := "pointX"
        typeParameters := []
        parameters := [
          {
            name := "x"
            type :=
              PsVerifiedIrType.primitive
                PsVerifiedIrPrimitiveType.uint32
          },
          {
            name := "y"
            type :=
              PsVerifiedIrType.primitive
                PsVerifiedIrPrimitiveType.uint32
          }
        ]
        resultType :=
          PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.uint32
        body :=
          PsVerifiedIrExpr.projection
            "Point"
            []
            (PsVerifiedIrExpr.record
              "Point"
              []
              [
                ("x", PsVerifiedIrExpr.var "x"),
                ("y", PsVerifiedIrExpr.var "y")
              ])
            "x"
      },
      {
        name := "smallSigned"
        typeParameters := []
        parameters := [
          {
            name := "value"
            type :=
              PsVerifiedIrType.primitive
                PsVerifiedIrPrimitiveType.int16
          }
        ]
        resultType :=
          PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.int16
        body :=
          PsVerifiedIrExpr.projection
            "SmallSigned"
            []
            (PsVerifiedIrExpr.record
              "SmallSigned"
              []
              [("value", PsVerifiedIrExpr.var "value")])
            "value"
      }
,
      {
        name := "smallUnsigned"
        typeParameters := []
        parameters := [
          {
            name := "value"
            type :=
              PsVerifiedIrType.primitive
                PsVerifiedIrPrimitiveType.uint16
          }
        ]
        resultType :=
          PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.uint16
        body :=
          PsVerifiedIrExpr.projection
            "SmallUnsigned"
            []
            (PsVerifiedIrExpr.record
              "SmallUnsigned"
              []
              [("value", PsVerifiedIrExpr.var "value")])
            "value"
      }
,
      {
        name := "someValue"
        typeParameters := []
        parameters := [
          {
            name := "input"
            type :=
              PsVerifiedIrType.primitive
                PsVerifiedIrPrimitiveType.uint32
          }
        ]
        resultType :=
          PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.uint32
        body :=
          PsVerifiedIrExpr.matchE
            "MaybeU32"
            []
            (PsVerifiedIrExpr.constructor
              "MaybeU32"
              "some"
              []
              [("value", PsVerifiedIrExpr.var "input")])
            [
              (
                "none",
                [],
                PsVerifiedIrExpr.literal
                  (PsVerifiedIrLiteral.machineInteger
                    PsVerifiedIrMachineIntegerType.uint32
                    0)
              ),
              (
                "some",
                [
                  {
                    field := "value"
                    name := "value"
                    type :=
                      PsVerifiedIrType.primitive
                        PsVerifiedIrPrimitiveType.uint32
                  }
                ],
                PsVerifiedIrExpr.var "value"
              )
            ]
      },
      {
        name := "noneValue"
        typeParameters := []
        parameters := []
        resultType :=
          PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.uint32
        body :=
          PsVerifiedIrExpr.matchE
            "MaybeU32"
            []
            (PsVerifiedIrExpr.constructor
              "MaybeU32"
              "none"
              []
              [])
            [
              (
                "none",
                [],
                PsVerifiedIrExpr.literal
                  (PsVerifiedIrLiteral.machineInteger
                    PsVerifiedIrMachineIntegerType.uint32
                    0)
              ),
              (
                "some",
                [
                  {
                    field := "value"
                    name := "value"
                    type :=
                      PsVerifiedIrType.primitive
                        PsVerifiedIrPrimitiveType.uint32
                  }
                ],
                PsVerifiedIrExpr.var "value"
              )
            ]
      }
,
      {
        name := "listLength"
        typeParameters := []
        parameters := [
          {
            name := "xs"
            type := PsVerifiedIrType.named "U32List" []
          }
        ]
        resultType :=
          PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.uint32
        body :=
          PsVerifiedIrExpr.matchE
            "U32List"
            []
            (PsVerifiedIrExpr.var "xs")
            [
              (
                "nil",
                [],
                PsVerifiedIrExpr.literal
                  (PsVerifiedIrLiteral.machineInteger
                    PsVerifiedIrMachineIntegerType.uint32
                    0)
              ),
              (
                "cons",
                [
                  {
                    field := "head"
                    name := "head"
                    type :=
                      PsVerifiedIrType.primitive
                        PsVerifiedIrPrimitiveType.uint32
                  },
                  {
                    field := "tail"
                    name := "tail"
                    type := PsVerifiedIrType.named "U32List" []
                  }
                ],
                PsVerifiedIrExpr.intrinsic
                  (PsVerifiedIrIntrinsic.machineIntBinary
                    PsVerifiedIrMachineIntegerType.uint32
                    PsVerifiedIrIntegerBinaryOp.add)
                  []
                  [
                    PsVerifiedIrExpr.literal
                      (PsVerifiedIrLiteral.machineInteger
                        PsVerifiedIrMachineIntegerType.uint32
                        1),
                    PsVerifiedIrExpr.call
                      (PsVerifiedIrExpr.var "listLength")
                      []
                      [PsVerifiedIrExpr.var "tail"]
                  ]
              )
            ]
      },
      {
        name := "listLengthTwo"
        typeParameters := []
        parameters := []
        resultType :=
          PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.uint32
        body :=
          PsVerifiedIrExpr.call
            (PsVerifiedIrExpr.var "listLength")
            []
            [
              PsVerifiedIrExpr.constructor
                "U32List"
                "cons"
                []
                [
                  (
                    "head",
                    PsVerifiedIrExpr.literal
                      (PsVerifiedIrLiteral.machineInteger
                        PsVerifiedIrMachineIntegerType.uint32
                        10)
                  ),
                  (
                    "tail",
                    PsVerifiedIrExpr.constructor
                      "U32List"
                      "cons"
                      []
                      [
                        (
                          "head",
                          PsVerifiedIrExpr.literal
                            (PsVerifiedIrLiteral.machineInteger
                              PsVerifiedIrMachineIntegerType.uint32
                              20)
                        ),
                        (
                          "tail",
                          PsVerifiedIrExpr.constructor
                            "U32List"
                            "nil"
                            []
                            []
                        )
                      ]
                  )
                ]
            ]
      }
,
      {
        name := "makeAdder"
        typeParameters := []
        parameters := [
          {
            name := "base"
            type := psWasmSmokeU32Type
          }
        ]
        resultType := psWasmSmokeU32FunctionType
        body :=
          PsVerifiedIrExpr.lambda
            [
              {
                name := "value"
                type := psWasmSmokeU32Type
              }
            ]
            psWasmSmokeU32Type
            (PsVerifiedIrExpr.intrinsic
              (PsVerifiedIrIntrinsic.machineIntBinary
                PsVerifiedIrMachineIntegerType.uint32
                PsVerifiedIrIntegerBinaryOp.add)
              []
              [
                PsVerifiedIrExpr.var "base",
                PsVerifiedIrExpr.var "value"
              ])
      },
      {
        name := "applyReturnedAdder"
        typeParameters := []
        parameters := [
          {
            name := "base"
            type := psWasmSmokeU32Type
          },
          {
            name := "value"
            type := psWasmSmokeU32Type
          }
        ]
        resultType := psWasmSmokeU32Type
        body :=
          PsVerifiedIrExpr.letE
            "adder"
            psWasmSmokeU32FunctionType
            (PsVerifiedIrExpr.call
              (PsVerifiedIrExpr.var "makeAdder")
              []
              [PsVerifiedIrExpr.var "base"])
            (PsVerifiedIrExpr.call
              (PsVerifiedIrExpr.var "adder")
              []
              [PsVerifiedIrExpr.var "value"])
      },
      {
        name := "applyTwice"
        typeParameters := []
        parameters := [
          {
            name := "fn"
            type := psWasmSmokeU32FunctionType
          },
          {
            name := "value"
            type := psWasmSmokeU32Type
          }
        ]
        resultType := psWasmSmokeU32Type
        body :=
          PsVerifiedIrExpr.call
            (PsVerifiedIrExpr.var "fn")
            []
            [
              PsVerifiedIrExpr.call
                (PsVerifiedIrExpr.var "fn")
                []
                [PsVerifiedIrExpr.var "value"]
            ]
      },
      {
        name := "applyTwiceIncrement"
        typeParameters := []
        parameters := [
          {
            name := "value"
            type := psWasmSmokeU32Type
          }
        ]
        resultType := psWasmSmokeU32Type
        body :=
          PsVerifiedIrExpr.letE
            "increment"
            psWasmSmokeU32FunctionType
            (PsVerifiedIrExpr.lambda
              [
                {
                  name := "input"
                  type := psWasmSmokeU32Type
                }
              ]
              psWasmSmokeU32Type
              (PsVerifiedIrExpr.intrinsic
                (PsVerifiedIrIntrinsic.machineIntBinary
                  PsVerifiedIrMachineIntegerType.uint32
                  PsVerifiedIrIntegerBinaryOp.add)
                []
                [
                  PsVerifiedIrExpr.var "input",
                  PsVerifiedIrExpr.literal
                    (PsVerifiedIrLiteral.machineInteger
                      PsVerifiedIrMachineIntegerType.uint32
                      1)
                ]))
            (PsVerifiedIrExpr.call
              (PsVerifiedIrExpr.var "applyTwice")
              []
              [
                PsVerifiedIrExpr.var "increment",
                PsVerifiedIrExpr.var "value"
              ])
      }
,
      {
        name := "genericId"
        typeParameters := [{ name := "A" }]
        parameters := [
          {
            name := "value"
            type := psWasmSmokeTypeA
          }
        ]
        resultType := psWasmSmokeTypeA
        body := PsVerifiedIrExpr.var "value"
      },
      {
        name := "genericLength"
        typeParameters := [{ name := "A" }]
        parameters := [
          {
            name := "xs"
            type := psWasmSmokeGenericListA
          }
        ]
        resultType := psWasmSmokeU32Type
        body :=
          PsVerifiedIrExpr.matchE
            "GenericList"
            [psWasmSmokeTypeA]
            (PsVerifiedIrExpr.var "xs")
            [
              (
                "nil",
                [],
                PsVerifiedIrExpr.literal
                  (PsVerifiedIrLiteral.machineInteger
                    PsVerifiedIrMachineIntegerType.uint32
                    0)
              ),
              (
                "cons",
                [
                  {
                    field := "head"
                    name := "head"
                    type := psWasmSmokeTypeA
                  },
                  {
                    field := "tail"
                    name := "tail"
                    type := psWasmSmokeGenericListA
                  }
                ],
                PsVerifiedIrExpr.intrinsic
                  (PsVerifiedIrIntrinsic.machineIntBinary
                    PsVerifiedIrMachineIntegerType.uint32
                    PsVerifiedIrIntegerBinaryOp.add)
                  []
                  [
                    PsVerifiedIrExpr.literal
                      (PsVerifiedIrLiteral.machineInteger
                        PsVerifiedIrMachineIntegerType.uint32
                        1),
                    PsVerifiedIrExpr.call
                      (PsVerifiedIrExpr.var "genericLength")
                      [psWasmSmokeTypeA]
                      [PsVerifiedIrExpr.var "tail"]
                  ]
              )
            ]
      },
      {
        name := "genericBoxRoundTrip"
        typeParameters := []
        parameters := [
          {
            name := "value"
            type := psWasmSmokeU32Type
          }
        ]
        resultType := psWasmSmokeU32Type
        body :=
          PsVerifiedIrExpr.projection
            "GenericBox"
            [psWasmSmokeU32Type]
            (PsVerifiedIrExpr.record
              "GenericBox"
              [psWasmSmokeU32Type]
              [("value", PsVerifiedIrExpr.var "value")])
            "value"
      },
      {
        name := "genericIdU32"
        typeParameters := []
        parameters := [
          {
            name := "value"
            type := psWasmSmokeU32Type
          }
        ]
        resultType := psWasmSmokeU32Type
        body :=
          PsVerifiedIrExpr.call
            (PsVerifiedIrExpr.var "genericId")
            [psWasmSmokeU32Type]
            [PsVerifiedIrExpr.var "value"]
      },
      {
        name := "genericLengthTwo"
        typeParameters := []
        parameters := []
        resultType := psWasmSmokeU32Type
        body :=
          PsVerifiedIrExpr.call
            (PsVerifiedIrExpr.var "genericLength")
            [psWasmSmokeU32Type]
            [
              PsVerifiedIrExpr.constructor
                "GenericList"
                "cons"
                [psWasmSmokeU32Type]
                [
                  (
                    "head",
                    PsVerifiedIrExpr.literal
                      (PsVerifiedIrLiteral.machineInteger
                        PsVerifiedIrMachineIntegerType.uint32
                        10)
                  ),
                  (
                    "tail",
                    PsVerifiedIrExpr.constructor
                      "GenericList"
                      "cons"
                      [psWasmSmokeU32Type]
                      [
                        (
                          "head",
                          PsVerifiedIrExpr.literal
                            (PsVerifiedIrLiteral.machineInteger
                              PsVerifiedIrMachineIntegerType.uint32
                              20)
                        ),
                        (
                          "tail",
                          PsVerifiedIrExpr.constructor
                            "GenericList"
                            "nil"
                            [psWasmSmokeU32Type]
                            []
                        )
                      ]
                  )
                ]
            ]
      }
,
      {
        name := "natAddLargeExact"
        typeParameters := []
        parameters := []
        resultType :=
          PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.bool
        body :=
          PsVerifiedIrExpr.intrinsic
            PsVerifiedIrIntrinsic.natEq
            []
            [
              PsVerifiedIrExpr.intrinsic
                PsVerifiedIrIntrinsic.natAdd
                []
                [
                  PsVerifiedIrExpr.literal
              (PsVerifiedIrLiteral.natural 1208925819614629174706176),
                  PsVerifiedIrExpr.literal
              (PsVerifiedIrLiteral.natural 1)
                ],
              PsVerifiedIrExpr.literal
              (PsVerifiedIrLiteral.natural 1208925819614629174706177)
            ]
      },
      {
        name := "natSubFloorsAtZero"
        typeParameters := []
        parameters := []
        resultType :=
          PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.bool
        body :=
          PsVerifiedIrExpr.intrinsic
            PsVerifiedIrIntrinsic.natEq
            []
            [
              PsVerifiedIrExpr.intrinsic
                PsVerifiedIrIntrinsic.natSub
                []
                [
                  PsVerifiedIrExpr.literal
              (PsVerifiedIrLiteral.natural 20),
                  PsVerifiedIrExpr.literal
              (PsVerifiedIrLiteral.natural 22)
                ],
              PsVerifiedIrExpr.literal
              (PsVerifiedIrLiteral.natural 0)
            ]
      },
      {
        name := "natMulOneExact"
        typeParameters := []
        parameters := []
        resultType :=
          PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.bool
        body :=
          PsVerifiedIrExpr.intrinsic
            PsVerifiedIrIntrinsic.natEq
            []
            [
              PsVerifiedIrExpr.intrinsic
                PsVerifiedIrIntrinsic.natMul
                []
                [
                  PsVerifiedIrExpr.literal
                    (PsVerifiedIrLiteral.natural 1),
                  PsVerifiedIrExpr.literal
                    (PsVerifiedIrLiteral.natural 7)
                ],
              PsVerifiedIrExpr.literal
                (PsVerifiedIrLiteral.natural 7)
            ]
      },
      {
        name := "natMulOddExact"
        typeParameters := []
        parameters := []
        resultType :=
          PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.bool
        body :=
          PsVerifiedIrExpr.intrinsic
            PsVerifiedIrIntrinsic.natEq
            []
            [
              PsVerifiedIrExpr.intrinsic
                PsVerifiedIrIntrinsic.natMul
                []
                [
                  PsVerifiedIrExpr.literal
                    (PsVerifiedIrLiteral.natural 3),
                  PsVerifiedIrExpr.literal
                    (PsVerifiedIrLiteral.natural 7)
                ],
              PsVerifiedIrExpr.literal
                (PsVerifiedIrLiteral.natural 21)
            ]
      },
      {
        name := "natMulExact"
        typeParameters := []
        parameters := []
        resultType :=
          PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.bool
        body :=
          PsVerifiedIrExpr.intrinsic
            PsVerifiedIrIntrinsic.natEq
            []
            [
              PsVerifiedIrExpr.intrinsic
                PsVerifiedIrIntrinsic.natMul
                []
                [
                  PsVerifiedIrExpr.literal
              (PsVerifiedIrLiteral.natural 6),
                  PsVerifiedIrExpr.literal
              (PsVerifiedIrLiteral.natural 7)
                ],
              PsVerifiedIrExpr.literal
              (PsVerifiedIrLiteral.natural 42)
            ]
      },
      {
        name := "natDivExact"
        typeParameters := []
        parameters := []
        resultType :=
          PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.bool
        body :=
          PsVerifiedIrExpr.intrinsic
            PsVerifiedIrIntrinsic.natEq
            []
            [
              PsVerifiedIrExpr.intrinsic
                PsVerifiedIrIntrinsic.natDiv
                []
                [
                  PsVerifiedIrExpr.literal
              (PsVerifiedIrLiteral.natural 100),
                  PsVerifiedIrExpr.literal
              (PsVerifiedIrLiteral.natural 7)
                ],
              PsVerifiedIrExpr.literal
              (PsVerifiedIrLiteral.natural 14)
            ]
      },
      {
        name := "natModExact"
        typeParameters := []
        parameters := []
        resultType :=
          PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.bool
        body :=
          PsVerifiedIrExpr.intrinsic
            PsVerifiedIrIntrinsic.natEq
            []
            [
              PsVerifiedIrExpr.intrinsic
                PsVerifiedIrIntrinsic.natMod
                []
                [
                  PsVerifiedIrExpr.literal
              (PsVerifiedIrLiteral.natural 100),
                  PsVerifiedIrExpr.literal
              (PsVerifiedIrLiteral.natural 7)
                ],
              PsVerifiedIrExpr.literal
              (PsVerifiedIrLiteral.natural 2)
            ]
      },
      {
        name := "natDivZero"
        typeParameters := []
        parameters := []
        resultType :=
          PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.bool
        body :=
          PsVerifiedIrExpr.intrinsic
            PsVerifiedIrIntrinsic.natEq
            []
            [
              PsVerifiedIrExpr.intrinsic
                PsVerifiedIrIntrinsic.natDiv
                []
                [
                  PsVerifiedIrExpr.literal
              (PsVerifiedIrLiteral.natural 42),
                  PsVerifiedIrExpr.literal
              (PsVerifiedIrLiteral.natural 0)
                ],
              PsVerifiedIrExpr.literal
              (PsVerifiedIrLiteral.natural 0)
            ]
      },
      {
        name := "natModZero"
        typeParameters := []
        parameters := []
        resultType :=
          PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.bool
        body :=
          PsVerifiedIrExpr.intrinsic
            PsVerifiedIrIntrinsic.natEq
            []
            [
              PsVerifiedIrExpr.intrinsic
                PsVerifiedIrIntrinsic.natMod
                []
                [
                  PsVerifiedIrExpr.literal
              (PsVerifiedIrLiteral.natural 42),
                  PsVerifiedIrExpr.literal
              (PsVerifiedIrLiteral.natural 0)
                ],
              PsVerifiedIrExpr.literal
              (PsVerifiedIrLiteral.natural 42)
            ]
      },
      {
        name := "natLtExact"
        typeParameters := []
        parameters := []
        resultType :=
          PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.bool
        body :=
          PsVerifiedIrExpr.intrinsic
            PsVerifiedIrIntrinsic.natLt
            []
            [
              PsVerifiedIrExpr.literal
              (PsVerifiedIrLiteral.natural 41),
              PsVerifiedIrExpr.literal
              (PsVerifiedIrLiteral.natural 42)
            ]
      }
    ]
  }

def psWasmGcArraySmokeTypeName : String :=
  "ProofScript.TestU32Array"

def psWasmAddGcArrayTargetSmoke
    (module : PsWasmModule) : PsWasmModule :=
  {
    structures := module.structures
    arrays :=
      module.arrays ++ [
        {
          name := psWasmGcArraySmokeTypeName
          elementType :=
            PsWasmStorageType.value PsWasmValueType.i32
          mutable := true
        }
      ]
    functionTypes := module.functionTypes
    functions :=
      module.functions ++ [
        {
          name := "gcArray42"
          typeName := none
          parameters := []
          results := [PsWasmValueType.i32]
          locals := [
            PsWasmValueType.refT psWasmGcArraySmokeTypeName
          ]
          body := [
            PsWasmInstruction.i32Const 20,
            PsWasmInstruction.i32Const 22,
            PsWasmInstruction.arrayNewFixed
              psWasmGcArraySmokeTypeName
              2,
            PsWasmInstruction.localSet 0,
            PsWasmInstruction.localGet 0,
            PsWasmInstruction.i32Const 0,
            PsWasmInstruction.arrayGet
              psWasmGcArraySmokeTypeName,
            PsWasmInstruction.localGet 0,
            PsWasmInstruction.i32Const 1,
            PsWasmInstruction.arrayGet
              psWasmGcArraySmokeTypeName,
            PsWasmInstruction.i32Add
          ]
        }
      ]
    functionRefs := module.functionRefs
    exports :=
      module.exports ++ [("gcArray42", "gcArray42")]
  }

def psWasmByteStrings : List UInt8 -> List String
  | [] => []
  | byte :: rest =>
      toString byte.toNat :: psWasmByteStrings rest

def psWasmJoinComma : List String -> String
  | [] => ""
  | [value] => value
  | value :: rest =>
      value ++ "," ++ psWasmJoinComma rest

def main : IO Unit := do
  match psWasmLowerModule psWasmSmokeProfile psWasmSmokeIrModule with
  | Except.error _ =>
      throw (IO.userError "PSC1_BACKEND_WASM_BINARY_SMOKE: lower failed")
  | Except.ok module =>
      let moduleWithArraySmoke :=
        psWasmAddGcArrayTargetSmoke module
      match psWasmEncodeModule moduleWithArraySmoke with
      | Except.error _ =>
          throw (IO.userError "PSC1_BACKEND_WASM_BINARY_SMOKE: encode failed")
      | Except.ok bytes =>
          IO.println (psWasmJoinComma (psWasmByteStrings bytes))
