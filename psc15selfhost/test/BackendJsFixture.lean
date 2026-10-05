import Ps.CompilerIr.Model

def psBackendJsFixtureModule : PsVerifiedIrModule :=
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

def psBackendJsFixtureValidated :
    Except String PsValidatedIrModule :=
  match
      psValidateErasedIrModule
        (PsErasedIrModule.mk
          psBackendJsFixtureModule) with
  | Except.error _ =>
      Except.error "VALIDATION"
  | Except.ok validated =>
      Except.ok validated
