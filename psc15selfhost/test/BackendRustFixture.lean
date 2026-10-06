import Ps.BackendRust.Module

def psBackendRustLetClosureFixture : PsVerifiedIrDeclaration :=
  let natType := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat;
  PsVerifiedIrDeclaration.mk "makeAdderViaLet" []
    [PsVerifiedIrParameter.mk "offset" natType]
    (PsVerifiedIrType.function [natType] natType)
    (PsVerifiedIrExpr.letE "captured" natType (PsVerifiedIrExpr.var "offset")
      (PsVerifiedIrExpr.lambda [PsVerifiedIrParameter.mk "value" natType] natType
        (PsVerifiedIrExpr.intrinsic PsVerifiedIrIntrinsic.natAdd []
          [PsVerifiedIrExpr.var "value", PsVerifiedIrExpr.var "captured"])))

def psBackendRustSharedCaptureFixture : PsVerifiedIrDeclaration :=
  let natType := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat;
  let fnType := PsVerifiedIrType.function [natType] natType;
  let closure := PsVerifiedIrExpr.lambda [PsVerifiedIrParameter.mk "value" natType] natType
    (PsVerifiedIrExpr.intrinsic PsVerifiedIrIntrinsic.natAdd []
      [PsVerifiedIrExpr.var "value", PsVerifiedIrExpr.var "offset"]);
  PsVerifiedIrDeclaration.mk "sharedCapture" []
    [PsVerifiedIrParameter.mk "offset" natType, PsVerifiedIrParameter.mk "value" natType]
    natType
    (PsVerifiedIrExpr.letE "first" fnType closure
      (PsVerifiedIrExpr.letE "second" fnType closure
        (PsVerifiedIrExpr.intrinsic PsVerifiedIrIntrinsic.natAdd []
          [PsVerifiedIrExpr.call (PsVerifiedIrExpr.var "first") [] [PsVerifiedIrExpr.var "value"],
           PsVerifiedIrExpr.call (PsVerifiedIrExpr.var "second") [] [PsVerifiedIrExpr.var "offset"]])))

def psBackendRustGlobalCallbackFixture : PsVerifiedIrDeclaration :=
  let natType := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat;
  let fnType := PsVerifiedIrType.function [natType] natType;
  PsVerifiedIrDeclaration.mk "globalCallback" [] [PsVerifiedIrParameter.mk "value" natType] natType
    (PsVerifiedIrExpr.letE "arrayIdOnly" fnType
      (PsVerifiedIrExpr.call (PsVerifiedIrExpr.var "returnCallback") []
        [PsVerifiedIrExpr.var "arrayIdOnly"])
      (PsVerifiedIrExpr.call (PsVerifiedIrExpr.var "arrayIdOnly") [] [PsVerifiedIrExpr.var "value"]))

def psBackendRustConditionalCallbackFixture : PsVerifiedIrDeclaration :=
  let natType := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat;
  PsVerifiedIrDeclaration.mk "conditionalCallback" []
    [PsVerifiedIrParameter.mk "choose" (PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.bool),
     PsVerifiedIrParameter.mk "value" natType] natType
    (PsVerifiedIrExpr.call
      (PsVerifiedIrExpr.ifE (PsVerifiedIrExpr.var "choose")
        (PsVerifiedIrExpr.var "arrayIdOnly") (PsVerifiedIrExpr.var "countDown")) []
      [PsVerifiedIrExpr.var "value"])

def psRustTailFixtureType : PsVerifiedIrType := .primitive .uint32

def psRustTailFixtureBinary (operation : PsVerifiedIrIntegerBinaryOp)
    (left right : PsVerifiedIrExpr) : PsVerifiedIrExpr :=
  .intrinsic (.machineIntBinary .uint32 operation) [] [left, right]

def psRustTailFixtureLit (value : Int) : PsVerifiedIrExpr := .literal (.machineInteger .uint32 value)

def psRustTailSwapFixture : PsVerifiedIrDeclaration :=
  .mk "tailSwap" [] [.mk "count" psRustTailFixtureType, .mk "left" psRustTailFixtureType, .mk "right" psRustTailFixtureType]
    psRustTailFixtureType
    (.ifE (.intrinsic (.machineIntCompare .uint32 .eq) [] [.var "count", psRustTailFixtureLit 0])
      (.var "left")
      (.call (.var "tailSwap") []
        [psRustTailFixtureBinary .sub (.var "count") (psRustTailFixtureLit 1), .var "right", .var "left"]))

def psRustTailShadowFixture : PsVerifiedIrDeclaration :=
  .mk "tailShadow" [] [.mk "count" psRustTailFixtureType, .mk "value" psRustTailFixtureType] psRustTailFixtureType
    (.ifE (.intrinsic (.machineIntCompare .uint32 .eq) [] [.var "count", psRustTailFixtureLit 0])
      (.var "value")
      (.letE "value" psRustTailFixtureType (psRustTailFixtureBinary .add (.var "value") (psRustTailFixtureLit 1))
        (.call (.var "tailShadow") [] [psRustTailFixtureBinary .sub (.var "count") (psRustTailFixtureLit 1), .var "value"])))

def psRustTailChainFixture : PsVerifiedIrDeclaration :=
  let chain := PsVerifiedIrType.named "SharedChain" [psRustTailFixtureType];
  .mk "tailChainCount" [] [.mk "chain" chain, .mk "count" psRustTailFixtureType] psRustTailFixtureType
    (.matchE "SharedChain" [psRustTailFixtureType] (.var "chain")
      [("empty", [], .var "count"),
       ("link", [.mk "head" "head" psRustTailFixtureType, .mk "tail" "tail" chain],
         .call (.var "tailChainCount") [] [.var "tail", psRustTailFixtureBinary .add (.var "count") (psRustTailFixtureLit 1)])])

def psRustTailAliasFixture (functionName aliasName shadowName : String) : PsVerifiedIrDeclaration :=
  .mk functionName [] [.mk "count" psRustTailFixtureType, .mk "value" psRustTailFixtureType] psRustTailFixtureType
    (.ifE (.intrinsic (.machineIntCompare .uint32 .eq) [] [.var "count", psRustTailFixtureLit 0]) (.var "value")
      (.letE "remaining" psRustTailFixtureType (psRustTailFixtureBinary .sub (.var "count") (psRustTailFixtureLit 1))
        (.letE aliasName (.function [psRustTailFixtureType] psRustTailFixtureType)
          (.lambda [.mk "next" psRustTailFixtureType] psRustTailFixtureType
            (.call (.var functionName) [] [.var "remaining", .var "next"]))
          (.letE shadowName psRustTailFixtureType (psRustTailFixtureLit 0)
            (.call (.var aliasName) [] [psRustTailFixtureBinary .add (.var "value") (psRustTailFixtureLit 1)])))))

def psRustTailGenericFixture : PsVerifiedIrDeclaration :=
  let type := PsVerifiedIrType.typeParameter "A";
  .mk "genericTailAlias" [.mk "A"] [.mk "count" psRustTailFixtureType, .mk "value" type] type
    (.ifE (.intrinsic (.machineIntCompare .uint32 .eq) [] [.var "count", psRustTailFixtureLit 0]) (.var "value")
      (.letE "remaining" psRustTailFixtureType (psRustTailFixtureBinary .sub (.var "count") (psRustTailFixtureLit 1))
        (.letE "smaller" (.function [type] type)
          (.lambda [.mk "next" type] type (.call (.var "genericTailAlias") [type] [.var "remaining", .var "next"]))
          (.call (.var "smaller") [] [.var "value"]))))

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
      },
      {
        name := "CallbackHolder"
        typeParameters := []
        fields := [
          {
            name := "callback"
            type :=
              PsVerifiedIrType.function
                [PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat]
                (PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat)
          }
        ]
      }
    ]
    inductives := [
      PsVerifiedIrInductive.mk "SharedChain" [PsVerifiedIrTypeParameter.mk "A"]
        [PsVerifiedIrConstructor.mk "empty" [],
         PsVerifiedIrConstructor.mk "link"
           [PsVerifiedIrConstructorField.mk "head" (PsVerifiedIrType.typeParameter "A"),
            PsVerifiedIrConstructorField.mk "tail" (PsVerifiedIrType.named "SharedChain" [PsVerifiedIrType.typeParameter "A"])]],
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
      },
      {
        name := "CallbackBox"
        typeParameters := []
        constructors := [
          {
            name := "stored"
            fields := [
              {
                name := "callback"
                type :=
                  PsVerifiedIrType.function
                    [PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat]
                    (PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat)
              }
            ]
          }
        ]
      }
    ]
    declarations := [
      psRustTailSwapFixture,
      psRustTailShadowFixture,
      psRustTailChainFixture,
      psRustTailAliasFixture "tailAlias" "smaller" "remaining",
      psRustTailAliasFixture "tailAliasBeforeBinder" "remaining" "count",
      psRustTailGenericFixture,
      PsVerifiedIrDeclaration.mk "shareChain" [PsVerifiedIrTypeParameter.mk "A"]
        [PsVerifiedIrParameter.mk "value" (PsVerifiedIrType.named "SharedChain" [PsVerifiedIrType.typeParameter "A"])]
        (PsVerifiedIrType.named "SharedChain" [PsVerifiedIrType.typeParameter "A"]) (PsVerifiedIrExpr.var "value"),
      psBackendRustLetClosureFixture,
      psBackendRustSharedCaptureFixture,
      psBackendRustGlobalCallbackFixture,
      psBackendRustConditionalCallbackFixture,
      {
        name := "idUInt8"
        typeParameters := []
        parameters := [{ name := "x", type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.uint8 }]
        resultType := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.uint8
        body := PsVerifiedIrExpr.var "x"
      },
      {
        name := "idUInt16"
        typeParameters := []
        parameters := [{ name := "x", type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.uint16 }]
        resultType := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.uint16
        body := PsVerifiedIrExpr.var "x"
      },
      {
        name := "idUInt32"
        typeParameters := []
        parameters := [{ name := "x", type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.uint32 }]
        resultType := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.uint32
        body := PsVerifiedIrExpr.var "x"
      },
      {
        name := "idUInt64"
        typeParameters := []
        parameters := [{ name := "x", type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.uint64 }]
        resultType := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.uint64
        body := PsVerifiedIrExpr.var "x"
      },
      {
        name := "idUSize"
        typeParameters := []
        parameters := [{ name := "x", type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.usize }]
        resultType := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.usize
        body := PsVerifiedIrExpr.var "x"
      },
      {
        name := "idInt8"
        typeParameters := []
        parameters := [{ name := "x", type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.int8 }]
        resultType := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.int8
        body := PsVerifiedIrExpr.var "x"
      },
      {
        name := "idInt16"
        typeParameters := []
        parameters := [{ name := "x", type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.int16 }]
        resultType := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.int16
        body := PsVerifiedIrExpr.var "x"
      },
      {
        name := "idInt32"
        typeParameters := []
        parameters := [{ name := "x", type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.int32 }]
        resultType := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.int32
        body := PsVerifiedIrExpr.var "x"
      },
      {
        name := "idInt64"
        typeParameters := []
        parameters := [{ name := "x", type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.int64 }]
        resultType := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.int64
        body := PsVerifiedIrExpr.var "x"
      },
      {
        name := "idISize"
        typeParameters := []
        parameters := [{ name := "x", type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.isize }]
        resultType := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.isize
        body := PsVerifiedIrExpr.var "x"
      },
      {
        name := "idFloat"
        typeParameters := []
        parameters := [{ name := "x", type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.float }]
        resultType := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.float
        body := PsVerifiedIrExpr.var "x"
      },
      {
        name := "idFloat32"
        typeParameters := []
        parameters := [{ name := "x", type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.float32 }]
        resultType := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.float32
        body := PsVerifiedIrExpr.var "x"
      },
      {
        name := "countDown"
        typeParameters := []
        parameters := [
          {
            name := "x"
            type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat
          }
        ]
        resultType := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat
        body :=
          PsVerifiedIrExpr.ifE
            (PsVerifiedIrExpr.intrinsic
              PsVerifiedIrIntrinsic.natEq
              []
              [
                PsVerifiedIrExpr.var "x",
                PsVerifiedIrExpr.literal
                  (PsVerifiedIrLiteral.natural 0)
              ])
            (PsVerifiedIrExpr.literal
              (PsVerifiedIrLiteral.natural 0))
            (PsVerifiedIrExpr.call
              (PsVerifiedIrExpr.var "countDown")
              []
              [
                PsVerifiedIrExpr.intrinsic
                  PsVerifiedIrIntrinsic.natSub
                  []
                  [
                    PsVerifiedIrExpr.var "x",
                    PsVerifiedIrExpr.literal
                      (PsVerifiedIrLiteral.natural 1)
                  ]
              ])
      },
      {
        name := "one"
        typeParameters := []
        parameters := []
        resultType := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat
        body := PsVerifiedIrExpr.literal (PsVerifiedIrLiteral.natural 1)
      },
      {
        name := "addGlobalOne"
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
            []
            [
              PsVerifiedIrExpr.var "x",
              PsVerifiedIrExpr.var "one"
            ]
      },
      {
        name := "shadowOne"
        typeParameters := []
        parameters := [
          {
            name := "one"
            type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat
          }
        ]
        resultType := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat
        body := PsVerifiedIrExpr.var "one"
      },
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
            []
            [
              PsVerifiedIrExpr.var "x",
              PsVerifiedIrExpr.literal (PsVerifiedIrLiteral.natural 1)
            ]
      },
      {
        name := "makeAdder"
        typeParameters := []
        parameters := [
          {
            name := "offset"
            type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat
          }
        ]
        resultType :=
          PsVerifiedIrType.function
            [PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat]
            (PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat)
        body :=
          PsVerifiedIrExpr.lambda
            [
              {
                name := "value"
                type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat
              }
            ]
            (PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat)
            (PsVerifiedIrExpr.intrinsic
              PsVerifiedIrIntrinsic.natAdd
              []
              [
                PsVerifiedIrExpr.var "value",
                PsVerifiedIrExpr.var "offset"
              ])
      },
      {
        name := "returnCallback"
        typeParameters := []
        parameters := [
          {
            name := "callback"
            type :=
              PsVerifiedIrType.function
                [PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat]
                (PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat)
          }
        ]
        resultType :=
          PsVerifiedIrType.function
            [PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat]
            (PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat)
        body := PsVerifiedIrExpr.var "callback"
      },
      {
        name := "applyViaCapturedLambda"
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
          PsVerifiedIrExpr.letE
            "callback"
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
              (PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat)
              (PsVerifiedIrExpr.intrinsic
                PsVerifiedIrIntrinsic.natAdd
                []
                [
                  PsVerifiedIrExpr.var "value",
                  PsVerifiedIrExpr.var "offset"
                ]))
            (PsVerifiedIrExpr.call
              (PsVerifiedIrExpr.lambda
                [
                  {
                    name := "f"
                    type :=
                      PsVerifiedIrType.function
                        [PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat]
                        (PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat)
                  },
                  {
                    name := "value"
                    type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat
                  }
                ]
                (PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat)
                (PsVerifiedIrExpr.call
                  (PsVerifiedIrExpr.var "f")
                  []
                  [PsVerifiedIrExpr.var "value"]))
              []
              [
                PsVerifiedIrExpr.var "callback",
                PsVerifiedIrExpr.var "x"
              ])
      },
      {
        name := "storePlusOne"
        typeParameters := []
        parameters := []
        resultType := PsVerifiedIrType.named "CallbackHolder" []
        body :=
          PsVerifiedIrExpr.record
            "CallbackHolder"
            []
            [
              ("callback", PsVerifiedIrExpr.var "plusOne")
            ]
      },
      {
        name := "callStored"
        typeParameters := []
        parameters := [
          {
            name := "holder"
            type := PsVerifiedIrType.named "CallbackHolder" []
          },
          {
            name := "x"
            type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat
          }
        ]
        resultType := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat
        body :=
          PsVerifiedIrExpr.call
            (PsVerifiedIrExpr.projection
              "CallbackHolder"
              []
              (PsVerifiedIrExpr.var "holder")
              "callback")
            []
            [PsVerifiedIrExpr.var "x"]
      },
      {
        name := "storePlusOneBox"
        typeParameters := []
        parameters := []
        resultType := PsVerifiedIrType.named "CallbackBox" []
        body :=
          PsVerifiedIrExpr.constructor
            "CallbackBox"
            "stored"
            []
            [
              ("callback", PsVerifiedIrExpr.var "plusOne")
            ]
      },
      {
        name := "callStoredBox"
        typeParameters := []
        parameters := [
          {
            name := "box"
            type := PsVerifiedIrType.named "CallbackBox" []
          },
          {
            name := "x"
            type := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat
          }
        ]
        resultType := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat
        body :=
          PsVerifiedIrExpr.matchE
            "CallbackBox"
            []
            (PsVerifiedIrExpr.var "box")
            [
              (
                "stored",
                (
                  [
                    {
                      field := "callback"
                      name := "callback"
                      type :=
                        PsVerifiedIrType.function
                          [PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat]
                          (PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat)
                    }
                  ],
                  PsVerifiedIrExpr.call
                    (PsVerifiedIrExpr.var "callback")
                    []
                    [PsVerifiedIrExpr.var "x"]
                )
              )
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
            []
            [
              ("left", PsVerifiedIrExpr.var "a"),
              ("right", PsVerifiedIrExpr.var "b")
            ]
      },
      {
        name := "pairLeft"
        typeParameters := []
        parameters := [
          {
            name := "pair"
            type := PsVerifiedIrType.named "Pair" []
          }
        ]
        resultType := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat
        body :=
          PsVerifiedIrExpr.projection
            "Pair"
            []
            (PsVerifiedIrExpr.var "pair")
            "left"
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
            []
            [
              PsVerifiedIrExpr.var "text",
              PsVerifiedIrExpr.intrinsic
                PsVerifiedIrIntrinsic.charOfNat
                []
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
            []
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
            []
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
            []
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
            []
            [
              PsVerifiedIrExpr.var "arrayKeepLeft",
              PsVerifiedIrExpr.literal (PsVerifiedIrLiteral.natural 0),
              PsVerifiedIrExpr.var "xs",
              PsVerifiedIrExpr.literal (PsVerifiedIrLiteral.natural 0),
              PsVerifiedIrExpr.intrinsic
                PsVerifiedIrIntrinsic.arraySize
                []
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
            (PsVerifiedIrType.named
              "Array"
              [PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat])
            (PsVerifiedIrExpr.intrinsic
              PsVerifiedIrIntrinsic.arrayPush
              []
              [
                PsVerifiedIrExpr.intrinsic
                  PsVerifiedIrIntrinsic.arrayPush
                  []
                  [
                    PsVerifiedIrExpr.intrinsic
                      PsVerifiedIrIntrinsic.arrayEmptyWithCapacity
                      []
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
                []
                [
                  PsVerifiedIrExpr.var "xs",
                  PsVerifiedIrExpr.literal
                    (PsVerifiedIrLiteral.natural 0),
                  PsVerifiedIrExpr.literal
                    (PsVerifiedIrLiteral.natural 10)
                ])
              (PsVerifiedIrExpr.intrinsic
                PsVerifiedIrIntrinsic.arrayGetD
                []
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
            [PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat]
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
