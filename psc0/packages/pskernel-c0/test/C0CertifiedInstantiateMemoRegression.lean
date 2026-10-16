import Ps.KernelCore.Architecture.CertifiedInstantiateMemo

/-!
Compare exact source substitution including binder offsets and changed flags;
a 26-level repeated-node DAG represents >134 million expanded AST nodes.
The historical exponential oracle is only called on small regression terms.
-/

def c0InstMemoShared (base : PsKernelExpr) (depth : Nat) : PsKernelExpr :=
  (List.range depth).foldl (fun x (_ : Nat) => .app x x) base

def main : IO Unit := do
  let a : PsKernelName := .str .anonymous "a"
  let b : PsKernelName := .str .anonymous "b"
  let base : PsKernelExpr := .bvar 0
  let replacement : PsKernelExpr := .fvar a
  let nestedTerm : PsKernelExpr :=
    .letE b (.sort .zero) (.app (.bvar 1) (.bvar 0))
      (.forallE b (.app (.fvar a) (.bvar 2))
        (.lam a (.sort .zero)
          (.app (.mdata 19 (.bvar 1))
            (.proj b 2 (.bvar 3))) .default) .implicit) false
  let samples : List PsKernelExpr := [
    base, .bvar 1, .bvar 12, .sort .zero, .fvar a,
    .app base base,
    .mdata 5 (.app base (.bvar 2)),
    .lam b (.bvar 1) (.bvar 0) .default,
    .forallE a (.bvar 0) (.bvar 1) .implicit,
    nestedTerm, c0InstMemoShared (.app base nestedTerm) 7
  ]
  for expr in samples do
    for offset in [0, 1, 2, 5] do
      for subst in [replacement, .bvar 0, .sort (.succ .zero)] do
        let exact := psKernelC0ExprInstantiateOneChanged expr subst offset
        let checked := psKernelC0InstOneMemoizedChanged expr subst offset
        let _source :
            psKernelC0InstOneMemoizedChanged expr subst offset =
              psKernelC0ExprInstantiateOneChanged expr subst offset :=
          psKernelC0InstOneMemoizedChanged_source expr subst offset
        if exact.2 != checked.2 ||
          !psKernelExprEqual exact.1 checked.1 then
          throw (IO.userError "memoized instantiation diverges from exact original source")

  let depth := 26
  let expanded := c0InstMemoShared (.bvar 0) depth
  let begin ← IO.monoNanosNow
  let computed := psKernelC0InstOneMemoizedChanged expanded replacement 0
  let elapsed ← IO.monoNanosNow
  -- Full structural equality here would itself exponentially expand
  -- the physical DAG; the source-equality theorem below is stronger.
  let _source :
      psKernelC0InstOneMemoizedChanged expanded replacement 0 =
        psKernelC0ExprInstantiateOneChanged expanded replacement 0 :=
    psKernelC0InstOneMemoizedChanged_source expanded replacement 0
  if !computed.2 ||
      psKernelExprGetAppNumArgs computed.1 != depth ||
      !psKernelExprEqual (psKernelExprGetAppFn computed.1) replacement then
    throw (IO.userError "shared DAG substitution has wrong binder or spine result")
  IO.println s!"C0_CERTIFIED_INSTANTIATE_MEMO source=Lean_proved all_offsets=pass shared_depth={depth} elapsed_ms={(elapsed - begin)/1000000}"
