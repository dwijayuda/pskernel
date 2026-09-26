import Ps.PSCKernel.Core.Declaration

structure PsCKernelDeclarationNamedTest where
  name : String
  passed : Bool

def psCKernelDeclarationName (text : String) : PsCKernelName :=
  psCKernelNameFromDotted text

def psCKernelDeclarationExpr (text : String) : PsCKernelExpr :=
  PsCKernelExpr.constE (psCKernelDeclarationName text) []

def psCKernelDeclarationBase (text : String) : PsCKernelConstantVal :=
  {
    name := psCKernelDeclarationName text
    levelParams := [psCKernelDeclarationName "u"]
    declType := psCKernelDeclarationExpr "Type"
  }

def psCKernelDeclarationDefinition
    (safety : PsCKernelDefinitionSafety)
    (hints : PsCKernelReducibilityHints) : PsCKernelConstantInfo :=
  PsCKernelConstantInfo.defnInfo {
    base := psCKernelDeclarationBase "f"
    value := psCKernelDeclarationExpr "body"
    hints := hints
    safety := safety
    all := [psCKernelDeclarationName "f"]
  }

def psCKernelDeclarationAxiom (isUnsafe : Bool) : PsCKernelConstantInfo :=
  PsCKernelConstantInfo.axiomInfo {
    base := psCKernelDeclarationBase "ax"
    isUnsafe := isUnsafe
  }

def psCKernelDeclarationTheorem : PsCKernelConstantInfo :=
  PsCKernelConstantInfo.thmInfo {
    base := psCKernelDeclarationBase "thm"
    value := psCKernelDeclarationExpr "proof"
    all := [psCKernelDeclarationName "thm"]
  }

def psCKernelDeclarationOpaque (isUnsafe : Bool) : PsCKernelConstantInfo :=
  PsCKernelConstantInfo.opaqueInfo {
    base := psCKernelDeclarationBase "opaque"
    value := psCKernelDeclarationExpr "opaqueBody"
    isUnsafe := isUnsafe
    all := [psCKernelDeclarationName "opaque"]
  }

def psCKernelDeclarationQuot : PsCKernelConstantInfo :=
  PsCKernelConstantInfo.quotInfo {
    base := psCKernelDeclarationBase "Quot"
    kind := PsCKernelQuotKind.type
  }

def psCKernelDeclarationOptionExprEq
    (left : Option PsCKernelExpr)
    (right : Option PsCKernelExpr) : Bool :=
  match left, right with
  | none, none => true
  | some leftExpr, some rightExpr => psCKernelExprEqStructural leftExpr rightExpr
  | _, _ => false

def psCKernelDeclarationTestReducibilityOrder : Bool :=
  psCKernelReducibilityHintsLt
      PsCKernelReducibilityHints.abbrev
      (PsCKernelReducibilityHints.regular 1) &&
    psCKernelReducibilityHintsLt
      (PsCKernelReducibilityHints.regular 3)
      (PsCKernelReducibilityHints.regular 2) &&
    psCKernelReducibilityHintsLt
      (PsCKernelReducibilityHints.regular 1)
      PsCKernelReducibilityHints.opaque &&
    !psCKernelReducibilityHintsLt
      PsCKernelReducibilityHints.opaque
      PsCKernelReducibilityHints.abbrev

def psCKernelDeclarationTestHintPredicates : Bool :=
  psCKernelReducibilityHintsIsAbbrev PsCKernelReducibilityHints.abbrev &&
    !psCKernelReducibilityHintsIsAbbrev PsCKernelReducibilityHints.opaque &&
    psCKernelReducibilityHintsIsRegular (PsCKernelReducibilityHints.regular 4) &&
    !psCKernelReducibilityHintsIsRegular PsCKernelReducibilityHints.abbrev

def psCKernelDeclarationTestDefinitionValue : Bool :=
  let info : PsCKernelConstantInfo :=
    psCKernelDeclarationDefinition
      PsCKernelDefinitionSafety.safe
      (PsCKernelReducibilityHints.regular 2)
  psCKernelConstantInfoHasValue info false &&
    psCKernelDeclarationOptionExprEq
      (psCKernelConstantInfoValue? info false)
      (some (psCKernelDeclarationExpr "body"))

def psCKernelDeclarationTestOpaqueVisibility : Bool :=
  !psCKernelConstantInfoHasValue psCKernelDeclarationTheorem false &&
    psCKernelConstantInfoHasValue psCKernelDeclarationTheorem true &&
    !psCKernelConstantInfoHasValue (psCKernelDeclarationOpaque false) false &&
    psCKernelConstantInfoHasValue (psCKernelDeclarationOpaque false) true

def psCKernelDeclarationTestUnsafeDefinition : Bool :=
  psCKernelConstantInfoIsUnsafe
      (psCKernelDeclarationDefinition
        PsCKernelDefinitionSafety.unsafe
        PsCKernelReducibilityHints.opaque) &&
    !psCKernelConstantInfoIsUnsafe
      (psCKernelDeclarationDefinition
        PsCKernelDefinitionSafety.safe
        PsCKernelReducibilityHints.opaque)

def psCKernelDeclarationTestUnsafeOtherKinds : Bool :=
  psCKernelConstantInfoIsUnsafe (psCKernelDeclarationAxiom true) &&
    psCKernelConstantInfoIsUnsafe (psCKernelDeclarationOpaque true) &&
    !psCKernelConstantInfoIsUnsafe psCKernelDeclarationTheorem &&
    !psCKernelConstantInfoIsUnsafe psCKernelDeclarationQuot

def psCKernelDeclarationTestPartial : Bool :=
  psCKernelConstantInfoIsPartial
      (psCKernelDeclarationDefinition
        PsCKernelDefinitionSafety.partial
        PsCKernelReducibilityHints.opaque) &&
    !psCKernelConstantInfoIsPartial psCKernelDeclarationTheorem

def psCKernelDeclarationTestBaseAccessors : Bool :=
  let info : PsCKernelConstantInfo := psCKernelDeclarationAxiom false
  psCKernelNameEq
      (psCKernelConstantInfoName info)
      (psCKernelDeclarationName "ax") &&
    Nat.beq (psCKernelConstantInfoNumLevelParams info) 1 &&
    psCKernelExprEqStructural
      (psCKernelConstantInfoType info)
      (psCKernelDeclarationExpr "Type")

def psCKernelDeclarationTestHintsFallback : Bool :=
  psCKernelReducibilityHintsEq
      (psCKernelConstantInfoHints
        (psCKernelDeclarationDefinition
          PsCKernelDefinitionSafety.safe
          PsCKernelReducibilityHints.abbrev))
      PsCKernelReducibilityHints.abbrev &&
    psCKernelReducibilityHintsEq
      (psCKernelConstantInfoHints psCKernelDeclarationTheorem)
      PsCKernelReducibilityHints.opaque

def psCKernelDeclarationTestInductiveHelpers : Bool :=
  let info : PsCKernelInductiveVal := {
    base := psCKernelDeclarationBase "NatLike"
    numParams := 1
    numIndices := 0
    all := [psCKernelDeclarationName "NatLike", psCKernelDeclarationName "Other"]
    ctors := [psCKernelDeclarationName "zero", psCKernelDeclarationName "succ"]
    numNested := 1
    isRec := true
    isUnsafe := false
    isReflexive := false
  }
  Nat.beq (psCKernelInductiveValNumCtors info) 2 &&
    psCKernelInductiveValIsNested info &&
    Nat.beq (psCKernelInductiveValNumTypeFormers info) 3

def psCKernelDeclarationTestConstructorUnsafe : Bool :=
  let info : PsCKernelConstantInfo :=
    PsCKernelConstantInfo.ctorInfo {
      base := psCKernelDeclarationBase "NatLike.succ"
      induct := psCKernelDeclarationName "NatLike"
      cidx := 1
      numParams := 1
      numFields := 1
      isUnsafe := true
    }
  psCKernelConstantInfoIsUnsafe info && psCKernelConstantInfoIsCtor info

def psCKernelDeclarationTestRecursorIndices : Bool :=
  let recInfo : PsCKernelRecursorVal := {
    base := psCKernelDeclarationBase "NatLike.rec"
    all := [psCKernelDeclarationName "NatLike"]
    numParams := 2
    numIndices := 3
    numMotives := 1
    numMinors := 4
    rules := []
    k := false
    isUnsafe := false
  }
  Nat.beq (psCKernelRecursorValGetMajorIdx recInfo) 10 &&
    Nat.beq (psCKernelRecursorValGetFirstIndexIdx recInfo) 7 &&
    Nat.beq (psCKernelRecursorValGetFirstMinorIdx recInfo) 3

def psCKernelDeclarationTestQuotKind : Bool :=
  let info : PsCKernelConstantInfo := psCKernelDeclarationQuot
  psCKernelConstantInfoIsQuot info &&
    !psCKernelConstantInfoIsDefinition info &&
    !psCKernelConstantInfoIsAxiom info

def psCKernelDeclarationTestAllFallback : Bool :=
  let names : List PsCKernelName :=
    psCKernelConstantInfoAll (psCKernelDeclarationAxiom false)
  match names with
  | [name] => psCKernelNameEq name (psCKernelDeclarationName "ax")
  | _ => false

def psCKernelDeclarationTests : List PsCKernelDeclarationNamedTest := [
  { name := "reducibility hint ordering follows Lean 4.34", passed := psCKernelDeclarationTestReducibilityOrder },
  { name := "reducibility hint predicates classify constructors", passed := psCKernelDeclarationTestHintPredicates },
  { name := "definitions expose values by default", passed := psCKernelDeclarationTestDefinitionValue },
  { name := "theorem and opaque values require allowOpaque", passed := psCKernelDeclarationTestOpaqueVisibility },
  { name := "definition safety controls unsafe classification", passed := psCKernelDeclarationTestUnsafeDefinition },
  { name := "unsafe flags and theorem quot safety match Lean", passed := psCKernelDeclarationTestUnsafeOtherKinds },
  { name := "partial classification is definition-only", passed := psCKernelDeclarationTestPartial },
  { name := "constant base accessors preserve name levels and type", passed := psCKernelDeclarationTestBaseAccessors },
  { name := "non-definition hints fall back to opaque", passed := psCKernelDeclarationTestHintsFallback },
  { name := "inductive helper counts follow Lean", passed := psCKernelDeclarationTestInductiveHelpers },
  { name := "constructor classification preserves unsafe flag", passed := psCKernelDeclarationTestConstructorUnsafe },
  { name := "recursor argument indices follow Lean formulas", passed := psCKernelDeclarationTestRecursorIndices },
  { name := "quotient classification stays distinct", passed := psCKernelDeclarationTestQuotKind },
  { name := "all fallback returns the declaration name", passed := psCKernelDeclarationTestAllFallback }
]

def psCKernelRunDeclarationTests
    (tests : List PsCKernelDeclarationNamedTest) : IO Bool :=
  match tests with
  | [] => pure true
  | test :: rest => do
      if test.passed then
        IO.println ("PSCKERNEL_DECLARATION_PASS: " ++ test.name)
      else
        IO.println ("PSCKERNEL_DECLARATION_FAIL: " ++ test.name)
      let restPassed ← psCKernelRunDeclarationTests rest
      pure (test.passed && restPassed)

def main : IO Unit := do
  let passed ← psCKernelRunDeclarationTests psCKernelDeclarationTests
  if passed then
    IO.println "PSCKERNEL_DECLARATION_TESTS: PASS"
  else
    throw (IO.userError "PSCKERNEL_DECLARATION_TESTS: FAIL")
