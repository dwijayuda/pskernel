import Ps.Host.ProjectCompiler
import Ps.Elab.DoLoopLift
import PracticalExecution

private def require (label : String) (condition : Bool) : IO Unit := do
  if !condition then throw (IO.userError ("PSC1_WHILE_FAIL: " ++ label))
  IO.println ("PSC1_WHILE_PASS: " ++ label)

private def elaborate (label : String) (kind : PsCompilerSourceKind)
    (source : String) : IO PsElabModuleResult :=
  match psCompilerElaborateSource kind source with
  | .ok value => pure value
  | .error (.leanFrontend (.lex error)) =>
      throw (IO.userError (label ++ ": " ++ psHostLexErrorText error))
  | .error (.leanFrontend (.parse error)) =>
      throw (IO.userError (label ++ ": " ++ psHostParseErrorText error))
  | .error (.proofScriptFrontend (.lex error)) =>
      throw (IO.userError (label ++ ": " ++ psHostLexErrorText error))
  | .error (.proofScriptFrontend (.parse error)) =>
      throw (IO.userError (label ++ ": " ++ psHostParseErrorText error))
  | .error (.elaboration error) =>
      throw (IO.userError (label ++ ": " ++ psHostElabErrorText error))
  | .error _ => throw (IO.userError (label ++ ": source elaboration"))

private def checkSource (label : String) (kind : PsCompilerSourceKind)
    (source : String) (type expected : PsExpr) : IO Unit := do
  let input ← elaborate label kind source
  psPracticalCheckExecutedOrdinary label input type expected

private def rejectElaboration (label : String) (source : String)
    (accept : PsElabError -> Bool) : IO Unit :=
  match psCompilerElaborateSource .lean source with
  | .error (.elaboration error) =>
      require (label ++ ": " ++ psHostElabErrorText error) (accept error)
  | .error _ => throw (IO.userError (label ++ ": fixture failed before elaboration"))
  | .ok _ => throw (IO.userError (label ++ ": unsupported fixture accepted"))

private def unsupported : PsElabError -> Bool
  | .doWhileUnsupportedBody => true
  | _ => false

private def counter : String :=
  "partial def counted (limit : Nat) : Id Nat := do\n" ++
  "  let mut i := 0\n" ++
  "  while Nat.blt i limit do\n" ++
  "    i := Nat.succ i\n" ++
  "  return i\n"

private def testCounting : IO Unit := do
  let natType := PsExpr.constE psNatName []
  for n in [0, 1, 10000] do
    checkSource ("ordinary while count " ++ toString n) .lean
      (counter ++ "def result : Nat := Id.run (counted " ++ toString n ++ ")\n")
      natType (.lit (.natural n))
  let ps :=
    "partial def counted(limit : Nat) : Id(Nat) := do {\n" ++
    "  let mut i := 0\n" ++
    "  while (Nat.blt(i, limit)) {\n" ++
    "    i := Nat.succ(i)\n" ++
    "  }\n" ++
    "  return i\n" ++
    "}\n" ++
    "def result : Nat := Id.run(counted(6))\n"
  checkSource "PS ordinary while counts" .proofScript ps natType (.lit (.natural 6))
  let translated ← match psCompilerTranslateSource .proofScript .lean ps with
    | .error _ => throw (IO.userError "while translation to Lean")
    | .ok value => pure value
  let original ← elaborate "while original" .proofScript ps
  let reparsed ← elaborate "while translated" .lean translated
  let first ← match psCompilerPrepareOrdinary original with
    | .error error => throw (IO.userError error)
    | .ok value => pure value
  let second ← match psCompilerPrepareOrdinary reparsed with
    | .error error => throw (IO.userError error)
    | .ok value => pure value
  match psCompilerAdmissionsFromPrepared first.logical,
      psCompilerAdmissionsFromPrepared second.logical with
  | .ok first, .ok second =>
      require "while translation preserves exact ordinary logical graph" (first == second)
  | _, _ => throw (IO.userError "while canonical ordinary admission")
  let owner := psRootName "counted"
  let marker := psElabDoLoopName owner
  require "source graph contains a per-site private partial helper"
    (original.declarations.any (fun declaration =>
      match declaration with
      | .partialDecl name _ _ _ => psElabDoLoopIsLiftedName owner name
      | _ => false))
  require "source graph contains no temporary generic while marker"
    (original.declarations.all (fun declaration =>
      match declaration with
      | .partialDecl _ _ type body | .definitionDecl _ _ type body =>
          !(psElabDoLoopOccurs marker type || psElabDoLoopOccurs marker body)
      | _ => true))
  checkSource "terminal false while returns Unit" .lean
    ("partial def done (flag : Bool) : Id Unit := do\n" ++
      "  while flag do\n    ()\n" ++
      "def result : Unit := Id.run (done false)\n")
    (.constE psUnitName []) (.constE psUnitUnitName [])

private def testCaptures : IO Unit := do
  let natType := PsExpr.constE psNatName []
  checkSource "while carries two mutable values and preserves an earlier closure" .lean
    ("partial def captured (limit : Nat) : Id Nat := do\n" ++
      "  let mut i := 0\n" ++
      "  let mut total := 3\n" ++
      "  let saved : Nat -> Nat := fun (n : Nat) => Nat.add total n\n" ++
      "  while Nat.blt i limit do\n" ++
      "    total := Nat.add total i\n" ++
      "    i := Nat.succ i\n" ++
      "  return Nat.add total (saved 1)\n" ++
      "def result : Nat := Id.run (captured 4)\n")
    natType (.lit (.natural 13))
  checkSource "while closes type-dependent captures in telescope order" .lean
    ("partial def captured {A : Type} (get : A -> Nat) (value : A) (limit : Nat) : Id Nat := do\n" ++
      "  let mut i := 0\n" ++
      "  let mut total := 0\n" ++
      "  while Nat.blt i limit do\n" ++
      "    total := Nat.add total (get value)\n" ++
      "    i := Nat.succ i\n" ++
      "  return total\n" ++
      "def result : Nat := Id.run (captured (fun (n : Nat) => n) 7 3)\n")
    natType (.lit (.natural 21))
  checkSource "while helper captures the source function without a forward dependency" .lean
    ("partial def prior (n : Nat) : Id Nat := do\n" ++
      "  if Nat.beq n 0 then\n    return 0\n" ++
      "  let mut i := 0\n" ++
      "  while Nat.blt i 1 do\n" ++
      "    let previous : Nat := Id.run (prior (Nat.sub n 1))\n" ++
      "    return Nat.succ previous\n" ++
      "  return 999\n" ++
      "def result : Nat := Id.run (prior 3)\n")
    natType (.lit (.natural 3))

private def testControl : IO Unit := do
  let natType := PsExpr.constE psNatName []
  checkSource "while early return skips later iterations and the outer continuation" .lean
    ("partial def first (limit : Nat) : Id Nat := do\n" ++
      "  let mut i := 0\n" ++
      "  while Nat.blt i limit do\n" ++
      "    if Nat.beq i 3 then\n      return i\n" ++
      "    i := Nat.succ i\n" ++
      "  return 999\n" ++
      "def result : Nat := Id.run (first 10)\n")
    natType (.lit (.natural 3))
  checkSource "sequential while loops preserve state and helper dependency order" .lean
    ("partial def sequential (limit : Nat) : Id Nat := do\n" ++
      "  let mut i := 0\n" ++
      "  let mut total := 0\n" ++
      "  while Nat.blt i 3 do\n" ++
      "    i := Nat.succ i\n" ++
      "    total := Nat.add total i\n" ++
      "  while Nat.blt i limit do\n" ++
      "    i := Nat.succ i\n" ++
      "    total := Nat.add total i\n" ++
      "  return total\n" ++
      "def result : Nat := Id.run (sequential 5)\n")
    natType (.lit (.natural 15))
  checkSource "while within a finite loop carries the outer mutable local" .lean
    ("partial def nested (limit : Nat) : Id Nat := do\n" ++
      "  let mut total := 0\n" ++
      "  for value in [1:limit] do\n" ++
      "    let mut i := 0\n" ++
      "    while Nat.blt i value do\n" ++
      "      total := Nat.succ total\n" ++
      "      i := Nat.succ i\n" ++
      "  return total\n" ++
      "def result : Nat := Id.run (nested 4)\n")
    natType (.lit (.natural 6))
  checkSource "outer early return bypasses an otherwise divergent while" .lean
    ("partial def stopped (flag : Bool) : Id Bool := do\n" ++
      "  if flag then\n    return true\n" ++
      "  while true do\n    ()\n" ++
      "  return false\n" ++
      "def result : Bool := Id.run (stopped true)\n")
    (.constE psBoolName []) (.constE psBoolTrueName [])

private def testExcept : IO Unit := do
  let natType := PsExpr.constE psNatName []
  let stringType := PsExpr.constE psStringName []
  let type := psSelfHostExceptOf stringType natType
  checkSource "while sequences successful Except actions" .lean
    ("partial def accumulated (limit : Nat) : Except String Nat := do\n" ++
      "  let mut i := 0\n" ++
      "  let mut total := 0\n" ++
      "  while Nat.blt i limit do\n" ++
      "    let value : Nat <- Except.ok (Nat.succ i)\n" ++
      "    total := Nat.add total value\n" ++
      "    i := Nat.succ i\n" ++
      "  return total\n" ++
      "def result : Except String Nat := accumulated 4\n")
    type (psSelfHostExceptOkOf stringType natType (.lit (.natural 10)))
  let source :=
    "partial def failing (limit : Nat) : Except String Nat := do\n" ++
    "  let mut i := 0\n" ++
    "  while Nat.blt i limit do\n" ++
    "    let value : Nat <- if Nat.beq i 3 then Except.error \"three\" else Except.ok i\n" ++
    "    i := Nat.succ value\n" ++
    "  return i\n" ++
    "def result : Except String Nat := failing 6\n"
  checkSource "while propagates the first typed Except failure" .lean source
    type (psSelfHostExceptErrorOf stringType natType (.lit (.string "three")))
  checkSource "while early return remains separate from a later Except failure" .lean
    ("partial def returning (limit : Nat) : Except String Nat := do\n" ++
      "  let mut i := 0\n" ++
      "  while Nat.blt i limit do\n" ++
      "    if Nat.beq i 2 then\n      return 7\n" ++
      "    let value : Nat <- if Nat.beq i 3 then Except.error \"three\" else Except.ok i\n" ++
      "    i := Nat.succ value\n" ++
      "  return 999\n" ++
      "def result : Except String Nat := returning 6\n")
    type (psSelfHostExceptOkOf stringType natType (.lit (.natural 7)))

private def testBoundaries : IO Unit := do
  rejectElaboration "while requires an explicit partial owner"
    "def total (flag : Bool) : Id Nat := do { while flag do { () }; return 7 }\n"
    (fun error => match error with | .doWhileNeedsPartial => true | _ => false)
  rejectElaboration "nested procedural while in a while body is explicitly refused"
    ("partial def nested (flag : Bool) : Id Nat := do\n" ++
      "  while flag do\n    while flag do\n      ()\n" ++
      "  return 7\n") unsupported
  rejectElaboration "procedural for in a while body is explicitly refused"
    ("partial def nested (flag : Bool) : Id Nat := do\n" ++
      "  while flag do\n    for i in [0:3] do\n      ()\n" ++
      "  return 7\n") unsupported
  rejectElaboration "function-valued Id while result is explicitly refused"
    ("partial def functionResult (flag : Bool) : Id (Nat -> Nat) := do\n" ++
      "  while flag do\n    ()\n" ++
      "  return fun (n : Nat) => n\n") unsupported
  rejectElaboration "generic result cannot later instantiate to a function"
    ("partial def genericResult {A : Type} (fallback : A) (flag : Bool) : Id A := do\n" ++
      "  while flag do\n    ()\n" ++
      "  return fallback\n" ++
      "def result : Nat := (Id.run (genericResult (fun (n : Nat) => n) false)) 7\n")
    unsupported
  rejectElaboration "while body locals do not escape"
    ("partial def localScope (limit : Nat) : Id Nat := do\n" ++
      "  let mut i := 0\n" ++
      "  while Nat.blt i limit do\n" ++
      "    let inside := Nat.succ i\n    i := inside\n" ++
      "  return inside\n")
    (fun error => match error with | .unknownName _ => true | _ => false)
  let localAlias :=
    "partial def alias (seed : Nat) : Id Nat := do\n" ++
    "  let T : Type := Nat\n" ++
    "  let mut value : T := seed\n"
  let _ ← elaborate "local type alias without a loop" .lean
    (localAlias ++ "  return value\n")
  -- Abstraction of a let-bound type currently loses its definitional equality.
  -- The helper type checker must reject, never replace that equality by an axiom.
  rejectElaboration "captured local type aliases fail closed in this while profile"
    (localAlias ++
      "  while Nat.blt value 1 do\n    value := Nat.succ value\n" ++
      "  return value\n")
    (fun _ => true)
  let input ← elaborate "ordinary-only while" .lean counter
  require "default checked admission refuses the generated partial graph"
    (match psCompilerPrepareElaborated input with | .error (.admission _) => true | _ => false)
  let resultLibrary ← IO.FS.readFile "stdlib/ProofScript/Data/Result.lean"
  let effectLibrary ← IO.FS.readFile "stdlib/ProofScript/Compiler/Effect.lean"
  let compilerFixture :=
    "partial def compilerWhile (flag : Bool) : CompilerM Unit Nat String Nat := do\n" ++
    "  while flag do\n    compilerSet 7\n" ++
    "  return 7\n"
  match psCompilerElaborateSourcesWorker .lean
      [resultLibrary, effectLibrary, compilerFixture] psSelfHostProdPreludeEnvironment [] with
  | .error (.elaboration error) =>
      require "CompilerM while is explicitly outside the current profile" (unsupported error)
  | .error _ => throw (IO.userError "CompilerM while fixture failed before elaboration")
  | .ok _ => throw (IO.userError "CompilerM while was silently accepted")

def main : IO Unit := do
  let groups : List (String × IO Unit) := [
    ("counting", testCounting),
    ("captures", testCaptures),
    ("control", testControl),
    ("Except", testExcept),
    ("boundaries", testBoundaries)]
  let mut failures : List String := []
  for (label, action) in groups do
    try
      action
    catch error =>
      IO.eprintln ("PSC1_WHILE_GROUP_FAIL: " ++ label ++ ": " ++ toString error)
      failures := failures ++ [label]
  if !failures.isEmpty then
    throw (IO.userError ("PSC1_WHILE_TESTS_FAILED: " ++ String.intercalate ", " failures))
  IO.println "PSC1_WHILE_TESTS: PASS"
