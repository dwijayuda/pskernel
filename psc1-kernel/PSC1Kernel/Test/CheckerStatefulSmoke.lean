import PSC1Kernel.CheckerState
import PSC1Kernel.TypeChecker

open PSC1Kernel

def expectStateful (label : String) (ok : Bool) : IO Unit :=
  if ok then pure ()
  else throw <| IO.userError ("stateful checker smoke failed: " ++ label)

def main : IO Unit := do
  let ctx := CheckerContext.empty Environment.empty
  let input : Expr := .sort .zero
  let expected : Expr := .sort (.succ .zero)
  let initial := { CheckerState.empty with nextFresh := 7 }

  match checkStateful ctx initial input with
  | .error err =>
      throw <| IO.userError ("stateful check failed: " ++ err)
  | .ok (actual, state1) =>
      expectStateful "checked result" (Expr.eq actual expected)
      expectStateful "state is threaded" (state1.nextFresh == 7)
      expectStateful "checked infer result is cached"
        (match CheckerExprMap.get? state1.checkedInfer input with
         | some cached => Expr.eq cached expected
         | none => false)
      match checkStateful ctx state1 input with
      | .error err =>
          throw <| IO.userError ("second stateful check failed: " ++ err)
      | .ok (actual2, state2) =>
          expectStateful "second checked result" (Expr.eq actual2 expected)
          expectStateful "checked cache cardinality is stable"
            (state2.checkedInfer.size == state1.checkedInfer.size)

  match inferStateful ctx initial input with
  | .error err =>
      throw <| IO.userError ("stateful infer failed: " ++ err)
  | .ok (actual, state) =>
      expectStateful "infer-only result" (Expr.eq actual expected)
      expectStateful "infer-only cache is separate"
        (match CheckerExprMap.get? state.inferOnly input with
         | some cached => Expr.eq cached expected
         | none => false)
      expectStateful "checked cache remains empty in infer-only run"
        (state.checkedInfer.size == 0)

  IO.println "PSC1 stateful recursive checker smoke: PASS"
