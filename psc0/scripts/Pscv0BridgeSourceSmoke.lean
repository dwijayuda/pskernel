import Ps.Syntax.Pscv0.Module

-- Fast native execution of the SAME portable implementation. This does not
-- replace the generated-JavaScript gate or confer compiler self-host status.
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
  let commented := "-- preserve me\n" ++ examples.head!
  let surface ← expectOk "commented source" (psPscv0ParseSource true commented)
  if psPscv0ReplayOriginal surface != commented then throw (IO.userError "comment was lost")
  match psPscv0PrintSurfaceModule false surface with
  | .ok _ => throw (IO.userError "unanchored comments were silently printed")
  | .error error =>
    if error != "PSCV0-TRIVIA-PRINT-PENDING" then throw (IO.userError error)
  IO.println "PSCV0_NATIVE_SURFACE_SMOKE: PASS 5 round trips, 4 refusals, exact comment replay"
