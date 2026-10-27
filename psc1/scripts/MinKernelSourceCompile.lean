import Ps.BackendTs.Sh1
import Ps.Host.ProjectCompiler

-- Linux CI transport only. The source-owned compiler performs all frontend,
-- canonical preparation and strict original/transformed IR checks.
def minKernelSourceFailure (error : PsSh1EmitError) : String :=
  match error with
  | .source sourceError =>
    match sourceError with
    | .policy finding => finding.code ++ ": " ++ finding.detail
    | .origin moduleName failure =>
      moduleName ++ ": " ++ psHostElabErrorText failure.error
    | .compiler moduleName _ => moduleName ++ ": source compiler refused"
  | .compiler _ => "compiler refused"
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
