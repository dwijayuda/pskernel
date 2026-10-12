import Ps.BackendWasm.AbiPlan

namespace PsWasm

def abiPrimitive (node : AbiNode) : Option (String × UInt8) :=
  match node.shape with
  | .scalar scalar => some (scalar.wit, scalar.byte)
  | .string => some ("string", 0x73)
  | _ => none

def abiWitType (plan : AbiPlan) (index : Nat) : Except String String := do
  let node ← abiNode plan index
  return (abiPrimitive node).map (·.1) |>.getD ("%" ++ node.name)

def abiNamedNodes (plan : AbiPlan) : List (AbiNode × Nat) :=
  plan.nodes.zipIdx.filter (fun (node, _) => (abiPrimitive node).isNone)

def abiComponentTypeIndex (plan : AbiPlan) (id : Nat) : Except String Nat :=
  match (abiNamedNodes plan).zipIdx.find? (fun ((_, nodeId), _) => nodeId == id) with
  | some (_, index) => pure index
  | none => throw "PSCV0-COMPONENT-PLAN: missing exported type identity"

def abiComponentValueBytes (plan : AbiPlan) (id : Nat) : Except String (List UInt8) := do
  let node ← abiNode plan id
  match abiPrimitive node with
  | some (_, byte) => do pure [byte]
  | none => return psWasmEncodeSleb (Int.ofNat (← abiComponentTypeIndex plan id))

def abiComponentValueText (plan : AbiPlan) (id : Nat) : Except String String := do
  let node ← abiNode plan id
  match abiPrimitive node with
  | some (name, _) => do pure name
  | none => return watId node.name

def abiSchemaFields (node : AbiNode) : List (String × Nat) :=
  match node.shape with
  | .natural limbs => [("limbs", limbs)]
  | .integer negative magnitude => [("negative", negative), ("magnitude", magnitude)]
  | .record _ fields | .payload fields => fields.map fun f => (f.name, f.node)
  | _ => []

def abiWitDefinition (plan : AbiPlan) (node : AbiNode) : Except String String := do
  let label := "%" ++ node.name
  match node.shape with
  | .limbs => return "type " ++ label ++ " = list<u32>;"
  | .list element => return "type " ++ label ++ " = list<" ++ (← abiWitType plan element) ++ ">;"
  | .variant _ cases _ _ =>
    let cases ← cases.mapM fun c => do
      let payload ← match c.payload with
        | none => pure ""
        | some id => (abiWitType plan id).map (fun type => "(" ++ type ++ ")")
      return "  %" ++ c.name ++ payload ++ ","
    return "variant " ++ label ++ " {\n" ++ String.intercalate "\n" cases ++ "\n}"
  | _ =>
    let fields ← (abiSchemaFields node).mapM fun (name, id) => do
      return "  %" ++ name ++ ": " ++ (← abiWitType plan id) ++ ","
    return "record " ++ label ++ " {\n" ++ String.intercalate "\n" fields ++ "\n}"

def abiWit (plan : AbiPlan) : Except String String := do
  let types ← (abiNamedNodes plan).mapM fun (node, _) => abiWitDefinition plan node
  let exports ← plan.exports.mapM fun e => do
    let params ← e.parameters.mapM fun (name, id) => do
      return "%" ++ name ++ ": " ++ (← abiWitType plan id)
    let result ← match e.result with
      | none => pure ""
      | some id => (abiWitType plan id).map (" -> " ++ ·)
    return "%" ++ e.foreignName ++ ": func(" ++ String.intercalate ", " params ++ ")" ++ result ++ ";"
  let lines := (String.intercalate "\n\n" (types ++ exports)).splitOn "\n"
  return "package proofscript:generated;\n\nworld application {\n  export api: interface {\n" ++
    String.intercalate "\n" (lines.map fun l => "    " ++ l) ++ "\n  }\n}\n"

def abiDefinitionBytes (plan : AbiPlan) (node : AbiNode) : Except String (List UInt8) := do
  let vector := fun values => psWasmEncodeUleb (List.length values) ++ List.flatten values
  match node.shape with
  | .limbs => return [0x70, 0x79]
  | .list element => return [0x70] ++ (← abiComponentValueBytes plan element)
  | .variant _ cases _ _ =>
    let cases ← cases.mapM fun c => do
      let payload ← match c.payload with
        | none => pure [0]
        | some id => (abiComponentValueBytes plan id).map ([1] ++ ·)
      return psWasmEncodeName c.name ++ payload ++ [0]
    return [0x71] ++ vector cases
  | _ =>
    let fields ← (abiSchemaFields node).mapM fun (name, id) => do
      return psWasmEncodeName name ++ (← abiComponentValueBytes plan id)
    return [0x72] ++ vector fields

def abiDefinitionText (plan : AbiPlan) (node : AbiNode) : Except String String := do
  match node.shape with
  | .limbs => return "(list u32)"
  | .list element => return "(list " ++ (← abiComponentValueText plan element) ++ ")"
  | .variant _ cases _ _ =>
    let cases ← cases.mapM fun c => do
      let payload ← match c.payload with
        | none => pure ""
        | some id => (abiComponentValueText plan id).map (" " ++ ·)
      return "(case " ++ watQuote c.name ++ payload ++ ")"
    return "(variant " ++ String.intercalate " " cases ++ ")"
  | _ =>
    let fields ← (abiSchemaFields node).mapM fun (name, id) => do
      return "(field " ++ watQuote name ++ " " ++ (← abiComponentValueText plan id) ++ ")"
    return "(record " ++ String.intercalate " " fields ++ ")"

end PsWasm
