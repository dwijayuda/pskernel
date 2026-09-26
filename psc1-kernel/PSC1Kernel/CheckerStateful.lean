import PSC1Kernel.CheckerState
import PSC1Kernel.TypeChecker

namespace PSC1Kernel

/--
Pure declaration-scoped stateful counterpart of the recursive checker layer.
The established TypeChecker remains the semantic reference; this module adds
Lean-4.34-style memo state without process-global mutation.
-/
partial def whnfCoreStatefulWith
    (publicWhnf : CheckerContext → CheckerState → Expr →
      Except String (Expr × CheckerState))
    (ctx : CheckerContext)
    (state : CheckerState)
    (e : Expr)
    (cheapRec cheapProj : Bool) : Except String (Expr × CheckerState) := do
  let ctx ← ctx.enterKernelRecDepth
  -- Match Lean/Lean4Lean: easy cases and metadata/let-FVar forwarding do not
  -- create entries under the outer expression.
  match e with
  | .bvar _ | .sort _ | .mvar _ | .forallE _ _ _ _
  | .const _ _ | .lam _ _ _ _ | .lit _ =>
      return (e, state)
  | .mdata _ body =>
      return ← whnfCoreStatefulWith publicWhnf ctx state body cheapRec cheapProj
  | .fvar name =>
      match ctx.lctx.find? name with
      | some decl =>
          match decl.value? with
          | some value =>
              return ← whnfCoreStatefulWith publicWhnf ctx state value cheapRec cheapProj
          | none => return (e, state)
      | none => return (e, state)
  | .app _ _ | .letE _ _ _ _ _ | .proj _ _ _ =>
      pure ()

  match CheckerExprMap.get? state.whnfCore e with
  | some cached => return (cached, state)
  | none => pure ()

  let save (result : Expr) (next : CheckerState) :
      Except String (Expr × CheckerState) :=
    if cheapProj then
      .ok (result, next)
    else
      .ok (result, {
        next with whnfCore := CheckerExprMap.insert next.whnfCore e result
      })

  match e with
  | .letE _ _ value body _ => do
      let (result, next) ←
        whnfCoreStatefulWith publicWhnf ctx state
          (body.instantiate1 value) cheapRec cheapProj
      save result next
  | .proj typeName idx struct => do
      let (struct', state1) ←
        if cheapProj then
          whnfCoreStatefulWith publicWhnf ctx state struct cheapRec cheapProj
        else
          publicWhnf ctx state struct
      let (struct'', state2) ←
        match struct' with
        | .lit (.str value) =>
            publicWhnf ctx state1 (stringLitToConstructor value)
        | _ => pure (struct', state1)
      match reduceProjCore ctx typeName idx struct'' with
      | some value => do
          let (result, state3) ←
            whnfCoreStatefulWith publicWhnf ctx state2 value cheapRec cheapProj
          save result state3
      | none => save e state2
  | .app _ _ => do
      let fn0 := e.getAppFn
      let args := e.getAppArgs
      let (fn, state1) ←
        whnfCoreStatefulWith publicWhnf ctx state fn0 cheapRec cheapProj
      match fn with
      | .lam _ _ _ _ =>
          let rec countLambdas (current : Expr) (count : Nat) : Expr × Nat :=
            match current with
            | .lam _ _ body _ =>
                if count < args.length then
                  if count + 1 < args.length then
                    match body with
                    | .lam _ _ _ _ => countLambdas body (count + 1)
                    | _ => (current, count + 1)
                  else
                    (current, count + 1)
                else
                  (current, count)
            | _ => (current, count)
          let (lastLam, consumed) := countLambdas fn 0
          let .lam _ _ body _ := lastLam
            | return (e, state1)
          let reducedBody := body.instantiateRev (args.take consumed)
          let reduced := Expr.applyArgsCheap reducedBody (args.drop consumed)
          let (result, state2) ←
            whnfCoreStatefulWith publicWhnf ctx state1 reduced cheapRec cheapProj
          save result state2
      | _ =>
          if Expr.eq fn fn0 then
            let reduced ← reduceRecursor ctx e cheapRec cheapProj
            match reduced with
            | some value =>
                -- Lean4Lean does not save the original recursor application
                -- here; recursive normalization owns any cache entries.
                whnfCoreStatefulWith publicWhnf ctx state1 value cheapRec cheapProj
            | none => pure (e, state1)
          else
            let rebuilt := Expr.applyArgsCheap fn args
            let (result, state2) ←
              whnfCoreStatefulWith publicWhnf ctx state1 rebuilt cheapRec cheapProj
            save result state2
  | .bvar _ | .sort _ | .mvar _ | .forallE _ _ _ _
  | .const _ _ | .lam _ _ _ _ | .lit _ | .mdata _ _ | .fvar _ =>
      unreachable!

partial def whnfStateful
    (ctx : CheckerContext)
    (state : CheckerState)
    (e : Expr) : Except String (Expr × CheckerState) := do
  -- Match the public Lean checker: trivial WHNF cases are not cached.
  match e with
  | .bvar _ | .sort _ | .mvar _ | .forallE _ _ _ _ | .lit _ =>
      return (e, state)
  | .mdata _ body =>
      return ← whnfStateful ctx state body
  | .fvar name =>
      match ctx.lctx.find? name with
      | some decl =>
          if decl.value?.isNone then return (e, state)
      | none => return (e, state)
  | .lam _ _ _ _ | .app _ _ | .const _ _ | .letE _ _ _ _ _ | .proj _ _ _ =>
      pure ()

  match CheckerExprMap.get? state.whnf e with
  | some cached => return (cached, state)
  | none => pure ()

  let rec loop
      (t : Expr)
      (current : CheckerState) : Except String (Expr × CheckerState) := do
    let (core, state1) ←
      whnfCoreStatefulWith whnfStateful ctx current t false false
    let native ← reduceNative ctx core
    match native with
    | some value => return (value, state1)
    | none => pure ()
    let nat ← reduceNat ctx core
    match nat with
    | some value => return (value, state1)
    | none =>
        match unfoldDefinition ctx core with
        | some value => loop value state1
        | none => return (core, state1)

  let (result, next) ← loop e state
  let next := {
    next with whnf := CheckerExprMap.insert next.whnf e result
  }
  pure (result, next)

/-- Stateful WHNF-core entry point with the public-WHNF callback fixed. -/
partial def whnfCoreStateful
    (ctx : CheckerContext)
    (state : CheckerState)
    (e : Expr)
    (cheapRec cheapProj : Bool) : Except String (Expr × CheckerState) :=
  whnfCoreStatefulWith whnfStateful ctx state e cheapRec cheapProj

/--
Declaration-scoped positive definitional-equality memoization. Successful pairs
are reusable throughout one immutable checker environment and the pair set is
symmetric. Arbitrary negative full-defeq results are intentionally not cached:
Lean 4.34's failure table is narrower and belongs at the lazy-delta argument
comparison site.

This compatibility wrapper remains for incremental callers. Fully migrated
callers inject `StatefulDefEq.isDefEq` through `inferCoreStatefulWith` instead.
-/
partial def isDefEqStateful
    (ctx : CheckerContext)
    (state : CheckerState)
    (a b : Expr) : Except String (Bool × CheckerState) := do
  if CheckerExprPairSet.contains state.success a b then
    let _ctx ← ctx.enterKernelRecDepth
    return (true, state)
  let result ← isDefEq ctx a b
  if result then
    return (true, {
      state with success := CheckerExprPairSet.insert state.success a b
    })
  else
    return (false, state)

private def cacheInferStatefulResult
    (state : CheckerState)
    (inferOnly : Bool)
    (e result : Expr) : CheckerState :=
  if inferOnly then
    { state with inferOnly := CheckerExprMap.insert state.inferOnly e result }
  else
    { state with checkedInfer := CheckerExprMap.insert state.checkedInfer e result }

private def ensureSortStatefulResult
    (ctx : CheckerContext)
    (state : CheckerState)
    (type : Expr) : Except String (Level × CheckerState) := do
  let (reduced, next) ← whnfStateful ctx state type
  match reduced with
  | .sort level => return (level, next)
  | _ => throw "expected sort"

/--
Incremental stateful counterpart of Lean 4.34 `infer_type_core` with an explicit
definitional-equality callback. The migrated application and binder paths share
one declaration-scoped state through recursive inference, WHNF, and defeq.
Non-migrated misses still delegate to the established pure semantic checker.
-/
partial def inferCoreStatefulWith
    (defeq : CheckerContext → CheckerState → Expr → Expr →
      Except String (Bool × CheckerState))
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
      | .app fn arg =>
          if inferOnly then do
            -- Lean 4.34 infer_app: infer the flattened function head through
            -- the shared state, consume syntactically visible Pi binders, and
            -- instantiate delayed argument slices only when a hidden Pi must
            -- be exposed. Infer-only mode deliberately does not check args.
            let ctx ← ctx.enterKernelRecDepth
            let args := e.getAppArgs
            let (fnType, state1) ←
              inferCoreStatefulWith defeq ctx state e.getAppFn true
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
                      whnfStateful ctx currentState exposed
                    let .forallE _ _ body _ := exposedWhnf
                      | throw "expected function type"
                    loopApp (i + 1) i body next
              else
                let result := current.instantiateRev (args.drop j)
                return (result, cacheInferStatefulResult currentState true e result)
            loopApp 0 0 fnType state1
          else do
            let ctx ← ctx.enterKernelRecDepth
            let (fnType, state1) ← inferCoreStatefulWith defeq ctx state fn false
            let (fnTypeWhnf, state2) ← whnfStateful ctx state1 fnType
            let .forallE _ domain body _ := fnTypeWhnf
              | throw "expected function type"
            let (argType, state3) ← inferCoreStatefulWith defeq ctx state2 arg false
            let eqCtx :=
              if isEagerReduceExpr arg then
                { ctx with eagerReduce := true }
              else
                ctx
            let (ok, state4) ← defeq eqCtx state3 argType domain
            if !ok then
              throw "application type mismatch"
            let result := body.instantiate1 arg
            return (result, cacheInferStatefulResult state4 false e result)

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
                      inferCoreStatefulWith defeq currentCtx currentState openedDomain false
                    let (_, next2) ←
                      ensureSortStatefulResult currentCtx next1 domainType
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
                  inferCoreStatefulWith defeq currentCtx currentState openedTail inferOnly
                let result := closeCheckerBinders binders tailType.cheapBetaReduce
                return (result, next)
          let (result, next) ← loopLambda ctx state e [] []
          return (result, cacheInferStatefulResult next inferOnly e result)

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
                  inferCoreStatefulWith defeq currentCtx currentState openedDomain inferOnly
                let (level, state2) ←
                  ensureSortStatefulResult currentCtx state1 domainType
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
                  inferCoreStatefulWith defeq currentCtx currentState openedTail inferOnly
                let (resultLevel, state2) ←
                  ensureSortStatefulResult currentCtx state1 tailType
                return (.sort (levels.foldr Level.mkIMax resultLevel), state2)
          let (result, next) ← loopForall ctx state e [] []
          return (result, cacheInferStatefulResult next inferOnly e result)

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
                      inferCoreStatefulWith defeq currentCtx currentState openedType false
                    let (_, next2) ←
                      ensureSortStatefulResult currentCtx next1 typeType
                    let (valueType, next3) ←
                      inferCoreStatefulWith defeq currentCtx next2 openedValue false
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
                  inferCoreStatefulWith defeq currentCtx currentState openedTail inferOnly
                let result := closeCheckerBinders binders tailType.cheapBetaReduce true
                return (result, next)
          let (result, next) ← loopLet ctx state e [] []
          return (result, cacheInferStatefulResult next inferOnly e result)

      | _ =>
          -- Non-migrated forms retain the proven pure resource accounting.
          match inferCore ctx e inferOnly with
          | .error err => .error err
          | .ok result =>
              .ok (result, cacheInferStatefulResult state inferOnly e result)

/-- Compatibility stateful inference using the older positive-cache wrapper. -/
partial def inferCoreStateful
    (ctx : CheckerContext)
    (state : CheckerState)
    (e : Expr)
    (inferOnly : Bool) : Except String (Expr × CheckerState) :=
  inferCoreStatefulWith isDefEqStateful ctx state e inferOnly

/-- Stateful checked-inference entry point with an injected defeq algorithm. -/
def checkStatefulWith
    (defeq : CheckerContext → CheckerState → Expr → Expr →
      Except String (Bool × CheckerState))
    (ctx : CheckerContext)
    (state : CheckerState)
    (e : Expr) : Except String (Expr × CheckerState) :=
  inferCoreStatefulWith defeq ctx state e false

/-- Stateful infer-only entry point with an injected defeq algorithm. -/
def inferStatefulWith
    (defeq : CheckerContext → CheckerState → Expr → Expr →
      Except String (Bool × CheckerState))
    (ctx : CheckerContext)
    (state : CheckerState)
    (e : Expr) : Except String (Expr × CheckerState) :=
  inferCoreStatefulWith defeq ctx state e true

/-- Compatibility checked-inference entry point. -/
def checkStateful
    (ctx : CheckerContext)
    (state : CheckerState)
    (e : Expr) : Except String (Expr × CheckerState) :=
  checkStatefulWith isDefEqStateful ctx state e

/-- Compatibility infer-only entry point with a cache separate from checked inference. -/
def inferStateful
    (ctx : CheckerContext)
    (state : CheckerState)
    (e : Expr) : Except String (Expr × CheckerState) :=
  inferStatefulWith isDefEqStateful ctx state e

end PSC1Kernel
