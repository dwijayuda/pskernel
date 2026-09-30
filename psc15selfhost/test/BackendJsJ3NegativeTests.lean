import Ps.BackendJs.Module


def jsJ3NegativeDecl
    (resultType : PsVerifiedIrPrimitiveType)
    (body : PsVerifiedIrExpr) : PsVerifiedIrDeclaration :=
  {
    name := "bad",
    typeParameters := [],
    parameters := [],
    resultType := .primitive resultType,
    body := body
  }


def jsJ3Rejects
    (resultType : PsVerifiedIrPrimitiveType)
    (body : PsVerifiedIrExpr) : Bool :=
  let module : PsVerifiedIrModule :=
    { psVerifiedIrModuleEmpty with
      declarations := [jsJ3NegativeDecl resultType body] };
  match psJsEmitModule module with
  | Except.error _error => true
  | Except.ok _source => false


def psBackendJsJ3RejectsWrongArity : Bool :=
  jsJ3Rejects
    PsVerifiedIrPrimitiveType.nat
    (PsVerifiedIrExpr.intrinsic
      PsVerifiedIrIntrinsic.natAdd
      []
      [PsVerifiedIrExpr.literal (PsVerifiedIrLiteral.natural 1)])


def psBackendJsJ3RejectsWrongArgumentType : Bool :=
  jsJ3Rejects
    PsVerifiedIrPrimitiveType.nat
    (PsVerifiedIrExpr.intrinsic
      PsVerifiedIrIntrinsic.natAdd
      []
      [ PsVerifiedIrExpr.literal (PsVerifiedIrLiteral.natural 1),
        PsVerifiedIrExpr.literal (PsVerifiedIrLiteral.bool true) ])


def psBackendJsJ3RejectsWrongResultType : Bool :=
  jsJ3Rejects
    PsVerifiedIrPrimitiveType.bool
    (PsVerifiedIrExpr.intrinsic
      PsVerifiedIrIntrinsic.natAdd
      []
      [ PsVerifiedIrExpr.literal (PsVerifiedIrLiteral.natural 1),
        PsVerifiedIrExpr.literal (PsVerifiedIrLiteral.natural 2) ])


def psBackendJsJ3RejectsTypeArguments : Bool :=
  jsJ3Rejects
    PsVerifiedIrPrimitiveType.nat
    (PsVerifiedIrExpr.intrinsic
      PsVerifiedIrIntrinsic.natAdd
      [PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat]
      [ PsVerifiedIrExpr.literal (PsVerifiedIrLiteral.natural 1),
        PsVerifiedIrExpr.literal (PsVerifiedIrLiteral.natural 2) ])


def psBackendJsJ3RejectsWrongUnaryArgumentType : Bool :=
  jsJ3Rejects
    PsVerifiedIrPrimitiveType.int
    (PsVerifiedIrExpr.intrinsic
      PsVerifiedIrIntrinsic.intOfNat
      []
      [PsVerifiedIrExpr.literal (PsVerifiedIrLiteral.integer 1)])


#guard psBackendJsJ3RejectsWrongArity
#guard psBackendJsJ3RejectsWrongArgumentType
#guard psBackendJsJ3RejectsWrongResultType
#guard psBackendJsJ3RejectsTypeArguments
#guard psBackendJsJ3RejectsWrongUnaryArgumentType
