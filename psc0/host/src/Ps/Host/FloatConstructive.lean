import Init.Data.Nat.Lemmas

/-!
Host-only constructive Nat.pow_eq_zero proof for Lean 4.35.0. A separate
source oracle audits its full transitive axiom closure. This is a real theorem,
not a new kernel axiom or a replacement for a computational definition.
No selected Standard or executable Float support.
-/
namespace PsV7Native.FloatConstructive

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
        | zero => exact ⟨rfl, Nat.succ_ne_zero n⟩
        | succ k =>
          have positive : 0 < (Nat.succ k) ^ (n + 1) :=
            Nat.pow_pos (Nat.zero_lt_succ k)
          exact False.elim ((Nat.ne_of_gt positive) h)
      · intro h
        cases h.1
        rfl

-- Exact pinned theorem type of BitVec.getLsbD_of_ge, proved without
-- upstream Omega/List/Int proof machinery. This is a theorem replacement
-- candidate ONLY; the portable checker still re-admits the proof term.
theorem getLsbDOfGe {w : Nat} (x : BitVec w) (i : Nat)
    (ge : w ≤ i) : x.getLsbD i = false := by
  have hp : (2 : Nat) ^ w ≤ 2 ^ i :=
    Nat.pow_le_pow_right (by decide) ge
  have hbound : x.toNat < 2 ^ i :=
    Nat.lt_of_lt_of_le x.isLt hp
  change x.toNat.testBit i = false
  exact Nat.testBit_lt_two_pow hbound

end PsV7Native.FloatConstructive
