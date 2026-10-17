import Ps.Core.Expr

structure PsInductiveInfo where
  name : PsName
  levelParams : List PsName
  type : PsExpr
  numParams : Nat
  numIndices : Nat
  constructors : List PsName
  isStructure : Bool

structure PsConstructorInfo where
  name : PsName
  levelParams : List PsName
  type : PsExpr
  inductiveName : PsName
  constructorIndex : Nat
  numParams : Nat
  numFields : Nat
  recursiveFields : List Nat

structure PsRecursorInfo where
  name : PsName
  levelParams : List PsName
  type : PsExpr
  inductiveNames : List PsName
  numParams : Nat
  numIndices : Nat
  numMotives : Nat
  numMinors : Nat

-- Kernel-generated quotient constants are distinct from axioms and inductives.
-- Their signatures are regenerated and checked by the official Lean provider.
inductive PsQuotientKind where
  | type
  | ctor
  | lift
  | ind

def psQuotientKindTag : PsQuotientKind → String
  | .type => "type"
  | .ctor => "ctor"
  | .lift => "lift"
  | .ind => "ind"

def psQuotientKindName : PsQuotientKind → PsName
  | .type => .str .anonymous "Quot"
  | .ctor => .str (.str .anonymous "Quot") "mk"
  | .lift => .str (.str .anonymous "Quot") "lift"
  | .ind => .str (.str .anonymous "Quot") "ind"

inductive PsDeclaration where
  | quotientDecl
      (name : PsName)
      (levelParams : List PsName)
      (type : PsExpr)
      (kind : PsQuotientKind)
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
