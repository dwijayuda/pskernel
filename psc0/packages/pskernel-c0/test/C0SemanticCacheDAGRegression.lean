import Ps.KernelCore.Runtime.Acceleration.CachePolicy

/-! All-input source theorem and DAG regression for native semantic cache
eligibility. This neither inserts nor consumes a checker cache receipt. -/

def c0FVarDag (n : Nat) (leaf : PsKernelExpr) : PsKernelExpr :=
  match n with
  | 0 => leaf
  | k + 1 =>
      let shared := c0FVarDag k leaf
      .app shared shared

def main : IO Unit := do
  let name : PsKernelName := .str .anonymous "local"
  let ty : PsKernelExpr := .sort .zero
  let samples : List PsKernelExpr := [
    .fvar name,
    .mvar name,
    .bvar 0,
    .app (.fvar name) ty,
    .lam name ty (.fvar name) .default,
    .forallE name ty (.fvar name) .default,
    .letE name ty ty (.fvar name) false,
    c0FVarDag 8 ty,
    c0FVarDag 8 (.fvar name),
    c0FVarDag 12 (.const name [])
  ]
  for expr in samples do
    let source := psKernelSemanticCacheEligible expr
    if psKernelC0FastSemanticCacheEligible expr != source then
      throw (IO.userError "certified semantic cache policy differs from original")
  let bigClosed := c0FVarDag 24 ty
  let bigOpen := c0FVarDag 24 (.fvar name)
  if !psKernelC0FastSemanticCacheEligible bigClosed ||
      psKernelC0FastSemanticCacheEligible bigOpen then
    throw (IO.userError "DAG semantic-cache scope policy wrong on open/closed expression")
  IO.println "C0_FVAR_SEMANTIC source_equal=Lean_proved scope_preserved=true shared_depth=24 no_trusted_cache_modified=true"
