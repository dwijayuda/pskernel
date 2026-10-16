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
    [psKernelExprEq, psKernelExprEqLegacy, Bool.and_assoc,
      Bool.beq_eq_decide_eq]

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
