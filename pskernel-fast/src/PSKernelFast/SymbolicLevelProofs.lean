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
  unfold smartMax
  split_ifs with hzA hzB heq hOrder
  · subst a
    simp [ULevel.denote]
  · subst b
    simp [ULevel.denote]
  · subst b
    simp [ULevel.denote]
  · rfl
  · exact Nat.max_comm (b.denote ρ) (a.denote ρ)

theorem smartIMax_denote (ρ : KName → Nat) (a b : ULevel) :
    (smartIMax a b).denote ρ =
      numericImax (a.denote ρ) (b.denote ρ) := by
  unfold smartIMax
  split_ifs with hzB hzA heq
  · subst b
    rfl
  · subst a
    exact (imax_zero_left (b.denote ρ)).symm
  · subst b
    exact (imax_self (a.denote ρ)).symm
  · cases b with
    | succ inner =>
        simpa [ULevel.denote, smartMax_denote] using
          (imax_succ_right (a.denote ρ) (inner.denote ρ)).symm
    | zero => simp_all
    | param n => rfl
    | mvar n => rfl
    | max left right => rfl
    | imax left right => rfl

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
  unfold compare at h
  split_ifs at h with hInvalid hEqual
  · cases h
  · exact positiveEquivalent_sound a b hEqual
  · cases h

end PSKernelFast.Core
