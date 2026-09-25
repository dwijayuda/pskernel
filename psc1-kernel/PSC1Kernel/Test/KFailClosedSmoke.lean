import PSC1Kernel

open PSC1Kernel

def main : IO Unit := do
  let Truth : Name := .str .anonymous "KFailClosedTruth"
  let EqRec : Name := .str (.str .anonymous "Eq") "rec"
  let recursor : RecursorInfo := {
    base := {
      name := EqRec
      levelParams := []
      type := .forallE (.str .anonymous "proof") (.const Truth [])
        (.const kernelNatName []) .default
    }
    all := [Truth]
    numParams := 0
    numIndices := 0
    numMotives := 0
    numMinors := 0
    rules := []
    k := true
    isUnsafe := false
  }
  let ctx := CheckerContext.empty Environment.empty
  let wrongMajor : Expr := .lit (.nat 0)
  match toConstructorWhenK ctx recursor wrongMajor with
  | .error err =>
      throw <| IO.userError (
        "K conversion rejected a nonmatching Eq.rec major instead of failing closed: " ++ err)
  | .ok result =>
      if Expr.eq result wrongMajor then
        IO.println "PSC1 Eq.rec K fail-closed smoke: PASS"
      else
        throw <| IO.userError "K conversion changed a nonmatching Eq.rec major"
