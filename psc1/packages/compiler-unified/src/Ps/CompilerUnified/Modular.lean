import Ps.Compiler.Service
import Ps.BackendCommon.ExecutablePlan
import Ps.BackendJs.ModuleFiles
import Ps.BackendTs.ModuleFiles
import Ps.CompilerIr.WorkerFusion

/-! Portable compiler-owned module generation. Captured elaborator member names
retain their tagged PsName identity; erased and synthetic owners come from exact
producer provenance. Output is candidate data only. A host must independently
admit the exact Core, verify every file/bound and recheck the graph before import.
No filesystem, checker, SDK or publication capability enters this module. -/

namespace Ps.Internal.ModularCompiler
open Ps.Internal.CompilerService

structure CapturedModules where
  captured : Captured
  owners : PsStringMap Nat

def nameKey : PsName -> String
  | .anonymous => "a"
  | .str parent value =>
      nameKey parent ++ "s" ++ psNatToString value.utf8ByteSize ++ ":" ++ value
  | .num parent value => nameKey parent ++ "n" ++ psNatToString value ++ ";"

def captureModules (sources : List Source) (request : Request) (unit : Nat)
    (current : CapturedModules) : Except String CapturedModules := do
  match sources with
  | [] => return current
  | source :: rest =>
    let captured := current.captured
    if captured.seen.contains source.moduleName then throw "PSC1_EXECUTABLE_DUPLICATE_SOURCE"
    let parsed ← (psCompilerParseSource request.kind source.text).mapError
      (fun _ => "PSC1_EXECUTABLE_SOURCE_PARSE:" ++ source.moduleName)
    let imports := parsed.imports.map (fun item => String.intercalate "." item.moduleName.segments)
    if imports.any (fun name => !captured.seen.contains name) then
      throw "PSC1_EXECUTABLE_SOURCE_IMPORT_ORDER"
    let next ← (psCompilerPreparationStepParsedWithOrigins captured.state parsed).mapError
      (fun _ => "PSC1_EXECUTABLE_SOURCE_ELABORATION:" ++ source.moduleName)
    let names := next.origins.flatMap (fun origin => origin.members.map (fun member => member.name))
    let count := next.state.declarationsRev.length - captured.state.declarationsRev.length
    let actual := (next.state.declarationsRev.take count).reverse.map psDeclarationName
    if names.length != actual.length || !(names.zip actual).all (fun pair => psNameEq pair.1 pair.2) ||
        next.origins.length != parsed.declarations.length then
      throw "PSC1_EXECUTABLE_ACTUAL_BATCH_MISMATCH"
    let mut owners := current.owners
    for name in names do
      let key := nameKey name
      if psStringMapContains owners key then throw "PSC1_EXECUTABLE_DUPLICATE_SOURCE_ORIGIN"
      owners := psStringMapPut owners key unit
    let updated := Captured.mk next.state (source.moduleName :: captured.seen)
      ((source.moduleName, imports) :: captured.graphRev) []
      (if source.moduleName == request.entry then some parsed else captured.entry)
    captureModules rest request (unit + 1) (CapturedModules.mk updated owners)

def originalOwners (semantic : Semantic) (authored : PsStringMap Nat) :
    Except String (List PsModuleOwner) := do
  let names := psErasureDeclarationNames
    (psErasureRuntimeDeclarations psSelfHostRuntimePreludeDeclarationsWithProd semantic.source)
  let mut erased : PsStringMap PsName := .empty
  for row in names do
    if psStringMapContains erased row.snd then throw ("PSC1_MODULE_ERASURE_OWNER:" ++ row.snd)
    erased := psStringMapPut erased row.snd row.fst
  let prelude := psStringSetFromList (psSelfHostRuntimePreludeDeclarationsWithProd.map
    (fun declaration => nameKey (psDeclarationName declaration)))
  semantic.raw.declarations.mapM fun declaration => do
    let some source := psStringMapGet erased declaration.name
      | throw ("PSC1_MODULE_ERASURE_OWNER:" ++ declaration.name)
    let key := nameKey source
    let unit ← match psStringMapGet authored key with
      | .some index => pure index
      | .none =>
        if psStringSetContains prelude key then pure 0
        else throw ("PSC1_MODULE_UNKNOWN_OWNER:" ++ declaration.name)
    return PsModuleOwner.mk declaration.name unit

def ownerJson (owner : PsModuleOwner) : String :=
  psJsonArray [psJsonQuote owner.name, psNatToString owner.unit]

def importJson (item : PsModuleImport) : String :=
  psJsonObject [("source", psJsonQuote item.source),
    ("names", psJsonArray (item.names.map psJsonQuote)),
    ("typeOnly", if item.typeOnly then "true" else "false")]

def artifactJson (kind : String) (artifact : PsModuleArtifact) : String :=
  psJsonObject [("unit", psNatToString artifact.unit),
    ("file", psJsonQuote (kind ++ "/unit-" ++ psNatToString artifact.unit ++
      (if kind == "js" then ".mjs" else ".mts"))),
    ("imports", psJsonArray (artifact.imports.map importJson)),
    ("exports", psJsonArray (artifact.exports.map psJsonQuote))]

def checkedFileBytes (files : List (Prod String String)) (total : Nat) : Except String Unit := do
  match files with
  | [] => pure ()
  | item :: rest =>
    let size := item.snd.utf8ByteSize
    if size > 33554432 then throw "PSC1_EXECUTABLE_FILE_BOUND"
    let next := total + size
    if next > 134217728 then throw "PSC1_EXECUTABLE_STAGE_AGGREGATE_BOUND"
    checkedFileBytes rest next

def generate (request : Request) (specifiers : List String) :
    Except String (List (Prod String String)) := do
  if request.sources.length > 256 ||
      request.sources.any (fun source => source.text.utf8ByteSize > 1048576) ||
      specifiers.length != request.sources.length + 1 then
    throw "PSC1_EXECUTABLE_SOURCE_BOUND"
  let start := Captured.mk (psCompilerPreparationStart request.kind) [] [] [] none
  let captured ← captureModules request.sources request 1 (CapturedModules.mk start .empty)
  if captured.captured.entry.isNone then throw "PSC1_EXECUTABLE_ENTRY_MISSING"
  let _ ← (exactClosureWorker captured.captured.graphRev [request.entry]).mapError
    (fun error => "PSC1_EXECUTABLE_CAPTURE:" ++ error.code)
  let semantic ← (prepare request captured.captured).mapError
    (fun error => "PSC1_EXECUTABLE_PREPARATION:" ++ error.code)
  let original ← (psStrictValidateModule semantic.raw).mapError
    (fun _ => "PSC1_EXECUTABLE_ORIGINAL_IR")
  let owners ← originalOwners semantic captured.owners
  let specialized ← (psIrSpecializeValidatedModuleWithOrigins original).mapError
    psIrSpecializeDiagnosticText
  let specializedOwners ← psModuleCarryOwners original.raw owners specialized
  let fused ← psFuseClosedWorkersWithOrigins (.mk specialized.raw)
  let fusedOwners ← psModuleCarryOwners specialized.raw specializedOwners fused
  let (selected, sourceToUnit) ← Ps.Internal.ExecutablePlan.plan fused.raw fusedOwners specifiers
  let lowered ← (psJsLowerSpecializedModule selected.raw).mapError
    (fun _ => "PSC1_EXECUTABLE_JS_LOWER")
  let _ ← (psJsValidateModule lowered).mapError (fun _ => "PSC1_EXECUTABLE_JS_VALIDATE")
  let mut declarations : PsStringMap PsJsIrDeclaration := .empty
  for declaration in lowered.declarations do
    declarations := psStringMapPut declarations declaration.name declaration
  let brands := psTsBuildBrandMap selected.raw
  let tags := psTsBuildTagMap selected.raw
  let mut files : List (Prod String String) := []
  let mut jsRows : List String := []
  let mut tsRows : List String := []
  for unit in selected.units do
    let ordered ← unit.declarations.mapM fun item =>
      match psStringMapGet declarations item.name with
      | .some value => .ok value
      | .none => .error ("PSC1_EXECUTABLE_JS_DECLARATION:" ++ item.name)
    let unitPlan : PsModulePlan := { selected with
      owners := unit.declarations.map (fun declaration => PsModuleOwner.mk declaration.name unit.index) }
    let js ← Ps.Internal.ModularJs.renderUnit unitPlan
      { lowered with declarations := ordered } request.sourceClosureDigest unit
    let ts ← Ps.Internal.ModularTs.renderUnit selected request.sourceClosureDigest brands tags unit
    let suffix := "/unit-" ++ psNatToString unit.index
    files := ("js" ++ suffix ++ ".mjs", js.source) ::
      ("js" ++ suffix ++ ".d.mts", js.declarations) ::
      ("ts" ++ suffix ++ ".mts", ts.source) :: files
    jsRows := artifactJson "js" js :: jsRows
    tsRows := artifactJson "ts" ts :: tsRows
  let originalIr ← (psIrEncodeModule original.raw).mapError (fun _ => "PSC1_EXECUTABLE_ENCODE_ORIGINAL")
  let specializedIr ← (psIrEncodeModule specialized.raw).mapError (fun _ => "PSC1_EXECUTABLE_ENCODE_SPECIALIZED")
  let fusedIr ← (psIrEncodeModule fused.raw).mapError (fun _ => "PSC1_EXECUTABLE_ENCODE_FUSED")
  let capture := psJsonObject [
    ("schema", psJsonQuote "psc1-executable-capture/1"),
    ("requestId", psJsonQuote request.requestId),
    ("sourceClosureDigest", psJsonQuote request.sourceClosureDigest),
    ("grammar", psJsonQuote request.grammar), ("entry", psJsonQuote request.entry),
    ("assurance", psJsonQuote request.assurance),
    ("partialNames", psJsonArray (semantic.partialNames.map (fun name => psJsonQuote (psNameToString name)))),
    ("leanVersion", psJsonQuote "4.35.0"),
    ("leanCommit", psJsonQuote "eb6cafb7290e8bd5f2937522d8d804f58f02bafc"),
    ("sourceModules", psJsonArray (request.sources.map (fun source => psJsonQuote source.moduleName))),
    ("owners", psJsonArray (fusedOwners.map ownerJson)),
    ("logicalDeclarations", psNatToString semantic.logicalCount),
    ("counts", psJsonArray ([original.raw.declarations.length,
      specialized.raw.declarations.length, fused.raw.declarations.length].map psNatToString)),
    ("specializationOriginCount", psNatToString specialized.origins.length),
    ("workerOriginCount", psNatToString fused.origins.length),
    ("claim", psJsonQuote "candidate metadata; external official Lean admission required")]
  let modules := psJsonObject [
    ("schema", psJsonQuote "psc1-executable-compiler-emission/1"),
    ("sourceClosureDigest", psJsonQuote request.sourceClosureDigest),
    ("protocol", psJsonQuote selected.protocol),
    ("packages", psJsonArray (selected.packages.map psJsonQuote)),
    ("sourceToUnit", psJsonArray (sourceToUnit.map psNatToString)),
    ("owners", psJsonArray (selected.owners.map ownerJson)),
    ("units", psJsonArray (selected.units.map fun unit => psJsonObject [
      ("index", psNatToString unit.index),
      ("names", psJsonArray (unit.declarations.map (fun declaration => psJsonQuote declaration.name))),
      ("imports", psJsonArray (unit.imports.map ownerJson)),
      ("computedInitializers", psJsonArray ((unit.declarations.filter
        (fun declaration => !Ps.Internal.ExecutablePlan.early declaration)).map
          (fun declaration => psJsonQuote declaration.name)))])),
    ("js", psJsonArray jsRows.reverse), ("ts", psJsonArray tsRows.reverse),
    ("logicalAdmission", psJsonQuote "external-host-required"),
    ("strictIR", "true"), ("referenceFuel", "4096")]
  let referenceJs ← (psJsPrintModuleStackSafe lowered).mapError (fun _ => "PSC1_EXECUTABLE_REFERENCE_JS")
  let referenceTs ← (psTsEmitModule selected.raw).mapError (fun _ => "PSC1_EXECUTABLE_REFERENCE_TS")
  let runtime := psJsStringRuntimeSupport ++ psJsStackRuntimeSupport ++
    "\nexport { " ++ String.intercalate ", "
      (Ps.Internal.ModularJs.helpers.filter (fun name => name != "__ps$cohort")) ++ " };\n"
  let result := [
    ("original-ir.json", originalIr), ("specialized-ir.json", specializedIr),
    ("fused-ir.json", fusedIr), ("admissions.json", semantic.admissions),
    ("capture.json", capture), ("modules.json", modules),
    ("js-runtime.mjs", runtime), ("reference.mjs", referenceJs),
    ("reference.mts", referenceTs)] ++ files.reverse
  checkedFileBytes result 0
  return result

def refused (reason : String) : String :=
  psJsonObject [("protocol", psJsonQuote "psc1-modular-build/1"),
    ("status", psJsonQuote "refused"), ("candidateOnly", "true"),
    ("admission", psJsonQuote "not-run"), ("code", psJsonQuote reason)]

def decodeBuild (fields : List PsJsonValue) : Except String String := do
  match fields with
  | [.string protocol, .array requestFields, .array specifierValues] =>
    if protocol != "psc1-modular-build/1" then throw "PSC1_EXECUTABLE_PROTOCOL"
    let request ← (decodeRequestFields requestFields).mapError
      (fun error => "PSC1_EXECUTABLE_REQUEST:" ++ error.code)
    let specifiers ← specifierValues.mapM fun value =>
      match value with
      | .string text => .ok text
      | _ => .error "PSC1_EXECUTABLE_SPECIFIER"
    let files ← generate request specifiers
    return psJsonObject [("protocol", psJsonQuote "psc1-modular-build/1"),
      ("status", psJsonQuote "candidate"), ("candidateOnly", "true"),
      ("admission", psJsonQuote "not-run"),
      ("requestId", psJsonQuote request.requestId),
      ("sourceClosureDigest", psJsonQuote request.sourceClosureDigest),
      ("files", psJsonArray (files.map (fun file =>
        psJsonArray [psJsonQuote file.fst, psJsonQuote file.snd])))]
  | _ => throw "PSC1_EXECUTABLE_REQUEST_ARITY"

def candidate (input : String) : String :=
  match psJsonParse input with
  | .ok (.array fields) =>
    match decodeBuild fields with
    | .ok result => result
    | .error reason => refused reason
  | _ => refused "PSC1_EXECUTABLE_INVALID_JSON"

end Ps.Internal.ModularCompiler

