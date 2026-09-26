import PSC1Kernel

open PSC1Kernel

def expectUnfold (label : String) (ok : Bool) : IO Unit :=
  if ok then pure ()
  else throw <| IO.userError ("stateful unfold smoke failed: " ++ label)

def main : IO Unit := do
  let u : Name := .str .anonymous "u"
  let D : Name := .str .anonymous "PolyUnfold"
  let input : Expr := .const D [.zero]
  let expected : Expr := .sort .zero
  let env :=
    Environment.empty.addUnchecked (.defnInfo {
      base := {
        name := D
        levelParams := [u]
        type := .sort (.succ (.param u))
      }
      value := .sort (.param u)
      hints := .regular 0
      safety := .safe
    })
  let session := Kernel.mkCheckerSession env [] .safe
  match session.whnfStateful input with
  | .error err => throw <| IO.userError err
  | .ok (actual, next) =>
      expectUnfold "polymorphic definition unfolds" (Expr.eq actual expected)
      expectUnfold "universe-instantiated head is memoized"
        (match CheckerExprMap.get? next.state.unfold input with
         | some value => Expr.eq value expected
         | none => false)
      let unfoldSize := next.state.unfold.size
      match StatefulReduction.unfoldDefinitionStateful next.context next.state input with
      | .error err => throw <| IO.userError err
      | .ok (some value, finalState) =>
          expectUnfold "memoized unfold result" (Expr.eq value expected)
          expectUnfold "unfold cache cardinality stable" (finalState.unfold.size == unfoldSize)
      | .ok (none, _) =>
          throw <| IO.userError "memoized unfold unexpectedly returned none"
  IO.println "PSC1 stateful unfold cache smoke: PASS"
