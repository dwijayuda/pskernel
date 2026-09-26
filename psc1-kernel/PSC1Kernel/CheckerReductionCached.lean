import PSC1Kernel.CheckerReductionStateful

namespace PSC1Kernel
namespace StatefulReductionCached

abbrev DefEqFn := StatefulReduction.DefEqFn
abbrev WhnfFn := StatefulReduction.WhnfFn

/--
Lean 4.34 caches the universe-instantiated value of a delta-reducible constant,
not the whole applied expression. Zero-universe constants skip this cache because
there is no level substitution work to reuse.
-/
def unfoldDefinitionCoreStateful
    (ctx : CheckerContext)
    (state : CheckerState)
    (e : Expr) : Except String (Option Expr × CheckerState) := do
  let .const name levels := e | return (none, state)
  let some info := ctx.env.find? name | return (none, state)
  let some value := info.deltaValue? | return (none, state)
  if info.levelParams.length != levels.length then
    return (none, state)
  if levels.length == 0 then
    return (some value, state)
  match CheckerExprMap.get? state.unfold e with
  | some cached => return (some cached, state)
  | none =>
      let result := value.instantiateLevelParams info.levelParams levels
      return (some result, {
        state with unfold := CheckerExprMap.insert state.unfold e result
      })

/-- Unfold the head constant and reapply term arguments outside the head cache. -/
def unfoldDefinitionStateful
    (ctx : CheckerContext)
    (state : CheckerState)
    (e : Expr) : Except String (Option Expr × CheckerState) := do
  let fn := e.getAppFn
  let args := e.getAppArgs
  let (head?, next) ← unfoldDefinitionCoreStateful ctx state fn
  match head? with
  | some head => return (some (applyArgs head args), next)
  | none => return (none, next)

/--
Public WHNF with the same recursive reducer as `StatefulReduction.whnf`, plus
Lean-4.34-faithful memoization of universe-instantiated delta heads.
-/
partial def whnf
    (defeq : DefEqFn)
    (ctx : CheckerContext)
    (state : CheckerState)
    (e : Expr) : Except String (Expr × CheckerState) := do
  match e with
  | .bvar _ | .sort _ | .mvar _ | .forallE _ _ _ _ | .lit _ =>
      return (e, state)
  | .mdata _ body => return ← whnf defeq ctx state body
  | .fvar name =>
      match ctx.lctx.find? name with
      | some decl => if decl.value?.isNone then return (e, state)
      | none => return (e, state)
  | .lam _ _ _ _ | .app _ _ | .const _ _ | .letE _ _ _ _ _ | .proj _ _ _ => pure ()

  match CheckerExprMap.get? state.whnf e with
  | some cached => return (cached, state)
  | none => pure ()

  let rec loop
      (t : Expr)
      (current : CheckerState) : Except String (Expr × CheckerState) := do
    let publicWhnf : WhnfFn := fun c s x => whnf defeq c s x
    let (core, state1) ←
      StatefulReduction.whnfCoreWith publicWhnf defeq ctx current t false false
    let native ← reduceNative ctx core
    match native with
    | some value => return (value, state1)
    | none => pure ()
    let (nat, state2) ← StatefulReduction.reduceNat publicWhnf ctx state1 core
    match nat with
    | some value => return (value, state2)
    | none =>
        let (unfolded, state3) ← unfoldDefinitionStateful ctx state2 core
        match unfolded with
        | some value => loop value state3
        | none => return (core, state3)

  let (result, next) ← loop e state
  return (result, { next with whnf := CheckerExprMap.insert next.whnf e result })

partial def whnfCore
    (defeq : DefEqFn)
    (ctx : CheckerContext)
    (state : CheckerState)
    (e : Expr)
    (cheapRec cheapProj : Bool) : Except String (Expr × CheckerState) :=
  StatefulReduction.whnfCoreWith (whnf defeq) defeq ctx state e cheapRec cheapProj

end StatefulReductionCached
end PSC1Kernel
