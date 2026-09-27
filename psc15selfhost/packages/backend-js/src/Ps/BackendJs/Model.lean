inductive PsJsError where
  | unsupportedModule
  | unsupportedDeclaration (name : String)
  | unsupportedExpression
  | literalTypeMismatch
  | invalidExportName (name : String)
  | duplicateExport (name : String)

inductive PsJsLiteral where
  | natural (value : Nat)
  | integer (value : Int)
  | boolean (value : Bool)
  | string (value : String)
  | undefined

inductive PsJsExpr where
  | literal (value : PsJsLiteral)
  | local (index : Nat)
  | letE (index : Nat) (value : PsJsExpr) (body : PsJsExpr)

structure PsJsConstant where
  exportName : String
  body : PsJsExpr

structure PsJsModule where
  constants : List PsJsConstant
