// Array universe-family digests independently measured by strict CI38734094047.
import Ps.Host.NativeV7
import Ps.Environment.StandardSnapshot
import Ps.Syntax.Pscv0.Operators
import Ps.Elab.Deriving

/-!
Native M2+A Standard surface manifest. The already strict, independently
measured declaration/instance/alias/reducibility roster is the authority for
those sections. This separately inventories *selected* surface notations,
deriving handlers, tactics and typed effects, with explicit unsupported
boundaries; it is not a claim of Lean-wide parity.

References pinned at Lean 4.35.0 (eb6cafb7290e8bd5f2937522d8d804f58f02bafc):
Init/Notation.lean, Lean/Parser/Term.lean, Lean/Meta/SynthInstance.lean,
Lean/Elab/Deriving/Basic.lean, Init/Data/Float/* and Init/System/Platform.lean.
-/

namespace PsV7Native

structure ManifestNotation where
  token : String
  kind : String
  precedence : Nat
  rightPrecedence : Nat
  nonAssociative : Bool
  deriving Repr

-- Paired with the *real* closed parser registry psPscv0InfixInfo.
-- This ledger is explicitly checked for status and precedence drift.
def selectedNotations : List ManifestNotation := [
  { token := "=", kind := "Eq", precedence := 50,
    rightPrecedence := 51, nonAssociative := true },
  { token := "==", kind := "BEq.beq", precedence := 50,
    rightPrecedence := 51, nonAssociative := true },
  { token := "!=", kind := "booleanNotEqual", precedence := 50,
    rightPrecedence := 51, nonAssociative := true },
  { token := "∧", kind := "And", precedence := 35,
    rightPrecedence := 35, nonAssociative := false },
  { token := "/\\", kind := "And", precedence := 35,
    rightPrecedence := 35, nonAssociative := false },
  { token := "∨", kind := "Or", precedence := 30,
    rightPrecedence := 30, nonAssociative := false },
  { token := "\\/", kind := "Or", precedence := 30,
    rightPrecedence := 30, nonAssociative := false },
  { token := "&&", kind := "booleanAnd", precedence := 35,
    rightPrecedence := 36, nonAssociative := false },
  { token := "||", kind := "booleanOr", precedence := 30,
    rightPrecedence := 31, nonAssociative := false },
  { token := "↔", kind := "Iff", precedence := 20,
    rightPrecedence := 21, nonAssociative := true },
  { token := "<->", kind := "Iff", precedence := 20,
    rightPrecedence := 21, nonAssociative := true },
  { token := "×", kind := "Prod", precedence := 35,
    rightPrecedence := 35, nonAssociative := false },
  { token := "::", kind := "List.cons", precedence := 67,
    rightPrecedence := 67, nonAssociative := false },
  { token := "+", kind := "HAdd.hAdd", precedence := 65,
    rightPrecedence := 66, nonAssociative := false },
  { token := "++", kind := "HAppend.hAppend", precedence := 65,
    rightPrecedence := 66, nonAssociative := false },
  { token := "-", kind := "HSub.hSub", precedence := 65,
    rightPrecedence := 66, nonAssociative := false },
  { token := "*", kind := "HMul.hMul", precedence := 70,
    rightPrecedence := 71, nonAssociative := false },
  { token := "/", kind := "HDiv.hDiv", precedence := 70,
    rightPrecedence := 71, nonAssociative := false },
  { token := "%", kind := "HMod.hMod", precedence := 70,
    rightPrecedence := 71, nonAssociative := false },
  { token := "→", kind := "arrow", precedence := 25,
    rightPrecedence := 25, nonAssociative := false },
  { token := "->", kind := "arrow", precedence := 25,
    rightPrecedence := 25, nonAssociative := false },
  { token := "matches", kind := "matches", precedence := 50,
    rightPrecedence := 51, nonAssociative := true }
]

def notationKind : PsPscv0InfixKind → String
  | .constant name => name
  | .arrow => "arrow"
  | .booleanAnd => "booleanAnd"
  | .booleanOr => "booleanOr"
  | .booleanNotEqual => "booleanNotEqual"
  | .matches => "matches"

-- This is a ledger of selected public handlers, not an automatic registration
-- mechanism and not authorization to accept arbitrary deriving names.
def selectedDeriving : List String :=
  ["Inhabited", "BEq", "DecidableEq", "Repr", "Hashable"]

-- Real surface spelling in Ps.Syntax.Pscv0.ProofRead; each elaborated proof
-- term is still checked by the pinned official Lean kernel.
def selectedTactics : List String :=
  ["exact", "refine", "apply", "cases", "induction", "case", "next",
   "have", "let", "change", "show", "intro", "assumption", "rfl",
   "constructor", "·", "focus", "all_goals", "any_goals"]

-- Source do-block rewrite currently admits explicit Except-typed results.
-- The broader elaborator separately supports bounded Id/Option/Except cases;
-- no general State/IO/FFI coverage is claimed by these entries.
def selectedSourceEffects : List String := ["Except"]
def selectedElabEffects : List String := ["Id", "Option", "Except"]
def selectedModuleBehaviors : List String :=
  ["named-import-closure", "ordered-interfaces", "private-export-hygiene",
   "kernel-checked-project-linking"]

def unqualifiedM2AFeatures : List String :=
  ["Float/Float32 F3 scientific/conversions and F4 complete qualification",
   "USize/ISize explicit target word profiles",
   "remaining deriving and class-search semantic boundaries",
   "full Lean module/notation/tactic/effect closure",
   "backend-wide semantic preservation proof"]

-- Canonical length-delimited human-surface snapshot. This digest is
-- independent of the existing kernel declaration and metadata snapshot:
-- notation/deriving/selected tactics and effect policy are included here.
-- A per-project resolved import graph is *not* part of this global manifest.
private def manifestInstanceKey (entry : PsInstanceEntry) : String :=
  match entry.value with
  | .constE name _ => psNameToString name
  | other => psStandardSnapshotExpr other

private def manifestInstancePayload (entry : PsInstanceEntry) : String :=
  psStandardSnapshotNode "registeredInstance" [
    manifestInstanceKey entry,
    toString entry.priority,
    (entry.className.map psNameToString).getD "",
    psStandardSnapshotList psStandardSnapshotName entry.levelParams]

private def manifestNotationPayload (entry : ManifestNotation) : String :=
  psStandardSnapshotNode "notation" [
    entry.token, entry.kind, toString entry.precedence,
    toString entry.rightPrecedence, psStandardSnapshotBool entry.nonAssociative]

def standardSurfaceManifestPayload (env : PsEnvironment) : String :=
  psStandardSnapshotNode "PSCV0-SELECTED-SOURCE-SURFACE-v1" [
    leanVersion, leanCommit,
    psStandardSnapshotSHA256Fingerprint env,
    psStandardSnapshotList manifestNotationPayload selectedNotations,
    psStandardSnapshotList id selectedDeriving,
    psStandardSnapshotList id selectedTactics,
    psStandardSnapshotList id selectedSourceEffects,
    psStandardSnapshotList id selectedElabEffects,
    psStandardSnapshotList id selectedModuleBehaviors,
    psStandardSnapshotList manifestInstancePayload env.instances.entries]

def standardSurfaceManifestSHA256 (env : PsEnvironment) : String :=
  "sha256:" ++ psStandardSnapshotSHA256 (standardSurfaceManifestPayload env)

-- Independently measured together with both declaration pins by the strict
-- registry refusal at 49a38a11 / native CI38730889997 (F2).
def standardSurfaceManifestExpectedSHA256 : String :=
  "sha256:579f461576427a5daf711943613979e4517803475779e40b0200f359450744fa"

private def manifestInstanceJson (entry : PsInstanceEntry) (rank : Nat) :
    Lean.Json :=
  Lean.Json.mkObj [
    ("rank", Lean.toJson rank),
    ("identity", Lean.toJson (manifestInstanceKey entry)),
    ("class", Lean.toJson ((entry.className.map psNameToString).getD "")),
    ("priority", Lean.toJson entry.priority),
    ("universes", Lean.toJson (entry.levelParams.map psNameToString))]

-- Every selected operator from this audited catalog MUST resolve to exactly
-- the documented live parser precedence/target. A new source spelling is not
-- silently admitted to this frozen manifest.
def selectedNotationAudit : Except String Unit := do
  if (selectedNotations.map (·.token)).eraseDups.length !=
      selectedNotations.length then
    throw "PSCV0-MANIFEST: duplicate selected notation"
  for entry in selectedNotations do
    let some live := psPscv0InfixInfo entry.token
      | throw ("PSCV0-MANIFEST: notation missing: " ++ entry.token)
    if notationKind live.kind != entry.kind ||
        live.precedence != entry.precedence ||
        live.rightPrecedence != entry.rightPrecedence ||
        live.nonAssociative != entry.nonAssociative then
      throw ("PSCV0-MANIFEST: notation drift: " ++ entry.token)
  if (psPscv0InfixInfo "?").isSome then
    throw "PSCV0-MANIFEST: unregistered notation unexpectedly admitted"

-- Lean 4.35.0 Meta/Instances.mkInstanceKey and checkNonClassInstance
-- reduce the entire Pi telescope before computing the result-class key.
-- Static Standard builders supply keys explicitly; audit the same invariant
-- once here so a reducible alias cannot silently hide a valid instance.
def standardInstanceIndexAudit (env : PsEnvironment) : Except String Unit := do
  for entry in env.instances.entries do
    let identity := manifestInstanceKey entry
    let some key := entry.className
      | throw ("PSCV0-MANIFEST: unclassified Standard instance " ++ identity)
    let prepared := psPrepareInstance env psLocalEmpty psMetaEmpty entry
    if !prepared.success then
      throw ("PSCV0-MANIFEST: instance telescope incomplete " ++ identity)
    let .constE resultClass _ := (psInferAppView prepared.resultType).head
      | throw ("PSCV0-MANIFEST: instance result is not a class " ++ identity)
    if !env.classes.any (psNameEq resultClass) || !psNameEq key resultClass then
      throw ("PSCV0-MANIFEST: instance class key mismatch " ++ identity ++
        "; registered " ++ psNameToString key ++ "; reduced " ++ psNameToString resultClass)

def standardSurfaceManifestAudit (env : PsEnvironment) :
    Except String Unit := do
  standardInstanceIndexAudit env
  -- Reuse, do not replace, the independently pinned dual registry hashes.
  match psStandardSnapshotValidate env psStandardSnapshotExpected with
  | .ok () => pure ()
  | .error message =>
      -- Authoring diagnostics report every dependent pin in the first refused
      -- run. This remains a hard error; no candidate is admitted or emitted.
      throw (message ++ "; surface SHA-256 candidate " ++
        standardSurfaceManifestSHA256 env)
  selectedNotationAudit
  if env.declarations.isEmpty || env.classes.isEmpty ||
      env.instances.entries.isEmpty then
    throw "PSCV0-MANIFEST: empty selected declaration/class/instance roster"
  if selectedDeriving.eraseDups.length != selectedDeriving.length ||
      selectedTactics.eraseDups.length != selectedTactics.length then
    throw "PSCV0-MANIFEST: duplicate surface registration"
  if selectedDeriving != psElabSelectedDerivingHandlers then
    throw "PSCV0-MANIFEST: deriving handler registry drift"
  if selectedSourceEffects.isEmpty || selectedElabEffects.isEmpty then
    throw "PSCV0-MANIFEST: empty selected effect policy"
  let observed := standardSurfaceManifestSHA256 env
  if observed != standardSurfaceManifestExpectedSHA256 then
    throw ("PSCV0-MANIFEST: surface registry drift; expected " ++
      standardSurfaceManifestExpectedSHA256 ++ " got " ++ observed)

private def notationJson (entry : ManifestNotation) : Lean.Json :=
  Lean.Json.mkObj [
    ("token", Lean.toJson entry.token),
    ("target", Lean.toJson entry.kind),
    ("precedence", Lean.toJson entry.precedence),
    ("rightPrecedence", Lean.toJson entry.rightPrecedence),
    ("nonAssociative", Lean.toJson entry.nonAssociative)]

def standardSurfaceManifestJson (env : PsEnvironment) : Lean.Json :=
  let knownAxioms : List String := env.declarations.filterMap fun declaration =>
    match declaration with
    | .axiomDecl name _ _ => some (psNameToString name)
    | _ => none
  Lean.Json.mkObj [
    ("schema", Lean.toJson ("pscv0-selected-standard-surface/1" : String)),
    ("leanVersion", Lean.toJson leanVersion),
    ("leanCommit", Lean.toJson leanCommit),
    ("selectedStandardFNV", Lean.toJson (psStandardSnapshotFingerprint env)),
    ("selectedStandardSHA256", Lean.toJson (psStandardSnapshotSHA256Fingerprint env)),
    ("selectedSurfaceSHA256", Lean.toJson (standardSurfaceManifestSHA256 env)),
    ("surfacePayloadFormat", Lean.toJson ("PSCV0-SELECTED-SOURCE-SURFACE-v1" : String)),
    ("projectImportGraph", Lean.toJson ("validated-per-project-not-global" : String)),
    ("declarations", Lean.toJson env.declarations.length),
    ("classes", Lean.toJson (env.classes.map psNameToString)),
    ("orderedInstances", Lean.toJson env.instances.entries.length),
    ("instanceRegistrations", Lean.Json.arr
      ((env.instances.entries.zipIdx.map fun (entry, rank) =>
        manifestInstanceJson entry rank).toArray)),
    ("registeredAxioms", Lean.toJson knownAxioms),
    ("selectedNotation", Lean.Json.arr (selectedNotations.map notationJson).toArray),
    ("selectedDeriving", Lean.toJson selectedDeriving),
    ("selectedTactics", Lean.toJson selectedTactics),
    ("sourceEffects", Lean.toJson selectedSourceEffects),
    ("boundedElaborationEffects", Lean.toJson selectedElabEffects),
    ("moduleBehaviors", Lean.toJson selectedModuleBehaviors),
    ("notYetQualified", Lean.toJson unqualifiedM2AFeatures)]

end PsV7Native
