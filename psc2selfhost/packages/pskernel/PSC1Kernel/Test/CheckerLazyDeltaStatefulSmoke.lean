import PSC1Kernel.CheckerLazyDeltaStateful

open PSC1Kernel

def expectLazyDeltaStateful (label : String) (ok : Bool) : IO Unit :=
  if ok then pure ()
  else throw <| IO.userError ("stateful lazy-delta smoke failed: " ++ label)

def deltaStatusDifferent : DeltaStepResult → Bool
  | .different _ _ => true
  | _ => false

def main : IO Unit := do
  let fName : Name := .str .anonymous "StatefulDeltaF"
  let xName : Name := .str .anonymous "x"
  let fType : Expr :=
    .forallE xName (.sort .zero) (.sort .zero) .default
  let fValue : Expr :=
    .lam xName (.sort .zero) (.bvar 0) .default
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
  let initial := CheckerState.empty

  match lazyDeltaReductionStepStateful ctx initial left right with
  | .error err =>
      throw <| IO.userError ("first stateful lazy-delta step failed: " ++ err)
  | .ok (status1, state1) =>
      expectLazyDeltaStateful "mismatched same-definition args continue to different result"
        (deltaStatusDifferent status1)
      expectLazyDeltaStateful "failed same-definition argument shortcut is cached"
        (CheckerExprPairSet.contains state1.failure left right)
      expectLazyDeltaStateful "failure shortcut does not create success memo"
        (state1.success.entries.size == 0)
      let failureSize := state1.failure.entries.size
      match lazyDeltaReductionStepStateful ctx state1 right left with
      | .error err =>
          throw <| IO.userError ("second stateful lazy-delta step failed: " ++ err)
      | .ok (status2, state2) =>
          expectLazyDeltaStateful "symmetric cached failure preserves result"
            (deltaStatusDifferent status2)
          expectLazyDeltaStateful "symmetric failure memo cardinality is stable"
            (state2.failure.entries.size == failureSize)
          expectLazyDeltaStateful "narrow failure memo remains present"
            (CheckerExprPairSet.contains state2.failure left right)

  IO.println "PSC1 stateful lazy-delta failure memo smoke: PASS"
