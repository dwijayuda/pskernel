import Ps.Host.SourceBindings

open Ps.Internal.CompilerService

private def demand (condition : Bool) (code : String) : IO Unit :=
  if condition then pure () else throw (IO.userError ("PSC1_OWNERSHIP_" ++ code))

def main (args : List String) : IO Unit := do
  let [mode, input, output, admissionsPath, irPath] := args
    | throw (IO.userError "PSC1_OWNERSHIP_USAGE")
  demand (["index", "bindings", "reference", "to-lean", "to-ps", "compare-bindings"].contains mode) "MODE"
  let bytes ← IO.FS.readBinFile input
  demand (bytes.size ≤ 33554432) "REQUEST_LIMIT"
  let some text := String.fromUTF8? bytes | throw (IO.userError "PSC1_OWNERSHIP_UTF8")
  if mode == "compare-bindings" then
    let response := match Ps.Internal.SourceBindingComparison.compare text with
      | .ok value => value
      | .error message => Lean.Json.mkObj [
          ("protocol", .str "psc1-source-binding-comparison/1"),
          ("status", .str "refused"), ("code", .str message)]
    demand (response.compress.utf8ByteSize ≤ 33554432) "RESPONSE_LIMIT"
    IO.FS.writeFile output response.compress
    return
  let request ← match decode text with
    | .ok value => pure value
    | .error error => throw (IO.userError ("PSC1_OWNERSHIP_WIRE:" ++ error.phase ++ ":" ++ error.code))
  demand (request.sources.length ≤ 256) "MODULE_LIMIT"
  demand (request.sources.all (fun s => s.text.utf8ByteSize ≤ 1048576)) "SOURCE_LIMIT"
  if mode == "to-lean" || mode == "to-ps" then
    let grammar := if mode == "to-lean" then "lean" else "ps"
    let target := if mode == "to-lean" then PsCompilerSourceKind.lean else .proofScript
    let response := match psOwnershipConvert request target grammar with
      | .ok value => value
      | .error error => Lean.Json.mkObj [
          ("protocol", .str "psc1-source-conversion/1"), ("status", .str "refused"),
          ("requestId", .str request.requestId), ("sourceClosureDigest", .str request.sourceClosureDigest),
          ("error", error)]
    demand (response.compress.utf8ByteSize ≤ 33554432) "RESPONSE_LIMIT"
    IO.FS.writeFile output response.compress
    return
  let outcome := if mode == "reference" then do
      let c ← (captureWorker request request.sources
        (Captured.mk (psCompilerPreparationStart request.kind) [] [] [] none)).mapError
        (fun e => psOwnershipError e.moduleName e.phase e.code)
      let _ ← (exactClosureWorker c.graphRev [request.entry]).mapError
        (fun e => psOwnershipError e.moduleName e.phase e.code)
      if c.entry.isNone then throw (psOwnershipError request.entry "capture" "entry-missing")
      pure (c, #[])
    else psOwnershipCaptureWithSourceTrace request (mode == "bindings")
  let result := do
    let (captured, rows) ← outcome
    let semantic ← psOwnershipPrepare request captured
    return (rows, semantic)
  match result with
  | .error error =>
      IO.FS.writeFile output ((Lean.Json.mkObj [
        ("protocol", .str "psc1-source-ownership/1"), ("status", .str "refused"),
        ("requestId", .str request.requestId), ("sourceClosureDigest", .str request.sourceClosureDigest),
        ("error", error)]).compress)
  | .ok (rows, semantic) =>
      let ir ← match psIrEncodeModule semantic.raw with
        | .ok value => pure value
        | .error _ => throw (IO.userError "PSC1_OWNERSHIP_IR_ENCODING")
      demand (semantic.admissions.utf8ByteSize ≤ 33554432 && ir.utf8ByteSize ≤ 33554432) "GRAPH_LIMIT"
      let response := (Lean.Json.mkObj [
        ("protocol", .str "psc1-source-ownership/1"), ("status", .str "prepared"),
        ("requestId", .str request.requestId), ("sourceClosureDigest", .str request.sourceClosureDigest),
        ("grammar", .str request.grammar), ("assurance", .str request.assurance),
        ("entry", .str request.entry), ("modules", .arr rows),
        ("sourceCoreDeclarations", Lean.toJson semantic.source.length),
        ("logicalCoreDeclarations", Lean.toJson semantic.logicalCount),
        ("partialNames", Lean.toJson (semantic.partialNames.map (fun n => psNameToString n)))]).compress
      demand (response.utf8ByteSize ≤ 33554432) ("RESPONSE_LIMIT:" ++ toString response.utf8ByteSize)
      IO.FS.writeFile admissionsPath semantic.admissions
      IO.FS.writeFile irPath ir
      IO.FS.writeFile output response
