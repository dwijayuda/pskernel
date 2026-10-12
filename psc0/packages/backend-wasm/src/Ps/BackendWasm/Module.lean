import Ps.BackendWasm.Lower
import Ps.BackendWasm.Component
import Ps.BackendWasm.ValidateIr

namespace PsWasm

def checkedCore (core : PsWasmModule) (locals : LocalNames := []) : Except String ByteArray := do
  let typeNames := core.structures.map (·.name) ++ core.arrays.map (·.name) ++ core.functionTypes.map (·.name)
  let duplicates := typeNames.filter (fun name => (typeNames.filter (· == name)).length > 1)
  if !duplicates.isEmpty then throw ("PSCV0-WASM-TYPE: duplicate target type identities: " ++ String.intercalate ", " duplicates.eraseDups)
  let _ ← (psWasmIrValidateModule core).mapError (fun e => "PSCV0-WASM-TYPE: " ++ reprStr e)
  let bytes ← namedCoreBinary core locals
  return ByteArray.mk bytes.toArray

-- Caller must enter through psWithCheckedIr. The independently checked target
-- module is retained unchanged for both binary and readable text serialization.
def emit (ir : PsVerifiedIrModule) (context : PsEmissionContext)
    (component : Bool) (exposure : PsApiExposure := .allRuntime) :
    Except String PsEmissionArtifact := do
  let api ← psPublicApi ir exposure
  let (view, names) ← psCodegenNamesFor ir []
  let nameOf := fun name => ((names.symbols.find? (fun s => s.semanticName == name)).map (·.outputName)).getD name
  let (lowered, locals) ← lowerModule view
  let mut core : PsWasmModule := { lowered with exports := api.exports.map fun (d : PsVerifiedIrDeclaration) => (d.name, nameOf d.name) }
  -- Scalar component compatibility: internal Unit is a value; WIT Unit result
  -- is an explicitly omitted result at the boundary.
  if component then
    for d in api.exports do
      if let .primitive .unit := d.resultType then
        let name := "__ps_abi_unit_" ++ nameOf d.name
        let parameters ← d.parameters.mapM (fun p => representation p.type)
        let wrapper : PsWasmFunction := {
          name, typeName := none, parameters, results := [], locals := []
          body := (parameters.zipIdx.map fun (_, i) => .localGet i) ++ [.call (nameOf d.name), .drop] }
        core := { core with
          functions := core.functions ++ [wrapper],
          exports := core.exports.map fun (exportedName, target) => (exportedName, if exportedName == d.name then name else target) }
  core ← pruneFunctions core
  let binary ← checkedCore core locals
  let source ← psRenderDoc (watModuleDoc core locals)
  let stem := context.outputStem
  let coreFiles : List PsArtifactFile := [
    { path := stem ++ ".core.wasm", role := .implementation, payload := .binary binary },
    { path := stem ++ ".core.wat", role := .debugText, payload := .text (source.text ++ "\n") }]
  let exports := api.exports.map fun d => {
    semanticName := d.name, typeParameters := d.typeParameters,
    parameters := d.parameters, result := d.resultType, witReason := psWitExportReason api d : PsApiExport }
  let base : PsEmissionArtifact := {
    target := if component then .wasmComponent else .wasmCore
    source, symbols := core.exports.map fun (a, b) => { semanticName := a, outputName := b }
    files := coreFiles, exports, origins := context.origins }
  if !component then return ← psValidateArtifact base
  let plan ← scalarApi api core locals
  let wasm ← scalarComponentBinary plan
  let wat ← psRenderDoc (scalarComponentWat plan)
  psValidateArtifact { base with
    source := wat
    symbols := plan.exports.map fun e => { semanticName := e.sourceName, outputName := e.foreignName }
    exports := exports.map fun e => { e with witReason := none }
    files := coreFiles ++ [
      { path := stem ++ ".wasm", role := .implementation, payload := .binary wasm },
      { path := stem ++ ".wat", role := .debugText, payload := .text (wat.text ++ "\n") },
      { path := stem ++ ".wit", role := .interface, payload := .text (scalarWit plan) }] }


end PsWasm
