import PSC1Kernel.Expr

namespace PSC1Kernel

inductive DefinitionSafety where
  | unsafeDef
  | safe
  | partialDef

def DefinitionSafety.isUnsafe : DefinitionSafety → Bool
  | .unsafeDef => true
  | .safe | .partialDef => false

def DefinitionSafety.isSafe : DefinitionSafety → Bool
  | .safe => true
  | .unsafeDef | .partialDef => false

inductive ReducibilityHints where
  | opaqueHint
  | abbrevHint
  | regular (height : Nat)

structure ConstantBase where
  name : Name
  levelParams : List Name
  type : Expr

structure AxiomInfo where
  base : ConstantBase
  isUnsafe : Bool

structure DefinitionInfo where
  base : ConstantBase
  value : Expr
  hints : ReducibilityHints
  safety : DefinitionSafety

structure TheoremInfo where
  base : ConstantBase
  value : Expr

structure OpaqueInfo where
  base : ConstantBase
  value : Expr
  isUnsafe : Bool

structure InductiveInfo where
  base : ConstantBase
  numParams : Nat
  numIndices : Nat
  all : List Name
  ctors : List Name
  numNested : Nat
  isRec : Bool
  isReflexive : Bool
  isUnsafe : Bool

structure ConstructorInfo where
  base : ConstantBase
  induct : Name
  cidx : Nat
  numParams : Nat
  numFields : Nat
  isUnsafe : Bool

structure RecursorRule where
  ctor : Name
  nFields : Nat
  rhs : Expr

structure RecursorInfo where
  base : ConstantBase
  all : List Name
  numParams : Nat
  numIndices : Nat
  numMotives : Nat
  numMinors : Nat
  rules : List RecursorRule
  k : Bool
  isUnsafe : Bool

inductive QuotKind where
  | typeQ
  | ctorQ
  | liftQ
  | indQ

structure QuotInfo where
  base : ConstantBase
  kind : QuotKind

inductive ConstantInfo where
  | axiomInfo (value : AxiomInfo)
  | defnInfo (value : DefinitionInfo)
  | thmInfo (value : TheoremInfo)
  | opaqueInfo (value : OpaqueInfo)
  | inductInfo (value : InductiveInfo)
  | ctorInfo (value : ConstructorInfo)
  | recInfo (value : RecursorInfo)
  | quotInfo (value : QuotInfo)

def ConstantInfo.base : ConstantInfo → ConstantBase
  | .axiomInfo v => v.base
  | .defnInfo v => v.base
  | .thmInfo v => v.base
  | .opaqueInfo v => v.base
  | .inductInfo v => v.base
  | .ctorInfo v => v.base
  | .recInfo v => v.base
  | .quotInfo v => v.base

def ConstantInfo.name (info : ConstantInfo) : Name :=
  info.base.name

def ConstantInfo.levelParams (info : ConstantInfo) : List Name :=
  info.base.levelParams

def ConstantInfo.type (info : ConstantInfo) : Expr :=
  info.base.type

def ConstantInfo.deltaValue? : ConstantInfo → Option Expr
  | .defnInfo value => some value.value
  | _ => none

def ConstantInfo.hints? : ConstantInfo → Option ReducibilityHints
  | .defnInfo value => some value.hints
  | _ => none

def ConstantInfo.isUnsafe : ConstantInfo → Bool
  | .axiomInfo value => value.isUnsafe
  | .defnInfo value =>
    match value.safety with
    | .unsafeDef => true
    | .safe | .partialDef => false
  | .opaqueInfo value => value.isUnsafe
  | .inductInfo value => value.isUnsafe
  | .ctorInfo value => value.isUnsafe
  | .recInfo value => value.isUnsafe
  | .thmInfo _ | .quotInfo _ => false

def ConstantInfo.isPartial : ConstantInfo → Bool
  | .defnInfo value =>
    match value.safety with
    | .partialDef => true
    | .unsafeDef | .safe => false
  | _ => false

def ConstantInfo.isDefinition : ConstantInfo → Bool
  | .defnInfo _ => true
  | _ => false

def ConstantInfo.definition? : ConstantInfo → Option DefinitionInfo
  | .defnInfo value => some value
  | _ => none

end PSC1Kernel
