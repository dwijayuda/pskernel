import Ps.Environment.StandardFloatConversionsData
import Ps.Environment.StandardClass

/-!
Selected F3 closure, independently replayed against the frozen pre-F3 boundary.
Logical dependencies do not implicitly register extra search rules. Native
OfScientific dictionaries and their default priority come from Lean 4.35.0
Init/Data/OfScientific.lean (Apache-2.0, Microsoft Corporation).
-/

def psStandardScientificNames : List PsName :=
  ["OfScientific", "OfScientific.mk", "OfScientific.ofScientific", "OfScientific.rec"].map psDecisionName

def psStandardScientificDeclarations : List PsDeclaration :=
  psStandardFloatConversionsDeclarations.filter fun declaration =>
    psStandardScientificNames.any (psNameEq (psDeclarationName declaration))

def psStandardScientificInstances : List PsDeclaration :=
  psStandardFloatConversionsDeclarations.filter fun declaration =>
    ["instOfScientificFloat", "instOfScientificFloat32"].contains (psNameToString (psDeclarationName declaration))

-- Ordinary checked dictionaries over the selected native conversion methods.
-- Preserve raw OfNat indices, including when a local OfNat Nat is in scope.
def psStandardFloatOfNatInstances : List PsDeclaration :=
  ["Float", "Float32"].map fun owner =>
    let type := PsExpr.constE (psRootName owner) []
    let nat := PsExpr.constE psNatName []
    let index := PsExpr.fvar 0
    .definitionDecl (psDecisionName ("PsStandard.instOfNat" ++ owner)) []
      (psLogicPi 0 "n" nat (psLogicApply (.constE (psRootName "OfNat") [.zero]) [type, index]))
      (psLogicLam 0 "n" nat (psLogicApply (.constE (psDecisionName "OfNat.mk") [.zero])
        [type, index, .app (.constE (psDecisionName (owner ++ ".ofNat")) []) index]))

def psStandardScientificExtend (environment : PsEnvironment) : PsEnvironment :=
  let environment := psStandardFloatConversionsDeclarations.foldl psEnvironmentInsert environment
  let environment := psStandardFloatConversionsReducibility.foldl (fun env (name, status) =>
    psEnvironmentSetReducibility env name status) environment
  let environment := psStandardFloatOfNatInstances.foldl psEnvironmentInsert environment
  let environment := psStandardRegisterClass environment "OfScientific"
  let environment := psStandardRegisterInstances environment "OfScientific" psStandardScientificInstances
  let environment := psStandardRegisterInstances environment "OfNat" psStandardFloatOfNatInstances
  let instances := psStandardScientificInstances.foldl (fun index declaration =>
    if psNameEq (psDeclarationName declaration) (psRootName "instOfScientificFloat") then
      psInstanceIndexAddDefault index {
        value := .constE (psDeclarationName declaration) []
        levelParams := []
        type := psDeclarationType declaration
        className := some (psRootName "OfScientific")
        priority := 501 }
    else index) environment.instances
  { environment with instances }

def psStandardScientificRuntimeDeclarations : List PsDeclaration :=
  psStandardScientificDeclarations ++ psStandardScientificInstances ++ psStandardFloatOfNatInstances

def psStandardScientificAudit (environment : PsEnvironment) : Except String Unit := do
  if psStandardFloatConversionsDeclarations.length != 134 ||
      psStandardScientificDeclarations.length != 4 ||
      psStandardScientificInstances.length != 2 then
    throw "PSCV0-STANDARD: native scientific/conversion family drift"
  for declaration in psStandardScientificRuntimeDeclarations do
    psStandardAuditDeclaration environment declaration
  for declaration in psStandardScientificInstances ++ psStandardFloatOfNatInstances do
    psStandardAuditInstance environment declaration
  if !environment.classes.any (psNameEq (psRootName "OfScientific")) then
    throw "PSCV0-STANDARD: missing OfScientific class"
  let entries := environment.instances.defaults.filter (fun entry =>
    match entry.value with | .constE name _ => psNameEq name (psRootName "instOfScientificFloat") | _ => false)
  let [entry] := entries | throw "PSCV0-STANDARD: scientific default count drift"
  if entry.priority != 501 || !(entry.className.any (psNameEq (psRootName "OfScientific"))) then
    throw "PSCV0-STANDARD: scientific default priority drift"
