import Ps.CompilerUnified.Service
import Lean.Data.Json

/-! Native bootstrap IO only. The same portable candidate entry computes all
semantics. Candidate files remain quarantined pending independent admission. -/
def main (args : List String) : IO Unit := do
  let [input, directory] := args | throw (IO.userError "PSC1_PORTABLE_SEED_ARGUMENTS")
  let request ← IO.FS.readFile input
  if request.utf8ByteSize > 33554432 then throw (IO.userError "PSC1_EXECUTABLE_REQUEST_BOUND")
  let response := psCompilerServiceCandidate request
  if response.utf8ByteSize > 134217728 then throw (IO.userError "PSC1_EXECUTABLE_OUTPUT_BOUND")
  let parsed ← match Lean.Json.parse response with
    | .ok value => pure value
    | .error reason => throw (IO.userError reason)
  let status ← match parsed.getObjValAs? String "status" with
    | .ok value => pure value
    | .error reason => throw (IO.userError reason)
  if status != "candidate" then throw (IO.userError response)
  let rows ← match (parsed.getObjVal? "files").bind Lean.Json.getArr? with
    | .ok value => pure value.toList
    | .error reason => throw (IO.userError reason)
  let allowed := ["original-ir.json", "specialized-ir.json", "fused-ir.json",
    "admissions.json", "capture.json", "modules.json", "js-runtime.mjs",
    "reference.mjs", "reference.mts"] ++ (List.range 257).flatMap (fun index =>
      let suffix := "/unit-" ++ toString index
      ["js" ++ suffix ++ ".mjs", "js" ++ suffix ++ ".d.mts", "ts" ++ suffix ++ ".mts"])
  if rows.length > allowed.length then throw (IO.userError "PSC1_EXECUTABLE_FILE_COUNT")
  let mut seen : List String := []
  let mut total := 0
  IO.FS.createDirAll (directory ++ "/js")
  IO.FS.createDirAll (directory ++ "/ts")
  for row in rows do
    let (name, text) ← match row.getArr? with
      | .ok #[.str name, .str text] => pure (name, text)
      | _ => throw (IO.userError "PSC1_EXECUTABLE_FILE_ROW")
    if !allowed.contains name || seen.contains name then
      throw (IO.userError "PSC1_EXECUTABLE_OUTPUT_PATH")
    seen := name :: seen
    if text.utf8ByteSize > 33554432 then throw (IO.userError "PSC1_EXECUTABLE_FILE_BOUND")
    total := total + text.utf8ByteSize
    if total > 134217728 then throw (IO.userError "PSC1_EXECUTABLE_STAGE_AGGREGATE_BOUND")
    IO.FS.writeFile (directory ++ "/" ++ name) text
  IO.println ("PSC1_PORTABLE_NATIVE_CANDIDATE " ++
    (Lean.Json.mkObj [("files", Lean.toJson seen.length), ("bytes", Lean.toJson total),
      ("wireBytes", Lean.toJson response.utf8ByteSize), ("admission", .str "not-run")]).compress)

