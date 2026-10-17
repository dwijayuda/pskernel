import Lean

open Lean

/-!
Independent official Lean 4.35.0 P1 assumption oracle.

Pin: eb6cafb7290e8bd5f2937522d8d804f58f02bafc.
This module is outside PSC0's portable compiler, selected Standard and
canonical admission closure. It records the pinned construction's actual
logical dependencies under the user-approved standard axiom profile. It does
not itself implement or admit portable `.ps` partial_fixpoint.

Pinned construction:
* Lean/Elab/PreDefinition/PartialFixpoint/Main.lean:104,191 synthesizes the
  result CCPO and constructs the fixed point through mkFixOfMonFun.
* Lean/Meta/Order.lean:52-54 selects Lean.Order.fix for a CCPO.
* Init/Internal/Order/Basic.lean:486 uses CCPO.csup; :114-115 selects
  the supremum through Classical.choose.
* Init/Classical.lean:19-20,29-30 implements choose using Classical.choice.
* PartialFixpoint/Eqns.lean:52-54 constructs equations using Order.fix_eq.

The Unit and Option cases already have CCPO instances, so this blocker is
independent of the separate Classical.ofNonempty fallback for flat orders.
The approved standard inventory is propext, Quot.sound and Classical.choice.
All loops below are inspected logically and are never executed.
-/

namespace Pscv0M3PartialFixpointAssumptions

-- These instances exist before partial-fixpoint elaboration. No fallback
-- inhabitant is needed to construct either result's CCPO.
example : Lean.Order.CCPO Unit := inferInstance
example : Lean.Order.CCPO (Option Unit) := inferInstance

def unitLoop (n : Nat) : Unit := unitLoop (n + 1)
partial_fixpoint

def optionLoop (n : Nat) : Option Unit := optionLoop (n + 1)
partial_fixpoint

-- Force realization and kernel checking of actual generated equations.
-- They are not fabricated `rfl` equations or P0 opaque declarations.
theorem unitLoop_equation (n : Nat) : unitLoop n = unitLoop (n + 1) :=
  unitLoop.eq_1 n

theorem optionLoop_equation (n : Nat) : optionLoop n = optionLoop (n + 1) :=
  optionLoop.eq_1 n

private def checkChoiceDependency (name : Lean.Name) :
    Lean.Elab.Command.CommandElabM Unit := do
  let axioms ← Lean.collectAxioms name
  unless axioms.contains ``Classical.choice do
    throwError "P1 assumption oracle: {name} no longer depends on Classical.choice: {axioms}"
  let unexpected := axioms.filter fun axiomName =>
    axiomName != ``propext && axiomName != ``Quot.sound &&
      axiomName != ``Classical.choice
  unless unexpected.isEmpty do
    throwError "P1 assumption oracle: unexpected dependency of {name}: {unexpected}"
  logInfo m!"PSCV0_M3_P1_ASSUMPTION_CLOSURE: {name}: {axioms}"

run_cmd do
  -- Monotonicity itself can be proved without importing classical choice.
  -- The fixed-point construction is the distinct source of the blocker.
  let monotonicityAxioms ← Lean.collectAxioms ``Lean.Order.monotone_id
  unless monotonicityAxioms.isEmpty do
    throwError "P1 assumption oracle: monotone_id changed axiom closure: {monotonicityAxioms}"
  for name in #[``Lean.Order.CCPO.csup, ``Lean.Order.fix,
      ``Lean.Order.fix_eq, ``unitLoop, ``unitLoop.eq_1,
      ``unitLoop_equation, ``optionLoop, ``optionLoop.eq_1,
      ``optionLoop_equation] do
    checkChoiceDependency name

end Pscv0M3PartialFixpointAssumptions

def main : IO Unit :=
  IO.println "PSCV0_M3_P1_ASSUMPTIONS: PASS pinned Unit/Option fixed points and checked equations require approved Classical.choice; portable P1 construction remains unavailable"
