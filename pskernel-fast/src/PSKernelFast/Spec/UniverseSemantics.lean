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

/-- The set denoted by Sort u in a supplied infinite-universe set model. -/
def sortSet (V : Type u) [SetTheoryBasis V] (level : Nat) : V :=
  SetTheoryBasis.univ level

/--
THE FIRST SET-MODEL THEOREM: under the explicitly supplied model
assumptions, the denotation of Sort u is a member of the denotation
of its actual inferred type Sort (succ u), for EVERY universe valuation.
This is a conditional semantic-membership fact, not an empty syntax
identity and not a constructed SetTheoryBasis instance.
-/
theorem sort_member_succ (V : Type u) [SetTheoryBasis V]
    (ρ : KName → Nat) (level : ULevel) :
    SetTheoryBasis.Mem
      (sortSet V (level.denote ρ))
      (sortSet V ((ULevel.succ level).denote ρ)) := by
  simpa [sortSet, ULevel.denote] using
    (SetTheoryBasis.universe_step (V := V) (level.denote ρ))

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

#print axioms SetTheoryBasis.universe_two_steps
#print axioms sort_member_succ
#print axioms numericIMax_zero_iff_codomain_zero
#print axioms piLevel_isProp_iff_codomain_isProp
#print axioms piLevel_positive_bounds

end PSKernelFast.Spec
