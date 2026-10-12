import Ps.BackendWasm.Value

namespace PsWasm

def constructorTypeName (owner name : String) := "__ps_constructor_" ++ owner ++ "__" ++ name

def dataLayouts (ir : PsVerifiedIrModule) : Except String (List PsWasmStructType) := do
  let records ← ir.structures.mapM fun s => do
    return valueStructure s.name (← s.fields.mapM fun f => do return (f.name, ← representation f.type))
  let variants ← ir.inductives.mapM fun i => do
    let tag : PsWasmStructField := { name := "tag", storageType := .value .i32 }
    let base : PsWasmStructType := {
      name := i.name, superType := some valueName, isFinal := false, fields := [tag] }
    let constructors ← i.constructors.mapM fun ctor => do
      let fields ← ctor.fields.mapM fun f => do
        return { name := f.name, storageType := .value (← representation f.type) : PsWasmStructField }
      return {
        name := constructorTypeName i.name ctor.name, superType := some i.name,
        isFinal := true, fields := tag :: fields : PsWasmStructType }
    return base :: constructors
  return records ++ variants.flatten

-- Reachability is over retained target identities, including closure code.
def functionDependencies (f : PsWasmFunction) : List String :=
  f.body.filterMap fun instruction => match instruction with
    | .call n | .returnCall n | .refFunc n => some n
    | _ => none

def reachableFunctions (functions : List PsWasmFunction) :
    Nat → List String → List String → Except String (List String)
  | 0, [], seen => pure seen
  | 0, _, _ => throw "PSCV0-WASM-RESOURCE: function reachability budget exhausted"
  | fuel + 1, pending, seen => do
    match pending with
    | [] => return seen
    | name :: rest =>
      if seen.contains name then return ← reachableFunctions functions fuel rest seen
      let some fn := functions.find? (fun f => f.name == name)
        | throw ("PSCV0-WASM-LINK: unknown function " ++ name)
      reachableFunctions functions fuel (functionDependencies fn ++ rest) (name :: seen)

def pruneFunctions (core : PsWasmModule) : Except String PsWasmModule := do
  let edges := core.functions.foldl (fun n f => n + (functionDependencies f).length) 0
  let seen ← reachableFunctions core.functions
    (edges + core.exports.length + core.functions.length + 1) (core.exports.map (·.2)) []
  let functions := core.functions.filter (fun f => seen.contains f.name)
  let references := (functions.flatMap fun f => f.body.filterMap fun i =>
    match i with | .refFunc name => some name | _ => none).eraseDups
  return { core with functions, functionRefs := references }

end PsWasm
