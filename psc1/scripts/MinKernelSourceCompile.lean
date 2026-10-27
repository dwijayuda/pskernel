import Ps.BackendTs.Sh1
import Ps.Host.ProjectCompiler

def minKernelCompilerFailure (error : PsCompilerError) : String :=
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
def minKernelSourceFailure (error : PsSh1EmitError) : String :=
  match error with
  | .source sourceError =>
    match sourceError with
    | .policy finding => finding.code ++ ": " ++ finding.detail
    | .origin moduleName failure =>
      moduleName ++ ": " ++ psHostElabErrorText failure.error
    | .compiler moduleName failure => moduleName ++ ": " ++ minKernelCompilerFailure failure
  | .compiler failure => minKernelCompilerFailure failure
  | .checkedEmit _ => "strict IR or emitter refused"
  | .target finding => finding.code ++ ": " ++ finding.detail

def main : IO Unit := do
  let checker ← IO.FS.readFile "packages/pskernel-min/src/Ps/MinKernel/Check.lean"
  let vectors ← IO.FS.readFile "packages/pskernel-min/src/Ps/MinKernel/Tests/Vectors.lean"
  let inputs := [psSh1SourceInput ["Ps", "MinKernel", "Check"] checker,
    psSh1SourceInput ["Ps", "MinKernel", "Tests", "Vectors"] vectors]
  match psCompilerSh1TypeScriptSources psSh1DefaultSourceOptions
      psIrCheckDefaultOptions PsCompilerSourceKind.lean inputs with
  | .error error => throw (IO.userError (minKernelSourceFailure error))
  | .ok result =>
    if !result.sourcePolicy.accepted || !result.targetPolicy.accepted ||
        !result.checkReport.accepted then
      throw (IO.userError "PSC1_MIN_SOURCE_OR_IR_REFUSED")
    IO.FS.writeFile "dist/pskernel-min/portable/vectors.ts" result.typeScript
    IO.FS.writeFile "dist/pskernel-min/portable/vectors.admissions.json" result.admissions
    IO.FS.writeFile "dist/pskernel-min/portable/vectors.source.json"
      (psJsonObject [("schema", psJsonQuote "psc1-min-source-compile/1"),
        ("sourceAccepted", "true"), ("targetAccepted", "true"),
        ("originalIrAccepted", "true"), ("providerChecked", "false"),
        ("moduleCount", toString result.sourcePolicy.moduleCount)] ++ "\n")
    IO.println "PSC1_MIN_SOURCE_COMPILE_PASS: candidate only; independent admission still required"
