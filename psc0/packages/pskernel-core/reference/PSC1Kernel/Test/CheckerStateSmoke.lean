import PSC1Kernel.CheckerState

open PSC1Kernel

def expectState (label : String) (ok : Bool) : IO Unit :=
  if ok then pure ()
  else throw <| IO.userError ("checker-state smoke failed: " ++ label)

def main : IO Unit := do
  let A : Expr := .sort .zero
  let body : Expr := .bvar 0
  let left : Expr :=
    .lam (.str .anonymous "left") A body .default
  let right : Expr :=
    .lam (.str .anonymous "right") A body .implicit

  expectState "Expr.eq ignores binder presentation" (Expr.eq left right)
  expectState "hash follows Expr.eq"
    (checkerExprHash left == checkerExprHash right)

  let inferOnly := CheckerExprMap.empty.insert left A
  expectState "structural expr-map lookup"
    ((inferOnly.get? right).any (fun value => Expr.eq value A))

  let pairSet := CheckerExprPairSet.empty.insert left A
  expectState "defeq pair set is symmetric" (pairSet.contains A right)

  let state0 := CheckerState.empty
  let state1 := { state0 with inferOnly := state0.inferOnly.insert left A }
  expectState "infer-only cache populated" (state1.inferOnly.get? right).isSome
  expectState "checked-infer cache remains separate" (state1.checkedInfer.get? right).isNone

  let base : Name := .str .anonymous "x"
  let (f1, state2) := state1.freshName base
  let (f2, _) := state2.freshName base
  expectState "session-global fresh FVars" (!Name.eq f1 f2)

  let success := state1.success.insert left A
  expectState "positive defeq cache" (success.contains A right)
  expectState "negative defeq cache remains separate" (!state1.failure.contains A right)

  IO.println "PSC1 checker-state cache invariants smoke: PASS"
