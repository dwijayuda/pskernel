import PSC1Kernel.CheckerReductionStateful

namespace PSC1Kernel
namespace StatefulInferenceReduced

abbrev DefEqFn := CheckerContext → CheckerState → Expr → Expr →
  Except String (Bool × CheckerState)

private def cacheResult
    (state : CheckerState)
    (inferOnly : Bool)
    (e result : Expr) : CheckerState :=
  if inferOnly then
    { state with inferOnly := CheckerExprMap.insert state.inferOnly e result }
  else
    { state with checkedInfer := CheckerExprMap.insert state.checkedInfer e result }

private def ensureSort
    (defeq : DefEqFn)
    (ctx : CheckerContext)
    (state : CheckerState)
    (type : Expr) : Except String (Level × CheckerState) := do
  let (reduced, next) ← StatefulReduction.whnf defeq ctx state type
  match reduced with
  | .sort level => return (level, next)
  | _ => throw "expected sort"

/--
Stateful Lean-4.34 inference whose recursive normalization uses the same
callback-driven reduction state as definitional equality. Simple leaves still
delegate to the established checker; every recursive expression form stays in
this stateful layer.
-/
partial def inferCore
    (defeq : DefEqFn)
    (ctx : CheckerContext)
    (state : CheckerState)
    (e : Expr)
    (inferOnly : Bool) : Except String (Expr × CheckerState) := do
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
              if isEagerReduceExpr arg then { ctx with eagerReduce := true } else ctx
            let (ok, state4) ← defeq eqCtx state3 argType domain
            if !ok then throw "application type mismatch"
            let result := body.instantiate1 arg
            return (result, cacheResult state4 false e result)

      | .lam _ _ _ _ => do
          let ctx ← ctx.enterKernelRecDepth
          let rec loopLambda
              (currentCtx : CheckerContext)
              (currentState : CheckerState)
              (current : Expr)
              (fvars : List Expr)
              (binders : List CheckerCloseBinder) :
              Except String (Expr × CheckerState) := do
            match current with
            | .lam name domain body binderInfo =>
                let openedDomain := domain.instantiateRev fvars
                let state1 ←
                  if inferOnly then
                    pure currentState
                  else do
                    let (domainType, next1) ←
                      inferCore defeq currentCtx currentState openedDomain false
                    let (_, next2) ← ensureSort defeq currentCtx next1 domainType
                    pure next2
                let (fresh, state2) := state1.freshName name
                let child := {
                  currentCtx with
                    lctx := currentCtx.lctx.addLocal fresh name openedDomain binderInfo
                }
                let binder : CheckerCloseBinder := {
                  internalName := fresh
                  userName := name
                  type := openedDomain
                  binderInfo := binderInfo
                }
                loopLambda child state2 body
                  (fvars ++ [.fvar fresh]) (binders ++ [binder])
            | tail =>
                let openedTail := tail.instantiateRev fvars
                let (tailType, next) ←
                  inferCore defeq currentCtx currentState openedTail inferOnly
                let result := closeCheckerBinders binders tailType.cheapBetaReduce
                return (result, next)
          let (result, next) ← loopLambda ctx state e [] []
          return (result, cacheResult next inferOnly e result)

      | .forallE _ _ _ _ => do
          let ctx ← ctx.enterKernelRecDepth
          let rec loopForall
              (currentCtx : CheckerContext)
              (currentState : CheckerState)
              (current : Expr)
              (fvars : List Expr)
              (levels : List Level) :
              Except String (Expr × CheckerState) := do
            match current with
            | .forallE name domain body binderInfo =>
                let openedDomain := domain.instantiateRev fvars
                let (domainType, state1) ←
                  inferCore defeq currentCtx currentState openedDomain inferOnly
                let (level, state2) ← ensureSort defeq currentCtx state1 domainType
                let (fresh, state3) := state2.freshName name
                let child := {
                  currentCtx with
                    lctx := currentCtx.lctx.addLocal fresh name openedDomain binderInfo
                }
                loopForall child state3 body
                  (fvars ++ [.fvar fresh]) (levels ++ [level])
            | tail =>
                let openedTail := tail.instantiateRev fvars
                let (tailType, state1) ←
                  inferCore defeq currentCtx currentState openedTail inferOnly
                let (resultLevel, state2) ← ensureSort defeq currentCtx state1 tailType
                return (.sort (levels.foldr Level.mkIMax resultLevel), state2)
          let (result, next) ← loopForall ctx state e [] []
          return (result, cacheResult next inferOnly e result)

      | .letE _ _ _ _ _ => do
          let ctx ← ctx.enterKernelRecDepth
          let rec loopLet
              (currentCtx : CheckerContext)
              (currentState : CheckerState)
              (current : Expr)
              (fvars : List Expr)
              (binders : List CheckerCloseBinder) :
              Except String (Expr × CheckerState) := do
            match current with
            | .letE name type value body nondep =>
                let openedType := type.instantiateRev fvars
                let openedValue := value.instantiateRev fvars
                let state1 ←
                  if inferOnly then
                    pure currentState
                  else do
                    let (typeType, next1) ←
                      inferCore defeq currentCtx currentState openedType false
                    let (_, next2) ← ensureSort defeq currentCtx next1 typeType
                    let (valueType, next3) ←
                      inferCore defeq currentCtx next2 openedValue false
                    let (ok, next4) ← defeq currentCtx next3 valueType openedType
                    if !ok then throw "let value type mismatch"
                    pure next4
                let (fresh, state2) := state1.freshName name
                let child := {
                  currentCtx with
                    lctx := currentCtx.lctx.addLet fresh name openedType openedValue
                }
                let binder : CheckerCloseBinder := {
                  internalName := fresh
                  userName := name
                  type := openedType
                  binderInfo := .default
                  value? := some openedValue
                  nondep := nondep
                }
                loopLet child state2 body
                  (fvars ++ [.fvar fresh]) (binders ++ [binder])
            | tail =>
                let openedTail := tail.instantiateRev fvars
                let (tailType, next) ←
                  inferCore defeq currentCtx currentState openedTail inferOnly
                let result := closeCheckerBinders binders tailType.cheapBetaReduce true
                return (result, next)
          let (result, next) ← loopLet ctx state e [] []
          return (result, cacheResult next inferOnly e result)

      | .proj typeName idx struct => do
          let ctx ← ctx.enterKernelRecDepth
          let (structType, state1) ← inferCore defeq ctx state struct inferOnly
          let (type, state2) ← StatefulReduction.whnf defeq ctx state1 structType
          if idx > leanUInt32Max then throw "invalid projection index"
          let fn := type.getAppFn
          let args := type.getAppArgs
          let (.const inductName inductLevels) := fn
            | .error "invalid projection: projected expression type is not an inductive application"
          if !Name.eq inductName typeName then
            .error "invalid projection: structure type mismatch"
          else
            let some (.inductInfo induct) := ctx.env.find? inductName
              | .error "invalid projection: structure name is not inductive"
            match induct.ctors with
            | [ctorName] =>
              if args.length != induct.numParams + induct.numIndices then
                .error "invalid projection: inductive type is not fully applied"
              else
                let some (.ctorInfo ctor) := ctx.env.find? ctorName
                  | .error "invalid projection: constructor metadata missing"
                let r0 := ctor.base.type.instantiateLevelParams ctor.base.levelParams inductLevels
                let rec applyParams
                    (i : Nat)
                    (r : Expr)
                    (currentState : CheckerState) :
                    Except String (Expr × CheckerState) := do
                  if i < induct.numParams then
                    let (r', next) ← StatefulReduction.whnf defeq ctx currentState r
                    let .forallE _ _ body _ := r'
                      | .error "invalid projection: constructor parameter is not a forall"
                    let some arg := listGet? args i
                      | .error "invalid projection: missing structure parameter"
                    applyParams (i + 1) (body.instantiate1 arg) next
                  else
                    .ok (r, currentState)
                let (r1, state3) ← applyParams 0 r0 state2
                let isPropStateful
                    (currentState : CheckerState)
                    (term : Expr) : Except String (Bool × CheckerState) := do
                  let (termType, next1) ← inferCore defeq ctx currentState term true
                  let (level, next2) ← ensureSort defeq ctx next1 termType
                  return (Level.normalizesToZero level, next2)
                let (propType, state4) ← isPropStateful state3 type
                let rec skipFields
                    (i : Nat)
                    (r : Expr)
                    (currentState : CheckerState) :
                    Except String (Expr × CheckerState) := do
                  if i < idx then
                    let (r', next1) ← StatefulReduction.whnf defeq ctx currentState r
                    let .forallE _ domain body _ := r'
                      | .error "invalid projection index"
                    if body.hasLooseBVar then
                      if propType then
                        let (domainProp, next2) ← isPropStateful next1 domain
                        if !domainProp then
                          .error "invalid projection: proof structure depends on data field"
                        else
                          skipFields (i + 1)
                            (body.instantiate1 (.proj inductName i struct)) next2
                      else
                        skipFields (i + 1)
                          (body.instantiate1 (.proj inductName i struct)) next1
                    else
                      skipFields (i + 1) body next1
                  else
                    .ok (r, currentState)
                let (r2, state5) ← skipFields 0 r1 state4
                let (r3, state6) ← StatefulReduction.whnf defeq ctx state5 r2
                let .forallE _ domain _ _ := r3
                  | .error "invalid projection index"
                if propType then
                  let (domainProp, state7) ← isPropStateful state6 domain
                  if !domainProp then
                    .error "invalid projection: proof structure field is not a proposition"
                  else
                    return (domain, cacheResult state7 inferOnly e domain)
                else
                  return (domain, cacheResult state6 inferOnly e domain)
            | _ => .error "invalid projection: inductive must have exactly one constructor"

      | .bvar _ | .mvar _ | .fvar _ | .sort _ | .const _ _ | .lit _ =>
          -- Leaves have no recursive normalization. Reuse the established
          -- checker implementation and its exact safety/level/literal rules.
          inferCoreStatefulWith defeq ctx state e inferOnly

partial def check
    (defeq : DefEqFn)
    (ctx : CheckerContext)
    (state : CheckerState)
    (e : Expr) : Except String (Expr × CheckerState) :=
  inferCore defeq ctx state e false

partial def infer
    (defeq : DefEqFn)
    (ctx : CheckerContext)
    (state : CheckerState)
    (e : Expr) : Except String (Expr × CheckerState) :=
  inferCore defeq ctx state e true

end StatefulInferenceReduced
end PSC1Kernel
