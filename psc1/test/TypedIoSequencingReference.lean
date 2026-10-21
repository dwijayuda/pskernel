import Lean
private def sequenceReference (flag : Bool) : Nat :=
  let text := if flag then "😀" else "A"
  let first := text.toList.head!
  first.toNat + ([1,2,3] : List Nat).foldl (· + ·) 0 + (if flag then 1 else 2)
private def recoveryReference (flag : Bool) : Nat :=
  let read : Except String String := if flag then .error "notFound" else .ok "A"
  match read with
  | .ok _ => 7
  | .error _ => 3 + 2
def main : IO Unit := do
  IO.println ("PSC1_COMPILERM_ORACLE: " ++ (Lean.Json.mkObj [
    ("leanVersion",Lean.toJson Lean.versionString),("leanCommit",Lean.toJson Lean.githash),
    ("sequenceCaseFalse",Lean.toJson (toString (sequenceReference false))),
    ("sequenceCaseTrue",Lean.toJson (toString (sequenceReference true))),
    ("recoveryCaseFalse",Lean.toJson (toString (recoveryReference false))),
    ("recoveryCaseTrue",Lean.toJson (toString (recoveryReference true)))
  ]).compress)
