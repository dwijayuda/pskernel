import Ps.KernelCore.Core.ExprDecidableEq

/-!
Full exact equality only. This test never performs inference, DefEq or
admission. The returned `Decidable (lhs = rhs)` carries an actual equality
or inequality proof, not merely a hash or pointer-based Boolean claim.
-/

def c0TestDecideResult (lhs rhs : PsKernelExpr) : Bool :=
  match psKernelC0DeepPtrDecEq lhs rhs with
  | .isTrue _ => true
  | .isFalse _ => false

def c0OldDecideResult (lhs rhs : PsKernelExpr) : Bool :=
  match (inferInstance : Decidable (lhs = rhs)) with
  | .isTrue _ => true
  | .isFalse _ => false

def c0SharedExpression : Nat → PsKernelExpr → PsKernelExpr
  | 0, leaf => leaf
  | n + 1, leaf =>
      let previous := c0SharedExpression n leaf
      .app previous previous

def main : IO Unit := do
  let n : PsKernelName := .str .anonymous "original"
  let m : PsKernelName := .str .anonymous "different"
  let atom : PsKernelExpr := .const n [.zero]
  let diff : PsKernelExpr := .const m [.zero]
  let sourceCases : List (PsKernelExpr × PsKernelExpr) := [
    (.bvar 0, .bvar 0),
    (.bvar 0, .bvar 1),
    (.bvar 0, .sort .zero),
    (.fvar n, .fvar m),
    (.mvar n, .mvar n),
    (atom, diff),
    (atom, atom),
    (.lit (.nat 42), .lit (.nat 40)),
    (.sort (.succ .zero), .sort .zero),
    (.app atom atom, .app atom atom),
    (.app atom atom, .app diff atom),
    (.lam n atom atom .default, .lam m atom atom .default),
    (.lam n atom atom .default, .lam n atom atom .implicit),
    (.forallE n atom atom .default, .forallE n atom atom .default),
    (.forallE n atom atom .default, .forallE n diff atom .default),
    (.letE n atom atom atom false, .letE n atom atom atom true),
    (.letE n atom atom atom false, .letE n atom diff atom false),
    (.mdata 2 atom, .mdata 3 atom),
    (.proj n 0 atom, .proj n 1 atom),
    (.proj n 0 atom, .proj n 0 atom),
    (c0SharedExpression 7 atom, c0SharedExpression 7 atom),
    (c0SharedExpression 7 atom, c0SharedExpression 7 diff)
  ]
  for (lhs, rhs) in sourceCases do
    if c0TestDecideResult lhs rhs != c0OldDecideResult lhs rhs then
      throw (IO.userError "exact DAG pointer decider differs from generated full DecidableEq")
  let child := c0SharedExpression 24 atom
  let lhs := PsKernelExpr.app child child
  let rhs := PsKernelExpr.app child child
  if !c0TestDecideResult lhs rhs then
    throw (IO.userError "pointer-shared positive 2^24 DAG falsely rejected")
  let negative := PsKernelExpr.app child diff
  if c0TestDecideResult lhs negative then
    throw (IO.userError "pointer-shared negative 2^24 DAG falsely accepted")
  IO.println "C0_DEEP_PTR_DECEQ exact_typed_proof=true ordinary_cases=22 shared_2pow24=pass negative=pass no_admission=true"
