import PSC1Kernel

open PSC1Kernel

def expectDefEqCache (label : String) (ok : Bool) : IO Unit :=
  if ok then pure ()
  else throw <| IO.userError ("checker defeq cache smoke failed: " ++ label)

def main : IO Unit := do
  let env := Environment.empty
  let left : Expr := .sort .zero
  let right : Expr := .sort (.succ .zero)
  let lctx := LocalContext.empty

  expectDefEqCache "initial success miss"
    (!checkerDefEqSuccessCached env lctx 0 leanNatMaxSizeDefault true left right)
  let storedSuccess :=
    checkerDefEqCacheSuccessResult
      env lctx 0 leanNatMaxSizeDefault true left right true
  expectDefEqCache "success identity" storedSuccess
  expectDefEqCache "success hit is symmetric"
    (checkerDefEqSuccessCached env lctx 0 leanNatMaxSizeDefault true right left)

  let x : Name := .str .anonymous "x"
  let lctxA := lctx.addLocal x x (.sort .zero) .default
  let lctxB := lctx.addLocal x x (.sort (.succ .zero)) .default
  let fvar : Expr := .fvar x
  let target : Expr := .sort .zero
  let storedLocalSuccess := checkerDefEqCacheSuccessResult
    env lctxA 0 leanNatMaxSizeDefault true fvar target true
  expectDefEqCache "local success identity" storedLocalSuccess
  expectDefEqCache "same local context hits"
    (checkerDefEqSuccessCached env lctxA 0 leanNatMaxSizeDefault true fvar target)
  expectDefEqCache "different local type does not alias"
    (!checkerDefEqSuccessCached env lctxB 0 leanNatMaxSizeDefault true fvar target)

  let env2 := { env with quotInitialized := true }
  expectDefEqCache "different environment does not alias"
    (!checkerDefEqSuccessCached env2 lctxA 0 leanNatMaxSizeDefault true fvar target)

  let storedConfiguredSuccess := checkerDefEqCacheSuccessResult
    env lctx 17 leanNatMaxSizeDefault true left target true
  expectDefEqCache "configured success identity" storedConfiguredSuccess
  expectDefEqCache "different recursion configuration does not alias"
    (!checkerDefEqSuccessCached env lctx 18 leanNatMaxSizeDefault true left target)

  let failed := checkerDefEqCacheFailureResult
    env lctx 0 leanNatMaxSizeDefault true left right false
  expectDefEqCache "failure identity" (!failed)
  expectDefEqCache "failure hit is symmetric"
    (checkerDefEqFailureCached env lctx 0 leanNatMaxSizeDefault true right left)
  expectDefEqCache "success/failure maps stay separate"
    (!checkerDefEqSuccessCached env lctx 0 leanNatMaxSizeDefault true left right)

  expectDefEqCache "disabled cache never hits"
    (!checkerDefEqFailureCached env lctx 0 leanNatMaxSizeDefault false left right)

  IO.println "PSC1 native defeq cache isolation smoke: PASS"
