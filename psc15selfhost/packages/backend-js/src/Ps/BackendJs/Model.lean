import Ps.CompilerIr.Model

inductive PsJsIrLiteral where
  | natural (value : Nat)
  | integer (value : Int)
  | string (value : String)
  | bool (value : Bool)
  | unit

inductive PsJsIrUnaryOp where
  | bigintNeg
  | boolNot

inductive PsJsIrBinaryOp where
  | bigintAdd
  | bigintSub
  | bigintMul
  | bigintEq
  | bigintNe
  | bigintLe
  | bigintLt
  | boolAnd
  | boolOr
  | boolEq
  | boolNe
  | stringConcat
  | stringEq

inductive PsJsIrRuntimeOp where
  | natSub
  | natDiv
  | natMod
  | intNegSucc
  | intRepr
  | charOfNat
  | charToNat
  | stringLength

inductive PsJsIrExpr where
  | literal (value : PsJsIrLiteral)
  | var (name : String)
  | unary
      (operation : PsJsIrUnaryOp)
      (value : PsJsIrExpr)
  | binary
      (operation : PsJsIrBinaryOp)
      (left right : PsJsIrExpr)
  | runtime
      (operation : PsJsIrRuntimeOp)
      (arguments : List PsJsIrExpr)
  | lambda
      (parameters : List String)
      (body : PsJsIrExpr)
  | call
      (fn : PsJsIrExpr)
      (arguments : List PsJsIrExpr)
  | letE
      (name : String)
      (value : PsJsIrExpr)
      (body : PsJsIrExpr)
  | ifE
      (condition : PsJsIrExpr)
      (thenBranch elseBranch : PsJsIrExpr)

structure PsJsIrParameter where
  name : String

structure PsJsIrDeclaration where
  name : String
  parameters : List PsJsIrParameter
  body : PsJsIrExpr

structure PsJsIrModule where
  declarations : List PsJsIrDeclaration
