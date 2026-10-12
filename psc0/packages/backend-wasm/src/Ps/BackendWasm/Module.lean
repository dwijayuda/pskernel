import Ps.BackendWasm.Scalar
import Ps.BackendWasm.Component
import Ps.BackendWasm.ValidateIr

namespace PsWasm

def checkedCore (core : PsWasmModule) : Except String ByteArray := do
  let _ ← (psWasmIrValidateModule core).mapError (fun e => "PSCV0-WASM-TYPE: " ++ reprStr e)
  let bytes ← (psWasmEncodeModule core).mapError (fun e => "PSCV0-WASM-ENCODE: " ++ reprStr e)
  return ByteArray.mk bytes.toArray

-- Caller must enter through psWithCheckedIr. The independently checked target
-- module is retained unchanged for both binary and readable text serialization.
def emitScalar (ir : PsVerifiedIrModule) (context : PsEmissionContext)
    (component : Bool) (exposure : PsApiExposure := .allRuntime) :
    Except String PsEmissionArtifact := do
  let api ← psPublicApi ir exposure
  let (lowered, locals) ← scalarModule ir
  let core := { lowered with exports := api.exports.map fun d => (d.name, d.name) }
  let binary ← checkedCore core
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
