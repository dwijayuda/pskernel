import Ps.BackendCommon.Plan
import Ps.BackendWasm.Binary
import Ps.BackendWasm.ValidateIr

/-- A concrete public schema, never evidence of logical admission. The first
profile retains the qualified Bool ABI; compound values need explicit adapters. -/
structure PsWasmComponentExport where
  name : String
  parameters : List String

structure PsWasmComponentPlan where
  exports : List PsWasmComponentExport

structure PsWasmComponentArtifacts where
  coreBytes : List UInt8
  componentBytes : List UInt8
  wit : String

def psWasmComponentWitIdent (name : String) : Bool :=
  let lower := fun (c : Char) => Nat.ble 97 c.toNat && Nat.ble c.toNat 122
  let digit := fun (c : Char) => Nat.ble 48 c.toNat && Nat.ble c.toNat 57
  let validPart := fun (part : String) => match part.toList with
    | [] => false
    | first :: rest => lower first && rest.all (fun c => lower c || digit c)
  let reserved := ["world", "interface", "package", "export", "import", "use", "type",
    "func", "record", "variant", "resource", "constructor", "static", "bool", "string",
    "char", "u8", "u16", "u32", "u64", "s8", "s16", "s32", "s64", "f32", "f64"]
  !reserved.contains name && (name.splitOn "-").all validPart

def psWasmComponentValidatePlan (plan : PsWasmComponentPlan) : Except String Unit := do
  let names := plan.exports.map (fun e => e.name)
  if names.eraseDups.length != names.length then
    throw "PSC1_COMPONENT_EXPORT_DUPLICATE"
  for exported in plan.exports do
    if !psWasmComponentWitIdent exported.name then
      throw "PSC1_COMPONENT_WIT_EXPORT_NAME_UNSUPPORTED"
    if exported.parameters.length > 16 then
      throw "PSC1_COMPONENT_INDIRECT_PARAMETERS_UNSUPPORTED"
    if exported.parameters.eraseDups.length != exported.parameters.length then
      throw "PSC1_COMPONENT_WIT_ARGUMENT_DUPLICATE"
    if !exported.parameters.all psWasmComponentWitIdent then
      throw "PSC1_COMPONENT_WIT_ARGUMENT_NAME_UNSUPPORTED"

/-- Recheck raw IR even when a caller can construct the wrapper. Publication
authority still belongs exclusively to the independently admitted host session. -/
def psWasmComponentMakePlan (source : PsValidatedIrModule)
    (publicNames : List String) : Except String PsWasmComponentPlan := do
  let source <- match psStrictValidateModule source.raw with
    | .ok value => pure value
    | .error _ => throw "PSC1_COMPONENT_INPUT_IR_INVALID"
  let exports <- publicNames.mapM fun name => do
    let some declaration := source.raw.declarations.find? (fun d => d.name == name)
      | throw "PSC1_COMPONENT_WIT_EXPORT_UNKNOWN"
    if !declaration.typeParameters.isEmpty then
      throw "PSC1_COMPONENT_WIT_GENERIC_EXPORT_UNSUPPORTED"
    let requireBool := fun type => match type with
      | PsVerifiedIrType.primitive .bool => Except.ok ()
      | _ => Except.error "PSC1_COMPONENT_WIT_TYPE_UNSUPPORTED"
    requireBool declaration.resultType
    for parameter in declaration.parameters do
      requireBool parameter.type
    pure { name, parameters := declaration.parameters.map (fun p => p.name) : PsWasmComponentExport }
  psBackendCheckPublicApi .wasmComponent source publicNames
  let plan := { exports : PsWasmComponentPlan }
  psWasmComponentValidatePlan plan
  return plan

def psWasmComponentWit (plan : PsWasmComponentPlan) : Except String String := do
  psWasmComponentValidatePlan plan
  return "package proofscript:psc1;\n\nworld app {\n" ++
    String.join (plan.exports.map fun exported =>
      "  export " ++ exported.name ++ ": func(" ++
      String.intercalate ", " (exported.parameters.map (fun name => name ++ ": bool")) ++
      ") -> bool;\n") ++ "}\n"

/-- Core function signatures must match the exact schema being lifted. A public
schema cannot manufacture a function, alter its calling convention or add exports. -/
def psWasmComponentCheckCore (plan : PsWasmComponentPlan)
    (core : PsWasmModule) : Except String Unit := do
  psWasmComponentValidatePlan plan
  match psWasmIrValidateModule core with
  | .ok _ => pure ()
  | .error _ => throw "PSC1_COMPONENT_CORE_IR_INVALID"
  if core.exports.length != plan.exports.length then
    throw "PSC1_COMPONENT_CORE_EXPORT_SET_MISMATCH"
  for exported in plan.exports do
    let some (_, target) := core.exports.find? (fun item => item.1 == exported.name)
      | throw "PSC1_COMPONENT_CORE_EXPORT_MISSING"
    let some function := core.functions.find? (fun f => f.name == target)
      | throw "PSC1_COMPONENT_CORE_FUNCTION_MISSING"
    if !psWasmIrValueTypeListsEq function.parameters
        (List.replicate exported.parameters.length .i32) ||
        !psWasmIrValueTypeListsEq function.results [.i32] then
      throw "PSC1_COMPONENT_CORE_SIGNATURE_MISMATCH"

/-- Encode component type, alias, lift and export sections from one schema.
The embedded core retains GC values; the qualified scalar ABI needs no memory.
Independent CI tools validate and execute the emitted bytes. -/
def psWasmComponentEmit (plan : PsWasmComponentPlan)
    (core : PsWasmModule) : Except String PsWasmComponentArtifacts := do
  psWasmComponentCheckCore plan core
  let wit <- psWasmComponentWit plan
  let coreBytes <- match psWasmEncodeModule core with
    | .ok bytes => pure bytes
    | .error _ => throw "PSC1_COMPONENT_BINARY_UNSUPPORTED"
  let vector := fun (items : List (List UInt8)) =>
    psWasmEncodeUleb items.length ++ items.flatten
  let types := plan.exports.map fun exported =>
    [0x40] ++ vector (exported.parameters.map (fun name => psWasmEncodeName name ++ [0x7f])) ++
      [0x00, 0x7f]
  let aliases := plan.exports.map fun exported =>
    [0x00, 0x00, 0x01, 0x00] ++ psWasmEncodeName exported.name
  let lifts := plan.exports.zipIdx.map fun (_, index) =>
    [0x00, 0x00] ++ psWasmEncodeUleb index ++ [0x00] ++ psWasmEncodeUleb index
  let exports := plan.exports.zipIdx.map fun (exported, index) =>
    [0x00] ++ psWasmEncodeName exported.name ++ [0x01] ++ psWasmEncodeUleb index ++ [0x00]
  let componentBytes := [0x00, 0x61, 0x73, 0x6d, 0x0d, 0x00, 0x01, 0x00] ++
    psWasmEncodeSection 1 coreBytes ++
    psWasmEncodeSection 2 [0x01, 0x00, 0x00, 0x00] ++
    psWasmEncodeSection 7 (vector types) ++
    psWasmEncodeSection 6 (vector aliases) ++
    psWasmEncodeSection 8 (vector lifts) ++
    psWasmEncodeSection 11 (vector exports)
  return { coreBytes, componentBytes, wit }
