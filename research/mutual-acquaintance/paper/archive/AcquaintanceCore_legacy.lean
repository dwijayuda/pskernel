/-!
A Dynamic Epistemic Model of Mutual Acquaintance
Core Lean 4 examples. No external Mathlib dependency intended.

IMPORTANT: This file has NOT been checked by the Lean kernel in this environment.
The executable Python verification checks only bounded finite examples.
The statements below capture elementary Boolean/propositional consequences,
NOT the paper's finite probability, information-value, or decision-theory theorems.
-/
import Init

namespace MutualAcquaintance

/-- Public signal from a hidden bit and a private key. -/
def publicSignal (theta key : Bool) : Bool := theta != key

/-- Knowledge of the private key determines the hidden bit. -/
theorem recover_with_key (theta key : Bool) :
    (publicSignal theta key != key) = theta := by
  cases theta <;> cases key <;> decide

/-- Distinct hidden states can produce the same public event. -/
theorem same_public_different_hidden :
    publicSignal false false = publicSignal true true := by
  decide

/-- A freely jointly undertaken step must include each party's willingness
    when mutual willingness is part of the definition. -/
theorem joint_implies_first (willingA willingB joint : Prop)
    (requiresBoth : joint → willingA ∧ willingB) : joint → willingA := by
  intro h
  exact (requiresBoth h).1

theorem joint_implies_second (willingA willingB joint : Prop)
    (requiresBoth : joint → willingA ∧ willingB) : joint → willingB := by
  intro h
  exact (requiresBoth h).2

/-- No trait-only constant can match two different dyadic histories.
    This is a skeleton of a counterexample rather than a general model theorem. -/
theorem trait_only_cannot_fit_both (traitOnlyValue : Bool)
    (hQuiet : traitOnlyValue = false) (hTogether : traitOnlyValue = true) : False := by
  have h : false = true := hQuiet.symm.trans hTogether
  cases h

end MutualAcquaintance