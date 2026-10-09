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

def psStrictNativeOriginPhase (phase : PsElabOriginPhase) : String :=
  match phase with
  | .stableDeclaration => "stableDeclaration"
  | .normalizationPlanning => "normalizationPlanning"
  | .normalizedWorker => "normalizedWorker"
  | .publicWrapper => "publicWrapper"
  | .declarationInsertion => "declarationInsertion"

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
        | .origin moduleName failure =>
            [("stage", psJsonQuote "source"),
             ("code", psJsonQuote "source-elaboration"),
             ("moduleName", psJsonQuote moduleName),
             ("compilerStage", psJsonQuote "elaboration"),
             ("detail", psJsonQuote (psHostElabErrorText failure.error)),
             ("owner", psJsonQuote (psSh1NameText failure.sourceName.segments)),
             ("sourceIndex", toString failure.sourceIndex),
             ("phase", psJsonQuote (psStrictNativeOriginPhase failure.phase)),
             ("span", psStrictNativeSpan (some failure.span))]
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
      ("semanticContractQualified", "false"),
      ("providerChecked", "false")] ++ fields)

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

-- These compact records observe the actual retained source-to-Core association.
-- Their field order matches observeStrictOrigins in sh1-strict-source.mjs.
-- Native IO serializes the data; the evidence binder hashes the common payload.
-- No parser, elaborator, admission encoder or IR checker is called again.
def psStrictNativeCoreNameParts
    (name : PsName) (parts : List String) : List String :=
  match name with
  | .anonymous => parts
  | .str parent value =>
      psStrictNativeCoreNameParts parent
        (psJsonArray [psJsonQuote "str", psJsonQuote value] :: parts)
  | .num parent value =>
      psStrictNativeCoreNameParts parent
        (psJsonArray [psJsonQuote "num", psJsonQuote (toString value)] :: parts)

def psStrictNativeCoreName (name : PsName) : String :=
  psJsonArray (psStrictNativeCoreNameParts name [])

def psStrictNativeOriginRole (role : PsElabOriginRole) : String :=
  match role with
  | .sourceDeclaration => "sourceDeclaration"
  | .inductiveType => "inductiveType"
  | .structureType => "structureType"
  | .constructor => "constructor"
  | .recursor => "recursor"
  | .normalizedWorker => "normalizedWorker"
  | .publicWrapper => "publicWrapper"

def psStrictNativeSyntaxKind (term : PsSyntaxTerm) : String :=
  match term with
  | .reference _ => "reference"
  | .natural _ _ => "natural"
  | .string _ _ => "string"
  | .character _ _ => "character"
  | .bool _ _ => "bool"
  | .unit _ => "unit"
  | .record _ _ => "record"
  | .app _ _ _ => "app"
  | .lambda _ _ _ => "lambda"
  | .forallE _ _ _ => "forallE"
  | .letE _ _ _ _ _ => "letE"
  | .ifE _ _ _ _ => "ifE"
  | .matchE _ _ _ => "matchE"

def psStrictNativeOriginIds (ids : List Nat) : String :=
  psJsonArray (ids.map (fun id => psJsonQuote (toString id)))

def psStrictNativeNormalization (origin : PsElabNormalizationOrigin) : String :=
  let plan := origin.plan
  psJsonObject
    [("functionName", psStrictNativeCoreName plan.functionName),
     ("workerName", psStrictNativeCoreName origin.workerName),
     ("parameterIds", psStrictNativeOriginIds plan.parameterIds),
     ("explicitIds", psStrictNativeOriginIds plan.explicitIds),
     ("majorId", psJsonQuote (toString plan.majorId)),
     ("generalizedIds", psStrictNativeOriginIds plan.generalizedIds),
     ("workerBinderCount", toString origin.workerBinders.length),
     ("workerTypeKind", psJsonQuote (psStrictNativeSyntaxKind origin.workerType)),
     ("workerValueKind", psJsonQuote (psStrictNativeSyntaxKind origin.workerValue)),
     ("actualWorkerSyntaxRetained", "true")]

def psStrictNativeOriginMember (member : PsElabMemberOrigin) : String :=
  psJsonObject
    [("index", toString member.index),
     ("name", psStrictNativeCoreName member.name),
     ("role", psJsonQuote (psStrictNativeOriginRole member.role))]

def psStrictNativeOriginBatch
    (batch : PsElabBatchOrigin) (coreStart : Nat) : String :=
  let normalization :=
    match batch.normalization with
    | none => "null"
    | some origin => psStrictNativeNormalization origin
  psJsonObject
    [("sourceIndex", toString batch.sourceIndex),
     ("sourceName", psJsonArray (batch.sourceName.segments.map psJsonQuote)),
     ("span", psStrictNativeSpan (some batch.span)),
     ("coreStart", toString coreStart),
     ("members", psJsonArray (batch.members.map psStrictNativeOriginMember)),
     ("normalization", normalization)]

structure PsStrictNativeOriginRecords where
  records : List String
  sourceCount : Nat
  normalizationCount : Nat

def psStrictNativeOriginBatches
    (batches : List PsElabBatchOrigin) (coreStart : Nat) :
    PsStrictNativeOriginRecords :=
  match batches with
  | [] => PsStrictNativeOriginRecords.mk [] 0 0
  | batch :: rest =>
      let tail := psStrictNativeOriginBatches rest (coreStart + batch.members.length)
      let normalized :=
        match batch.normalization with
        | none => 0
        | some _ => 1
      PsStrictNativeOriginRecords.mk
        (psStrictNativeOriginBatch batch coreStart :: tail.records)
        (tail.sourceCount + 1) (tail.normalizationCount + normalized)

def psStrictNativeOriginModules (modules : List PsSh1ModuleOrigin) :
    PsStrictNativeOriginRecords :=
  match modules with
  | [] => PsStrictNativeOriginRecords.mk [] 0 0
  | current :: rest =>
      let batches := psStrictNativeOriginBatches current.batches current.coreStart
      let tail := psStrictNativeOriginModules rest
      let record := psJsonObject
        [("moduleName", psJsonArray (current.moduleName.map psJsonQuote)),
         ("coreStart", toString current.coreStart),
         ("batches", psJsonArray batches.records)]
      PsStrictNativeOriginRecords.mk (record :: tail.records)
        (batches.sourceCount + tail.sourceCount)
        (batches.normalizationCount + tail.normalizationCount)

def psStrictNativeSourceOrigins (result : PsSh1Emission) : String :=
  let records := psStrictNativeOriginModules result.origins
  psJsonObject
    [("policy", psJsonQuote "psc0-declaration-origins/1"),
     ("actualParsedModulesRetained", toString result.parsedModules.length),
     ("moduleCount", toString result.origins.length),
     ("sourceDeclarationCount", toString records.sourceCount),
     ("coreDeclarationCount", toString result.prepared.declarations.length),
     ("normalizationCount", toString records.normalizationCount),
     ("modules", psJsonArray records.records),
     ("semanticCorrespondenceDischarged", "false")]

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
     ("sourceOrigins", psStrictNativeSourceOrigins result),
     ("preparationCount", "1"),
     ("canonicalAdmissionEncodingCount", "1"),
     ("environmentReconstructionCount", "0"),
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
