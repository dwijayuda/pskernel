import Ps.BackendRust.Module

def psBackendRustLetFunctionResultFixture : PsVerifiedIrModule :=
  {
    imports := []
    structures := []
    inductives := []
    declarations := [
      {
        name := "makeAdderViaLet"
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
          PsVerifiedIrExpr.letE
            "delta"
            (PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat)
            (PsVerifiedIrExpr.var "offset")
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
                [
                  PsVerifiedIrExpr.var "value",
                  PsVerifiedIrExpr.var "delta"
                ]))
      },
      {
        name := "forwardCallbackViaLet"
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
        body :=
          PsVerifiedIrExpr.letE
            "forwarded"
            (PsVerifiedIrType.function
              [PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat]
              (PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat))
            (PsVerifiedIrExpr.var "callback")
            (PsVerifiedIrExpr.var "forwarded")
      }
    ]
  }

def main : IO Unit := do
  match psRustEmitModule psBackendRustLetFunctionResultFixture with
  | Except.error _ =>
      throw (IO.userError "PSC1_BACKEND_RUST_LET_FUNCTION_RESULT_FIXTURE: emission failed")
  | Except.ok output =>
      IO.print output
