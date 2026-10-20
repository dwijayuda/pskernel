import Ps.Compiler.Api
import Ps.Host.ProjectCompiler
import Lean.Data.Json

/-- Native diagnostic only; outside every portable compiler closure. -/
def psCensusPair (name value : String) : String × Lean.Json :=
  (name, Lean.toJson value)

def psCensusParseDetail : PsCompilerError → String
  | .leanFrontend (.lex error) => psHostLexErrorText error
  | .leanFrontend (.parse error) => psHostParseErrorText error
  | .proofScriptFrontend (.lex error) => psHostLexErrorText error
  | .proofScriptFrontend (.parse error) => psHostParseErrorText error
  | .elaboration error => psHostElabErrorText error
  | _ => "compiler-stage-refused"

def psCensusWrite (output : String) (records : Array Lean.Json) : IO Unit :=
  IO.FS.writeFile output ((Lean.Json.mkObj [
    psCensusPair "schema" "psc1-live-source-stage-probe/1",
    ("authoritative", Lean.toJson false),
    psCensusPair "scope" "selected compiler source; no kernel self-hosting",
    psCensusPair "admission" "not-run",
    psCensusPair "ir" "not-run",
    psCensusPair "generatedExecution" "not-run",
    psCensusPair "fixedPoint" "not-run",
    ("records", .arr records)]).compress ++ "\n")

def psCensusProbe (output : String) (args : List String) : IO Unit := do
  let mut state := psCompilerPreparationStart .lean
  let mut failed : List String := []
  let mut records : Array Lean.Json := #[]
  let mut pending := args
  while !pending.isEmpty do
    let moduleName :: sourcePath :: rest := pending
      | throw (IO.userError "PSC1_CENSUS_ARGUMENT_PAIRS: module path")
    pending := rest
    let source ← IO.FS.readFile sourcePath
    let base := [psCensusPair "module" moduleName, psCensusPair "path" sourcePath,
      ("utf8Bytes", Lean.toJson source.utf8ByteSize)]
    let record ← match psCompilerParseSource .lean source with
      | .error error =>
          failed := moduleName :: failed
          pure (Lean.Json.mkObj (base ++ [
            psCensusPair "parse" "refused", psCensusPair "elaboration" "blocked-by-parse",
            psCensusPair "detail" (psCensusParseDetail error)]))
      | .ok parsed =>
          let blocked := parsed.imports.filterMap (fun item =>
            let imported := String.intercalate "." item.moduleName.segments
            if failed.contains imported then some imported else none)
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
    psCensusWrite output records
  IO.println ("PSC1_SOURCE_CENSUS_OBSERVED: " ++ toString records.size ++
    " modules; " ++ toString failed.length ++ " refused/blocked (not a self-host qualification)")

def main (args : List String) : IO Unit := do
  match args with
  | "--out" :: output :: "--modules" :: entries => psCensusProbe output entries
  | _ => throw (IO.userError
      "usage: psc1_source_census_probe --out report.json --modules module path ...")
