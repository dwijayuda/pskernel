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
