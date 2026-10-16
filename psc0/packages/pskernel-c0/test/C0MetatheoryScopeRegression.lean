import Ps.KernelCore.Checker.Session
import Ps.KernelCore.Runtime.Acceleration.CachePolicy

/-! Regression for metatheory-discovered local FVar semantic-cache escape. -/
def main : IO Unit := do
  let source := psKernelMkCheckerSession psKernelEnvironmentEmpty []
    .safe 4096 psKernelLeanNatMaxSizeDefault
  let name : PsKernelName := .str .anonymous "scoped"
  let key : PsKernelExpr := .fvar name
  let typ : PsKernelExpr := .sort .zero
  let scopeLocal := psKernelLocalContextAddLocal
    source.context.localContext name name typ .default
  let ctx := psKernelCheckerContextWithLocalContext source.context scopeLocal
  if psKernelSemanticCacheEligible key ||
      psKernelSemanticCacheEligible (.app typ key) ||
      psKernelSemanticPairCacheEligible typ key ||
      psKernelInferCacheEligible true key then
    throw (IO.userError "semantic cache: local FVar remains eligible")
  let checked ← match psKernelCheckerCheck 4096 ctx source.state key with
    | .ok answer => pure answer
    | .error e => throw (IO.userError ("valid FVar rejected: " ++ e))
  if (psKernelExprMapGet checked.snd.checkedInfer key).isSome then
    throw (IO.userError "semantic cache: scoped type published")
  let forged := psKernelCheckerStateWithCheckedInfer source.state
    (psKernelExprMapInsert source.state.checkedInfer key typ)
  match psKernelCheckerCheck 4096 source.context forged key with
  | .ok _ => throw (IO.userError "semantic cache: foreign scope FVar accepted")
  | .error _ => pure ()
  let forgedInfer := psKernelCheckerStateWithInferOnly source.state
    (psKernelExprMapInsert source.state.inferOnly key typ)
  match psKernelCheckerInfer 4096 source.context forgedInfer key with
  | .ok _ => throw (IO.userError "semantic cache: stale infer-only accepted")
  | .error _ => pure ()
  -- Guard both the root FVar and a structurally different expression
  -- containing it. An adversarial caller may preseed a syntactically equal
  -- entry from another local scope; neither inference mode may consume it.
  let wrapped : PsKernelExpr := .mdata 83 key
  let forgedWrapped := psKernelCheckerStateWithCheckedInfer source.state
    (psKernelExprMapInsert source.state.checkedInfer wrapped typ)
  match psKernelCheckerCheck 4096 source.context forgedWrapped wrapped with
  | .ok _ => throw (IO.userError "semantic cache: wrapped foreign FVar accepted")
  | .error _ => pure ()
  let forgedWrappedInfer := psKernelCheckerStateWithInferOnly source.state
    (psKernelExprMapInsert source.state.inferOnly wrapped typ)
  match psKernelCheckerInfer 4096 source.context forgedWrappedInfer wrapped with
  | .ok _ => throw (IO.userError "semantic cache: wrapped infer-only FVar accepted")
  | .error _ => pure ()

  -- Reintroduce the same user-created name in a new scope with a different
  -- genuine type. Exact text/name equality alone cannot determine the
  -- correct result. Both modes must consult the local-context declaration.
  let newer : PsKernelExpr := .sort (.succ .zero)
  let shadowLocals := psKernelLocalContextAddLocal scopeLocal
    name name newer .default
  let shadowCtx := psKernelCheckerContextWithLocalContext ctx shadowLocals
  match psKernelCheckerCheck 4096 shadowCtx forged key with
  | .ok (ty, _) =>
      if !psKernelExprEq ty newer then
        throw (IO.userError "semantic cache: shadowed FVar type poisoned")
  | .error e => throw (IO.userError ("shadowed FVar wrongly rejected: " ++ e))
  match psKernelCheckerInfer 4096 shadowCtx forgedInfer key with
  | .ok (ty, _) =>
      if !psKernelExprEq ty newer then
        throw (IO.userError "semantic cache: shadowed inferred type poisoned")
  | .error e => throw (IO.userError ("shadowed infer-only FVar rejected: " ++ e))

  -- A forged POSITIVE DefEq pair involving a local FVar must not turn
  -- two unknown, distinct variables into an equality verdict. Both the raw
  -- pair and an enclosing metadata pair exercise the source quick-cache
  -- guard and the recursive metadata checker, respectively.
  let foreignName : PsKernelName := .str .anonymous "foreignScoped"
  let foreignKey : PsKernelExpr := .fvar foreignName
  let poisonedSuccess := psKernelCheckerStateWithSuccess source.state
    (psKernelExprPairSetInsert source.state.success key foreignKey)
  match psKernelIsDefEq 4096 source.context poisonedSuccess key foreignKey with
  | .ok (true, _) =>
      throw (IO.userError "semantic cache: forged cross-scope DefEq accepted")
  | _ => pure ()
  let wrappedForeign : PsKernelExpr := .mdata 83 foreignKey
  let poisonedNestedSuccess := psKernelCheckerStateWithSuccess source.state
    (psKernelExprPairSetInsert source.state.success wrapped wrappedForeign)
  match psKernelIsDefEq 4096 source.context
      poisonedNestedSuccess wrapped wrappedForeign with
  | .ok (true, _) =>
      throw (IO.userError "semantic cache: wrapped forged DefEq accepted")
  | _ => pure ()

  -- Exit scope must restore ALL five expression caches and both DefEq
  -- verdict sets, not merely the positive cache exercised by the original
  -- metatheory counterexample. Only nextFresh may advance monotonically.
  let child := {checked.snd with
    nextFresh := checked.snd.nextFresh + 3
    inferOnly := psKernelExprMapInsert checked.snd.inferOnly key typ
    checkedInfer := psKernelExprMapInsert checked.snd.checkedInfer key typ
    whnfCore := psKernelExprMapInsert checked.snd.whnfCore key typ
    whnf := psKernelExprMapInsert checked.snd.whnf key typ
    unfold := psKernelExprMapInsert checked.snd.unfold key typ
    success := psKernelExprPairSetInsert checked.snd.success key typ
    failure := psKernelExprPairSetInsert checked.snd.failure key typ }
  let restored := psKernelCheckerStateExitLocalScope source.state child
  if restored.nextFresh != child.nextFresh ||
      (psKernelExprMapGet restored.inferOnly key).isSome ||
      (psKernelExprMapGet restored.checkedInfer key).isSome ||
      (psKernelExprMapGet restored.whnfCore key).isSome ||
      (psKernelExprMapGet restored.whnf key).isSome ||
      (psKernelExprMapGet restored.unfold key).isSome ||
      psKernelExprPairSetContains restored.success key typ ||
      psKernelExprPairSetContains restored.failure key typ then
    throw (IO.userError "semantic cache: binder state leaked")
  IO.println "C0_METATHEORY_SCOPE fvar_keys=blocked wrapped_foreign=error shadowed_types=correct forged_defeq=blocked all_seven_caches=restored monotone_fresh=pass"
