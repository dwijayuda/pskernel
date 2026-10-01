import Ps.Host.LeanChecked

def psCheckedSeedAssert (label : String) (passed : Bool) : IO Unit := do
  if passed then IO.println ("PSC2_LEAN_CHECKED_CASE: PASS " ++ label)
  else throw (IO.userError ("PSC2_LEAN_CHECKED_CASE: FAIL " ++ label))

def psCheckedSeedTests : IO Unit := do
  let .ok prepared := psCompilerPrepareSource .lean "def answer : Nat := 42\n"
    | throw (IO.userError "valid source preparation failed")
  let checked ← psHostLeanCheckPrepared prepared
  psCheckedSeedAssert "real kernel accepts actual frontend declarations" checked.isOk
  let emitted ← psHostLeanEmitPrepared prepared
  psCheckedSeedAssert "real kernel then actual erasure and TS emission"
    (match emitted with | .ok (_, ts) => ts.contains "answer" | _ => false)
  let forged := { prepared with canonicalAdmissions := "forged" }
  let rejected ← psHostLeanEmitPrepared forged
  psCheckedSeedAssert "forged prepared artifact blocked before emission"
    (match rejected with | .error "PSC2_CHECKED_PREPARED_INTEGRITY_FAILED" => true | _ => false)
  let invalidDeclarations := [PsDeclaration.definitionDecl (psRootName "bad") []
    (PsExpr.constE psNatName []) (PsExpr.sortE PsLevel.zero)]
  let .ok canonical := psEncodeCheckedAdmissionsCanonical invalidDeclarations
    | throw (IO.userError "ill-typed fixture is not codec-valid")
  let invalid : PsCompilerAdmissionReadyModule := {
    declarations := invalidDeclarations, canonicalAdmissions := canonical }
  let invalidResult ← psHostLeanEmitPrepared invalid
  psCheckedSeedAssert "codec-valid ill-typed declaration rejected by real kernel"
    (match invalidResult with | .error error => error.startsWith "PSC2_KERNEL_REJECTED:" | _ => false)
  IO.println "PSC2_LEAN_CHECKED_NATIVE: PASS"

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
def psCheckedSeedSession
    (kind : PsCompilerSourceKind)
    (sourcePath : String) : IO Unit := do
  let source ← IO.FS.readFile sourcePath
  let .ok prepared := psCompilerPrepareSource kind source
    | throw (IO.userError "PSC2_CHECKED_PREPARE_FAILED")
  let .ok admissions := psCompilerAdmissionsFromPrepared prepared
    | throw (IO.userError "PSC2_CHECKED_PREPARED_INTEGRITY_FAILED")
  let stdout ← IO.getStdout
  stdout.putStrLn
    ("{\"phase\":\"prepared\",\"admissions\":" ++ psJsonQuote admissions ++ "}")
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
        stdout.putStrLn
          ("{\"phase\":\"emitted\",\"typescript\":" ++ psJsonQuote output ++ "}")
        stdout.flush
  else
    throw (IO.userError "PSC2_CHECKED_SEED_SESSION_COMMAND")

def main (args : List String) : IO Unit := do
  match args with
  | ["--test"] => psCheckedSeedTests
  | ["--check-lean"] => psCheckedSeedRun false .lean
  | ["--check-ps"] => psCheckedSeedRun false .proofScript
  | ["--emit-lean"] => psCheckedSeedRun true .lean
  | ["--emit-ps"] => psCheckedSeedRun true .proofScript
  | ["--session-lean", sourcePath] => psCheckedSeedSession .lean sourcePath
  | ["--session-ps", sourcePath] => psCheckedSeedSession .proofScript sourcePath
  | _ => throw (IO.userError "usage: psc2_lean_checked_seed --test|--check-lean|--check-ps|--emit-lean|--emit-ps|--session-lean <file>|--session-ps <file>")
