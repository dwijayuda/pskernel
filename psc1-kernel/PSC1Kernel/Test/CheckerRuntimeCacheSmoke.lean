import PSC1Kernel.CheckerRuntimeCache

open PSC1Kernel

private def expectCache (label : String) (ok : Bool) : IO Unit :=
  if ok then pure ()
  else throw <| IO.userError ("checker-runtime-cache smoke failed: " ++ label)

private def expectOkBool (label : String) (actual : Except String Bool) (expected : Bool) : IO Unit :=
  match actual with
  | .ok value => expectCache label (value == expected)
  | .error message =>
      throw <| IO.userError
        ("checker-runtime-cache smoke failed: " ++ label ++ ": " ++ message)

def main : IO Unit := do
  let cache := CheckerRuntimeCache.freshFor Environment.empty
  let left : Expr := .sort .zero
  let right : Expr := .sort (.succ .zero)

  let first :=
    CheckerRuntimeCache.withClosedSuccess cache left right (fun _ => .ok true)
  expectOkBool "first closed computation" first true

  let reused :=
    CheckerRuntimeCache.withClosedSuccess cache right left (fun _ => .ok false)
  expectOkBool "closed successful pair is reused symmetrically" reused true

  let fvar : Expr := .fvar (.str .anonymous "x")
  let openFirst :=
    CheckerRuntimeCache.withClosedSuccess cache fvar left (fun _ => .ok true)
  expectOkBool "open pair first computation" openFirst true

  let openSecond :=
    CheckerRuntimeCache.withClosedSuccess cache fvar left (fun _ => .ok false)
  expectOkBool "FVar pair bypasses success cache" openSecond false

  IO.println "PSC1 checker runtime cache smoke: PASS"
