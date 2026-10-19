import Ps.Environment.Basic
import Ps.Core.Equality

/-!
Actual source implementation closure for inspection only. The project owner
builds these entries before restricting source visibility; external module
interfaces cannot supply them. This table never supplies kernel admission,
source name resolution, exported aliases, classes or instance registration.
-/

def psInspectionNamesEqual (left right : List PsName) : Bool :=
  left.length == right.length && (left.zip right).all (fun pair => psNameEq pair.1 pair.2)

def psInspectionDeclarationEqual (left right : PsDeclaration) : Bool :=
  match left, right with
  | .quotientDecl name levels type kind, .quotientDecl other otherLevels otherType otherKind =>
    psNameEq name other && psInspectionNamesEqual levels otherLevels &&
      psExprAlphaEq type otherType && psQuotientKindTag kind == psQuotientKindTag otherKind
  | .axiomDecl name levels type, .axiomDecl other otherLevels otherType =>
    psNameEq name other && psInspectionNamesEqual levels otherLevels &&
      psExprAlphaEq type otherType
  | .definitionDecl name levels type value, .definitionDecl other otherLevels otherType otherValue
  | .theoremDecl name levels type value, .theoremDecl other otherLevels otherType otherValue
  | .opaqueDecl name levels type value, .opaqueDecl other otherLevels otherType otherValue
  | .partialDecl name levels type value, .partialDecl other otherLevels otherType otherValue =>
    psNameEq name other && psInspectionNamesEqual levels otherLevels &&
      psExprAlphaEq type otherType && psExprAlphaEq value otherValue
  | .inductiveDecl left, .inductiveDecl right =>
    psNameEq left.name right.name && psInspectionNamesEqual left.levelParams right.levelParams &&
      psExprAlphaEq left.type right.type && left.numParams == right.numParams &&
      left.numIndices == right.numIndices && psInspectionNamesEqual left.constructors right.constructors &&
      left.isStructure == right.isStructure
  | .constructorDecl left, .constructorDecl right =>
    psNameEq left.name right.name && psInspectionNamesEqual left.levelParams right.levelParams &&
      psExprAlphaEq left.type right.type && psNameEq left.inductiveName right.inductiveName &&
      left.constructorIndex == right.constructorIndex && left.numParams == right.numParams &&
      left.numFields == right.numFields && left.recursiveFields == right.recursiveFields
  | .recursorDecl left, .recursorDecl right =>
    psNameEq left.name right.name && psInspectionNamesEqual left.levelParams right.levelParams &&
      psExprAlphaEq left.type right.type && psInspectionNamesEqual left.inductiveNames right.inductiveNames &&
      left.numParams == right.numParams && left.numIndices == right.numIndices &&
      left.numMotives == right.numMotives && left.numMinors == right.numMinors
  | _, _ => false

-- Ordinary source definitions become opaque in a module import view. Their
-- type, universe telescope and stored body must still agree exactly.
def psInspectionVisibleDeclarationEqual (actual visible : PsDeclaration) : Bool :=
  match actual, visible with
  | .definitionDecl name levels type value, .opaqueDecl other otherLevels otherType otherValue =>
    psNameEq name other && psInspectionNamesEqual levels otherLevels &&
      psExprAlphaEq type otherType && psExprAlphaEq value otherValue
  | _, _ => psInspectionDeclarationEqual actual visible

def psInspectionEntryEqual (left right : PsInspectionDeclaration) : Bool :=
  left.isNoncomputable == right.isNoncomputable &&
    psInspectionDeclarationEqual left.declaration right.declaration

def psInspectionAttach (environment : PsEnvironment)
    (entries : List PsInspectionDeclaration) : Except String PsEnvironment := do
  let combined ← entries.foldlM (fun current entry => do
    let name := psDeclarationName entry.declaration
    if let some visible := psEnvironmentFind environment name then
      if !psInspectionVisibleDeclarationEqual entry.declaration visible ||
          entry.isNoncomputable != psEnvironmentIsNoncomputable environment name then
        throw ("PSCV0-INSPECTION: conflicting visible implementation or policy for " ++
          psNameToString name)
    match current.find? (fun old => psNameEq (psDeclarationName old.declaration) name) with
    | some old =>
      if !psInspectionEntryEqual old entry then
        throw ("PSCV0-INSPECTION: conflicting implementation closure for " ++ psNameToString name)
      return current
    | none => return current ++ [entry]) environment.inspectionDeclarations
  return { environment with inspectionDeclarations := combined }

def psInspectionCapture (environment : PsEnvironment) (declarations : List PsDeclaration) :
    Except String (List PsInspectionDeclaration) := do
  let entries := declarations.map fun declaration => {
    declaration
    isNoncomputable := psEnvironmentIsNoncomputable environment (psDeclarationName declaration) }
  return (← psInspectionAttach environment entries).inspectionDeclarations

-- Only callers that already resolved and checked the public expression may use
-- this temporary body view. Hidden entries remain absent from source lookup,
-- exported aliases, class metadata and instance registries.
def psInspectionExecutionEnvironment (environment : PsEnvironment) :
    Except String PsEnvironment := do
  let _ ← psInspectionAttach { environment with inspectionDeclarations := [] }
    environment.inspectionDeclarations
  environment.inspectionDeclarations.foldlM (fun current entry => do
    let name := psDeclarationName entry.declaration
    if psEnvironmentContains current name then return current
    let some next := psEnvironmentAdd current entry.declaration
      | throw ("PSCV0-INSPECTION: cannot install actual implementation " ++ psNameToString name)
    return if entry.isNoncomputable then psEnvironmentMarkNoncomputable next name else next) environment
