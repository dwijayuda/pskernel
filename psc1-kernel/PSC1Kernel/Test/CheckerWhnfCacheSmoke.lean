import PSC1Kernel.CheckerWhnfCacheRuntime

open PSC1Kernel

def expectWhnfCache (label : String) (ok : Bool) : IO Unit :=
  if ok then pure ()
  else throw <| IO.userError ("checker WHNF cache smoke failed: " ++ label)

def main : IO Unit := do
  let env := Environment.empty
  let lctx := LocalContext.empty
  let closed : Expr := .app (.lam (.str .anonymous "x") (.sort .zero) (.bvar 0) .default) (.sort .zero)
  let closedResult : Expr := .sort .zero

  expectWhnfCache "initial WHNF miss"
    ((checkerWhnfCached env lctx 0 leanNatMaxSizeDefault true closed).isNone)
  let stored := checkerWhnfCacheResult
    env lctx 0 leanNatMaxSizeDefault true closed closedResult
  expectWhnfCache "WHNF store is identity" (Expr.eq stored closedResult)
  expectWhnfCache "WHNF hit"
    (match checkerWhnfCached env lctx 0 leanNatMaxSizeDefault true closed with
     | some value => Expr.eq value closedResult
     | none => false)

  let x : Name := .str .anonymous "x"
  let lctxA := lctx.addLocal x x (.sort .zero) .default
  let lctxB := lctx.addLocal x x (.sort (.succ .zero)) .default
  let openExpr : Expr := .fvar x
  let openResult : Expr := .sort .zero
  let storedOpen := checkerWhnfCacheResult
    env lctxA 0 leanNatMaxSizeDefault true openExpr openResult
  expectWhnfCache "open WHNF store is identity" (Expr.eq storedOpen openResult)
  expectWhnfCache "same local context hits"
    ((checkerWhnfCached env lctxA 0 leanNatMaxSizeDefault true openExpr).isSome)
  expectWhnfCache "different local context does not alias"
    ((checkerWhnfCached env lctxB 0 leanNatMaxSizeDefault true openExpr).isNone)

  let lctxC := lctx.addLocal (.str .anonymous "unused") (.str .anonymous "unused") (.sort (.succ .zero)) .default
  expectWhnfCache "closed WHNF reuses across local contexts"
    (match checkerWhnfCached env lctxC 0 leanNatMaxSizeDefault true closed with
     | some value => Expr.eq value closedResult
     | none => false)

  expectWhnfCache "WHNF-core table starts separate"
    ((checkerWhnfCoreCached env lctx 0 leanNatMaxSizeDefault true closed).isNone)
  let storedCore := checkerWhnfCoreCacheResult
    env lctx 0 leanNatMaxSizeDefault true closed closedResult
  expectWhnfCache "WHNF-core store is identity" (Expr.eq storedCore closedResult)
  expectWhnfCache "WHNF-core hit"
    ((checkerWhnfCoreCached env lctx 0 leanNatMaxSizeDefault true closed).isSome)

  let env2 := { env with quotInitialized := true }
  expectWhnfCache "different environment does not alias"
    ((checkerWhnfCached env2 lctx 0 leanNatMaxSizeDefault true closed).isNone)
  expectWhnfCache "different recursion configuration does not alias"
    ((checkerWhnfCached env lctx 1 leanNatMaxSizeDefault true closed).isNone)
  expectWhnfCache "disabled cache never hits"
    ((checkerWhnfCached env lctx 0 leanNatMaxSizeDefault false closed).isNone)

  IO.println "PSC1 native WHNF cache isolation smoke: PASS"
