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
