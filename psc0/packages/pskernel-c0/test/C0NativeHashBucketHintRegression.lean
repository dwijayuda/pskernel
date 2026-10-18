import Ps.KernelCore.Runtime.Acceleration.Cache

/-!
Nontrusting native hash-bucket hint regression. The all-input source-hash
certificate `psKernelC0ExactMemoizedExprHash_source` is unchanged. The
new native child-pointer index controls ONLY which exact-syntax memo entry
is visited, and every successful lookup still supplies a Lean equality
proof of the original source expression. No declaration is admitted here.
-/

def c0BucketSharedTree : Nat → PsKernelExpr → PsKernelExpr
  | 0, x => x
  | n + 1, x =>
      let child := c0BucketSharedTree n x
      .app child child

def c0BucketFoldSource (hash : Nat) : Nat → Nat
  | 0 => hash
  | n + 1 =>
      let previous := c0BucketFoldSource hash n
      psKernelCacheMix (psKernelCacheMix 26 previous) previous

def main : IO Unit := do
  let a : PsKernelName := .str .anonymous "alpha"
  let b : PsKernelName := .str .anonymous "beta"
  let root : PsKernelExpr := .app (.const a [.zero]) (.lit (.nat 4))
  let sorts : PsKernelExpr := .sort (.succ .zero)
  let one : PsKernelExpr := .app root root
  let other : PsKernelExpr := .app (.const b [.zero]) sorts
  let examples : List PsKernelExpr := [
    .app root other,
    .app one other,
    .app (c0BucketSharedTree 8 root) (.lit (.nat 3)),
    .lam a sorts (.app root other) .default,
    .lam b sorts (.app root other) .implicit,
    .forallE a sorts (.app root other) .strictImplicit,
    .letE a sorts root one false,
    .letE b sorts root one true,
    .mdata 18 one,
    .mdata 19 one,
    .proj a 0 one,
    .proj b 0 one,
    .lit (.str "hash-index"),
    c0BucketSharedTree 11 root,
    c0BucketSharedTree 11 other
  ]
  for expr in examples do
    let oracle := psKernelExprHash expr
    let actual := psKernelC0ExactMemoizedExprHash expr
    let _proof : psKernelC0ExactMemoizedExprHash expr =
        psKernelExprHash expr :=
      psKernelC0ExactMemoizedExprHash_source expr
    if oracle != actual then
      throw (IO.userError "native hash bucket altered source hash")
  let hugeDepth := 25
  let huge := c0BucketSharedTree hugeDepth root
  let expected := c0BucketFoldSource (psKernelExprHash root) hugeDepth
  let actual := psKernelC0ExactMemoizedExprHash huge
  if actual != expected then
    throw (IO.userError "shared-expression DAG hash changed")
  IO.println "C0_NATIVE_HASH_BUCKET source_proved=all_inputs varied_nonsharing=15 independently_shared_DAG=pass pointer_only_indexing=true source_fuel_unchanged=true no_admission=true"
