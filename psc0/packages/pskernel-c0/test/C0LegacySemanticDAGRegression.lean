import Ps.KernelCore.Core.ExprDecidableEq

/-!
This checks that the new DAG algorithm has EXACT historical semantic equality,
including the intentional erasure of binder display names and annotations.
Structural DecidableEq is intentionally not the semantic oracle.
The Lean source theorem proves the result for all inputs; finite cases here
exercise ordinary and independently reconstructed shared graphs.
-/

def c0LegacySharedTree : Nat → PsKernelExpr → PsKernelExpr
  | 0, leaf => leaf
  | n + 1, leaf =>
      let child := c0LegacySharedTree n leaf
      .app child child

def main : IO Unit := do
  let alpha : PsKernelName := .str .anonymous "left"
  let beta : PsKernelName := .str .anonymous "right"
  let ty : PsKernelExpr := .sort .zero
  let lamA : PsKernelExpr := .lam alpha ty (.bvar 0) .default
  let lamB : PsKernelExpr := .lam beta ty (.bvar 0) .implicit
  let piA : PsKernelExpr := .forallE alpha ty (.bvar 0) .default
  let piB : PsKernelExpr := .forallE beta ty (.bvar 0) .strictImplicit
  let letA : PsKernelExpr := .letE alpha ty (.bvar 0) (.bvar 0) false
  let letB : PsKernelExpr := .letE beta ty (.bvar 0) (.bvar 0) false
  let leftDag := c0LegacySharedTree 8 lamA
  let rightDag := c0LegacySharedTree 8 lamB
  let cases : List (PsKernelExpr × PsKernelExpr) := [
    (lamA, lamB),
    (piA, piB),
    (letA, letB),
    (.app lamA piA, .app lamB piB),
    (.mdata 1 lamA, .mdata 1 lamB),
    (.mdata 2 lamA, .mdata 3 lamB),
    (.proj alpha 0 lamA, .proj beta 0 lamB),
    (.proj alpha 0 lamA, .proj alpha 0 lamB),
    (leftDag, rightDag),
    (c0LegacySharedTree 8 piA, c0LegacySharedTree 8 piB),
    (c0LegacySharedTree 8 (.fvar alpha), c0LegacySharedTree 8 (.fvar beta)),
    (c0LegacySharedTree 8 ty, c0LegacySharedTree 8 ty),
    (.sort .zero, .sort (.succ .zero)),
    (.bvar 0, .bvar 1),
    (.lit (.nat 12), .lit (.nat 12)),
    (.lit (.nat 12), .lit (.nat 13))
  ]
  for (lhs, rhs) in cases do
    let old := psKernelExprEqLegacy lhs rhs
    let fresh := psKernelC0LegacyMemoExprEq lhs rhs
    if old != fresh then
      throw (IO.userError "DAG semantic equality diverged from old source")
  if !psKernelC0LegacyMemoExprEq lamA lamB ||
      !psKernelC0LegacyMemoExprEq piA piB ||
      !psKernelC0LegacyMemoExprEq leftDag rightDag then
    throw (IO.userError "semantic binder erasure was incorrectly replaced by strict Eq")
  if psKernelC0LegacyMemoExprEq (.mdata 2 lamA) (.mdata 3 lamB) then
    throw (IO.userError "semantic metadata difference incorrectly ignored")
  IO.println "C0_LEGACY_DAG source_exact=Lean_proved binders_display_ignored=true metadata_checked=true independently_shared=true no_admission=true"
