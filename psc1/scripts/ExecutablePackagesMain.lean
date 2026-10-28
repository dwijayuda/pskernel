import Ps.Host.SourceModules
import Ps.Host.ExecutablePlan
import Ps.Host.PortableIr
import Ps.BackendJs.ModuleFiles
import Ps.BackendTs.ModuleFiles
import Ps.CompilerIr.WorkerFusion

/-! Production build adapter: capture and candidate-file emission are separate
bounded commands. The host must independently admit exact canonical Core between
them. This native adapter is not a second frontend and grants no publication or
checker capability. Full modular G2/G3 emission remains a separate release gate. -/

namespace Ps.Host.ExecutablePackages
open Ps.Internal.CompilerService

def liftResult {α : Type} (value : Except String α) : IO α :=
  match value with
  | .ok result => pure result
  | .error reason => throw (IO.userError reason)

def readJson (file : String) : IO Lean.Json := do
  let text ← IO.FS.readFile file
  if text.utf8ByteSize > 33554432 then throw (IO.userError "PSC1_EXECUTABLE_INPUT_BOUND")
  liftResult (Lean.Json.parse text)

def write (budget : IO.Ref Nat) (file text : String) : IO Unit := do
  if text.utf8ByteSize > 33554432 then throw (IO.userError "PSC1_EXECUTABLE_FILE_BOUND")
  let total := (← budget.get) + text.utf8ByteSize
  if total > 134217728 then throw (IO.userError "PSC1_EXECUTABLE_STAGE_AGGREGATE_BOUND")
  budget.set total
  IO.FS.writeFile file text

def phase (name : String) : IO Unit := do
  IO.println ("PSC1_EXECUTABLE_PHASE " ++ name ++ " " ++ toString (← IO.monoMsNow))
  (← IO.getStdout).flush

def ownerJson (owner : PsModuleOwner) : Lean.Json :=
  .arr #[.str owner.name, Lean.toJson owner.unit]

def importJson (item : PsModuleImport) : Lean.Json :=
  .mkObj [("source", .str item.source), ("names", Lean.toJson item.names),
    ("typeOnly", Lean.toJson item.typeOnly)]

def artifactJson (kind : String) (artifact : PsModuleArtifact) : Lean.Json :=
  .mkObj [("unit", Lean.toJson artifact.unit),
    ("file", .str (kind ++ "/unit-" ++ toString artifact.unit ++
      (if kind == "js" then ".mjs" else ".mts"))),
    ("imports", Lean.toJson (artifact.imports.map importJson)),
    ("exports", Lean.toJson artifact.exports)]

def capture (input directory : String) : IO Unit := do
  let budget ← IO.mkRef (0 : Nat)
  let text ← IO.FS.readFile input
  if text.utf8ByteSize > 33554432 then throw (IO.userError "PSC1_EXECUTABLE_REQUEST_BOUND")
  let request ← match decode text with
    | .ok value => pure value
    | .error error => throw (IO.userError ("PSC1_EXECUTABLE_DECODE:" ++ error.code))
  if request.assurance != "checked" || request.sources.length > 256 ||
      request.sources.any (fun source => source.text.utf8ByteSize > 1048576) then
    throw (IO.userError "PSC1_EXECUTABLE_SOURCE_BOUND")
  phase "capture"
  let (captured, rows) ← match psOwnershipCapture request with
    | .ok value => pure value
    | .error error => throw (IO.userError error.compress)
  phase "prepare"
  let semantic ← match psOwnershipPrepare request captured with
    | .ok value => pure value
    | .error error => throw (IO.userError error.compress)
  let original ← liftResult ((psStrictValidateModule semantic.raw).mapError
    (fun _ => "PSC1_EXECUTABLE_ORIGINAL_IR"))
  let owners ← liftResult (SourceModules.originalOwners semantic rows)
  phase "specialize"
  let specialized ← liftResult ((psIrSpecializeValidatedModuleWithOrigins original).mapError
    psIrSpecializeDiagnosticText)
  let specializedOwners ← liftResult (psModuleCarryOwners original.raw owners specialized)
  phase "worker-fusion"
  let fused ← liftResult (psFuseClosedWorkersWithOrigins (.mk specialized.raw))
  let fusedOwners ← liftResult (psModuleCarryOwners specialized.raw specializedOwners fused)
  IO.FS.createDirAll directory
  write budget (directory ++ "/original-ir.json") (← liftResult
    ((psIrEncodeModule original.raw).mapError (fun _ => "PSC1_EXECUTABLE_ENCODE_ORIGINAL")))
  write budget (directory ++ "/specialized-ir.json") (← liftResult
    ((psIrEncodeModule specialized.raw).mapError (fun _ => "PSC1_EXECUTABLE_ENCODE_SPECIALIZED")))
  write budget (directory ++ "/fused-ir.json") (← liftResult
    ((psIrEncodeModule fused.raw).mapError (fun _ => "PSC1_EXECUTABLE_ENCODE_FUSED")))
  write budget (directory ++ "/admissions.json") semantic.admissions
  write budget (directory ++ "/capture.json") (Lean.Json.mkObj [
    ("schema", .str "psc1-executable-capture/1"), ("requestId", .str request.requestId),
    ("sourceClosureDigest", .str request.sourceClosureDigest),
    ("grammar", .str request.grammar), ("entry", .str request.entry),
    ("leanVersion", .str Lean.versionString), ("leanCommit", .str Lean.githash),
    ("sourceModules", Lean.toJson (request.sources.map (fun s => s.moduleName))),
    ("owners", Lean.toJson (fusedOwners.map ownerJson)),
    ("counts", Lean.toJson ([original.raw.declarations.length,
      specialized.raw.declarations.length, fused.raw.declarations.length] : List Nat)),
    ("specializationOriginCount", Lean.toJson specialized.origins.length),
    ("workerOriginCount", Lean.toJson fused.origins.length),
    ("claim", .str "candidate metadata; external official Lean admission required")
  ]).compress
  phase "captured"

def emit (directory specifierFile digest : String) : IO Unit := do
  let budget ← IO.mkRef (0 : Nat)
  phase "decode"
  let raw ← liftResult (PortableIr.decode (← readJson (directory ++ "/fused-ir.json")))
  let captured ← readJson (directory ++ "/capture.json")
  let identity ← liftResult (captured.getObjValAs? String "sourceClosureDigest")
  if identity != digest then throw (IO.userError "PSC1_EXECUTABLE_SOURCE_MISMATCH")
  let owners ← liftResult do
    let rows ← (← captured.getObjVal? "owners").getArr?
    rows.toList.mapM fun row => do
      let entries ← row.getArr?
      if entries.size != 2 then throw "PSC1_EXECUTABLE_OWNER_ROW"
      return PsModuleOwner.mk (← entries[0]!.getStr?) (← entries[1]!.getNat?)
  let specifierJson ← readJson specifierFile
  let specifiers ← liftResult do
    let rows ← specifierJson.getArr?
    rows.mapM Lean.Json.getStr?
  phase "plan"
  let (selected, sourceToUnit) ← liftResult (ExecutablePlan.plan raw owners specifiers)
  phase "lower"
  let lowered ← liftResult ((psJsLowerSpecializedModule selected.raw).mapError
    (fun _ => "PSC1_EXECUTABLE_JS_LOWER"))
  let _ ← liftResult ((psJsValidateModule lowered).mapError
    (fun _ => "PSC1_EXECUTABLE_JS_VALIDATE"))
  let mut declarations : Std.HashMap String PsJsIrDeclaration := {}
  for declaration in lowered.declarations do
    declarations := declarations.insert declaration.name declaration
  let brands := psTsBuildBrandMap selected.raw
  let tags := psTsBuildTagMap selected.raw
  IO.FS.createDirAll (directory ++ "/js")
  IO.FS.createDirAll (directory ++ "/ts")
  let mut jsRows := []
  let mut tsRows := []
  phase "print"
  for unit in selected.units do
    let ordered ← liftResult (unit.declarations.mapM fun item =>
      match declarations.get? item.name with
      | some value => .ok value
      | none => .error ("PSC1_EXECUTABLE_JS_DECLARATION:" ++ item.name))
    -- Feed the unchanged structured renderer only the selected, ordered unit.
    -- This avoids a full-program owner scan for every generated file.
    let local := { selected with owners := unit.declarations.map
      (fun declaration => PsModuleOwner.mk declaration.name unit.index) }
    let js ← liftResult (Ps.Internal.ModularJs.renderUnit local
      { lowered with declarations := ordered } digest unit)
    let ts ← liftResult (Ps.Internal.ModularTs.renderUnit selected digest brands tags unit)
    let suffix := "/unit-" ++ toString unit.index
    write budget (directory ++ "/js" ++ suffix ++ ".mjs") js.source
    write budget (directory ++ "/js" ++ suffix ++ ".d.mts") js.declarations
    write budget (directory ++ "/ts" ++ suffix ++ ".mts") ts.source
    jsRows := artifactJson "js" js :: jsRows
    tsRows := artifactJson "ts" ts :: tsRows
  write budget (directory ++ "/js-runtime.mjs") (psJsStringRuntimeSupport ++ psJsStackRuntimeSupport ++
    "\nexport { " ++ String.intercalate ", "
      (Ps.Internal.ModularJs.helpers.filter (fun name => name != "__ps$cohort")) ++ " };\n")
  phase "reference"
  write budget (directory ++ "/reference.mjs") (← liftResult
    ((psJsPrintModuleStackSafe lowered).mapError (fun _ => "PSC1_EXECUTABLE_REFERENCE_JS")))
  write budget (directory ++ "/reference.mts") (← liftResult
    ((psTsEmitModule selected.raw).mapError (fun _ => "PSC1_EXECUTABLE_REFERENCE_TS")))
  write budget (directory ++ "/modules.json") (Lean.Json.mkObj [
    ("schema", .str "psc1-executable-compiler-emission/1"),
    ("sourceClosureDigest", .str digest), ("protocol", .str selected.protocol),
    ("packages", Lean.toJson selected.packages),
    ("sourceToUnit", Lean.toJson sourceToUnit),
    ("owners", Lean.toJson (selected.owners.map ownerJson)),
    ("units", Lean.toJson (selected.units.map fun unit => Lean.Json.mkObj [
      ("index", Lean.toJson unit.index),
      ("names", Lean.toJson (unit.declarations.map (fun d => d.name))),
      ("imports", Lean.toJson (unit.imports.map ownerJson)),
      ("computedInitializers", Lean.toJson ((unit.declarations.filter
        (fun d => !ExecutablePlan.early d)).map (fun d => d.name)))])),
    ("js", Lean.toJson jsRows.reverse), ("ts", Lean.toJson tsRows.reverse),
    ("logicalAdmission", .str "external-host-required"),
    ("strictIR", Lean.toJson true), ("referenceFuel", Lean.toJson (4096 : Nat))
  ]).compress
  phase "complete"

def main (args : List String) : IO Unit := do
  match args with
  | ["capture", request, directory] => capture request directory
  | ["emit", directory, specifiers, digest] => emit directory specifiers digest
  | _ => throw (IO.userError "PSC1_EXECUTABLE_ARGUMENTS")

end Ps.Host.ExecutablePackages

def main : List String → IO Unit := Ps.Host.ExecutablePackages.main
