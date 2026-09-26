import PSC1Kernel.CheckerStateful

open PSC1Kernel

def expectDefEqStateful (label : String) (ok : Bool) : IO Unit :=
  if ok then pure ()
  else throw <| IO.userError ("stateful defeq smoke failed: " ++ label)

def main : IO Unit := do
  let fName : Name := .str .anonymous "StatefulDefEqF"
  let xName : Name := .str .anonymous "x"
  let fType : Expr :=
    .forallE xName (.sort (.succ .zero)) (.sort (.succ .zero)) .default
  let fValue : Expr :=
    .lam xName (.sort (.succ .zero)) (.bvar 0) .default
  let env :=
    Environment.empty.addUnchecked (.defnInfo {
      base := { name := fName, levelParams := [], type := fType }
      value := fValue
      hints := .regular 1
      safety := .safe
    })
  let ctx := CheckerContext.empty env
  let left : Expr := .app (.const fName []) (.sort .zero)
  let right : Expr := .app (.const fName []) (.sort (.succ .zero))

  match isDefEqStateful ctx CheckerState.empty left right with
  | .error err =>
      throw <| IO.userError ("real stateful defeq failed: " ++ err)
  | .ok (equal, state) =>
      expectDefEqStateful "same-definition mismatched applications remain unequal" (!equal)
      -- This is the decisive integration assertion. Lean 4.34 records this pair
      -- only after the regular same-definition argument shortcut fails. An
      -- outer success-cache wrapper around the old pure defeq cannot satisfy it.
      expectDefEqStateful "real defeq reaches narrow lazy-delta failure memo"
        (CheckerExprPairSet.contains state.failure left right)
      expectDefEqStateful "negative pair is not inserted into success memo"
        (!CheckerExprPairSet.contains state.success left right)

  IO.println "PSC1 recursive stateful defeq smoke: PASS"
