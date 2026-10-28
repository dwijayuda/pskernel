import Ps.MinKernel.Tests.ByteCursor
import Ps.BackendTs.Sh1
import Ps.Host.ProjectCompiler
import Ps.CompilerIr.Encode
import Lean

def byteCursorCompilerFailure (error : PsCompilerError) : String :=
  match error with
  | .elaboration failure => psHostElabErrorText failure
  | .leanFrontend failure =>
    match failure with
    | .lex error => psHostLexErrorText error
    | .parse error => psHostParseErrorText error
  | .proofScriptFrontend failure =>
    match failure with
    | .lex error => psHostLexErrorText error
    | .parse error => psHostParseErrorText error
  | .translation _ => "translation refused"
  | .admission _ => "canonical admission encoding refused"
  | .erasure _ => "erasure refused"

-- Linux CI transport only. The source-owned compiler performs all frontend,
-- canonical preparation and strict original/transformed IR checks.
def byteCursorSourceFailure (error : PsSh1EmitError) : String :=
  match error with
  | .source sourceError =>
    match sourceError with
    | .policy finding => finding.code ++ ": " ++ finding.detail
    | .origin moduleName failure =>
      moduleName ++ ": " ++ psHostElabErrorText failure.error
    | .compiler moduleName failure => moduleName ++ ": " ++ byteCursorCompilerFailure failure
  | .compiler failure => byteCursorCompilerFailure failure
  | .checkedEmit _ => "strict IR or emitter refused"
  | .target finding => finding.code ++ ": " ++ finding.detail



def main : IO Unit := do
  let dir := "dist/pskernel-min/byte-cursor"
  IO.FS.createDirAll dir
  let vectorText ← IO.FS.readFile (dir ++ "/vectors.json")
  let vectorJson ← match Lean.Json.parse vectorText with
    | .ok value => pure value
    | .error message => throw (IO.userError message)
  let vectors ← match vectorJson.getArr? with
    | .ok value => pure value
    | .error message => throw (IO.userError message)
  let mut rows : List Lean.Json := []
  for row in vectors do
    let field (name : String) : IO String :=
      match row.getObjValAs? String name with
      | .ok value => pure value
      | .error message => throw (IO.userError message)
    let number (name : String) : IO Nat :=
      match row.getObjValAs? Nat name with
      | .ok value => pure value
      | .error message => throw (IO.userError message)
    let label ← field "label"
    let file ← field "file"
    let command ← field "command"
    let expected ← field "expected"
    let size ← number "size"
    let offset ← number "offset"
    let remaining ← number "remaining"
    let invalid ← match row.getObjValAs? Bool "invalid" with
      | .ok value => pure value
      | .error message => throw (IO.userError message)
    let bytes ← IO.FS.readBinFile file
    let byteAt : Nat → Nat := fun index =>
      if invalid then 256 else (bytes[index]!).toNat
    let actual :=
      if command == "read" then psMinByteCursorReadCode size byteAt offset
      else if command == "walk" then psMinByteCursorWalkCode remaining size byteAt
      else psMinByteCursorDigest size byteAt
    unless toString actual == expected do
      throw (IO.userError ("BYTE_CURSOR_NATIVE:" ++ label ++ ":" ++ toString actual))
    rows := rows ++ [Lean.Json.mkObj [("label",Lean.toJson label),
      ("actual",Lean.toJson (toString actual))]]
  IO.FS.writeFile (dir ++ "/native.json") (Lean.toJson rows).compress
  let source ← IO.FS.readFile (dir ++ "/inputs.json")
  let json ← match Lean.Json.parse source with
    | .ok value => pure value
    | .error message => throw (IO.userError message)
  let array ← match json.getArr? with
    | .ok value => pure value
    | .error message => throw (IO.userError message)
  let inputs ← array.toList.mapM fun row => do
    let names ← match row.getObjValAs? (Array String) "moduleName" with
      | .ok value => pure value
      | .error message => throw (IO.userError message)
    let text ← match row.getObjValAs? String "source" with
      | .ok value => pure value
      | .error message => throw (IO.userError message)
    pure (psSh1SourceInput names.toList text)
  match psCompilerSh1TypeScriptSources psSh1DefaultSourceOptions psIrCheckDefaultOptions PsCompilerSourceKind.lean inputs with
  | .error error => throw (IO.userError (byteCursorSourceFailure error))
  | .ok result =>
      unless result.sourcePolicy.accepted && result.targetPolicy.accepted &&
          result.checkReport.accepted && result.checkReport.traversalComplete do
        throw (IO.userError "BYTE_CURSOR_SOURCE_GUARD")
      IO.FS.writeFile (dir ++ "/cursor.ts") result.typeScript
      IO.FS.writeFile (dir ++ "/cursor.admissions.json") result.admissions
      match psIrEncodeModule result.originalIr with
      | .error _ => throw (IO.userError "BYTE_CURSOR_IR_ENCODING")
      | .ok text => IO.FS.writeFile (dir ++ "/cursor.ir.json") text
      IO.FS.writeFile (dir ++ "/policy.json") (Lean.Json.mkObj [
        ("sourceAccepted",Lean.toJson result.sourcePolicy.accepted),
        ("targetAccepted",Lean.toJson result.targetPolicy.accepted),
        ("originalIrAccepted",Lean.toJson result.checkReport.accepted),
        ("moduleCount",Lean.toJson result.sourcePolicy.moduleCount),
        ("providerChecked",Lean.toJson result.providerChecked),
        ("semanticContractQualified",Lean.toJson result.semanticContractQualified),
        ("strictSh1Qualified",Lean.toJson result.strictSh1Qualified)]).compress
  IO.println "PSC1_BYTE_CURSOR_NATIVE_SOURCE_PASS"
