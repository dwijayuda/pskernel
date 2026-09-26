import Ps.PSCKernel.Core.Declaration

def psCKernelDeclarationFixtureBoolText (value : Bool) : String :=
  if value then "true" else "false"

def psCKernelDeclarationFixtureEmit (key : String) (value : String) : IO Unit :=
  IO.println (key ++ "\t" ++ value)

def psCKernelDeclarationFixtureEmitBool (key : String) (value : Bool) : IO Unit :=
  psCKernelDeclarationFixtureEmit key (psCKernelDeclarationFixtureBoolText value)

def psCKernelDeclarationFixtureName (text : String) : PsCKernelName :=
  psCKernelNameFromDotted text

def psCKernelDeclarationFixtureExpr (text : String) : PsCKernelExpr :=
  PsCKernelExpr.constE (psCKernelDeclarationFixtureName text) []

def psCKernelDeclarationFixtureBase (text : String) : PsCKernelConstantVal :=
  {
    name := psCKernelDeclarationFixtureName text
    levelParams := [psCKernelDeclarationFixtureName "u"]
    declType := psCKernelDeclarationFixtureExpr "Type"
  }

def psCKernelDeclarationFixtureDefinition
    (safety : PsCKernelDefinitionSafety) : PsCKernelConstantInfo :=
  PsCKernelConstantInfo.defnInfo {
    base := psCKernelDeclarationFixtureBase "f"
    value := psCKernelDeclarationFixtureExpr "body"
    hints := PsCKernelReducibilityHints.regular 2
    safety := safety
    all := [psCKernelDeclarationFixtureName "f"]
  }

def psCKernelDeclarationFixtureAxiom (flag : Bool) : PsCKernelConstantInfo :=
  PsCKernelConstantInfo.axiomInfo {
    base := psCKernelDeclarationFixtureBase "ax"
    isUnsafe := flag
  }

def psCKernelDeclarationFixtureTheorem : PsCKernelConstantInfo :=
  PsCKernelConstantInfo.thmInfo {
    base := psCKernelDeclarationFixtureBase "thm"
    value := psCKernelDeclarationFixtureExpr "proof"
    all := [psCKernelDeclarationFixtureName "thm"]
  }

def psCKernelDeclarationFixtureOpaque (flag : Bool) : PsCKernelConstantInfo :=
  PsCKernelConstantInfo.opaqueInfo {
    base := psCKernelDeclarationFixtureBase "opq"
    value := psCKernelDeclarationFixtureExpr "hidden"
    isUnsafe := flag
    all := [psCKernelDeclarationFixtureName "opq"]
  }

def psCKernelDeclarationFixtureQuot : PsCKernelConstantInfo :=
  PsCKernelConstantInfo.quotInfo {
    base := psCKernelDeclarationFixtureBase "Quot"
    kind := PsCKernelQuotKind.type
  }

def psCKernelDeclarationFixtureInductive : PsCKernelConstantInfo :=
  PsCKernelConstantInfo.inductInfo {
    base := psCKernelDeclarationFixtureBase "NatLike"
    numParams := 1
    numIndices := 0
    all := [psCKernelDeclarationFixtureName "NatLike"]
    ctors := [
      psCKernelDeclarationFixtureName "NatLike.zero",
      psCKernelDeclarationFixtureName "NatLike.succ"
    ]
    numNested := 0
    isRec := true
    isUnsafe := true
    isReflexive := false
  }

def psCKernelDeclarationFixtureHintKey
    (hint : PsCKernelReducibilityHints) : String :=
  match hint with
  | PsCKernelReducibilityHints.opaqueHint => "opaque"
  | PsCKernelReducibilityHints.abbreviation => "abbrev"
  | PsCKernelReducibilityHints.regular height => "regular:" ++ toString height

def psCKernelDeclarationFixtureSafetyKey
    (safety : PsCKernelDefinitionSafety) : String :=
  match safety with
  | PsCKernelDefinitionSafety.unsafeDef => "unsafe"
  | PsCKernelDefinitionSafety.safe => "safe"
  | PsCKernelDefinitionSafety.partial => "partial"

def main : IO Unit := do
  let safeDef := psCKernelDeclarationFixtureDefinition PsCKernelDefinitionSafety.safe
  let unsafeDef := psCKernelDeclarationFixtureDefinition PsCKernelDefinitionSafety.unsafeDef
  let partialDef := psCKernelDeclarationFixtureDefinition PsCKernelDefinitionSafety.partial
  let theoremInfo := psCKernelDeclarationFixtureTheorem
  let opaqueInfo := psCKernelDeclarationFixtureOpaque true
  let axiomInfo := psCKernelDeclarationFixtureAxiom true
  let quotInfo := psCKernelDeclarationFixtureQuot
  let inductiveInfo := psCKernelDeclarationFixtureInductive

  psCKernelDeclarationFixtureEmit
    "definition.name"
    (psCKernelNameToString (psCKernelConstantInfoName safeDef))
  psCKernelDeclarationFixtureEmit
    "definition.levelCount"
    (toString (psCKernelConstantInfoNumLevelParams safeDef))
  psCKernelDeclarationFixtureEmit
    "definition.hint"
    (psCKernelDeclarationFixtureHintKey (psCKernelConstantInfoHints safeDef))
  psCKernelDeclarationFixtureEmit
    "definition.safety"
    (psCKernelDeclarationFixtureSafetyKey PsCKernelDefinitionSafety.safe)
  psCKernelDeclarationFixtureEmitBool
    "definition.hasValue"
    (psCKernelConstantInfoHasValue safeDef false)
  psCKernelDeclarationFixtureEmitBool
    "theorem.hasValue"
    (psCKernelConstantInfoHasValue theoremInfo true)
  psCKernelDeclarationFixtureEmitBool
    "opaque.hasValue"
    (psCKernelConstantInfoHasValue opaqueInfo true)
  psCKernelDeclarationFixtureEmitBool
    "axiom.hasValue"
    (psCKernelConstantInfoHasValue axiomInfo true)
  psCKernelDeclarationFixtureEmitBool
    "unsafe.definition"
    (psCKernelConstantInfoIsUnsafe unsafeDef)
  psCKernelDeclarationFixtureEmitBool
    "unsafe.safeDefinition"
    (psCKernelConstantInfoIsUnsafe safeDef)
  psCKernelDeclarationFixtureEmitBool
    "unsafe.axiom"
    (psCKernelConstantInfoIsUnsafe axiomInfo)
  psCKernelDeclarationFixtureEmitBool
    "unsafe.opaque"
    (psCKernelConstantInfoIsUnsafe opaqueInfo)
  psCKernelDeclarationFixtureEmitBool
    "unsafe.theorem"
    (psCKernelConstantInfoIsUnsafe theoremInfo)
  psCKernelDeclarationFixtureEmitBool
    "unsafe.quot"
    (psCKernelConstantInfoIsUnsafe quotInfo)
  psCKernelDeclarationFixtureEmitBool
    "unsafe.inductive"
    (psCKernelConstantInfoIsUnsafe inductiveInfo)
  psCKernelDeclarationFixtureEmitBool
    "partial.definition"
    (psCKernelConstantInfoIsPartial partialDef)
