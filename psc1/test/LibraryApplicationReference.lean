import Lean

namespace PSC1LibraryReference
def input (flag : Bool) : Array Nat := if flag then #[2,4,6] else #[]
def persistent (flag : Bool) : Nat :=
  let original := input flag
  let alias := original
  let changed := (original.setIfInBounds 0 20).map (· + 1)
  changed.foldl (· + ·) 0 * 100 + alias.getD 0 0 * 10 + changed.size
def optional (flag : Bool) : Nat :=
  let original := input flag
  let unchanged := (original.push 9).setIfInBounds 9007199254740993123456789 999
  let found := match unchanged[9007199254740993123456789]? with
    | none => 7
    | some value => value
  unchanged.foldl (· + ·) 0 * 100 + original.size * 10 + found
end PSC1LibraryReference

def main : IO Unit := do
  IO.println ("PSC1_COMPILERM_ORACLE: " ++ (Lean.Json.mkObj [
    ("leanVersion",Lean.toJson Lean.versionString),("leanCommit",Lean.toJson Lean.githash),
    ("persistentLibraryCaseFalse",Lean.toJson (toString (PSC1LibraryReference.persistent false))),
    ("persistentLibraryCaseTrue",Lean.toJson (toString (PSC1LibraryReference.persistent true))),
    ("optionalLibraryCaseFalse",Lean.toJson (toString (PSC1LibraryReference.optional false))),
    ("optionalLibraryCaseTrue",Lean.toJson (toString (PSC1LibraryReference.optional true)))
  ]).compress)
