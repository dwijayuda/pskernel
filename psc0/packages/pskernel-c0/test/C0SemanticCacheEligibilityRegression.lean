import Ps.KernelCore.Runtime.Acceleration.CachePolicy

/-!
Every test observes exactly the complete source semantic eligibility
decision. The theorem in CachePolicy proves *all* inputs, while these
cases exercise actual selected compiler execution and shared syntax.
No kernel declaration is admitted in this diagnostic.
-/

def c0EligSharedDAG : Nat → PsKernelExpr → PsKernelExpr
  | 0, value => value
  | n + 1, value =>
      let subtree := c0EligSharedDAG n value
      .app subtree subtree

def main : IO Unit := do
  let x : PsKernelName := .str .anonymous "external"
  let atom : PsKernelExpr := .const x []
  let yes : PsKernelExpr := .fvar x
  let cases : List PsKernelExpr := [
    .bvar 0,
    .sort .zero,
    .sort (.mvar x),
    .const x [.mvar x],
    yes,
    .mvar x,
    .lam x atom yes .default,
    .forallE x yes atom .default,
    .letE x atom yes atom false,
    .mdata 1 yes,
    .proj x 0 yes,
    c0EligSharedDAG 11 atom,
    c0EligSharedDAG 11 yes,
    .app (c0EligSharedDAG 11 atom) yes,
    .app yes (c0EligSharedDAG 11 atom)
  ]
  for expr in cases do
    let expected := psKernelSemanticCacheEligible expr
    let selected := psKernelC0AdaptiveSemanticCacheEligible expr
    if selected != expected ||
        selected != !psKernelC0MemoizedHasFVar expr then
      throw (IO.userError "whole-source semantic cache-eligibility verdict diverged")
  for left in cases do
    for right in cases do
      if psKernelC0CertifiedSemanticPairEligible left right !=
          psKernelSemanticPairCacheEligible left right then
        throw (IO.userError "DefEq pair eligibility differs from the source")
  -- Compare source parity including a deep shared DAG on one side and a
  -- context-local free variable on the other; no cache leak can be hidden.
  let large := c0EligSharedDAG 18 atom
  for pair in [(large, large), (large, yes), (yes, large),
      (c0EligSharedDAG 18 yes, large)] do
    if psKernelC0CertifiedSemanticPairEligible pair.1 pair.2 !=
        psKernelSemanticPairCacheEligible pair.1 pair.2 then
      throw (IO.userError "shared DefEq cache guard source divergence")
  IO.println "C0_WHNF_ELIG source_proved=all_inputs selected=15 pair_guards=225 shared_DAG=pass FVar_scope_guard=unchanged no_admission=true"
