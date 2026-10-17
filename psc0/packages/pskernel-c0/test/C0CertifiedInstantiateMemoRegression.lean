import Ps.KernelCore.Architecture.CertifiedInstantiateMemo

/-!
Compare exact source substitution including binder offsets and changed flags;
a 26-level repeated-node DAG represents >134 million expanded AST nodes.
The historical exponential oracle is only called on small regression terms.
-/

def c0InstMemoShared (base : PsKernelExpr) (depth : Nat) : PsKernelExpr :=
  (List.range depth).foldl (fun x (_ : Nat) => .app x x) base

/-- Fifty different deep heads collide under the source depth-three
memo selector, but can be distinguished by depth four after upgrading only
that collision-heavy bucket. -/
def c0InstMemoShallowCollision (i : Nat) : PsKernelExpr :=
  let fn : PsKernelExpr := .const (.num .anonymous i) []
  let arg : PsKernelExpr := .lit (.nat 1)
  .app (.app (.app fn arg) arg) arg

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

  -- Exercise the collision-triggered secondary-key path using a real
  -- shared source expression, not forged memo results. A source-equal
  -- computation remains required even when 50 distinct keys land in the
  -- same shallow trie leaf.
  let crowded : List PsKernelExpr :=
    (List.range 50).map c0InstMemoShallowCollision
  let shallowKey := psKernelC0MemoShapeHash 3 (c0InstMemoShallowCollision 0)
  for expr in crowded do
    if psKernelC0MemoShapeHash 3 expr != shallowKey then
      throw (IO.userError "instantiation memo collision shape not reproduced")
  let crowdedRoot :=
    crowded.foldl (fun acc next => .app acc next) (.bvar 0)
  let plainCrowded :=
    psKernelC0ExprInstantiateOneChanged crowdedRoot replacement 0
  let fastCrowded :=
    psKernelC0InstOneMemoizedChanged crowdedRoot replacement 0
  if plainCrowded.2 != fastCrowded.2 ||
      !psKernelExprEqual plainCrowded.1 fastCrowded.1 then
    throw (IO.userError "secondary index changed certified substitution")
  IO.println "C0_CERTIFIED_INSTANTIATE_MEMO depth_three_collision_upgrade=source_exact"

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
