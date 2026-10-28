import Ps.MinKernel.Tests.CompilerCaller
import Ps.BackendTs.Sh1
import Ps.Host.ProjectCompiler
import Ps.CompilerIr.Encode
import Lean

def callerCompilerFailure (error : PsCompilerError) : String :=
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
def callerSourceFailure (error : PsSh1EmitError) : String :=
  match error with
  | .source sourceError =>
    match sourceError with
    | .policy finding => finding.code ++ ": " ++ finding.detail
    | .origin moduleName failure =>
      moduleName ++ ": " ++ psHostElabErrorText failure.error
    | .compiler moduleName failure => moduleName ++ ": " ++ callerCompilerFailure failure
  | .compiler failure => callerCompilerFailure failure
  | .checkedEmit _ => "strict IR or emitter refused"
  | .target finding => finding.code ++ ": " ++ finding.detail



def main : IO Unit := do
  let dir := "dist/pskernel-min/compiler-caller"
  IO.FS.createDirAll dir
  let naturalValues : List Nat := [0, 1, 65536, 2^64+1, 2^256+7]
  let textValues := ["", "a", "λ", "🙂", String.singleton (Char.ofNat 0), "\"\\\n"]
  let mut rows : List Lean.Json := []
  for depth in [0, 1, 2, 4, 8, 16] do
    for typeBinder in [false, true] do
      for enough in [false, true] do
        let fuel := if enough then Nat.succ depth else depth
        for value in naturalValues do
          let actual := psCallerNatProbe depth typeBinder fuel value
          unless actual == enough do throw (IO.userError "CALLER_NATIVE_NAT")
          rows := rows ++ [Lean.Json.mkObj [
            ("name", Lean.toJson "psCallerNatProbe"), ("depth", Lean.toJson depth),
            ("typeBinder", Lean.toJson typeBinder), ("fuel", Lean.toJson fuel),
            ("value", Lean.toJson (toString value)), ("kind", Lean.toJson "nat"),
            ("expected", Lean.toJson enough)]]
        for value in textValues do
          let actual := psCallerTextProbe depth typeBinder fuel value
          let expected := if enough then String.append "ok:" value else "refused"
          unless actual == expected do throw (IO.userError "CALLER_NATIVE_TEXT")
          rows := rows ++ [Lean.Json.mkObj [
            ("name", Lean.toJson "psCallerTextProbe"), ("depth", Lean.toJson depth),
            ("typeBinder", Lean.toJson typeBinder), ("fuel", Lean.toJson fuel),
            ("value", Lean.toJson value), ("kind", Lean.toJson "text"),
            ("expected", Lean.toJson expected)]]
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
  | .error error => throw (IO.userError (callerSourceFailure error))
  | .ok result =>
      unless result.sourcePolicy.accepted && result.targetPolicy.accepted &&
          result.checkReport.accepted && result.checkReport.traversalComplete do
        throw (IO.userError "CALLER_SOURCE_GUARD")
      IO.FS.writeFile (dir ++ "/caller.ts") result.typeScript
      IO.FS.writeFile (dir ++ "/caller.admissions.json") result.admissions
      match psIrEncodeModule result.originalIr with
      | .error _ => throw (IO.userError "CALLER_IR_ENCODING")
      | .ok text => IO.FS.writeFile (dir ++ "/caller.ir.json") text
      IO.FS.writeFile (dir ++ "/policy.json") (Lean.Json.mkObj [
        ("sourceAccepted",Lean.toJson result.sourcePolicy.accepted),
        ("targetAccepted",Lean.toJson result.targetPolicy.accepted),
        ("originalIrAccepted",Lean.toJson result.checkReport.accepted),
        ("moduleCount",Lean.toJson result.sourcePolicy.moduleCount),
        ("providerChecked",Lean.toJson result.providerChecked),
        ("semanticContractQualified",Lean.toJson result.semanticContractQualified),
        ("strictSh1Qualified",Lean.toJson result.strictSh1Qualified)]).compress
  IO.println "PSC1_CALLER_NATIVE_SOURCE_PASS"
