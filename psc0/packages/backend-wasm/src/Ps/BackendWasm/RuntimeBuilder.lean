import Ps.BackendWasm.Model
import Ps.BackendWasm.TailCalls

namespace PsWasm

-- Small authoring combinators for compiler-owned runtime functions. These
-- resolve named locals into the existing typed target IR; they are not a
-- second source language or a runtime interpreter.
inductive RuntimeCode where
  | get (name : String)
  | set (name : String) (value : RuntimeCode)
  | i32 (value : Int)
  | i64 (value : Int)
  | op (instruction : PsWasmInstruction) (arguments : List RuntimeCode)
  | call (name : String) (arguments : List RuntimeCode)
  | seq (steps : List RuntimeCode)
  | ite (result : Option PsWasmValueType) (condition yes no : RuntimeCode)

abbrev R := RuntimeCode

def runtimeCode (names : List String) : Nat → R → Except String (List PsWasmInstruction)
  | 0, _ => throw "PSCV0-WASM-RUNTIME: authoring depth exhausted"
  | n + 1, code => do
    let lower := runtimeCode names n
    let localIndex := fun name =>
      match names.zipIdx.find? (fun p => p.1 == name) with
      | some (_, index) => .ok index
      | none => .error ("PSCV0-WASM-RUNTIME: undeclared local " ++ name)
    match code with
    | .get name => return [.localGet (← localIndex name)]
    | .set name value => return (← lower value) ++ [.localSet (← localIndex name)]
    | .i32 value => return [.i32Const value]
    | .i64 value => return [.i64Const value]
    | .op instruction arguments => return (← arguments.mapM lower).flatten ++ [instruction]
    | .call name arguments => return (← arguments.mapM lower).flatten ++ [.call name]
    | .seq steps => return (← steps.mapM lower).flatten
    | .ite result condition yes no =>
      return (← lower condition) ++ [.ifStart result] ++ (← lower yes) ++
        [.else_] ++ (← lower no) ++ [.end_]

structure RuntimeDefinition where
  function : PsWasmFunction
  names : List String

def runtimeDefinition (name : String) (parameters : List (String × PsWasmValueType))
    (results : List PsWasmValueType) (locals : List (String × PsWasmValueType)) (body : R) :
    Except String RuntimeDefinition := do
  let names := (parameters ++ locals).map (·.1)
  if names.eraseDups.length != names.length then throw ("PSCV0-WASM-RUNTIME: duplicate local in " ++ name)
  return {
    function := {
      name, typeName := none, parameters := parameters.map (·.2)
      results, locals := locals.map (·.2)
      body := psWasmTailCalls (← runtimeCode names 65536 body) }
    names }

end PsWasm
