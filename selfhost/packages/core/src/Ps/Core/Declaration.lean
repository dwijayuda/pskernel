import Ps.Core.Expr

inductive PsDeclaration where
  | axiom
      (name : PsName)
      (levelParams : List PsName)
      (type : PsExpr)
  | definition
      (name : PsName)
      (levelParams : List PsName)
      (type : PsExpr)
      (value : PsExpr)
  | theorem
      (name : PsName)
      (levelParams : List PsName)
      (type : PsExpr)
      (value : PsExpr)
  | opaqueDef
      (name : PsName)
      (levelParams : List PsName)
      (type : PsExpr)
      (value : PsExpr)
