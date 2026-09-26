import PSC1Kernel.CheckerReductionStateful

namespace PSC1Kernel
namespace StatefulInferenceReduced

abbrev DefEqFn := StatefulReduction.DefEqFn

private def cacheResult
    (state : CheckerState)
    (inferOnly : Bool)
    (e result : Expr) : CheckerState :=
  if inferOnly then
    { state with inferOnly := CheckerExprMap.insert state.inferOnly e result }
  else
    { state with checkedInfer := CheckerExprMap.insert state.checkedInfer e result }

/--
Application-focused stateful inference whose normalization method is the same
stateful reduction layer used by recursive defeq. Non-application forms retain
the proven `CheckerStateful` implementation while this closes the hot
inference → WHNF → recursor state escape.
-/
partial def inferCore
    (defeq : DefEqFn)
    (ctx : CheckerContext)
    (state : CheckerState)
    (e : Expr)
    (inferOnly : Bool) : Except String (Expr × CheckerState) :=
  let cache := if inferOnly then state.inferOnly else state.checkedInfer
  match CheckerExprMap.get? cache e with
  | some cached => do
      let _ctx ← ctx.enterKernelRecDepth
      return (cached, state)
  | none =>
      match e with
      | .mdata _ body => do
          let ctx ← ctx.enterKernelRecDepth
          let (result, next) ← inferCore defeq ctx state body inferOnly
          return (result, cacheResult next inferOnly e result)

      | .app fn arg =>
          if inferOnly then do
            let ctx ← ctx.enterKernelRecDepth
            let args := e.getAppArgs
            let (fnType, state1) ← inferCore defeq ctx state e.getAppFn true
            let rec loopApp
                (i j : Nat)
                (current : Expr)
                (currentState : CheckerState) :
                Except String (Expr × CheckerState) := do
              if i < args.length then
                match current with
                | .forallE _ _ body _ =>
                    loopApp (i + 1) j body currentState
                | _ =>
                    let pending := (args.drop j).take (i - j)
                    let exposed := current.instantiateRev pending
                    let (exposedWhnf, next) ←
                      StatefulReduction.whnf defeq ctx currentState exposed
                    let .forallE _ _ body _ := exposedWhnf
                      | throw "expected function type"
                    loopApp (i + 1) i body next
              else
                let result := current.instantiateRev (args.drop j)
                return (result, cacheResult currentState true e result)
            loopApp 0 0 fnType state1
          else do
            let ctx ← ctx.enterKernelRecDepth
            let (fnType, state1) ← inferCore defeq ctx state fn false
            let (fnTypeWhnf, state2) ←
              StatefulReduction.whnf defeq ctx state1 fnType
            let .forallE _ domain body _ := fnTypeWhnf
              | throw "expected function type"
            let (argType, state3) ← inferCore defeq ctx state2 arg false
            let eqCtx :=
              if isEagerReduceExpr arg then
                { ctx with eagerReduce := true }
              else
                ctx
            let (ok, state4) ← defeq eqCtx state3 argType domain
            if !ok then throw "application type mismatch"
            let result := body.instantiate1 arg
            return (result, cacheResult state4 false e result)

      | _ =>
          inferCoreStatefulWith defeq ctx state e inferOnly

/-- Checked inference using one stateful reduction method on application paths. -/
def checkStateful
    (defeq : DefEqFn)
    (ctx : CheckerContext)
    (state : CheckerState)
    (e : Expr) : Except String (Expr × CheckerState) :=
  inferCore defeq ctx state e false

/-- Infer-only operation using one stateful reduction method on application paths. -/
def inferStateful
    (defeq : DefEqFn)
    (ctx : CheckerContext)
    (state : CheckerState)
    (e : Expr) : Except String (Expr × CheckerState) :=
  inferCore defeq ctx state e true

end StatefulInferenceReduced
end PSC1Kernel
