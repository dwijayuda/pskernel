import Ps.Syntax.Pscv0.Module

-- ProofScript is the sole source authority. Compare native PSCV0 reader
-- and emitted Lean 4.35.0-rc4 *kernel-checkable* source. This does not require
-- the historical PSC0 Lean-to-ProofScript reader to accept all Lean syntax.
def pscv0App04Get {α : Type} (label : String) (value : Except String α) : IO α :=
  match value with
  | .ok result => pure result
  | .error error => throw (IO.userError (label ++ ": " ++ error))

def main : IO Unit := do
  let groupedPs :=
    "function add(x: Nat, y: Nat): Nat := Nat.add(x, y)\n" ++
    "const grouped: Nat := (add(1))(2)\n"
  let lean ← pscv0App04Get "grouped Lean projection"
    (psPscv0LowerToLean true groupedPs)
  let expectedLean :=
    "def add (x : Nat) (y : Nat) : Nat := Nat.add x y\n\n" ++
    "def grouped : Nat := (add 1) 2\n"
  unless lean == expectedLean do
    throw (IO.userError ("APP-04 grouping in generated Lean differs from exact model:\n" ++ lean))
  let printedPs ← pscv0App04Get "canonical PS printing"
    (psPscv0TranslateReadable true true groupedPs)
  let replay ← pscv0App04Get "canonical PS source replay"
    (psPscv0LowerToLean true printedPs)
  unless replay == lean do
    throw (IO.userError "APP-04 PS source print/parse changed Lean projection")

  let family :=
    "function twice(n: Nat): Nat := Nat.add(n, n)\n" ++
    "function inc(n: Nat): Nat := Nat.succ(n)\n"
  let mixed ← pscv0App04Get "mixed native/postfix"
    (psPscv0LowerToLean true (family ++ "const observed: Nat := twice inc(3)\n"))
  let nested ← pscv0App04Get "explicit nested postfix"
    (psPscv0LowerToLean true (family ++ "const observed: Nat := twice(inc(3))\n"))
  unless mixed == nested do
    throw (IO.userError "APP-04 postfix precedence not preserved")
  let misgrouped ← pscv0App04Get "different native/postfix tree"
    (psPscv0LowerToLean true (family ++ "const observed: Nat := (twice inc)(3)\n"))
  if mixed == misgrouped then
    throw (IO.userError "APP-04 mixed native/postfix and grouped source trees merged")

  let proof :=
    lean ++ "\n\ntheorem pscv0_app04_grouped_value : grouped = 3 := by rfl\n" ++
    "#print axioms pscv0_app04_grouped_value\n"
  IO.FS.createDirAll "dist/pscv0-app04"
  IO.FS.writeFile "dist/pscv0-app04/grouped-proof.lean" proof
  IO.FS.writeFile "dist/pscv0-app04/grouped.ps" groupedPs
  IO.FS.writeFile "dist/pscv0-app04/canonical.ps" printedPs
  IO.FS.writeFile "dist/pscv0-app04/lean-source.lean" lean
  IO.FS.writeFile "dist/pscv0-app04/mixed-source.lean" mixed
  IO.println "PSCV0_APP04_SOURCE_CORE: PASS grouped AST, native/postfix ownership, PS round trip"
