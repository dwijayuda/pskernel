import Ps.Compiler.Api
import Ps.Compiler.Ordinary
import Ps.Host.ProjectCompiler
import Lean.Data.Json
import Ps.Host.LeanChecked
import Ps.CompilerIr.Validate

/-- Native diagnostic only; outside every portable compiler closure. -/
def psCensusPair (name value : String) : String × Lean.Json :=
  (name, Lean.toJson value)

def psCensusGrammar : PsCompilerSourceKind -> String
  | .lean => "lean"
  | .proofScript => "ps"

def psCensusDerivation : PsCompilerSourceKind -> String
  | .lean => "repository-lean-source"
  | .proofScript => "owned-canonical-translation-from-lean"

def psCensusPrintDetail : PsSourcePrintError -> String
  | .fuelExhausted => "print-fuelExhausted"
  | .unsupportedApplication => "print-unsupportedApplication"
  | .emptyName => "print-emptyName"
  | .unsupportedSourceForm message => "print-unsupportedSourceForm:" ++ message

def psCensusParseDetail : PsCompilerError -> String
  | .leanFrontend (.lex error) => psHostLexErrorText error
  | .leanFrontend (.parse error) => psHostParseErrorText error
  | .proofScriptFrontend (.lex error) => psHostLexErrorText error
  | .proofScriptFrontend (.parse error) => psHostParseErrorText error
  | .translation (.leanFrontend (.lex error)) => psHostLexErrorText error
  | .translation (.leanFrontend (.parse error)) => psHostParseErrorText error
  | .translation (.proofScriptFrontend (.lex error)) => psHostLexErrorText error
  | .translation (.proofScriptFrontend (.parse error)) => psHostParseErrorText error
  | .translation (.print error) => psCensusPrintDetail error
  | .elaboration error => psHostElabErrorText error
  | _ => "compiler-stage-refused"

def psCensusWrite (kind : PsCompilerSourceKind) (output : String)
    (records : Array Lean.Json) : IO Unit :=
  IO.FS.writeFile output ((Lean.Json.mkObj [
    psCensusPair "schema" "psc1-live-source-stage-probe/1",
    ("authoritative", Lean.toJson false),
    psCensusPair "grammar" (psCensusGrammar kind),
    psCensusPair "sourceDerivation" (psCensusDerivation kind),
    psCensusPair "scope" "selected compiler source; no kernel self-hosting",
    psCensusPair "admission" "not-run",
    psCensusPair "ir" "not-run",
    psCensusPair "generatedExecution" "not-run",
    psCensusPair "fixedPoint" "not-run",
    ("records", .arr records)]).compress ++ "\n")

def psCensusProbe (kind : PsCompilerSourceKind) (output : String)
    (args : List String) : IO Unit := do
  -- Every invocation owns a fresh state and failure set. PS never inherits Lean acceptance.
  let mut state := psCompilerPreparationStart kind
  let mut failed : List String := []
  let mut records : Array Lean.Json := #[]
  let mut pending := args
  while !pending.isEmpty do
    let moduleName :: sourcePath :: rest := pending
      | throw (IO.userError "PSC1_CENSUS_ARGUMENT_PAIRS: module path")
    pending := rest
    let source <- IO.FS.readFile sourcePath
    let base := [psCensusPair "module" moduleName, psCensusPair "path" sourcePath,
      psCensusPair "grammar" (psCensusGrammar kind),
      ("utf8Bytes", Lean.toJson source.utf8ByteSize)]
    let input : Except PsCompilerError String :=
      match kind with
      | .lean => .ok source
      | .proofScript => psCompilerTranslateSource .lean .proofScript source
    let record <- match input with
      | .error error =>
          failed := moduleName :: failed
          pure (Lean.Json.mkObj (base ++ [
            psCensusPair "translation" "refused",
            psCensusPair "parse" "blocked-by-translation",
            psCensusPair "elaboration" "blocked-by-translation",
            psCensusPair "detail" (psCensusParseDetail error)]))
      | .ok input =>
          let inputFields := match kind with
            | .lean => [psCensusPair "translation" "not-applicable"]
            | .proofScript => [psCensusPair "translation" "accepted",
                psCensusPair "inputSource" input]
          let base := base ++ inputFields ++ [
            ("inputUtf8Bytes", Lean.toJson input.utf8ByteSize)]
          match psCompilerParseSource kind input with
          | .error error =>
              failed := moduleName :: failed
              pure (Lean.Json.mkObj (base ++ [
                psCensusPair "parse" "refused", psCensusPair "elaboration" "blocked-by-parse",
                psCensusPair "detail" (psCensusParseDetail error)]))
          | .ok parsed =>
              let imports := parsed.imports.map (fun item =>
                String.intercalate "." item.moduleName.segments)
              let base := base ++ [("parsedImports", Lean.toJson imports)]
              let blocked := imports.filter (fun imported => failed.contains imported)
              if !blocked.isEmpty then
                failed := moduleName :: failed
                pure (Lean.Json.mkObj (base ++ [
                  psCensusPair "parse" "accepted", psCensusPair "elaboration" "blocked-by-import",
                  ("blockedImports", Lean.toJson blocked)]))
              else
                match psCompilerPreparationStepParsedWithOrigins state parsed with
                | .error error =>
                    failed := moduleName :: failed
                    pure (Lean.Json.mkObj (base ++ [
                      psCensusPair "parse" "accepted", psCensusPair "elaboration" "refused",
                      psCensusPair "detail" (psHostElabErrorText error.error),
                      psCensusPair "sourceDeclaration" (String.intercalate "." error.sourceName.segments),
                      ("sourceIndex", Lean.toJson error.sourceIndex),
                      ("line", Lean.toJson error.span.start.line),
                      ("column", Lean.toJson error.span.start.column)]))
                | .ok next =>
                    state := next.state
                    pure (Lean.Json.mkObj (base ++ [
                      psCensusPair "parse" "accepted", psCensusPair "elaboration" "accepted",
                      ("sourceDeclarations", Lean.toJson parsed.declarations.length)]))
    records := records.push record
    psCensusWrite kind output records
  IO.println ("PSC1_SOURCE_CENSUS_OBSERVED: " ++ psCensusGrammar kind ++ " " ++
    toString records.size ++ " modules; " ++ toString failed.length ++
    " refused/blocked (not a self-host qualification)")

def psClosureAdmissionDetail : PsCheckedAdmissionCodecError -> String
  | .universeMetavariable => "universeMetavariable"
  | .freeVariable => "freeVariable"
  | .expressionMetavariable => "expressionMetavariable"
  | .missingConstructor name => "missingConstructor:" ++ psNameToString name
  | .mismatchedConstructor name => "mismatchedConstructor:" ++ psNameToString name
  | .unsupportedDeclaration => "unsupportedDeclaration"

def psClosureErasureDetail : PsErasureError -> String
  | .fuelExhausted => "fuelExhausted"
  | .binderMismatch => "binderMismatch"
  | .looseBoundVariable => "looseBoundVariable"
  | .unresolvedMetavariable => "unresolvedMetavariable"
  | .unknownLocal id => "unknownLocal:" ++ toString id
  | .erasedLocalUsed id => "erasedLocalUsed:" ++ toString id
  | .unsupportedRuntimeTerm => "unsupportedRuntimeTerm"
  | .unsupportedApplication => "unsupportedApplication"
  | .unknownConstant name => "unknownConstant:" ++ psNameToString name

def psClosureCompilerDetail : PsCompilerError -> String
  | .admission error => "admission-encoding:" ++ psClosureAdmissionDetail error
  | .erasure error => "erasure:" ++ psClosureErasureDetail error
  | error => psCensusParseDetail error

def psClosureWrite (kind : PsCompilerSourceKind) (assurance output preparation admission ir : String)
    (records : Array Lean.Json) (extra : List (String × Lean.Json)) : IO Unit :=
  IO.FS.writeFile output ((Lean.Json.mkObj ([
    psCensusPair "schema" "psc1-compiler-closure-probe/2",
    ("authoritative", Lean.toJson false),
    psCensusPair "grammar" (psCensusGrammar kind),
    psCensusPair "frontend" "owned-native-PSC1",
    psCensusPair "assurance" assurance,
    psCensusPair "preparation" preparation,
    psCensusPair "admission" admission,
    psCensusPair "ir" ir,
    psCensusPair "generatedExecution" "not-run",
    psCensusPair "selfCompilation" "not-run",
    psCensusPair "fixedPoint" "not-run",
    psCensusPair "formalPreservation" "not-provided",
    psCensusPair "leanVersion" Lean.versionString,
    psCensusPair "leanCommit" Lean.githash,
    ("records", .arr records)] ++ extra)).compress ++ "\n")

/-- Host diagnostic retains the exact production ordinary pairing as one value. -/
structure PsClosurePreparedBatch where
  logical : PsCompilerAdmissionReadyModule
  admissions : String
  ordinary : Option PsCompilerOrdinaryModule
  sourceCoreDeclarations : Nat
  partialNames : List String

def psClosurePrepare (assurance : String) (state : PsCompilerPreparationState) :
    Except String PsClosurePreparedBatch := do
  let source := psCompilerPreparationElaborated state
  if assurance == "checked" then
    match psCompilerPreparationFinishWithOutput state with
    | .error error => throw (psClosureCompilerDetail error)
    | .ok value =>
        pure { logical := value.prepared, admissions := value.admissions, ordinary := none,
          sourceCoreDeclarations := source.declarations.length, partialNames := [] }
  else if assurance == "ordinary-checked" then
    let ordinary <- psCompilerPrepareOrdinary source
    let admissions <- match psCompilerAdmissionsFromPrepared ordinary.logical with
      | .error error => throw (psClosureCompilerDetail error)
      | .ok value => pure value
    pure { logical := ordinary.logical, admissions := admissions, ordinary := some ordinary,
      sourceCoreDeclarations := ordinary.source.declarations.length,
      partialNames := ordinary.partialNames.map psNameToString }
  else throw "PSC1_CLOSURE_UNKNOWN_ASSURANCE"

-- Qualification consumes the exact supplied parser inputs, including retained PS.
-- It owns a fresh state for one selected closure; no union-lane state is reused.
def psClosureProbe (kind : PsCompilerSourceKind) (assurance output admissionsPath : String)
    (args : List String) : IO Unit := do
  let mut state := psCompilerPreparationStart kind
  let mut records : Array Lean.Json := #[]
  let mut seen : List String := []
  let mut pending := args
  psClosureWrite kind assurance output "in-progress" "not-run" "not-run" records []
  while !pending.isEmpty do
    let moduleName :: inputPath :: rest := pending
      | throw (IO.userError "PSC1_CLOSURE_ARGUMENT_PAIRS")
    pending := rest
    if seen.contains moduleName then throw (IO.userError "PSC1_CLOSURE_DUPLICATE_MODULE")
    seen := moduleName :: seen
    let input <- IO.FS.readFile inputPath
    let base := [psCensusPair "module" moduleName, psCensusPair "inputPath" inputPath,
      ("inputUtf8Bytes", Lean.toJson input.utf8ByteSize)]
    let parsed <- match psCompilerParseSource kind input with
      | .error error =>
          records := records.push (Lean.Json.mkObj (base ++ [
            psCensusPair "parse" "refused", psCensusPair "elaboration" "blocked-by-parse",
            psCensusPair "detail" (psCensusParseDetail error)]))
          psClosureWrite kind assurance output "refused" "not-run" "not-run" records []
          throw (IO.userError ("PSC1_CLOSURE_PARSE_REFUSED: " ++ moduleName))
      | .ok value => pure value
    let imports := parsed.imports.map (fun item => String.intercalate "." item.moduleName.segments)
    let base := base ++ [("parsedImports", Lean.toJson imports)]
    match psCompilerPreparationStepParsedWithOrigins state parsed with
    | .error error =>
        records := records.push (Lean.Json.mkObj (base ++ [
          psCensusPair "parse" "accepted", psCensusPair "elaboration" "refused",
          psCensusPair "detail" (psHostElabErrorText error.error),
          psCensusPair "sourceDeclaration" (String.intercalate "." error.sourceName.segments),
          ("sourceIndex", Lean.toJson error.sourceIndex),
          ("line", Lean.toJson error.span.start.line), ("column", Lean.toJson error.span.start.column)]))
        psClosureWrite kind assurance output "refused" "not-run" "not-run" records []
        throw (IO.userError ("PSC1_CLOSURE_ELABORATION_REFUSED: " ++ moduleName))
    | .ok next =>
        state := next.state
        let origins := next.origins.map (fun origin => Lean.Json.mkObj [
          ("sourceIndex", Lean.toJson origin.sourceIndex),
          psCensusPair "sourceDeclaration" (String.intercalate "." origin.sourceName.segments),
          ("line", Lean.toJson origin.span.start.line),
          ("column", Lean.toJson origin.span.start.column),
          ("members", Lean.toJson (origin.members.map (fun member => Lean.Json.mkObj [
            ("index", Lean.toJson member.index),
            psCensusPair "name" (psNameToString member.name)])))])
        records := records.push (Lean.Json.mkObj (base ++ [
          psCensusPair "parse" "accepted", psCensusPair "elaboration" "accepted",
          ("sourceDeclarations", Lean.toJson parsed.declarations.length),
          ("origins", Lean.toJson origins)]))
        psClosureWrite kind assurance output "in-progress" "not-run" "not-run" records []
  if records.isEmpty then throw (IO.userError "PSC1_CLOSURE_EMPTY")
  let prepared <- match psClosurePrepare assurance state with
    | .error error =>
        psClosureWrite kind assurance output "refused" "not-run" "not-run" records [
          psCensusPair "detail" error]
        throw (IO.userError "PSC1_CLOSURE_PREPARATION_REFUSED")
    | .ok value => pure value
  let common := [("sourceCoreDeclarations", Lean.toJson prepared.sourceCoreDeclarations),
    ("partialNames", Lean.toJson prepared.partialNames),
    ("coreDeclarations", Lean.toJson prepared.logical.declarations.length),
    ("admissionsUtf8Bytes", Lean.toJson prepared.admissions.utf8ByteSize)]
  IO.FS.writeFile admissionsPath prepared.admissions
  psClosureWrite kind assurance output "accepted" "in-progress" "not-run" records common
  match <- psHostLeanCheckPrepared prepared.logical with
  | .error detail =>
      psClosureWrite kind assurance output "accepted" "refused" "not-run" records
        (common ++ [psCensusPair "detail" detail])
      throw (IO.userError ("PSC1_CLOSURE_ADMISSION_REFUSED: " ++ detail))
  | .ok admitted =>
      if admitted != prepared.admissions then
        throw (IO.userError "PSC1_CLOSURE_ADMISSION_BYTES_CHANGED")
  psClosureWrite kind assurance output "accepted" "accepted" "in-progress" records common
  -- The same immutable checked batch or ordinary source/logical/body pairing is
  -- erased only after the exact retained logical admissions were accepted.
  let rawResult : Except String PsVerifiedIrModule :=
    match prepared.ordinary with
    | .none =>
        match psCompilerVerifiedIrFromPrepared prepared.logical with
        | .error error => .error (psClosureCompilerDetail error)
        | .ok value => .ok value
    | .some ordinary => psCompilerOrdinaryIr ordinary
  let raw <- match rawResult with
    | .error detail =>
        psClosureWrite kind assurance output "accepted" "accepted" "refused" records
          (common ++ [psCensusPair "detail" detail])
        throw (IO.userError ("PSC1_CLOSURE_ERASURE_REFUSED: " ++ detail))
    | .ok value => pure value
  match psStrictValidateModule raw with
  | .error _ =>
      let report := psCheckVerifiedIrModule psIrCheckDefaultOptions raw
      let findings := report.findings.map (fun finding => Lean.Json.mkObj [
        psCensusPair "owner" finding.owner, psCensusPair "path" finding.path,
        psCensusPair "code" finding.code, psCensusPair "detail" finding.detail])
      psClosureWrite kind assurance output "accepted" "accepted" "refused" records (common ++ [
        psCensusPair "detail" "strict-IR-validation-refused",
        ("traversalComplete", Lean.toJson report.traversalComplete),
        ("visitedSteps", Lean.toJson report.visitedSteps),
        ("findingCount", Lean.toJson report.findingCount),
        ("findings", Lean.toJson findings)])
      throw (IO.userError "PSC1_CLOSURE_STRICT_IR_REFUSED")
  | .ok validated =>
      psClosureWrite kind assurance output "accepted" "accepted" "accepted" records (common ++ [
        psCensusPair "strictEntryPoint" "psStrictValidateModule",
        ("irDeclarations", Lean.toJson validated.raw.declarations.length),
        ("irStructures", Lean.toJson validated.raw.structures.length),
        ("irInductives", Lean.toJson validated.raw.inductives.length)])
  IO.println ("PSC1_COMPILER_CLOSURE: " ++ psCensusGrammar kind ++
    " exact declarations independently admitted and strict IR accepted; generated execution not-run")

def main (args : List String) : IO Unit := do
  match args with
  | "--qualify" :: "--assurance" :: assurance :: "--grammar" :: grammar :: "--out" :: output ::
      "--admissions" :: admissions :: "--modules" :: entries =>
      if !["checked", "ordinary-checked"].contains assurance then
        throw (IO.userError "PSC1_CLOSURE_UNKNOWN_ASSURANCE")
      if grammar == "lean" then psClosureProbe .lean assurance output admissions entries
      else if grammar == "ps" then psClosureProbe .proofScript assurance output admissions entries
      else throw (IO.userError "PSC1_CLOSURE_UNKNOWN_GRAMMAR")
  | "--qualify" :: "--grammar" :: "lean" :: "--out" :: output ::
      "--admissions" :: admissions :: "--modules" :: entries =>
      psClosureProbe .lean "checked" output admissions entries
  | "--qualify" :: "--grammar" :: "ps" :: "--out" :: output ::
      "--admissions" :: admissions :: "--modules" :: entries =>
      psClosureProbe .proofScript "checked" output admissions entries
  | "--out" :: output :: "--modules" :: entries => psCensusProbe .lean output entries
  | "--grammar" :: "lean" :: "--out" :: output :: "--modules" :: entries =>
      psCensusProbe .lean output entries
  | "--grammar" :: "ps" :: "--out" :: output :: "--modules" :: entries =>
      psCensusProbe .proofScript output entries
  | _ => throw (IO.userError
      "usage: psc1_source_census_probe [--grammar lean|ps] --out report.json --modules module path ...")
