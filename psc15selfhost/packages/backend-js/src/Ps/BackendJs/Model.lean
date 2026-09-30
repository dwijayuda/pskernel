inductive PsJsError where
  | unsupportedModule
  | unsupportedDeclaration (name : String)
  | unsupportedExpression
  | literalTypeMismatch
  | invalidExportName (name : String)
  | duplicateExport (name : String)
  | fuelExhausted

inductive PsJsLiteral where
  | natural (value : Nat)
  | integer (value : Int)
  | machineNumber (value : Int)
  | machineBigInt (value : Int)
  | boolean (value : Bool)
  | string (value : String)
  | undefined

inductive PsJsIntrinsic where
  | natAdd
  | natSub
  | natMul
  | natDiv
  | natMod
  | natEq
  | natNe
  | natLe
  | natLt
  | intOfNat
  | intNegSucc
  | intNeg
  | intAdd
  | intSub
  | intMul
  | intEq
  | intLe
  | intLt
  | intRepr
  | boolNot
  | boolAnd
  | boolOr
  | boolEq
  | boolNe

inductive PsJsExpr where
  | literal (value : PsJsLiteral)
  | local (index : Nat)
  | global (index : Nat)
  | intrinsic (operation : PsJsIntrinsic) (arguments : List PsJsExpr)
  | letE (index : Nat) (value : PsJsExpr) (body : PsJsExpr)
  | lambda (parameters : List Nat) (body : PsJsExpr)
  | call (fn : PsJsExpr) (arguments : List PsJsExpr)
  | ifE (condition : PsJsExpr) (thenBranch : PsJsExpr) (elseBranch : PsJsExpr)

structure PsJsConstant where
  exportName : String
  body : PsJsExpr

structure PsJsModule where
  constants : List PsJsConstant
