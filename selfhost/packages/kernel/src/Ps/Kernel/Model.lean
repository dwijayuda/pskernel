import Ps.Core.Expr

inductive PsKernelDefinitionSafety where
  | safe
  | unsafeDef
  | partial

inductive PsKernelReducibilityHints where
  | opaqueHint
  | abbrevHint
  | regular (height : Nat)

structure PsKernelBaseInfo where
  name : PsName
  levelParams : List PsName
  type : PsExpr

structure PsKernelAxiomInfo where
  base : PsKernelBaseInfo
  isUnsafe : Bool

structure PsKernelDefinitionInfo where
  base : PsKernelBaseInfo
  value : PsExpr
  hints : PsKernelReducibilityHints
  safety : PsKernelDefinitionSafety

structure PsKernelTheoremInfo where
  base : PsKernelBaseInfo
  value : PsExpr

structure PsKernelOpaqueInfo where
  base : PsKernelBaseInfo
  value : PsExpr
  isUnsafe : Bool

structure PsKernelInductiveInfo where
  base : PsKernelBaseInfo
  numParams : Nat
  numIndices : Nat
  all : List PsName
  constructors : List PsName
  numNested : Nat
  isRec : Bool
  isReflexive : Bool
  isUnsafe : Bool

structure PsKernelConstructorInfo where
  base : PsKernelBaseInfo
  inductiveName : PsName
  constructorIndex : Nat
  numParams : Nat
  numFields : Nat
  isUnsafe : Bool

structure PsKernelRecursorRule where
  constructorName : PsName
  numFields : Nat
  rhs : PsExpr

structure PsKernelRecursorInfo where
  base : PsKernelBaseInfo
  all : List PsName
  numParams : Nat
  numIndices : Nat
  numMotives : Nat
  numMinors : Nat
  rules : List PsKernelRecursorRule
  k : Bool
  isUnsafe : Bool

inductive PsKernelQuotKind where
  | typeDecl
  | constructorDecl
  | liftDecl
  | indDecl

structure PsKernelQuotInfo where
  base : PsKernelBaseInfo
  kind : PsKernelQuotKind

inductive PsKernelConstantInfo where
  | axiomInfo (info : PsKernelAxiomInfo)
  | definitionInfo (info : PsKernelDefinitionInfo)
  | theoremInfo (info : PsKernelTheoremInfo)
  | opaqueInfo (info : PsKernelOpaqueInfo)
  | inductiveInfo (info : PsKernelInductiveInfo)
  | constructorInfo (info : PsKernelConstructorInfo)
  | recursorInfo (info : PsKernelRecursorInfo)
  | quotInfo (info : PsKernelQuotInfo)

def psKernelConstantBase : PsKernelConstantInfo -> PsKernelBaseInfo
  | .axiomInfo info => info.base
  | .definitionInfo info => info.base
  | .theoremInfo info => info.base
  | .opaqueInfo info => info.base
  | .inductiveInfo info => info.base
  | .constructorInfo info => info.base
  | .recursorInfo info => info.base
  | .quotInfo info => info.base

def psKernelConstantName (info : PsKernelConstantInfo) : PsName :=
  (psKernelConstantBase info).name

def psKernelConstantLevelParams (info : PsKernelConstantInfo) : List PsName :=
  (psKernelConstantBase info).levelParams

def psKernelConstantType (info : PsKernelConstantInfo) : PsExpr :=
  (psKernelConstantBase info).type

def psKernelConstantValue : PsKernelConstantInfo -> Option PsExpr
  | .definitionInfo info => some info.value
  | .theoremInfo info => some info.value
  | .opaqueInfo info => some info.value
  | _ => none

def psKernelDeltaValue : PsKernelConstantInfo -> Option PsExpr
  | .definitionInfo info => some info.value
  | _ => none
