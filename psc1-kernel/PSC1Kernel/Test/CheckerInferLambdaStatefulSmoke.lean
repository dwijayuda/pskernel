import PSC1Kernel.CheckerStateful

open PSC1Kernel

def expectLambdaStateful (label : String) (ok : Bool) : IO Unit :=
  if ok then pure ()
  else throw <| IO.userError ("stateful lambda infer smoke failed: " ++ label)

def main : IO Unit := do
  let xName : Name := .str .anonymous "x"
  let input : Expr :=
    .lam xName (.sort .zero) (.bvar 0) .default
  let expected : Expr :=
    .forallE xName (.sort .zero) (.sort .zero) .default
  let ctx := CheckerContext.empty Environment.empty
  let initial := { CheckerState.empty with nextFresh := 7 }

  match inferStateful ctx initial input with
  | .error err =>
      throw <| IO.userError ("stateful lambda infer failed: " ++ err)
  | .ok (actual, state) =>
      expectLambdaStateful "lambda result" (Expr.eq actual expected)
      expectLambdaStateful "outer lambda is cached"
        ((CheckerExprMap.get? state.inferOnly input).isSome)
      -- A whole-lambda fallback into the old pure checker can only cache the
      -- outer expression. A real stateful lambda spine must recursively infer
      -- the opened body and therefore leave at least one additional infer-only
      -- entry while consuming the declaration-scoped fresh-name supply.
      expectLambdaStateful "lambda recursively populates infer cache"
        (state.inferOnly.size > 1)
      expectLambdaStateful "lambda consumes checker fresh-name state"
        (state.nextFresh > initial.nextFresh)

  IO.println "PSC1 stateful lambda infer smoke: PASS"
