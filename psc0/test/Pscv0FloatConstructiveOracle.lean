import Lean
import Init.Data.Nat.Lemmas
import Lean.Util.CollectAxioms

/-!
Lean 4.35.0 constructive dependency experiment for Float/Float32.ofBits.

The official pinned Nat.pow_eq_zero theorem is propositionally correct but
its *generated proof body* reaches Classical.choice through a private simp
helper in the F1 exported source closure (CI 38543575033). Here we prove
the same statement by constructor/positivity cases with no classical choice,
then inspect transitive axioms using the official Lean CollectAxioms.

This is an independent oracle, NOT a new selected Standard declaration,
kernel extension, authority to rewrite a published proof or permission to
enable executable Float. The F1 exporter still fails closed until a reviewed
proof-replacement policy can replay this exact statement and all dependencies.
-/

namespace Pscv0FloatConstructive

theorem powEqZero {a : Nat} : ∀ {n : Nat}, a ^ n = 0 ↔ a = 0 ∧ n ≠ 0
  | 0 => by
      constructor
      · intro h
        have contradiction : (1 : Nat) = 0 := h
        cases contradiction
      · intro h
        exact False.elim (h.2 rfl)
  | n + 1 => by
      constructor
      · intro h
        cases a with
        | zero =>
          exact ⟨rfl, Nat.succ_ne_zero n⟩
        | succ k =>
          have positive : 0 < (Nat.succ k) ^ (n + 1) :=
            Nat.pow_pos (Nat.zero_lt_succ k)
          exact False.elim ((Nat.ne_of_gt positive) h)
      · intro h
        cases h.1
        rfl

-- The theorem has the exact logical statement of pinned Nat.pow_eq_zero,
-- without depending on its original proof term.
example {a n : Nat} : a ^ n = 0 ↔ a = 0 ∧ n ≠ 0 :=
  powEqZero

end Pscv0FloatConstructive

run_cmd do
  let used ← Lean.collectAxioms ``Pscv0FloatConstructive.powEqZero
  if used.contains ``Classical.choice then
    throwError "PSCV0-FLOAT-F1: constructive powEqZero unexpectedly imports Classical.choice"
  if used.contains ``sorryAx then
    throwError "PSCV0-FLOAT-F1: constructive powEqZero depends on sorryAx"
  logInfo s!"PSCV0_FLOAT_CONSTRUCTIVE: Nat.pow_eq_zero alternative is free of Classical.choice; axioms={used.toList}"

