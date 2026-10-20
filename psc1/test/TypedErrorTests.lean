import Ps.Host.LeanChecked
import Ps.Host.ProjectCompiler
import Ps.CompilerIr.Check
import PracticalExecution

private def require (label : String) (condition : Bool) : IO Unit := do
  if !condition then throw (IO.userError ("PSC1_TYPED_ERROR_FAIL: " ++ label))
  IO.println ("PSC1_TYPED_ERROR_PASS: " ++ label)

private def prepare (kind : PsCompilerSourceKind) (source : String) :
    IO PsCompilerAdmissionReadyModule := do
  match psCompilerPrepareSource kind source with
  | .ok value => pure value
  | .error (.elaboration error) => throw (IO.userError (psHostElabErrorText error))
  | .error (.leanFrontend (.parse error)) => throw (IO.userError (psHostParseErrorText error))
  | .error (.proofScriptFrontend (.parse error)) => throw (IO.userError (psHostParseErrorText error))
  | .error _ => throw (IO.userError "typed-error source preparation failed")

private def checkPrepared (label : String) (prepared : PsCompilerAdmissionReadyModule) : IO Unit := do
  match <- psHostLeanCheckPrepared prepared with
  | .error error => throw (IO.userError (label ++ ": independent admission: " ++ error))
  | .ok _ => pure ()
  match psCompilerVerifiedIrFromPrepared prepared with
  | .error _ => throw (IO.userError (label ++ ": erasure failed"))
  | .ok ir =>
      let report := psCheckVerifiedIrModule psIrCheckDefaultOptions ir
      require (label ++ " independent admission and complete typed IR")
        (report.accepted && report.traversalComplete)

private def translate (source : String) : IO String :=
  match psCompilerTranslateSource .lean .proofScript source with
  | .ok result => pure result
  | .error _ => throw (IO.userError "typed-error translation failed")

private def dualRefusal (label source : String) : IO Unit := do
  require (label ++ " [lean]")
    (match psCompilerPrepareSource .lean source with | .error _ => true | .ok _ => false)
  let ps <- translate source
  require (label ++ " [ps]")
    (match psCompilerPrepareSource .proofScript ps with | .error _ => true | .ok _ => false)

private def compilerM : IO Unit := do
  let resultLibrary <- IO.FS.readFile "stdlib/ProofScript/Data/Result.lean"
  let effectLibrary <- IO.FS.readFile "stdlib/ProofScript/Compiler/Effect.lean"
  let fixture :=
    "def program : CompilerM Unit Nat Nat Nat := do\n" ++
    "  let mut localValue : Nat := 2\n" ++
    "  try\n" ++
    "    localValue := 100\n" ++
    "    compilerSet 99\n" ++
    "    throw 5\n" ++
    "  catch error =>\n" ++
    "    let original : Nat <- compilerGet ()\n" ++
    "    localValue := localValue + error + original\n" ++
    "    compilerSet (original + 1)\n" ++
    "  return localValue\n" ++
    "def result : Nat := match program.run () 7 with\n" ++
    "  | Result.ok pair => pair.fst * 100 + pair.snd\n" ++
    "  | Result.error error => 0\n"
  for kind in [PsCompilerSourceKind.lean, PsCompilerSourceKind.proofScript] do
    let sources <- if kind matches .lean then pure [resultLibrary, effectLibrary, fixture]
      else [resultLibrary, effectLibrary, fixture].mapM translate
    let prepared <- match psCompilerPrepareSources kind sources with
      | .ok value => pure value
      | .error (.elaboration error) => throw (IO.userError (psHostElabErrorText error))
      | .error _ => throw (IO.userError "CompilerM typed-error preparation")
    psPracticalCheckExecuted "CompilerM catch resets effect and lexical state in both grammars"
      prepared (PsExpr.constE psNatName []) (PsExpr.lit (PsLiteral.natural 1408))

  let early :=
    "def program : CompilerM Unit Nat Nat Nat := do\n" ++
    "  try\n" ++
    "    compilerSet 8\n" ++
    "    return 3\n" ++
    "  catch error =>\n" ++
    "    return 999\n" ++
    "def result : Nat := match program.run () 7 with\n" ++
    "  | Result.ok pair => pair.fst * 100 + pair.snd\n" ++
    "  | Result.error error => 0\n"
  let prepared <- match psCompilerPrepareSources .lean [resultLibrary, effectLibrary, early] with
    | .ok value => pure value
    | .error (.elaboration error) => throw (IO.userError (psHostElabErrorText error))
    | .error _ => throw (IO.userError "CompilerM early-return preparation")
  psPracticalCheckExecuted "CompilerM early return preserves successful effect state"
    prepared (PsExpr.constE psNatName []) (PsExpr.lit (PsLiteral.natural 308))

def main : IO Unit := do
  let source <- IO.FS.readFile "test/TypedErrorFixtures.lean"
  let ps <- translate source
  let original <- prepare .lean source
  let reparsed <- prepare .proofScript ps
  checkPrepared "native handler corpus" original
  checkPrepared "PS handler corpus" reparsed
  match psCompilerAdmissionsFromPrepared original, psCompilerAdmissionsFromPrepared reparsed with
  | .ok a, .ok b => require "both grammars produce the same canonical admission graph" (a == b)
  | _, _ => throw (IO.userError "typed-error canonical graph encoding")
  let back <- match psCompilerTranslateSource .proofScript .lean ps with
    | .ok value => pure value
    | .error _ => throw (IO.userError "handler reverse translation")
  let roundtripped <- prepare .lean back
  match psCompilerAdmissionsFromPrepared original, psCompilerAdmissionsFromPrepared roundtripped with
  | .ok a, .ok b => require "PS-to-Lean handler graph roundtrip" (a == b)
  | _, _ => throw (IO.userError "typed-error reverse graph encoding")
  for (label, body) in [
    ("throw error type mismatch", "def result : Except Nat Nat := do { throw true }"),
    ("Id has no typed-error channel", "def result : Id Nat := do { try { return 1 } catch error => { return 2 } }"),
    ("Id throw is not an Except action", "def result : Id Nat := do { throw 1 }"),
    ("handler result mismatch", "def result : Except Nat Nat := do { try { throw 1 } catch error => { return true } }"),
    ("catch binder cannot shadow mutable local", "def result : Except Nat Nat := do { let mut error : Nat := 1; try { throw 2 } catch error => { return error } }"),
    ("handler binder cannot escape", "def result : Except Nat Nat := do { try { pure () } catch error => { pure () }; return error }"),
    ("try local cannot escape", "def result : Except Nat Nat := do { try { let inside : Nat := 2; pure () } catch error => { pure () }; return inside }"),
    ("handler local cannot escape", "def result : Except Nat Nat := do { try { throw 1 } catch error => { let inside : Nat := 2; pure () }; return inside }"),
    ("handler cannot change mutable type", "def result : Except Nat Nat := do { let mut value : Nat := 1; try { throw 2 } catch error => { value := true }; return value }")
  ] do
    dualRefusal label body
  for source in [
    "def result : Except Nat Nat := do { try { return 1 } }",
    "def result : Except Nat Nat := do { try { throw 1 } catch error { return 2 } }",
    "def result : Except Nat Nat := do { catch error => { return 2 } }",
    "def result : Except Nat Nat := try { return 1 } catch error => { return 2 }"
  ] do
    require "malformed or out-of-block handler refuses"
      (match psCompilerPrepareSource .lean source with | .error _ => true | .ok _ => false)
  let barePs := "def result : Except Nat Nat := do {\n try {\n  throw 7\n } catch error => {\n  return error\n }\n}\n"
  checkPrepared "native-spelled PS throw and braces" (<- prepare .proofScript barePs)
  compilerM
  IO.println "PSC1_TYPED_ERROR_TESTS: PASS"
