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

  let whnfInput : Expr :=
    .app
      (.lam (.str .anonymous "x") (.sort .zero) (.bvar 0) .default)
      (.sort .zero)
  let whnfExpected : Expr := .sort .zero
  match whnfStateful ctx initial whnfInput with
  | .error err =>
      throw <| IO.userError ("stateful whnf failed: " ++ err)
  | .ok (actual, state1) =>
      expectStateful "whnf result" (Expr.eq actual whnfExpected)
      expectStateful "whnf result is cached"
        (match CheckerExprMap.get? state1.whnf whnfInput with
         | some cached => Expr.eq cached whnfExpected
         | none => false)
      expectStateful "whnf-core table remains separate"
        (state1.whnfCore.size == 0)
      match whnfStateful ctx state1 whnfInput with
      | .error err =>
          throw <| IO.userError ("second stateful whnf failed: " ++ err)
      | .ok (actual2, state2) =>
          expectStateful "second whnf result" (Expr.eq actual2 whnfExpected)
          expectStateful "whnf cache cardinality is stable"
            (state2.whnf.size == state1.whnf.size)

  -- This term forces checked application inference to expose a function type
  -- through public WHNF. A merely outer `checkStateful` wrapper cannot populate
  -- this internal WHNF entry; recursive checker state must flow through infer.
  let fName : Name := .str .anonymous "f"
  let xName : Name := .str .anonymous "x"
  let aName : Name := .str .anonymous "A"
  let letFnType : Expr :=
    .letE aName
      (.sort (.succ .zero))
      (.sort .zero)
      (.forallE xName (.sort .zero) (.sort .zero) .default)
      false
  let exposedFnType : Expr :=
    .forallE xName (.sort .zero) (.sort .zero) .default
  let recursiveLCtx :=
    (LocalContext.empty.addLocal fName fName letFnType .default).addLocal
      xName xName (.sort .zero) .default
  let recursiveCtx := { ctx with lctx := recursiveLCtx }
  let recursiveInput : Expr := .app (.fvar fName) (.fvar xName)
  match checkStateful recursiveCtx initial recursiveInput with
  | .error err =>
      throw <| IO.userError ("recursive stateful check failed: " ++ err)
  | .ok (actual, state) =>
      expectStateful "recursive checked result" (Expr.eq actual (.sort .zero))
      expectStateful "recursive checked infer caches top application"
        ((CheckerExprMap.get? state.checkedInfer recursiveInput).isSome)
      expectStateful "recursive inference threads internal WHNF cache"
        (match CheckerExprMap.get? state.whnf letFnType with
         | some cached => Expr.eq cached exposedFnType
         | none => false)

  IO.println "PSC1 stateful recursive checker smoke: PASS"
