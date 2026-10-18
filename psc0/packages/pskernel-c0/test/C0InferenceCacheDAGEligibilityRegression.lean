import Ps.KernelCore.Runtime.Acceleration.CachePolicy

/-!
All-input correctness is established by
`psKernelC0DAGInferCacheEligible_source` in imported Lean source.
These diagnostics exercise actual compilation and checked/infer cache
policy on closed, open, and deeply shared independently built expressions.
The test never admits a declaration or treats cached syntax as a proof.
-/

def c0InferEligSharedGraph : Nat → PsKernelExpr → PsKernelExpr
  | 0, leaf => leaf
  | n + 1, leaf =>
      let child := c0InferEligSharedGraph n leaf
      .app child child

def main : IO Unit := do
  let name : PsKernelName := .str .anonymous "inference"
  let closed : PsKernelExpr := .const name []
  let opened : PsKernelExpr := .fvar name
  let cases : List PsKernelExpr := [
    .bvar 0, .sort .zero, .const name [], opened,
    .mvar name,
    .lit (.nat 8),
    .app closed closed,
    .app closed opened,
    .lam name closed closed .default,
    .lam name closed opened .default,
    .forallE name closed opened .default,
    .letE name closed opened closed false,
    .mdata 1 opened, .proj name 0 closed,
    c0InferEligSharedGraph 10 closed,
    c0InferEligSharedGraph 10 opened,
    c0InferEligSharedGraph 13 closed,
    c0InferEligSharedGraph 13 opened
  ]
  for inferOnly in [false, true] do
    for expr in cases do
      let historical := psKernelInferCacheEligible inferOnly expr
      let previous := psKernelC0FastInferCacheEligible inferOnly expr
      let candidate := psKernelC0DAGInferCacheEligible inferOnly expr
      if historical != previous || candidate != historical then
        throw (IO.userError "C0 inference eligibility differs from source")
  for inferOnly in [false, true] do
    if psKernelC0DAGInferCacheEligible inferOnly opened then
      throw (IO.userError "free-variable inference cache admission forbidden")
    if psKernelC0DAGInferCacheEligible inferOnly (.app opened closed) then
      throw (IO.userError "open application inference cache admission forbidden")
  if psKernelC0DAGInferCacheEligible false (.app closed closed) then
    throw (IO.userError "checked application must not enter inference cache")
  if !psKernelC0DAGInferCacheEligible true (.app closed closed) then
    throw (IO.userError "closed infer-only application was incorrectly blocked")
  IO.println "C0_INFER_DAG_CACHE source_proved=all_inputs cases=36 FVar_scope=preserved checked_app_cache=false infer_app_cache=source_exact no_admission=true"
