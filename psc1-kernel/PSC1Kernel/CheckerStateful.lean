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

partial def whnfCoreStateful
    (ctx : CheckerContext)
    (state : CheckerState)
    (e : Expr)
    (cheapRec cheapProj : Bool) : Except String (Expr × CheckerState) :=
  whnfCoreStatefulWith whnfStateful ctx state e cheapRec cheapProj

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
Incremental stateful counterpart of Lean 4.34 `infer_type_core` with an explicit
definitional-equality callback. Cache hits and migrated misses enter the same
kernel recursion boundary as final Lean 4.34. Non-migrated misses still defer
to the established pure checker until their stateful equivalents are added.
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
      | .app fn arg => do
          let ctx ← ctx.enterKernelRecDepth
          if inferOnly then
            let appFn := e.getAppFn
            let args := e.getAppArgs
            let (fnType, state1) ← inferCoreStatefulWith defeq ctx state appFn true
            let rec loop
                (fType : Expr)
                (j i : Nat)
                (current : CheckerState) : Except String (Expr × CheckerState) := do
              if i < args.length then
                match fType with
                | .forallE _ _ body _ =>
                    loop body j (i + 1) current
                | _ => do
                    let pending := (args.drop j).take (i - j)
                    let exposedInput := fType.instantiateRev pending
                    let (exposed, next) ← whnfStateful ctx current exposedInput
                    let .forallE _ _ body _ := exposed
                      | throw "expected function type"
                    loop body i (i + 1) next
              else
                return (fType.instantiateRev (args.drop j), current)
            let (result, next) ← loop fnType 0 0 state1
            return (result, cacheInferStatefulResult next true e result)
          else
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
      | _ =>
          match inferCore ctx e inferOnly with
          | .error err => .error err
          | .ok result =>
              .ok (result, cacheInferStatefulResult state inferOnly e result)

partial def inferCoreStateful
    (ctx : CheckerContext)
    (state : CheckerState)
    (e : Expr)
    (inferOnly : Bool) : Except String (Expr × CheckerState) :=
  inferCoreStatefulWith isDefEqStateful ctx state e inferOnly

def checkStatefulWith
    (defeq : CheckerContext → CheckerState → Expr → Expr →
      Except String (Bool × CheckerState))
    (ctx : CheckerContext)
    (state : CheckerState)
    (e : Expr) : Except String (Expr × CheckerState) :=
  inferCoreStatefulWith defeq ctx state e false

def inferStatefulWith
    (defeq : CheckerContext → CheckerState → Expr → Expr →
      Except String (Bool × CheckerState))
    (ctx : CheckerContext)
    (state : CheckerState)
    (e : Expr) : Except String (Expr × CheckerState) :=
  inferCoreStatefulWith defeq ctx state e true

def checkStateful
    (ctx : CheckerContext)
    (state : CheckerState)
    (e : Expr) : Except String (Expr × CheckerState) :=
  checkStatefulWith isDefEqStateful ctx state e

def inferStateful
    (ctx : CheckerContext)
    (state : CheckerState)
    (e : Expr) : Except String (Expr × CheckerState) :=
  inferStatefulWith isDefEqStateful ctx state e

end PSC1Kernel
