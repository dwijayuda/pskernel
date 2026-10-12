import Ps.Host.NativeV7

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
