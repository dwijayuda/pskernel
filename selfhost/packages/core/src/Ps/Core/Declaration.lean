import Ps.Core.Expr

structure PsInductiveInfo where
  name : PsName
  levelParams : List PsName
  type : PsExpr
  numParams : Nat
  numIndices : Nat
  constructors : List PsName
  isStructure : Bool := false

structure PsConstructorInfo where
  name : PsName
  levelParams : List PsName
  type : PsExpr
  inductiveName : PsName
  constructorIndex : Nat
  numParams : Nat
  numFields : Nat
  recursiveFields : List Nat := []

structure PsRecursorInfo where
  name : PsName
  levelParams : List PsName
  type : PsExpr
  inductiveNames : List PsName
  numParams : Nat
  numIndices : Nat
  numMotives : Nat
  numMinors : Nat

inductive PsDeclaration where
  | axiomDecl
      (name : PsName)
      (levelParams : List PsName)
      (type : PsExpr)
  | definitionDecl
      (name : PsName)
      (levelParams : List PsName)
      (type : PsExpr)
      (value : PsExpr)
  | theoremDecl
      (name : PsName)
      (levelParams : List PsName)
      (type : PsExpr)
      (value : PsExpr)
  | partialDecl
      (name : PsName)
      (levelParams : List PsName)
      (type : PsExpr)
      (value : PsExpr)
  | opaqueDecl
      (name : PsName)
      (levelParams : List PsName)
      (type : PsExpr)
      (value : PsExpr)
  | inductiveDecl
      (info : PsInductiveInfo)
  | constructorDecl
      (info : PsConstructorInfo)
  | recursorDecl
      (info : PsRecursorInfo)
