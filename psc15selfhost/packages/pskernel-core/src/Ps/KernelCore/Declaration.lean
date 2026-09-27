import Ps.KernelCore.Expr

inductive PsKernelCoreDefinitionSafety where
  | unsafeDef
  | safe
  | partialDef

def psKernelCoreDefinitionSafetyIsUnsafe
    (value : PsKernelCoreDefinitionSafety) : Bool :=
  match value with
  | PsKernelCoreDefinitionSafety.unsafeDef => true
  | PsKernelCoreDefinitionSafety.safe => false
  | PsKernelCoreDefinitionSafety.partialDef => false

def psKernelCoreDefinitionSafetyIsSafe
    (value : PsKernelCoreDefinitionSafety) : Bool :=
  match value with
  | PsKernelCoreDefinitionSafety.unsafeDef => false
  | PsKernelCoreDefinitionSafety.safe => true
  | PsKernelCoreDefinitionSafety.partialDef => false

inductive PsKernelCoreReducibilityHints where
  | opaqueHint
  | abbrevHint
  | regular (height : Nat)

def psKernelCoreNatGt (left : Nat) : Nat -> Bool :=
  match left with
  | Nat.zero =>
      fun (_right : Nat) => false
  | Nat.succ leftRest =>
      let restGt : Nat -> Bool := psKernelCoreNatGt leftRest;
      fun (right : Nat) =>
        match right with
        | Nat.zero => true
        | Nat.succ rightRest => restGt rightRest

def psKernelCoreReducibilityHintsLt
    (left : PsKernelCoreReducibilityHints)
    (right : PsKernelCoreReducibilityHints) : Bool :=
  match left with
  | PsKernelCoreReducibilityHints.abbrevHint =>
      match right with
      | PsKernelCoreReducibilityHints.abbrevHint => false
      | PsKernelCoreReducibilityHints.opaqueHint => true
      | PsKernelCoreReducibilityHints.regular _ => true
  | PsKernelCoreReducibilityHints.regular leftHeight =>
      match right with
      | PsKernelCoreReducibilityHints.abbrevHint => false
      | PsKernelCoreReducibilityHints.opaqueHint => true
      | PsKernelCoreReducibilityHints.regular rightHeight =>
          psKernelCoreNatGt leftHeight rightHeight
  | PsKernelCoreReducibilityHints.opaqueHint => false

def psKernelCoreReducibilityHintsIsRegular
    (value : PsKernelCoreReducibilityHints) : Bool :=
  match value with
  | PsKernelCoreReducibilityHints.regular _ => true
  | PsKernelCoreReducibilityHints.opaqueHint => false
  | PsKernelCoreReducibilityHints.abbrevHint => false

structure PsKernelCoreConstantBase where
  name : PsKernelCoreName
  levelParams : PsKernelCoreList PsKernelCoreName
  type : PsKernelCoreExpr

structure PsKernelCoreAxiomInfo where
  base : PsKernelCoreConstantBase
  isUnsafe : Bool

structure PsKernelCoreDefinitionInfo where
  base : PsKernelCoreConstantBase
  value : PsKernelCoreExpr
  hints : PsKernelCoreReducibilityHints
  safety : PsKernelCoreDefinitionSafety

structure PsKernelCoreTheoremInfo where
  base : PsKernelCoreConstantBase
  value : PsKernelCoreExpr

structure PsKernelCoreOpaqueInfo where
  base : PsKernelCoreConstantBase
  value : PsKernelCoreExpr
  isUnsafe : Bool

inductive PsKernelCoreConstantInfo where
  | axiomInfo (value : PsKernelCoreAxiomInfo)
  | defnInfo (value : PsKernelCoreDefinitionInfo)
  | thmInfo (value : PsKernelCoreTheoremInfo)
  | opaqueInfo (value : PsKernelCoreOpaqueInfo)

def psKernelCoreConstantInfoBase
    (info : PsKernelCoreConstantInfo) : PsKernelCoreConstantBase :=
  match info with
  | PsKernelCoreConstantInfo.axiomInfo value => value.base
  | PsKernelCoreConstantInfo.defnInfo value => value.base
  | PsKernelCoreConstantInfo.thmInfo value => value.base
  | PsKernelCoreConstantInfo.opaqueInfo value => value.base

def psKernelCoreConstantInfoName
    (info : PsKernelCoreConstantInfo) : PsKernelCoreName :=
  let base := psKernelCoreConstantInfoBase info;
  base.name

def psKernelCoreConstantInfoLevelParams
    (info : PsKernelCoreConstantInfo) : PsKernelCoreList PsKernelCoreName :=
  let base := psKernelCoreConstantInfoBase info;
  base.levelParams

def psKernelCoreConstantInfoType
    (info : PsKernelCoreConstantInfo) : PsKernelCoreExpr :=
  let base := psKernelCoreConstantInfoBase info;
  base.type

def psKernelCoreConstantInfoDeltaValue?
    (info : PsKernelCoreConstantInfo) : PsKernelCoreOption PsKernelCoreExpr :=
  match info with
  | PsKernelCoreConstantInfo.defnInfo value =>
      PsKernelCoreOption.some value.value
  | PsKernelCoreConstantInfo.axiomInfo _ => PsKernelCoreOption.none
  | PsKernelCoreConstantInfo.thmInfo _ => PsKernelCoreOption.none
  | PsKernelCoreConstantInfo.opaqueInfo _ => PsKernelCoreOption.none

def psKernelCoreConstantInfoHints?
    (info : PsKernelCoreConstantInfo) :
    PsKernelCoreOption PsKernelCoreReducibilityHints :=
  match info with
  | PsKernelCoreConstantInfo.defnInfo value =>
      PsKernelCoreOption.some value.hints
  | PsKernelCoreConstantInfo.axiomInfo _ => PsKernelCoreOption.none
  | PsKernelCoreConstantInfo.thmInfo _ => PsKernelCoreOption.none
  | PsKernelCoreConstantInfo.opaqueInfo _ => PsKernelCoreOption.none

def psKernelCoreConstantInfoIsUnsafe
    (info : PsKernelCoreConstantInfo) : Bool :=
  match info with
  | PsKernelCoreConstantInfo.axiomInfo value => value.isUnsafe
  | PsKernelCoreConstantInfo.defnInfo value =>
      psKernelCoreDefinitionSafetyIsUnsafe value.safety
  | PsKernelCoreConstantInfo.thmInfo _ => false
  | PsKernelCoreConstantInfo.opaqueInfo value => value.isUnsafe

def psKernelCoreConstantInfoIsPartial
    (info : PsKernelCoreConstantInfo) : Bool :=
  match info with
  | PsKernelCoreConstantInfo.defnInfo value =>
      match value.safety with
      | PsKernelCoreDefinitionSafety.partialDef => true
      | PsKernelCoreDefinitionSafety.unsafeDef => false
      | PsKernelCoreDefinitionSafety.safe => false
  | PsKernelCoreConstantInfo.axiomInfo _ => false
  | PsKernelCoreConstantInfo.thmInfo _ => false
  | PsKernelCoreConstantInfo.opaqueInfo _ => false

def psKernelCoreConstantInfoIsDefinition
    (info : PsKernelCoreConstantInfo) : Bool :=
  match info with
  | PsKernelCoreConstantInfo.defnInfo _ => true
  | PsKernelCoreConstantInfo.axiomInfo _ => false
  | PsKernelCoreConstantInfo.thmInfo _ => false
  | PsKernelCoreConstantInfo.opaqueInfo _ => false

def psKernelCoreConstantInfoDefinition?
    (info : PsKernelCoreConstantInfo) :
    PsKernelCoreOption PsKernelCoreDefinitionInfo :=
  match info with
  | PsKernelCoreConstantInfo.defnInfo value => PsKernelCoreOption.some value
  | PsKernelCoreConstantInfo.axiomInfo _ => PsKernelCoreOption.none
  | PsKernelCoreConstantInfo.thmInfo _ => PsKernelCoreOption.none
  | PsKernelCoreConstantInfo.opaqueInfo _ => PsKernelCoreOption.none
