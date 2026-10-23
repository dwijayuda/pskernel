import Ps.BackendWasm.CompilerService
open Ps.Internal.CompilerService

private def requireProbe {α : Type} (value : Except Error α) : IO α :=
  match value with
  | .error error => throw (IO.userError (error.phase ++ ":" ++ error.code))
  | .ok result => pure result

def main (args : List String) : IO Unit := do
  let [input, output] := args | throw (IO.userError "usage: request.json findings.json")
  let request <- requireProbe (decode (<- IO.FS.readFile input))
  let initial := Captured.mk (psCompilerPreparationStart request.kind) [] [] [] Option.none
  let captured <- requireProbe (captureWorker request request.sources initial)
  let work <- requireProbe (prepare request captured)
  let report := psCheckVerifiedIrModule psIrCheckDefaultOptions work.raw
  let finding := fun (row : PsIrCheckFinding) => psJsonObject [
    ("code",psJsonQuote row.code),("detail",psJsonQuote row.detail),
    ("owner",psJsonQuote row.owner),("path",psJsonQuote row.path)]
  let text := psJsonObject [
    ("schema",psJsonQuote "psc1-direct-wasm-original-ir-diagnosis/1"),
    ("sourceClosureDigest",psJsonQuote request.sourceClosureDigest),
    ("accepted",if report.accepted then "true" else "false"),
    ("traversalComplete",if report.traversalComplete then "true" else "false"),
    ("visitedSteps",psNatToString report.visitedSteps),
    ("findingCount",psNatToString report.findingCount),
    ("findings",psJsonArray (psListMap finding report.findings)),
    ("qualification","false")]
  IO.FS.writeFile output text
  IO.println ("PSC1_DIRECT_WASM_ORIGINAL_IR_DIAGNOSIS: " ++ text)
