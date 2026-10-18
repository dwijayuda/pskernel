import Ps.BackendWasm.Lower
import Ps.BackendWasm.AbiComponent
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
  let (lowered, initialLocals) ← lowerModule view
  let mut core : PsWasmModule := { lowered with exports := api.exports.map fun (d : PsVerifiedIrDeclaration) => (d.name, nameOf d.name) }
  let mut locals := initialLocals
  let mut aggregate : Option AbiPlan := none
  if component then
    -- Scalar-only worlds need no marshalling memory. Other worlds are planned
    -- through the same canonical layout policy, including indirect scalars.
    let scalar ← match scalarApi api core locals with
      | .ok plan => pure (some plan)
      | .error _ => pure none
    if scalar.isSome then
      for d in api.exports do
        let normalize := fun type => match type with
          | PsVerifiedIrType.primitive .float => [.call "__ps_float64_canonical"]
          | .primitive .float32 => [.call "__ps_float32_canonical"]
          | _ => []
        let omitResult := match d.resultType with | .primitive .unit => true | _ => false
        if omitResult || !(normalize d.resultType).isEmpty ||
            d.parameters.any (fun p => !(normalize p.type).isEmpty) then
          let name := "__ps_abi_scalar_" ++ nameOf d.name
          let parameters ← d.parameters.mapM (fun p => representation p.type)
          let results ← if omitResult then pure [] else (representation d.resultType).map (fun t => [t])
          let wrapper : PsWasmFunction := {
            name, typeName := none, parameters, results, locals := []
            body := (d.parameters.zipIdx.flatMap fun (p, i) => [.localGet i] ++ normalize p.type) ++
              [.call (nameOf d.name)] ++ (if omitResult then [.drop] else normalize d.resultType) }
          core := { core with
            functions := core.functions ++ [wrapper],
            exports := core.exports.map fun (exportedName, target) => (exportedName, if exportedName == d.name then name else target) }
    else
      let exports ← api.exports.mapM fun d => do
        return (d.name, ← requireDeclaration view (nameOf d.name))
      let plan ← canonicalAbiPlan view exports
      let (adapted, adaptedNames) ← addCanonicalAdapters core locals plan
      core := adapted
      locals := adaptedNames
      aggregate := some plan
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
  let (wasm, wat, wit, symbols) ← match aggregate with
    | none => do
      let plan ← scalarApi api core locals
      pure (← scalarComponentBinary plan, ← psRenderDoc (scalarComponentWat plan), scalarWit plan,
        plan.exports.map fun e => { semanticName := e.sourceName, outputName := e.foreignName : PsCodegenSymbol })
    | some abi => do
      let plan : AggregateComponent := { core, locals, abi }
      pure (← aggregateComponentBinary plan, ← psRenderDoc (← aggregateComponentWat plan), ← abiWit abi,
        abi.exports.map fun e => { semanticName := e.semanticName, outputName := "api." ++ e.foreignName : PsCodegenSymbol })
  psValidateArtifact { base with
    source := wat
    symbols
    exports := exports.map fun e => { e with witReason := none }
    files := coreFiles ++ [
      { path := stem ++ ".wasm", role := .implementation, payload := .binary wasm },
      { path := stem ++ ".wat", role := .debugText, payload := .text (wat.text ++ "\n") },
      { path := stem ++ ".wit", role := .interface, payload := .text wit }] }


end PsWasm
