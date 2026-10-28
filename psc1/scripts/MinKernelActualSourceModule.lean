import Ps.MinKernel.Tests.SourcePositions
import Ps.BackendTs.Sh1
import Ps.Host.ProjectCompiler
import Ps.CompilerIr.Encode
import Lean

def sourceModuleCompilerFailure (error : PsCompilerError) : String :=
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
def sourceModuleFailure (error : PsSh1EmitError) : String :=
  match error with
  | .source sourceError =>
    match sourceError with
    | .policy finding => finding.code ++ ": " ++ finding.detail
    | .origin moduleName failure =>
      moduleName ++ ": " ++ psHostElabErrorText failure.error
    | .compiler moduleName failure => moduleName ++ ": " ++ sourceModuleCompilerFailure failure
  | .compiler failure => sourceModuleCompilerFailure failure
  | .checkedEmit _ => "strict IR or emitter refused"
  | .target finding => finding.code ++ ": " ++ finding.detail



def main : IO Unit := do
  let dir := "dist/pskernel-min/module-matrix/source-runtime"
  IO.FS.createDirAll dir
  let values : List Nat := [0, 1, 65536, 2^64+1, 2^256+7]
  let mut rows : List Lean.Json := []
  for a in values do
    for b in values do
      for c in values do
        let entries := [
          ("psMinSourceByteOffset", psMinSourceByteOffset a b c, a),
          ("psMinSourceLine", psMinSourceLine a b c, b),
          ("psMinSourceColumn", psMinSourceColumn a b c, c)]
        for (label, actual, expected) in entries do
          unless actual == expected do throw (IO.userError ("ACTUAL_SOURCE_NATIVE:" ++ label))
          rows := rows ++ [Lean.Json.mkObj [
            ("name",Lean.toJson label),("values",Lean.toJson ([a,b,c].map toString)),
            ("expected",Lean.toJson (toString expected))]]
  for a in values do
    for d in values do
      let b := Nat.add a 1
      let c := Nat.add a 2
      let e := Nat.add d 3
      let f := Nat.add d 4
      let entries := [
        ("psMinSourceSpanStartOffset",psMinSourceSpanStartOffset a b c d e f,a),
        ("psMinSourceSpanStartLine",psMinSourceSpanStartLine a b c d e f,b),
        ("psMinSourceSpanStartColumn",psMinSourceSpanStartColumn a b c d e f,c),
        ("psMinSourceSpanStopOffset",psMinSourceSpanStopOffset a b c d e f,d),
        ("psMinSourceSpanStopLine",psMinSourceSpanStopLine a b c d e f,e),
        ("psMinSourceSpanStopColumn",psMinSourceSpanStopColumn a b c d e f,f)]
      for (label, actual, expected) in entries do
        unless actual == expected do throw (IO.userError ("ACTUAL_SOURCE_NATIVE:" ++ label))
        rows := rows ++ [Lean.Json.mkObj [
          ("name",Lean.toJson label),("values",Lean.toJson ([a,b,c,d,e,f].map toString)),
          ("expected",Lean.toJson (toString expected))]]
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
  | .error error => throw (IO.userError (sourceModuleFailure error))
  | .ok result =>
      unless result.sourcePolicy.accepted && result.targetPolicy.accepted &&
          result.checkReport.accepted && result.checkReport.traversalComplete do
        throw (IO.userError "ACTUAL_SOURCE_SOURCE_GUARD")
      IO.FS.writeFile (dir ++ "/module.ts") result.typeScript
      IO.FS.writeFile (dir ++ "/module.admissions.json") result.admissions
      match psIrEncodeModule result.originalIr with
      | .error _ => throw (IO.userError "ACTUAL_SOURCE_IR_ENCODING")
      | .ok text => IO.FS.writeFile (dir ++ "/module.ir.json") text
      IO.FS.writeFile (dir ++ "/policy.json") (Lean.Json.mkObj [
        ("sourceAccepted",Lean.toJson result.sourcePolicy.accepted),
        ("targetAccepted",Lean.toJson result.targetPolicy.accepted),
        ("originalIrAccepted",Lean.toJson result.checkReport.accepted),
        ("moduleCount",Lean.toJson result.sourcePolicy.moduleCount),
        ("providerChecked",Lean.toJson result.providerChecked),
        ("semanticContractQualified",Lean.toJson result.semanticContractQualified),
        ("strictSh1Qualified",Lean.toJson result.strictSh1Qualified)]).compress
  IO.println "PSC1_ACTUAL_SOURCE_NATIVE_SOURCE_PASS"
