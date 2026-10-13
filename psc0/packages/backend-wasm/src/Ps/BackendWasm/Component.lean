import Ps.BackendWasm.Names
import Ps.Codegen.Api

namespace PsWasm

inductive WitScalar where
  | bool | u8 | u16 | u32 | u64 | char
  deriving BEq

def WitScalar.name : WitScalar → String
  | .bool => "bool" | .u8 => "u8" | .u16 => "u16" | .u32 => "u32" | .u64 => "u64" | .char => "char"

def WitScalar.byte : WitScalar → UInt8
  | .bool => 0x7f | .u8 => 0x7d | .u16 => 0x7b | .u32 => 0x79 | .u64 => 0x77 | .char => 0x74

def WitScalar.coreType : WitScalar → PsWasmValueType
  | .u64 => .i64 | _ => .i32

def WitScalar.loadOp : WitScalar → PsWasmMemoryOp
  | .bool | .u8 => .load8 | .u16 => .load16 | .u64 => .load64 | _ => .load32

def WitScalar.storeOp : WitScalar → PsWasmMemoryOp
  | .bool | .u8 => .store8 | .u16 => .store16 | .u64 => .store64 | _ => .store32

structure ScalarExport where
  sourceName : String
  foreignName : String
  parameters : List (String × WitScalar)
  result : Option WitScalar

-- One explicit interface plan drives WIT, component types and core lifting.
structure ScalarComponent where
  core : PsWasmModule
  locals : LocalNames := []
  exports : List ScalarExport

def witName (raw : String) : String :=
  let parts := raw.toList.foldl (fun (s : String) c =>
    if c.isUpper then s ++ (if s.isEmpty || s.endsWith "-" then "" else "-") ++ String.singleton c.toLower
    else if c.isLower || c.isDigit then s ++ String.singleton c
    else s ++ "-") ""
  let parts := (parts.splitOn "-").filter (fun s => !s.isEmpty)
  let name := String.intercalate "-" parts
  if name.isEmpty then "value"
  else if name.toList.head!.isDigit then "value-" ++ name else name

def scalarApi (api : PsPublicApi) (core : PsWasmModule) (locals : LocalNames) :
    Except String ScalarComponent := do
  let mut seen : List String := []
  let mut exports : List ScalarExport := []
  for d in api.exports do
    if !d.typeParameters.isEmpty then throw ("PSCV0-WIT-CAPABILITY: concrete export required: " ++ d.name)
    let type := fun (t : PsVerifiedIrType) => match t with
      | .primitive .bool => .ok WitScalar.bool
      | .primitive .char => .ok WitScalar.char
      | .primitive .uint8 => .ok WitScalar.u8 | .primitive .uint16 => .ok WitScalar.u16
      | .primitive .uint32 => .ok WitScalar.u32 | .primitive .uint64 => .ok WitScalar.u64
      | _ => .error ("PSCV0-WIT-SCALAR-PLAN: scalar interface required: " ++ d.name)
    let parameters ← d.parameters.mapM fun p => do return (witName p.name, ← type p.type)
    if (parameters.map (·.1)).eraseDups.length != parameters.length then
      throw ("PSCV0-WIT-NAME: parameter collision: " ++ d.name)
    if parameters.length > 16 then throw "PSCV0-WIT-SCALAR-PLAN: indirect parameters use the aggregate ABI plan"
    let result ← match d.resultType with
      | .primitive .unit => pure none
      | t => (type t).map some
    let name := witName d.name
    if seen.contains name then throw ("PSCV0-WIT-NAME: export collision: " ++ name)
    seen := name :: seen
    exports := exports ++ [{ sourceName := d.name, foreignName := name, parameters, result }]
  return { core, locals, exports }

def scalarWit (plan : ScalarComponent) : String :=
  "package proofscript:generated;\n\nworld application {\n" ++
    String.join (plan.exports.map fun e =>
      "  export %" ++ e.foreignName ++ ": func(" ++
      String.intercalate ", " (e.parameters.map fun (n, t) => "%" ++ n ++ ": " ++ t.name) ++
      ")" ++ (e.result.map (fun t => " -> " ++ t.name)).getD "" ++ ";\n") ++ "}\n"

def scalarComponentWat (plan : ScalarComponent) : PsDoc :=
  let signatures := plan.exports.zipIdx.map fun (e, i) =>
    let params := String.join (e.parameters.map fun (n, t) => " (param " ++ watQuote n ++ " " ++ t.name ++ ")")
    let result := (e.result.map (fun t => " (result " ++ t.name ++ ")")).getD ""
    PsDoc.text ("(type $__ps_signature" ++ toString i ++ " (func" ++ params ++ result ++ "))")
  let aliases := plan.exports.zipIdx.map fun (e, i) =>
    PsDoc.text ("(alias core export $instance " ++ watQuote e.sourceName ++ " (core func $lift" ++ toString i ++ "))")
  let functions := plan.exports.zipIdx.map fun (e, i) =>
    PsDoc.text ("(func " ++ watId e.foreignName ++ " (type $__ps_signature" ++ toString i ++
      ") (canon lift (core func $lift" ++ toString i ++ ")))")
  let exports := plan.exports.map fun e =>
    PsDoc.text ("(export " ++ watQuote e.foreignName ++ " (func " ++ watId e.foreignName ++ "))")
  .append (.text "(component")
    (.append (.nest 2 (.append .hardline (psDocJoin .hardline (
      [watModuleDoc plan.core plan.locals "(core module $implementation",
       .text "(core instance $instance (instantiate $implementation))"] ++ signatures ++ aliases ++ functions ++ exports))))
      (.append .hardline (.text ")")))

def scalarComponentBinary (plan : ScalarComponent) : Except String ByteArray := do
  let core ← namedCoreBinary plan.core plan.locals
  let u := psWasmEncodeUleb
  let str := psWasmEncodeName
  let vec := fun (xs : List (List UInt8)) => u xs.length ++ xs.flatten
  let encodeSection :=  psWasmEncodeSection
  let types := plan.exports.map fun e =>
    [0x40] ++ vec (e.parameters.map fun (n, t) => str n ++ [t.byte]) ++
      (match e.result with | none => [0x01, 0x00] | some t => [0x00, t.byte])
  let aliases := plan.exports.map fun e => [0x00, 0x00, 0x01, 0x00] ++ str e.sourceName
  let lifts := plan.exports.zipIdx |>.map fun (_, i) => [0x00, 0x00] ++ u i ++ [0x00] ++ u i
  let exports := plan.exports.zipIdx |>.map fun (e, i) =>
    [0x00] ++ str e.foreignName ++ [0x01] ++ u i ++ [0x00]
  let bytes := [0x00, 0x61, 0x73, 0x6d, 0x0d, 0x00, 0x01, 0x00] ++
    encodeSection 1 core ++ encodeSection 2 [0x01, 0x00, 0x00, 0x00] ++
    encodeSection 7 (vec types) ++ encodeSection 6 (vec aliases) ++
    encodeSection 8 (vec lifts) ++ encodeSection 11 (vec exports)
  return ByteArray.mk bytes.toArray

end PsWasm
