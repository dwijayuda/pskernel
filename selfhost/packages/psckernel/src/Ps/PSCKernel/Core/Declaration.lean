import Ps.PSCKernel.Core.Expr

inductive PsCKernelReducibilityHints where
  | opaqueHint
  | abbreviation
  | regular (height : Nat)

inductive PsCKernelDefinitionSafety where
  | unsafeDef
  | safe
  | partial

structure PsCKernelConstantVal where
  name : PsCKernelName
  levelParams : List PsCKernelName
  declType : PsCKernelExpr

structure PsCKernelAxiomVal where
  base : PsCKernelConstantVal
  isUnsafe : Bool

structure PsCKernelDefinitionVal where
  base : PsCKernelConstantVal
  value : PsCKernelExpr
  hints : PsCKernelReducibilityHints
  safety : PsCKernelDefinitionSafety
  all : List PsCKernelName

structure PsCKernelTheoremVal where
  base : PsCKernelConstantVal
  value : PsCKernelExpr
  all : List PsCKernelName

structure PsCKernelOpaqueVal where
  base : PsCKernelConstantVal
  value : PsCKernelExpr
  isUnsafe : Bool
  all : List PsCKernelName

structure PsCKernelInductiveVal where
  base : PsCKernelConstantVal
  numParams : Nat
  numIndices : Nat
  all : List PsCKernelName
  ctors : List PsCKernelName
  numNested : Nat
  isRec : Bool
  isUnsafe : Bool
  isReflexive : Bool

structure PsCKernelConstructorVal where
  base : PsCKernelConstantVal
  induct : PsCKernelName
  cidx : Nat
  numParams : Nat
  numFields : Nat
  isUnsafe : Bool

structure PsCKernelRecursorRule where
  ctor : PsCKernelName
  nfields : Nat
  rhs : PsCKernelExpr

structure PsCKernelRecursorVal where
  base : PsCKernelConstantVal
  all : List PsCKernelName
  numParams : Nat
  numIndices : Nat
  numMotives : Nat
  numMinors : Nat
  rules : List PsCKernelRecursorRule
  k : Bool
  isUnsafe : Bool

inductive PsCKernelQuotKind where
  | type
  | ctor
  | lift
  | ind

structure PsCKernelQuotVal where
  base : PsCKernelConstantVal
  kind : PsCKernelQuotKind

inductive PsCKernelConstantInfo where
  | axiomInfo (value : PsCKernelAxiomVal)
  | defnInfo (value : PsCKernelDefinitionVal)
  | thmInfo (value : PsCKernelTheoremVal)
  | opaqueInfo (value : PsCKernelOpaqueVal)
  | quotInfo (value : PsCKernelQuotVal)
  | inductInfo (value : PsCKernelInductiveVal)
  | ctorInfo (value : PsCKernelConstructorVal)
  | recInfo (value : PsCKernelRecursorVal)

def psCKernelReducibilityHintsEq
    (left : PsCKernelReducibilityHints)
    (right : PsCKernelReducibilityHints) : Bool :=
  match left, right with
  | PsCKernelReducibilityHints.opaqueHint, PsCKernelReducibilityHints.opaqueHint => true
  | PsCKernelReducibilityHints.abbreviation, PsCKernelReducibilityHints.abbreviation => true
  | PsCKernelReducibilityHints.regular leftHeight,
      PsCKernelReducibilityHints.regular rightHeight =>
      Nat.beq leftHeight rightHeight
  | _, _ => false

def psCKernelReducibilityHintsLt
    (left : PsCKernelReducibilityHints)
    (right : PsCKernelReducibilityHints) : Bool :=
  match left, right with
  | PsCKernelReducibilityHints.abbreviation, PsCKernelReducibilityHints.abbreviation => false
  | PsCKernelReducibilityHints.abbreviation, _ => true
  | PsCKernelReducibilityHints.regular leftHeight,
      PsCKernelReducibilityHints.regular rightHeight =>
      Nat.blt rightHeight leftHeight
  | PsCKernelReducibilityHints.regular _, PsCKernelReducibilityHints.opaqueHint => true
  | _, _ => false

def psCKernelReducibilityHintsIsAbbrev
    (hints : PsCKernelReducibilityHints) : Bool :=
  match hints with
  | PsCKernelReducibilityHints.abbreviation => true
  | _ => false

def psCKernelReducibilityHintsIsRegular
    (hints : PsCKernelReducibilityHints) : Bool :=
  match hints with
  | PsCKernelReducibilityHints.regular _ => true
  | _ => false

def psCKernelDefinitionSafetyEq
    (left : PsCKernelDefinitionSafety)
    (right : PsCKernelDefinitionSafety) : Bool :=
  match left, right with
  | PsCKernelDefinitionSafety.unsafeDef, PsCKernelDefinitionSafety.unsafeDef => true
  | PsCKernelDefinitionSafety.safe, PsCKernelDefinitionSafety.safe => true
  | PsCKernelDefinitionSafety.partial, PsCKernelDefinitionSafety.partial => true
  | _, _ => false

def psCKernelConstantInfoBase (info : PsCKernelConstantInfo) : PsCKernelConstantVal :=
  match info with
  | PsCKernelConstantInfo.axiomInfo value => value.base
  | PsCKernelConstantInfo.defnInfo value => value.base
  | PsCKernelConstantInfo.thmInfo value => value.base
  | PsCKernelConstantInfo.opaqueInfo value => value.base
  | PsCKernelConstantInfo.quotInfo value => value.base
  | PsCKernelConstantInfo.inductInfo value => value.base
  | PsCKernelConstantInfo.ctorInfo value => value.base
  | PsCKernelConstantInfo.recInfo value => value.base

def psCKernelConstantInfoName (info : PsCKernelConstantInfo) : PsCKernelName :=
  (psCKernelConstantInfoBase info).name

def psCKernelConstantInfoLevelParams
    (info : PsCKernelConstantInfo) : List PsCKernelName :=
  (psCKernelConstantInfoBase info).levelParams

def psCKernelConstantInfoNumLevelParams (info : PsCKernelConstantInfo) : Nat :=
  (psCKernelConstantInfoLevelParams info).length

def psCKernelConstantInfoType (info : PsCKernelConstantInfo) : PsCKernelExpr :=
  (psCKernelConstantInfoBase info).declType

def psCKernelConstantInfoIsUnsafe (info : PsCKernelConstantInfo) : Bool :=
  match info with
  | PsCKernelConstantInfo.defnInfo value =>
      psCKernelDefinitionSafetyEq value.safety PsCKernelDefinitionSafety.unsafeDef
  | PsCKernelConstantInfo.axiomInfo value => value.isUnsafe
  | PsCKernelConstantInfo.thmInfo _ => false
  | PsCKernelConstantInfo.opaqueInfo value => value.isUnsafe
  | PsCKernelConstantInfo.quotInfo _ => false
  | PsCKernelConstantInfo.inductInfo value => value.isUnsafe
  | PsCKernelConstantInfo.ctorInfo value => value.isUnsafe
  | PsCKernelConstantInfo.recInfo value => value.isUnsafe

def psCKernelConstantInfoIsPartial (info : PsCKernelConstantInfo) : Bool :=
  match info with
  | PsCKernelConstantInfo.defnInfo value =>
      psCKernelDefinitionSafetyEq value.safety PsCKernelDefinitionSafety.partial
  | _ => false

def psCKernelConstantInfoValue?
    (info : PsCKernelConstantInfo)
    (allowOpaque : Bool := false) : Option PsCKernelExpr :=
  match info with
  | PsCKernelConstantInfo.defnInfo value => some value.value
  | PsCKernelConstantInfo.thmInfo value =>
      if allowOpaque then some value.value else none
  | PsCKernelConstantInfo.opaqueInfo value =>
      if allowOpaque then some value.value else none
  | _ => none

def psCKernelConstantInfoHasValue
    (info : PsCKernelConstantInfo)
    (allowOpaque : Bool := false) : Bool :=
  match info with
  | PsCKernelConstantInfo.defnInfo _ => true
  | PsCKernelConstantInfo.thmInfo _ => allowOpaque
  | PsCKernelConstantInfo.opaqueInfo _ => allowOpaque
  | _ => false

def psCKernelConstantInfoHints
    (info : PsCKernelConstantInfo) : PsCKernelReducibilityHints :=
  match info with
  | PsCKernelConstantInfo.defnInfo value => value.hints
  | _ => PsCKernelReducibilityHints.opaqueHint

def psCKernelConstantInfoIsCtor (info : PsCKernelConstantInfo) : Bool :=
  match info with
  | PsCKernelConstantInfo.ctorInfo _ => true
  | _ => false

def psCKernelConstantInfoIsAxiom (info : PsCKernelConstantInfo) : Bool :=
  match info with
  | PsCKernelConstantInfo.axiomInfo _ => true
  | _ => false

def psCKernelConstantInfoIsInductive (info : PsCKernelConstantInfo) : Bool :=
  match info with
  | PsCKernelConstantInfo.inductInfo _ => true
  | _ => false

def psCKernelConstantInfoIsDefinition (info : PsCKernelConstantInfo) : Bool :=
  match info with
  | PsCKernelConstantInfo.defnInfo _ => true
  | _ => false

def psCKernelConstantInfoIsTheorem (info : PsCKernelConstantInfo) : Bool :=
  match info with
  | PsCKernelConstantInfo.thmInfo _ => true
  | _ => false

def psCKernelConstantInfoIsQuot (info : PsCKernelConstantInfo) : Bool :=
  match info with
  | PsCKernelConstantInfo.quotInfo _ => true
  | _ => false

def psCKernelConstantInfoAll (info : PsCKernelConstantInfo) : List PsCKernelName :=
  match info with
  | PsCKernelConstantInfo.inductInfo value => value.all
  | PsCKernelConstantInfo.defnInfo value => value.all
  | PsCKernelConstantInfo.thmInfo value => value.all
  | PsCKernelConstantInfo.opaqueInfo value => value.all
  | _ => [psCKernelConstantInfoName info]

def psCKernelInductiveValNumCtors (value : PsCKernelInductiveVal) : Nat :=
  value.ctors.length

def psCKernelInductiveValIsNested (value : PsCKernelInductiveVal) : Bool :=
  Nat.blt 0 value.numNested

def psCKernelInductiveValNumTypeFormers (value : PsCKernelInductiveVal) : Nat :=
  Nat.add value.all.length value.numNested

def psCKernelRecursorValGetMajorIdx (value : PsCKernelRecursorVal) : Nat :=
  Nat.add
    (Nat.add (Nat.add value.numParams value.numMotives) value.numMinors)
    value.numIndices

def psCKernelRecursorValGetFirstIndexIdx (value : PsCKernelRecursorVal) : Nat :=
  Nat.add (Nat.add value.numParams value.numMotives) value.numMinors

def psCKernelRecursorValGetFirstMinorIdx (value : PsCKernelRecursorVal) : Nat :=
  Nat.add value.numParams value.numMotives
