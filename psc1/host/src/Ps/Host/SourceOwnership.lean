import Ps.Compiler.Service
import Ps.Host.ProjectCompiler
import Ps.CompilerIr.Validate
import Lean.Data.Json

/-! Read-only ownership from the production elaborator's actual output.
This host-only adapter is outside the portable compiler closure. -/

open Ps.Internal.CompilerService

def psOwnershipPosition (p : PsSourcePos) : Lean.Json :=
  Lean.Json.mkObj [("byteOffset", Lean.toJson p.byteOffset),
    ("line", Lean.toJson p.line), ("column", Lean.toJson p.column)]

def psOwnershipSpan (s : PsSourceSpan) : Lean.Json :=
  Lean.Json.mkObj [("start", psOwnershipPosition s.start), ("stop", psOwnershipPosition s.stop)]

-- Tagged components retain the distinction between numeric and string names.
def psOwnershipName : PsName → List Lean.Json
  | .anonymous => []
  | .str parent value => psOwnershipName parent ++ [Lean.toJson (["s", value] : List String)]
  | .num parent value => psOwnershipName parent ++ [Lean.toJson (["n", toString value] : List String)]

def psOwnershipRole : PsElabOriginRole → String
  | .sourceDeclaration => "sourceDeclaration"
  | .inductiveType => "inductiveType"
  | .structureType => "structureType"
  | .constructor => "constructor"
  | .recursor => "recursor"
  | .normalizedWorker => "normalizedWorker"
  | .publicWrapper => "publicWrapper"

def psOwnershipPhase : PsElabOriginPhase → String
  | .stableDeclaration => "stableDeclaration"
  | .normalizationPlanning => "normalizationPlanning"
  | .normalizedWorker => "normalizedWorker"
  | .publicWrapper => "publicWrapper"
  | .declarationInsertion => "declarationInsertion"

def psOwnershipOrigin (origin : PsElabBatchOrigin) : Lean.Json :=
  Lean.Json.mkObj [
    ("sourceIndex", Lean.toJson origin.sourceIndex),
    ("sourceName", Lean.toJson origin.sourceName.segments),
    ("nameSpan", psOwnershipSpan origin.sourceName.span),
    ("span", psOwnershipSpan origin.span),
    ("members", Lean.toJson (origin.members.map fun member => Lean.Json.mkObj [
      ("index", Lean.toJson member.index), ("name", Lean.toJson (psOwnershipName member.name)),
      ("displayName", Lean.toJson (psNameToString member.name)),
      ("role", Lean.toJson (psOwnershipRole member.role))])),
    ("normalization", match origin.normalization with
      | none => .null
      | some value => Lean.Json.mkObj [
          ("workerName", Lean.toJson (psOwnershipName value.workerName)),
          ("span", psOwnershipSpan value.span)])]

def psOwnershipError (moduleName phase detail : String)
    (origin : Option PsElabOriginError := none) : Lean.Json :=
  Lean.Json.mkObj [("module", .str moduleName), ("phase", .str phase),
    ("detail", .str detail), ("origin", match origin with
      | none => .null
      | some value => Lean.Json.mkObj [
          ("sourceIndex", Lean.toJson value.sourceIndex),
          ("sourceName", Lean.toJson value.sourceName.segments),
          ("span", psOwnershipSpan value.span),
          ("phase", .str (psOwnershipPhase value.phase))])]

/-- One actual elaboration per module. No second resolver, parser or compiler. -/
def psOwnershipCapture (request : Request) :
    Except Lean.Json (Captured × Array Lean.Json) := do
  let mut captured := Captured.mk (psCompilerPreparationStart request.kind) [] [] [] none
  let mut rows : Array Lean.Json := #[]
  for source in request.sources do
    if captured.seen.contains source.moduleName then
      throw (psOwnershipError source.moduleName "capture" "duplicate-module")
    let parsed ← (psCompilerParseSource request.kind source.text).mapError
      (fun _ => psOwnershipError source.moduleName "parse" "source-refused")
    let imports := parsed.imports.map (fun i => String.intercalate "." i.moduleName.segments)
    if imports.any (fun name => !captured.seen.contains name) then
      throw (psOwnershipError source.moduleName "capture" "import-order-or-missing")
    let next ← (psCompilerPreparationStepParsedWithOrigins captured.state parsed).mapError
      (fun error => psOwnershipError source.moduleName "elaboration"
        (psHostElabErrorText error.error) (some error))
    -- Check coverage against the declarations returned by that same execution.
    let names := next.origins.flatMap (fun origin => origin.members.map (fun member => member.name))
    let count := next.state.declarationsRev.length - captured.state.declarationsRev.length
    let actual := (next.state.declarationsRev.take count).reverse.map psDeclarationName
    if names.length != actual.length || !(names.zip actual).all (fun pair => psNameEq pair.1 pair.2) ||
        next.origins.length != parsed.declarations.length then
      throw (psOwnershipError source.moduleName "ownership" "actual-batch-mismatch")
    rows := rows.push (Lean.Json.mkObj [
      ("module", .str source.moduleName), ("byteLength", Lean.toJson source.text.utf8ByteSize),
      ("imports", Lean.toJson imports), ("sourceDeclarations", Lean.toJson parsed.declarations.length),
      ("origins", Lean.toJson (next.origins.map psOwnershipOrigin))])
    captured := Captured.mk next.state (source.moduleName :: captured.seen)
      ((source.moduleName, imports) :: captured.graphRev) []
      (if source.moduleName == request.entry then some parsed else captured.entry)
  if captured.entry.isNone then throw (psOwnershipError request.entry "capture" "entry-missing")
  let _ ← (exactClosureWorker captured.graphRev [request.entry]).mapError
    (fun error => psOwnershipError error.moduleName error.phase error.code)
  return (captured, rows)

def psOwnershipPrepare (request : Request) (captured : Captured) :
    Except Lean.Json Semantic := do
  let semantic ← (prepare request captured).mapError
    (fun error => psOwnershipError error.moduleName error.phase error.code)
  let _ ← (psStrictValidateModule semantic.raw).mapError
    (fun _ => psOwnershipError "" "strict-ir" "refused")
  return semantic


/-- Conversion reuses the existing frontend/printer. Admission is a separate
before/after host obligation; this function grants no editing authority. -/
def psOwnershipConvert (request : Request) (target : PsCompilerSourceKind)
    (grammar : String) : Except Lean.Json Lean.Json := do
  let mut modules : Array Lean.Json := #[]
  for source in request.sources do
    let text ← (psCompilerTranslateSource request.kind target source.text).mapError
      (fun _ => psOwnershipError source.moduleName "translation" "unsupported-or-invalid-source")
    if text.utf8ByteSize > 1048576 then
      throw (psOwnershipError source.moduleName "translation" "source-limit")
    let parsed ← (psCompilerParseSource target text).mapError
      (fun _ => psOwnershipError source.moduleName "translation" "printed-source-parse-refused")
    let declarations := parsed.declarations.map (fun declaration =>
      let origin := psElabOriginSource declaration
      Lean.Json.mkObj [("sourceName", Lean.toJson origin.1.segments),
        ("span", psOwnershipSpan origin.2)])
    modules := modules.push (Lean.Json.mkObj [("module", .str source.moduleName),
      ("text", .str text), ("declarations", Lean.toJson declarations)])
  return Lean.Json.mkObj [
    ("protocol", .str "psc1-source-conversion/1"), ("status", .str "candidate"),
    ("requestId", .str request.requestId), ("sourceClosureDigest", .str request.sourceClosureDigest),
    ("sourceGrammar", .str request.grammar), ("targetGrammar", .str grammar),
    ("modules", .arr modules)]
