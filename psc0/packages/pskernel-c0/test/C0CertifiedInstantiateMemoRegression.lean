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
  -- Non-bvar source atoms are not affected by single-binder substitution.
  -- The certified runtime should neither look them up nor populate a
  -- collision-index trie. BVars still require exact per-offset memoization.
  let atomicUnchanged : List PsKernelExpr := [
    .fvar a, .mvar b, .sort .zero,
    .sort (.max .zero (.succ .zero)),
    .const (.str .anonymous "VeryLongQualifiedName") [.zero],
    .lit (.nat 13), .lit (.str "κernel")
  ]
  for atom in atomicUnchanged do
    let (proof, memo) := psKernelC0InstOneMemoGo replacement atom 2 .empty
    let _source :
        proof.value = psKernelC0ExprInstantiateOneChanged atom replacement 2 :=
      proof.source
    if proof.value.2 || !psKernelExprEqual proof.value.1 atom then
      throw (IO.userError "non-BVar instantiation atom changed source")
    match memo with
    | .empty => pure ()
    | _ => throw (IO.userError "non-BVar atom polluted instantiation memo")
  IO.println "C0_CERTIFIED_INSTANTIATE_MEMO immutable_atom_leaves=source_exact memo_unchanged=true"

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

  -- Force two keys into the SAME shallow hash bucket but with different
  -- binder offsets. Offsets differ by the hash modulus: an exact syntax
  -- hit alone must never reuse a result from the wrong binder scope.
  let zeroBVar : PsKernelExpr := .bvar 0
  let farOffset := psKernelCacheHashModulus
  if psKernelCacheMix (psKernelC0MemoShapeHash 3 zeroBVar) 0 !=
      psKernelCacheMix (psKernelC0MemoShapeHash 3 zeroBVar) farOffset then
    throw (IO.userError "binder offset collision test was not constructed")
  let firstCertified :=
    psKernelC0InstOneMemoGo replacement zeroBVar 0 .empty
  let secondCertified :=
    psKernelC0InstOneMemoGo replacement zeroBVar farOffset
      firstCertified.2
  let expectedFar :=
    psKernelC0ExprInstantiateOneChanged zeroBVar replacement farOffset
  if firstCertified.1.value.2 != true ||
      secondCertified.1.value.2 != false ||
      !psKernelExprEqual secondCertified.1.value.1 expectedFar.1 ||
      secondCertified.1.value.2 != expectedFar.2 then
    throw (IO.userError
      "memo reused checked substitution across incompatible binder offsets")
  IO.println "C0_CERTIFIED_INSTANTIATE_MEMO colliding_offset_keys=source_exact false_reuse=blocked"

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
