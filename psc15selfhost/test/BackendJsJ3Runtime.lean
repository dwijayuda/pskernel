import Ps.BackendJs.Module


def jsJ3RuntimeDecl
    (name : String)
    (resultType : PsVerifiedIrPrimitiveType)
    (body : PsVerifiedIrExpr) : PsVerifiedIrDeclaration :=
  {
    name := name,
    typeParameters := [],
    parameters := [],
    resultType := .primitive resultType,
    body := body
  }


def jsJ3NatValue (value : Nat) : PsVerifiedIrExpr :=
  PsVerifiedIrExpr.literal (PsVerifiedIrLiteral.natural value)


def jsJ3IntValue (value : Int) : PsVerifiedIrExpr :=
  PsVerifiedIrExpr.literal (PsVerifiedIrLiteral.integer value)


def jsJ3BoolValue (value : Bool) : PsVerifiedIrExpr :=
  PsVerifiedIrExpr.literal (PsVerifiedIrLiteral.bool value)


def jsJ3RuntimeModule : PsVerifiedIrModule :=
  { psVerifiedIrModuleEmpty with declarations := [
      jsJ3RuntimeDecl "natAdd" .nat
        (.intrinsic .natAdd [] [jsJ3NatValue 41, jsJ3NatValue 1]),
      jsJ3RuntimeDecl "natSub" .nat
        (.intrinsic .natSub [] [jsJ3NatValue 3, jsJ3NatValue 5]),
      jsJ3RuntimeDecl "natMul" .nat
        (.intrinsic .natMul [] [jsJ3NatValue 6, jsJ3NatValue 7]),
      jsJ3RuntimeDecl "natDiv" .nat
        (.intrinsic .natDiv [] [jsJ3NatValue 9, jsJ3NatValue 0]),
      jsJ3RuntimeDecl "natMod" .nat
        (.intrinsic .natMod [] [jsJ3NatValue 9, jsJ3NatValue 0]),
      jsJ3RuntimeDecl "natEq" .bool
        (.intrinsic .natEq [] [jsJ3NatValue 7, jsJ3NatValue 7]),
      jsJ3RuntimeDecl "natNe" .bool
        (.intrinsic .natNe [] [jsJ3NatValue 7, jsJ3NatValue 8]),
      jsJ3RuntimeDecl "natLe" .bool
        (.intrinsic .natLe [] [jsJ3NatValue 7, jsJ3NatValue 8]),
      jsJ3RuntimeDecl "natLt" .bool
        (.intrinsic .natLt [] [jsJ3NatValue 7, jsJ3NatValue 8]),
      jsJ3RuntimeDecl "intOfNat" .int
        (.intrinsic .intOfNat [] [jsJ3NatValue 41]),
      jsJ3RuntimeDecl "intNegSucc" .int
        (.intrinsic .intNegSucc [] [jsJ3NatValue 2]),
      jsJ3RuntimeDecl "intNeg" .int
        (.intrinsic .intNeg [] [jsJ3IntValue 7]),
      jsJ3RuntimeDecl "intAdd" .int
        (.intrinsic .intAdd [] [jsJ3IntValue (-2), jsJ3IntValue 5]),
      jsJ3RuntimeDecl "intSub" .int
        (.intrinsic .intSub [] [jsJ3IntValue 3, jsJ3IntValue 5]),
      jsJ3RuntimeDecl "intMul" .int
        (.intrinsic .intMul [] [jsJ3IntValue (-3), jsJ3IntValue 4]),
      jsJ3RuntimeDecl "intEq" .bool
        (.intrinsic .intEq [] [jsJ3IntValue (-7), jsJ3IntValue (-7)]),
      jsJ3RuntimeDecl "intLe" .bool
        (.intrinsic .intLe [] [jsJ3IntValue (-8), jsJ3IntValue 7]),
      jsJ3RuntimeDecl "intLt" .bool
        (.intrinsic .intLt [] [jsJ3IntValue (-8), jsJ3IntValue 7]),
      jsJ3RuntimeDecl "intRepr" .string
        (.intrinsic .intRepr [] [jsJ3IntValue (-42)]),
      jsJ3RuntimeDecl "boolNot" .bool
        (.intrinsic .boolNot [] [jsJ3BoolValue true]),
      jsJ3RuntimeDecl "boolAnd" .bool
        (.intrinsic .boolAnd [] [jsJ3BoolValue true, jsJ3BoolValue false]),
      jsJ3RuntimeDecl "boolOr" .bool
        (.intrinsic .boolOr [] [jsJ3BoolValue false, jsJ3BoolValue true]),
      jsJ3RuntimeDecl "boolEq" .bool
        (.intrinsic .boolEq [] [jsJ3BoolValue true, jsJ3BoolValue true]),
      jsJ3RuntimeDecl "boolNe" .bool
        (.intrinsic .boolNe [] [jsJ3BoolValue true, jsJ3BoolValue false])
    ] }


def main (args : List String) : IO Unit := do
  let out := args.head!;
  match psJsEmitModule jsJ3RuntimeModule with
  | Except.error _error => throw (IO.userError "J3 runtime emission failed")
  | Except.ok source => IO.FS.writeFile (out ++ "/j3.mjs") source
