from pathlib import Path

path = Path("selfhost/test/WasmBinarySmoke.lean")
text = path.read_text()

if 'name := "natAddCarrySmallExact"' in text:
    raise SystemExit(0)

marker = '''      {
        name := "natAddLargeExact"'''

insertion = '''      {
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
                (PsVerifiedIrLiteral.natural 42),
              PsVerifiedIrExpr.literal
                (PsVerifiedIrLiteral.natural 42)
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
        name := "natAddLargeExact"'''

if marker not in text:
    raise SystemExit("live Nat smoke insertion marker not found")

path.write_text(text.replace(marker, insertion, 1))
