import Ps.Syntax.Pscv0.Module

-- Native execution of the same portable implementation. This does not replace
-- generated-JavaScript qualification or confer a compiler self-host fixed point.
def expectOk {α : Type} (name : String) (result : Except String α) : IO α :=
  match result with
  | .ok value => pure value
  | .error error => throw (IO.userError (name ++ ": " ++ error))

def expectError (name code source : String) : IO Unit := do
  match psPscv0ParseSource true source with
  | .ok _ => throw (IO.userError (name ++ ": invalid source accepted"))
  | .error error =>
    if error != code then throw (IO.userError (name ++ ": expected " ++ code ++ ", got " ++ error))

def fixture (body : String) : String :=
  "function step(a: Except String Nat): Except String Nat := do {\n" ++ body ++ "\n}\n"

def main : IO Unit := do
  let examples := [
    fixture "  let x ← a\n  return Nat.succ(x)",
    fixture "  let x ← a\n  let y : Nat := Nat.succ(x)\n  Except.ok(y)",
    fixture "  let _ ← a\n  return 42",
    fixture "  a\n  return 42",
    fixture "  let x <- a\n  return x"
  ]
  for source in examples do
    let surface ← expectOk "parse PS" (psPscv0ParseSource true source)
    if psPscv0ReplayOriginal surface != source then throw (IO.userError "original source changed")
    let readable ← expectOk "print readable Lean" (psPscv0PrintSurfaceModule false surface)
    let reparsed ← expectOk "parse readable Lean" (psPscv0ParseSource false readable)
    let psAgain ← expectOk "print PS again" (psPscv0PrintSurfaceModule true reparsed)
    let originalLowered ← expectOk "lower PS" (psPscv0LowerToLean true source)
    let roundTripLowered ← expectOk "lower round trip" (psPscv0LowerToLean true psAgain)
    if originalLowered != roundTripLowered then throw (IO.userError "lowered source changed in round trip")
    IO.println readable
  expectError "empty" "PSCV0-DO-EMPTY" (fixture "")
  expectError "dangling bind" "PSCV0-DO-MISSING-FINAL-ACTION" (fixture "  let x ← a")
  expectError "nonterminal return" "PSCV0-DO-NONTERMINAL-RETURN-UNSUPPORTED" (fixture "  return 1\n  return 2")
  expectError "gap application" "PSCV0-APP-02" (fixture "  let x ← a\n  return Nat.succ (x)")
  -- V7 APP-04: a postfix call binds to its immediately preceding head
  -- before the surrounding Lean whitespace application. This checks the
  -- source/projection trees, not the intentionally ill-typed grouped branch.
  let operators :=
    "function twice(n: Nat): Nat := Nat.add(n, n)\n" ++
    "function inc(n: Nat): Nat := Nat.succ(n)\n"
  let mixed ← expectOk "v7 mixed APP-04"
    (psPscv0LowerToLean true (operators ++ "const value: Nat := twice inc(3)\n"))
  let explicit ← expectOk "v7 adjacent nested APP-04"
    (psPscv0LowerToLean true (operators ++ "const value: Nat := twice(inc(3))\n"))
  if mixed != explicit then throw (IO.userError "PSCV0-APP-04-MIXED-TREE-MISMATCH")
  let grouped ← expectOk "v7 grouped APP-04"
    (psPscv0LowerToLean true (operators ++ "const value: Nat := (twice inc)(3)\n"))
  if mixed == grouped then throw (IO.userError "PSCV0-APP-04-GROUPING-LOST")
  let groupedPS ← expectOk "v7 grouped APP-04 PS rendering"
    (psPscv0TranslateReadable false true grouped)
  let groupedAgain ← expectOk "v7 grouped APP-04 PS round trip"
    (psPscv0LowerToLean true groupedPS)
  if groupedAgain != grouped then throw (IO.userError "PSCV0-APP-04-ROUNDTRIP-TREE-CHANGED")
  expectError "gap outside do" "PSCV0-APP-02"
    (operators ++ "const value: Nat := twice (inc 3)\n")
  -- V7 is the only prospective ProofScript source language. These commands
  -- are not accepted through an older .ps grammar or native Lean fallback.
  expectError "retired partial" "PSCV0-PARTIAL-EXCLUDED"
    "partial def legacy(n: Nat): Nat := n\n"
  expectError "unsafe declaration" "PSCV0-UNSAFE-EXCLUDED"
    "unsafe def unsafeCode(n: Nat): Nat := n\n"
  expectError "source axiom" "PSCV0-SOURCE-AXIOM-EXCLUDED"
    "axiom unproved : False\n"
  expectError "removed verify" "PSCV0-VERIFY-REMOVED"
    "verify f := by { omega }\n"
  expectError "removed ghost" "PSCV0-GHOST-REMOVED"
    "ghost mut x := 0\n"
  expectError "unselected syntax extension" "PSCV0-V7-COMMAND-NOT-YET-SUPPORTED"
    "syntax \"foo\" : term\n"
  let commented := "-- preserve me\n" ++ examples.head!
  let surface ← expectOk "commented source" (psPscv0ParseSource true commented)
  if psPscv0ReplayOriginal surface != commented then throw (IO.userError "comment was lost")
  match psPscv0PrintSurfaceModule false surface with
  | .ok _ => throw (IO.userError "unanchored comments were silently printed")
  | .error error =>
    if error != "PSCV0-TRIVIA-PRINT-PENDING" then throw (IO.userError error)
  let body := "(a: Except String Nat, b: Except String Nat): Except String Nat := do {\n  let x ← a\n  let y ← b\n  return Nat.add(x, y)\n}\n"
  let readable ← expectOk "reference readable" (psPscv0TranslateReadable true false ("function referenceProgram" ++ body))
  let lowered ← expectOk "reference lowered" (psPscv0LowerToLean true ("function loweredProgram" ++ body))
  let theoremSource := readable ++ "\n" ++ lowered ++ "\ntheorem pscv0_native_do_correspondence (a b : Except String Nat) :\n    referenceProgram a b = loweredProgram a b := by\n  cases a <;> cases b <;> rfl\n\n#print axioms pscv0_native_do_correspondence\n"
  IO.FS.createDirAll "dist/pscv0-source-check"
  IO.FS.writeFile "dist/pscv0-source-check/correspondence.lean" theoremSource
  IO.println theoremSource
  IO.println "PSCV0_NATIVE_SURFACE_SMOKE: PASS 5 do round trips, APP-04 source-tree comparison, 11 refusals, exact comment replay; emitted correspondence fixture still requires checking"
