import Ps.KernelCore.Declaration
import PSC1Kernel.Declaration

def psKernelCoreDefinitionSafetyTag
    (value : PsKernelCoreDefinitionSafety) : Nat :=
  match value with
  | PsKernelCoreDefinitionSafety.unsafeDef => 0
  | PsKernelCoreDefinitionSafety.safe => 1
  | PsKernelCoreDefinitionSafety.partialDef => 2

def psReferenceDefinitionSafetyTag
    (value : PSC1Kernel.DefinitionSafety) : Nat :=
  match value with
  | PSC1Kernel.DefinitionSafety.unsafeDef => 0
  | PSC1Kernel.DefinitionSafety.safe => 1
  | PSC1Kernel.DefinitionSafety.partialDef => 2

def psKernelCoreReducibilityTag
    (value : PsKernelCoreReducibilityHints) : Nat :=
  match value with
  | PsKernelCoreReducibilityHints.opaqueHint => 0
  | PsKernelCoreReducibilityHints.abbrevHint => 1
  | PsKernelCoreReducibilityHints.regular height => Nat.add 10 height

def psReferenceReducibilityTag
    (value : PSC1Kernel.ReducibilityHints) : Nat :=
  match value with
  | PSC1Kernel.ReducibilityHints.opaqueHint => 0
  | PSC1Kernel.ReducibilityHints.abbrevHint => 1
  | PSC1Kernel.ReducibilityHints.regular height => Nat.add 10 height

def psKernelCoreOptionExprTag
    (value : PsKernelCoreOption PsKernelCoreExpr) : Nat :=
  match value with
  | PsKernelCoreOption.none => 0
  | PsKernelCoreOption.some _ => 1

def psReferenceOptionExprTag
    (value : Option PSC1Kernel.Expr) : Nat :=
  match value with
  | none => 0
  | some _ => 1

def psKernelCoreOptionHintsTag
    (value : PsKernelCoreOption PsKernelCoreReducibilityHints) : Nat :=
  match value with
  | PsKernelCoreOption.none => 0
  | PsKernelCoreOption.some hint => Nat.add 1 (psKernelCoreReducibilityTag hint)

def psReferenceOptionHintsTag
    (value : Option PSC1Kernel.ReducibilityHints) : Nat :=
  match value with
  | none => 0
  | some hint => Nat.add 1 (psReferenceReducibilityTag hint)

def psKernelCoreOptionDefinitionTag
    (value : PsKernelCoreOption PsKernelCoreDefinitionInfo) : Nat :=
  match value with
  | PsKernelCoreOption.none => 0
  | PsKernelCoreOption.some _ => 1

def psReferenceOptionDefinitionTag
    (value : Option PSC1Kernel.DefinitionInfo) : Nat :=
  match value with
  | none => 0
  | some _ => 1

def psKernelCoreDeclarationParity : Bool :=
  let kcAnon := PsKernelCoreName.anonymous
  let kcName := PsKernelCoreName.str kcAnon "answer"
  let kcU := PsKernelCoreName.str kcAnon "u"
  let kcParams := PsKernelCoreList.cons kcU PsKernelCoreList.nil
  let kcType := PsKernelCoreExpr.sort PsKernelCoreLevel.zero
  let kcValue := PsKernelCoreExpr.bvar 0
  let kcBase : PsKernelCoreConstantBase := {
    name := kcName
    levelParams := kcParams
    type := kcType
  }
  let kcAxiom : PsKernelCoreConstantInfo :=
    PsKernelCoreConstantInfo.axiomInfo {
      base := kcBase
      isUnsafe := true
    }
  let kcDef : PsKernelCoreConstantInfo :=
    PsKernelCoreConstantInfo.defnInfo {
      base := kcBase
      value := kcValue
      hints := PsKernelCoreReducibilityHints.regular 3
      safety := PsKernelCoreDefinitionSafety.partialDef
    }
  let kcTheorem : PsKernelCoreConstantInfo :=
    PsKernelCoreConstantInfo.thmInfo {
      base := kcBase
      value := kcValue
    }
  let kcOpaque : PsKernelCoreConstantInfo :=
    PsKernelCoreConstantInfo.opaqueInfo {
      base := kcBase
      value := kcValue
      isUnsafe := false
    }
  let refAnon := PSC1Kernel.Name.anonymous
  let refName := PSC1Kernel.Name.str refAnon "answer"
  let refU := PSC1Kernel.Name.str refAnon "u"
  let refType := PSC1Kernel.Expr.sort PSC1Kernel.Level.zero
  let refValue := PSC1Kernel.Expr.bvar 0
  let refBase : PSC1Kernel.ConstantBase := {
    name := refName
    levelParams := [refU]
    type := refType
  }
  let refAxiom : PSC1Kernel.ConstantInfo :=
    PSC1Kernel.ConstantInfo.axiomInfo {
      base := refBase
      isUnsafe := true
    }
  let refDef : PSC1Kernel.ConstantInfo :=
    PSC1Kernel.ConstantInfo.defnInfo {
      base := refBase
      value := refValue
      hints := PSC1Kernel.ReducibilityHints.regular 3
      safety := PSC1Kernel.DefinitionSafety.partialDef
    }
  let refTheorem : PSC1Kernel.ConstantInfo :=
    PSC1Kernel.ConstantInfo.thmInfo {
      base := refBase
      value := refValue
    }
  let refOpaque : PSC1Kernel.ConstantInfo :=
    PSC1Kernel.ConstantInfo.opaqueInfo {
      base := refBase
      value := refValue
      isUnsafe := false
    }
  (psKernelCoreDefinitionSafetyTag PsKernelCoreDefinitionSafety.unsafeDef ==
    psReferenceDefinitionSafetyTag PSC1Kernel.DefinitionSafety.unsafeDef) &&
  (psKernelCoreDefinitionSafetyTag PsKernelCoreDefinitionSafety.safe ==
    psReferenceDefinitionSafetyTag PSC1Kernel.DefinitionSafety.safe) &&
  (psKernelCoreDefinitionSafetyTag PsKernelCoreDefinitionSafety.partialDef ==
    psReferenceDefinitionSafetyTag PSC1Kernel.DefinitionSafety.partialDef) &&
  (psKernelCoreDefinitionSafetyIsUnsafe PsKernelCoreDefinitionSafety.unsafeDef ==
    PSC1Kernel.DefinitionSafety.isUnsafe PSC1Kernel.DefinitionSafety.unsafeDef) &&
  (psKernelCoreDefinitionSafetyIsSafe PsKernelCoreDefinitionSafety.safe ==
    PSC1Kernel.DefinitionSafety.isSafe PSC1Kernel.DefinitionSafety.safe) &&
  (psKernelCoreReducibilityTag PsKernelCoreReducibilityHints.abbrevHint ==
    psReferenceReducibilityTag PSC1Kernel.ReducibilityHints.abbrevHint) &&
  (psKernelCoreReducibilityHintsLt
      PsKernelCoreReducibilityHints.abbrevHint
      (PsKernelCoreReducibilityHints.regular 1) ==
    PSC1Kernel.ReducibilityHints.lt
      PSC1Kernel.ReducibilityHints.abbrevHint
      (PSC1Kernel.ReducibilityHints.regular 1)) &&
  (psKernelCoreReducibilityHintsLt
      (PsKernelCoreReducibilityHints.regular 3)
      (PsKernelCoreReducibilityHints.regular 2) ==
    PSC1Kernel.ReducibilityHints.lt
      (PSC1Kernel.ReducibilityHints.regular 3)
      (PSC1Kernel.ReducibilityHints.regular 2)) &&
  (psKernelCoreReducibilityHintsLt
      (PsKernelCoreReducibilityHints.regular 2)
      (PsKernelCoreReducibilityHints.regular 2) ==
    PSC1Kernel.ReducibilityHints.lt
      (PSC1Kernel.ReducibilityHints.regular 2)
      (PSC1Kernel.ReducibilityHints.regular 2)) &&
  (psKernelCoreReducibilityHintsLt
      (PsKernelCoreReducibilityHints.regular 2)
      PsKernelCoreReducibilityHints.opaqueHint ==
    PSC1Kernel.ReducibilityHints.lt
      (PSC1Kernel.ReducibilityHints.regular 2)
      PSC1Kernel.ReducibilityHints.opaqueHint) &&
  (psKernelCoreReducibilityHintsIsRegular
      (PsKernelCoreReducibilityHints.regular 4) ==
    PSC1Kernel.ReducibilityHints.isRegular
      (PSC1Kernel.ReducibilityHints.regular 4)) &&
  psKernelCoreNameEq (psKernelCoreConstantInfoName kcDef) kcName &&
  PSC1Kernel.Name.eq (PSC1Kernel.ConstantInfo.name refDef) refName &&
  (psKernelCoreOptionExprTag (psKernelCoreConstantInfoDeltaValue? kcDef) ==
    psReferenceOptionExprTag (PSC1Kernel.ConstantInfo.deltaValue? refDef)) &&
  (psKernelCoreOptionExprTag (psKernelCoreConstantInfoDeltaValue? kcAxiom) ==
    psReferenceOptionExprTag (PSC1Kernel.ConstantInfo.deltaValue? refAxiom)) &&
  (psKernelCoreOptionExprTag (psKernelCoreConstantInfoDeltaValue? kcTheorem) ==
    psReferenceOptionExprTag (PSC1Kernel.ConstantInfo.deltaValue? refTheorem)) &&
  (psKernelCoreOptionExprTag (psKernelCoreConstantInfoDeltaValue? kcOpaque) ==
    psReferenceOptionExprTag (PSC1Kernel.ConstantInfo.deltaValue? refOpaque)) &&
  (psKernelCoreOptionHintsTag (psKernelCoreConstantInfoHints? kcDef) ==
    psReferenceOptionHintsTag (PSC1Kernel.ConstantInfo.hints? refDef)) &&
  (psKernelCoreConstantInfoIsUnsafe kcAxiom == PSC1Kernel.ConstantInfo.isUnsafe refAxiom) &&
  (psKernelCoreConstantInfoIsUnsafe kcOpaque == PSC1Kernel.ConstantInfo.isUnsafe refOpaque) &&
  (psKernelCoreConstantInfoIsPartial kcDef == PSC1Kernel.ConstantInfo.isPartial refDef) &&
  (psKernelCoreConstantInfoIsDefinition kcDef == PSC1Kernel.ConstantInfo.isDefinition refDef) &&
  (psKernelCoreConstantInfoIsDefinition kcTheorem == PSC1Kernel.ConstantInfo.isDefinition refTheorem) &&
  (psKernelCoreOptionDefinitionTag (psKernelCoreConstantInfoDefinition? kcDef) ==
    psReferenceOptionDefinitionTag (PSC1Kernel.ConstantInfo.definition? refDef)) &&
  (psKernelCoreOptionDefinitionTag (psKernelCoreConstantInfoDefinition? kcTheorem) ==
    psReferenceOptionDefinitionTag (PSC1Kernel.ConstantInfo.definition? refTheorem))

def main : IO Unit := do
  if psKernelCoreDeclarationParity then
    IO.println "PSC2_KERNEL_CORE_DECLARATION_PARITY: PASS"
  else
    throw (IO.userError "PSC2_KERNEL_CORE_DECLARATION_PARITY: FAIL")
