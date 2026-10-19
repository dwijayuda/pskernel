import Ps.KernelCore.Core.Expr

/-!
The old recursive oracle deliberately runs only on small expressions. The
source theorem proves equality for all inputs; the 4000-node DAG checks
actual native computed-field operation without exponentially expanding it.
-/

def c0LooseBoundShared : Nat → PsKernelExpr → PsKernelExpr
  | 0, v => v
  | n+1, v =>
      let child := c0LooseBoundShared n v
      .app child child

def main : IO Unit := do
  let a : PsKernelName := .str .anonymous "a"
  let xs : List PsKernelExpr := [
    .bvar 0, .bvar 1, .bvar 7, .sort .zero,
    .const a [], .app (.bvar 0) (.bvar 5),
    .lam a (.bvar 0) (.bvar 0) .default,
    .lam a (.sort .zero) (.bvar 1) .default,
    .forallE a (.bvar 2) (.bvar 0) .implicit,
    .letE a (.bvar 2) (.bvar 0) (.bvar 1) false,
    .mdata 3 (.bvar 8), .proj a 0 (.bvar 4),
    .fvar a, .mvar a, .lit (.nat 3)
  ]
  for expr in xs do
    for offset in [0,1,2,3,7,8,12] do
      let original := psKernelExprHasLooseAt expr offset
      let fast := psKernelC0HasLooseBVarFast expr offset
      let _theorem : fast = original :=
        psKernelC0HasLooseBVarFast_source expr offset
      if fast != original then
        throw (IO.userError "native loose-bound metadata differs from source oracle")
  let closed := c0LooseBoundShared 4000 (.const a [])
  let free := c0LooseBoundShared 4000 (.bvar 0)
  let deep := c0LooseBoundShared 4000 (.bvar 128)
  let _closed : psKernelC0HasLooseBVarFast closed 0 =
    psKernelExprHasLooseAt closed 0 :=
    psKernelC0HasLooseBVarFast_source closed 0
  let _free : psKernelC0HasLooseBVarFast free 0 =
    psKernelExprHasLooseAt free 0 :=
    psKernelC0HasLooseBVarFast_source free 0
  let start ← IO.monoNanosNow
  if psKernelC0HasLooseBVarFast closed 0 then
    throw (IO.userError "closed immutable DAG misclassified")
  if !psKernelC0HasLooseBVarFast free 0 then
    throw (IO.userError "free immutable DAG misclassified")
  if !psKernelC0HasLooseBVarFast deep 128 then
    throw (IO.userError "offset-128 loose bound missing")
  if psKernelC0HasLooseBVarFast deep 129 then
    throw (IO.userError "offset-129 loose bound false positive")
  let stop ← IO.monoNanosNow
  IO.println s!"C0_LOOSE_BVAR_BOUND proof=all_inputs native_small_cases=15 offsets=7 shared_depth=4000 exact_offsets=true query_ms={(stop-start)/1000000} no_admission=true"
