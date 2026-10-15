import Ps.BackendWasm.AbiSchema
import Ps.BackendWasm.AbiMarshal

namespace PsWasm

structure AggregateComponent where
  core : PsWasmModule
  locals : LocalNames
  abi : AbiPlan

def abiFunctionTypeBytes (plan : AbiPlan) (e : AbiExport) : Except String (List UInt8) := do
  let parameters ← e.parameters.mapM fun (name, id) => do
    return psWasmEncodeName name ++ (← abiComponentValueBytes plan id)
  let result ← match e.result with
    | none => pure [1, 0]
    | some id => (abiComponentValueBytes plan id).map ([0] ++ ·)
  return [0x40] ++ psWasmEncodeUleb parameters.length ++ parameters.flatten ++ result

def aggregateComponentBinary (plan : AggregateComponent) : Except String ByteArray := do
  let core ← namedCoreBinary plan.core plan.locals
  let u := psWasmEncodeUleb
  let str := psWasmEncodeName
  let vector := fun (xs : List (List UInt8)) => u xs.length ++ xs.flatten
  let sect := psWasmEncodeSection
  let mut bytes := [0, 97, 115, 109, 13, 0, 1, 0] ++ sect 1 core ++ sect 2 [1, 0, 0, 0]
  let dataTypes ← (abiNamedNodes plan.abi).mapM fun (node, _) => abiDefinitionBytes plan.abi node
  let typeCount := dataTypes.length
  let functionTypes ← plan.abi.exports.mapM (abiFunctionTypeBytes plan.abi)
  bytes := bytes ++ sect 7 (vector (dataTypes ++ functionTypes))
  let aliases := (abiCoreAliases.map fun name => (name, 0)) ++ [("memory", 2)] ++
    plan.abi.exports.map fun e => (e.semanticName, 0)
  bytes := bytes ++ sect 6 (vector (aliases.map fun (name, kind) =>
    [0, UInt8.ofNat kind, 1, 0] ++ str name))
  let lifts ← plan.abi.exports.zipIdx.mapM fun (e, index) => do
    return [0, 0] ++ u (abiCoreAliases.length + index) ++ [4, 0, 3, 0, 4, 0, 5] ++
      u (← abiPostReturnIndex plan.abi e) ++ u (typeCount + index)
  bytes := bytes ++ sect 8 (vector lifts)
  let typeExports := (abiNamedNodes plan.abi).zipIdx.map fun ((node, _), index) =>
    [0] ++ str node.name ++ [3] ++ u index
  let functionExports := plan.abi.exports.zipIdx.map fun (e, index) =>
    [0] ++ str e.foreignName ++ [1] ++ u index
  let instanceSection := sect 5 (vector [[1] ++ vector (typeExports ++ functionExports)])
  let exported := sect 11 (vector [[0] ++ str "api" ++ [5, 0, 0]])
  return ByteArray.mk (bytes ++ instanceSection ++ exported).toArray

def aggregateComponentWat (plan : AggregateComponent) : Except String PsDoc := do
  let mut declarations : List PsDoc := [
    watModuleDoc plan.core plan.locals "(core module $implementation",
    .text "(core instance $instance (instantiate $implementation))"]
  for (node, _) in abiNamedNodes plan.abi do
    declarations := declarations ++ [
      .text ("(type " ++ watId node.name ++ " " ++ (← abiDefinitionText plan.abi node) ++ ")")]
  for (e, index) in plan.abi.exports.zipIdx do
    let parameters ← e.parameters.mapM fun (name, id) => do
      return " (param " ++ watQuote name ++ " " ++ (← abiComponentValueText plan.abi id) ++ ")"
    let result ← match e.result with
      | none => pure ""
      | some id => (abiComponentValueText plan.abi id).map (fun type => " (result " ++ type ++ ")")
    declarations := declarations ++ [.text ("(type $__ps_signature" ++ toString index ++ " (func" ++
      String.join parameters ++ result ++ "))")]
  declarations := declarations ++ (abiCoreAliases.map fun name =>
    .text ("(alias core export $instance " ++ watQuote name ++ " (core func " ++ watId name ++ "))")) ++ [
    .text "(alias core export $instance \"memory\" (core memory $abi_memory))"]
  for (e, index) in plan.abi.exports.zipIdx do
    declarations := declarations ++ [.text ("(alias core export $instance " ++ watQuote e.semanticName ++
      " (core func $lift" ++ toString index ++ "))")]
  for (e, index) in plan.abi.exports.zipIdx do
    let (post, _) ← abiPostReturn plan.abi e
    declarations := declarations ++ [.text ("(func " ++ watId e.foreignName ++ " (type $__ps_signature" ++ toString index ++
      ") (canon lift (core func $lift" ++ toString index ++ ") string-encoding=utf8 (memory $abi_memory)" ++
      " (realloc " ++ watId "__ps_abi_realloc" ++ ") (post-return " ++ watId post ++ ")))")]
  let typeExports := (abiNamedNodes plan.abi).map fun (node, _) =>
    PsDoc.text ("(export " ++ watQuote node.name ++ " (type " ++ watId node.name ++ "))")
  let functionExports := plan.abi.exports.map fun e =>
    PsDoc.text ("(export " ++ watQuote e.foreignName ++ " (func " ++ watId e.foreignName ++ "))")
  declarations := declarations ++ [
    .append (.text "(instance $api") (.append
      (.nest 2 (.append .hardline (psDocJoin .hardline (typeExports ++ functionExports))))
      (.append .hardline (.text ")"))),
    .text "(export \"api\" (instance $api))"]
  return .append (.text "(component")
    (.append (.nest 2 (.append .hardline (psDocJoin .hardline declarations))) (.append .hardline (.text ")")))

end PsWasm
