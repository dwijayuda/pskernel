import PSC1Kernel.CheckerState

open PSC1Kernel

def expectState (label : String) (ok : Bool) : IO Unit :=
  if ok then pure ()
  else throw <| IO.userError ("checker-state smoke failed: " ++ label)

def deepLambda : Nat → Expr → Expr
  | 0, leaf => leaf
  | n + 1, leaf =>
      .lam (.str .anonymous "deep") (.sort .zero) (deepLambda n leaf) .default

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

  -- The portable checker hash is deliberately bounded: unlike Lean's native
  -- Expr node it cannot read a constructor-cached hash in O(1). Deep suffixes
  -- may therefore collide, and structural Expr.eq must remain the final key
  -- discriminator. This regression lets us optimize hashing without weakening
  -- cache semantics.
  let deepLeft := deepLambda 12 (.sort .zero)
  let deepRight := deepLambda 12 (.sort (.succ .zero))
  expectState "deep collision terms are structurally distinct" (!Expr.eq deepLeft deepRight)
  expectState "bounded checker hash permits deep collision"
    (checkerExprHash deepLeft == checkerExprHash deepRight)
  let collisionMap := CheckerExprMap.empty.insert deepLeft A
  expectState "hash collision cannot create false cache hit"
    (collisionMap.get? deepRight).isNone
  let collisionMap := collisionMap.insert deepRight (.sort (.succ .zero))
  expectState "colliding left key survives"
    ((collisionMap.get? deepLeft).any (fun value => Expr.eq value A))
  expectState "colliding right key survives"
    ((collisionMap.get? deepRight).any (fun value => Expr.eq value (.sort (.succ .zero))))

  IO.println "PSC1 checker-state cache invariants smoke: PASS"
