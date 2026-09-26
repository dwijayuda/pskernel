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

Lean enters the kernel recursion-depth scope before its success-cache quick
path. A cache hit therefore still performs that resource-boundary check. On a
miss the established `isDefEq` implementation performs the check itself.
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

/--
Incremental stateful counterpart of Lean 4.34 `infer_type_core`.

Final Lean 4.34 enters `scope_rec_depth` before the infer-cache lookup. During
this incremental migration, cache hits and the custom checked-application path
therefore enter the PSC1 recursion guard explicitly. Non-migrated misses still
delegate to the established pure `inferCore`, which already enters that guard;
charging them here as well would incorrectly double-count recursion depth.
-/
partial def inferCoreStateful
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
          if inferOnly then
            -- This branch is not migrated yet. Pure `inferCore` owns exactly
            -- one recursion-depth scope, matching the C++ miss path.
            match inferCore ctx e true with
            | .error err => .error err
            | .ok result =>
                .ok (result, cacheInferStatefulResult state true e result)
          else do
            -- This branch replaces pure `inferCore`, so it must own the one
            -- `scope_rec_depth` that Lean C++ charges before recursive work.
            let ctx ← ctx.enterKernelRecDepth
            let (fnType, state1) ← inferCoreStateful ctx state fn false
            let (fnTypeWhnf, state2) ← whnfStateful ctx state1 fnType
            let .forallE _ domain body _ := fnTypeWhnf
              | throw "expected function type"
            let (argType, state3) ← inferCoreStateful ctx state2 arg false
            let eqCtx :=
              if isEagerReduceExpr arg then
                { ctx with eagerReduce := true }
              else
                ctx
            let (ok, state4) ← isDefEqStateful eqCtx state3 argType domain
            if !ok then
              throw "application type mismatch"
            let result := body.instantiate1 arg
            return (result, cacheInferStatefulResult state4 false e result)
      | _ =>
          -- Non-migrated forms retain the proven pure resource accounting.
          match inferCore ctx e inferOnly with
          | .error err => .error err
          | .ok result =>
              .ok (result, cacheInferStatefulResult state inferOnly e result)

/-- Stateful checked-inference entry point. -/
def checkStateful
    (ctx : CheckerContext)
    (state : CheckerState)
    (e : Expr) : Except String (Expr × CheckerState) :=
  inferCoreStateful ctx state e false

/-- Stateful infer-only entry point with a cache separate from checked inference. -/
def inferStateful
    (ctx : CheckerContext)
    (state : CheckerState)
    (e : Expr) : Except String (Expr × CheckerState) :=
  inferCoreStateful ctx state e true

end PSC1Kernel
