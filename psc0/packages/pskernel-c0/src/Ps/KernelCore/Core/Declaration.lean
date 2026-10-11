import Ps.KernelCore.Core.Expr

inductive PsKernelDefinitionSafety where
  | unsafeDef
  | safe
  | partialDef

def psKernelDefinitionSafetyIsUnsafe
    (value : PsKernelDefinitionSafety) : Bool :=
  match value with
  | PsKernelDefinitionSafety.unsafeDef => true
  | PsKernelDefinitionSafety.safe => false
  | PsKernelDefinitionSafety.partialDef => false

def psKernelDefinitionSafetyIsSafe
    (value : PsKernelDefinitionSafety) : Bool :=
  match value with
  | PsKernelDefinitionSafety.safe => true
  | PsKernelDefinitionSafety.unsafeDef => false
  | PsKernelDefinitionSafety.partialDef => false

inductive PsKernelReducibilityHints where
  | opaqueHint
  | abbrevHint
  | regular (height : Nat)

def psKernelReducibilityHintsLt
    (left : PsKernelReducibilityHints)
    (right : PsKernelReducibilityHints) : Bool :=
  match left with
  | PsKernelReducibilityHints.abbrevHint =>
      match right with
      | PsKernelReducibilityHints.abbrevHint => false
      | _ => true
  | PsKernelReducibilityHints.regular leftHeight =>
      match right with
      | PsKernelReducibilityHints.regular rightHeight =>
          psKernelNatGt leftHeight rightHeight
      | PsKernelReducibilityHints.opaqueHint => true
      | PsKernelReducibilityHints.abbrevHint => false
  | PsKernelReducibilityHints.opaqueHint =>
      false

def psKernelReducibilityHintsIsRegular
    (value : PsKernelReducibilityHints) : Bool :=
  match value with
  | PsKernelReducibilityHints.regular _ => true
  | _ => false

structure PsKernelConstantBase where
  name : PsKernelName
  levelParams : List PsKernelName
  type : PsKernelExpr

structure PsKernelAxiomInfo where
  base : PsKernelConstantBase
  isUnsafe : Bool

structure PsKernelDefinitionInfo where
  base : PsKernelConstantBase
  value : PsKernelExpr
  hints : PsKernelReducibilityHints
  safety : PsKernelDefinitionSafety

structure PsKernelTheoremInfo where
  base : PsKernelConstantBase
  value : PsKernelExpr

structure PsKernelOpaqueInfo where
  base : PsKernelConstantBase
  value : PsKernelExpr
  isUnsafe : Bool

structure PsKernelInductiveInfo where
  base : PsKernelConstantBase
  numParams : Nat
  numIndices : Nat
  all : List PsKernelName
  ctors : List PsKernelName
  numNested : Nat
  isRec : Bool
  isReflexive : Bool
  isUnsafe : Bool

structure PsKernelConstructorInfo where
  base : PsKernelConstantBase
  induct : PsKernelName
  cidx : Nat
  numParams : Nat
  numFields : Nat
  isUnsafe : Bool

structure PsKernelRecursorRule where
  ctor : PsKernelName
  nFields : Nat
  rhs : PsKernelExpr

structure PsKernelRecursorInfo where
  base : PsKernelConstantBase
  all : List PsKernelName
  numParams : Nat
  numIndices : Nat
  numMotives : Nat
  numMinors : Nat
  rules : List PsKernelRecursorRule
  k : Bool
  isUnsafe : Bool

inductive PsKernelQuotKind where
  | typeQ
  | ctorQ
  | liftQ
  | indQ

structure PsKernelQuotInfo where
  base : PsKernelConstantBase
  kind : PsKernelQuotKind

inductive PsKernelConstantInfo where
  | axiomInfo (value : PsKernelAxiomInfo)
  | defnInfo (value : PsKernelDefinitionInfo)
  | thmInfo (value : PsKernelTheoremInfo)
  | opaqueInfo (value : PsKernelOpaqueInfo)
  | inductInfo (value : PsKernelInductiveInfo)
  | ctorInfo (value : PsKernelConstructorInfo)
  | recInfo (value : PsKernelRecursorInfo)
  | quotInfo (value : PsKernelQuotInfo)

def psKernelConstantInfoBase
    (info : PsKernelConstantInfo) :
    PsKernelConstantBase :=
  match info with
  | PsKernelConstantInfo.axiomInfo value => value.base
  | PsKernelConstantInfo.defnInfo value => value.base
  | PsKernelConstantInfo.thmInfo value => value.base
  | PsKernelConstantInfo.opaqueInfo value => value.base
  | PsKernelConstantInfo.inductInfo value => value.base
  | PsKernelConstantInfo.ctorInfo value => value.base
  | PsKernelConstantInfo.recInfo value => value.base
  | PsKernelConstantInfo.quotInfo value => value.base

def psKernelConstantInfoName
    (info : PsKernelConstantInfo) : PsKernelName :=
  let base := psKernelConstantInfoBase info;
  base.name

def psKernelConstantInfoLevelParams
    (info : PsKernelConstantInfo) :
    List PsKernelName :=
  let base := psKernelConstantInfoBase info;
  base.levelParams

def psKernelConstantInfoType
    (info : PsKernelConstantInfo) : PsKernelExpr :=
  let base := psKernelConstantInfoBase info;
  base.type

def psKernelConstantInfoDeltaValue
    (info : PsKernelConstantInfo) :
    Option PsKernelExpr :=
  match info with
  | PsKernelConstantInfo.defnInfo value =>
      Option.some value.value
  | _ =>
      Option.none

def psKernelConstantInfoHints
    (info : PsKernelConstantInfo) :
    Option PsKernelReducibilityHints :=
  match info with
  | PsKernelConstantInfo.defnInfo value =>
      Option.some value.hints
  | _ =>
      Option.none

def psKernelConstantInfoIsUnsafe
    (info : PsKernelConstantInfo) : Bool :=
  match info with
  | PsKernelConstantInfo.axiomInfo value =>
      value.isUnsafe
  | PsKernelConstantInfo.defnInfo value =>
      psKernelDefinitionSafetyIsUnsafe value.safety
  | PsKernelConstantInfo.opaqueInfo value =>
      value.isUnsafe
  | PsKernelConstantInfo.inductInfo value =>
      value.isUnsafe
  | PsKernelConstantInfo.ctorInfo value =>
      value.isUnsafe
  | PsKernelConstantInfo.recInfo value =>
      value.isUnsafe
  | PsKernelConstantInfo.thmInfo _ =>
      false
  | PsKernelConstantInfo.quotInfo _ =>
      false

def psKernelConstantInfoIsPartial
    (info : PsKernelConstantInfo) : Bool :=
  match info with
  | PsKernelConstantInfo.defnInfo value =>
      match value.safety with
      | PsKernelDefinitionSafety.partialDef => true
      | PsKernelDefinitionSafety.unsafeDef => false
      | PsKernelDefinitionSafety.safe => false
  | _ =>
      false

def psKernelConstantInfoIsDefinition
    (info : PsKernelConstantInfo) : Bool :=
  match info with
  | PsKernelConstantInfo.defnInfo _ => true
  | _ => false

def psKernelConstantInfoDefinition
    (info : PsKernelConstantInfo) :
    Option PsKernelDefinitionInfo :=
  match info with
  | PsKernelConstantInfo.defnInfo value =>
      Option.some value
  | _ =>
      Option.none
