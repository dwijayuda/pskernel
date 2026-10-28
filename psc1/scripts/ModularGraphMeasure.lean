import Ps.Host.ModularPilot

open Ps.Internal.CompilerService
open Ps.Host.ModularPilot

def graphMark (phase : String) : IO Unit := do
  IO.println ("PSC1_TRANSFORM_GRAPH_PHASE " ++ phase ++ " " ++ toString (← IO.monoMsNow))
  (← IO.getStdout).flush

def graphWrite (path text : String) : IO Unit := do
  if text.utf8ByteSize > 33554432 then throw (IO.userError "PSC1_TRANSFORM_GRAPH_OUTPUT_BOUND")
  IO.FS.writeFile path text

def graphStage (raw : PsVerifiedIrModule) (owners : List PsModuleOwner) :
    Except String Lean.Json := do
  let _ ← (psStrictValidateModule raw).mapError (fun _ => "PSC1_TRANSFORM_GRAPH_STRICT_IR")
  if owners.length != raw.declarations.length then throw "PSC1_TRANSFORM_GRAPH_OWNERS"
  let declarations ← raw.declarations.mapM fun declaration => do
    let assigned ← Ps.Internal.ModuleGraph.owner owners declaration.name
    let references ← Ps.Internal.ModuleGraph.references 4096
      (declaration.parameters.map (fun p => p.name)) declaration.body
    let imports ← references.mapM (Ps.Internal.ModuleGraph.owner owners)
    return Lean.Json.mkObj [
      ("name", .str declaration.name), ("owner", Lean.toJson assigned.unit),
      ("references", Lean.toJson ((Ps.Internal.ModuleGraph.distinctImports imports).map ownerJson))]
  return .mkObj [
    ("values", Lean.toJson raw.declarations.length),
    ("structures", Lean.toJson raw.structures.length),
    ("inductives", Lean.toJson raw.inductives.length),
    ("declarations", Lean.toJson declarations)]

def main (args : List String) : IO Unit := do
  let [input, directory] := args | throw (IO.userError "PSC1_TRANSFORM_GRAPH_ARGUMENTS")
  let text ← IO.FS.readFile input
  if text.utf8ByteSize > 33554432 then throw (IO.userError "PSC1_TRANSFORM_GRAPH_REQUEST_BOUND")
  let request ← match decode text with
    | .ok value => pure value
    | .error error => throw (IO.userError ("PSC1_TRANSFORM_GRAPH_DECODE:" ++ error.code))
  if request.sources.length > 256 ||
      request.sources.any (fun source => source.text.utf8ByteSize > 1048576) then
    throw (IO.userError "PSC1_TRANSFORM_GRAPH_SOURCE_BOUND")
  graphMark "capture"
  let (captured, rows) ← match psOwnershipCapture request with
    | .ok value => pure value
    | .error error => throw (IO.userError error.compress)
  graphMark "prepare"
  let semantic ← match psOwnershipPrepare request captured with
    | .ok value => pure value
    | .error error => throw (IO.userError error.compress)
  let original ← liftResult ((psStrictValidateModule semantic.raw).mapError (fun _ => "strict-original"))
  let owners ← liftResult (originalOwners semantic rows)
  graphMark "specialize-with-origins"
  let specialized ← liftResult ((psIrSpecializeValidatedModuleWithOrigins original).mapError psIrSpecializeDiagnosticText)
  let specializedOwners ← liftResult (psModuleCarryOwners original.raw owners specialized)
  graphMark "worker-fusion-with-origins"
  let fused ← liftResult (psFuseClosedWorkersWithOrigins (.mk specialized.raw))
  let fusedOwners ← liftResult (psModuleCarryOwners specialized.raw specializedOwners fused)
  graphMark "measure"
  let before ← liftResult (graphStage original.raw owners)
  let middle ← liftResult (graphStage specialized.raw specializedOwners)
  let after ← liftResult (graphStage fused.raw fusedOwners)
  let originalText ← liftResult ((psIrEncodeModule original.raw).mapError (fun _ => "encode-original"))
  let specializedText ← liftResult ((psIrEncodeModule specialized.raw).mapError (fun _ => "encode-specialized"))
  let fusedText ← liftResult ((psIrEncodeModule fused.raw).mapError (fun _ => "encode-fused"))
  graphWrite (directory ++ "/original-ir.json") originalText
  graphWrite (directory ++ "/specialized-ir.json") specializedText
  graphWrite (directory ++ "/fused-ir.json") fusedText
  graphWrite (directory ++ "/admissions.json") semantic.admissions
  let result := Lean.Json.mkObj [
    ("schema", .str "psc1-transformed-compiler-graph/1"),
    ("sourceClosureDigest", .str request.sourceClosureDigest),
    ("grammar", .str request.grammar), ("assurance", .str request.assurance),
    ("entry", .str request.entry), ("sourceModules", Lean.toJson (request.sources.map (fun source => source.moduleName))),
    ("leanVersion", .str Lean.versionString), ("leanCommit", .str Lean.githash),
    ("original", before), ("specialized", middle), ("fused", after),
    ("specializationOrigins", Lean.toJson (specialized.origins.filter (fun row =>
      match row.rule with | .specialization => true | _ => false)).length),
    ("workerOrigins", Lean.toJson (fused.origins.filter (fun row =>
      match row.rule with | .worker => true | _ => false)).length),
    ("authority", .str "read-only diagnostic; no emission, publication or self-host qualification")]
  graphWrite (directory ++ "/native-graph.json") result.compress
  graphMark "complete"
