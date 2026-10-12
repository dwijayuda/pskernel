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
    | some id => do return [0] ++ (← abiComponentValueBytes plan id)
  return [0x40] ++ psWasmEncodeUleb parameters.length ++ parameters.flatten ++ result

def aggregateComponentBinary (plan : AggregateComponent) : Except String ByteArray := do
  let core ← namedCoreBinary plan.core plan.locals
  let u := psWasmEncodeUleb
  let str := psWasmEncodeName
  let vector := fun (xs : List (List UInt8)) => u xs.length ++ xs.flatten
  let sect := psWasmEncodeSection
  let mut bytes := [0, 97, 115, 109, 13, 0, 1, 0] ++ sect 1 core ++ sect 2 [1, 0, 0, 0]
  for ((node, _), index) in (abiNamedNodes plan.abi).zipIdx do
    bytes := bytes ++ sect 7 (vector [← abiDefinitionBytes plan.abi node]) ++
      sect 11 (vector [[0] ++ str node.name ++ [3] ++ u (2 * index) ++ [0]])
  let typeCount := 2 * (abiNamedNodes plan.abi).length
  let types ← plan.abi.exports.mapM (abiFunctionTypeBytes plan.abi)
  bytes := bytes ++ sect 7 (vector types)
  let aliases := [("__ps_abi_realloc", 0), ("__ps_abi_post_return", 0),
      ("__ps_abi_post_return_void", 0), ("memory", 2)] ++
    plan.abi.exports.map fun e => (e.semanticName, 0)
  bytes := bytes ++ sect 6 (vector (aliases.map fun (name, kind) =>
    [0, UInt8.ofNat kind, 1, 0] ++ str name))
  let lifts := plan.abi.exports.zipIdx.map fun (e, index) =>
    [0, 0] ++ u (3 + index) ++ [4, 0, 3, 0, 4, 0, 5] ++
      u (if e.result.isSome then 1 else 2) ++ u (typeCount + index)
  bytes := bytes ++ sect 8 (vector lifts)
  let exports := plan.abi.exports.zipIdx.map fun (e, index) =>
    [0] ++ str e.foreignName ++ [1] ++ u index ++ [0]
  return ByteArray.mk (bytes ++ sect 11 (vector exports)).toArray

def aggregateComponentWat (plan : AggregateComponent) : Except String PsDoc := do
  let mut declarations : List PsDoc := [
    watModuleDoc plan.core plan.locals "(core module $implementation",
    .text "(core instance $instance (instantiate $implementation))"]
  for (node, _) in abiNamedNodes plan.abi do
    let definition := node.name ++ "_definition"
    declarations := declarations ++ [
      .text ("(type " ++ watId definition ++ " " ++ (← abiDefinitionText plan.abi node) ++ ")"),
      .text ("(export " ++ watId node.name ++ " " ++ watQuote node.name ++ " (type " ++ watId definition ++ "))")]
  for (e, index) in plan.abi.exports.zipIdx do
    let parameters ← e.parameters.mapM fun (name, id) => do
      return " (param " ++ watQuote name ++ " " ++ (← abiComponentValueText plan.abi id) ++ ")"
    let result ← match e.result with
      | none => pure ""
      | some id => do return " (result " ++ (← abiComponentValueText plan.abi id) ++ ")"
    declarations := declarations ++ [.text ("(type $__ps_signature" ++ toString index ++ " (func" ++
      String.join parameters ++ result ++ "))")]
  declarations := declarations ++ [
    .text "(alias core export $instance \"__ps_abi_realloc\" (core func $reallocate))",
    .text "(alias core export $instance \"__ps_abi_post_return\" (core func $post_return))",
    .text "(alias core export $instance \"__ps_abi_post_return_void\" (core func $post_return_void))",
    .text "(alias core export $instance \"memory\" (core memory $abi_memory))"]
  for (e, index) in plan.abi.exports.zipIdx do
    declarations := declarations ++ [.text ("(alias core export $instance " ++ watQuote e.semanticName ++
      " (core func $lift" ++ toString index ++ "))")]
  for (e, index) in plan.abi.exports.zipIdx do
    declarations := declarations ++ [.text ("(func " ++ watId e.foreignName ++ " (type $__ps_signature" ++ toString index ++
      ") (canon lift (core func $lift" ++ toString index ++ ") string-encoding=utf8 (memory $abi_memory)" ++
      " (realloc $reallocate) (post-return " ++
      (if e.result.isSome then "$post_return" else "$post_return_void") ++ ")))")]
  for e in plan.abi.exports do
    declarations := declarations ++ [.text ("(export " ++ watQuote e.foreignName ++ " (func " ++ watId e.foreignName ++ "))")]
  return .append (.text "(component")
    (.append (.nest 2 (.append .hardline (psDocJoin .hardline declarations))) (.append .hardline (.text ")")))

end PsWasm
