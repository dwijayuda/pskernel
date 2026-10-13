import Ps.BackendWasm.Intrinsic
import Ps.BackendWasm.Layout
import Ps.Codegen.Captures
import Ps.Codegen.Names

namespace PsWasm

structure Binding where
  name : String
  index : Nat
  type : PsVerifiedIrType

structure Compiled where
  code : List PsWasmInstruction
  type : PsVerifiedIrType

structure LowerState where
  locals : List PsWasmValueType := []
  names : List String := []
  lifted : List RuntimeDefinition := []
  arities : List Nat := [1, 2]
  next : Nat := 0
  owner : String := ""

abbrev LowerM := StateT LowerState (Except String)

def allocateLocal (name : String) (type : PsWasmValueType) : LowerM Nat := do
  let state ← get
  let index := state.locals.length
  let name := psCodegenFresh (state.names.length + 1) state.names (psCodegenBaseName name)
  set { state with locals := state.locals ++ [type], names := state.names ++ [name] }
  return index

def allocateBinding (name : String) (type : PsVerifiedIrType) : LowerM Binding := do
  return { name, type, index := ← allocateLocal name (← representation type) }

def converted (value : Compiled) (expected : PsVerifiedIrType) : Except String (List PsWasmInstruction) := do
  return value.code ++ (← convert value.type expected)

def requireDeclaration (ir : PsVerifiedIrModule) (name : String) : Except String PsVerifiedIrDeclaration :=
  match ir.declarations.find? (fun d => d.name == name) with
  | some d => pure d
  | none => throw ("PSCV0-WASM-LINK: unknown declaration " ++ name)

def requireStructure (ir : PsVerifiedIrModule) (name : String) : Except String PsVerifiedIrStructure :=
  match ir.structures.find? (fun d => d.name == name) with
  | some d => pure d
  | none => throw ("PSCV0-WASM-LAYOUT: unknown record " ++ name)

def requireInductive (ir : PsVerifiedIrModule) (name : String) : Except String PsVerifiedIrInductive :=
  match ir.inductives.find? (fun d => d.name == name) with
  | some d => pure d
  | none => throw ("PSCV0-WASM-LAYOUT: unknown variant " ++ name)

def requireConstructor (i : PsVerifiedIrInductive) (name : String) :
    Except String (PsVerifiedIrConstructor × Nat) :=
  match i.constructors.zipIdx.find? (fun p => p.1.name == name) with
  | some c => pure c
  | none => throw ("PSCV0-WASM-LAYOUT: unknown constructor " ++ name)

def literalCode (literal : PsVerifiedIrLiteral) : Except String Compiled := do
  match literal with
  | .natural value => return { code := naturalLiteral value, type := .primitive .nat }
  | .integer value => return { code := integerLiteral value, type := .primitive .int }
  | .string value => return { code := stringLiteral value, type := .primitive .string }
  | .bool value => return { code := [.i32Const (if value then 1 else 0)], type := .primitive .bool }
  | .unit => return { code := [.i32Const 0], type := .primitive .unit }
  | .machineInteger width value =>
    let type ← (psIrCheckLiteralType literal).mapError (fun e => "PSCV0-WASM-LITERAL: " ++ e.code)
    return { code := psWasmLowerMachineIntegerLiteral ⟨.wasm32⟩ width value, type }

def fieldIndex (fields : List (String × PsVerifiedIrType)) (name : String) :
    Except String (PsVerifiedIrType × Nat) :=
  match fields.zipIdx.find? (fun p => p.1.1 == name) with
  | some ((_, type), index) => pure (type, index)
  | none => throw ("PSCV0-WASM-LAYOUT: unknown field " ++ name)

end PsWasm
