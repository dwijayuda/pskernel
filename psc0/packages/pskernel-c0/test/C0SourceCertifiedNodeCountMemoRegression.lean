import Ps.KernelCore.Runtime.Acceleration.CertifiedNodeCountMemo

/-!
Exact node-count memo conformance. The count is the number of expanded
syntax-tree nodes (not distinct nodes in the shared DAG), because source
traversal budgets use that exact number. The Lean all-input theorem
establishes the complete numerical equivalence; these native fixtures
cover executable cases and hash bucket collisions.
-/

def main : IO Unit := do
  let name : PsKernelName := .str .anonymous "countMemo"
  let leaf : PsKernelExpr := .sort .zero
  let localVar : PsKernelExpr := .fvar name
  let samples : List PsKernelExpr := [
    leaf, localVar, .bvar 12, .mvar name,
    .const name [], .lit (.nat 25),
    .app leaf localVar,
    .lam name leaf (.app leaf localVar) .default,
    .forallE name (.app localVar leaf) leaf .default,
    .letE name leaf leaf (.app leaf localVar) false,
    .mdata 13 (.app leaf leaf),
    .proj name 0 (.app leaf leaf)
  ]
  for expr in samples do
    let expected := psKernelExprNodeCount expr
    if psKernelC0MemoizedExprNodeCount expr != expected ||
        psKernelC0AdaptiveExprNodeCount expr != expected ||
        psKernelC0DirectExprNodeCount expr != expected then
      throw (IO.userError "node count diverged from exact source fuel sizing")

  let mut shared := leaf
  for _ in [:12] do
    shared := .app shared shared
  let reference := psKernelExprNodeCount shared
  if psKernelC0MemoizedExprNodeCount shared != reference ||
      psKernelC0AdaptiveExprNodeCount shared != reference then
    throw (IO.userError "shared DAG node count lost expanded occurrences")

  -- Extend the same syntactic DAG to a much larger expanded tree, but
  -- compute its reference total algebraically rather than expanding it.
  let mut expected : Nat := reference
  for _ in [:17] do
    shared := .app shared shared
    expected := Nat.succ (expected + expected)
  if psKernelC0MemoizedExprNodeCount shared != expected ||
      psKernelC0AdaptiveExprNodeCount shared != expected then
    throw (IO.userError "large DAG node count changed resource budget")

  -- Same shallow hash, different exact expanded counts, in the same query.
  let mut left := leaf
  let mut right : PsKernelExpr := .app leaf leaf
  for _ in [:6] do
    left := .app left leaf
    right := .app right leaf
  if psKernelC0MemoShapeHash 4 left !=
      psKernelC0MemoShapeHash 4 right then
    throw (IO.userError "missing expected shallow hash collision")
  if psKernelC0MemoizedExprNodeCount (.app left right) !=
      psKernelExprNodeCount (.app left right) then
    throw (IO.userError "node count reused a colliding wrong-size result")
  IO.println "C0_NODE_COUNT_MEMO source_equivalence=Lean expanded_budget=exact shared_DAG=pass hash_collision=pass"
