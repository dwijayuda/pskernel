import Ps.CompilerIr.Model

inductive PsJsIrLiteral where
  | natural (value : Nat)
  | integer (value : Int)
  | string (value : String)
  | bool (value : Bool)
  | unit

inductive PsJsIrBinaryOp where
  | bigintAdd

inductive PsJsIrExpr where
  | literal (value : PsJsIrLiteral)
  | var (name : String)
  | binary
      (operation : PsJsIrBinaryOp)
      (left right : PsJsIrExpr)
  | call
      (fn : PsJsIrExpr)
      (arguments : List PsJsIrExpr)
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
