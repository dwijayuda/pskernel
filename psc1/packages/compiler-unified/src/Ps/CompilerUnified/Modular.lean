import Ps.Compiler.Service
import Ps.BackendCommon.ExecutablePlan
import Ps.BackendJs.ModuleFiles
import Ps.BackendTs.ModuleFiles
import Ps.CompilerIr.WorkerFusion

/-! Portable module generation uses the existing frontend, elaborator, checked
IR, transform provenance and structured renderers. Tagged names remain exact.
All output is quarantined candidate data; no checker or publication authority. -/
namespace Ps.Internal.ModularCompiler

structure CapturedModules where
  captured : Ps.Internal.CompilerService.Captured
  owners : PsStringMap Nat

def nameKey : PsName -> String
  | PsName.anonymous => "a"
  | PsName.str parent value =>
      psTextJoin "" [nameKey parent, "s", psNatToString (String.utf8ByteSize value), ":", value]
  | PsName.num parent value => psTextJoin "" [nameKey parent, "n", psNatToString value, ";"]

def captureModules (sources : List Ps.Internal.CompilerService.Source)
    (request : Ps.Internal.CompilerService.Request) (unit : Nat)
    (current : CapturedModules) : Except String CapturedModules := do
  match sources with
  | [] => do return current
  | source :: rest => do
    let captured := current.captured
    if psBackendNameSeen source.moduleName captured.seen then throw "PSC1_EXECUTABLE_DUPLICATE_SOURCE"
    let parsed ← psExceptMapError
      (fun _ => String.Internal.append "PSC1_EXECUTABLE_SOURCE_PARSE:" source.moduleName)
      (psCompilerParseSource request.kind source.text)
    let imports := psListMap (fun (item : PsSyntaxImport) =>
      psTextJoin "." item.moduleName.segments) parsed.imports
    if psListAny (fun (name : String) => !psBackendNameSeen name captured.seen) imports then
      throw "PSC1_EXECUTABLE_SOURCE_IMPORT_ORDER"
    let next ← psExceptMapError
      (fun _ => String.Internal.append "PSC1_EXECUTABLE_SOURCE_ELABORATION:" source.moduleName)
      (psCompilerPreparationStepParsedWithOrigins captured.state parsed)
    let names := psListFlatMap (fun (origin : PsElabBatchOrigin) =>
      psListMap (fun (member : PsElabMemberOrigin) => member.name) origin.members) next.origins
    let count := Nat.sub (psListLength next.state.declarationsRev)
      (psListLength captured.state.declarationsRev)
    let actual := psListMap psDeclarationName
      (psListReverse (psListTake count next.state.declarationsRev))
    if !(Nat.beq (psListLength names) (psListLength actual)) ||
        !psListAll (fun (pair : Prod PsName PsName) => psNameEq pair.fst pair.snd)
          (psListZip names actual) ||
        !(Nat.beq (psListLength next.origins) (psListLength parsed.declarations)) then
      throw "PSC1_EXECUTABLE_ACTUAL_BATCH_MISMATCH"
    let mut owners := current.owners
    for name in names do
      let key := nameKey name
      if psStringMapContains owners key then throw "PSC1_EXECUTABLE_DUPLICATE_SOURCE_ORIGIN"
      owners := psStringMapPut owners key unit
    let updated := Ps.Internal.CompilerService.Captured.mk next.state
      (List.cons source.moduleName captured.seen)
      (List.cons (Prod.mk source.moduleName imports) captured.graphRev) []
      (if psStringEq source.moduleName request.entry then Option.some parsed else captured.entry)
    captureModules rest request (Nat.succ unit) (CapturedModules.mk updated owners)

def originalOwners (semantic : Ps.Internal.CompilerService.Semantic) (authored : PsStringMap Nat) :
    Except String (List PsModuleOwner) := do
  let names := psErasureDeclarationNames
    (psErasureRuntimeDeclarations psSelfHostRuntimePreludeDeclarationsWithProd semantic.source)
  let mut erased : PsStringMap PsName := PsStringMap.empty
  for row in names do
    if psStringMapContains erased row.snd then
      throw (String.Internal.append "PSC1_MODULE_ERASURE_OWNER:" row.snd)
    erased := psStringMapPut erased row.snd row.fst
  let prelude := psStringSetFromList (psListMap
    (fun (declaration : PsDeclaration) => nameKey (psDeclarationName declaration))
    psSelfHostRuntimePreludeDeclarationsWithProd)
  psListMapExcept (fun (declaration : PsVerifiedIrDeclaration) => do
    let source ← match psStringMapGet erased declaration.name with
      | Option.some value => Except.ok value
      | Option.none => Except.error (String.Internal.append "PSC1_MODULE_ERASURE_OWNER:" declaration.name)
    let key := nameKey source
    let unit ← match psStringMapGet authored key with
      | Option.some index => Except.ok index
      | Option.none =>
        if psStringSetContains prelude key then Except.ok 0
        else Except.error (String.Internal.append "PSC1_MODULE_UNKNOWN_OWNER:" declaration.name)
    return PsModuleOwner.mk declaration.name unit) semantic.raw.declarations

def ownerJson (owner : PsModuleOwner) : String :=
  psJsonArray [psJsonQuote owner.name, psNatToString owner.unit]

def importJson (item : PsModuleImport) : String :=
  psJsonObject [("source", psJsonQuote item.source),
    ("names", psJsonArray (psListMap psJsonQuote item.names)),
    ("typeOnly", if item.typeOnly then "true" else "false")]

def artifactJson (kind : String) (artifact : PsModuleArtifact) : String :=
  psJsonObject [("unit", psNatToString artifact.unit),
    ("file", psJsonQuote (psTextJoin "" [kind, "/unit-", psNatToString artifact.unit,
      if psStringEq kind "js" then ".mjs" else ".mts"])),
    ("imports", psJsonArray (psListMap importJson artifact.imports)),
    ("exports", psJsonArray (psListMap psJsonQuote artifact.exports))]

def checkedFileBytes (files : List (Prod String String)) (total : Nat) : Except String Unit := do
  match files with
  | [] => do return ()
  | item :: rest => do
    let size := String.utf8ByteSize item.snd
    if Nat.blt 33554432 size then throw "PSC1_EXECUTABLE_FILE_BOUND"
    let next := Nat.add total size
    if Nat.blt 134217728 next then throw "PSC1_EXECUTABLE_STAGE_AGGREGATE_BOUND"
    checkedFileBytes rest next

def generate (request : Ps.Internal.CompilerService.Request) (specifiers : List String) :
    Except String (List (Prod String String)) := do
  if Nat.blt 256 (psListLength request.sources) ||
      psListAny (fun (source : Ps.Internal.CompilerService.Source) =>
        Nat.blt 1048576 (String.utf8ByteSize source.text)) request.sources ||
      !(Nat.beq (psListLength specifiers) (Nat.succ (psListLength request.sources))) then
    throw "PSC1_EXECUTABLE_SOURCE_BOUND"
  let start := Ps.Internal.CompilerService.Captured.mk
    (psCompilerPreparationStart request.kind) [] [] [] Option.none
  let captured ← captureModules request.sources request 1 (CapturedModules.mk start PsStringMap.empty)
  let absent := match captured.captured.entry with
    | Option.none => true
    | Option.some _ => false
  if absent then throw "PSC1_EXECUTABLE_ENTRY_MISSING"
  let _ ← psExceptMapError (fun (error : Ps.Internal.CompilerService.Error) =>
      String.Internal.append "PSC1_EXECUTABLE_CAPTURE:" error.code)
    (Ps.Internal.CompilerService.exactClosureWorker captured.captured.graphRev [request.entry])
  let semantic ← psExceptMapError (fun (error : Ps.Internal.CompilerService.Error) =>
      String.Internal.append "PSC1_EXECUTABLE_PREPARATION:" error.code)
    (Ps.Internal.CompilerService.prepare request captured.captured)
  let original ← psExceptMapError (fun _ => "PSC1_EXECUTABLE_ORIGINAL_IR")
    (psStrictValidateModule semantic.raw)
  let owners ← originalOwners semantic captured.owners
  let specialized ← psExceptMapError psIrSpecializeDiagnosticText
    (psIrSpecializeValidatedModuleWithOrigins original)
  let specializedOwners ← psModuleCarryOwners original.raw owners specialized
  let fused ← psFuseClosedWorkersWithOrigins (PsValidatedIrModule.mk specialized.raw)
  let fusedOwners ← psModuleCarryOwners specialized.raw specializedOwners fused
  let planning ← Ps.Internal.ExecutablePlan.plan fused.raw fusedOwners specifiers
  let selected := planning.fst
  let sourceToUnit := planning.snd
  let lowered ← psExceptMapError (fun _ => "PSC1_EXECUTABLE_JS_LOWER")
    (psJsLowerSpecializedModule selected.raw)
  let _ ← psExceptMapError (fun _ => "PSC1_EXECUTABLE_JS_VALIDATE") (psJsValidateModule lowered)
  let mut declarations : PsStringMap PsJsIrDeclaration := PsStringMap.empty
  for declaration in lowered.declarations do
    declarations := psStringMapPut declarations declaration.name declaration
  let brands := psTsBuildBrandMap selected.raw
  let tags := psTsBuildTagMap selected.raw
  let mut files : List (Prod String String) := []
  let mut jsRows : List String := []
  let mut tsRows : List String := []
  for unit in selected.units do
    let ordered ← psListMapExcept (fun (item : PsVerifiedIrDeclaration) =>
      match psStringMapGet declarations item.name with
      | Option.some value => Except.ok value
      | Option.none => Except.error (String.Internal.append "PSC1_EXECUTABLE_JS_DECLARATION:" item.name))
      unit.declarations
    let unitOwners := psListMap (fun (declaration : PsVerifiedIrDeclaration) =>
      PsModuleOwner.mk declaration.name unit.index) unit.declarations
    let unitPlan := PsModulePlan.mk selected.raw unitOwners selected.units selected.packages selected.protocol
    let js ← Ps.Internal.ModularJs.renderUnit unitPlan
      (PsJsIrModule.mk lowered.imports ordered) request.sourceClosureDigest unit
    let ts ← Ps.Internal.ModularTs.renderUnit selected request.sourceClosureDigest brands tags unit
    let suffix := String.Internal.append "/unit-" (psNatToString unit.index)
    files := psListAppend [
      Prod.mk (psTextJoin "" ["js", suffix, ".mjs"]) js.source,
      Prod.mk (psTextJoin "" ["js", suffix, ".d.mts"]) js.declarations,
      Prod.mk (psTextJoin "" ["ts", suffix, ".mts"]) ts.source] files
    jsRows := List.cons (artifactJson "js" js) jsRows
    tsRows := List.cons (artifactJson "ts" ts) tsRows
  let originalIr ← psExceptMapError (fun _ => "PSC1_EXECUTABLE_ENCODE_ORIGINAL") (psIrEncodeModule original.raw)
  let specializedIr ← psExceptMapError (fun _ => "PSC1_EXECUTABLE_ENCODE_SPECIALIZED") (psIrEncodeModule specialized.raw)
  let fusedIr ← psExceptMapError (fun _ => "PSC1_EXECUTABLE_ENCODE_FUSED") (psIrEncodeModule fused.raw)
  let capture := psJsonObject [
    ("schema", psJsonQuote "psc1-executable-capture/1"),
    ("requestId", psJsonQuote request.requestId),
    ("sourceClosureDigest", psJsonQuote request.sourceClosureDigest),
    ("grammar", psJsonQuote request.grammar), ("entry", psJsonQuote request.entry),
    ("assurance", psJsonQuote request.assurance),
    ("partialNames", psJsonArray (psListMap
      (fun (name : PsName) => psJsonQuote (psNameToString name)) semantic.partialNames)),
    ("leanVersion", psJsonQuote "4.35.0"),
    ("leanCommit", psJsonQuote "eb6cafb7290e8bd5f2937522d8d804f58f02bafc"),
    ("sourceModules", psJsonArray (psListMap
      (fun (source : Ps.Internal.CompilerService.Source) => psJsonQuote source.moduleName) request.sources)),
    ("owners", psJsonArray (psListMap ownerJson fusedOwners)),
    ("logicalDeclarations", psNatToString semantic.logicalCount),
    ("counts", psJsonArray (psListMap psNatToString [psListLength original.raw.declarations,
      psListLength specialized.raw.declarations, psListLength fused.raw.declarations])),
    ("specializationOriginCount", psNatToString (psListLength specialized.origins)),
    ("workerOriginCount", psNatToString (psListLength fused.origins)),
    ("claim", psJsonQuote "candidate metadata; external official Lean admission required")]
  let modules := psJsonObject [
    ("schema", psJsonQuote "psc1-executable-compiler-emission/1"),
    ("sourceClosureDigest", psJsonQuote request.sourceClosureDigest),
    ("protocol", psJsonQuote selected.protocol),
    ("packages", psJsonArray (psListMap psJsonQuote selected.packages)),
    ("sourceToUnit", psJsonArray (psListMap psNatToString sourceToUnit)),
    ("owners", psJsonArray (psListMap ownerJson selected.owners)),
    ("units", psJsonArray (psListMap (fun (unit : PsModuleUnit) => psJsonObject [
      ("index", psNatToString unit.index),
      ("names", psJsonArray (psListMap (fun (declaration : PsVerifiedIrDeclaration) =>
        psJsonQuote declaration.name) unit.declarations)),
      ("imports", psJsonArray (psListMap ownerJson unit.imports)),
      ("computedInitializers", psJsonArray (psListMap (fun (declaration : PsVerifiedIrDeclaration) =>
        psJsonQuote declaration.name) (psListFilter (fun (declaration : PsVerifiedIrDeclaration) =>
          !Ps.Internal.ExecutablePlan.early declaration) unit.declarations)))]) selected.units)),
    ("js", psJsonArray (psListReverse jsRows)), ("ts", psJsonArray (psListReverse tsRows)),
    ("logicalAdmission", psJsonQuote "external-host-required"),
    ("strictIR", "true"), ("referenceFuel", "4096")]
  let referenceJs ← psExceptMapError (fun _ => "PSC1_EXECUTABLE_REFERENCE_JS")
    (psJsPrintModuleStackSafe lowered)
  let referenceTs ← psExceptMapError (fun _ => "PSC1_EXECUTABLE_REFERENCE_TS") (psTsEmitModule selected.raw)
  let runtime := psTextJoin "" [psJsStringRuntimeSupport, psJsStackRuntimeSupport, "\nexport { ",
    psTextJoin ", " (psListFilter (fun (name : String) => !psStringEq name "__ps$cohort")
      Ps.Internal.ModularJs.helpers), " };\n"]
  let result := psListAppend [
    ("original-ir.json", originalIr), ("specialized-ir.json", specializedIr),
    ("fused-ir.json", fusedIr), ("admissions.json", semantic.admissions),
    ("capture.json", capture), ("modules.json", modules),
    ("js-runtime.mjs", runtime), ("reference.mjs", referenceJs), ("reference.mts", referenceTs)]
    (psListReverse files)
  checkedFileBytes result 0
  return result

def refused (reason : String) : String :=
  psJsonObject [("protocol", psJsonQuote "psc1-modular-build/1"),
    ("status", psJsonQuote "refused"), ("candidateOnly", "true"),
    ("admission", psJsonQuote "not-run"), ("code", psJsonQuote reason)]

def wireError (error : Ps.Internal.CompilerService.Error) : String :=
  String.Internal.append "PSC1_EXECUTABLE_REQUEST:" error.code

def decodeBuild (fields : List PsJsonValue) : Except String String := do
  if !(Nat.beq (psListLength fields) 3) then throw "PSC1_EXECUTABLE_REQUEST_ARITY"
  let protocol ← psExceptMapError wireError (Ps.Internal.CompilerService.stringAt fields 0)
  if !psStringEq protocol "psc1-modular-build/1" then throw "PSC1_EXECUTABLE_PROTOCOL"
  let requestValue ← psExceptMapError wireError (Ps.Internal.CompilerService.atWorker fields 1)
  let requestFields ← psExceptMapError wireError (Ps.Internal.CompilerService.readArray requestValue)
  let request ← psExceptMapError wireError (Ps.Internal.CompilerService.decodeRequestFields requestFields)
  let specifierValue ← psExceptMapError wireError (Ps.Internal.CompilerService.atWorker fields 2)
  let specifierValues ← psExceptMapError wireError (Ps.Internal.CompilerService.readArray specifierValue)
  let specifiers ← psListMapExcept (fun (value : PsJsonValue) =>
    match value with
    | PsJsonValue.string text => Except.ok text
    | _ => Except.error "PSC1_EXECUTABLE_SPECIFIER") specifierValues
  let files ← generate request specifiers
  return psJsonObject [("protocol", psJsonQuote "psc1-modular-build/1"),
    ("status", psJsonQuote "candidate"), ("candidateOnly", "true"),
    ("admission", psJsonQuote "not-run"), ("requestId", psJsonQuote request.requestId),
    ("sourceClosureDigest", psJsonQuote request.sourceClosureDigest),
    ("files", psJsonArray (psListMap (fun (file : Prod String String) =>
      psJsonArray [psJsonQuote file.fst, psJsonQuote file.snd]) files))]

def candidate (input : String) : String :=
  match psJsonParse input with
  | Except.ok value =>
    match value with
    | PsJsonValue.array fields =>
      match decodeBuild fields with
      | Except.ok output => output
      | Except.error reason => refused reason
    | _ => refused "PSC1_EXECUTABLE_INVALID_JSON"
  | Except.error _ => refused "PSC1_EXECUTABLE_INVALID_JSON"

end Ps.Internal.ModularCompiler

