import PSKernelFast.CoreSyntaxProofs
import PSKernelFast.SymbolicLevel

/-!
Independent proofs of POSITIVE answers for the actual G4.0 symbolic universe
normalizer. These theorems do not imply completeness relative to Lean 4.35.
-/

namespace PSKernelFast.Core

private theorem imax_zero_left (v : Nat) : numericImax 0 v = v := by
  cases v with
  | zero => rfl
  | succ n => simp [numericImax]

private theorem imax_self (v : Nat) : numericImax v v = v := by
  cases v with
  | zero => rfl
  | succ n => simp [numericImax]

private theorem imax_succ_right (u v : Nat) :
    numericImax u (v + 1) = Nat.max u (v + 1) := by
  simp [numericImax]

theorem smartMax_denote (ρ : KName → Nat) (a b : ULevel) :
    (smartMax a b).denote ρ =
      Nat.max (a.denote ρ) (b.denote ρ) := by
  by_cases ha : a = .zero
  · subst a
    simp [smartMax, ULevel.denote]
  · by_cases hb : b = .zero
    · subst b
      simp [smartMax, ha, ULevel.denote]
    · by_cases heq : a = b
      · subst b
        simp [smartMax, ha, ULevel.denote]
      · by_cases horder : levelOrder a b = true
        · simp [smartMax, ha, hb, heq, horder, ULevel.denote]
        · simp [smartMax, ha, hb, heq, horder, ULevel.denote, Nat.max_comm]

theorem smartIMax_denote (ρ : KName → Nat) (a b : ULevel) :
    (smartIMax a b).denote ρ =
      numericImax (a.denote ρ) (b.denote ρ) := by
  by_cases hb : b = .zero
  · subst b
    simp [smartIMax, ULevel.denote, numericImax]
  · by_cases ha : a = .zero
    · subst a
      simpa [smartIMax, hb] using (imax_zero_left (b.denote ρ)).symm
    · by_cases heq : a = b
      · subst b
        simpa [smartIMax, ha] using (imax_self (a.denote ρ)).symm
      · cases b with
        | zero => contradiction
        | succ inner =>
            simp [smartIMax, hb, ha, heq, ULevel.denote,
              smartMax_denote, numericImax]
        | param n =>
            simp [smartIMax, hb, ha, heq, ULevel.denote]
        | mvar n =>
            simp [smartIMax, hb, ha, heq, ULevel.denote]
        | max left right =>
            simp [smartIMax, hb, ha, heq, ULevel.denote]
        | imax left right =>
            simp [smartIMax, hb, ha, heq, ULevel.denote]

theorem normalize_denote (ρ : KName → Nat) (level : ULevel) :
    (normalize level).denote ρ = level.denote ρ := by
  induction level with
  | zero => rfl
  | param n => rfl
  | mvar n => rfl
  | succ l ih =>
      simp only [normalize, ULevel.denote, ih]
  | max a b ihA ihB =>
      simp only [normalize, smartMax_denote, ULevel.denote, ihA, ihB]
  | imax a b ihA ihB =>
      simp only [normalize, smartIMax_denote, ULevel.denote, ihA, ihB]

/-- Positive symbolic comparison is sound for every possible valuation. -/
theorem positiveEquivalent_sound (a b : ULevel)
    (h : positiveEquivalent a b = true) :
    ∀ ρ : KName → Nat, a.denote ρ = b.denote ρ := by
  have hEq : normalize a = normalize b :=
    of_decide_eq_true (by simpa [positiveEquivalent] using h)
  intro ρ
  calc
    a.denote ρ = (normalize a).denote ρ := (normalize_denote ρ a).symm
    _ = (normalize b).denote ρ := congrArg (fun t => t.denote ρ) hEq
    _ = b.denote ρ := normalize_denote ρ b

/--
An externally observable equality answer is sound irrespective of the
implementation's internal normalization/interning/hash ordering.
-/
theorem compare_equal_sound (params : List KName) (a b : ULevel)
    (h : compare params a b = .equal) :
    ∀ ρ : KName → Nat, a.denote ρ = b.denote ρ := by
  by_cases hBad : (!a.validParams params || !b.validParams params) = true
  · simp [compare, hBad] at h
  · by_cases hEq : positiveEquivalent a b = true
    · exact positiveEquivalent_sound a b hEq
    · simp [compare, hBad, hEq] at h

end PSKernelFast.Core
