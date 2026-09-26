import PSC1Kernel.CheckerDefEqStateful

namespace PSC1Kernel

namespace StatefulDefEqClosed

abbrev DefEqFn := StatefulDefEq.DefEqFn

private def finish
    (state : CheckerState)
    (left right : Expr)
    (value : Bool) : Bool × CheckerState :=
  if value then
    (true, {
      state with success := CheckerExprPairSet.insert state.success left right
    })
  else
    (false, state)

partial def isProp
    (defeq : DefEqFn)
    (ctx : CheckerContext)
    (state : CheckerState)
    (e : Expr) : Except String (Bool × CheckerState) := do
  let (type, state1) ← inferStatefulWith defeq ctx state e
  let (reduced, state2) ← whnfStateful ctx state1 type
  match reduced with
  | .sort level => return (Level.normalizesToZero level, state2)
  | _ => throw "expected sort"

partial def etaStructCore
    (defeq : DefEqFn)
    (ctx : CheckerContext)
    (state : CheckerState)
    (t s : Expr) : Except String (Bool × CheckerState) := do
  let fn := s.getAppFn
  let args := s.getAppArgs
  let .const ctorName _ := fn | return (false, state)
  let some (.ctorInfo ctor) := ctx.env.find? ctorName | return (false, state)
  if args.length != ctor.numParams + ctor.numFields then return (false, state)
  if !ctx.env.isNonRecStructure ctor.induct then return (false, state)
  let (tType, state1) ← inferStatefulWith defeq ctx state t
  let (sType, state2) ← inferStatefulWith defeq ctx state1 s
  let (typesEq, state3) ← defeq ctx state2 tType sType
  if !typesEq then return (false, state3)
  let rec loop
      (current : CheckerState)
      (i : Nat) : Except String (Bool × CheckerState) := do
    if i < ctor.numFields then
      let some arg := listGet? args (ctor.numParams + i)
        | return (false, current)
      let (equal, next) ← defeq ctx current (.proj ctor.induct i t) arg
      if !equal then return (false, next)
      loop next (i + 1)
    else
      return (true, current)
  loop state3 0

partial def etaStruct
    (defeq : DefEqFn)
    (ctx : CheckerContext)
    (state : CheckerState)
    (t s : Expr) : Except String (Bool × CheckerState) := do
  let (first, state1) ← etaStructCore defeq ctx state t s
  if first then return (true, state1)
  etaStructCore defeq ctx state1 s t

partial def unitLike
    (defeq : DefEqFn)
    (ctx : CheckerContext)
    (state : CheckerState)
    (t s : Expr) : Except String (Bool × CheckerState) := do
  let (tType0, state1) ← inferStatefulWith defeq ctx state t
  let (tType, state2) ← whnfStateful ctx state1 tType0
  let .const inductName _ := tType.getAppFn | return (false, state2)
  if !ctx.env.isNonRecStructure inductName then return (false, state2)
  let some (.inductInfo induct) := ctx.env.find? inductName
    | return (false, state2)
  let [ctorName] := induct.ctors | return (false, state2)
  let some (.ctorInfo ctor) := ctx.env.find? ctorName
    | return (false, state2)
  if ctor.numFields != 0 then return (false, state2)
  let (sType, state3) ← inferStatefulWith defeq ctx state2 s
  defeq ctx state3 tType sType

/--
Experimental closed recursive checker loop. Unlike the compatibility path, every
inference request made from definitional equality receives this same recursive
defeq callback, so checked application inference cannot fall back to the old
outer positive-cache wrapper.
-/
partial def isDefEq
    (ctx : CheckerContext)
    (state : CheckerState)
    (a b : Expr) : Except String (Bool × CheckerState) := do
  let ctx ← ctx.enterKernelRecDepth

  if Expr.eq a b then
    return finish state a b true
  if CheckerExprPairSet.contains state.success a b then
    return (true, state)

  let (quickResult, state1) ← StatefulDefEq.quick isDefEq ctx state a b
  match quickResult with
  | some value => return finish state1 a b value
  | none => pure ()

  let mut current := state1
  if !a.hasFVar || ctx.eagerReduce then
    match b with
    | .const name levels =>
        if levels.length == 0 && Name.eq name kernelBoolTrueName then
          let (reduced, next) ← whnfStateful ctx current a
          current := next
          match reduced with
          | .const reducedName reducedLevels =>
              if reducedLevels.length == 0 &&
                  Name.eq reducedName kernelBoolTrueName then
                return finish current a b true
          | _ => pure ()
    | _ => pure ()

  let (aCore, state2) ← whnfCoreStateful ctx current a false true
  let (bCore, state3) ← whnfCoreStateful ctx state2 b false true
  let (quickCore, state4) ← StatefulDefEq.quick isDefEq ctx state3 aCore bCore
  match quickCore with
  | some value => return finish state4 a b value
  | none => pure ()

  let (aType, state5) ← inferStatefulWith isDefEq ctx state4 aCore
  let (aIsProof, state6) ← isProp isDefEq ctx state5 aType
  if aIsProof then
    let (bType, state7) ← inferStatefulWith isDefEq ctx state6 bCore
    let (equal, state8) ← isDefEq ctx state7 aType bType
    return finish state8 a b equal

  let (delta, state7) ← StatefulDefEq.lazyReduction isDefEq ctx state6 aCore bCore
  let (aDelta, bDelta, state8) ←
    match delta with
    | .decided value => return finish state7 a b value
    | .residual left right => pure (left, right, state7)

  match aDelta, bDelta with
  | .const n₁ ls₁, .const n₂ ls₂ =>
      if Name.eq n₁ n₂ && levelListsEquivalent ls₁ ls₂ then
        return finish state8 a b true
  | .fvar n₁, .fvar n₂ =>
      if Name.eq n₁ n₂ then return finish state8 a b true
  | .proj n₁ i₁ e₁, .proj n₂ i₂ e₂ =>
      if Name.eq n₁ n₂ && i₁ == i₂ then
        let (equal, next) ←
          StatefulDefEq.lazyProjReduction isDefEq ctx state8 e₁ e₂ n₁ i₁
        if equal then return finish next a b true
  | _, _ => pure ()

  let (aFull, state9) ← whnfCoreStateful ctx state8 aDelta false false
  let (bFull, state10) ← whnfCoreStateful ctx state9 bDelta false false
  if !Expr.eq aFull aDelta || !Expr.eq bFull bDelta then
    let (equal, next) ← isDefEq ctx state10 aFull bFull
    return finish next a b equal

  let mut finalState := state10
  match aFull, bFull with
  | .sort u, .sort v =>
      return finish finalState a b (Level.equivalent u v)
  | .lit x, .lit y =>
      return finish finalState a b (Literal.eq x y)
  | .app _ _, .app _ _ =>
      let (equal, next) ← StatefulDefEq.app isDefEq ctx finalState aFull bFull
      finalState := next
      if equal then return finish finalState a b true
  | .forallE .., .forallE .. =>
      let (equal, next) ← StatefulDefEq.forallSpine isDefEq ctx finalState aFull bFull
      finalState := next
      if equal then return finish finalState a b true
  | .lam .., .lam .. =>
      let (equal, next) ← StatefulDefEq.lambdaSpine isDefEq ctx finalState aFull bFull
      finalState := next
      if equal then return finish finalState a b true
  | .lam _ _ _ _, other =>
      let (otherType0, next1) ← inferStatefulWith isDefEq ctx finalState other
      let (otherType, next2) ← whnfStateful ctx next1 otherType0
      finalState := next2
      match otherType with
      | .forallE name domain _ binderInfo =>
          let eta := .lam name domain (.app other (.bvar 0)) binderInfo
          let (equal, next3) ← isDefEq ctx finalState aFull eta
          finalState := next3
          if equal then return finish finalState a b true
      | _ => pure ()
  | other, .lam _ _ _ _ =>
      let (otherType0, next1) ← inferStatefulWith isDefEq ctx finalState other
      let (otherType, next2) ← whnfStateful ctx next1 otherType0
      finalState := next2
      match otherType with
      | .forallE name domain _ binderInfo =>
          let eta := .lam name domain (.app other (.bvar 0)) binderInfo
          let (equal, next3) ← isDefEq ctx finalState eta bFull
          finalState := next3
          if equal then return finish finalState a b true
      | _ => pure ()
  | _, _ => pure ()

  let (etaEqual, state11) ← etaStruct isDefEq ctx finalState aFull bFull
  if etaEqual then return finish state11 a b true
  let (stringResult, state12) ←
    StatefulDefEq.stringLitExpansion isDefEq ctx state11 aFull bFull
  match stringResult with
  | some value => return finish state12 a b value
  | none => pure ()
  let (unitEqual, state13) ← unitLike isDefEq ctx state12 aFull bFull
  return finish state13 a b unitEqual

end StatefulDefEqClosed

end PSC1Kernel
