import PSC1Kernel.CheckerStateful

namespace PSC1Kernel
namespace StatefulReduction

abbrev DefEqFn := CheckerContext → CheckerState → Expr → Expr →
  Except String (Bool × CheckerState)

abbrev WhnfFn := CheckerContext → CheckerState → Expr →
  Except String (Expr × CheckerState)

abbrev WhnfCoreFn := CheckerContext → CheckerState → Expr → Bool → Bool →
  Except String (Expr × CheckerState)

abbrev InferFn := CheckerContext → CheckerState → Expr →
  Except String (Expr × CheckerState)

/-- Stateful counterpart of Quot recursor reduction. -/
partial def reduceQuot
    (publicWhnf : WhnfFn)
    (ctx : CheckerContext)
    (state : CheckerState)
    (e : Expr) : Except String (Option Expr × CheckerState) := do
  if !ctx.env.quotInitialized then
    return (none, state)
  let .const fnName _ := e.getAppFn | return (none, state)
  let isLift := Name.eq fnName kernelQuotLiftName
  let isInd := Name.eq fnName kernelQuotIndName
  if !isLift && !isInd then
    return (none, state)
  let mkPos : Nat := if isLift then 5 else 4
  let argPos : Nat := 3
  let args := e.getAppArgs
  if args.length <= mkPos then
    return (none, state)
  let some major := listGet? args mkPos | return (none, state)
  let (major', state1) ← publicWhnf ctx state major
  let .const mkName _ := major'.getAppFn | return (none, state1)
  if !Name.eq mkName kernelQuotMkName || major'.getAppNumArgs != 3 then
    return (none, state1)
  let mkArgs := major'.getAppArgs
  let some representative := listGet? mkArgs 2 | return (none, state1)
  let some f := listGet? args argPos | return (none, state1)
  let base := Expr.app f representative
  let elimArity := mkPos + 1
  return (some (applyArgs base (args.drop elimArity)), state1)

partial def toConstructorWhenK
    (publicWhnf : WhnfFn)
    (inferType : InferFn)
    (defeq : DefEqFn)
    (ctx : CheckerContext)
    (state : CheckerState)
    (recursor : RecursorInfo)
    (major : Expr) : Except String (Expr × CheckerState) := do
  let some majorInduct := recursorMajorInduct? recursor
    | return (major, state)
  let (majorType, state1) ← inferType ctx state major
  let (appType, state2) ← publicWhnf ctx state1 majorType
  let .const typeInduct typeLevels := appType.getAppFn
    | return (major, state2)
  if !Name.eq typeInduct majorInduct then
    return (major, state2)

  if exprHasMVarForK appType then
    let indices := appType.getAppArgs.drop recursor.numParams
    if indices.any exprHasMVarForK then
      return (major, state2)

  let some (.inductInfo induct) := ctx.env.find? typeInduct
    | return (major, state2)
  let ctorName :: _ := induct.ctors
    | return (major, state2)
  let params := appType.getAppArgs.take recursor.numParams
  if params.length != recursor.numParams then
    return (major, state2)
  let candidate := applyArgs (.const ctorName typeLevels) params
  let (candidateType, state3) ← inferType ctx state2 candidate
  let (equal, state4) ← defeq ctx state3 appType candidateType
  if !equal then
    return (major, state4)
  return (candidate, state4)

partial def isProp
    (publicWhnf : WhnfFn)
    (inferType : InferFn)
    (ctx : CheckerContext)
    (state : CheckerState)
    (e : Expr) : Except String (Bool × CheckerState) := do
  let (type, state1) ← inferType ctx state e
  let (reduced, state2) ← publicWhnf ctx state1 type
  match reduced with
  | .sort level => return (Level.normalizesToZero level, state2)
  | _ => throw "expected sort"

partial def toConstructorWhenStructure
    (publicWhnf : WhnfFn)
    (inferType : InferFn)
    (ctx : CheckerContext)
    (state : CheckerState)
    (recursor : RecursorInfo)
    (major : Expr) : Except String (Expr × CheckerState) := do
  if isConstructorApp ctx.env major then
    return (major, state)
  let some inductName := recursorMajorInduct? recursor
    | return (major, state)
  if !ctx.env.isNonRecStructure inductName then
    return (major, state)
  let (majorType0, state1) ← inferType ctx state major
  let (majorType, state2) ← publicWhnf ctx state1 majorType0
  let .const typeName levels := majorType.getAppFn
    | return (major, state2)
  if !Name.eq typeName inductName then
    return (major, state2)
  let (propType, state3) ← isProp publicWhnf inferType ctx state2 majorType
  if propType then
    return (major, state3)
  let some (.inductInfo induct) := ctx.env.find? inductName
    | return (major, state3)
  let [ctorName] := induct.ctors
    | return (major, state3)
  let some (.ctorInfo ctor) := ctx.env.find? ctorName
    | return (major, state3)
  let args := majorType.getAppArgs
  if args.length < ctor.numParams then
    return (major, state3)
  let params := args.take ctor.numParams
  let rec fields (i : Nat) : List Expr :=
    if _h : i < ctor.numFields then
      .proj inductName i major :: fields (i + 1)
    else
      []
  return (applyArgs (.const ctorName levels) (params ++ fields 0), state3)

partial def reduceInductiveRec
    (publicWhnf : WhnfFn)
    (coreWhnf : WhnfCoreFn)
    (inferType : InferFn)
    (defeq : DefEqFn)
    (ctx : CheckerContext)
    (state : CheckerState)
    (e : Expr)
    (cheapRec cheapProj : Bool) :
    Except String (Option Expr × CheckerState) := do
  let .const recName recLevels := e.getAppFn | return (none, state)
  let some (.recInfo recursor) := ctx.env.find? recName | return (none, state)
  let recArgs := e.getAppArgs
  let majorIdx :=
    recursor.numParams + recursor.numMotives +
      recursor.numMinors + recursor.numIndices
  if majorIdx >= recArgs.length then
    return (none, state)
  let some major0 := listGet? recArgs majorIdx | return (none, state)
  let (majorK, state1) ←
    if recursor.k then
      toConstructorWhenK publicWhnf inferType defeq ctx state recursor major0
    else
      pure (major0, state)
  let (majorReduced, state2) ←
    if cheapRec then
      coreWhnf ctx state1 majorK cheapRec cheapProj
    else
      publicWhnf ctx state1 majorK
  let (major, state3) ←
    match majorReduced with
    | .lit (.nat 0) =>
        pure (Expr.const kernelNatZeroName [], state2)
    | .lit (.nat (n + 1)) =>
        pure (Expr.app (Expr.const kernelNatSuccName []) (.lit (.nat n)), state2)
    | .lit (.str value) =>
        publicWhnf ctx state2 (stringLitToConstructor value)
    | _ =>
        toConstructorWhenStructure publicWhnf inferType ctx state2 recursor majorReduced
  let .const ctorName _ := major.getAppFn | return (none, state3)
  let some rule := findRecursorRule ctorName recursor.rules | return (none, state3)
  let majorArgs := major.getAppArgs
  if rule.nFields > majorArgs.length then
    return (none, state3)
  if recLevels.length != recursor.base.levelParams.length then
    return (none, state3)
  let rhs0 := rule.rhs.instantiateLevelParams recursor.base.levelParams recLevels
  let fixedCount :=
    recursor.numParams + recursor.numMotives + recursor.numMinors
  let rhs1 := applyArgs rhs0 (recArgs.take fixedCount)
  let ctorParamCount := majorArgs.length - rule.nFields
  let rhs2 := applyArgs rhs1 ((majorArgs.drop ctorParamCount).take rule.nFields)
  return (some (applyArgs rhs2 (recArgs.drop (majorIdx + 1))), state3)

partial def reduceRecursor
    (publicWhnf : WhnfFn)
    (coreWhnf : WhnfCoreFn)
    (inferType : InferFn)
    (defeq : DefEqFn)
    (ctx : CheckerContext)
    (state : CheckerState)
    (e : Expr)
    (cheapRec cheapProj : Bool) :
    Except String (Option Expr × CheckerState) := do
  let (quot, state1) ← reduceQuot publicWhnf ctx state e
  match quot with
  | some value => return (some value, state1)
  | none =>
      reduceInductiveRec publicWhnf coreWhnf inferType defeq
        ctx state1 e cheapRec cheapProj

/-- Stateful Nat reduction: operand WHNF uses the same checker state. -/
partial def reduceNat
    (publicWhnf : WhnfFn)
    (ctx : CheckerContext)
    (state : CheckerState)
    (e : Expr) : Except String (Option Expr × CheckerState) :=
  match e with
  | .app (.const name levels) arg =>
    if levels.length == 0 && Name.eq name kernelNatSuccName then do
      let (arg', state1) ← publicWhnf ctx state arg
      match natLiteralValue? arg' with
      | some value => do
          let result := value + 1
          checkNatSize ctx.maxNatSize result
          return (some (.lit (.nat result)), state1)
      | none => return (none, state1)
    else
      .ok (none, state)
  | .app (.app (.const name levels) left) right =>
    if levels.length == 0 then do
      let (left', state1) ← publicWhnf ctx state left
      let (right', state2) ← publicWhnf ctx state1 right
      match natLiteralValue? left', natLiteralValue? right' with
      | some a, some b =>
          match reduceNatBinary ctx.maxNatSize name a b with
          | .ok result => .ok (result, state2)
          | .error err => .error err
      | _, _ => .ok (none, state2)
    else
      .ok (none, state)
  | _ => .ok (none, state)

/--
WHNF-core using the same declaration-scoped state for recursor/Quot reduction.
The callback parameter breaks the ordinary public-WHNF/core-WHNF recursion in
exactly the same way as Lean4Lean's `Methods` record.
-/
partial def whnfCoreWith
    (publicWhnf : WhnfFn)
    (defeq : DefEqFn)
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
      return ← whnfCoreWith publicWhnf defeq ctx state body cheapRec cheapProj
  | .fvar name =>
      match ctx.lctx.find? name with
      | some decl =>
          match decl.value? with
          | some value =>
              return ← whnfCoreWith publicWhnf defeq ctx state value cheapRec cheapProj
          | none => return (e, state)
      | none => return (e, state)
  | .app _ _ | .letE _ _ _ _ _ | .proj _ _ _ => pure ()

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
        whnfCoreWith publicWhnf defeq ctx state
          (body.instantiate1 value) cheapRec cheapProj
      save result next
  | .proj typeName idx struct => do
      let (struct', state1) ←
        if cheapProj then
          whnfCoreWith publicWhnf defeq ctx state struct cheapRec cheapProj
        else
          publicWhnf ctx state struct
      let (struct'', state2) ←
        match struct' with
        | .lit (.str value) => publicWhnf ctx state1 (stringLitToConstructor value)
        | _ => pure (struct', state1)
      match reduceProjCore ctx typeName idx struct'' with
      | some value => do
          let (result, state3) ←
            whnfCoreWith publicWhnf defeq ctx state2 value cheapRec cheapProj
          save result state3
      | none => save e state2
  | .app _ _ => do
      let fn0 := e.getAppFn
      let args := e.getAppArgs
      let (fn, state1) ←
        whnfCoreWith publicWhnf defeq ctx state fn0 cheapRec cheapProj
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
          let .lam _ _ body _ := lastLam | return (e, state1)
          let reducedBody := body.instantiateRev (args.take consumed)
          let reduced := Expr.applyArgsCheap reducedBody (args.drop consumed)
          let (result, state2) ←
            whnfCoreWith publicWhnf defeq ctx state1 reduced cheapRec cheapProj
          save result state2
      | _ =>
          if Expr.eq fn fn0 then
            let coreWhnf : WhnfCoreFn :=
              fun c s x cr cp => whnfCoreWith publicWhnf defeq c s x cr cp
            let inferType : InferFn :=
              fun c s x => inferStatefulWith defeq c s x
            let (reduced, state2) ←
              reduceRecursor publicWhnf coreWhnf inferType defeq
                ctx state1 e cheapRec cheapProj
            match reduced with
            | some value =>
                whnfCoreWith publicWhnf defeq ctx state2 value cheapRec cheapProj
            | none => pure (e, state2)
          else
            let rebuilt := Expr.applyArgsCheap fn args
            let (result, state2) ←
              whnfCoreWith publicWhnf defeq ctx state1 rebuilt cheapRec cheapProj
            save result state2
  | .bvar _ | .sort _ | .mvar _ | .forallE _ _ _ _
  | .const _ _ | .lam _ _ _ _ | .lit _ | .mdata _ _ | .fvar _ => unreachable!

/--
Public WHNF whose Nat/Quot/inductive-rec reduction stays inside CheckerState.
`defeq` is injected so callers such as the closed recursive checker can keep the
same equality algorithm all the way through K reduction.
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
    let (core, state1) ← whnfCoreWith publicWhnf defeq ctx current t false false
    let native ← reduceNative ctx core
    match native with
    | some value => return (value, state1)
    | none => pure ()
    let (nat, state2) ← reduceNat publicWhnf ctx state1 core
    match nat with
    | some value => return (value, state2)
    | none =>
        match unfoldDefinition ctx core with
        | some value => loop value state2
        | none => return (core, state2)

  let (result, next) ← loop e state
  return (result, { next with whnf := CheckerExprMap.insert next.whnf e result })

partial def whnfCore
    (defeq : DefEqFn)
    (ctx : CheckerContext)
    (state : CheckerState)
    (e : Expr)
    (cheapRec cheapProj : Bool) : Except String (Expr × CheckerState) :=
  whnfCoreWith (whnf defeq) defeq ctx state e cheapRec cheapProj

end StatefulReduction
end PSC1Kernel
