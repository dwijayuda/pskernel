import Ps.KernelCore.Metatheory.SemanticLevel
import Ps.KernelCore.Metatheory.Comparator

/-!
Semantic preservation by the production universe smart constructors.
The statements quantify over all parameter and metavariable valuations.
Normalization and universe admission have separate obligations.
-/

namespace PsKernelSemantics

variable (params metavariables : PsKernelName → Nat)

private theorem levelEq_eval {a b : PsKernelLevel} (h : psKernelLevelEq a b = true) :
    evalLevel params metavariables a = evalLevel params metavariables b := by
  exact congrArg (evalLevel params metavariables)
    (psKernelLevelEq_sound_of_string_law psKernelStringEq_sound_lean435 a b h)

theorem isZero_eval {l : PsKernelLevel} (h : psKernelLevelIsZero l = true) :
    evalLevel params metavariables l = 0 := by
  cases l <;> simp_all [psKernelLevelIsZero, evalLevel]

theorem isNotZero_eval {l : PsKernelLevel} (h : psKernelLevelIsNotZero l = true) :
    evalLevel params metavariables l ≠ 0 := by
  induction l with
  | zero | param _ | mvar _ => simp [psKernelLevelIsNotZero] at h
  | succ l ih => simp [evalLevel]
  | max a b iha ihb =>
      cases ha : psKernelLevelIsNotZero a with
      | false =>
          have hb : psKernelLevelIsNotZero b = true := by
            simpa [psKernelLevelIsNotZero, ha] using h
          have := ihb hb
          simp only [evalLevel]
          omega
      | true =>
          have := iha ha
          simp only [evalLevel]
          omega
  | imax a b iha ihb =>
      have hb := ihb h
      simp only [evalLevel, ite_eq_right hb]
      omega

theorem toOffset_eval (l : PsKernelLevel) :
    evalLevel params metavariables l =
      evalLevel params metavariables (psKernelLevelToOffset l).1 +
        (psKernelLevelToOffset l).2 := by
  induction l <;> simp_all [psKernelLevelToOffset, evalLevel, Nat.add_assoc]

theorem addOffset_eval (l : PsKernelLevel) (n : Nat) :
    evalLevel params metavariables (psKernelLevelAddOffset l n) =
      evalLevel params metavariables l + n := by
  induction n <;> simp_all [psKernelLevelAddOffset, evalLevel, Nat.add_assoc]

theorem explicit_eval {l : PsKernelLevel} (h : psKernelLevelIsExplicit l = true) :
    evalLevel params metavariables l = (psKernelLevelToOffset l).2 := by
  rw [toOffset_eval]
  have hz := isZero_eval params metavariables h
  rw [hz, Nat.zero_add]

private theorem natGt_true {a b : Nat} (h : psKernelNatGt a b = true) : b < a := by
  unfold psKernelNatGt psKernelNatLt at h
  split at h <;> simp_all <;> omega

private theorem natGt_false {a b : Nat} (h : psKernelNatGt a b ≠ true) : a ≤ b := by
  unfold psKernelNatGt psKernelNatLt at h
  split at h <;> simp_all <;> omega

private theorem offset_choice_eval (a b : PsKernelLevel) :
    evalLevel params metavariables
      (if psKernelLevelEq (psKernelLevelToOffset a).1 (psKernelLevelToOffset b).1 then
        if psKernelNatGt (psKernelLevelToOffset a).2 (psKernelLevelToOffset b).2
          then a else b
       else .max a b) =
      max (evalLevel params metavariables a) (evalLevel params metavariables b) := by
  split
  · next he =>
      have hr := levelEq_eval params metavariables he
      have ha := toOffset_eval params metavariables a
      have hb := toOffset_eval params metavariables b
      split
      · next h => have := natGt_true h; omega
      · next h => have := natGt_false h; omega
  · rfl

private theorem explicit_choice_eval (a b : PsKernelLevel)
    (ha : psKernelLevelIsExplicit a = true)
    (hb : psKernelLevelIsExplicit b = true) :
    evalLevel params metavariables
      (if psKernelNatGe (psKernelLevelToOffset a).2 (psKernelLevelToOffset b).2
        then a else b) =
      max (evalLevel params metavariables a) (evalLevel params metavariables b) := by
  have ea := explicit_eval params metavariables ha
  have eb := explicit_eval params metavariables hb
  by_cases h : psKernelNatGe (psKernelLevelToOffset a).2 (psKernelLevelToOffset b).2 = true
  · rw [if_pos h]
    have hl := Nat.le_of_ble_eq_true h
    omega
  · rw [if_neg h]
    have hn : ¬ (psKernelLevelToOffset b).2 ≤ (psKernelLevelToOffset a).2 := by
      intro hl
      exact h (Nat.ble_eq_true_of_le hl)
    omega

private def maxContains (a b : PsKernelLevel) : Bool :=
  match a with
  | .max x y => if psKernelLevelEq x b then true else psKernelLevelEq y b
  | _ => false

private theorem maxContains_eval {a b : PsKernelLevel}
    (h : maxContains a b = true) :
    evalLevel params metavariables b ≤ evalLevel params metavariables a := by
  cases a <;> simp only [maxContains, Bool.false_eq_true] at h
  rename_i x y
  cases hx : psKernelLevelEq x b with
  | true =>
      have he := levelEq_eval params metavariables hx
      simp only [evalLevel]
      omega
  | false =>
      have hy : psKernelLevelEq y b = true := by simpa [hx] using h
      have he := levelEq_eval params metavariables hy
      simp only [evalLevel]
      omega

private def maxChoice (a b : PsKernelLevel) : PsKernelLevel :=
  if maxContains b a then b
  else if maxContains a b then a
  else
    if psKernelLevelEq (psKernelLevelToOffset a).1 (psKernelLevelToOffset b).1 then
      if psKernelNatGt (psKernelLevelToOffset a).2 (psKernelLevelToOffset b).2
        then a else b
    else .max a b

private theorem maxChoice_eval (a b : PsKernelLevel) :
    evalLevel params metavariables (maxChoice a b) =
      max (evalLevel params metavariables a) (evalLevel params metavariables b) := by
  unfold maxChoice
  by_cases hb : maxContains b a = true
  · rw [if_pos hb]
    exact (Nat.max_eq_right (maxContains_eval params metavariables hb)).symm
  · rw [if_neg hb]
    by_cases ha : maxContains a b = true
    · rw [if_pos ha]
      exact (Nat.max_eq_left (maxContains_eval params metavariables ha)).symm
    · rw [if_neg ha]
      exact offset_choice_eval params metavariables a b

theorem mkMax_eval (a b : PsKernelLevel) :
    evalLevel params metavariables (psKernelLevelMkMax a b) =
      max (evalLevel params metavariables a) (evalLevel params metavariables b) := by
  unfold psKernelLevelMkMax
  by_cases hex : (if psKernelLevelIsExplicit a then psKernelLevelIsExplicit b else false) = true
  · rw [if_pos hex]
    have hs : psKernelLevelIsExplicit a = true ∧ psKernelLevelIsExplicit b = true := by
      cases ha : psKernelLevelIsExplicit a <;> simp_all
    exact explicit_choice_eval params metavariables a b hs.1 hs.2
  · rw [if_neg hex]
    by_cases he : psKernelLevelEq a b = true
    · rw [if_pos he, levelEq_eval params metavariables he, Nat.max_self]
    · rw [if_neg he]
      by_cases ha : psKernelLevelIsZero a = true
      · rw [if_pos ha, isZero_eval params metavariables ha, Nat.zero_max]
      · rw [if_neg ha]
        by_cases hb : psKernelLevelIsZero b = true
        · rw [if_pos hb, isZero_eval params metavariables hb, Nat.max_zero]
        · rw [if_neg hb]
          cases a <;> cases b <;> exact maxChoice_eval params metavariables _ _

private theorem imaxEqChoice_eval (a b : PsKernelLevel) :
    evalLevel params metavariables
      (if psKernelLevelEq a b then a else .imax a b) =
      evalLevel params metavariables (.imax a b) := by
  by_cases h : psKernelLevelEq a b = true
  · rw [if_pos h]
    change evalLevel params metavariables a =
      (if evalLevel params metavariables b = 0 then 0
       else max (evalLevel params metavariables a) (evalLevel params metavariables b))
    rw [levelEq_eval params metavariables h]
    split <;> simp_all
  · rw [if_neg h]

theorem mkIMax_eval (a b : PsKernelLevel) :
    evalLevel params metavariables (psKernelLevelMkIMax a b) =
      evalLevel params metavariables (.imax a b) := by
  unfold psKernelLevelMkIMax
  by_cases hn : psKernelLevelIsNotZero b = true
  · rw [if_pos hn, mkMax_eval]
    simp [evalLevel, isNotZero_eval params metavariables hn]
  · rw [if_neg hn]
    by_cases hb : psKernelLevelIsZero b = true
    · rw [if_pos hb]
      have hz := isZero_eval params metavariables hb
      simp [evalLevel, hz]
    · rw [if_neg hb]
      by_cases ha : psKernelLevelIsZero a = true
      · rw [if_pos ha]
        have hz := isZero_eval params metavariables ha
        simp [evalLevel, hz]
      · rw [if_neg ha]
        cases a with
        | succ a =>
            cases a with
            | zero =>
                change evalLevel params metavariables b =
                  (if evalLevel params metavariables b = 0 then 0
                    else max 1 (evalLevel params metavariables b))
                split <;> omega
            | succ _ | max _ _ | imax _ _ | param _ | mvar _ =>
                exact imaxEqChoice_eval params metavariables _ _
        | zero | max _ _ | imax _ _ | param _ | mvar _ =>
            exact imaxEqChoice_eval params metavariables _ _

end PsKernelSemantics
