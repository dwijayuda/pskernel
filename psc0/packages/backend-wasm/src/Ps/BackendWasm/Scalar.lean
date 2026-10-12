import Ps.BackendWasm.Model
import Ps.Codegen.Api

namespace PsWasm

structure ScalarState where
  types : List PsWasmValueType := []
  names : List String := []

def scalarUnit : PsVerifiedIrType → Bool
  | .primitive .unit => true
  | _ => false

abbrev ScalarM := StateT ScalarState (Except String)

def scalarType : PsVerifiedIrType → Except String PsWasmValueType
  | .primitive .bool | .primitive .char | .primitive .unit => pure .i32
  | _ => throw "PSCV0-WASM-C3-CAPABILITY: expected Bool, Char or Unit; aggregate/bigint runtime requires C4"

def scalarLocal (name : String) (type : PsWasmValueType) : ScalarM Nat := do
  let state ← get
  let index := state.types.length
  let output := psCodegenFresh (state.names.length + 1) state.names (psCodegenBaseName name)
  set { types := state.types ++ [type], names := state.names ++ [output] }
  return index

def scalarExpr (module : PsVerifiedIrModule) :
    Nat → List (String × Nat) → PsVerifiedIrExpr → ScalarM (List PsWasmInstruction)
  | 0, _, _ => throw "PSCV0-WASM-CAPABILITY: expression budget exhausted"
  | fuel + 1, locals, expr => do
    let lower := scalarExpr module fuel locals
    match expr with
    | .unreachable _ => return [.unreachable]
    | .literal (.bool b) => return [.i32Const (if b then 1 else 0)]
    | .literal .unit => return [.i32Const 0]
    | .literal _ => throw "PSCV0-WASM-C3-CAPABILITY: literal requires C4"
    | .var name =>
      match locals.find? (fun p => p.1 == name) with
      | some (_, index) => return [.localGet index]
      | none =>
        match module.declarations.find? (fun d => d.name == name) with
        | some d =>
          if !d.parameters.isEmpty then throw ("PSCV0-WASM-C3-CAPABILITY: function value " ++ name)
          return [.call name] ++ (if scalarUnit d.resultType then [.i32Const 0] else [])
        | none => throw ("PSCV0-WASM-CAPABILITY: unknown variable " ++ name)
    | .letE name type value body =>
      let value ← lower value
      let index ← scalarLocal name (← scalarType type)
      return value ++ [.localSet index] ++ (← scalarExpr module fuel ((name, index) :: locals) body)
    | .ifE condition yes no =>
      -- IR validation guarantees the branches have the same scalar type.
      return (← lower condition) ++ [.ifStart (some .i32)] ++
        (← lower yes) ++ [.else_] ++ (← lower no) ++ [.end_]
    | .call (.var name) [] args =>
      if locals.any (fun p => p.1 == name) then
        throw "PSCV0-WASM-C3-CAPABILITY: closure call requires C4"
      let some d := module.declarations.find? (fun d => d.name == name)
        | throw ("PSCV0-WASM-CAPABILITY: unknown function " ++ name)
      let instructions ← args.mapM lower
      return instructions.flatten ++ [.call name] ++
        (if scalarUnit d.resultType then [.i32Const 0] else [])
    | .intrinsic op [] args =>
      let instructions ← args.mapM lower
      let operation ← match op with
        | .boolNot => pure [.i32Const 0, .i32Eq]
        | .boolAnd => pure [.i32And]
        | .boolOr => pure [.i32Or]
        | .boolEq => pure [.i32Eq]
        | .boolNe => pure [.i32Ne]
        | _ => throw "PSCV0-WASM-C3-CAPABILITY: intrinsic requires C4"
      return instructions.flatten ++ operation
    | _ => throw "PSCV0-WASM-C3-CAPABILITY: expression requires C4"

def scalarModule (ir : PsVerifiedIrModule) :
    Except String (PsWasmModule × List (String × List String)) := do
  if !ir.imports.isEmpty then throw "PSCV0-WASM-CAPABILITY: external imports are not admitted"
  let functions ← ir.declarations.mapM fun d => do
    if !d.typeParameters.isEmpty then
      throw ("PSCV0-WASM-C3-CAPABILITY: generic declaration " ++ d.name)
    let parameters ← d.parameters.mapM (fun p => scalarType p.type)
    let result ← scalarType d.resultType
    let action : ScalarM (List PsWasmInstruction) := do
      let bindings ← d.parameters.mapM fun p => do
        return (p.name, ← scalarLocal p.name (← scalarType p.type))
      scalarExpr ir 65536 bindings.reverse d.body
    let (body, state) ← action.run {}
    let unitResult := scalarUnit d.resultType
    let function : PsWasmFunction := {
      name := d.name
      typeName := none
      parameters
      results := if unitResult then [] else [result]
      locals := state.types.drop parameters.length
      body := body ++ (if unitResult then [.drop] else []) }
    return (function, (d.name, state.names))
  return ({ psWasmModuleEmpty with
    functions := functions.map (·.1)
    exports := ir.declarations.map fun d => (d.name, d.name) }, functions.map (·.2))

end PsWasm
