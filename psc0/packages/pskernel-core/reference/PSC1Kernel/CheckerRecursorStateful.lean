import PSC1Kernel.CheckerState
import PSC1Kernel.TypeChecker

namespace PSC1Kernel

/--
Recursor-local infer cache adapter. It preserves the established pure inference
algorithm on a miss, but unlike the old recursor fallback it threads the result
through the declaration-scoped checker state so repeated K/structure probes can
reuse it.
-/
partial def inferRecursorCached
    (ctx : CheckerContext)
    (state : CheckerState)
    (e : Expr) : Except String (Expr × CheckerState) := do
  match CheckerExprMap.get? state.inferOnly e with
  | some cached =>
      let _ctx ← ctx.enterKernelRecDepth
      return (cached, state)
  | none =>
      let result ← infer ctx e
      return (result, {
        state with inferOnly := CheckerExprMap.insert state.inferOnly e result
      })

/-- Positive-only defeq cache adapter used by K conversion. -/
partial def isDefEqRecursorCached
    (ctx : CheckerContext)
    (state : CheckerState)
    (left right : Expr) : Except String (Bool × CheckerState) := do
  if CheckerExprPairSet.contains state.success left right then
    let _ctx ← ctx.enterKernelRecDepth
    return (true, state)
  let ok ← isDefEq ctx left right
  if ok then
    return (true, {
      state with success := CheckerExprPairSet.insert state.success left right
    })
  else
    return (false, state)

partial def isPropRecursorCachedWith
    (publicWhnf : CheckerContext → CheckerState → Expr →
      Except String (Expr × CheckerState))
    (ctx : CheckerContext)
    (state : CheckerState)
    (e : Expr) : Except String (Bool × CheckerState) := do
  let (type, state1) ← inferRecursorCached ctx state e
  let (reduced, state2) ← publicWhnf ctx state1 type
  match reduced with
  | .sort level => return (Level.normalizesToZero level, state2)
  | _ => throw "expected sort"

partial def toConstructorWhenKStatefulWith
    (publicWhnf : CheckerContext → CheckerState → Expr →
      Except String (Expr × CheckerState))
    (ctx : CheckerContext)
    (state : CheckerState)
    (recursor : RecursorInfo)
    (major : Expr) : Except String (Expr × CheckerState) := do
  let some majorInduct := recursorMajorInduct? recursor
    | return (major, state)
  let (majorType0, state1) ← inferRecursorCached ctx state major
  let (appType, state2) ← publicWhnf ctx state1 majorType0
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
  let (candidateType, state3) ← inferRecursorCached ctx state2 candidate
  let (ok, state4) ← isDefEqRecursorCached ctx state3 appType candidateType
  if !ok then
    return (major, state4)
  return (candidate, state4)

partial def toConstructorWhenStructureStatefulWith
    (publicWhnf : CheckerContext → CheckerState → Expr →
      Except String (Expr × CheckerState))
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
  let (majorType0, state1) ← inferRecursorCached ctx state major
  let (majorType, state2) ← publicWhnf ctx state1 majorType0
  let .const typeName levels := majorType.getAppFn
    | return (major, state2)
  if !Name.eq typeName inductName then
    return (major, state2)
  let (propType, state3) ←
    isPropRecursorCachedWith publicWhnf ctx state2 majorType
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
    if h : i < ctor.numFields then
      .proj inductName i major :: fields (i + 1)
    else
      []
  return (applyArgs (.const ctorName levels) (params ++ fields 0), state3)

partial def reduceQuotRecStatefulWith
    (publicWhnf : CheckerContext → CheckerState → Expr →
      Except String (Expr × CheckerState))
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

partial def reduceInductiveRecStatefulWith
    (publicWhnf : CheckerContext → CheckerState → Expr →
      Except String (Expr × CheckerState))
    (coreWhnf : CheckerContext → CheckerState → Expr →
      Except String (Expr × CheckerState))
    (ctx : CheckerContext)
    (state : CheckerState)
    (e : Expr)
    (cheapRec : Bool) : Except String (Option Expr × CheckerState) := do
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
      toConstructorWhenKStatefulWith publicWhnf ctx state recursor major0
    else
      pure (major0, state)
  let (majorReduced, state2) ←
    if cheapRec then coreWhnf ctx state1 majorK
    else publicWhnf ctx state1 majorK
  let (major, state3) ←
    match majorReduced with
    | .lit (.nat 0) =>
        pure (Expr.const kernelNatZeroName [], state2)
    | .lit (.nat (n + 1)) =>
        pure (Expr.app (Expr.const kernelNatSuccName []) (.lit (.nat n)), state2)
    | .lit (.str value) =>
        publicWhnf ctx state2 (stringLitToConstructor value)
    | _ =>
        toConstructorWhenStructureStatefulWith
          publicWhnf ctx state2 recursor majorReduced
  let .const ctorName _ := major.getAppFn | return (none, state3)
  let some rule := findRecursorRule ctorName recursor.rules
    | return (none, state3)
  let majorArgs := major.getAppArgs
  if rule.nFields > majorArgs.length then
    return (none, state3)
  if recLevels.length != recursor.base.levelParams.length then
    return (none, state3)
  let rhs0 :=
    rule.rhs.instantiateLevelParams recursor.base.levelParams recLevels
  let fixedCount :=
    recursor.numParams + recursor.numMotives + recursor.numMinors
  let rhs1 := applyArgs rhs0 (recArgs.take fixedCount)
  let ctorParamCount := majorArgs.length - rule.nFields
  let rhs2 :=
    applyArgs rhs1 ((majorArgs.drop ctorParamCount).take rule.nFields)
  return (some (applyArgs rhs2 (recArgs.drop (majorIdx + 1))), state3)

/--
State-threaded counterpart of the kernel recursor hook. Reduction ordering and
K/structure conditions are unchanged; only the checker callbacks now preserve
and consult the declaration-scoped memo state.
-/
partial def reduceRecursorStatefulWith
    (publicWhnf : CheckerContext → CheckerState → Expr →
      Except String (Expr × CheckerState))
    (coreWhnf : CheckerContext → CheckerState → Expr →
      Except String (Expr × CheckerState))
    (ctx : CheckerContext)
    (state : CheckerState)
    (e : Expr)
    (cheapRec : Bool) : Except String (Option Expr × CheckerState) := do
  let (quot, state1) ← reduceQuotRecStatefulWith publicWhnf ctx state e
  match quot with
  | some value => return (some value, state1)
  | none =>
      reduceInductiveRecStatefulWith
        publicWhnf coreWhnf ctx state1 e cheapRec

end PSC1Kernel
