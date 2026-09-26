import PSC1Kernel.CheckerStateful

namespace PSC1Kernel

namespace StatefulDefEq

abbrev DefEqFn :=
  CheckerContext → CheckerState → Expr → Expr →
    Except String (Bool × CheckerState)

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

private def withLocal
    (ctx : CheckerContext)
    (state : CheckerState)
    (userName : Name)
    (type : Expr)
    (binderInfo : BinderInfo) : Name × CheckerContext × CheckerState :=
  let (fresh, next) := state.freshName userName
  let lctx := ctx.lctx.addLocal fresh userName type binderInfo
  (fresh, { ctx with lctx := lctx }, next)

partial def lambdaSpine
    (defeq : DefEqFn)
    (ctx : CheckerContext)
    (state : CheckerState)
    (left right : Expr)
    (subst : List Expr := []) : Except String (Bool × CheckerState) := do
  match left, right with
  | .lam _ leftDomain leftBody _,
      .lam rightName rightDomain rightBody rightBinderInfo => do
      let leftDomain' := leftDomain.instantiateRev subst
      let rightDomain' := rightDomain.instantiateRev subst
      let mut current := state
      if !Expr.eq leftDomain rightDomain then
        let (domainsEq, next) ← defeq ctx current leftDomain' rightDomain'
        current := next
        if !domainsEq then return (false, current)
      if leftBody.hasLooseBVar || rightBody.hasLooseBVar then
        let (fresh, child, next) :=
          withLocal ctx current rightName rightDomain' rightBinderInfo
        lambdaSpine defeq child next leftBody rightBody
          (subst ++ [.fvar fresh])
      else
        lambdaSpine defeq ctx current leftBody rightBody
          (subst ++ [.sort .zero])
  | _, _ =>
      defeq ctx state
        (left.instantiateRev subst)
        (right.instantiateRev subst)

partial def forallSpine
    (defeq : DefEqFn)
    (ctx : CheckerContext)
    (state : CheckerState)
    (left right : Expr)
    (subst : List Expr := []) : Except String (Bool × CheckerState) := do
  match left, right with
  | .forallE _ leftDomain leftBody _,
      .forallE rightName rightDomain rightBody rightBinderInfo => do
      let leftDomain' := leftDomain.instantiateRev subst
      let rightDomain' := rightDomain.instantiateRev subst
      let mut current := state
      if !Expr.eq leftDomain rightDomain then
        let (domainsEq, next) ← defeq ctx current leftDomain' rightDomain'
        current := next
        if !domainsEq then return (false, current)
      if leftBody.hasLooseBVar || rightBody.hasLooseBVar then
        let (fresh, child, next) :=
          withLocal ctx current rightName rightDomain' rightBinderInfo
        forallSpine defeq child next leftBody rightBody
          (subst ++ [.fvar fresh])
      else
        forallSpine defeq ctx current leftBody rightBody
          (subst ++ [.sort .zero])
  | _, _ =>
      defeq ctx state
        (left.instantiateRev subst)
        (right.instantiateRev subst)

partial def args
    (defeq : DefEqFn)
    (ctx : CheckerContext)
    (state : CheckerState)
    (left right : Expr) : Except String (Bool × CheckerState) := do
  match left, right with
  | .app lf la, .app rf ra =>
      let (argEq, next) ← defeq ctx state la ra
      if !argEq then return (false, next)
      args defeq ctx next lf rf
  | .app _ _, _ => return (false, state)
  | _, .app _ _ => return (false, state)
  | _, _ => return (true, state)

partial def app
    (defeq : DefEqFn)
    (ctx : CheckerContext)
    (state : CheckerState)
    (left right : Expr) : Except String (Bool × CheckerState) := do
  let (headsEq, state1) ← defeq ctx state left.getAppFn right.getAppFn
  if !headsEq then return (false, state1)
  let leftArgs := left.getAppArgs
  let rightArgs := right.getAppArgs
  if leftArgs.length != rightArgs.length then
    return (false, state1)
  let rec compare
      (current : CheckerState)
      (as bs : List Expr) : Except String (Bool × CheckerState) := do
    match as, bs with
    | [], [] => return (true, current)
    | a :: as', b :: bs' =>
        let (equal, next) ← defeq ctx current a b
        if !equal then return (false, next)
        compare next as' bs'
    | _, _ => return (false, current)
  compare state1 leftArgs rightArgs

partial def quick
    (defeq : DefEqFn)
    (ctx : CheckerContext)
    (state : CheckerState)
    (left right : Expr) : Except String (Option Bool × CheckerState) := do
  if Expr.eq left right then
    return (some true, state)
  if CheckerExprPairSet.contains state.success left right then
    return (some true, state)
  match left, right with
  | .lam .., .lam .. =>
      let (value, next) ← lambdaSpine defeq ctx state left right
      return (some value, next)
  | .forallE .., .forallE .. =>
      let (value, next) ← forallSpine defeq ctx state left right
      return (some value, next)
  | .sort u, .sort v =>
      return (some (Level.equivalent u v), state)
  | .mdata _ leftBody, .mdata _ rightBody =>
      let (value, next) ← defeq ctx state leftBody rightBody
      return (some value, next)
  | .lit x, .lit y =>
      return (some (Literal.eq x y), state)
  | _, _ => return (none, state)

def unfold
    (ctx : CheckerContext)
    (state : CheckerState)
    (e : Expr) : Option Expr × CheckerState :=
  match CheckerExprMap.get? state.unfold e with
  | some cached => (some cached, state)
  | none =>
      match unfoldDefinition ctx e with
      | none => (none, state)
      | some value =>
          (some value, {
            state with unfold := CheckerExprMap.insert state.unfold e value
          })

partial def deltaOnce
    (ctx : CheckerContext)
    (state : CheckerState)
    (e : Expr) : Except String (Expr × CheckerState) := do
  let (unfolded?, state1) := unfold ctx state e
  let some unfolded := unfolded?
    | throw "internal lazy-delta request for non-definition"
  whnfCoreStateful ctx state1 unfolded false true

partial def tryUnfoldProjApp
    (ctx : CheckerContext)
    (state : CheckerState)
    (e : Expr) : Except String (Option Expr × CheckerState) := do
  match e.getAppFn with
  | .proj _ _ _ =>
      let (reduced, next) ← whnfCoreStateful ctx state e false false
      if Expr.eq reduced e then return (none, next)
      return (some reduced, next)
  | _ => return (none, state)

partial def lazyStep
    (defeq : DefEqFn)
    (ctx : CheckerContext)
    (state : CheckerState)
    (left right : Expr) : Except String (DeltaStepResult × CheckerState) := do
  let finishStep
      (current : CheckerState)
      (a b : Expr) : Except String (DeltaStepResult × CheckerState) := do
    let (quickResult, next) ← quick defeq ctx current a b
    match quickResult with
    | some true => return (.equal, next)
    | some false => return (.different a b, next)
    | none => return (.continue a b, next)

  match deltaDefinition? ctx left, deltaDefinition? ctx right with
  | none, none => return (.unknown left right, state)
  | some _, none =>
      let (rightProj, state1) ← tryUnfoldProjApp ctx state right
      match rightProj with
      | some right' => finishStep state1 left right'
      | none =>
          let (left', state2) ← deltaOnce ctx state1 left
          finishStep state2 left' right
  | none, some _ =>
      let (leftProj, state1) ← tryUnfoldProjApp ctx state left
      match leftProj with
      | some left' => finishStep state1 left' right
      | none =>
          let (right', state2) ← deltaOnce ctx state1 right
          finishStep state2 left right'
  | some leftDef, some rightDef =>
      if leftDef.hints.lt rightDef.hints then
        let (left', state1) ← deltaOnce ctx state left
        finishStep state1 left' right
      else if rightDef.hints.lt leftDef.hints then
        let (right', state1) ← deltaOnce ctx state right
        finishStep state1 left right'
      else do
        let mut current := state
        if left.getAppNumArgs > 0 && right.getAppNumArgs > 0 &&
            sameDeltaDefinition leftDef rightDef &&
            leftDef.hints.isRegular &&
            appHeadLevelsEquivalent left right then
          if !CheckerExprPairSet.contains current.failure left right then
            let (argsEq, next) ← args defeq ctx current left right
            current := next
            if argsEq then return (.equal, current)
            current := {
              current with
                failure := CheckerExprPairSet.insert current.failure left right
            }
        let (left', state1) ← deltaOnce ctx current left
        let (right', state2) ← deltaOnce ctx state1 right
        finishStep state2 left' right'

partial def lazyReduction
    (defeq : DefEqFn)
    (ctx : CheckerContext)
    (state : CheckerState)
    (left right : Expr) : Except String (DeltaResult × CheckerState) := do
  let rec loop
      (current : CheckerState)
      (a b : Expr) : Except String (DeltaResult × CheckerState) := do
    if isNatZeroExpr a && isNatZeroExpr b then
      return (.decided true, current)
    match natPredExpr? a, natPredExpr? b with
    | some pa, some pb =>
        let (value, next) ← defeq ctx current pa pb
        return (.decided value, next)
    | _, _ => pure ()

    let mut current := current
    if (!a.hasFVar && !b.hasFVar) || ctx.eagerReduce then
      let ar ← reduceNat ctx a
      match ar with
      | some value =>
          let (equal, next) ← defeq ctx current value b
          return (.decided equal, next)
      | none => pure ()
      let br ← reduceNat ctx b
      match br with
      | some value =>
          let (equal, next) ← defeq ctx current a value
          return (.decided equal, next)
      | none => pure ()

    let an ← reduceNative ctx a
    match an with
    | some value =>
        let (equal, next) ← defeq ctx current value b
        return (.decided equal, next)
    | none => pure ()
    let bn ← reduceNative ctx b
    match bn with
    | some value =>
        let (equal, next) ← defeq ctx current a value
        return (.decided equal, next)
    | none => pure ()

    let (step, next) ← lazyStep defeq ctx current a b
    match step with
    | .continue a' b' => loop next a' b'
    | .unknown a' b' => return (.residual a' b', next)
    | .equal => return (.decided true, next)
    | .different _ _ => return (.decided false, next)
  loop state left right

partial def lazyProjReduction
    (defeq : DefEqFn)
    (ctx : CheckerContext)
    (state : CheckerState)
    (left right : Expr)
    (typeName : Name)
    (index : Nat) : Except String (Bool × CheckerState) := do
  let finishProj
      (current : CheckerState)
      (a b : Expr) : Except String (Bool × CheckerState) := do
    match reduceProjCore ctx typeName index a,
          reduceProjCore ctx typeName index b with
    | some lfield, some rfield => defeq ctx current lfield rfield
    | _, _ => defeq ctx current a b
  let rec loop
      (current : CheckerState)
      (a b : Expr) : Except String (Bool × CheckerState) := do
    let (step, next) ← lazyStep defeq ctx current a b
    match step with
    | .continue a' b' => loop next a' b'
    | .equal => return (true, next)
    | .unknown a' b' => finishProj next a' b'
    | .different a' b' => finishProj next a' b'
  loop state left right

partial def isProp
    (ctx : CheckerContext)
    (state : CheckerState)
    (e : Expr) : Except String (Bool × CheckerState) := do
  let (type, state1) ← inferStateful ctx state e
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
  let (tType, state1) ← inferStateful ctx state t
  let (sType, state2) ← inferStateful ctx state1 s
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

partial def stringLitExpansionCore
    (defeq : DefEqFn)
    (ctx : CheckerContext)
    (state : CheckerState)
    (t s : Expr) : Except String (Option Bool × CheckerState) := do
  match t with
  | .lit (.str value) =>
      if isStringOfListApp s then
        let (expanded, state1) ← whnfStateful ctx state (stringLitToConstructor value)
        let (equal, state2) ← defeq ctx state1 expanded s
        return (some equal, state2)
      return (none, state)
  | _ => return (none, state)

partial def stringLitExpansion
    (defeq : DefEqFn)
    (ctx : CheckerContext)
    (state : CheckerState)
    (t s : Expr) : Except String (Option Bool × CheckerState) := do
  let (first, state1) ← stringLitExpansionCore defeq ctx state t s
  match first with
  | some value => return (some value, state1)
  | none => stringLitExpansionCore defeq ctx state1 s t

partial def unitLike
    (defeq : DefEqFn)
    (ctx : CheckerContext)
    (state : CheckerState)
    (t s : Expr) : Except String (Bool × CheckerState) := do
  let (tType0, state1) ← inferStateful ctx state t
  let (tType, state2) ← whnfStateful ctx state1 tType0
  let .const inductName _ := tType.getAppFn | return (false, state2)
  if !ctx.env.isNonRecStructure inductName then return (false, state2)
  let some (.inductInfo induct) := ctx.env.find? inductName
    | return (false, state2)
  let [ctorName] := induct.ctors | return (false, state2)
  let some (.ctorInfo ctor) := ctx.env.find? ctorName
    | return (false, state2)
  if ctor.numFields != 0 then return (false, state2)
  let (sType, state3) ← inferStateful ctx state2 s
  defeq ctx state3 tType sType

/--
Full declaration-scoped Lean-4.34-style definitional equality. The algorithmic
order is copied from the established PSC1 Lean checker; the only intended
change is that recursive infer/WHNF/delta/defeq work shares one pure
`CheckerState`.
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

  let (quickResult, state1) ← quick isDefEq ctx state a b
  match quickResult with
  | some value => return finish state1 a b value
  | none => pure ()

  -- Lean 4.34 reflection fast path.
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
  let (quickCore, state4) ← quick isDefEq ctx state3 aCore bCore
  match quickCore with
  | some value => return finish state4 a b value
  | none => pure ()

  -- Proof irrelevance precedes lazy delta.
  let (aType, state5) ← inferStateful ctx state4 aCore
  let (aIsProof, state6) ← isProp ctx state5 aType
  if aIsProof then
    let (bType, state7) ← inferStateful ctx state6 bCore
    let (equal, state8) ← isDefEq ctx state7 aType bType
    return finish state8 a b equal

  let (delta, state7) ← lazyReduction isDefEq ctx state6 aCore bCore
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
          lazyProjReduction isDefEq ctx state8 e₁ e₂ n₁ i₁
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
      let (equal, next) ← app isDefEq ctx finalState aFull bFull
      finalState := next
      if equal then return finish finalState a b true
  | .forallE .., .forallE .. =>
      let (equal, next) ← forallSpine isDefEq ctx finalState aFull bFull
      finalState := next
      if equal then return finish finalState a b true
  | .lam .., .lam .. =>
      let (equal, next) ← lambdaSpine isDefEq ctx finalState aFull bFull
      finalState := next
      if equal then return finish finalState a b true
  | .lam _ _ _ _, other =>
      let (otherType0, next1) ← inferStateful ctx finalState other
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
      let (otherType0, next1) ← inferStateful ctx finalState other
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
    stringLitExpansion isDefEq ctx state11 aFull bFull
  match stringResult with
  | some value => return finish state12 a b value
  | none => pure ()
  let (unitEqual, state13) ← unitLike isDefEq ctx state12 aFull bFull
  return finish state13 a b unitEqual

end StatefulDefEq

end PSC1Kernel
