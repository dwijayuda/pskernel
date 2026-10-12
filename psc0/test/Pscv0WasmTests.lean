import Ps.Host.NativeV7
import Ps.BackendWasm.Natural

namespace PsWasm

-- Focused compatibility fixture: a GC allocation/read lies on the executed
-- path of a lifted component export. No JS semantic imports or WAT assembler.
def gcComponentProbe : ScalarComponent := {
  core := { psWasmModuleEmpty with
    structures := [{
      name := "CapturedValue", superType := none, isFinal := true,
      fields := [{ name := "value", storageType := .value .i32 }] }]
    functions := [{
      name := "readCaptured", typeName := none, parameters := [.i32], results := [.i32], locals := [],
      body := [.localGet 0, .structNew "CapturedValue", .structGet "CapturedValue" 0] }]
    exports := [("readCaptured", "readCaptured")] }
  locals := [("readCaptured", ["value"])]
  exports := [{
    sourceName := "readCaptured", foreignName := "read-captured",
    parameters := [("value", .u32)], result := some .u32 }] }

-- One runtime qualification fixture covers limb carries/borrows, multiplication,
-- quotient/remainder and Lean's total division-by-zero semantics. The expected
-- values come from native Lean Nat; the generated functions execute GC arithmetic.
def naturalComponentProbe : Except String ScalarComponent := do
  let runtime ← naturalRuntime
  let large := 2^64 - 1
  let dividend := 2^130 + 5
  let divisor := 2^65 + 1
  let cases : List (String × String × Nat × Nat × Nat) := [
    ("carry", "add", large, 1, large + 1),
    ("borrow", "sub", 2^64, 1, large),
    ("saturating", "sub", 1, large, 0),
    ("product", "mul", large, large, large * large),
    ("quotient", "div", dividend, divisor, dividend / divisor),
    ("remainder", "mod", dividend, divisor, dividend % divisor),
    ("divisionZero", "div", large, 0, 0),
    ("remainderZero", "mod", large, 0, large)]
  let checks := cases.map fun (name, operation, left, right, expected) => {
    name, typeName := none, parameters := [], results := [.i32], locals := []
    body := naturalLiteral left ++ naturalLiteral right ++
      [.call ("__ps_nat_" ++ operation)] ++ naturalLiteral expected ++ [.call "__ps_nat_eq"]
    : PsWasmFunction }
  let core := {
    psWasmModuleEmpty with
    structures := valueStructures, arrays := valueArrays
    functions := runtime.map (·.function) ++ checks
    exports := checks.map fun f => (f.name, f.name) }
  return {
    core, locals := runtime.map fun d => (d.function.name, d.names)
    exports := checks.map fun f => {
      sourceName := f.name, foreignName := witName f.name, parameters := [], result := some .bool } }

end PsWasm


private def unwrap {α : Type} (result : Except String α) : IO α :=
  match result with
  | .ok value => pure value
  | .error message => throw (IO.userError message)

private def writePlan (stem : String) (plan : PsWasm.ScalarComponent) : IO Unit := do
  let core ← unwrap (PsWasm.checkedCore plan.core)
  let wasm ← unwrap (PsWasm.scalarComponentBinary plan)
  let wat ← unwrap (psRenderDoc (PsWasm.scalarComponentWat plan))
  let coreWat ← unwrap (psRenderDoc (PsWasm.watModuleDoc plan.core plan.locals))
  IO.FS.writeBinFile (stem ++ ".core.wasm") core
  IO.FS.writeBinFile (stem ++ ".wasm") wasm
  IO.FS.writeFile (stem ++ ".wat") (wat.text ++ "\n")
  IO.FS.writeFile (stem ++ ".core.wat") (coreWat.text ++ "\n")
  IO.FS.writeFile (stem ++ ".wit") (PsWasm.scalarWit plan)

def main : IO Unit := do
  let directory := "../dist/pscv0-native/wasm"
  IO.FS.createDirAll directory
  writePlan (directory ++ "/gc-probe") PsWasm.gcComponentProbe
  writePlan (directory ++ "/natural-probe") (← unwrap PsWasm.naturalComponentProbe)
  let source := "function both(left: Bool, right: Bool): Bool := if (left) { right } else { false }\n" ++
    "function invert(value: Bool): Bool := if (value) { false } else { true }\n"
  IO.FS.writeFile (directory ++ "/scalar.ps") source
  IO.FS.writeFile (directory ++ "/exports.json") "[\"both\", \"invert\"]"
  let requests : Array PsV7Native.Request := #[
    { source, targets := [.wasmComponent], outputStem := "scalar",
      exports := .selected ["both", "invert"] },
    { source := "const bigint: Nat := 18446744073709551617\n", targets := [.wasmCore] },
    { source, targets := [.wasmComponent], exports := .selected ["missing"] }]
  let batch ← match ← PsV7Native.runBatch requests with
    | .ok b => pure b
    | .error e => throw (IO.userError (reprStr e))
  for (result, i) in batch.results.toList.zipIdx do
    if i == 0 then
      let value ← match result with
        | .ok v => pure v
        | .error e => throw (IO.userError (reprStr e))
      for artifact in value.artifacts do
        for file in artifact.files do
          let path := directory ++ "/" ++ file.path
          match file.payload with
          | .text s => IO.FS.writeFile path s
          | .binary b => IO.FS.writeBinFile path b
    else
      match result with
      | .ok _ => throw (IO.userError "expected bounded-profile/export refusal")
      | .error e =>
        if e.phase != "ir/emit" then throw (IO.userError ("unexpected refusal phase: " ++ e.phase))
  IO.println "Wasm C3: scalar native pipeline, two refusals, typed GC/component fixture emitted."
