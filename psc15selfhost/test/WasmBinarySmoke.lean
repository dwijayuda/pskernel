import Ps.BackendWasm.Lower
import Ps.BackendWasm.Binary
import Ps.BackendWasm.ValidateIr

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

def psWasmSmokeArrayType
    (elementType : PsVerifiedIrType) : PsVerifiedIrType :=
  PsVerifiedIrType.named "Array" [elementType]

def psWasmSmokeNatLiteral (value : Nat) : PsVerifiedIrExpr :=
  PsVerifiedIrExpr.literal (PsVerifiedIrLiteral.natural value)

def psWasmSmokeStringType : PsVerifiedIrType :=
  PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.string

def psWasmSmokeCharType : PsVerifiedIrType :=
  PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.char

def psWasmSmokeStringLiteral
    (value : String) : PsVerifiedIrExpr :=
  PsVerifiedIrExpr.literal
    (PsVerifiedIrLiteral.string value)

def psWasmSmokeCharOfNat
    (value : Nat) : PsVerifiedIrExpr :=
  PsVerifiedIrExpr.intrinsic
    PsVerifiedIrIntrinsic.charOfNat
    []
    [psWasmSmokeNatLiteral value]

def psWasmSmokeStringPush
    (value char : PsVerifiedIrExpr) : PsVerifiedIrExpr :=
  PsVerifiedIrExpr.intrinsic
    PsVerifiedIrIntrinsic.stringPush
    []
    [value, char]

def psWasmSmokeStringSingleton
    (char : PsVerifiedIrExpr) : PsVerifiedIrExpr :=
  PsVerifiedIrExpr.intrinsic
    PsVerifiedIrIntrinsic.stringSingleton
    []
    [char]

def psWasmSmokeStringLength
    (value : PsVerifiedIrExpr) : PsVerifiedIrExpr :=
  PsVerifiedIrExpr.intrinsic
    PsVerifiedIrIntrinsic.stringLength
    []
    [value]

def psWasmSmokeStringAppend
    (left right : PsVerifiedIrExpr) : PsVerifiedIrExpr :=
  PsVerifiedIrExpr.intrinsic
    PsVerifiedIrIntrinsic.stringAppend
    []
    [left, right]

def psWasmSmokeStringUtf8ByteSize
    (value : PsVerifiedIrExpr) : PsVerifiedIrExpr :=
  PsVerifiedIrExpr.intrinsic
    PsVerifiedIrIntrinsic.stringUtf8ByteSize
    []
    [value]

def psWasmSmokeStringNext
    (value position : PsVerifiedIrExpr) : PsVerifiedIrExpr :=
  PsVerifiedIrExpr.intrinsic
    PsVerifiedIrIntrinsic.stringNext
    []
    [value, position]

def psWasmSmokeStringGet
    (value position : PsVerifiedIrExpr) : PsVerifiedIrExpr :=
  PsVerifiedIrExpr.intrinsic
    PsVerifiedIrIntrinsic.stringGet
    []
    [value, position]

def psWasmSmokeStringAtEnd
    (value position : PsVerifiedIrExpr) : PsVerifiedIrExpr :=
  PsVerifiedIrExpr.intrinsic
    PsVerifiedIrIntrinsic.stringAtEnd
    []
    [value, position]

def psWasmSmokeStringExtract
    (value begin endPos : PsVerifiedIrExpr) : PsVerifiedIrExpr :=
  PsVerifiedIrExpr.intrinsic
    PsVerifiedIrIntrinsic.stringExtract
    []
    [value, begin, endPos]

def psWasmSmokeStringEq
    (left right : PsVerifiedIrExpr) : PsVerifiedIrExpr :=
  PsVerifiedIrExpr.intrinsic
    PsVerifiedIrIntrinsic.stringEq
    []
    [left, right]

def psWasmSmokeIntRepr
    (value : PsVerifiedIrExpr) : PsVerifiedIrExpr :=
  PsVerifiedIrExpr.intrinsic
    PsVerifiedIrIntrinsic.intRepr
    []
    [value]

def psWasmSmokeU32Literal (value : Int) : PsVerifiedIrExpr :=
  PsVerifiedIrExpr.literal
    (PsVerifiedIrLiteral.machineInteger
      PsVerifiedIrMachineIntegerType.uint32
      value)

def psWasmSmokeArrayEmpty
    (elementType : PsVerifiedIrType)
    (capacity : Nat) : PsVerifiedIrExpr :=
  PsVerifiedIrExpr.intrinsic
    PsVerifiedIrIntrinsic.arrayEmptyWithCapacity
    [elementType]
    [psWasmSmokeNatLiteral capacity]

def psWasmSmokeArraySize
    (elementType : PsVerifiedIrType)
    (array : PsVerifiedIrExpr) : PsVerifiedIrExpr :=
  PsVerifiedIrExpr.intrinsic
    PsVerifiedIrIntrinsic.arraySize
    [elementType]
    [array]

def psWasmSmokeArrayPush
    (elementType : PsVerifiedIrType)
    (array value : PsVerifiedIrExpr) : PsVerifiedIrExpr :=
  PsVerifiedIrExpr.intrinsic
    PsVerifiedIrIntrinsic.arrayPush
    [elementType]
    [array, value]

def psWasmSmokeArrayGet
    (elementType : PsVerifiedIrType)
    (array index : PsVerifiedIrExpr) : PsVerifiedIrExpr :=
  PsVerifiedIrExpr.intrinsic
    PsVerifiedIrIntrinsic.arrayGet
    [elementType]
    [array, index]

def psWasmSmokeArrayGetD
    (elementType : PsVerifiedIrType)
    (array index fallback : PsVerifiedIrExpr) : PsVerifiedIrExpr :=
  PsVerifiedIrExpr.intrinsic
    PsVerifiedIrIntrinsic.arrayGetD
    [elementType]
    [array, index, fallback]

def psWasmSmokeArraySet
    (elementType : PsVerifiedIrType)
    (array index value : PsVerifiedIrExpr) : PsVerifiedIrExpr :=
  PsVerifiedIrExpr.intrinsic
    PsVerifiedIrIntrinsic.arraySet
    [elementType]
    [array, index, value]

def psWasmSmokeArraySetIfInBounds
    (elementType : PsVerifiedIrType)
    (array index value : PsVerifiedIrExpr) : PsVerifiedIrExpr :=
  PsVerifiedIrExpr.intrinsic
    PsVerifiedIrIntrinsic.arraySetIfInBounds
    [elementType]
    [array, index, value]

def psWasmSmokeArrayMap
    (inputType outputType : PsVerifiedIrType)
    (fn array : PsVerifiedIrExpr) : PsVerifiedIrExpr :=
  PsVerifiedIrExpr.intrinsic
    PsVerifiedIrIntrinsic.arrayMap
    [inputType, outputType]
    [fn, array]

def psWasmSmokeArrayFoldl
    (elementType accumulatorType : PsVerifiedIrType)
    (fn init array start stop : PsVerifiedIrExpr) :
    PsVerifiedIrExpr :=
  PsVerifiedIrExpr.intrinsic
    PsVerifiedIrIntrinsic.arrayFoldl
    [elementType, accumulatorType]
    [fn, init, array, start, stop]

def psWasmSmokeU32ArrayTwo : PsVerifiedIrExpr :=
  psWasmSmokeArrayPush
    psWasmSmokeU32Type
    (psWasmSmokeArrayPush
      psWasmSmokeU32Type
      (psWasmSmokeArrayEmpty psWasmSmokeU32Type 2)
      (psWasmSmokeU32Literal 20))
    (psWasmSmokeU32Literal 22)

def psWasmSmokeU32ArrayThree : PsVerifiedIrExpr :=
  psWasmSmokeArrayPush
    psWasmSmokeU32Type
    (psWasmSmokeU32ArrayTwo)
    (psWasmSmokeU32Literal 30)

def psWasmSmokeSelectedFunction : PsVerifiedIrExpr :=
  PsVerifiedIrExpr.ifE (PsVerifiedIrExpr.var "choose")
    (PsVerifiedIrExpr.lambda [PsVerifiedIrParameter.mk "x" psWasmSmokeU32Type]
      psWasmSmokeU32Type
      (PsVerifiedIrExpr.intrinsic
        (PsVerifiedIrIntrinsic.machineIntBinary PsVerifiedIrMachineIntegerType.uint32 PsVerifiedIrIntegerBinaryOp.add)
        [] [PsVerifiedIrExpr.var "x", PsVerifiedIrExpr.var "offset"]))
    (PsVerifiedIrExpr.lambda [PsVerifiedIrParameter.mk "x" psWasmSmokeU32Type]
      psWasmSmokeU32Type
      (PsVerifiedIrExpr.intrinsic
        (PsVerifiedIrIntrinsic.machineIntBinary PsVerifiedIrMachineIntegerType.uint32 PsVerifiedIrIntegerBinaryOp.sub)
        [] [PsVerifiedIrExpr.var "x", PsVerifiedIrExpr.var "offset"]))


def psWasmSmokeUnitType : PsVerifiedIrType := .primitive .unit
def psWasmSmokeUnit : PsVerifiedIrExpr := .literal .unit
def psWasmSmokeUnitCall (name : String) (arguments : List PsVerifiedIrExpr) : PsVerifiedIrExpr :=
  .call (.var name) [] arguments

def psWasmSmokeUnitArray : PsVerifiedIrExpr :=
  psWasmSmokeArrayPush psWasmSmokeUnitType
    (psWasmSmokeArrayPush psWasmSmokeUnitType (psWasmSmokeArrayEmpty psWasmSmokeUnitType 2)
      (PsVerifiedIrExpr.var "unitValue"))
    (psWasmSmokeUnitCall "unitIdentity" [psWasmSmokeUnit])

def psWasmSmokeUnitDeclarations : List PsVerifiedIrDeclaration :=
  let unit := psWasmSmokeUnitType
  let token := psWasmSmokeUnit
  let boolean := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.bool
  let param := PsVerifiedIrParameter.mk "value" unit
  let value := PsVerifiedIrExpr.var "value"
  let decl := fun name parameters result body =>
    PsVerifiedIrDeclaration.mk name [] parameters result body
  let call := psWasmSmokeUnitCall
  let unitArray := psWasmSmokeUnitArray
  let unitFn := PsVerifiedIrType.function [unit] unit
  let mapper := PsVerifiedIrExpr.lambda [param] unit (call "unitIdentity" [value])
  let foldFn := PsVerifiedIrExpr.lambda [PsVerifiedIrParameter.mk "state" unit, param] unit
    (call "unitIdentity" [PsVerifiedIrExpr.var "state"])
  let trapping := PsVerifiedIrExpr.lambda [param] unit
    (PsVerifiedIrExpr.letE "mustEvaluate" psWasmSmokeU32Type
      (psWasmSmokeArrayGet psWasmSmokeU32Type
        (psWasmSmokeArrayEmpty psWasmSmokeU32Type 0) (psWasmSmokeNatLiteral 0)) token)
  [
    decl "unitValue" [] unit token,
    decl "unitIdentity" [param] unit value,
    decl "unitLocal" [] unit
      (.letE "saved" unit (call "unitIdentity" [PsVerifiedIrExpr.var "unitValue"]) (.var "saved")),
    decl "unitIf" [PsVerifiedIrParameter.mk "choose" boolean, param] unit
      (.ifE (.var "choose") (call "unitIdentity" [value]) (.var "unitValue")),
    decl "unitArgument" [PsVerifiedIrParameter.mk "choose" boolean] unit
      (call "unitIdentity" [.ifE (.var "choose") (.var "unitValue") (call "unitLocal" [])]),
    decl "unitMatch" [PsVerifiedIrParameter.mk "choose" boolean] unit
      (.matchE "MaybeU32" []
        (.ifE (.var "choose") (.constructor "MaybeU32" "none" [] [])
          (.constructor "MaybeU32" "some" [] [("value", psWasmSmokeU32Literal 9)]))
        [("none", [], call "unitLocal" []),
          ("some", [PsVerifiedIrMatchBinding.mk "value" "matched" psWasmSmokeU32Type],
            call "unitIdentity" [token])]),
    decl "unitApply" [PsVerifiedIrParameter.mk "fn" unitFn, param] unit
      (.call (.var "fn") [] [value]),
    decl "unitLambda" [PsVerifiedIrParameter.mk "choose" boolean] unit
      (call "unitApply" [.lambda [param] unit
        (call "unitIf" [.var "choose", value]), token]),
    decl "unitRecord" [] unit
      (.projection "UnitBox" [] (.record "UnitBox" [] [("token", call "unitLocal" [])]) "token"),
    decl "unitMapSize" [] boolean
      (.intrinsic .natEq []
        [psWasmSmokeArraySize unit (psWasmSmokeArrayMap unit unit mapper unitArray), psWasmSmokeNatLiteral 2]),
    decl "unitMapToU32" [] psWasmSmokeU32Type
      (psWasmSmokeArrayGet psWasmSmokeU32Type
        (psWasmSmokeArrayMap unit psWasmSmokeU32Type
          (.lambda [param] psWasmSmokeU32Type (psWasmSmokeU32Literal 42)) unitArray)
        (psWasmSmokeNatLiteral 1)),
    decl "unitFold" [] unit
      (psWasmSmokeArrayFoldl unit unit foldFn token unitArray
        (psWasmSmokeNatLiteral 0) (psWasmSmokeNatLiteral 2)),
    decl "unitTrappingMap" [] (psWasmSmokeArrayType unit)
      (psWasmSmokeArrayMap unit unit trapping unitArray),
    decl "unitEmptyMapSize" [] boolean
      (.intrinsic .natEq []
        [psWasmSmokeArraySize unit
          (psWasmSmokeArrayMap unit unit trapping (psWasmSmokeArrayEmpty unit 0)), psWasmSmokeNatLiteral 0]),
    decl "unitTailCountdown" [PsVerifiedIrParameter.mk "remaining" psWasmSmokeU32Type] unit
      (.ifE (.intrinsic (.machineIntCompare .uint32 .eq) [] [.var "remaining", psWasmSmokeU32Literal 0])
        token (call "unitTailCountdown"
          [.intrinsic (.machineIntBinary .uint32 .sub) [] [.var "remaining", psWasmSmokeU32Literal 1]]))
  ]

def psWasmSmokeIrModule : PsVerifiedIrModule :=
  {
    imports := []
    structures := [
      PsVerifiedIrStructure.mk "UnitBox" [] [PsVerifiedIrStructureField.mk "token" psWasmSmokeUnitType],
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
    declarations := psWasmSmokeUnitDeclarations ++ [
      {
        name := "largeLiteralContentExact"
        typeParameters := []
        parameters := []
        resultType := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.bool
        body :=
          let head := String.ofList (List.replicate 4095 'A');
          let tail := String.ofList (List.replicate 5000 'B');
          psWasmSmokeStringEq
            (psWasmSmokeStringLiteral (head ++ "😀é" ++ tail ++ tail))
            (psWasmSmokeStringAppend
              (psWasmSmokeStringAppend (psWasmSmokeStringLiteral head)
                (psWasmSmokeStringLiteral "😀é"))
              (psWasmSmokeStringAppend (psWasmSmokeStringLiteral tail)
                (psWasmSmokeStringLiteral tail)))
      },
      {
        name := "longUtf8ByteSizeExact"
        typeParameters := []
        parameters := []
        resultType := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.bool
        body := PsVerifiedIrExpr.intrinsic PsVerifiedIrIntrinsic.natEq []
          [psWasmSmokeStringUtf8ByteSize
             (let part := psWasmSmokeStringLiteral (String.ofList (List.replicate 5000 '😀'));
              let half := psWasmSmokeStringAppend part part;
              psWasmSmokeStringAppend half half),
           psWasmSmokeNatLiteral 80000]
      },
      {
        name := "tailCountdown"
        typeParameters := []
        parameters := [{ name := "remaining", type := psWasmSmokeU32Type },
                       { name := "total", type := psWasmSmokeU32Type }]
        resultType := psWasmSmokeU32Type
        body := PsVerifiedIrExpr.ifE
          (PsVerifiedIrExpr.intrinsic
            (PsVerifiedIrIntrinsic.machineIntCompare PsVerifiedIrMachineIntegerType.uint32 PsVerifiedIrIntegerCompareOp.eq) []
            [PsVerifiedIrExpr.var "remaining",
             PsVerifiedIrExpr.literal (PsVerifiedIrLiteral.machineInteger PsVerifiedIrMachineIntegerType.uint32 0)])
          (PsVerifiedIrExpr.var "total")
          (PsVerifiedIrExpr.call (PsVerifiedIrExpr.var "tailCountdown") []
            [PsVerifiedIrExpr.intrinsic
               (PsVerifiedIrIntrinsic.machineIntBinary PsVerifiedIrMachineIntegerType.uint32 PsVerifiedIrIntegerBinaryOp.sub) []
               [PsVerifiedIrExpr.var "remaining", PsVerifiedIrExpr.literal (PsVerifiedIrLiteral.machineInteger PsVerifiedIrMachineIntegerType.uint32 1)],
             PsVerifiedIrExpr.intrinsic
               (PsVerifiedIrIntrinsic.machineIntBinary PsVerifiedIrMachineIntegerType.uint32 PsVerifiedIrIntegerBinaryOp.add) []
               [PsVerifiedIrExpr.var "total", PsVerifiedIrExpr.literal (PsVerifiedIrLiteral.machineInteger PsVerifiedIrMachineIntegerType.uint32 1)]])
      },

      {
        name := "applySelectedFunction"
        typeParameters := []
        parameters := [
          PsVerifiedIrParameter.mk "choose" (PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.bool),
          PsVerifiedIrParameter.mk "offset" psWasmSmokeU32Type,
          PsVerifiedIrParameter.mk "value" psWasmSmokeU32Type]
        resultType := psWasmSmokeU32Type
        body := PsVerifiedIrExpr.call psWasmSmokeSelectedFunction [] [PsVerifiedIrExpr.var "value"]
      },
      {
        name := "applyComputedFunction"
        typeParameters := []
        parameters := [PsVerifiedIrParameter.mk "offset" psWasmSmokeU32Type,
          PsVerifiedIrParameter.mk "value" psWasmSmokeU32Type]
        resultType := psWasmSmokeU32Type
        body := PsVerifiedIrExpr.call
          (PsVerifiedIrExpr.call (PsVerifiedIrExpr.var "makeAdder") [] [PsVerifiedIrExpr.var "offset"])
          [] [PsVerifiedIrExpr.var "value"]
      },
      {
        name := "applyGlobalFunctionValue"
        typeParameters := []
        parameters := [PsVerifiedIrParameter.mk "value" psWasmSmokeU32Type]
        resultType := psWasmSmokeU32Type
        body := PsVerifiedIrExpr.letE "fn" psWasmSmokeU32FunctionType
          (PsVerifiedIrExpr.var "incrementU32")
          (PsVerifiedIrExpr.call (PsVerifiedIrExpr.var "fn") [] [PsVerifiedIrExpr.var "value"])
      },
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
        name := "natLiteralEqExact"
        typeParameters := []
        parameters := []
        resultType :=
          PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.bool
        body :=
          PsVerifiedIrExpr.intrinsic
            PsVerifiedIrIntrinsic.natEq
            []
            [
              PsVerifiedIrExpr.literal
                (PsVerifiedIrLiteral.natural 2),
              PsVerifiedIrExpr.literal
                (PsVerifiedIrLiteral.natural 2)
            ]
      },
      {
        name := "natAddOneOneExact"
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
                    (PsVerifiedIrLiteral.natural 1),
                  PsVerifiedIrExpr.literal
                    (PsVerifiedIrLiteral.natural 1)
                ],
              PsVerifiedIrExpr.literal
                (PsVerifiedIrLiteral.natural 2)
            ]
      },
      {
        name := "natAddCarrySmallExact"
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
                    (PsVerifiedIrLiteral.natural 3),
                  PsVerifiedIrExpr.literal
                    (PsVerifiedIrLiteral.natural 1)
                ],
              PsVerifiedIrExpr.literal
                (PsVerifiedIrLiteral.natural 4)
            ]
      },
      {
        name := "natAddCarryMidExact"
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
                    (PsVerifiedIrLiteral.natural 7),
                  PsVerifiedIrExpr.literal
                    (PsVerifiedIrLiteral.natural 3)
                ],
              PsVerifiedIrExpr.literal
                (PsVerifiedIrLiteral.natural 10)
            ]
      },
      {
        name := "natAddCarryExact"
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
                    (PsVerifiedIrLiteral.natural 14),
                  PsVerifiedIrExpr.literal
                    (PsVerifiedIrLiteral.natural 7)
                ],
              PsVerifiedIrExpr.literal
                (PsVerifiedIrLiteral.natural 21)
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
      },
      {
        name := "intOfNatExact"
        typeParameters := []
        parameters := []
        resultType :=
          PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.bool
        body :=
          PsVerifiedIrExpr.intrinsic
            PsVerifiedIrIntrinsic.intEq
            []
            [
              PsVerifiedIrExpr.intrinsic
              PsVerifiedIrIntrinsic.intOfNat
              []
              [
                PsVerifiedIrExpr.literal
                (PsVerifiedIrLiteral.natural 42)
              ],
              PsVerifiedIrExpr.literal
                (PsVerifiedIrLiteral.integer (42))
            ]
      },
      {
        name := "intNegSuccExact"
        typeParameters := []
        parameters := []
        resultType :=
          PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.bool
        body :=
          PsVerifiedIrExpr.intrinsic
            PsVerifiedIrIntrinsic.intEq
            []
            [
              PsVerifiedIrExpr.intrinsic
              PsVerifiedIrIntrinsic.intNegSucc
              []
              [
                PsVerifiedIrExpr.literal
                (PsVerifiedIrLiteral.natural 41)
              ],
              PsVerifiedIrExpr.literal
                (PsVerifiedIrLiteral.integer (-42))
            ]
      },
      {
        name := "intNegExact"
        typeParameters := []
        parameters := []
        resultType :=
          PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.bool
        body :=
          PsVerifiedIrExpr.intrinsic
            PsVerifiedIrIntrinsic.intEq
            []
            [
              PsVerifiedIrExpr.intrinsic
              PsVerifiedIrIntrinsic.intNeg
              []
              [
                PsVerifiedIrExpr.literal
                (PsVerifiedIrLiteral.integer (-42))
              ],
              PsVerifiedIrExpr.literal
                (PsVerifiedIrLiteral.integer (42))
            ]
      },
      {
        name := "intAddMixedExact"
        typeParameters := []
        parameters := []
        resultType :=
          PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.bool
        body :=
          PsVerifiedIrExpr.intrinsic
            PsVerifiedIrIntrinsic.intEq
            []
            [
              PsVerifiedIrExpr.intrinsic
              PsVerifiedIrIntrinsic.intAdd
              []
              [
                PsVerifiedIrExpr.literal
                (PsVerifiedIrLiteral.integer (-50)),
                PsVerifiedIrExpr.literal
                (PsVerifiedIrLiteral.integer (92))
              ],
              PsVerifiedIrExpr.literal
                (PsVerifiedIrLiteral.integer (42))
            ]
      },
      {
        name := "intSubMixedExact"
        typeParameters := []
        parameters := []
        resultType :=
          PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.bool
        body :=
          PsVerifiedIrExpr.intrinsic
            PsVerifiedIrIntrinsic.intEq
            []
            [
              PsVerifiedIrExpr.intrinsic
              PsVerifiedIrIntrinsic.intSub
              []
              [
                PsVerifiedIrExpr.literal
                (PsVerifiedIrLiteral.integer (20)),
                PsVerifiedIrExpr.literal
                (PsVerifiedIrLiteral.integer (-22))
              ],
              PsVerifiedIrExpr.literal
                (PsVerifiedIrLiteral.integer (42))
            ]
      },
      {
        name := "intMulSignedExact"
        typeParameters := []
        parameters := []
        resultType :=
          PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.bool
        body :=
          PsVerifiedIrExpr.intrinsic
            PsVerifiedIrIntrinsic.intEq
            []
            [
              PsVerifiedIrExpr.intrinsic
              PsVerifiedIrIntrinsic.intMul
              []
              [
                PsVerifiedIrExpr.literal
                (PsVerifiedIrLiteral.integer (-6)),
                PsVerifiedIrExpr.literal
                (PsVerifiedIrLiteral.integer (-7))
              ],
              PsVerifiedIrExpr.literal
                (PsVerifiedIrLiteral.integer (42))
            ]
      },
      {
        name := "intLargeExact"
        typeParameters := []
        parameters := []
        resultType :=
          PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.bool
        body :=
          PsVerifiedIrExpr.intrinsic
            PsVerifiedIrIntrinsic.intEq
            []
            [
              PsVerifiedIrExpr.intrinsic
              PsVerifiedIrIntrinsic.intAdd
              []
              [
                PsVerifiedIrExpr.literal
                (PsVerifiedIrLiteral.integer (-1208925819614629174706176)),
                PsVerifiedIrExpr.literal
                (PsVerifiedIrLiteral.integer (1208925819614629174706218))
              ],
              PsVerifiedIrExpr.literal
                (PsVerifiedIrLiteral.integer (42))
            ]
      },
      {
        name := "intLtExact"
        typeParameters := []
        parameters := []
        resultType :=
          PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.bool
        body :=
          PsVerifiedIrExpr.intrinsic
              PsVerifiedIrIntrinsic.intLt
              []
              [
                PsVerifiedIrExpr.literal
                (PsVerifiedIrLiteral.integer (-43)),
                PsVerifiedIrExpr.literal
                (PsVerifiedIrLiteral.integer (42))
              ]
      },

      {
        name := "intReprZeroExact"
        typeParameters := []
        parameters := []
        resultType :=
          PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.bool
        body :=
          psWasmSmokeStringEq
            (psWasmSmokeIntRepr
              (PsVerifiedIrExpr.literal
                (PsVerifiedIrLiteral.integer 0)))
            (psWasmSmokeStringLiteral "0")
      },
      {
        name := "intReprPositiveExact"
        typeParameters := []
        parameters := []
        resultType :=
          PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.bool
        body :=
          psWasmSmokeStringEq
            (psWasmSmokeIntRepr
              (PsVerifiedIrExpr.literal
                (PsVerifiedIrLiteral.integer 42)))
            (psWasmSmokeStringLiteral "42")
      },
      {
        name := "intReprNegativeExact"
        typeParameters := []
        parameters := []
        resultType :=
          PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.bool
        body :=
          psWasmSmokeStringEq
            (psWasmSmokeIntRepr
              (PsVerifiedIrExpr.literal
                (PsVerifiedIrLiteral.integer (-42))))
            (psWasmSmokeStringLiteral "-42")
      },
      {
        name := "intReprLargeExact"
        typeParameters := []
        parameters := []
        resultType :=
          PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.bool
        body :=
          psWasmSmokeStringEq
            (psWasmSmokeIntRepr
              (PsVerifiedIrExpr.literal
                (PsVerifiedIrLiteral.integer
                  (-1208925819614629174706176))))
            (psWasmSmokeStringLiteral
              "-1208925819614629174706176")
      },

      {
        name := "stringLiteralLengthExact"
        typeParameters := []
        parameters := []
        resultType :=
          PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.bool
        body :=
          PsVerifiedIrExpr.intrinsic
            PsVerifiedIrIntrinsic.natEq
            []
            [
              psWasmSmokeStringLength
                (psWasmSmokeStringLiteral "Aé😀"),
              psWasmSmokeNatLiteral 3
            ]
      },
      {
        name := "stringUtf8ByteSizeExact"
        typeParameters := []
        parameters := []
        resultType :=
          PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.bool
        body :=
          PsVerifiedIrExpr.intrinsic
            PsVerifiedIrIntrinsic.natEq
            []
            [
              psWasmSmokeStringUtf8ByteSize
                (psWasmSmokeStringLiteral "Aé😀"),
              psWasmSmokeNatLiteral 7
            ]
      },
      {
        name := "stringNextUnicodeExact"
        typeParameters := []
        parameters := []
        resultType :=
          PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.bool
        body :=
          PsVerifiedIrExpr.intrinsic
            PsVerifiedIrIntrinsic.natEq
            []
            [
              psWasmSmokeStringNext
                (psWasmSmokeStringLiteral "Aé😀")
                (psWasmSmokeNatLiteral 1),
              psWasmSmokeNatLiteral 3
            ]
      },
      {
        name := "stringNextMisalignedExact"
        typeParameters := []
        parameters := []
        resultType :=
          PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.bool
        body :=
          PsVerifiedIrExpr.intrinsic
            PsVerifiedIrIntrinsic.natEq
            []
            [
              psWasmSmokeStringNext
                (psWasmSmokeStringLiteral "Aé😀")
                (psWasmSmokeNatLiteral 2),
              psWasmSmokeNatLiteral 3
            ]
      },
      {
        name := "stringGetUnicode"
        typeParameters := []
        parameters := []
        resultType := psWasmSmokeCharType
        body :=
          psWasmSmokeStringGet
            (psWasmSmokeStringLiteral "Aé😀")
            (psWasmSmokeNatLiteral 3)
      },
      {
        name := "stringGetMisaligned"
        typeParameters := []
        parameters := []
        resultType := psWasmSmokeCharType
        body :=
          psWasmSmokeStringGet
            (psWasmSmokeStringLiteral "Aé😀")
            (psWasmSmokeNatLiteral 2)
      },
      {
        name := "stringAtEndExact"
        typeParameters := []
        parameters := []
        resultType :=
          PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.bool
        body :=
          psWasmSmokeStringAtEnd
            (psWasmSmokeStringLiteral "Aé😀")
            (psWasmSmokeNatLiteral 7)
      },
      {
        name := "stringAppendExact"
        typeParameters := []
        parameters := []
        resultType :=
          PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.bool
        body :=
          psWasmSmokeStringEq
            (psWasmSmokeStringAppend
              (psWasmSmokeStringLiteral "Aé")
              (psWasmSmokeStringLiteral "😀"))
            (psWasmSmokeStringLiteral "Aé😀")
      },
      {
        name := "stringPushExact"
        typeParameters := []
        parameters := []
        resultType :=
          PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.bool
        body :=
          psWasmSmokeStringEq
            (psWasmSmokeStringPush
              (psWasmSmokeStringLiteral "Aé")
              (psWasmSmokeCharOfNat 128512))
            (psWasmSmokeStringLiteral "Aé😀")
      },
      {
        name := "stringSingletonExact"
        typeParameters := []
        parameters := []
        resultType :=
          PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.bool
        body :=
          psWasmSmokeStringEq
            (psWasmSmokeStringSingleton
              (psWasmSmokeCharOfNat 233))
            (psWasmSmokeStringLiteral "é")
      },
      {
        name := "stringExtractExact"
        typeParameters := []
        parameters := []
        resultType :=
          PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.bool
        body :=
          psWasmSmokeStringEq
            (psWasmSmokeStringExtract
              (psWasmSmokeStringLiteral "Aé😀")
              (psWasmSmokeNatLiteral 1)
              (psWasmSmokeNatLiteral 7))
            (psWasmSmokeStringLiteral "é😀")
      },
      {
        name := "stringExtractMisalignedEmpty"
        typeParameters := []
        parameters := []
        resultType :=
          PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.bool
        body :=
          psWasmSmokeStringEq
            (psWasmSmokeStringExtract
              (psWasmSmokeStringLiteral "Aé😀")
              (psWasmSmokeNatLiteral 2)
              (psWasmSmokeNatLiteral 7))
            (psWasmSmokeStringLiteral "")
      },
      {
        name := "stringEqMismatch"
        typeParameters := []
        parameters := []
        resultType :=
          PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.bool
        body :=
          psWasmSmokeStringEq
            (psWasmSmokeStringLiteral "Aé😀")
            (psWasmSmokeStringLiteral "Aé😁")
      },

      {
        name := "incrementU32"
        typeParameters := []
        parameters := [
          {
            name := "value"
            type := psWasmSmokeU32Type
          }
        ]
        resultType := psWasmSmokeU32Type
        body :=
          PsVerifiedIrExpr.intrinsic
            (PsVerifiedIrIntrinsic.machineIntBinary
              PsVerifiedIrMachineIntegerType.uint32
              PsVerifiedIrIntegerBinaryOp.add)
            []
            [
              PsVerifiedIrExpr.var "value",
              psWasmSmokeU32Literal 1
            ]
      },
      {
        name := "arrayMapTopLevelGet"
        typeParameters := []
        parameters := []
        resultType := psWasmSmokeU32Type
        body :=
          psWasmSmokeArrayGet
            psWasmSmokeU32Type
            (psWasmSmokeArrayMap
              psWasmSmokeU32Type
              psWasmSmokeU32Type
              (PsVerifiedIrExpr.var "incrementU32")
              psWasmSmokeU32ArrayTwo)
            (psWasmSmokeNatLiteral 1)
      },
      {
        name := "arrayMapLambdaGet"
        typeParameters := []
        parameters := []
        resultType := psWasmSmokeU32Type
        body :=
          psWasmSmokeArrayGet
            psWasmSmokeU32Type
            (psWasmSmokeArrayMap
              psWasmSmokeU32Type
              psWasmSmokeU32Type
              (PsVerifiedIrExpr.lambda
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
                    PsVerifiedIrExpr.var "value",
                    psWasmSmokeU32Literal 2
                  ]))
              psWasmSmokeU32ArrayTwo)
            (psWasmSmokeNatLiteral 0)
      },
      {
        name := "arrayMapEmptySizeExact"
        typeParameters := []
        parameters := []
        resultType :=
          PsVerifiedIrType.primitive
            PsVerifiedIrPrimitiveType.bool
        body :=
          PsVerifiedIrExpr.intrinsic
            PsVerifiedIrIntrinsic.natEq
            []
            [
              psWasmSmokeArraySize
                psWasmSmokeU32Type
                (psWasmSmokeArrayMap
                  psWasmSmokeU32Type
                  psWasmSmokeU32Type
                  (PsVerifiedIrExpr.var "incrementU32")
                  (psWasmSmokeArrayEmpty
                    psWasmSmokeU32Type
                    4)),
              psWasmSmokeNatLiteral 0
            ]
      },
      {
        name := "arrayFoldRange"
        typeParameters := []
        parameters := []
        resultType := psWasmSmokeU32Type
        body :=
          psWasmSmokeArrayFoldl
            psWasmSmokeU32Type
            psWasmSmokeU32Type
            (PsVerifiedIrExpr.var "addU32")
            (psWasmSmokeU32Literal 1)
            psWasmSmokeU32ArrayThree
            (psWasmSmokeNatLiteral 1)
            (psWasmSmokeNatLiteral 3)
      },
      {
        name := "arrayFoldStopBeyond"
        typeParameters := []
        parameters := []
        resultType := psWasmSmokeU32Type
        body :=
          psWasmSmokeArrayFoldl
            psWasmSmokeU32Type
            psWasmSmokeU32Type
            (PsVerifiedIrExpr.var "addU32")
            (psWasmSmokeU32Literal 0)
            psWasmSmokeU32ArrayTwo
            (psWasmSmokeNatLiteral 0)
            (psWasmSmokeNatLiteral
              1208925819614629174706176)
      },
      {
        name := "arrayFoldStartBeyond"
        typeParameters := []
        parameters := []
        resultType := psWasmSmokeU32Type
        body :=
          psWasmSmokeArrayFoldl
            psWasmSmokeU32Type
            psWasmSmokeU32Type
            (PsVerifiedIrExpr.var "addU32")
            (psWasmSmokeU32Literal 7)
            psWasmSmokeU32ArrayTwo
            (psWasmSmokeNatLiteral
              1208925819614629174706176)
            (psWasmSmokeNatLiteral
              1208925819614629174706177)
      },
      {
        name := "arrayEmptySizeExact"
        typeParameters := []
        parameters := []
        resultType :=
          PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.bool
        body :=
          PsVerifiedIrExpr.intrinsic
            PsVerifiedIrIntrinsic.natEq
            []
            [
              psWasmSmokeArraySize
                psWasmSmokeU32Type
                (psWasmSmokeArrayEmpty psWasmSmokeU32Type 100),
              psWasmSmokeNatLiteral 0
            ]
      },
      {
        name := "arrayPushGet"
        typeParameters := []
        parameters := []
        resultType := psWasmSmokeU32Type
        body :=
          psWasmSmokeArrayGet
            psWasmSmokeU32Type
            (psWasmSmokeArrayPush
              psWasmSmokeU32Type
              (psWasmSmokeArrayEmpty psWasmSmokeU32Type 1)
              (psWasmSmokeU32Literal 42))
            (psWasmSmokeNatLiteral 0)
      },
      {
        name := "arrayPushSizeExact"
        typeParameters := []
        parameters := []
        resultType :=
          PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.bool
        body :=
          PsVerifiedIrExpr.intrinsic
            PsVerifiedIrIntrinsic.natEq
            []
            [
              psWasmSmokeArraySize
                psWasmSmokeU32Type
                psWasmSmokeU32ArrayTwo,
              psWasmSmokeNatLiteral 2
            ]
      },
      {
        name := "arrayGetDInBounds"
        typeParameters := []
        parameters := []
        resultType := psWasmSmokeU32Type
        body :=
          psWasmSmokeArrayGetD
            psWasmSmokeU32Type
            psWasmSmokeU32ArrayTwo
            (psWasmSmokeNatLiteral 1)
            (psWasmSmokeU32Literal 99)
      },
      {
        name := "arrayGetDOob"
        typeParameters := []
        parameters := []
        resultType := psWasmSmokeU32Type
        body :=
          psWasmSmokeArrayGetD
            psWasmSmokeU32Type
            psWasmSmokeU32ArrayTwo
            (psWasmSmokeNatLiteral 7)
            (psWasmSmokeU32Literal 99)
      },
      {
        name := "arrayGetDHugeIndex"
        typeParameters := []
        parameters := []
        resultType := psWasmSmokeU32Type
        body :=
          psWasmSmokeArrayGetD
            psWasmSmokeU32Type
            psWasmSmokeU32ArrayTwo
            (psWasmSmokeNatLiteral 1208925819614629174706176)
            (psWasmSmokeU32Literal 99)
      },
      {
        name := "arraySetPersistent"
        typeParameters := []
        parameters := []
        resultType := psWasmSmokeU32Type
        body :=
          PsVerifiedIrExpr.letE
            "original"
            (psWasmSmokeArrayType psWasmSmokeU32Type)
            (psWasmSmokeArrayPush
              psWasmSmokeU32Type
              (psWasmSmokeArrayEmpty psWasmSmokeU32Type 1)
              (psWasmSmokeU32Literal 20))
            (PsVerifiedIrExpr.letE
              "updated"
              (psWasmSmokeArrayType psWasmSmokeU32Type)
              (psWasmSmokeArraySet
                psWasmSmokeU32Type
                (PsVerifiedIrExpr.var "original")
                (psWasmSmokeNatLiteral 0)
                (psWasmSmokeU32Literal 42))
              (PsVerifiedIrExpr.intrinsic
                (PsVerifiedIrIntrinsic.machineIntBinary
                  PsVerifiedIrMachineIntegerType.uint32
                  PsVerifiedIrIntegerBinaryOp.add)
                []
                [
                  psWasmSmokeArrayGet
                    psWasmSmokeU32Type
                    (PsVerifiedIrExpr.var "original")
                    (psWasmSmokeNatLiteral 0),
                  psWasmSmokeArrayGet
                    psWasmSmokeU32Type
                    (PsVerifiedIrExpr.var "updated")
                    (psWasmSmokeNatLiteral 0)
                ]))
      },
      {
        name := "arraySetIfInBoundsOob"
        typeParameters := []
        parameters := []
        resultType := psWasmSmokeU32Type
        body :=
          psWasmSmokeArrayGet
            psWasmSmokeU32Type
            (psWasmSmokeArraySetIfInBounds
              psWasmSmokeU32Type
              (psWasmSmokeArrayPush
                psWasmSmokeU32Type
                (psWasmSmokeArrayEmpty psWasmSmokeU32Type 1)
                (psWasmSmokeU32Literal 20))
              (psWasmSmokeNatLiteral 1208925819614629174706176)
              (psWasmSmokeU32Literal 99))
            (psWasmSmokeNatLiteral 0)
      },
      {
        name := "arrayNatRoundTripExact"
        typeParameters := []
        parameters := []
        resultType :=
          PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.bool
        body :=
          PsVerifiedIrExpr.intrinsic
            PsVerifiedIrIntrinsic.natEq
            []
            [
              psWasmSmokeArrayGet
                psWasmSmokeNatType
                (psWasmSmokeArrayPush
                  psWasmSmokeNatType
                  (psWasmSmokeArrayEmpty psWasmSmokeNatType 1)
                  (psWasmSmokeNatLiteral 42))
                (psWasmSmokeNatLiteral 0),
              psWasmSmokeNatLiteral 42
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
      let .ok _ := psWasmIrValidateModule moduleWithArraySmoke
        | throw (IO.userError "PSC1_BACKEND_WASM_BINARY_SMOKE: target validation failed")
      match psWasmEncodeModule moduleWithArraySmoke with
      | Except.error error =>
          let detail :=
            match error with
            | PsWasmEncodeError.unsupportedValueType => "unsupportedValueType"
            | PsWasmEncodeError.unsupportedInstruction => "unsupportedInstruction"
            | PsWasmEncodeError.negativeIntegerConstant => "negativeIntegerConstant"
            | PsWasmEncodeError.unknownFunction name => "unknownFunction:" ++ name
            | PsWasmEncodeError.unknownFunctionType name => "unknownFunctionType:" ++ name
            | PsWasmEncodeError.unknownStructure name => "unknownStructure:" ++ name
          throw (IO.userError ("PSC1_BACKEND_WASM_BINARY_SMOKE: encode failed: " ++ detail))
      | Except.ok bytes =>
          IO.println (psWasmJoinComma (psWasmByteStrings bytes))
