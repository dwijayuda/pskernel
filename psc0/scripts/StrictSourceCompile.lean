import Ps.BackendTs.Sh1
import Ps.Host.ProjectCompiler

-- Native host IO only. The portable atomic API owns parsing, source policy,
-- preparation, erasure, IR checking, target admission and same-IR emission.
def psStrictNativeBool (value : Bool) : String :=
  if value then "true" else "false"

def psStrictNativePos (value : PsSourcePos) : String :=
  psJsonObject
    [("byteOffset", toString value.byteOffset),
     ("line", toString value.line),
     ("column", toString value.column)]

def psStrictNativeSpan (value : Option PsSourceSpan) : String :=
  match value with
  | none => "null"
  | some span =>
      psJsonObject
        [("start", psStrictNativePos span.start),
         ("stop", psStrictNativePos span.stop)]

def psStrictNativeCompilerDetail (error : PsCompilerError) : String :=
  match error with
  | .elaboration value => psHostElabErrorText value
  | .leanFrontend value =>
      match value with
      | .lex failure => psHostLexErrorText failure
      | .parse failure => psHostParseErrorText failure
  | .proofScriptFrontend value =>
      match value with
      | .lex failure => psHostLexErrorText failure
      | .parse failure => psHostParseErrorText failure
  | .translation _ => "source translation refused"
  | .admission _ => "admission codec refused"
  | .erasure _ => "runtime erasure refused"

def psStrictNativeError (error : PsSh1EmitError) : String :=
  let fields :=
    match error with
    | .source sourceError =>
        match sourceError with
        | .policy finding =>
            [("stage", psJsonQuote "source"),
             ("code", psJsonQuote finding.code),
             ("detail", psJsonQuote finding.detail),
             ("moduleName", psJsonQuote finding.moduleName),
             ("owner", psJsonQuote finding.owner),
             ("span", psStrictNativeSpan finding.span)]
        | .compiler moduleName failure =>
            [("stage", psJsonQuote "source"),
             ("code", psJsonQuote "source-compiler"),
             ("moduleName", psJsonQuote moduleName),
             ("detail", psJsonQuote (psStrictNativeCompilerDetail failure))]
    | .compiler failure =>
        [("stage", psJsonQuote "compiler"),
         ("code", psJsonQuote "compiler-refused"),
         ("detail", psJsonQuote (psStrictNativeCompilerDetail failure))]
    | .checkedEmit failure =>
        match failure with
        | .check report =>
            [("stage", psJsonQuote "original-ir"),
             ("code", psJsonQuote "original-ir-refused"),
             ("findingCount", toString report.findingCount),
             ("traversalComplete", psStrictNativeBool report.traversalComplete)]
        | .emit _ =>
            [("stage", psJsonQuote "emitter"),
             ("code", psJsonQuote "emitter-refused")]
    | .target failure =>
        [("stage", psJsonQuote "target"),
         ("code", psJsonQuote failure.code),
         ("detail", psJsonQuote failure.detail),
         ("owner", psJsonQuote failure.owner),
         ("path", psJsonQuote failure.path),
         ("visitedSteps", toString failure.visitedSteps)]
  psJsonObject
    ([("schemaVersion", "1"),
      ("evidence", psJsonQuote "native-atomic-source-refusal"),
      ("strictSh1Qualified", "false"),
      ("semanticContractQualified", "false")] ++ fields)

def psStrictNativeInput
    (sourceKind : PsCompilerSourceKind) (path : String) : IO PsSh1SourceInput := do
  let suffix :=
    match sourceKind with
    | .lean => ".lean"
    | .proofScript => ".ps"
  if !(path.endsWith suffix) then
    throw (IO.userError ("PSC0_SH1_NATIVE_SOURCE_KIND: " ++ path))
  let modulePath ←
    match path.splitOn "/src/" with
    | [_prefix, value] => pure (value.dropRight suffix.length)
    | _ => throw (IO.userError ("PSC0_SH1_NATIVE_MODULE_PATH: " ++ path))
  let source ← IO.FS.readFile path
  pure (psSh1SourceInput (modulePath.splitOn "/") source)

def psStrictNativeReport
    (result : PsSh1Emission) (sourceKind : String) : String :=
  let policy := result.sourcePolicy
  let options := policy.options
  let stats := policy.stats
  let target := result.targetPolicy
  let ir := result.checkReport
  let sourceFields :=
    [("profile", psJsonQuote policy.profile),
     ("enforcementVersion", toString policy.enforcementVersion),
     ("sourceKind", psJsonQuote sourceKind),
     ("accepted", psStrictNativeBool policy.accepted),
     ("traversalComplete", psStrictNativeBool policy.traversalComplete),
     ("moduleCount", toString policy.moduleCount),
     ("sourceBytes", toString policy.sourceBytes),
     ("inputBytes", toString policy.inputBytes),
     ("importCount", toString policy.importCount),
     ("options", psJsonObject
       [("maxModules", toString options.maxModules),
        ("maxInputBytes", toString options.maxInputBytes),
        ("maxSyntaxSteps", toString options.maxSyntaxSteps),
        ("maxTypeSteps", toString options.maxTypeSteps),
        ("maxTermSteps", toString options.maxTermSteps)]),
     ("stats", psJsonObject
       [("visitedSteps", toString stats.visitedSteps),
        ("typeSteps", toString stats.typeSteps),
        ("termSteps", toString stats.termSteps),
        ("declarationCount", toString stats.declarationCount),
        ("theoremCount", toString stats.theoremCount)])]
  let irFields :=
    [("schemaVersion", "1"),
     ("kind", psJsonQuote "psc0-native-original-ir-check"),
     ("accepted", psStrictNativeBool ir.accepted),
     ("traversalComplete", psStrictNativeBool ir.traversalComplete),
     ("visitedSteps", toString ir.visitedSteps),
     ("expressionCount", toString ir.expressionCount),
     ("findingCount", toString ir.findingCount),
     ("retainedFindingCount", toString ir.findings.length),
     ("omittedFindingDetails", toString (ir.findingCount - ir.findings.length)),
     ("sameOriginalIrCheckedBeforeEmission", "true"),
     ("strictSh1Qualified", "false")]
  psJsonObject
    [("schemaVersion", "1"),
     ("evidence", psJsonQuote "native-atomic-source-and-target-enforcement"),
     ("sourceKind", psJsonQuote sourceKind),
     ("sourcePolicy", psJsonObject sourceFields),
     ("targetPolicy", psJsonObject
       [("policy", psJsonQuote target.policy),
        ("accepted", psStrictNativeBool target.accepted),
        ("traversalComplete", psStrictNativeBool target.traversalComplete),
        ("visitedSteps", toString target.visitedSteps)]),
     ("originalIr", psJsonObject irFields),
     ("sourceOrigins", psJsonObject
       [("actualParsedModulesRetained", toString result.parsedModules.length),
        ("semanticCorrespondenceDischarged", "false")]),
     ("preparationCount", "1"),
     ("portableIrCheckCount", "1"),
     ("strictSh1Qualified", psStrictNativeBool result.strictSh1Qualified),
     ("semanticContractQualified", psStrictNativeBool result.semanticContractQualified),
     ("providerChecked", psStrictNativeBool result.providerChecked)]

def psStrictNativeCompile
    (kind outputPath admissionsPath reportPath : String)
    (sourcePaths : List String) : IO Unit := do
  let sourceKind ←
    match kind with
    | "lean" => pure PsCompilerSourceKind.lean
    | "ps" => pure PsCompilerSourceKind.proofScript
    | _ => throw (IO.userError "PSC0_SH1_NATIVE_SOURCE_KIND")
  let inputs ← sourcePaths.mapM (psStrictNativeInput sourceKind)
  match psCompilerSh1TypeScriptSources psSh1DefaultSourceOptions
      psIrCheckDefaultOptions sourceKind inputs with
  | .error error =>
      let evidence := psStrictNativeError error
      IO.FS.writeFile reportPath (evidence ++ "\n")
      IO.println ("PSC0_SH1_STRICT_SOURCE_NATIVE_REJECTED: " ++ evidence)
      throw (IO.userError "PSC0_SH1_STRICT_SOURCE_NATIVE_REJECTED")
  | .ok result =>
      let evidence := psStrictNativeReport result kind
      IO.FS.writeFile outputPath result.typeScript
      IO.FS.writeFile admissionsPath result.admissions
      IO.FS.writeFile reportPath (evidence ++ "\n")
      IO.println ("PSC0_SH1_STRICT_SOURCE_NATIVE: " ++ evidence)

def main (args : List String) : IO Unit := do
  match args with
  | "--kind" :: kind :: "--out" :: outputPath :: "--admissions" :: admissionsPath ::
      "--report" :: reportPath :: "--sources" :: paths =>
      psStrictNativeCompile kind outputPath admissionsPath reportPath paths
  | _ =>
      throw (IO.userError
        "usage: psc1_sh1_compile --kind lean|ps --out file.ts --admissions admissions.json --report report.json --sources ordered-package-source-paths...")
