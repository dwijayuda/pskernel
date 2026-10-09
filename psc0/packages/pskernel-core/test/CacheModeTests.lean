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
