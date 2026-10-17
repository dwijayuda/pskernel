import Ps.KernelCore.Core.Expr

/-!
The source legacy comparator deliberately IGNORES lambda/Pi binder names
and binderInfo, unlike full DecidableEq.  We prove/compiler-rewrite it
with the pre-existing all-input Lean theorem, and test representative
positive/negative and shared-DAG shapes. No kernel admission takes place.
-/

def c0LegacyEqShared : Nat → PsKernelExpr → PsKernelExpr
  | 0, e => e
  | n + 1, e =>
      let c := c0LegacyEqShared n e
      .app c c

def main : IO Unit := do
  let x : PsKernelName := .str .anonymous "x"
  let y : PsKernelName := .str .anonymous "y"
  let atom : PsKernelExpr := .const x []
  let binderA : PsKernelExpr := .lam x atom (.bvar 0) .default
  let binderB : PsKernelExpr := .lam y atom (.bvar 0) .implicit
  let piA : PsKernelExpr := .forallE x atom (.bvar 0) .default
  let piB : PsKernelExpr := .forallE y atom (.bvar 0) .instImplicit
  let letA : PsKernelExpr := .letE x atom atom (.bvar 0) false
  let letB : PsKernelExpr := .letE y atom atom (.bvar 0) false
  if !psKernelExprEqLegacy binderA binderB ||
     !psKernelC0FullPairedExprEq binderA binderB ||
     !psKernelExprEqLegacy piA piB ||
     !psKernelC0FullPairedExprEq piA piB ||
     !psKernelExprEqLegacy letA letB then
    throw (IO.userError "legacy binder erasure semantics were changed")
  let cases : List PsKernelExpr := [
    .bvar 0, .bvar 1, .mvar x, .fvar x,
    .sort .zero, .sort (.succ .zero),
    atom, .const y [], .const x [.zero],
    .lit (.nat 5), .lit (.nat 6),
    binderA, binderB, piA, piB, letA, letB,
    .mdata 1 atom, .mdata 2 atom,
    .proj x 0 atom, .proj y 1 atom,
    c0LegacyEqShared 9 atom,
    c0LegacyEqShared 9 (.bvar 0),
    c0LegacyEqShared 9 binderA,
    c0LegacyEqShared 9 binderB
  ]
  for lhs in cases do
    for rhs in cases do
      let original := psKernelExprEqLegacy lhs rhs
      let selected := psKernelC0FullPairedExprEq lhs rhs
      if original != selected then
        throw (IO.userError "full paired legacy equality changed source Boolean")
  IO.println "C0_LEGACY_EQ_SOURCE all_input_Lean_proved=true pairs=625 shared_DAG=pass binder_name_info_erasure=preserved no_admission=true"
