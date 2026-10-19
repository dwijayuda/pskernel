import Ps.Environment.Bootstrap
import Ps.Environment.Fingerprint
import PsKernelLean.Replay

private def bootstrapRequire (condition : Bool) (message : String) : IO Unit :=
  if condition then pure () else throw (IO.userError ("BOOTSTRAP: " ++ message))

private def bootstrapExpr (expression : PsExpr) : IO Lean.Expr :=
  match PsKernelLean.toLeanExpr expression with
  | .ok value => pure value
  | .error error => throw (IO.userError error.message)

private def bootstrapRecursiveFields (family : Lean.Name)
    (parameters fields : Nat) (type : Lean.Expr) : Except String (List Nat) := do
  let rec skip : Nat → Lean.Expr → Except String Lean.Expr
    | 0, value => pure value
    | n + 1, .forallE _ _ body _ => skip n body
    | _, _ => throw "constructor parameter telescope mismatch"
  let rec collect : Nat → Nat → Lean.Expr → Except String (List Nat)
    | 0, _, _ => pure []
    | n + 1, index, .forallE _ domain body _ => do
      let rest ← collect n (index + 1) body
      if domain.getForallBody.getAppFn.isConstOf family then return index :: rest
      if domain.getUsedConstants.contains family then
        throw "nested recursive field is outside Bootstrap authoring policy"
      return rest
    | _, _, _ => throw "constructor field telescope mismatch"
  collect fields 0 (← skip parameters type)

private def bootstrapReplay (declarations : List PsDeclaration) :
    IO Lean.Kernel.Environment := do
  let mut checked := (← Lean.mkEmptyEnvironment 0).toKernelEnv
  bootstrapRequire checked.constants.toList.isEmpty "fresh kernel is not empty"
  let mut pending := declarations.reverse
  while !pending.isEmpty do
    let before := pending.length
    let mut deferred : List PsDeclaration := []
    for declaration in pending do
      let attempt ← PsKernelLean.withFreshKernelHeartbeatScope fun _ =>
        PsKernelLean.tryPreludeDeclaration declarations checked declaration 2000000 20000
      match attempt with
      | .ok (.admitted next) => checked := next
      | .ok .deferred => deferred := declaration :: deferred
      | .error error => throw (IO.userError error.message)
    pending := deferred.reverse
    bootstrapRequire (decide (pending.length < before))
      ("unresolved declaration dependencies: " ++
        String.intercalate ", " (pending.map (psNameToString ∘ psDeclarationName)))
  return checked

private def bootstrapCheckMetadata (native : Lean.Environment)
    (checked : Lean.Kernel.Environment) (declaration : PsDeclaration) : IO Nat := do
  let name := PsKernelLean.toLeanName (psDeclarationName declaration)
  let some actual := checked.find? name
    | throw (IO.userError ("BOOTSTRAP: missing checked declaration " ++ toString name))
  let expectedType ← bootstrapExpr (psDeclarationType declaration)
  bootstrapRequire
    (actual.levelParams == PsKernelLean.toLeanNames (psDeclarationLevelParams declaration) &&
      actual.type == expectedType && !actual.isUnsafe && !actual.isPartial)
    ("checked signature or safety differs: " ++ toString name)
  match declaration, actual with
  | .definitionDecl _ _ _ value, .defnInfo info =>
      bootstrapRequire (info.value == (← bootstrapExpr value))
        ("checked definition body differs: " ++ toString name)
      return 0
  | .theoremDecl _ _ _ value, .thmInfo info =>
      bootstrapRequire (info.value == (← bootstrapExpr value))
        ("checked theorem proof differs: " ++ toString name)
      return 0
  | .opaqueDecl _ _ _ value, .opaqueInfo info =>
      bootstrapRequire (info.value == (← bootstrapExpr value))
        ("checked opaque body differs: " ++ toString name)
      return 0
  | .inductiveDecl expected, .inductInfo info =>
      bootstrapRequire
        (info.numParams == expected.numParams && info.numIndices == expected.numIndices &&
          info.ctors == PsKernelLean.toLeanNames expected.constructors &&
          info.all == [name] && info.numNested == 0 &&
          expected.isStructure == Lean.isStructure native name)
        ("inductive family metadata differs: " ++ toString name)
      return 0
  | .constructorDecl expected, .ctorInfo info =>
      let recursivePositions ← match bootstrapRecursiveFields info.induct info.numParams
          info.numFields info.type with
        | .ok value => pure value
        | .error error => throw (IO.userError error)
      bootstrapRequire
        (info.induct == PsKernelLean.toLeanName expected.inductiveName &&
          info.cidx == expected.constructorIndex && info.numParams == expected.numParams &&
          info.numFields == expected.numFields && recursivePositions == expected.recursiveFields)
        ("constructor metadata differs: " ++ toString name)
      return 0
  | .recursorDecl expected, .recInfo info =>
      bootstrapRequire
        (info.all == PsKernelLean.toLeanNames expected.inductiveNames &&
          info.numParams == expected.numParams && info.numIndices == expected.numIndices &&
          info.numMotives == expected.numMotives && info.numMinors == expected.numMinors)
        ("recursor metadata differs: " ++ toString name)
      return info.rules.length
  | _, _ =>
      throw (IO.userError ("BOOTSTRAP: unexpected declaration kind: " ++ toString name))

private def bootstrapNativeStatus (native : Lean.Environment) (name : Lean.Name) :
    PsReducibility :=
  match Lean.getReducibilityStatusCore native name with
  | .reducible => .reducible
  | .semireducible => .semireducible
  | .irreducible => .irreducible
  | .instanceReducible => .instanceReducible
  | .implicitReducible => .implicitReducible

def main (args : List String) : IO Unit := do
  let [sourcePath, manifestPath] := args
    | throw (IO.userError "usage: pscv0_bootstrap_replay SOURCE.lean MANIFEST.json")
  bootstrapRequire
    (Lean.githash == "eb6cafb7290e8bd5f2937522d8d804f58f02bafc")
    "pinned native toolchain differs"
  let source ← IO.FS.readFile (System.FilePath.mk sourcePath)
  bootstrapRequire (source.utf8ByteSize == 118573) "generated source byte count differs"
  bootstrapRequire
    (psStandardSnapshotSHA256 source ==
      "05fd8f7917054c52b66d8d448bdeeb8e9071fcd6d21d0a6ded088a758628da54")
    "generated source identity differs"
  let declarations := psCoreBootstrapCandidateDeclarations
  let names := declarations.map (PsKernelLean.toLeanName ∘ psDeclarationName)
  bootstrapRequire (declarations.length == 76 && names.eraseDups.length == 76)
    "declaration roster is not the measured 76 unique names"
  bootstrapRequire psCoreBootstrapCandidateBoundary.isEmpty "boundary is not empty"
  bootstrapRequire
    (!(declarations.any fun declaration =>
      match declaration with | .axiomDecl .. => true | _ => false))
    "unexpected assumption"
  let environment := psBootstrapEnvironment
  bootstrapRequire (environment.declarations.length == 76) "composition changed the roster"
  for declaration in declarations do
    let some installed := psEnvironmentFind environment (psDeclarationName declaration)
      | throw (IO.userError "BOOTSTRAP: composition lost a declaration")
    bootstrapRequire
      (psStandardSnapshotDeclaration installed == psStandardSnapshotDeclaration declaration)
      ("composition changed declaration: " ++ psNameToString (psDeclarationName declaration))
  let statusNames := psCoreBootstrapCandidateReducibility.map
    (PsKernelLean.toLeanName ∘ Prod.fst)
  bootstrapRequire (statusNames.eraseDups.length == statusNames.length)
    "duplicate reducibility entry"
  let definitionNames := declarations.filterMap fun declaration =>
    match declaration with
    | .definitionDecl name .. => some (PsKernelLean.toLeanName name)
    | _ => none
  bootstrapRequire
    (statusNames.length == definitionNames.length &&
      statusNames.all definitionNames.contains)
    "reducibility roster does not match definition roster"
  Lean.initSearchPath (← Lean.findSysroot)
  let native ← Lean.importModules #[{ module := `Init }] {}
  for (name, status) in psCoreBootstrapCandidateReducibility do
    bootstrapRequire
      (psReducibilityName (psEnvironmentReducibility environment name) ==
        psReducibilityName status &&
        psReducibilityName status ==
          psReducibilityName (bootstrapNativeStatus native (PsKernelLean.toLeanName name)))
      ("source reducibility differs: " ++ psNameToString name)
  let checked ← bootstrapReplay declarations
  let checkedNames := checked.constants.toList.map Prod.fst
  bootstrapRequire
    (checkedNames.length == names.length && checkedNames.all names.contains)
    "replay contains missing or extra declarations"
  let mut rules := 0
  for declaration in declarations do
    rules := rules + (← bootstrapCheckMetadata native checked declaration)
  bootstrapRequire (rules == 24) "regenerated rule count differs"
  bootstrapRequire
    (environment.classes.isEmpty && environment.classParameters.isEmpty &&
      environment.instances.entries.isEmpty && environment.instances.defaults.isEmpty &&
      environment.exportedAliases.isEmpty)
    "declaration-only composition installed an unreviewed source registry"
  let payload := psStandardSnapshotPayload environment
  let manifest := Lean.Json.mkObj [
    ("schema", Lean.toJson ("pscv0-bootstrap-replay/1" : String)),
    ("nativeCommit", Lean.toJson Lean.githash),
    ("sourceBytes", Lean.toJson source.utf8ByteSize),
    ("sourceSHA256", Lean.toJson (psStandardSnapshotSHA256 source)),
    ("canonicalPayloadBytes", Lean.toJson payload.utf8ByteSize),
    ("canonicalPayloadSHA256", Lean.toJson (psStandardSnapshotSHA256 payload)),
    ("canonicalPayloadFNV64", Lean.toJson (psStandardSnapshotFNV64 payload)),
    ("declarations", Lean.toJson declarations.length),
    ("names", Lean.toJson (names.map toString)),
    ("axioms", Lean.toJson ([] : List String)),
    ("regeneratedRecursorRules", Lean.toJson rules),
    ("reducibilityEntries", Lean.toJson statusNames.length),
    ("emptyBoundary", Lean.toJson true),
    ("kernelTrustLevel", Lean.toJson (0 : Nat)),
    ("maxHeartbeatsPerDeclaration", Lean.toJson (2000000 : Nat)),
    ("maxRecDepthPerDeclaration", Lean.toJson (20000 : Nat)),
    ("sourceRegistriesSelected", Lean.toJson false),
    ("compilerDefaultSelected", Lean.toJson false),
    ("coreCompletenessClaimed", Lean.toJson false)]
  IO.FS.writeFile (System.FilePath.mk manifestPath) (manifest.compress ++ "\n")
  IO.println manifest.compress
  IO.println "PSCV0_BOOTSTRAP_REPLAY: PASS exact 76 declarations, empty trust-zero replay, 24 regenerated rules, finite budgets, preserved family metadata and reducibility"
