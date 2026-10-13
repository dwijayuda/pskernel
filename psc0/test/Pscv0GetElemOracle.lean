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
example : Nat.le 2 5 := show 2 ≤ 5 from by decide
example : ¬Nat.le 5 2 := show ¬(5 ≤ 2) from by decide
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
example : decide (184467440737095516170 ≤ 184467440737095516171) = true := rfl

universe u v

structure UniverseBox (α : Type u) where
  value : α
instance {α : Type u} : GetElem (UniverseBox α) Nat α (fun _ _ => True) where
  getElem xs _ _ := xs.value
example {α : Type u} : LawfulGetElem (UniverseBox α) Nat α (fun _ _ => True) := inferInstance
def bindUniverses {α : Type u} {β : Type v} (f : α → β) (xs : Option α) : Option β :=
  xs.bind (fun x => some (f x))
def doUniverse {α β : Type u} (f : α → β) (xs : Option α) : Option β := do
  let x ← xs
  return f x
example : doUniverse (fun x : ULift.{1} Nat => x) (some ⟨373⟩) = some ⟨373⟩ := rfl
example : bindUniverses (fun n : Nat => ULift.up.{1} n) (some 373) = some ⟨373⟩ := rfl
example : (⟨ULift.up.{1} 359⟩ : UniverseBox (ULift.{1} Nat))[0]? = some ⟨359⟩ := rfl
example {α : Type u} : (default : Option α) = none := rfl
example (i j size : Nat) (h : i < j) (k : j ≤ size) : i < size := by omega


-- List algorithms and Fin adapters retain the collection-specific bound.
example : ([401, 409] : List Nat)[1] = 409 := rfl
example : ([431, 433] : List Nat)[1]? = some 433 := rfl
example : ([] : List Nat)[0]? = none := rfl
example : ([449] : List Nat)[184467440737095516170]? = none := rfl
def finSeed : Fin 10 := ⟨1, by decide⟩
example : ([463, 467] : List Nat)[finSeed]? = some 467 := rfl
example : ([479] : List Nat)[finSeed]? = none := rfl
example : LawfulGetElem (List Nat) Nat Nat (fun xs i => i < xs.length) := inferInstance
example : LawfulGetElem (List Nat) (Fin 10) Nat (fun xs i => i.val < xs.length) := inferInstance
example : (List.get [509, 521] ⟨1, by decide⟩) = 521 := rfl

-- The logical Array structure and optimized operations have the same observables.
example : (#[541, 547] : Array Nat)[1] = 547 := rfl
example : (#[577] : Array Nat)[184467440737095516170]? = none := rfl
example : (#[587] : Array Nat)[finSeed]? = none := rfl
example : LawfulGetElem (Array Nat) Nat Nat (fun xs i => i < xs.size) := inferInstance
example : (Array.mk [613, 617])[1] = 617 := rfl
example : ([619, 631].toArray.toList)[1]? = some 631 := rfl
example : (Array.mk [false, true]).toList[1]? = some true := rfl
example : (#[2, 3, 5, 7] : Array Nat).foldl Nat.add 0 1 3 = 8 := rfl
example : (#[2, 3] : Array Nat).foldl Nat.add 661
    184467440737095516170 184467440737095516171 = 661 := rfl
example : (#[653] : Array Nat).setIfInBounds 184467440737095516170 0 = #[653] := rfl

end Pscv0GetElemOracle
