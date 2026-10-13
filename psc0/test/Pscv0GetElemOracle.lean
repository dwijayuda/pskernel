import Init

/-!
  Independent Lean 4.35.0-rc4 source oracle for the selected PSCV0 GetElem
  foundation. This is compiled by the official Lean checker, not by the
  PSCV0 parser/elaborator, and is deliberately kept out of the selected
  Standard environment's TCB.
-/

namespace Pscv0GetElemOracle

structure IndexBox where
  value : Nat

instance : GetElem IndexBox Nat Nat (fun _ i => i = 0) where
  getElem xs _ _ := xs.value

def checkedAtZero (xs : IndexBox) : Nat := xs[0]
def checkedWithProof (xs : IndexBox) (i : Nat) (h : i = 0) : Nat := xs[i]'h
def checkedWithAssumption (xs : IndexBox) (i : Nat) (h : i = 0) : Nat := xs[i]

example : checkedAtZero ⟨23⟩ = 23 := rfl
example : checkedWithProof ⟨19⟩ 0 rfl = 19 := rfl
example : checkedWithAssumption ⟨17⟩ 0 rfl = 17 := rfl

structure AlwaysBox where
  value : Nat

instance : GetElem AlwaysBox Nat Nat (fun _ _ => True) where
  getElem xs _ _ := xs.value

example : (⟨29⟩ : AlwaysBox)[42] = 29 := rfl

structure ProductProofBox where
  value : Nat

instance : GetElem ProductProofBox Nat Nat (fun _ _ => True ∧ True) where
  getElem xs _ _ := xs.value

example : (⟨31⟩ : ProductProofBox)[42] = 31 := rfl

-- Upstream GetElem? is an actual superclass extension. These witnesses are
-- intentionally *oracle-only* until PSCV0 implements the lawful Option and
-- panic/default contracts without dropping genuine validity evidence.
example : (⟨23⟩ : IndexBox)[0]? = some 23 := by decide
example : (⟨23⟩ : IndexBox)[1]? = none := by decide

-- Independent order oracle for the M1 successor/inversion/reflection contract.
example : Nat.le 2 5 := by decide
example : ¬Nat.le 5 2 := by decide
example (n : Nat) : Nat.le 0 n := Nat.zero_le n
example (n m : Nat) (h : Nat.le n m) :
    Nat.le (Nat.succ n) (Nat.succ m) := Nat.succ_le_succ h
example (n m : Nat) (h : Nat.le (Nat.succ n) (Nat.succ m)) :
    Nat.le n m := Nat.le_of_succ_le_succ h
example (n : Nat) : ¬Nat.lt n 0 := Nat.not_lt_zero n
example (n m k : Nat) (h : Nat.le n m) (q : Nat.le m k) :
    Nat.le n k := Nat.le_trans h q
example (n m : Nat) (h : Nat.lt (Nat.succ n) (Nat.succ m)) :
    Nat.lt n m := Nat.lt_of_succ_lt_succ h
example : decide (Nat.le 184467440737095516170 184467440737095516171) = true := rfl

end Pscv0GetElemOracle
