import Ps.Host.LeanChecked
import Lean.Data.Json

-- Transport encoding belongs to the native host. Canonical admission bytes stay
-- unchanged; avoid recursively concatenating a multi-megabyte quoted payload.
def psCheckedSeedMessage (phase key value : String) : String :=
  (Lean.Json.mkObj [("phase", Lean.Json.str phase), (key, Lean.Json.str value)]).compress

def psCheckedSeedAssert (label : String) (passed : Bool) : IO Unit := do
  if passed then IO.println ("PSC2_LEAN_CHECKED_CASE: PASS " ++ label)
  else throw (IO.userError ("PSC2_LEAN_CHECKED_CASE: FAIL " ++ label))

def psCheckedSeedTests : IO Unit := do
  let large := String.ofList (List.replicate 10000000 'x') ++ "\n\t\"\\λ😀"
  let .ok message := Lean.Json.parse (psCheckedSeedMessage "prepared" "admissions" large)
    | throw (IO.userError "large transport JSON failed")
  psCheckedSeedAssert "large transport preserves exact payload and escaped Unicode"
    (match message.getObjValAs? String "admissions", message.getObjValAs? String "phase" with
     | .ok value, .ok phase => value == large && phase == "prepared"
     | _, _ => false)
  let .ok prepared := psCompilerPrepareSource .lean "def answer : Nat := 42\n"
    | throw (IO.userError "valid source preparation failed")
  let checked ← psHostLeanCheckPrepared prepared
  psCheckedSeedAssert "real kernel accepts actual frontend declarations" checked.isOk
  let emitted ← psHostLeanEmitPrepared prepared
  psCheckedSeedAssert "real kernel then actual erasure and TS emission"
    (match emitted with | .ok (_, ts) => ts.contains "answer" | _ => false)
  let forged : PsCompilerAdmissionReadyModule := { declarations := [
    PsDeclaration.definitionDecl (psRootName "bad") []
      (PsExpr.constE psNatName []) (PsExpr.mvar 0)] }
  let rejected ← psHostLeanEmitPrepared forged
  psCheckedSeedAssert "codec-invalid prepared declarations blocked before emission"
    (match rejected with | .error "PSC2_CHECKED_PREPARED_INTEGRITY_FAILED" => true | _ => false)
  let invalidDeclarations := [PsDeclaration.definitionDecl (psRootName "bad") []
    (PsExpr.constE psNatName []) (PsExpr.sortE PsLevel.zero)]
  let .ok _ := psEncodeCheckedAdmissionsCanonical invalidDeclarations
    | throw (IO.userError "ill-typed fixture is not codec-valid")
  let invalid : PsCompilerAdmissionReadyModule := {
    declarations := invalidDeclarations }
  let invalidResult ← psHostLeanEmitPrepared invalid
  psCheckedSeedAssert "codec-valid ill-typed declaration rejected by real kernel"
    (match invalidResult with | .error error => error.startsWith "PSC2_KERNEL_REJECTED:" | _ => false)
  let nestedSource ← IO.FS.readFile "../test/fixtures/checked-nested-recursor.lean"
  let .ok nested := psCompilerPrepareSource .lean nestedSource
    | throw (IO.userError "nested source preparation failed")
  let .ok nestedAdmissions := psCompilerAdmissionsFromPrepared nested
    | throw (IO.userError "nested admission encoding failed")
  psCheckedSeedAssert "nested List Option Prod recursors are adapted in the canonical payload"
    (nestedAdmissions.contains "_pscShallowRec" && nestedAdmissions.contains "_pscCheckedNestedUnit")
  let nestedResult ← psHostLeanEmitPrepared nested
  psCheckedSeedAssert "real kernel accepts nested recursors and direct recursive hypotheses"
    (match nestedResult with | .ok (_, ts) => ts.contains "checkedTreeExample" | _ => false)
  let .ok wrappers := psCheckedNestedCollect nested.declarations nested.declarations
    | throw (IO.userError "nested wrapper classification failed")
  psCheckedSeedAssert "parameterized direct recursion is not a nested recursor"
    ((psCheckedNestedFind wrappers (psRootName "CheckedList")).isNone &&
      match nestedResult with | .ok (_, ts) => ts.contains "checkedListExample" | _ => false)
  let self := PsExpr.constE (psRootName "Family") []
  let parameter := PsExpr.fvar 0
  psCheckedSeedAssert "direct recursion classification retains nested self arguments"
    (psCheckedNestedDirect (psRootName "Family") (PsExpr.app self parameter) &&
      !psCheckedNestedDirect (psRootName "Family") (PsExpr.app self self))
  IO.println "PSC2_LEAN_CHECKED_NATIVE: PASS"

-- Parse current PS before dependency discovery. The native host shares the
-- compiler parser and returns only import names; kernel/provider behavior and
-- the prepared-session protocol below are unchanged.
def psCheckedSeedSourceImports : IO Unit := do
  let source ← (← IO.getStdin).readToEnd
  let .ok sourceModule := psParseProofScriptSource source
    | throw (IO.userError "PSC2_SOURCE_PARSE_FAILED")
  let names ← sourceModule.imports.mapM fun sourceImport => do
    let .ok name := psPrintSyntaxName sourceImport.moduleName
      | throw (IO.userError "PSC2_SOURCE_IMPORT_NAME_FAILED")
    pure (Lean.Json.str name)
  IO.println (Lean.Json.arr names.toArray).compress

def psCheckedSeedRun (emit : Bool) (kind : PsCompilerSourceKind) : IO Unit := do
  let source ← (← IO.getStdin).readToEnd
  let .ok prepared := psCompilerPrepareSource kind source
    | throw (IO.userError "PSC2_CHECKED_PREPARE_FAILED")
  if emit then
    match ← psHostLeanEmitPrepared prepared with
    | .error error => throw (IO.userError error)
    | .ok (admissions, output) =>
        IO.println ("{" ++ PsKernelLean.providerIdentityJsonFields ++
          ",\"accepted\":true,\"admissions\":" ++ psJsonQuote admissions ++
          ",\"typescript\":" ++ psJsonQuote output ++ "}")
  else
    match ← psHostLeanCheckPrepared prepared with
    | .error error => throw (IO.userError error)
    | .ok admissions =>
        IO.println ("{" ++ PsKernelLean.providerIdentityJsonFields ++
          ",\"accepted\":true,\"admissions\":" ++ psJsonQuote admissions ++ "}")

-- Two-phase host protocol used when the selected checker is external to the
-- native seed (for example pskernel-lean-wasm). The source is read once and the
-- prepared Lean value remains alive while the host checks its canonical
-- admissions. Erasure/emission runs only after the host replies `emit`.
def psCheckedSeedPreparedSession
    (prepared : PsCompilerAdmissionReadyModule) : IO Unit := do
  let .ok admissions := psCompilerAdmissionsFromPrepared prepared
    | throw (IO.userError "PSC2_CHECKED_PREPARED_INTEGRITY_FAILED")
  let stdout ← IO.getStdout
  stdout.putStrLn (psCheckedSeedMessage "prepared" "admissions" admissions)
  stdout.flush
  let command ← (← IO.getStdin).getLine
  if command.trim == "checked" then
    stdout.putStrLn "{\"phase\":\"checked\"}"
    stdout.flush
  else if command.trim == "emit" then
    let .ok currentAdmissions := psCompilerAdmissionsFromPrepared prepared
      | throw (IO.userError "PSC2_CHECKED_PREPARED_INTEGRITY_FAILED")
    if currentAdmissions != admissions then
      throw (IO.userError "PSC2_CHECKED_PAYLOAD_CHANGED")
    match psCompilerTypeScriptFromPrepared prepared with
    | .error _ => throw (IO.userError "PSC2_CHECKED_EMISSION_FAILED")
    | .ok output =>
        stdout.putStrLn (psCheckedSeedMessage "emitted" "typescript" output)
        stdout.flush
  else
    throw (IO.userError "PSC2_CHECKED_SEED_SESSION_COMMAND")

def psCheckedSeedSession
    (kind : PsCompilerSourceKind) (sourcePath : String) : IO Unit := do
  let source ← IO.FS.readFile sourcePath
  let .ok prepared := psCompilerPrepareSource kind source
    | throw (IO.userError "PSC2_CHECKED_PREPARE_FAILED")
  psCheckedSeedPreparedSession prepared

def psCheckedSeedModulesSession
    (kind : PsCompilerSourceKind) (sourcePath : String) : IO Unit := do
  let source ← IO.FS.readFile sourcePath
  let .ok json := Lean.Json.parse source
    | throw (IO.userError "PSC2_CHECKED_MODULES_JSON")
  let .ok entries := json.getArr?
    | throw (IO.userError "PSC2_CHECKED_MODULES_ARRAY")
  let sources ← entries.toList.mapM fun entry =>
    match entry.getStr? with
    | .error _ => throw (IO.userError "PSC2_CHECKED_MODULES_SOURCE")
    | .ok text => pure text
  let .ok prepared := psCompilerPrepareSources kind sources
    | throw (IO.userError "PSC2_CHECKED_PREPARE_FAILED")
  psCheckedSeedPreparedSession prepared

def psCheckedSeedDiagnoseAdmissions (sourcePath : String) : IO Unit := do
  let source ← IO.FS.readFile sourcePath
  let .ok declarations := PsKernelLean.decodeCanonicalAdmissions source
    | throw (IO.userError "PSC2_CHECKED_DIAGNOSE_DECODE")
  let .ok initial ← PsKernelLean.buildLeanPreludeEnvironment
    | throw (IO.userError "PSC2_CHECKED_DIAGNOSE_PRELUDE")
  let mut environment := initial
  for index in [:declarations.size] do
    match environment.addDeclCore 2000000 20000 declarations[index]! none true with
    | .ok next => environment := next
    | .error error =>
        IO.println s!"PSC2_CHECKED_DIAGNOSE_REJECTION: {index}"
        throw (IO.userError (← (error.toMessageData {}).toString))
  IO.println "PSC2_CHECKED_DIAGNOSE_ACCEPTED"

def main (args : List String) : IO Unit := do
  match args with
  | ["--test"] => psCheckedSeedTests
  | ["--source-imports-ps"] => psCheckedSeedSourceImports
  | ["--diagnose-admissions", sourcePath] => psCheckedSeedDiagnoseAdmissions sourcePath
  | ["--check-lean"] => psCheckedSeedRun false .lean
  | ["--check-ps"] => psCheckedSeedRun false .proofScript
  | ["--emit-lean"] => psCheckedSeedRun true .lean
  | ["--emit-ps"] => psCheckedSeedRun true .proofScript
  | ["--session-lean", sourcePath] => psCheckedSeedSession .lean sourcePath
  | ["--session-ps", sourcePath] => psCheckedSeedSession .proofScript sourcePath
  | ["--session-modules-lean", sourcePath] => psCheckedSeedModulesSession .lean sourcePath
  | ["--session-modules-ps", sourcePath] => psCheckedSeedModulesSession .proofScript sourcePath
  | _ => throw (IO.userError "usage: psc2_lean_checked_seed --test|--source-imports-ps|--check-lean|--check-ps|--emit-lean|--emit-ps|--session-lean <file>|--session-ps <file>")
