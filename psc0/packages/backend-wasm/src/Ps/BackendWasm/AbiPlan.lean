import Ps.BackendWasm.Lower
import Ps.BackendWasm.Component

namespace PsWasm

inductive AbiScalar where
  | bool | char | word
  deriving BEq

def AbiScalar.wit : AbiScalar → String
  | .bool => "bool" | .char => "char" | .word => "u32"

def AbiScalar.byte : AbiScalar → UInt8
  | .bool => 0x7f | .char => 0x74 | .word => 0x79

structure AbiField where
  name : String
  node : Nat
  offset : Nat
  formal : PsVerifiedIrType
  index : Nat

structure AbiCase where
  name : String
  constructor : String
  fields : List AbiField
  payload : Option Nat
  tag : Nat

inductive AbiShape where
  | scalar (kind : AbiScalar)
  | string
  | limbs
  | natural (limbs : Nat)
  | integer (negative magnitude : Nat)
  | list (element : Nat)
  | record (runtimeName : String) (fields : List AbiField)
  | variant (runtimeName : String) (cases : List AbiCase) (payloadOffset tagSize : Nat)
  | payload (fields : List AbiField)

structure AbiNode where
  key : String
  name : String
  type : PsVerifiedIrType
  shape : AbiShape
  size : Nat
  alignment : Nat
  flat : Nat

structure AbiExport where
  semanticName : String
  foreignName : String
  target : String
  parameters : List (String × Nat)
  result : Option Nat
  parameterOffsets : List Nat
  parameterSize : Nat
  indirectParameters : Bool
  indirectResult : Bool

structure AbiPlan where
  nodes : List AbiNode := []
  exports : List AbiExport := []

abbrev AbiM := StateT AbiPlan (Except String)

def abiAlign (size alignment : Nat) := (size + alignment - 1) / alignment * alignment

def abiNode (plan : AbiPlan) (index : Nat) : Except String AbiNode :=
  match plan.nodes[index]? with
  | some node => pure node
  | none => throw "PSCV0-ABI-PLAN: unresolved type identity"

def abiTypeKey : Nat → PsVerifiedIrType → Except String String
  | 0, _ => throw "PSCV0-ABI-RESOURCE: type traversal exhausted"
  | fuel + 1, type => do
    match type with
    | .primitive p => return "primitive:" ++ psIrCheckPrimitiveName p
    | .named name arguments =>
      return "data:" ++ toString name.length ++ ":" ++ name ++ "[" ++
        String.intercalate "," (← arguments.mapM (abiTypeKey fuel)) ++ "]"
    | _ => throw "PSCV0-WIT-CAPABILITY: concrete first-order value required"

def addAbiNode (node : AbiNode) : AbiM Nat := do
  let plan : AbiPlan ← get
  if let some (_, index) := plan.nodes.zipIdx.find? (fun p => p.1.key == node.key) then return index
  if plan.nodes.any (fun n => n.name == node.name) then
    throw ("PSCV0-WIT-NAME: type collision: " ++ node.name)
  set { plan with nodes := plan.nodes ++ [node] }
  return plan.nodes.length

def abiFieldsLayout (fields : List (String × Nat × PsVerifiedIrType)) :
    AbiM (List AbiField × Nat × Nat × Nat) := do
  let plan : AbiPlan ← get
  let mut result : List AbiField := []
  let mut size := 0
  let mut alignment := 1
  let mut flat := 0
  for ((name, node, formal), index) in fields.zipIdx do
    let child ← abiNode plan node
    let offset := abiAlign size child.alignment
    result := result ++ [{ name := witName name, node, offset, formal, index }]
    size := offset + child.size
    alignment := max alignment child.alignment
    flat := flat + child.flat
  if (result.map (·.name)).eraseDups.length != result.length then throw "PSCV0-WIT-NAME: field collision"
  return (result, abiAlign size alignment, alignment, flat)

-- Concrete signatures are planned once. Recursive data and function values
-- require an explicitly selected resource/view API; they are never flattened
-- speculatively or confused with numeric handles.
def planAbiType (ir : PsVerifiedIrModule) :
    Nat → List String → PsVerifiedIrType → AbiM Nat
  | 0, _, _ => throw "PSCV0-ABI-RESOURCE: type planning exhausted"
  | fuel + 1, seen, type => do
    let key ← abiTypeKey 4096 type
    let plan : AbiPlan ← get
    if let some (_, index) := plan.nodes.zipIdx.find? (fun p => p.1.key == key) then return index
    if seen.contains key then throw ("PSCV0-WIT-CAPABILITY: recursive value requires an explicit resource/view API: " ++ key)
    let child := planAbiType ir fuel (key :: seen)
    let readable ← match type with
      | .primitive p => pure (psIrCheckPrimitiveName p)
      | .named name arguments => do
        let arguments ← arguments.mapM (fun arg => do return ← abiTypeKey 4096 arg)
        pure (name ++ (if arguments.isEmpty then "" else "-" ++ String.intercalate "-" arguments))
      | _ => pure key
    let name := witName readable
    let make := fun shape size alignment flat =>
      addAbiNode { key, name, type, shape, size, alignment, flat }
    match type with
    | .primitive .bool => make (.scalar .bool) 1 1 1
    | .primitive .char => make (.scalar .char) 4 4 1
    | .primitive .string => make .string 8 4 2
    | .primitive .nat =>
      let limbs ← addAbiNode {
        key := "@natural-limbs", name := "natural-limbs", type := .primitive .nat,
        shape := .limbs, size := 8, alignment := 4, flat := 2 }
      make (.natural limbs) 8 4 2
    | .primitive .int =>
      let negative ← child (.primitive .bool)
      let magnitude ← child (.primitive .nat)
      make (.integer negative magnitude) 12 4 3
    | .named "Array" [element] =>
      let element ← child element
      make (.list element) 8 4 2
    | .named runtimeName arguments =>
      if !((ir.foreignData.find? (fun p => p.1 == runtimeName)).map (·.2)).getD false then
        throw ("PSCV0-WIT-INVARIANT: dependent/proof-bearing data requires an explicit validating adapter: " ++ runtimeName)
      if let some s := ir.structures.find? (fun s => s.name == runtimeName) then
        let fields ← s.fields.mapM fun field => do
          let concrete ← substitute s.typeParameters arguments field.type
          return (field.name, ← child concrete, field.type)
        if fields.isEmpty then throw ("PSCV0-WIT-CAPABILITY: empty record requires a selected finite view: " ++ name)
        let (fields, size, alignment, flat) ← abiFieldsLayout fields
        make (.record runtimeName fields) size alignment flat
      else
        let i ← requireInductive ir runtimeName
        if i.constructors.isEmpty then throw ("PSCV0-WIT-CAPABILITY: uninhabited public type: " ++ name)
        let mut cases : List AbiCase := []
        let mut payloadSize := 0
        let mut payloadAlignment := 1
        let mut payloadFlat := 0
        for (ctor, tag) in i.constructors.zipIdx do
          let fields ← ctor.fields.mapM fun field => do
            return (field.name, ← child (← substitute i.typeParameters arguments field.type), field.type)
          let (fields, size, alignment, flat) ← abiFieldsLayout fields
          let payload ← if fields.isEmpty then pure none else do
            let id ← addAbiNode {
              key := key ++ "::" ++ ctor.name, name := name ++ "-" ++ witName ctor.name ++ "-payload",
              type, shape := .payload fields, size, alignment, flat }
            pure (some id)
          cases := cases ++ [{
            name := witName ctor.name, constructor := constructorTypeName runtimeName ctor.name, fields, payload, tag }]
          payloadSize := max payloadSize size
          payloadAlignment := max payloadAlignment alignment
          payloadFlat := max payloadFlat flat
        if (cases.map (·.name)).eraseDups.length != cases.length then throw "PSCV0-WIT-NAME: variant case collision"
        let tagSize := if cases.length <= 256 then 1 else if cases.length <= 65536 then 2 else 4
        let offset := abiAlign tagSize payloadAlignment
        let alignment := max tagSize payloadAlignment
        make (.variant runtimeName cases offset tagSize)
          (abiAlign (offset + payloadSize) alignment) alignment (1 + payloadFlat)
    | .primitive .unit => throw "PSCV0-WIT-CAPABILITY: Unit/proof slots are omitted only as results"
    | _ => throw ("PSCV0-WIT-CAPABILITY: explicit foreign adapter required: " ++ name)

def canonicalAbiPlan (ir : PsVerifiedIrModule) (exports : List (String × PsVerifiedIrDeclaration)) :
    Except String AbiPlan := do
  let action : AbiM Unit := do
    for (semanticName, d) in exports do
      if !d.typeParameters.isEmpty then throw ("PSCV0-WIT-CAPABILITY: concrete export required: " ++ semanticName)
      let parameters ← d.parameters.mapM fun p => do
        return (witName p.name, ← planAbiType ir 4096 [] p.type)
      let result ← match d.resultType with
        | .primitive .unit => pure none
        | type => (planAbiType ir 4096 [] type).map some
      let (fields, size, _, flat) ← abiFieldsLayout
        (parameters.map fun (name, node) => (name, node, PsVerifiedIrType.unknown))
      let plan : AbiPlan ← get
      let resultFlat ← match result with | none => pure 0 | some n => do return (← abiNode plan n).flat
      let foreignName := witName semanticName
      if plan.exports.any (fun e => e.foreignName == foreignName) ||
          plan.nodes.any (fun n => n.name == foreignName) then
        throw ("PSCV0-WIT-NAME: public collision: " ++ foreignName)
      set { plan with exports := plan.exports ++ [{
        semanticName, foreignName, target := d.name, parameters, result,
        parameterOffsets := fields.map (·.offset), parameterSize := size,
        indirectParameters := flat > 16, indirectResult := resultFlat > 1 : AbiExport }] }
  let (_, plan) ← action.run {}
  return plan

end PsWasm
