import PSKernelFast.Spec.SetTheoryBasis

/-!
P1d: true *conditional* set-model membership for the Sort constructor,
and proof of the Lean numeric imax/Prop regime. This uses a supplied
SetTheoryBasis V, whose existence has NOT been established in this package.

Pi itself has no set-theoretic closure theorem here. That construction
requires an actual dependent-function set interpreter, verified binder
codomain Prop-regime data and proof-irrelevant semantics. Numeric rank
algebra alone must never be misrepresented as a model of Pi types.
-/

namespace PSKernelFast.Spec

open PSKernelFast.Core

universe u

/--
A TWO-TRUTH-VALUE candidate for Lean's impredicative Sort 0 (= Prop):
the subsets of the singleton powerset of the derived empty set.
The two distinct truth-value sets are empty and powerset empty.
This carrier is not yet a proof-irrelevant Pi/lambda interpretation.
-/
noncomputable def propTruthUniverse (V : Type u) [SetTheoryBasis V] : V :=
  SetTheoryBasis.powerset
    (SetTheoryBasis.powerset (SetTheoryBasis.emptySet V))

/--
The sort tower must distinguish impredicative Prop (level zero) from
predicative Type universes. Positive ranks start two stages above the
underlying Grothendieck chain, following the existence proof below.
-/
noncomputable def sortSet (V : Type u) [SetTheoryBasis V] : Nat → V
  | 0 => propTruthUniverse V
  | n + 1 => SetTheoryBasis.univ (n + 2)

/-- Empty (false) is a member of the two-truth-value universe. -/
theorem propFalse_mem (V : Type u) [SetTheoryBasis V] :
    SetTheoryBasis.Mem (SetTheoryBasis.emptySet V)
      (propTruthUniverse V) := by
  apply (SetTheoryBasis.member_powerset).2
  intro z hz
  exact False.elim (SetTheoryBasis.not_member_empty V z hz)

/-- Powerset empty (true) is another member of the truth-value universe. -/
theorem propTrue_mem (V : Type u) [SetTheoryBasis V] :
    SetTheoryBasis.Mem (SetTheoryBasis.powerset (SetTheoryBasis.emptySet V))
      (propTruthUniverse V) := by
  exact (SetTheoryBasis.member_powerset).2 (fun z hz => hz)

/-- The two truth values are distinct, derived without a new axiom. -/
theorem propFalse_ne_true (V : Type u) [SetTheoryBasis V] :
    SetTheoryBasis.emptySet V ≠
      SetTheoryBasis.powerset (SetTheoryBasis.emptySet V) := by
  intro h
  have hEmptyInPower : SetTheoryBasis.Mem
      (SetTheoryBasis.emptySet V)
      (SetTheoryBasis.powerset (SetTheoryBasis.emptySet V)) := by
    apply (SetTheoryBasis.member_powerset).2
    intro z hz
    exact False.elim (SetTheoryBasis.not_member_empty V z hz)
  have hSelf : SetTheoryBasis.Mem
      (SetTheoryBasis.emptySet V) (SetTheoryBasis.emptySet V) := by
    simpa [← h] using hEmptyInPower
  exact SetTheoryBasis.not_member_empty V _ hSelf

/--
Derived membership of the candidate Prop universe in the FIRST positive
Sort. This uses the tower and two successive Grothendieck powerset
closure steps, and is not a new assumed Pi/Prop interpretation law.
-/
theorem propUniverse_mem_typeOne (V : Type u) [SetTheoryBasis V] :
    SetTheoryBasis.Mem (propTruthUniverse V)
      (SetTheoryBasis.univ 2) := by
  have hChain : SetTheoryBasis.Mem
      (SetTheoryBasis.univ 1 : V) (SetTheoryBasis.univ 2) :=
    SetTheoryBasis.universe_step (V := V) 1
  have hEmpty : SetTheoryBasis.Mem
      (SetTheoryBasis.emptySet V) (SetTheoryBasis.univ 2) :=
    SetTheoryBasis.universe_subset_closed (V := V) 2
      (SetTheoryBasis.univ 1) (SetTheoryBasis.emptySet V)
      hChain (by
        intro z hz
        exact False.elim (SetTheoryBasis.not_member_empty V z hz))
  have hPower : SetTheoryBasis.Mem
      (SetTheoryBasis.powerset (SetTheoryBasis.emptySet V))
      (SetTheoryBasis.univ 2) :=
    SetTheoryBasis.universe_powerset_closed (V := V) 2
      (SetTheoryBasis.emptySet V) hEmpty
  exact SetTheoryBasis.universe_powerset_closed (V := V) 2
    (SetTheoryBasis.powerset (SetTheoryBasis.emptySet V)) hPower

/--
FIRST CONDITIONAL LEAN-SHAPED SET-MODEL MEMBERSHIP THEOREM:
the interpretation of Sort u belongs to the interpretation of
its inferred Sort (u+1), for every ground universe valuation.
Unlike a raw Grothendieck tower, zero now has a distinct two-valued
Prop carrier. This still does NOT interpret proof irrelevance or Pi.
-/
theorem sort_member_succ (V : Type u) [SetTheoryBasis V]
    (ρ : KName → Nat) (level : ULevel) :
    SetTheoryBasis.Mem
      (sortSet V (level.denote ρ))
      (sortSet V ((ULevel.succ level).denote ρ)) := by
  cases hLevel : level.denote ρ with
  | zero =>
      simpa [sortSet, ULevel.denote, hLevel] using
        (propUniverse_mem_typeOne V)
  | succ n =>
      simpa [sortSet, ULevel.denote, hLevel, Nat.add_assoc] using
        (SetTheoryBasis.universe_step (V := V) (n + 2))

/--
Lean's impredicative Pi sort rule uses imax u v. The resulting sort is
Prop (universe 0) exactly when the CODOMAIN is Prop. This is independent
of the domain level and holds for every Nat value, including zero.
-/
theorem numericIMax_zero_iff_codomain_zero (domain codomain : Nat) :
    numericImax domain codomain = 0 ↔ codomain = 0 := by
  constructor
  · intro h
    by_cases hc : codomain = 0
    · exact hc
    · have hpositive : 0 < codomain := Nat.pos_of_ne_zero hc
      have hle : codomain ≤ Nat.max domain codomain :=
        Nat.le_max_right domain codomain
      have hmax : Nat.max domain codomain = 0 := by
        simpa [numericImax, hc] using h
      omega
  · intro h
    subst codomain
    simp [numericImax]

/-- With a non-Prop codomain, imax is the ordinary maximum universe. -/
theorem numericIMax_positive_bounds (domain codomain : Nat)
    (h : codomain ≠ 0) :
    domain ≤ numericImax domain codomain ∧
      codomain ≤ numericImax domain codomain := by
  have heq : numericImax domain codomain = Nat.max domain codomain := by
    simp [numericImax, h]
  rw [heq]
  exact ⟨Nat.le_max_left domain codomain,
    Nat.le_max_right domain codomain⟩

/--
An exact symbolic-level Prop-regime test, not a finite-sample heuristic:
the denotation of the actual ULevel.imax result is universe zero
precisely when the body's sort denotes universe zero.
-/
theorem piLevel_isProp_iff_codomain_isProp
    (ρ : KName → Nat) (domain codomain : ULevel) :
    ((ULevel.imax domain codomain).denote ρ = 0) ↔
      codomain.denote ρ = 0 := by
  simpa [ULevel.denote] using
    (numericIMax_zero_iff_codomain_zero
      (domain.denote ρ) (codomain.denote ρ))

/-- Exact positive-level upper bounds used by later dependent Pi models. -/
theorem piLevel_positive_bounds
    (ρ : KName → Nat) (domain codomain : ULevel)
    (h : codomain.denote ρ ≠ 0) :
    domain.denote ρ ≤ (ULevel.imax domain codomain).denote ρ ∧
      codomain.denote ρ ≤ (ULevel.imax domain codomain).denote ρ := by
  simpa [ULevel.denote] using
    (numericIMax_positive_bounds
      (domain.denote ρ) (codomain.denote ρ) h)

#print axioms SetTheoryBasis.exists_empty
#print axioms SetTheoryBasis.not_member_empty
#print axioms SetTheoryBasis.universe_subset_closed
#print axioms SetTheoryBasis.universe_powerset_closed
#print axioms propUniverse_mem_typeOne
#print axioms propFalse_mem
#print axioms propTrue_mem
#print axioms propFalse_ne_true
#print axioms SetTheoryBasis.universe_two_steps
#print axioms sort_member_succ
#print axioms numericIMax_zero_iff_codomain_zero
#print axioms piLevel_isProp_iff_codomain_isProp
#print axioms piLevel_positive_bounds

end PSKernelFast.Spec
