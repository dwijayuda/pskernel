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

def psWasmSmokeNatType : PsVerifiedIrType :=
  PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat

def psWasmSmokeBoolType : PsVerifiedIrType :=
  PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.bool

def psWasmSmokeNat
    (value : Nat) : PsVerifiedIrExpr :=
  PsVerifiedIrExpr.literal (PsVerifiedIrLiteral.natural value)

def psWasmSmokeNatBinary
    (operation : PsVerifiedIrIntrinsic)
    (left right : Nat) : PsVerifiedIrExpr :=
  PsVerifiedIrExpr.intrinsic
    operation
    [psWasmSmokeNat left, psWasmSmokeNat right]

def psWasmSmokeNatEq
    (left right : PsVerifiedIrExpr) : PsVerifiedIrExpr :=
  PsVerifiedIrExpr.intrinsic
    PsVerifiedIrIntrinsic.natEq
    [left, right]

def psWasmSmokeIntType : PsVerifiedIrType :=
  PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.int

def psWasmSmokeInt
    (value : Int) : PsVerifiedIrExpr :=
  PsVerifiedIrExpr.literal (PsVerifiedIrLiteral.integer value)

def psWasmSmokeIntBinary
    (operation : PsVerifiedIrIntrinsic)
    (left right : Int) : PsVerifiedIrExpr :=
  PsVerifiedIrExpr.intrinsic
    operation
    [psWasmSmokeInt left, psWasmSmokeInt right]

def psWasmSmokeIntEq
    (left right : PsVerifiedIrExpr) : PsVerifiedIrExpr :=
  PsVerifiedIrExpr.intrinsic
    PsVerifiedIrIntrinsic.intEq
    [left, right]

def psWasmSmokeArrayU32Type : PsVerifiedIrType :=
  PsVerifiedIrType.named "Array" [psWasmSmokeU32Type]

def psWasmSmokeU32
    (value : Int) : PsVerifiedIrExpr :=
  PsVerifiedIrExpr.literal
    (PsVerifiedIrLiteral.machineInteger
      PsVerifiedIrMachineIntegerType.uint32
      value)

def psWasmSmokeArrayEmptyU32
    (capacity : Nat) : PsVerifiedIrExpr :=
  PsVerifiedIrExpr.intrinsic
    (PsVerifiedIrIntrinsic.arrayEmptyWithCapacity
      psWasmSmokeU32Type)
    [psWasmSmokeNat capacity]

def psWasmSmokeArrayPushU32
    (array value : PsVerifiedIrExpr) : PsVerifiedIrExpr :=
  PsVerifiedIrExpr.intrinsic
    (PsVerifiedIrIntrinsic.arrayPush
      psWasmSmokeU32Type)
    [array, value]

def psWasmSmokeArrayGetU32
    (array index : PsVerifiedIrExpr) : PsVerifiedIrExpr :=
  PsVerifiedIrExpr.intrinsic
    (PsVerifiedIrIntrinsic.arrayGet
      psWasmSmokeU32Type)
    [array, index]

def psWasmSmokeArrayTwoU32
    (first second : Int) : PsVerifiedIrExpr :=
  psWasmSmokeArrayPushU32
    (psWasmSmokeArrayPushU32
      (psWasmSmokeArrayEmptyU32 2)
      (psWasmSmokeU32 first))
    (psWasmSmokeU32 second)

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
        name := "natAddExact"
        typeParameters := []
        parameters := []
        resultType := psWasmSmokeBoolType
        body :=
          psWasmSmokeNatEq
            (psWasmSmokeNatBinary
              PsVerifiedIrIntrinsic.natAdd
              5
              7)
            (psWasmSmokeNat 12)
      },
      {
        name := "natSubSaturates"
        typeParameters := []
        parameters := []
        resultType := psWasmSmokeBoolType
        body :=
          psWasmSmokeNatEq
            (psWasmSmokeNatBinary
              PsVerifiedIrIntrinsic.natSub
              3
              5)
            (psWasmSmokeNat 0)
      },
      {
        name := "natMulExact"
        typeParameters := []
        parameters := []
        resultType := psWasmSmokeBoolType
        body :=
          psWasmSmokeNatEq
            (psWasmSmokeNatBinary
              PsVerifiedIrIntrinsic.natMul
              4
              3)
            (psWasmSmokeNat 12)
      },
      {
        name := "natDivExact"
        typeParameters := []
        parameters := []
        resultType := psWasmSmokeBoolType
        body :=
          psWasmSmokeNatEq
            (psWasmSmokeNatBinary
              PsVerifiedIrIntrinsic.natDiv
              13
              5)
            (psWasmSmokeNat 2)
      },
      {
        name := "natDivZero"
        typeParameters := []
        parameters := []
        resultType := psWasmSmokeBoolType
        body :=
          psWasmSmokeNatEq
            (psWasmSmokeNatBinary
              PsVerifiedIrIntrinsic.natDiv
              13
              0)
            (psWasmSmokeNat 0)
      },
      {
        name := "natModExact"
        typeParameters := []
        parameters := []
        resultType := psWasmSmokeBoolType
        body :=
          psWasmSmokeNatEq
            (psWasmSmokeNatBinary
              PsVerifiedIrIntrinsic.natMod
              13
              5)
            (psWasmSmokeNat 3)
      },
      {
        name := "natModZero"
        typeParameters := []
        parameters := []
        resultType := psWasmSmokeBoolType
        body :=
          psWasmSmokeNatEq
            (psWasmSmokeNatBinary
              PsVerifiedIrIntrinsic.natMod
              13
              0)
            (psWasmSmokeNat 13)
      },
      {
        name := "natOrder"
        typeParameters := []
        parameters := []
        resultType := psWasmSmokeBoolType
        body :=
          PsVerifiedIrExpr.intrinsic
            PsVerifiedIrIntrinsic.natLt
            [psWasmSmokeNat 3, psWasmSmokeNat 5]
      }
,
      {
        name := "intAddMixed"
        typeParameters := []
        parameters := []
        resultType := psWasmSmokeBoolType
        body :=
          psWasmSmokeIntEq
            (psWasmSmokeIntBinary
              PsVerifiedIrIntrinsic.intAdd
              (-5)
              7)
            (psWasmSmokeInt 2)
      },
      {
        name := "intSubNegative"
        typeParameters := []
        parameters := []
        resultType := psWasmSmokeBoolType
        body :=
          psWasmSmokeIntEq
            (psWasmSmokeIntBinary
              PsVerifiedIrIntrinsic.intSub
              3
              8)
            (psWasmSmokeInt (-5))
      },
      {
        name := "intMulNegative"
        typeParameters := []
        parameters := []
        resultType := psWasmSmokeBoolType
        body :=
          psWasmSmokeIntEq
            (psWasmSmokeIntBinary
              PsVerifiedIrIntrinsic.intMul
              (-4)
              3)
            (psWasmSmokeInt (-12))
      },
      {
        name := "intNegExact"
        typeParameters := []
        parameters := []
        resultType := psWasmSmokeBoolType
        body :=
          psWasmSmokeIntEq
            (PsVerifiedIrExpr.intrinsic
              PsVerifiedIrIntrinsic.intNeg
              [psWasmSmokeInt (-5)])
            (psWasmSmokeInt 5)
      },
      {
        name := "intOrderNegative"
        typeParameters := []
        parameters := []
        resultType := psWasmSmokeBoolType
        body :=
          PsVerifiedIrExpr.intrinsic
            PsVerifiedIrIntrinsic.intLt
            [psWasmSmokeInt (-7), psWasmSmokeInt (-3)]
      },
      {
        name := "intOfNatExact"
        typeParameters := []
        parameters := []
        resultType := psWasmSmokeBoolType
        body :=
          psWasmSmokeIntEq
            (PsVerifiedIrExpr.intrinsic
              PsVerifiedIrIntrinsic.intOfNat
              [psWasmSmokeNat 9])
            (psWasmSmokeInt 9)
      },
      {
        name := "intNegSuccExact"
        typeParameters := []
        parameters := []
        resultType := psWasmSmokeBoolType
        body :=
          psWasmSmokeIntEq
            (PsVerifiedIrExpr.intrinsic
              PsVerifiedIrIntrinsic.intNegSucc
              [psWasmSmokeNat 4])
            (psWasmSmokeInt (-5))
      }
,
      {
        name := "arraySizeAfterPush"
        typeParameters := []
        parameters := []
        resultType := psWasmSmokeBoolType
        body :=
          psWasmSmokeNatEq
            (PsVerifiedIrExpr.intrinsic
              (PsVerifiedIrIntrinsic.arraySize
                psWasmSmokeU32Type)
              [
                psWasmSmokeArrayPushU32
                  (psWasmSmokeArrayEmptyU32 8)
                  (psWasmSmokeU32 42)
              ])
            (psWasmSmokeNat 1)
      },
      {
        name := "arrayGetAfterPush"
        typeParameters := []
        parameters := []
        resultType := psWasmSmokeU32Type
        body :=
          psWasmSmokeArrayGetU32
            (psWasmSmokeArrayPushU32
              (psWasmSmokeArrayEmptyU32 4)
              (psWasmSmokeU32 42))
            (psWasmSmokeNat 0)
      },
      {
        name := "arrayGetDFallback"
        typeParameters := []
        parameters := []
        resultType := psWasmSmokeU32Type
        body :=
          PsVerifiedIrExpr.intrinsic
            (PsVerifiedIrIntrinsic.arrayGetD
              psWasmSmokeU32Type)
            [
              psWasmSmokeArrayPushU32
                (psWasmSmokeArrayEmptyU32 1)
                (psWasmSmokeU32 10),
              psWasmSmokeNat 5,
              psWasmSmokeU32 99
            ]
      },
      {
        name := "arraySetPersistent"
        typeParameters := []
        parameters := []
        resultType := psWasmSmokeBoolType
        body :=
          PsVerifiedIrExpr.letE
            "original"
            psWasmSmokeArrayU32Type
            (psWasmSmokeArrayPushU32
              (psWasmSmokeArrayEmptyU32 1)
              (psWasmSmokeU32 10))
            (PsVerifiedIrExpr.letE
              "updated"
              psWasmSmokeArrayU32Type
              (PsVerifiedIrExpr.intrinsic
                (PsVerifiedIrIntrinsic.arraySet
                  psWasmSmokeU32Type)
                [
                  PsVerifiedIrExpr.var "original",
                  psWasmSmokeNat 0,
                  psWasmSmokeU32 42
                ])
              (PsVerifiedIrExpr.intrinsic
                (PsVerifiedIrIntrinsic.machineIntCompare
                  PsVerifiedIrMachineIntegerType.uint32
                  PsVerifiedIrIntegerCompareOp.eq)
                [
                  PsVerifiedIrExpr.intrinsic
                    (PsVerifiedIrIntrinsic.machineIntBinary
                      PsVerifiedIrMachineIntegerType.uint32
                      PsVerifiedIrIntegerBinaryOp.add)
                    [
                      psWasmSmokeArrayGetU32
                        (PsVerifiedIrExpr.var "original")
                        (psWasmSmokeNat 0),
                      psWasmSmokeArrayGetU32
                        (PsVerifiedIrExpr.var "updated")
                        (psWasmSmokeNat 0)
                    ],
                  psWasmSmokeU32 52
                ]))
      },
      {
        name := "arraySetIfOutOfBounds"
        typeParameters := []
        parameters := []
        resultType := psWasmSmokeU32Type
        body :=
          PsVerifiedIrExpr.letE
            "original"
            psWasmSmokeArrayU32Type
            (psWasmSmokeArrayPushU32
              (psWasmSmokeArrayEmptyU32 1)
              (psWasmSmokeU32 10))
            (PsVerifiedIrExpr.letE
              "unchanged"
              psWasmSmokeArrayU32Type
              (PsVerifiedIrExpr.intrinsic
                (PsVerifiedIrIntrinsic.arraySetIfInBounds
                  psWasmSmokeU32Type)
                [
                  PsVerifiedIrExpr.var "original",
                  psWasmSmokeNat 5,
                  psWasmSmokeU32 42
                ])
              (psWasmSmokeArrayGetU32
                (PsVerifiedIrExpr.var "unchanged")
                (psWasmSmokeNat 0)))
      }
,
      {
        name := "arrayMapIncrementSum"
        typeParameters := []
        parameters := []
        resultType := psWasmSmokeU32Type
        body :=
          PsVerifiedIrExpr.letE
            "mapped"
            psWasmSmokeArrayU32Type
            (PsVerifiedIrExpr.intrinsic
              (PsVerifiedIrIntrinsic.arrayMap
                psWasmSmokeU32Type
                psWasmSmokeU32Type)
              [
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
                    [
                      PsVerifiedIrExpr.var "value",
                      psWasmSmokeU32 1
                    ]),
                psWasmSmokeArrayTwoU32 10 20
              ])
            (PsVerifiedIrExpr.intrinsic
              (PsVerifiedIrIntrinsic.machineIntBinary
                PsVerifiedIrMachineIntegerType.uint32
                PsVerifiedIrIntegerBinaryOp.add)
              [
                psWasmSmokeArrayGetU32
                  (PsVerifiedIrExpr.var "mapped")
                  (psWasmSmokeNat 0),
                psWasmSmokeArrayGetU32
                  (PsVerifiedIrExpr.var "mapped")
                  (psWasmSmokeNat 1)
              ])
      },
      {
        name := "arrayFoldlSum"
        typeParameters := []
        parameters := []
        resultType := psWasmSmokeU32Type
        body :=
          PsVerifiedIrExpr.intrinsic
            (PsVerifiedIrIntrinsic.arrayFoldl
              psWasmSmokeU32Type
              psWasmSmokeU32Type)
            [
              PsVerifiedIrExpr.lambda
                [
                  {
                    name := "acc"
                    type := psWasmSmokeU32Type
                  },
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
                  [
                    PsVerifiedIrExpr.var "acc",
                    PsVerifiedIrExpr.var "value"
                  ]),
              psWasmSmokeU32 1,
              psWasmSmokeArrayTwoU32 10 20,
              psWasmSmokeNat 0,
              psWasmSmokeNat 2
            ]
      }
    ]
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
      match psWasmEncodeModule module with
      | Except.error _ =>
          throw (IO.userError "PSC1_BACKEND_WASM_BINARY_SMOKE: encode failed")
      | Except.ok bytes =>
          IO.println (psWasmJoinComma (psWasmByteStrings bytes))
