import Ps.BackendWasm.Wat

namespace PsWasm

private def indexedNames (names : List String) : List UInt8 :=
  psWasmEncodeUleb names.length ++ (names.zipIdx.flatMap fun (name, index) =>
    psWasmEncodeUleb index ++ psWasmEncodeName name)

private def nestedNames (names : List (List String)) : List UInt8 :=
  psWasmEncodeUleb names.length ++ (names.zipIdx.flatMap fun (locals, index) =>
    psWasmEncodeUleb index ++ indexedNames locals)

-- Debug names never participate in linking. The same retained identity/local
-- tables supply WAT labels and standard binary name metadata.
def coreNameSection (core : PsWasmModule) (locals : LocalNames) : List UInt8 :=
  let typeNames := core.structures.map (·.name) ++ core.arrays.map (·.name) ++
    core.functionTypes.map (·.name) ++
    core.functions.zipIdx.map (fun (_, index) => anonymousTypeName core index)
  psWasmEncodeSection 0 (psWasmEncodeName "name" ++
    psWasmEncodeSection 1 (indexedNames (core.functions.map (·.name))) ++
    psWasmEncodeSection 2 (nestedNames (core.functions.map (functionLocalNames locals))) ++
    psWasmEncodeSection 4 (indexedNames typeNames) ++
    psWasmEncodeSection 10 (nestedNames (core.structures.map fun s => s.fields.map (·.name))))

def namedCoreBinary (core : PsWasmModule) (locals : LocalNames) : Except String (List UInt8) := do
  let bytes ← (psWasmEncodeModule core).mapError (fun e => "PSCV0-WASM-ENCODE: " ++ reprStr e)
  return bytes ++ coreNameSection core locals

end PsWasm
