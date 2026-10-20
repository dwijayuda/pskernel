import Ps.Compiler.Api
import Ps.Host.ProjectCompiler
import Lean.Data.Json

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

def main (args : List String) : IO Unit := do
  match args with
  | "--out" :: output :: "--modules" :: entries => psCensusProbe .lean output entries
  | "--grammar" :: "lean" :: "--out" :: output :: "--modules" :: entries =>
      psCensusProbe .lean output entries
  | "--grammar" :: "ps" :: "--out" :: output :: "--modules" :: entries =>
      psCensusProbe .proofScript output entries
  | _ => throw (IO.userError
      "usage: psc1_source_census_probe [--grammar lean|ps] --out report.json --modules module path ...")
