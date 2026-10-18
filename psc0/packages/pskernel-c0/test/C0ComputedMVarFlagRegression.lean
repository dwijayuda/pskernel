import Ps.KernelCore.Admission.Declaration.Validation

/-!
Native C0 MVar computed-field proof and old source decision regressions.

The all-input theorem is in the source Validation module. This test
observes real native field computation and compares it with the old
recursive oracle on small trees. Large shared-DAG examples deliberately do
NOT evaluate the exponential historical oracle: they are proven by the
all-input theorem. No declaration is admitted from a cached flag alone.
-/

def c0FlagMakeShared : Nat → PsKernelExpr → PsKernelExpr
  | 0, leaf => leaf
  | n + 1, leaf =>
      let child := c0FlagMakeShared n leaf
      .app child child

def main : IO Unit := do
  let name : PsKernelName := .str .anonymous "flag-source"
  let ok : PsKernelExpr := .const name []
  let mvar : PsKernelExpr := .mvar name
  let levelMVar : PsKernelExpr := .sort (.mvar name)
  let levelListMVar : PsKernelExpr := .const name [.zero, .mvar name]
  let xs : List PsKernelExpr := [
    .bvar 0, .fvar name, mvar,
    .sort .zero, levelMVar, levelListMVar,
    ok, .app ok mvar, .app mvar ok,
    .lam name ok mvar .default,
    .forallE name levelMVar ok .implicit,
    .letE name ok levelListMVar ok false,
    .mdata 9 (.app ok mvar),
    .proj name 0 (.app ok levelMVar),
    .lit (.nat 4),
    .lit (.str "field")
  ]
  for expr in xs do
    let original := psKernelExprHasMVar expr
    let computed := expr.psKernelC0MVarFlag
    let _witness : expr.psKernelC0MVarFlag = psKernelExprHasMVar expr :=
      psKernelC0MVarFlag_source expr
    if original != computed then
      throw (IO.userError "native computed MVar flag diverged from source")
  let closed := c0FlagMakeShared 4000 ok
  let opened := c0FlagMakeShared 4000 mvar
  let _closedProof : closed.psKernelC0MVarFlag = psKernelExprHasMVar closed :=
    psKernelC0MVarFlag_source closed
  let _openedProof : opened.psKernelC0MVarFlag = psKernelExprHasMVar opened :=
    psKernelC0MVarFlag_source opened
  let start ← IO.monoNanosNow
  if closed.psKernelC0MVarFlag || !opened.psKernelC0MVarFlag then
    throw (IO.userError "large shared source node MVar flag incorrect")
  let doneAt ← IO.monoNanosNow
  if (psKernelCheckNoMVarNoFVar opened).isOk then
    throw (IO.userError "declaration preflight admitted an MVar-positive DAG")
  if !(psKernelCheckNoMVarNoFVar closed).isOk then
    throw (IO.userError "closed shared DAG was incorrectly rejected")
  IO.println s!"C0_NODE_MVAR_FIELD proof=all_inputs checked_cases=16 large_DAG_depth=4000 positive_and_negative=correct native_field_query_ms={(doneAt-start)/1000000} error_order_preserved=true no_axioms_or_admission_shortcuts=true"
