import PSC1Kernel.CheckerDefEqStatefulReduced

open PSC1Kernel

def expectReducedDefEq (label : String) (ok : Bool) : IO Unit :=
  if ok then pure ()
  else throw <| IO.userError ("reduced defeq smoke failed: " ++ label)

def main : IO Unit := do
  let natType : Expr := .sort (.succ .zero)
  let natExpr : Expr := .const kernelNatName []
  let xName : Name := .str .anonymous "x"
  let yName : Name := .str .anonymous "y"
  let addType : Expr :=
    .forallE xName natExpr
      (.forallE yName natExpr natExpr .default) .default
  let env0 :=
    Environment.empty.addUnchecked (.axiomInfo {
      base := { name := kernelNatName, levelParams := [], type := natType }
      isUnsafe := false
    })
  let env :=
    env0.addUnchecked (.axiomInfo {
      base := { name := kernelNatAddName, levelParams := [], type := addType }
      isUnsafe := false
    })
  let ctx := CheckerContext.empty env

  let localName : Name := .str .anonymous "n"
  let reducibleOperand : Expr :=
    .letE localName natExpr (.lit (.nat 1)) (.bvar 0) false
  let left : Expr :=
    .app
      (.app (.const kernelNatAddName []) reducibleOperand)
      (.lit (.nat 2))
  let right : Expr := .lit (.nat 3)

  match StatefulDefEqReduced.isDefEq ctx CheckerState.empty left right with
  | .error err => throw <| IO.userError ("reduced stateful defeq failed: " ++ err)
  | .ok (equal, state) =>
      expectReducedDefEq "Nat equality succeeds" equal
      expectReducedDefEq "lazy Nat reduction threads operand WHNF cache"
        ((CheckerExprMap.get? state.whnf reducibleOperand).isSome)

  IO.println "PSC1 reduced stateful defeq smoke: PASS"
