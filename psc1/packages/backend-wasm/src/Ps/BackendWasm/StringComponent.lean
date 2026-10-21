import Ps.BackendWasm.StringAbi

def psWasmStringAbiWit (plan : PsWasmStringAbiPlan) : String :=
  "package proofscript:psc1;\n\nworld app {\n" ++
  (if plan.io then "  import dispatch: func(request: string) -> string;\n" else "") ++
  String.join (plan.exports.map fun e =>
    "  export " ++ e.name ++ ": func(" ++
    String.intercalate ", " (e.parameters.map (fun p =>
      p.1 ++ ": " ++ (if p.2 then "string" else "bool"))) ++
    ") -> " ++ (if e.resultString then "string" else "bool") ++ ";\n") ++ "}\n"

def psWasmStringAbiComponent (source : PsValidatedIrModule)
    (plan : PsWasmStringAbiPlan) (core : PsWasmModule) :
    Except String PsWasmComponentArtifacts := do
  let expected <- psWasmStringAbiMakePlan source (plan.exports.map (fun e => e.name)) plan.io
  if expected != plan then throw "PSC1_WASM_STRING_COMPONENT_SCHEMA_SOURCE_MISMATCH"
  match psWasmIrValidateModule core with
  | .error _ => throw "PSC1_WASM_STRING_COMPONENT_IR_INVALID"
  | .ok _ => pure ()
  if !core.abiMemory || core.abiMemoryImports || core.abiGlobalsExport then
    throw "PSC1_WASM_STRING_COMPONENT_MEMORY_PROFILE_INVALID"
  if core.exports.length != plan.exports.length + 2 then
    throw "PSC1_WASM_STRING_COMPONENT_EXPORT_SET_MISMATCH"
  for exported in plan.exports do
    let some (_, target) := core.exports.find? (fun item => item.1 == exported.name)
      | throw "PSC1_WASM_STRING_COMPONENT_EXPORT_MISSING"
    let some function := core.functions.find? (fun f => f.name == target)
      | throw "PSC1_WASM_STRING_COMPONENT_FUNCTION_MISSING"
    let parameters := exported.parameters.flatMap (fun p =>
      if p.2 then [PsWasmValueType.i32, .i32] else [.i32])
    if !psWasmIrValueTypeListsEq function.parameters parameters ||
        !psWasmIrValueTypeListsEq function.results [.i32] then
      throw "PSC1_WASM_STRING_COMPONENT_SIGNATURE_MISMATCH"
  let encoded := fun module => match psWasmEncodeModule module with
    | .ok value => Except.ok value
    | .error _ => Except.error "PSC1_WASM_STRING_COMPONENT_BINARY_FAILED"
  let coreBytes <- encoded core
  let vector := fun (items : List (List UInt8)) =>
    psWasmEncodeUleb items.length ++ items.flatten
  let scalar := fun string => if string then (0x73 : UInt8) else 0x7f
  let types := plan.exports.map fun e =>
    [0x40] ++ vector (e.parameters.map (fun p => psWasmEncodeName p.1 ++ [scalar p.2])) ++
    [0x00, scalar e.resultString]
  let options : List UInt8 := [0x03, 0x00, 0x03, 0x00, 0x04, 0x00]
  let header : List UInt8 := [0x00, 0x61, 0x73, 0x6d, 0x0d, 0x00, 0x01, 0x00]
  let alias := fun (kind : UInt8) instance name =>
    [0x00, kind, 0x01] ++ psWasmEncodeUleb instance ++ psWasmEncodeName name
  let abiAliases := [alias 0x02 0 "memory", alias 0x00 0 "cabi_realloc"]
  let exportAliases := fun instance => plan.exports.map (fun e => alias 0x00 instance e.name)
  let mut bytes := header
  let mut firstFunction := 2
  let mut firstType := 0
  let mut importedFunctions := 0
  if plan.io then
    if core.functionImports.length != 1 then throw "PSC1_WASM_STRING_COMPONENT_DISPATCH_IMPORT_MISSING"
    match psWasmIrValidateModule psWasmStringAbiAllocator with
    | .error _ => throw "PSC1_WASM_STRING_ALLOCATOR_IR_INVALID"
    | .ok _ => pure ()
    let allocator <- encoded psWasmStringAbiAllocator
    let importedCore := { core with abiMemoryImports := true }
    match psWasmIrValidateModule importedCore with
    | .error _ => throw "PSC1_WASM_STRING_IMPORTED_MEMORY_IR_INVALID"
    | .ok _ => pure ()
    let main <- encoded importedCore
    let dispatchType : List UInt8 :=
      [0x40] ++ vector [psWasmEncodeName "request" ++ [0x73]] ++ [0x00, 0x73]
    bytes := bytes ++ psWasmEncodeSection 7 (vector (dispatchType :: types)) ++
      psWasmEncodeSection 10 (vector [[0x00] ++ psWasmEncodeName "dispatch" ++ [0x01, 0x00]]) ++
      psWasmEncodeSection 1 allocator ++
      psWasmEncodeSection 2 [0x01, 0x00, 0x00, 0x00] ++
      psWasmEncodeSection 6 (vector abiAliases) ++
      psWasmEncodeSection 8 (vector [[0x01, 0x00, 0x00] ++ options]) ++
      psWasmEncodeSection 2 (vector [[0x01] ++ vector [
        psWasmEncodeName "dispatch" ++ [0x00, 0x01]]]) ++
      psWasmEncodeSection 1 main ++
      psWasmEncodeSection 2 (vector [[0x00, 0x01] ++ vector [
        psWasmEncodeName "psc1:abi" ++ [0x12, 0x00],
        psWasmEncodeName "psc1:io" ++ [0x12, 0x01]]]) ++
      psWasmEncodeSection 6 (vector (alias 0x00 2 "cabi_post_return" :: exportAliases 2))
    firstFunction := 3
    firstType := 1
    importedFunctions := 1
  else
    if !core.functionImports.isEmpty then throw "PSC1_WASM_STRING_COMPONENT_UNEXPECTED_IMPORT"
    bytes := bytes ++ psWasmEncodeSection 7 (vector types) ++
      psWasmEncodeSection 1 coreBytes ++
      psWasmEncodeSection 2 [0x01, 0x00, 0x00, 0x00] ++
      psWasmEncodeSection 6 (vector (abiAliases ++ [alias 0x00 0 "cabi_post_return"] ++ exportAliases 0))
  let lifts := plan.exports.zipIdx.map fun (_, index) =>
    [0x00, 0x00] ++ psWasmEncodeUleb (firstFunction + index) ++ [0x04, 0x00, 0x03, 0x00, 0x04, 0x00, 0x05] ++
      psWasmEncodeUleb (if plan.io then 2 else 1) ++
      psWasmEncodeUleb (firstType + index)
  let exports := plan.exports.zipIdx.map fun (e, index) =>
    [0x00] ++ psWasmEncodeName e.name ++ [0x01] ++
      psWasmEncodeUleb (importedFunctions + index) ++ [0x00]
  bytes := bytes ++ psWasmEncodeSection 8 (vector lifts) ++
    psWasmEncodeSection 11 (vector exports)
  pure { coreBytes, componentBytes := bytes, wit := psWasmStringAbiWit plan }
