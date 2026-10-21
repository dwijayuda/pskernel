import Ps.BackendWasm.RuntimeString
import Ps.BackendWasm.Type
import Ps.BackendWasm.Component

-- Fixed 16 MiB UTF-8 arena. GC strings own copies; host memory cannot alias
-- source values. Malformed scalars, ranges, allocation overflow and reentry trap.
def psWasmStringAbiFunctions : List PsWasmFunction :=
[
  { name := "__psc1_abi_memory_copy", typeName := none
    parameters := [.i32, .i32, .i32, .i32], results := []
    locals := []
    body := [.localGet 3,
      .localGet 2,
      .i32LtU,
      .ifStart none,
      .localGet 0,
      .localGet 3,
      .i32Add,
      .localGet 1,
      .localGet 3,
      .i32Add,
      .i32Load8U,
      .i32Store8,
      .localGet 0,
      .localGet 1,
      .localGet 2,
      .localGet 3,
      .i32Const 1,
      .i32Add,
      .returnCall "__psc1_abi_memory_copy",
      .end_] },
  { name := "__psc1_abi_realloc", typeName := none
    parameters := [.i32, .i32, .i32, .i32], results := [.i32]
    locals := [.i32]
    body := [.localGet 2,
      .i32Const 1,
      .i32Ne,
      .ifStart none,
      .unreachable,
      .end_,
      .localGet 0,
      .i32Const 16777216,
      .i32GtU,
      .ifStart none,
      .unreachable,
      .end_,
      .localGet 1,
      .i32Const 16777216,
      .localGet 0,
      .i32Sub,
      .i32GtU,
      .ifStart none,
      .unreachable,
      .end_,
      .localGet 1,
      .i32Const 0,
      .i32Ne,
      .localGet 0,
      .i32Const 64,
      .i32LtU,
      .i32And,
      .ifStart none,
      .unreachable,
      .end_,
      .localGet 1,
      .i32Const 0,
      .i32Ne,
      .localGet 0,
      .localGet 1,
      .i32Add,
      .abiHeapGet,
      .i32GtU,
      .i32And,
      .ifStart none,
      .unreachable,
      .end_,
      .localGet 3,
      .i32Const 0,
      .i32Eq,
      .ifStart (some .i32),
      .i32Const 0,
      .else_,
      .abiHeapGet,
      .localSet 4,
      .localGet 3,
      .i32Const 16777216,
      .localGet 4,
      .i32Sub,
      .i32GtU,
      .ifStart none,
      .unreachable,
      .end_,
      .localGet 4,
      .localGet 3,
      .i32Add,
      .abiHeapSet,
      .localGet 4,
      .localGet 0,
      .localGet 1,
      .localGet 3,
      .i32LtU,
      .ifStart (some .i32),
      .localGet 1,
      .else_,
      .localGet 3,
      .end_,
      .i32Const 0,
      .call "__psc1_abi_memory_copy",
      .localGet 4,
      .end_] },
  { name := "__psc1_abi_copy_in", typeName := none
    parameters := [.i32, (.refT psWasmStringBytesName), .i32, .i32], results := []
    locals := []
    body := [.localGet 3,
      .localGet 2,
      .i32LtU,
      .ifStart none,
      .localGet 1,
      .localGet 3,
      .localGet 0,
      .localGet 3,
      .i32Add,
      .i32Load8U,
      .arraySet psWasmStringBytesName,
      .localGet 0,
      .localGet 1,
      .localGet 2,
      .localGet 3,
      .i32Const 1,
      .i32Add,
      .returnCall "__psc1_abi_copy_in",
      .end_] },
  { name := "__psc1_abi_copy_out", typeName := none
    parameters := [(.refT psWasmStringBytesName), .i32, .i32, .i32], results := []
    locals := []
    body := [.localGet 3,
      .localGet 2,
      .i32LtU,
      .ifStart none,
      .localGet 1,
      .localGet 3,
      .i32Add,
      .localGet 0,
      .localGet 3,
      .arrayGetU psWasmStringBytesName,
      .i32Store8,
      .localGet 0,
      .localGet 1,
      .localGet 2,
      .localGet 3,
      .i32Const 1,
      .i32Add,
      .returnCall "__psc1_abi_copy_out",
      .end_] },
  { name := "__psc1_abi_count_utf8", typeName := none
    parameters := [(.refT psWasmStringBytesName), .i32, .i32, .i32], results := [.i32]
    locals := [.i32, .i32, .i32]
    body := [.localGet 2,
      .localGet 1,
      .i32Eq,
      .ifStart (some .i32),
      .localGet 3,
      .else_,
      .localGet 0,
      .localGet 2,
      .arrayGetU psWasmStringBytesName,
      .localSet 4,
      .localGet 4,
      .i32Const 128,
      .i32LtU,
      .ifStart (some .i32),
      .i32Const 1,
      .else_,
      .localGet 4,
      .i32Const 194,
      .i32GeU,
      .localGet 4,
      .i32Const 223,
      .i32LeU,
      .i32And,
      .ifStart (some .i32),
      .i32Const 2,
      .else_,
      .localGet 4,
      .i32Const 224,
      .i32GeU,
      .localGet 4,
      .i32Const 239,
      .i32LeU,
      .i32And,
      .ifStart (some .i32),
      .i32Const 3,
      .else_,
      .localGet 4,
      .i32Const 240,
      .i32GeU,
      .localGet 4,
      .i32Const 244,
      .i32LeU,
      .i32And,
      .ifStart (some .i32),
      .i32Const 4,
      .else_,
      .unreachable,
      .end_,
      .end_,
      .end_,
      .end_,
      .localSet 5,
      .localGet 5,
      .localGet 1,
      .localGet 2,
      .i32Sub,
      .i32GtU,
      .ifStart none,
      .unreachable,
      .end_,
      .localGet 5,
      .i32Const 1,
      .i32GtU,
      .ifStart none,
      .localGet 0,
      .localGet 2,
      .i32Const 1,
      .i32Add,
      .arrayGetU psWasmStringBytesName,
      .localSet 6,
      .localGet 6,
      .i32Const 128,
      .i32LtU,
      .localGet 6,
      .i32Const 191,
      .i32GtU,
      .i32Or,
      .ifStart none,
      .unreachable,
      .end_,
      .localGet 4,
      .i32Const 224,
      .i32Eq,
      .localGet 6,
      .i32Const 160,
      .i32LtU,
      .i32And,
      .ifStart none,
      .unreachable,
      .end_,
      .localGet 4,
      .i32Const 237,
      .i32Eq,
      .localGet 6,
      .i32Const 159,
      .i32GtU,
      .i32And,
      .ifStart none,
      .unreachable,
      .end_,
      .localGet 4,
      .i32Const 240,
      .i32Eq,
      .localGet 6,
      .i32Const 144,
      .i32LtU,
      .i32And,
      .ifStart none,
      .unreachable,
      .end_,
      .localGet 4,
      .i32Const 244,
      .i32Eq,
      .localGet 6,
      .i32Const 143,
      .i32GtU,
      .i32And,
      .ifStart none,
      .unreachable,
      .end_,
      .end_,
      .localGet 5,
      .i32Const 2,
      .i32GtU,
      .ifStart none,
      .localGet 0,
      .localGet 2,
      .i32Const 2,
      .i32Add,
      .arrayGetU psWasmStringBytesName,
      .localSet 6,
      .localGet 6,
      .i32Const 128,
      .i32LtU,
      .localGet 6,
      .i32Const 191,
      .i32GtU,
      .i32Or,
      .ifStart none,
      .unreachable,
      .end_,
      .end_,
      .localGet 5,
      .i32Const 3,
      .i32GtU,
      .ifStart none,
      .localGet 0,
      .localGet 2,
      .i32Const 3,
      .i32Add,
      .arrayGetU psWasmStringBytesName,
      .localSet 6,
      .localGet 6,
      .i32Const 128,
      .i32LtU,
      .localGet 6,
      .i32Const 191,
      .i32GtU,
      .i32Or,
      .ifStart none,
      .unreachable,
      .end_,
      .end_,
      .localGet 0,
      .localGet 1,
      .localGet 2,
      .localGet 5,
      .i32Add,
      .localGet 3,
      .i32Const 1,
      .i32Add,
      .returnCall "__psc1_abi_count_utf8",
      .end_] },
  { name := "__psc1_abi_from_memory", typeName := none
    parameters := [.i32, .i32], results := [(.refT psWasmStringName)]
    locals := [(.refT psWasmStringBytesName)]
    body := [.localGet 0,
      .i32Const 16777216,
      .i32GtU,
      .ifStart none,
      .unreachable,
      .end_,
      .localGet 1,
      .i32Const 16777216,
      .localGet 0,
      .i32Sub,
      .i32GtU,
      .ifStart none,
      .unreachable,
      .end_,
      .localGet 1,
      .arrayNewDefault psWasmStringBytesName,
      .localSet 2,
      .localGet 0,
      .localGet 2,
      .localGet 1,
      .i32Const 0,
      .call "__psc1_abi_copy_in",
      .localGet 2,
      .localGet 2,
      .localGet 1,
      .i32Const 0,
      .i32Const 0,
      .call "__psc1_abi_count_utf8",
      .structNew psWasmStringName] },
  { name := "__psc1_abi_to_memory", typeName := none
    parameters := [(.refT psWasmStringName)], results := [.i32]
    locals := [(.refT psWasmStringBytesName), .i32, .i32]
    body := [.localGet 0,
      .structGet psWasmStringName 0,
      .localSet 1,
      .localGet 1,
      .arrayLen,
      .localSet 2,
      .i32Const 0,
      .i32Const 0,
      .i32Const 1,
      .localGet 2,
      .call "__psc1_abi_realloc",
      .localSet 3,
      .localGet 1,
      .localGet 3,
      .localGet 2,
      .i32Const 0,
      .call "__psc1_abi_copy_out",
      .i32Const 0,
      .localGet 3,
      .i32Store 0,
      .i32Const 0,
      .localGet 2,
      .i32Store 4,
      .i32Const 0] }
]

def psWasmStringAbiAllocator : PsWasmModule :=
  { psWasmModuleEmpty with
    abiMemory := true, abiGlobalsExport := true
    functions := psWasmStringAbiFunctions.filter (fun f =>
      f.name == "__psc1_abi_memory_copy" || f.name == "__psc1_abi_realloc")
    exports := [("cabi_realloc", "__psc1_abi_realloc")] }

structure PsWasmStringAbiExport where
  name : String
  parameters : List (String × Bool)
  resultString : Bool
  deriving BEq

structure PsWasmStringAbiPlan where
  exports : List PsWasmStringAbiExport
  io : Bool
  deriving BEq

def psWasmStringAbiIsString (type : PsVerifiedIrType) : Bool :=
  match type with | .primitive .string => true | _ => false

def psWasmStringAbiIsBool (type : PsVerifiedIrType) : Bool :=
  match type with | .primitive .bool => true | _ => false

def psWasmStringAbiMakePlan (source : PsValidatedIrModule)
    (names : List String) (ioAbi : Bool) : Except String PsWasmStringAbiPlan := do
  let source <- match psStrictValidateModule source.raw with
    | .ok value => pure value
    | .error _ => throw "PSC1_WASM_STRING_INPUT_IR_INVALID"
  if names.isEmpty || names.eraseDups.length != names.length then
    throw "PSC1_WASM_STRING_EXPORT_SET_INVALID"
  let mut hasDispatcher := false
  let mut exports := []
  for name in names do
    if !psWasmComponentWitIdent name || name == "memory" || name == "cabi-realloc" then
      throw "PSC1_WASM_STRING_EXPORT_NAME_UNSUPPORTED"
    let some declaration := source.raw.declarations.find? (fun d => d.name == name)
      | throw "PSC1_WASM_STRING_EXPORT_MISSING"
    if !declaration.typeParameters.isEmpty then throw "PSC1_WASM_STRING_GENERIC_UNSUPPORTED"
    if !(psWasmStringAbiIsString declaration.resultType || psWasmStringAbiIsBool declaration.resultType) then
      throw "PSC1_WASM_STRING_RESULT_UNSUPPORTED"
    let mut dispatchers := 0
    let mut parameters := []
    for parameter in declaration.parameters do
      if psBackendIoDispatcherType parameter.type && ioAbi then
        dispatchers := dispatchers + 1
      else if psWasmStringAbiIsString parameter.type || psWasmStringAbiIsBool parameter.type then
        if !psWasmComponentWitIdent parameter.name then throw "PSC1_WASM_STRING_ARGUMENT_NAME_UNSUPPORTED"
        parameters := parameters ++ [(parameter.name, psWasmStringAbiIsString parameter.type)]
      else throw "PSC1_WASM_STRING_ARGUMENT_UNSUPPORTED"
    if dispatchers > 1 then throw "PSC1_WASM_IO_DISPATCHER_COUNT_UNSUPPORTED"
    if dispatchers == 1 then hasDispatcher := true
    if (parameters.map (fun p => p.1)).eraseDups.length != parameters.length then
      throw "PSC1_WASM_STRING_ARGUMENT_DUPLICATE"
    if (parameters.map (fun p => if p.2 then 2 else 1)).foldl Nat.add 0 > 16 then
      throw "PSC1_WASM_STRING_INDIRECT_ARGUMENTS_UNSUPPORTED"
    exports := exports ++ [{ name, parameters, resultString := psWasmStringAbiIsString declaration.resultType }]
  if ioAbi && !hasDispatcher then throw "PSC1_WASM_IO_DISPATCHER_REQUIRED"
  pure { exports, io := ioAbi }

def psWasmStringAbiDispatchType : PsVerifiedIrType :=
  .function [.primitive .string] (.primitive .string)

def psWasmStringAbiDispatchFunction (baseName codeTypeName : String) : PsWasmFunction :=
  { name := "__psc1_abi_dispatch_gc", typeName := some codeTypeName
    parameters := [.refT baseName, psWasmStringRef], results := [psWasmStringRef]
    locals := [psWasmStringRef]
    body := [
      .i32Const 64, .abiHeapSet,
      .localGet 1, .call "__psc1_abi_to_memory", .drop,
      .i32Const 0, .i32Load 0, .i32Const 0, .i32Load 4, .i32Const 0,
      .call "__psc1_abi_host_dispatch",
      .i32Const 0, .i32Load 0, .i32Const 0, .i32Load 4,
      .call "__psc1_abi_from_memory", .localSet 2,
      .i32Const 64, .abiHeapSet, .localGet 2] }

def psWasmStringAbiWrapper (declaration : PsVerifiedIrDeclaration)
    (target baseName : String) (ioAbi : Bool) : Except String PsWasmFunction := do
  let mut body : List PsWasmInstruction := [
    .abiBusyGet, .ifStart none, .unreachable, .end_]
  let mut parameters : List PsWasmValueType := []
  let mut index := 0
  for parameter in declaration.parameters do
    if psBackendIoDispatcherType parameter.type && ioAbi then
      body := body ++ [.refFunc "__psc1_abi_dispatch_gc", .structNew baseName]
    else if psWasmStringAbiIsString parameter.type then
      body := body ++ [.localGet index, .localGet (index+1), .call "__psc1_abi_from_memory"]
      parameters := parameters ++ [.i32, .i32]
      index := index + 2
    else if psWasmStringAbiIsBool parameter.type then
      -- Canonical Bool values are exactly zero or one.
      body := body ++ [.localGet index, .i32Const 1, .i32GtU,
        .ifStart none, .unreachable, .end_, .localGet index]
      parameters := parameters ++ [.i32]
      index := index + 1
    else throw "PSC1_WASM_STRING_WRAPPER_ARGUMENT_UNSUPPORTED"
  body := body ++ [.i32Const 1, .abiBusySet, .i32Const 64, .abiHeapSet, .call target]
  if psWasmStringAbiIsString declaration.resultType then
    body := body ++ [.i32Const 64, .abiHeapSet, .call "__psc1_abi_to_memory"]
  else if !psWasmStringAbiIsBool declaration.resultType then
    throw "PSC1_WASM_STRING_WRAPPER_RESULT_UNSUPPORTED"
  body := body ++ [.i32Const 0, .abiBusySet]
  pure { name := "__psc1_abi_export_" ++ declaration.name, typeName := none
    parameters, results := [.i32], locals := [], body }

def psWasmStringAbiAdapt (plan : PsWasmStringAbiPlan)
    (source : PsValidatedIrModule) (lowered : PsWasmModule) : Except String PsWasmModule := do
  let expected <- psWasmStringAbiMakePlan source (plan.exports.map (fun e => e.name)) plan.io
  if expected != plan then throw "PSC1_WASM_STRING_SCHEMA_SOURCE_MISMATCH"
  if lowered.abiMemory || !lowered.functionImports.isEmpty ||
      lowered.functions.any (fun f => f.name.startsWith "__psc1_abi_") then
    throw "PSC1_WASM_STRING_RESERVED_TARGET_COLLISION"
  let some baseName := psWasmClosureBaseName psWasmStringAbiDispatchType
    | throw "PSC1_WASM_IO_CLOSURE_TYPE_UNSUPPORTED"
  let some codeTypeName := psWasmClosureCodeTypeName psWasmStringAbiDispatchType
    | throw "PSC1_WASM_IO_CLOSURE_TYPE_UNSUPPORTED"
  let wrappers <- plan.exports.mapM fun exported => do
    let some declaration := source.raw.declarations.find? (fun d => d.name == exported.name)
      | throw "PSC1_WASM_STRING_EXPORT_MISSING"
    let some (_, target) := lowered.exports.find? (fun e => e.1 == exported.name)
      | throw "PSC1_WASM_STRING_LOWERED_EXPORT_MISSING"
    psWasmStringAbiWrapper declaration target baseName plan.io
  let imports := if plan.io then [{
    moduleName := "psc1:io", importName := "dispatch"
    function := { name := "__psc1_abi_host_dispatch", typeName := none
      parameters := [.i32, .i32, .i32], results := [], locals := [], body := [] }
  }] else []
  let dispatch := if plan.io then [psWasmStringAbiDispatchFunction baseName codeTypeName] else []
  let extraStructures := psWasmStringRuntimeStructures.filter (fun item =>
    !lowered.structures.any (fun existing => existing.name == item.name))
  let extraArrays := psWasmStringRuntimeArrays.filter (fun item =>
    !lowered.arrays.any (fun existing => existing.name == item.name))
  let output : PsWasmModule := { lowered with
    abiMemory := true, functionImports := imports
    structures := lowered.structures ++ extraStructures
    arrays := lowered.arrays ++ extraArrays
    functions := lowered.functions ++ psWasmStringAbiFunctions ++ [{
      name := "__psc1_abi_post_return", typeName := none, parameters := [.i32], results := []
      locals := [], body := [.i32Const 64, .abiHeapSet] }] ++ dispatch ++ wrappers
    functionRefs := lowered.functionRefs ++ (if plan.io then ["__psc1_abi_dispatch_gc"] else [])
    exports := plan.exports.map (fun e => (e.name, "__psc1_abi_export_" ++ e.name)) ++
      [("cabi_realloc", "__psc1_abi_realloc"), ("cabi_post_return", "__psc1_abi_post_return")]
  }
  match psWasmIrValidateModule output with
  | .ok _ => pure output
  | .error _ => throw "PSC1_WASM_STRING_TARGET_IR_INVALID"
