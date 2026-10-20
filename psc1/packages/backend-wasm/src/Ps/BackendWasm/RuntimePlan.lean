import Ps.BackendWasm.Lower
import Ps.BackendWasm.Encode

/-- Runtime calls are selected from the lowered instruction graph. Keep all user
functions and their closure references, and close only the backend helper set. -/
private def runtimeNames : List String :=
  (psWasmNatRuntimeFunctions ++ psWasmIntRuntimeFunctions ++
    psWasmStringRuntimeFunctions ++ psWasmIntReprRuntimeFunctions).map (fun f => f.name)

private def calls (function : PsWasmFunction) : List String :=
  function.body.filterMap fun instruction => match instruction with
    | .call name | .returnCall name | .refFunc name => some name
    | _ => none

private def closeHelpers (remaining : Nat) (helpers : List PsWasmFunction)
    (pending seen : List String) : List String :=
  match remaining with
  | 0 => seen
  | rest + 1 =>
      let fresh := helpers.filter (fun f => pending.contains f.name && !seen.contains f.name)
      if fresh.isEmpty then seen
      else closeHelpers rest helpers (fresh.flatMap calls) (seen ++ fresh.map (fun f => f.name))

def psWasmSelectRuntime (source : PsWasmModule) : PsWasmModule :=
  let helpers := source.functions.filter (fun f => runtimeNames.contains f.name)
  let userFunctions := source.functions.filter (fun f => !runtimeNames.contains f.name)
  let roots := userFunctions.flatMap calls ++ source.functionRefs ++ source.exports.map (fun e => e.2)
  -- There can be at most helpers.length fresh graph layers. This is finite
  -- compilation graph traversal, never a limit on execution or recursion.
  let needed := closeHelpers (helpers.length + 1) helpers roots []
  { source with functions := source.functions.filter (fun f =>
      !runtimeNames.contains f.name || needed.contains f.name) }

def psWasmRuntimeRequirements (source : PsWasmModule) : List String :=
  (source.functions.filter (fun f => runtimeNames.contains f.name)).map (fun f => f.name)

/-- The runtime digest covers canonical lowered helper IR, including actual
instructions after the tail-call pass. It is not advertised as a WAT source hash. -/
def psWasmRuntimeCanonicalSource (source : PsWasmModule) : Except String String := do
  let helpers := source.functions.filter (fun f => runtimeNames.contains f.name)
  if helpers.isEmpty then return ""
  match psWasmIrEncodeValues (helpers.map psWasmIrEncodeFunction) with
  | .ok value => return value
  | .error _ => throw "PSC1_WASM_RUNTIME_DESCRIPTOR_FAILED"
