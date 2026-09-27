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

structure PsJsConstant where
  exportName : String
  value : PsJsLiteral

structure PsJsModule where
  constants : List PsJsConstant
