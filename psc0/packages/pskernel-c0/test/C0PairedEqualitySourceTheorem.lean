import Ps.KernelCore.Core.Expr

/-!
Diagnostic proof that C0's existing constructor-paired equality entry
preserves the historical curried comparator for arbitrary source expressions.
This is a semantic baseline for a later fully recursive paired comparator:
only a proved equality, not an unchecked runtime shortcut, can qualify it.
-/

theorem c0PairedEntry_eq_historical
    (left right : PsKernelExpr) :
    psKernelExprEq left right =
      psKernelExprEqLegacy left right := by
  cases left <;> cases right <;> simp
    [psKernelExprEq, psKernelExprEqLegacy, Bool.and_assoc]
  all_goals rfl

def main : IO Unit := do
  let one : PsKernelName := .str .anonymous "one"
  let x : PsKernelExpr := .bvar 0
  let f : PsKernelExpr := .const one []
  let pair : PsKernelExpr := .app (.app f x) (.app f x)
  for a in [x, f, pair, .lam one x pair .default,
      .forallE one f pair .implicit,
      .letE one x f pair false] do
    for b in [x, f, pair, .lam one x pair .strictImplicit,
        .forallE one f pair .default,
        .letE one x f pair false] do
      if psKernelExprEq a b != psKernelExprEqLegacy a b then
        throw (IO.userError "paired outer equality differs from historical source")
  IO.println "C0_PAIRED_OUTER_EQUALITY exact_full_source=Lean_proved"

  let deep : PsKernelExpr :=
    .app (.lam one (.sort .zero) pair .default)
      (.app (.const one []) pair)
  let fixtures : List PsKernelExpr := [
    x, .bvar 1, f, pair, deep,
    .lam one x pair .default,
    .lam one x pair .instImplicit,
    .forallE one f deep .implicit,
    .forallE one f deep .default,
    .letE one x f pair false,
    .letE one x f pair true,
    .lit (.nat 3), .lit (.str "κernel"),
    .mdata 7 deep, .mdata 8 deep,
    .proj one 0 pair, .proj one 1 pair
  ]
  for lhs in fixtures do
    for rhs in fixtures do
      if psKernelC0FullPairedExprEq lhs rhs !=
          psKernelExprEqLegacy lhs rhs then
        throw (IO.userError
          "full recursive paired equality changed source comparison")
  -- Deliberate binder-name and binder-info erasure remains visible on
  -- nested applications, not just on standalone lambdas.
  let other : PsKernelName := .str .anonymous "other"
  let alpha : PsKernelExpr := .app (.lam one x pair .default) x
  let beta : PsKernelExpr := .app (.lam other x pair .implicit) x
  if !psKernelC0FullPairedExprEq alpha beta then
    throw (IO.userError "paired equality lost binder-name erasure")
  IO.println "C0_FULL_RECURSIVE_PAIRED_EQUALITY all_input_theorem=Lean_proved fixtures=pass"
