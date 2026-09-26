import PSC1Kernel.CheckerStateful

namespace PSC1Kernel

/--
Stateful counterpart of Lean 4.34 `is_def_eq_args`. The order deliberately
matches the kernel: compare outer application arguments first, then walk toward
the head. Successful recursive defeq facts stay in the declaration-scoped
checker state.
-/
partial def isDefEqArgsStateful
    (ctx : CheckerContext)
    (state : CheckerState)
    (left right : Expr) : Except String (Bool × CheckerState) := do
  match left, right with
  | .app lf la, .app rf ra =>
      let (argsEq, state1) ← isDefEqStateful ctx state la ra
      if !argsEq then
        return (false, state1)
      isDefEqArgsStateful ctx state1 lf rf
  | .app _ _, _ => return (false, state)
  | _, .app _ _ => return (false, state)
  | _, _ => return (true, state)

private def lazyDeltaFinishStateful
    (ctx : CheckerContext)
    (state : CheckerState)
    (left right : Expr) : Except String (DeltaStepResult × CheckerState) := do
  match ← quickDefEq ctx left right with
  | some true => return (.equal, state)
  | some false => return (.different left right, state)
  | none => return (.continue left right, state)

private def deltaOnceStateful
    (ctx : CheckerContext)
    (state : CheckerState)
    (e : Expr) : Except String (Expr × CheckerState) := do
  let some unfolded := unfoldDefinition ctx e
    | throw "internal lazy-delta request for non-definition"
  whnfCoreStateful ctx state unfolded false true

private def tryUnfoldProjAppStateful
    (ctx : CheckerContext)
    (state : CheckerState)
    (e : Expr) : Except String (Option Expr × CheckerState) := do
  match e.getAppFn with
  | .proj _ _ _ =>
      let (reduced, state1) ← whnfCoreStateful ctx state e false false
      if Expr.eq reduced e then
        return (none, state1)
      else
        return (some reduced, state1)
  | _ => return (none, state)

/--
Pure declaration-scoped counterpart of final Lean 4.34
`type_checker::lazy_delta_reduction_step`.

The negative pair cache is intentionally narrow. It records only a failed
attempt to prove that two applications of the same regular definition have
definitionally-equal arguments. This matches the C++ `failed_before` /
`cache_failure` call site and does not memoize arbitrary negative defeq results.
-/
partial def lazyDeltaReductionStepStateful
    (ctx : CheckerContext)
    (state : CheckerState)
    (left right : Expr) : Except String (DeltaStepResult × CheckerState) := do
  match deltaDefinition? ctx left, deltaDefinition? ctx right with
  | none, none =>
      return (.unknown left right, state)
  | some _, none =>
      let (rightProj, state1) ← tryUnfoldProjAppStateful ctx state right
      match rightProj with
      | some right' => lazyDeltaFinishStateful ctx state1 left right'
      | none =>
          let (left', state2) ← deltaOnceStateful ctx state1 left
          lazyDeltaFinishStateful ctx state2 left' right
  | none, some _ =>
      let (leftProj, state1) ← tryUnfoldProjAppStateful ctx state left
      match leftProj with
      | some left' => lazyDeltaFinishStateful ctx state1 left' right
      | none =>
          let (right', state2) ← deltaOnceStateful ctx state1 right
          lazyDeltaFinishStateful ctx state2 left right'
  | some leftDef, some rightDef =>
      if leftDef.hints.lt rightDef.hints then
        let (left', state1) ← deltaOnceStateful ctx state left
        lazyDeltaFinishStateful ctx state1 left' right
      else if rightDef.hints.lt leftDef.hints then
        let (right', state1) ← deltaOnceStateful ctx state right
        lazyDeltaFinishStateful ctx state1 left right'
      else do
        let mut current := state
        if left.getAppNumArgs > 0 && right.getAppNumArgs > 0 &&
            sameDeltaDefinition leftDef rightDef &&
            leftDef.hints.isRegular &&
            appHeadLevelsEquivalent left right then
          if !CheckerExprPairSet.contains current.failure left right then
            let (argsEq, next) ← isDefEqArgsStateful ctx current left right
            current := next
            if argsEq then
              return (.equal, current)
            current := {
              current with
                failure := CheckerExprPairSet.insert current.failure left right
            }
        let (left', state1) ← deltaOnceStateful ctx current left
        let (right', state2) ← deltaOnceStateful ctx state1 right
        lazyDeltaFinishStateful ctx state2 left' right'

end PSC1Kernel
