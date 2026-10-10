import Ps.KernelCore.API.Kernel

-- A cheap recursor result must not populate the full core-WHNF cache.
-- The callback isolates cache-mode behavior without depending on a recursor
-- declaration's admission or on the particular primitive being reduced.
def main : IO Unit := do
  let name := PsKernelName.str .anonymous "cacheFixture"
  let input := PsKernelExpr.letE name (.sort .zero) (.sort .zero)
    (.app (.const name []) (.bvar 0)) false
  let stuck := PsKernelExpr.app (.const name []) (.sort .zero)
  let reduced := PsKernelExpr.sort (.succ .zero)
  let ctx := psKernelCheckerContextEmpty psKernelEnvironmentEmpty
  let identityWhnf := fun (_ : PsKernelCheckerContext) (s : PsKernelCheckerState)
      (e : PsKernelExpr) => Except.ok (e, s)
  let reduce := fun (_ : PsKernelCheckerContext) (s : PsKernelCheckerState)
      (e : PsKernelExpr) (cheapRec _cheapProj : Bool) =>
    Except.ok (if cheapRec then none else if psKernelExprEq e stuck then some reduced else none, s)
  let cheap ← match psKernelWhnfCoreWithFuel 32 identityWhnf reduce
      ctx psKernelCheckerStateEmpty input true false with
    | .error e => throw (IO.userError e)
    | .ok pair => pure pair
  unless psKernelExprEq cheap.1 stuck do
    throw (IO.userError "cheap recursor fixture reduced unexpectedly")
  match psKernelExprMapGet cheap.2.whnfCore input with
  | .some _ => throw (IO.userError "cheap recursor result polluted full WHNF cache")
  | .none => pure ()
  let full ← match psKernelWhnfCoreWithFuel 32 identityWhnf reduce ctx cheap.2 input false false with
    | .error e => throw (IO.userError e)
    | .ok pair => pure pair
  unless psKernelExprEq full.1 reduced do
    throw (IO.userError "full recursor reduction reused a cheap result")
  IO.println "PSKERNEL_WHNF_CACHE_MODES: PASS"
  -- Forty shared app layers contain over a trillion tree nodes, but selecting
  -- one lambda must inspect only the lambda spine, never its type/body.
  let dag := (List.range 40).foldl (fun e _ => PsKernelExpr.app e e) (.sort .zero)
  let lambda := PsKernelExpr.lam .anonymous dag dag .default
  let counted := psKernelWhnfCountLambdas lambda 1
  unless counted.2 == 1 do
    throw (IO.userError "lambda spine consumed the wrong number of arguments")
  IO.println "PSKERNEL_LAMBDA_SPINE_BOUND: PASS"

  let indexed := { psKernelCheckerStateEmpty with
    success := { small := [], index := some PsKernelExprPairSetIndex.empty } }
  if psKernelDefEqSuccessCacheHit indexed dag (.sort .zero) then
    throw (IO.userError "ineligible key unexpectedly hit empty cache")
  match psKernelIsDefEqWithFuel 1 ctx indexed (.fvar name) dag with
  | .error _ => pure ()
  | .ok _ => throw (IO.userError "zero remaining reduction fuel unexpectedly succeeded")
  IO.println "PSKERNEL_BOUNDED_SUCCESS_LOOKUP: PASS"

  -- Cache an open reduction, then leave its scope and reuse the same raw name
  -- for a different let. The second scope must not inherit the first result.
  let parent := psKernelCheckerStateEmpty
  let firstLocal := psKernelCheckerContextWithLet ctx name (.sort (.succ .zero)) (.sort .zero)
  let openExpr := PsKernelExpr.app
    (.lam .anonymous (.sort (.succ .zero)) (.bvar 0) .default)
    (.fvar firstLocal.1)
  let first ← match psKernelWhnfNoRecursor 32 firstLocal.2 parent openExpr with
    | .error e => throw (IO.userError e)
    | .ok pair => pure pair
  unless psKernelExprEq first.1 (.sort .zero) do
    throw (IO.userError "open reduction produced the wrong first result")
  match psKernelExprMapGet first.2.whnf openExpr with
  | .none => throw (IO.userError "open reduction was not memoized")
  | .some cached =>
    unless psKernelExprEq cached first.1 do
      throw (IO.userError "open reduction cache contains the wrong result")
  -- One unit of WHNF fuel is sufficient only because this lookup is cached.
  match psKernelWhnfNoRecursor 1 firstLocal.2 first.2 openExpr with
  | .error e => throw (IO.userError ("open cache lookup failed: " ++ e))
  | .ok pair =>
    unless psKernelExprEq pair.1 first.1 do
      throw (IO.userError "open cache lookup changed the result")
  let restored := psKernelCheckerStateExitLocalScope parent first.2
  match psKernelExprMapGet restored.whnf openExpr with
  | .some _ => throw (IO.userError "child reduction cache escaped its local scope")
  | .none => pure ()
  let secondLocal := psKernelCheckerContextWithLet ctx name (.sort (.succ (.succ .zero))) (.sort (.succ .zero))
  match psKernelWhnfNoRecursor 32 secondLocal.2 restored openExpr with
  | .error e => throw (IO.userError e)
  | .ok pair =>
    unless psKernelExprEq pair.1 (.sort (.succ .zero)) do
      throw (IO.userError "second local scope reused the first scope's result")
  if psKernelWhnfCacheEligible dag then
    throw (IO.userError "giant reduction cache key escaped the node bound")
  IO.println "PSKERNEL_OPEN_WHNF_SCOPE: PASS"

  let inferred ← match psKernelCheckerInfer 64 firstLocal.2 parent (.fvar firstLocal.1) with
    | .error e => throw (IO.userError e)
    | .ok pair => pure pair
  match psKernelExprMapGet inferred.2.inferOnly (.fvar firstLocal.1) with
  | .none => throw (IO.userError "local inference result was not cached")
  | .some cached =>
    unless psKernelExprEq cached (.sort (.succ .zero)) do
      throw (IO.userError "local inference cached the wrong type")
  let equalityState := (psKernelDefEqFinish inferred.2 (.fvar firstLocal.1) (.sort .zero) true).2
  unless psKernelExprPairSetContains equalityState.success (.fvar firstLocal.1) (.sort .zero) do
    throw (IO.userError "open equality result was not cached")
  let restoredAll := psKernelCheckerStateExitLocalScope parent equalityState
  if psKernelExprPairSetContains restoredAll.success (.fvar firstLocal.1) (.sort .zero) then
    throw (IO.userError "child equality cache escaped its scope")
  match psKernelCheckerInfer 64 secondLocal.2 restoredAll (.fvar firstLocal.1) with
  | .error e => throw (IO.userError e)
  | .ok pair =>
    unless psKernelExprEq pair.1 (.sort (.succ (.succ .zero))) do
      throw (IO.userError "second scope reused the first local's type")
  match psKernelIsDefEq 64 secondLocal.2 restoredAll (.fvar firstLocal.1) (.sort .zero) with
  | .error e => throw (IO.userError e)
  | .ok pair =>
    if pair.1 then
      throw (IO.userError "second scope reused the first local's equality")
  IO.println "PSKERNEL_OPEN_INFERENCE_EQUALITY_SCOPE: PASS"
