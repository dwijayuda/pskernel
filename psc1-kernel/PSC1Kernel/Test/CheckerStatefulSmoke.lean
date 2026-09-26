import PSC1Kernel.CheckerStateful

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
      expectStateful "public whnf threads whnf-core cache"
        (match CheckerExprMap.get? state1.whnfCore whnfInput with
         | some cached => Expr.eq cached whnfExpected
         | none => false)
      match whnfStateful ctx state1 whnfInput with
      | .error err =>
          throw <| IO.userError ("second stateful whnf failed: " ++ err)
      | .ok (actual2, state2) =>
          expectStateful "second whnf result" (Expr.eq actual2 whnfExpected)
          expectStateful "whnf cache cardinality is stable"
            (state2.whnf.size == state1.whnf.size)
          expectStateful "whnf-core cache cardinality is stable"
            (state2.whnfCore.size == state1.whnfCore.size)

  match whnfCoreStateful ctx initial whnfInput false true with
  | .error err =>
      throw <| IO.userError ("cheap-proj stateful whnf-core failed: " ++ err)
  | .ok (actual, state) =>
      expectStateful "cheap-proj whnf-core result" (Expr.eq actual whnfExpected)
      expectStateful "cheap-proj suppresses whnf-core cache" (state.whnfCore.size == 0)

  match isDefEqStateful ctx initial whnfInput whnfExpected with
  | .error err =>
      throw <| IO.userError ("stateful defeq failed: " ++ err)
  | .ok (equal1, state1) =>
      expectStateful "stateful defeq succeeds" equal1
      expectStateful "successful defeq pair is cached"
        (CheckerExprPairSet.contains state1.success whnfInput whnfExpected)
      let successSize := state1.success.entries.size
      match isDefEqStateful ctx state1 whnfExpected whnfInput with
      | .error err =>
          throw <| IO.userError ("symmetric stateful defeq failed: " ++ err)
      | .ok (equal2, state2) =>
          expectStateful "symmetric successful defeq reuses cache" equal2
          expectStateful "successful defeq cache cardinality is stable"
            (state2.success.entries.size == successSize)
          expectStateful "positive memo does not populate failure set"
            (state2.failure.entries.size == 0)

  match isDefEqStateful ctx initial (.sort .zero) (.sort (.succ .zero)) with
  | .error err =>
      throw <| IO.userError ("negative stateful defeq failed: " ++ err)
  | .ok (equal, state) =>
      expectStateful "negative stateful defeq remains false" (!equal)
      expectStateful "negative full defeq is not globally memoized"
        (state.failure.entries.size == 0 && state.success.entries.size == 0)

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

  -- Metadata is semantically transparent to inference. Its body must stay in
  -- the same stateful recursion so inner application/inference work is reused.
  let mdataInput : Expr := .mdata 17 recursiveInput
  match checkStateful recursiveCtx initial mdataInput with
  | .error err =>
      throw <| IO.userError ("mdata stateful check failed: " ++ err)
  | .ok (actual, state) =>
      expectStateful "mdata checked result" (Expr.eq actual (.sort .zero))
      expectStateful "mdata wrapper is cached"
        ((CheckerExprMap.get? state.checkedInfer mdataInput).isSome)
      expectStateful "mdata inference keeps inner application in stateful cache"
        ((CheckerExprMap.get? state.checkedInfer recursiveInput).isSome)

  IO.println "PSC1 stateful recursive checker smoke: PASS"
