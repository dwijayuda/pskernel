import Ps.Host.SourceOwnership
import Ps.BackendJs.Modules
import Ps.BackendTs.Modules
import Ps.CompilerIr.WorkerFusion
import Lean.Data.Json

/-! Native pilot coordinator. It captures through the production elaborator once,
prepares exact Core for external official Lean admission, then uses the existing
specializer and backend printers. It writes candidates only; no filesystem
publication authority comes from JSON or an IR wrapper. -/

namespace Ps.Host.ModularPilot

open Ps.Internal.CompilerService

def liftResult {α : Type} (value : Except String α) : IO α :=
  match value with
  | .ok result => pure result
  | .error reason => throw (IO.userError reason)

def jsonRows (value : Lean.Json) (key : String) : Except String (List Lean.Json) := do
  return (← (← value.getObjVal? key).getArr?).toList

def sourceOwners (rows : Array Lean.Json) : Except String (List (Lean.Json × Nat)) := do
  let mut result := []
  for index in [:rows.size] do
    for origin in ← jsonRows rows[index]! "origins" do
      for member in ← jsonRows origin "members" do
        result := result ++ [(← member.getObjVal? "name", index + 1)]
  return result

def originalOwners (semantic : Semantic) (rows : Array Lean.Json) :
    Except String (List PsModuleOwner) := do
  let authored ← sourceOwners rows
  let names := psErasureDeclarationNames
    (psErasureRuntimeDeclarations psSelfHostRuntimePreludeDeclarationsWithProd semantic.source)
  semantic.raw.declarations.mapM fun declaration => do
    let matchingNames := names.filter (fun item => item.2 == declaration.name)
    let [entry] := matchingNames | throw ("PSC1_MODULE_ERASURE_OWNER:" ++ declaration.name)
    let tagged := Lean.toJson (psOwnershipName entry.1)
    let sources := authored.filter (fun item => item.1.compress == tagged.compress)
    let unit ← match sources with
      | [item] => pure item.2
      | [] =>
        if psSelfHostRuntimePreludeDeclarationsWithProd.any
            (fun core => psNameEq (psDeclarationName core) entry.1) then pure 0
        else throw ("PSC1_MODULE_UNKNOWN_OWNER:" ++ declaration.name)
      | _ => throw ("PSC1_MODULE_DUPLICATE_ORIGIN:" ++ declaration.name)
    return { name := declaration.name, unit }

def ownerJson (owner : PsModuleOwner) : Lean.Json :=
  .arr #[.str owner.name, Lean.toJson owner.unit]

def importJson (item : PsModuleImport) : Lean.Json :=
  .mkObj [("source", .str item.source), ("names", Lean.toJson item.names),
    ("typeOnly", Lean.toJson item.typeOnly)]

def artifactJson (item : PsModuleArtifact) : Lean.Json :=
  .mkObj [("unit", Lean.toJson item.unit), ("source", .str item.source),
    ("declarations", .str item.declarations), ("imports", Lean.toJson (item.imports.map importJson)),
    ("exports", Lean.toJson item.exports)]

def originKindName : PsIrOriginKind → String
  | .structure => "structure"
  | .inductive => "inductive"
  | .declaration => "declaration"

def originRuleName : PsIrOriginRule → String
  | .retained => "retained-identity"
  | .specialization => "specialization"
  | .worker => "worker"

def transformOriginJson (row : PsIrTransformOrigin) : Except String Lean.Json := do
  let arguments ← row.arguments.mapM fun type => do
    let text ← (psIrEncodeType type).mapError (fun _ => "PSC1_MODULE_ORIGIN_TYPE_ENCODING")
    Lean.Json.parse text
  return .mkObj [
    ("kind", .str (originKindName row.kind)), ("rule", .str (originRuleName row.rule)),
    ("outputName", .str row.outputName), ("inputName", .str row.inputName),
    ("arguments", Lean.toJson arguments)]

def packageForModule (name : String) : String :=
  if name == "Ps.Foundation.Name" then "@proofscript/modular-pilot-names"
  else if name == "Pilot.Consumer" then "@proofscript/modular-pilot-consumer"
  else "@proofscript/modular-pilot-" ++ ((name.replace "." "-").replace "_" "-").toLower

def compileWithMode (request : Request) (extended : Bool) : IO Lean.Json := do
  let sourceCount := request.sources.length
  if request.assurance != "checked" || sourceCount < 2 ||
      sourceCount > (if extended then 8 else 2) then
    throw (IO.userError "PSC1_MODULE_PILOT_REQUEST_SCOPE")
  let (captured, rows) ← match psOwnershipCapture request with
    | .ok result => pure result
    | .error error => throw (IO.userError ("PSC1_MODULE_CAPTURE:" ++ error.compress))
  let semantic ← match psOwnershipPrepare request captured with
    | .ok result => pure result
    | .error error => throw (IO.userError ("PSC1_MODULE_PREPARE:" ++ error.compress))
  let original ← liftResult ((psStrictValidateModule semantic.raw).mapError
    (fun _ => "PSC1_MODULE_ORIGINAL_IR"))
  let owners ← liftResult (originalOwners semantic rows)
  let specialized ← liftResult ((psIrSpecializeValidatedModuleWithOrigins original).mapError
    psIrSpecializeDiagnosticText)
  let selectedOwners ← if extended then
      liftResult (psModuleCarryOwners semantic.raw owners specialized)
    else
      liftResult (specialized.raw.declarations.mapM fun declaration =>
        match owners.find? (fun owner => owner.name == declaration.name) with
        | some owner => .ok owner
        | none => .error ("PSC1_MODULE_SYNTHETIC_OWNER_UNQUALIFIED:" ++ declaration.name))
  let transformed ← if extended then
      liftResult (psFuseClosedWorkersWithOrigins (.mk specialized.raw))
    else pure specialized
  let finalOwners ← if extended then
      liftResult (psModuleCarryOwners specialized.raw selectedOwners transformed)
    else pure selectedOwners
  let protocol := if extended then "psc1-modular-pilot/2" else "psc1-modular-pilot/1"
  let packages := "@proofscript/modular-pilot-runtime" ::
    request.sources.map (fun source => packageForModule source.moduleName)
  let plan ← liftResult (psPlanModulesWithPackages transformed.raw finalOwners packages protocol)
  let js ← liftResult (psEmitJsModules plan request.sourceClosureDigest)
  let ts ← liftResult (psEmitTsModules plan request.sourceClosureDigest)
  let lowered ← liftResult ((psJsLowerSpecializedModule plan.raw).mapError
    (fun _ => "PSC1_MODULE_REFERENCE_JS_LOWER"))
  let referenceJs ← liftResult ((psJsPrintModuleStackSafe lowered).mapError
    (fun _ => "PSC1_MODULE_REFERENCE_JS_PRINT"))
  let referenceTs ← liftResult ((psTsEmitModule plan.raw).mapError
    (fun _ => "PSC1_MODULE_REFERENCE_TS_PRINT"))
  let originalIr ← liftResult ((psIrEncodeModule semantic.raw).mapError
    (fun _ => "PSC1_MODULE_ORIGINAL_ENCODING"))
  let transformedIr ← liftResult ((psIrEncodeModule plan.raw).mapError
    (fun _ => "PSC1_MODULE_TRANSFORMED_ENCODING"))
  let fields : List (String × Lean.Json) := [
    ("protocol", .str (if extended then "psc1-modular-pilot-candidate/2" else "psc1-modular-pilot-candidate/1")),
    ("requestId", .str request.requestId),
    ("sourceClosureDigest", .str request.sourceClosureDigest),
    ("grammar", .str request.grammar),
    ("admission", .str "not-run"), ("candidateOnly", Lean.toJson true),
    ("admissionRequest", ← liftResult (Lean.Json.parse
      (psCompilerHostAdmissionRequest request.requestId request.sourceClosureDigest "js" semantic.admissions))),
    ("leanVersion", .str Lean.versionString), ("leanCommit", .str Lean.githash),
    ("admissions", .str semantic.admissions), ("origins", .arr rows),
    ("originalIr", ← liftResult (Lean.Json.parse originalIr)),
    ("transformedIr", ← liftResult (Lean.Json.parse transformedIr)),
    ("owners", Lean.toJson (plan.owners.map ownerJson)),
    ("units", Lean.toJson (plan.units.map fun unit => Lean.Json.mkObj [
      ("index", Lean.toJson unit.index),
      ("names", Lean.toJson (unit.declarations.map (fun declaration => declaration.name))),
      ("imports", Lean.toJson (unit.imports.map ownerJson))])),
    ("js", Lean.toJson (js.map artifactJson)), ("ts", Lean.toJson (ts.map artifactJson)),
    ("referenceJs", .str referenceJs), ("referenceTs", .str referenceTs),
    ("behaviorallyVerified", Lean.toJson false),
    ("profile", .str (if extended then "closed-specialization/explicit-origins/worker-fusion/dag/2"
      else "closed-specialization/exact-owners/dag/1"))]
  let extra ← if extended then do
      let specializedIr ← liftResult ((psIrEncodeModule specialized.raw).mapError
        (fun _ => "PSC1_MODULE_SPECIALIZED_ENCODING"))
      let specialization ← liftResult (specialized.origins.mapM transformOriginJson)
      let fusion ← liftResult (transformed.origins.mapM transformOriginJson)
      pure [
        ("packages", Lean.toJson packages),
        ("sourceModules", Lean.toJson (request.sources.map (fun source => source.moduleName))),
        ("originalOwners", Lean.toJson (owners.map ownerJson)),
        ("specializedOwners", Lean.toJson (selectedOwners.map ownerJson)),
        ("specializedIr", ← liftResult (Lean.Json.parse specializedIr)),
        ("transformOrigins", Lean.Json.mkObj [
          ("specialization", Lean.toJson specialization), ("workerFusion", Lean.toJson fusion)])]
    else pure []
  return .mkObj (fields ++ extra)

def compile (request : Request) : IO Lean.Json :=
  compileWithMode request false

def main (args : List String) : IO UInt32 := do
  try
    match args with
    | ["--translate", file] =>
      let source ← IO.FS.readFile file
      let output ← match psCompilerTranslateSource .lean .proofScript source with
        | .ok text => pure text
        | .error _ => throw (IO.userError "PSC1_MODULE_TRANSLATION")
      IO.print output
    | [file] =>
      let text ← IO.FS.readFile file
      if text.utf8ByteSize > 1024 * 1024 then throw (IO.userError "PSC1_MODULE_REQUEST_BOUND")
      let parsed ← liftResult (Lean.Json.parse text)
      let .arr cells := parsed | throw (IO.userError "PSC1_MODULE_WIRE_ARRAY")
      let some (.str protocol) := cells[0]? | throw (IO.userError "PSC1_MODULE_WIRE_PROTOCOL")
      if protocol != "psc1-modular-pilot/1" && protocol != "psc1-modular-pilot/2" then
        throw (IO.userError "PSC1_MODULE_WIRE_PROTOCOL")
      let fields ← liftResult do
        -- Existing portable decoder owns grammar/assurance/source request syntax.
        let portable ← (psJsonParse parsed.compress).mapError (fun _ => "PSC1_MODULE_WIRE_JSON")
        let .array values := portable | throw "PSC1_MODULE_WIRE_ARRAY"
        (decodeRequestFieldsForProtocol protocol 7 values).mapError
          (fun error => "PSC1_MODULE_WIRE:" ++ error.code)
      let candidate ← compileWithMode fields (protocol == "psc1-modular-pilot/2")
      let output := candidate.compress
      if output.utf8ByteSize > 32 * 1024 * 1024 then throw (IO.userError "PSC1_MODULE_RESPONSE_BOUND")
      IO.println output
    | _ => throw (IO.userError "PSC1_MODULE_ARGUMENTS")
    return 0
  catch error =>
    (← IO.getStderr).putStrLn error.toString
    return 1

end Ps.Host.ModularPilot

