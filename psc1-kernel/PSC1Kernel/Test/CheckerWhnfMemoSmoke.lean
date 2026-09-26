import PSC1Kernel.CheckerWhnfCacheRuntime

open PSC1Kernel

def whnfMemoSmokeNatMax : Nat :=
  128 * 1024 * 1024

def expectWhnfMemo (label : String) (ok : Bool) : IO Unit :=
  if ok then pure ()
  else throw <| IO.userError ("checker WHNF memo smoke failed: " ++ label)

def expectWhnfMemoResult (label : String) : Except String Expr → IO Expr
  | .ok value => pure value
  | .error err => throw <| IO.userError (label ++ ": " ++ err)

unsafe def main : IO Unit := do
  let env := Environment.empty
  let lctx := LocalContext.empty
  let expr : Expr :=
    .app
      (.lam (.str .anonymous "x") (.sort .zero) (.bvar 0) .default)
      (.sort .zero)
  let result : Expr := .sort .zero

  checkerWhnfMemoResetStatsIO

  let first ← expectWhnfMemoResult "first memo computation failed" <|
    checkerWhnfMemo env lctx 0 whnfMemoSmokeNatMax true expr
      (fun _ => .ok result)
  expectWhnfMemo "first result" (Expr.eq first result)

  let second ← expectWhnfMemoResult "second memo computation failed" <|
    checkerWhnfMemo env lctx 0 whnfMemoSmokeNatMax true expr
      (fun _ => .ok result)
  expectWhnfMemo "second result" (Expr.eq second result)

  let (hits1, misses1) ← checkerWhnfMemoStatsIO
  expectWhnfMemo "same-scope second call hits cache"
    (hits1 == 1 && misses1 == 1)

  let lctx2 :=
    lctx.addLocal
      (.str .anonymous "unused")
      (.str .anonymous "unused")
      (.sort (.succ .zero))
      .default
  let third ← expectWhnfMemoResult "closed cross-context memo failed" <|
    checkerWhnfMemo env lctx2 0 whnfMemoSmokeNatMax true expr
      (fun _ => .ok result)
  expectWhnfMemo "closed expression reuses across local contexts"
    (Expr.eq third result)
  let (hits2, misses2) ← checkerWhnfMemoStatsIO
  expectWhnfMemo "closed cross-context call is a hit"
    (hits2 == 2 && misses2 == 1)

  let env2 := { env with quotInitialized := true }
  let fourth ← expectWhnfMemoResult "changed-env memo failed" <|
    checkerWhnfMemo env2 lctx 0 whnfMemoSmokeNatMax true expr
      (fun _ => .ok result)
  expectWhnfMemo "changed environment result" (Expr.eq fourth result)
  let (hits3, misses3) ← checkerWhnfMemoStatsIO
  expectWhnfMemo "environment change forces miss"
    (hits3 == 2 && misses3 == 2)

  IO.println "PSC1 native WHNF memo combinator smoke: PASS"
