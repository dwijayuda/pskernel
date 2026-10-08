import Ps.BackendWasm.Lower
import Ps.BackendWasm.Binary
import Ps.BackendWasm.Validate

def psWasmProfile32 : PsWasmTargetProfile :=
  { wordSize := PsWasmWordSize.wasm32 }

def psWasmProfile64 : PsWasmTargetProfile :=
  { wordSize := PsWasmWordSize.wasm64 }

def psWasmIsI32 : PsWasmValueType -> Bool
  | .i32 => true
  | _ => false

def psWasmIsI64 : PsWasmValueType -> Bool
  | .i64 => true
  | _ => false

def psWasmIsF32 : PsWasmValueType -> Bool
  | .f32 => true
  | _ => false

def psWasmIsF64 : PsWasmValueType -> Bool
  | .f64 => true
  | _ => false

def psWasmIsPackedI8 : PsWasmStorageType -> Bool
  | .packedI8 => true
  | _ => false

def psWasmIsPackedI16 : PsWasmStorageType -> Bool
  | .packedI16 => true
  | _ => false

def psWasmIsNatRef : PsWasmValueType -> Bool
  | .refT name => name == "ProofScript.Nat"
  | _ => false

def psTestWasmScalarLowering : Bool :=
  psWasmIsI32 (psWasmValueTypeOfPrimitive psWasmProfile32 .uint8)
    && psWasmIsPackedI8 (psWasmStorageTypeOfPrimitive psWasmProfile32 .uint8)
    && psWasmIsI32 (psWasmValueTypeOfPrimitive psWasmProfile32 .int16)
    && psWasmIsPackedI16 (psWasmStorageTypeOfPrimitive psWasmProfile32 .int16)
    && psWasmIsI64 (psWasmValueTypeOfPrimitive psWasmProfile32 .uint64)
    && psWasmIsF32 (psWasmValueTypeOfPrimitive psWasmProfile32 .float32)
    && psWasmIsF64 (psWasmValueTypeOfPrimitive psWasmProfile32 .float)
    && psWasmIsNatRef (psWasmValueTypeOfPrimitive psWasmProfile32 .nat)

def psTestWasmWordProfiles : Bool :=
  psWasmIsI32 (psWasmValueTypeOfPrimitive psWasmProfile32 .usize)
    && psWasmIsI32 (psWasmValueTypeOfPrimitive psWasmProfile32 .isize)
    && psWasmIsI64 (psWasmValueTypeOfPrimitive psWasmProfile64 .usize)
    && psWasmIsI64 (psWasmValueTypeOfPrimitive psWasmProfile64 .isize)

def psWasmIsUInt8Add : List PsWasmInstruction -> Bool
  | .i32Add :: .i32Const value :: .i32And :: [] =>
      value == 255
  | _ => false

def psWasmIsInt8Add : List PsWasmInstruction -> Bool
  | .i32Add :: .i32Extend8S :: [] => true
  | _ => false

def psWasmIsUInt64Xor : List PsWasmInstruction -> Bool
  | .i64Xor :: [] => true
  | _ => false

def psWasmIsInt16Lt : List PsWasmInstruction -> Bool
  | .i32LtS :: [] => true
  | _ => false

def psWasmIsUInt16Lt : List PsWasmInstruction -> Bool
  | .i32LtU :: [] => true
  | _ => false

def psWasmIsUSize64Add : List PsWasmInstruction -> Bool
  | .i64Add :: [] => true
  | _ => false

def psWasmIsUInt8Literal : List PsWasmInstruction -> Bool
  | .i32Const value :: .i32Const mask :: .i32And :: [] =>
      value == 255 && mask == 255
  | _ => false

def psWasmIsUInt64Literal : List PsWasmInstruction -> Bool
  | .i64Const value :: [] => value == 42
  | _ => false

def psTestWasmMachineIntegerLiterals : Bool :=
  psWasmIsUInt8Literal
      (psWasmLowerMachineIntegerLiteral
        psWasmProfile32
        .uint8
        255)
    && psWasmIsUInt64Literal
      (psWasmLowerMachineIntegerLiteral
        psWasmProfile32
        .uint64
        42)

def psTestWasmMachineIntegerOps : Bool :=
  psWasmIsUInt8Add
      (psWasmLowerMachineIntegerBinary
        psWasmProfile32
        .uint8
        .add)
    && psWasmIsInt8Add
      (psWasmLowerMachineIntegerBinary
        psWasmProfile32
        .int8
        .add)
    && psWasmIsUInt64Xor
      (psWasmLowerMachineIntegerBinary
        psWasmProfile32
        .uint64
        .bitXor)
    && psWasmIsInt16Lt
      (psWasmLowerMachineIntegerCompare
        psWasmProfile32
        .int16
        .lt)
    && psWasmIsUInt16Lt
      (psWasmLowerMachineIntegerCompare
        psWasmProfile32
        .uint16
        .lt)
    && psWasmIsUSize64Add
      (psWasmLowerMachineIntegerBinary
        psWasmProfile64
        .usize
        .add)

def psWasmIsF32Add : List PsWasmInstruction -> Bool
  | .f32Add :: [] => true
  | _ => false

def psWasmIsF64Le : List PsWasmInstruction -> Bool
  | .f64Le :: [] => true
  | _ => false

def psTestWasmFloatOps : Bool :=
  psWasmIsF32Add
      (psWasmLowerFloatBinary .float32 .add)
    && psWasmIsF64Le
      (psWasmLowerFloatCompare .float .le)

def psWasmAddU32IrModule : PsVerifiedIrModule :=
  {
    imports := []
    structures := []
    inductives := []
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
    ]
  }

def psWasmIsAddU32Function : PsWasmFunction -> Bool
  | {
      name := name,
      typeName := none,
      parameters := [.i32, .i32],
      results := [.i32],
      locals := [],
      body := [.localGet 0, .localGet 1, .i32Add]
    } => name == "addU32"
  | _ => false

def psTestWasmVerifiedIrLowering : Bool :=
  match psWasmLowerModule psWasmProfile32 psWasmAddU32IrModule with
  | Except.error _ => false
  | Except.ok module =>
      match module.functions with
      | [function] =>
          psWasmIsAddU32Function function
            && module.exports == [("addU32", "addU32")]
      | _ => false

def psWasmLetIrModule : PsVerifiedIrModule :=
  {
    imports := []
    structures := []
    inductives := []
    declarations := [
      {
        name := "letU32"
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
    ]
  }

def psWasmIsLetU32Function : PsWasmFunction -> Bool
  | {
      name := name,
      typeName := none,
      parameters := [.i32],
      results := [.i32],
      locals := [.i32],
      body :=
        [
          .localGet 0,
          .localSet 1,
          .localGet 1,
          .i32Const 1,
          .i32Add
        ]
    } => name == "letU32"
  | _ => false

def psTestWasmLetLowering : Bool :=
  match psWasmLowerModule psWasmProfile32 psWasmLetIrModule with
  | Except.error _ => false
  | Except.ok module =>
      match module.functions with
      | [function] => psWasmIsLetU32Function function
      | _ => false

def psWasmStructureIrModule : PsVerifiedIrModule :=
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
    ]
    inductives := []
    declarations := [
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
    ]
  }

def psWasmIsPointStructure : PsWasmStructType -> Bool
  | {
      name := name,
      superType := none,
      isFinal := true,
      fields := [
        { name := "x", storageType := .value .i32 },
        { name := "y", storageType := .value .i32 }
      ]
    } => name == "Point"
  | _ => false

def psWasmIsSmallSignedStructure : PsWasmStructType -> Bool
  | {
      name := name,
      superType := none,
      isFinal := true,
      fields := [
        { name := "value", storageType := .packedI16 }
      ]
    } => name == "SmallSigned"
  | _ => false

def psWasmIsPointXFunction : PsWasmFunction -> Bool
  | {
      name := name,
      typeName := none,
      parameters := [.i32, .i32],
      results := [.i32],
      locals := [],
      body :=
        [
          .localGet 0,
          .localGet 1,
          .structNew "Point",
          .structGet "Point" 0
        ]
    } => name == "pointX"
  | _ => false

def psWasmIsSmallSignedFunction : PsWasmFunction -> Bool
  | {
      name := name,
      typeName := none,
      parameters := [.i32],
      results := [.i32],
      locals := [],
      body :=
        [
          .localGet 0,
          .structNew "SmallSigned",
          .structGetS "SmallSigned" 0
        ]
    } => name == "smallSigned"
  | _ => false

def psTestWasmStructureLowering : Bool :=
  match psWasmLowerModule psWasmProfile32 psWasmStructureIrModule with
  | Except.error _ => false
  | Except.ok module =>
      match module.structures, module.functions with
      | [point, small], [pointFn, smallFn] =>
          psWasmIsPointStructure point
            && psWasmIsSmallSignedStructure small
            && psWasmIsPointXFunction pointFn
            && psWasmIsSmallSignedFunction smallFn
      | _, _ => false

def psWasmMaybeIrModule : PsVerifiedIrModule :=
  {
    imports := []
    structures := []
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
    ]
    declarations := [
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
    ]
  }

def psWasmIsMaybeBase : PsWasmStructType -> Bool
  | {
      name := "MaybeU32",
      superType := none,
      isFinal := false,
      fields := []
    } => true
  | _ => false

def psWasmIsMaybeNone : PsWasmStructType -> Bool
  | {
      name := "MaybeU32$none",
      superType := some "MaybeU32",
      isFinal := true,
      fields := []
    } => true
  | _ => false

def psWasmIsMaybeSome : PsWasmStructType -> Bool
  | {
      name := "MaybeU32$some",
      superType := some "MaybeU32",
      isFinal := true,
      fields := [
        { name := "value", storageType := .value .i32 }
      ]
    } => true
  | _ => false

def psWasmIsSomeValueFunction : PsWasmFunction -> Bool
  | {
      name := "someValue",
      typeName := none,
      parameters := [.i32],
      results := [.i32],
      locals := [.refT "MaybeU32", .i32],
      body := [
        .localGet 0,
        .structNew "MaybeU32$some",
        .localSet 1,
        .localGet 1,
        .refTest "MaybeU32$none",
        .ifStart (some .i32),
        .i32Const 0,
        .else_,
        .localGet 1,
        .refCast "MaybeU32$some",
        .structGet "MaybeU32$some" 0,
        .localSet 2,
        .localGet 2,
        .end_
      ]
    } => true
  | _ => false

def psTestWasmInductiveMatchLowering : Bool :=
  match psWasmLowerModule psWasmProfile32 psWasmMaybeIrModule with
  | Except.error _ => false
  | Except.ok module =>
      match module.structures, module.functions with
      | [base, noneType, someType], someFn :: _ =>
          psWasmIsMaybeBase base
            && psWasmIsMaybeNone noneType
            && psWasmIsMaybeSome someType
            && psWasmIsSomeValueFunction someFn
      | _, _ => false

def psWasmRecursiveListIrModule : PsVerifiedIrModule :=
  {
    imports := []
    structures := []
    inductives := [
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
    ]
    declarations := [
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
    ]
  }

def psWasmIsRecursiveListTypes :
    List PsWasmStructType -> Bool
  | [
      {
        name := "U32List",
        superType := none,
        isFinal := false,
        fields := []
      },
      {
        name := "U32List$nil",
        superType := some "U32List",
        isFinal := true,
        fields := []
      },
      {
        name := "U32List$cons",
        superType := some "U32List",
        isFinal := true,
        fields := [
          { name := "head", storageType := .value .i32 },
          {
            name := "tail",
            storageType := .value (.refT "U32List")
          }
        ]
      }
    ] => true
  | _ => false

def psTestWasmRecursiveListLowering : Bool :=
  match
      psWasmLowerModule
        psWasmProfile32
        psWasmRecursiveListIrModule with
  | Except.error _ => false
  | Except.ok module =>
      psWasmIsRecursiveListTypes module.structures
        && module.functions.length == 2

def psWasmClosureTestU32Type : PsVerifiedIrType :=
  PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.uint32

def psWasmClosureTestFunctionType : PsVerifiedIrType :=
  PsVerifiedIrType.function
    [psWasmClosureTestU32Type]
    psWasmClosureTestU32Type

def psWasmClosureTestBaseName : String :=
  match psWasmClosureBaseName psWasmClosureTestFunctionType with
  | none => ""
  | some name => name

def psWasmClosureTestCodeTypeName : String :=
  match psWasmClosureCodeTypeName psWasmClosureTestFunctionType with
  | none => ""
  | some name => name

def psWasmClosureTestLambdaName : String :=
  "makeAdder$lambda$0"

def psWasmClosureTestSubtypeName : String :=
  psWasmClosureTestBaseName
    ++ "$"
    ++ psWasmClosureTestLambdaName

def psWasmClosureIrModule : PsVerifiedIrModule :=
  {
    imports := []
    structures := []
    inductives := []
    declarations := [
      {
        name := "makeAdder"
        typeParameters := []
        parameters := [
          {
            name := "base"
            type := psWasmClosureTestU32Type
          }
        ]
        resultType := psWasmClosureTestFunctionType
        body :=
          PsVerifiedIrExpr.lambda
            [
              {
                name := "value"
                type := psWasmClosureTestU32Type
              }
            ]
            psWasmClosureTestU32Type
            (PsVerifiedIrExpr.intrinsic
              (PsVerifiedIrIntrinsic.machineIntBinary
                PsVerifiedIrMachineIntegerType.uint32
                PsVerifiedIrIntegerBinaryOp.add)
              []
              [
                PsVerifiedIrExpr.var "base",
                PsVerifiedIrExpr.var "value"
              ])
      }
    ]
  }

def psWasmIsClosureBase : PsWasmStructType -> Bool
  | {
      name := name,
      superType := none,
      isFinal := false,
      fields := [
        {
          name := "code",
          storageType := .value .funcRef
        }
      ]
    } => name == psWasmClosureTestBaseName
  | _ => false

def psWasmIsClosureSubtype : PsWasmStructType -> Bool
  | {
      name := name,
      superType := some superName,
      isFinal := true,
      fields := [
        {
          name := "code",
          storageType := .value .funcRef
        },
        {
          name := "base",
          storageType := .value .i32
        }
      ]
    } =>
      name == psWasmClosureTestSubtypeName
        && superName == psWasmClosureTestBaseName
  | _ => false

def psWasmIsClosureCodeType : PsWasmFunctionType -> Bool
  | {
      name := name,
      parameters := [.refT baseName, .i32],
      results := [.i32]
    } =>
      name == psWasmClosureTestCodeTypeName
        && baseName == psWasmClosureTestBaseName
  | _ => false

def psWasmIsMakeAdderFunction : PsWasmFunction -> Bool
  | {
      name := "makeAdder",
      typeName := none,
      parameters := [.i32],
      results := [.refT resultBase],
      locals := [],
      body := [
        .refFunc lambdaName,
        .localGet 0,
        .structNew subtypeName
      ]
    } =>
      resultBase == psWasmClosureTestBaseName
        && lambdaName == psWasmClosureTestLambdaName
        && subtypeName == psWasmClosureTestSubtypeName
  | _ => false

def psWasmIsGeneratedClosureFunction : PsWasmFunction -> Bool
  | {
      name := lambdaName,
      typeName := some typeName,
      parameters := [.refT baseName, .i32],
      results := [.i32],
      locals := [.i32],
      body := [
        .localGet 0,
        .refCast subtypeName,
        .structGet captureType 1,
        .localSet 2,
        .localGet 2,
        .localGet 1,
        .i32Add
      ]
    } =>
      lambdaName == psWasmClosureTestLambdaName
        && typeName == psWasmClosureTestCodeTypeName
        && baseName == psWasmClosureTestBaseName
        && subtypeName == psWasmClosureTestSubtypeName
        && captureType == psWasmClosureTestSubtypeName
  | _ => false

def psTestWasmClosureLowering : Bool :=
  match
      psWasmLowerModule
        psWasmProfile32
        psWasmClosureIrModule with
  | Except.error _ => false
  | Except.ok module =>
      match
          module.structures,
          module.functionTypes,
          module.functions with
      | [baseType, subtype], [codeType], [makeAdder, generated] =>
          psWasmIsClosureBase baseType
            && psWasmIsClosureSubtype subtype
            && psWasmIsClosureCodeType codeType
            && psWasmIsMakeAdderFunction makeAdder
            && psWasmIsGeneratedClosureFunction generated
            && module.functionRefs ==
              [psWasmClosureTestLambdaName]
      | _, _, _ => false

def psWasmUInt8OfNatTestState : PsWasmLowerState :=
  {
    nextLocalIndex := 0
    localTypes := []
    currentDefinition := "test"
    nextLambdaId := 0
    generatedStructures := []
    generatedFunctionTypes := []
    generatedFunctions := []
    generatedFunctionRefs := []
  }

def psWasmUInt8OfNatTestLower
    (_expected : Option PsWasmValueType)
    (state : PsWasmLowerState)
    (_expr : PsVerifiedIrExpr) :
    Except PsWasmLowerError PsWasmLoweredExpr :=
  Except.ok {
    instructions := [PsWasmInstruction.localGet 0]
    state := state
  }

def psTestWasmUInt8OfNatIntrinsic : Bool :=
  match
      psWasmLowerIntrinsicWith
        psWasmProfile32
        psWasmUInt8OfNatTestLower
        psWasmUInt8OfNatTestState
        PsVerifiedIrIntrinsic.uint8OfNat
        []
        [PsVerifiedIrExpr.literal (PsVerifiedIrLiteral.natural 300)] with
  | Except.ok {
      instructions := [
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.call functionName,
        PsWasmInstruction.i32Const 255,
        PsWasmInstruction.i32And
      ],
      state := _
    } =>
      psStringEq functionName psWasmNatToU32Fn
  | _ => false

def psTestWasmRuntimeUnitRepresentation : Bool :=
  let unitType : PsVerifiedIrType :=
    PsVerifiedIrType.primitive
      PsVerifiedIrPrimitiveType.unit;
  let valueTypeOk : Bool :=
    match psWasmValueTypeOfIrType? psWasmProfile32 unitType with
    | Option.some PsWasmValueType.i32 => true
    | _ => false;
  let resultTypeOk : Bool :=
    match psWasmLowerResultType psWasmProfile32 unitType with
    | Except.ok [] => true
    | _ => false;
  let literalOk : Bool :=
    match
        psWasmLowerExpr
          psWasmProfile32
          []
          []
          []
          []
          (Option.some PsWasmValueType.i32)
          psWasmUInt8OfNatTestState
          (PsVerifiedIrExpr.literal
            PsVerifiedIrLiteral.unit) with
    | Except.ok {
        instructions := [PsWasmInstruction.i32Const 0],
        state := _
      } => true
    | _ => false;
  valueTypeOk && resultTypeOk && literalOk

def psWasmBoolInstructionMatches
    (operation : PsVerifiedIrIntrinsic)
    (instruction : PsWasmInstruction) : Bool :=
  match operation with
  | PsVerifiedIrIntrinsic.boolAnd =>
      match instruction with
      | PsWasmInstruction.i32And => true
      | _ => false
  | PsVerifiedIrIntrinsic.boolOr =>
      match instruction with
      | PsWasmInstruction.i32Or => true
      | _ => false
  | PsVerifiedIrIntrinsic.boolEq =>
      match instruction with
      | PsWasmInstruction.i32Eq => true
      | _ => false
  | PsVerifiedIrIntrinsic.boolNe =>
      match instruction with
      | PsWasmInstruction.i32Ne => true
      | _ => false
  | _ => false

def psTestWasmBoolBinaryIntrinsic
    (operation : PsVerifiedIrIntrinsic) : Bool :=
  match
      psWasmLowerIntrinsicWith
        psWasmProfile32
        psWasmUInt8OfNatTestLower
        psWasmUInt8OfNatTestState
        operation
        []
        [
          PsVerifiedIrExpr.literal (PsVerifiedIrLiteral.bool true),
          PsVerifiedIrExpr.literal (PsVerifiedIrLiteral.bool false)
        ] with
  | Except.ok {
      instructions := [
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.localGet 0,
        actual
      ],
      state := _
    } =>
      psWasmBoolInstructionMatches operation actual
  | _ => false

def psTestWasmBoolIntrinsics : Bool :=
  let notOk :=
    match
        psWasmLowerIntrinsicWith
          psWasmProfile32
          psWasmUInt8OfNatTestLower
          psWasmUInt8OfNatTestState
          PsVerifiedIrIntrinsic.boolNot
          []
          [PsVerifiedIrExpr.literal (PsVerifiedIrLiteral.bool true)] with
    | Except.ok {
        instructions := [
          PsWasmInstruction.localGet 0,
          PsWasmInstruction.i32Const 0,
          PsWasmInstruction.i32Eq
        ],
        state := _
      } => true
    | _ => false;
  notOk
    && psTestWasmBoolBinaryIntrinsic
      PsVerifiedIrIntrinsic.boolAnd
    && psTestWasmBoolBinaryIntrinsic
      PsVerifiedIrIntrinsic.boolOr
    && psTestWasmBoolBinaryIntrinsic
      PsVerifiedIrIntrinsic.boolEq
    && psTestWasmBoolBinaryIntrinsic
      PsVerifiedIrIntrinsic.boolNe

def psTestWasmCharOfNatIntrinsic : Bool :=
  match
      psWasmLowerIntrinsicWith
        psWasmProfile32
        psWasmUInt8OfNatTestLower
        psWasmUInt8OfNatTestState
        PsVerifiedIrIntrinsic.charOfNat
        []
        [PsVerifiedIrExpr.literal (PsVerifiedIrLiteral.natural 65)] with
  | Except.ok {
      instructions := [
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.localSet 0,
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.call fitsName,
        PsWasmInstruction.ifStart (Option.some PsWasmValueType.i32),
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.call toU32Name,
        PsWasmInstruction.localSet 1,
        PsWasmInstruction.localGet 1,
        PsWasmInstruction.i32Const 55296,
        PsWasmInstruction.i32LtU,
        PsWasmInstruction.ifStart (Option.some PsWasmValueType.i32),
        PsWasmInstruction.localGet 1,
        PsWasmInstruction.else_,
        PsWasmInstruction.localGet 1,
        PsWasmInstruction.i32Const 57343,
        PsWasmInstruction.i32GtU,
        PsWasmInstruction.localGet 1,
        PsWasmInstruction.i32Const 1114112,
        PsWasmInstruction.i32LtU,
        PsWasmInstruction.i32And,
        PsWasmInstruction.ifStart (Option.some PsWasmValueType.i32),
        PsWasmInstruction.localGet 1,
        PsWasmInstruction.else_,
        PsWasmInstruction.i32Const 0,
        PsWasmInstruction.end_,
        PsWasmInstruction.end_,
        PsWasmInstruction.else_,
        PsWasmInstruction.i32Const 0,
        PsWasmInstruction.end_
      ],
      state := finalState
    } =>
      psStringEq fitsName psWasmNatFitsU32Fn
        && psStringEq toU32Name psWasmNatToU32Fn
        && Nat.beq finalState.nextLocalIndex 2
  | _ => false

def psTestWasmCharToNatIntrinsic : Bool :=
  match
      psWasmLowerIntrinsicWith
        psWasmProfile32
        psWasmUInt8OfNatTestLower
        psWasmUInt8OfNatTestState
        PsVerifiedIrIntrinsic.charToNat
        []
        [PsVerifiedIrExpr.literal (PsVerifiedIrLiteral.natural 65)] with
  | Except.ok {
      instructions := [
        PsWasmInstruction.localGet 0,
        PsWasmInstruction.call functionName
      ],
      state := _
    } =>
      psStringEq functionName psWasmNatOfU32Fn
  | _ => false

def psWasmValidationSource : PsSpecializedIrModule :=
  PsSpecializedIrModule.mk
    {
      imports := []
      structures := []
      inductives := []
      declarations := [
        {
          name := "answer"
          typeParameters := []
          parameters := []
          resultType :=
            PsVerifiedIrType.primitive
              PsVerifiedIrPrimitiveType.uint32
          body :=
            PsVerifiedIrExpr.literal
              (PsVerifiedIrLiteral.machineInteger
                PsVerifiedIrMachineIntegerType.uint32
                42)
        }
      ]
    }

def psTestWasmTranslationValidator : Bool :=
  match
      psWasmLowerSpecializedValidatedModule
        psWasmProfile32
        psWasmValidationSource with
  | Except.error _ =>
      false
  | Except.ok lowered =>
      match
          psWasmValidateSpecializedLiteralModule
            psWasmValidationSource
            lowered with
      | Except.error _ =>
          false
      | Except.ok _ =>
          true

def psTestWasmTranslationValidatorRejectsDrift : Bool :=
  let drifted : PsWasmModule := {
    structures := []
    arrays := []
    functionTypes := []
    functions := [
      {
        name := "answer"
        typeName := none
        parameters := []
        results := [PsWasmValueType.i32]
        locals := []
        body := [PsWasmInstruction.i32Const 43]
      }
    ]
    functionRefs := []
    exports := [("answer", "answer")]
  };
  match
      psWasmValidateSpecializedLiteralModule
        psWasmValidationSource
        drifted with
  | Except.error
      (PsWasmTranslationValidationError.functionMismatch
        name) =>
      psStringEq name "answer"
  | _ =>
      false

def psWasmAnswerModule : PsWasmModule :=
  {
    structures := []
    arrays := []
    functionTypes := []
    functions := [
      {
        name := "answer"
        typeName := none
        parameters := []
        results := [PsWasmValueType.i32]
        locals := []
        body := [PsWasmInstruction.i32Const 42]
      }
    ]
    functionRefs := []
    exports := [("answer", "answer")]
  }

def psWasmExpectedAnswerBytes : List UInt8 := [
  psWasmByte 0,
  psWasmByte 97,
  psWasmByte 115,
  psWasmByte 109,
  psWasmByte 1,
  psWasmByte 0,
  psWasmByte 0,
  psWasmByte 0,
  psWasmByte 1,
  psWasmByte 7,
  psWasmByte 1,
  psWasmByte 78,
  psWasmByte 1,
  psWasmByte 96,
  psWasmByte 0,
  psWasmByte 1,
  psWasmByte 127,
  psWasmByte 3,
  psWasmByte 2,
  psWasmByte 1,
  psWasmByte 0,
  psWasmByte 7,
  psWasmByte 10,
  psWasmByte 1,
  psWasmByte 6,
  psWasmByte 97,
  psWasmByte 110,
  psWasmByte 115,
  psWasmByte 119,
  psWasmByte 101,
  psWasmByte 114,
  psWasmByte 0,
  psWasmByte 0,
  psWasmByte 10,
  psWasmByte 6,
  psWasmByte 1,
  psWasmByte 4,
  psWasmByte 0,
  psWasmByte 65,
  psWasmByte 42,
  psWasmByte 11
]

def psTestWasmUleb : Bool :=
  psWasmEncodeUleb 624485 ==
    [psWasmByte 229, psWasmByte 142, psWasmByte 38]

def psTestWasmSignedLeb : Bool :=
  psWasmEncodeI32Constant (-1) == [psWasmByte 127]
    && psWasmEncodeI32Constant 4294967295 == [psWasmByte 127]
    && psWasmEncodeI64Constant (-1) == [psWasmByte 127]
    && psWasmEncodeI64Constant 18446744073709551615 ==
      [psWasmByte 127]

def psTestWasmBinaryModule : Bool :=
  match psWasmEncodeModule psWasmAnswerModule with
  | Except.error _ => false
  | Except.ok bytes => bytes == psWasmExpectedAnswerBytes

def psTestWasmNatConstructorIdentityInvariant : Bool :=
      match psWasmNatRuntimeStructures with
      | _ :: _ :: bit0 :: bit1 :: _ =>
          bit0.name == psWasmNatBit0Name
            && bit1.name == psWasmNatBit1Name
            && bit0.fields.length == 1
            && bit1.fields.length == 2
      | _ => false

def psTestWasmTailPositions : Bool :=
  let body := [PsWasmInstruction.localGet 0,
    PsWasmInstruction.ifStart (Option.some PsWasmValueType.i32),
      PsWasmInstruction.call "nonTail", PsWasmInstruction.i32Const 1, PsWasmInstruction.i32Add,
    PsWasmInstruction.else_,
      PsWasmInstruction.localGet 1,
      PsWasmInstruction.ifStart (Option.some PsWasmValueType.i32),
        PsWasmInstruction.call "direct",
      PsWasmInstruction.else_,
        PsWasmInstruction.callRef "indirect",
      PsWasmInstruction.end_,
    PsWasmInstruction.end_];
  match psWasmTailCalls body with
  | [.localGet 0, .ifStart _, .call nonTail, .i32Const 1, .i32Add,
     .else_, .localGet 1, .ifStart _, .returnCall direct, .else_,
     .returnCallRef indirect, .end_, .end_] =>
      nonTail == "nonTail" && direct == "direct" && indirect == "indirect"
  | _ => false

def psTestWasmUnitReturnBridge : Bool :=
  let body := [PsWasmInstruction.localGet 0,
    PsWasmInstruction.ifStart (Option.some PsWasmValueType.i32),
      PsWasmInstruction.call "left", PsWasmInstruction.i32Const 0,
    PsWasmInstruction.else_,
      PsWasmInstruction.localGet 1,
      PsWasmInstruction.ifStart (Option.some PsWasmValueType.i32),
        PsWasmInstruction.callRef "right", PsWasmInstruction.i32Const 0,
      PsWasmInstruction.else_,
        PsWasmInstruction.localGet 2,
      PsWasmInstruction.end_,
    PsWasmInstruction.end_]
  match psWasmTailCalls (psWasmDiscardUnit body) with
  | [.localGet 0, .ifStart none, .returnCall left, .else_,
      .localGet 1, .ifStart none, .returnCallRef right, .else_,
      .localGet 2, .drop, .end_, .end_] => left == "left" && right == "right"
  | _ => false

def psTestWasmBulkEncoding : Bool :=
  let instructions := (List.range 20000).flatMap fun _ =>
    [PsWasmInstruction.i32Const 42, PsWasmInstruction.drop]
  let expected := (List.range 20000).flatMap fun _ =>
    [psWasmByte 65, psWasmByte 42, psWasmByte 26]
  let encoded :=
    match psWasmEncodeInstructions [] [] [] [] instructions with
    | Except.ok bytes => bytes == expected
    | Except.error _ => false
  let firstError :=
    match psWasmEncodeInstructions [] [] [] []
        [PsWasmInstruction.call "first", PsWasmInstruction.call "last"] with
    | Except.error (PsWasmEncodeError.unknownFunction name) => name == "first"
    | _ => false
  encoded && firstError

def psTestWasmBulkListOperations : Bool :=
  let values := List.range 65536
  let mapped := psListMap Nat.succ values
  let appendOk := psListAppend values [65536, 65537] == List.range 65538
  let mapOk := mapped == values.map Nat.succ
  let mapExceptOk :=
    match psListMapExcept (fun (value : Nat) => (Except.ok (value + 1) : Except String Nat)) values with
    | Except.ok result => result == mapped
    | Except.error _ => false
  let firstError :=
    match psListMapExcept (fun (value : Nat) => (Except.error value : Except Nat Nat)) [3, 7] with
    | Except.error value => value == 3
    | Except.ok _ => false
  appendOk && mapOk && mapExceptOk && firstError

def main : IO Unit := do
  if psTestWasmBulkEncoding
      && psTestWasmBulkListOperations
      && psTestWasmUnitReturnBridge
      && psTestWasmTailPositions
      && psTestWasmScalarLowering
      && psTestWasmNatConstructorIdentityInvariant
      && psTestWasmWordProfiles
      && psTestWasmMachineIntegerOps
      && psTestWasmMachineIntegerLiterals
      && psTestWasmUInt8OfNatIntrinsic
      && psTestWasmRuntimeUnitRepresentation
      && psTestWasmBoolIntrinsics
      && psTestWasmCharOfNatIntrinsic
      && psTestWasmCharToNatIntrinsic
      && psTestWasmFloatOps
      && psTestWasmVerifiedIrLowering
      && psTestWasmLetLowering
      && psTestWasmStructureLowering
      && psTestWasmInductiveMatchLowering
      && psTestWasmRecursiveListLowering
      && psTestWasmClosureLowering
      && psTestWasmTranslationValidator
      && psTestWasmTranslationValidatorRejectsDrift
      && psTestWasmUleb
      && psTestWasmSignedLeb
      && psTestWasmBinaryModule then
    IO.println "PSC1_BACKEND_WASM_TESTS: PASS"
  else
    throw (IO.userError "PSC1_BACKEND_WASM_TESTS: FAIL")
