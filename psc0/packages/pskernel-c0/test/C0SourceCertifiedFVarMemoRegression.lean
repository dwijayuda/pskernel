import Ps.KernelCore.Runtime.Acceleration.CachePolicy

/-!
Regress the exact source-certified FVar-membership memo and its bounded
selector independently of kernel admissions. DAG sharing is intentional:
the original structural predicate must agree with the memoized answer for
closed, open, nested, and mixed constructors. The Lean all-input theorem
is the authority; the tests cover executable traversal and performance.
-/

def main : IO Unit := do
  let name : PsKernelName := .str .anonymous "memoFVar"
  let closed : PsKernelExpr := .sort .zero
  let local : PsKernelExpr := .fvar name
  let raw : List PsKernelExpr := [
    closed, local, .bvar 0, .mvar name, .const name [],
    .lit (.nat 17), .app closed local, .app local closed,
    .lam name closed (.app closed local) .default,
    .forallE name (.app closed local) closed .default,
    .letE name closed closed (.app closed local) false,
    .mdata 17 (.app local closed),
    .proj name 0 (.app closed local)
  ]
  for expr in raw do
    let original := psKernelExprHasFVar expr
    if psKernelC0MemoizedHasFVar expr != original ||
        psKernelC0AdaptiveHasFVar expr != original then
      throw (IO.userError "FVar memo disagrees with the original predicate")

  -- The same subterm is reused on both sides. A naive recursive query
  -- visits an exponentially expanded tree; the operation-local memo
  -- verifies each unique subtree under exact syntax equality.
  let mut shared := closed
  for _ in [:13] do
    shared := .app shared shared
  if psKernelExprHasFVar shared ||
      psKernelC0MemoizedHasFVar shared ||
      psKernelC0AdaptiveHasFVar shared then
    throw (IO.userError "closed shared DAG gained a free variable")

  let withLocal : PsKernelExpr := .app shared local
  if !psKernelExprHasFVar withLocal ||
      !psKernelC0MemoizedHasFVar withLocal ||
      !psKernelC0AdaptiveHasFVar withLocal then
    throw (IO.userError "FVar memo missed a local on shared DAG")

  let mut huge := closed
  for _ in [:22] do
    huge := .app huge huge
  if psKernelC0MemoizedHasFVar huge ||
      psKernelC0AdaptiveHasFVar huge then
    throw (IO.userError "memo misclassified a deeply shared closed DAG")

  -- Hash buckets are hints only: binder names and info are not semantic
  -- cache keys. The proof-producing equality check must still discriminate
  -- different expressions regardless of their shallow shape.
  let another : PsKernelName := .str .anonymous "differentFVar"
  let a : PsKernelExpr := .lam name closed local .default
  let b : PsKernelExpr := .lam another closed local .default
  if psKernelC0MemoShapeHash 4 a != psKernelC0MemoShapeHash 4 b then
    throw (IO.userError "expected binder-name-insensitive shape collision")
  if !psKernelC0MemoizedHasFVar a || !psKernelC0MemoizedHasFVar b then
    throw (IO.userError "shape hash affected source FVar result")

  IO.println "C0_FVAR_MEMO source_equivalence=Lean constructors=pass shared_DAG=pass shape_collision=pass"
