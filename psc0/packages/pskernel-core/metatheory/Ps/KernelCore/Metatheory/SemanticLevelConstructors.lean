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
  simp only [psKernelNatGe]
  split
  · next h => have := Nat.le_of_ble_eq_true h; omega
  · next h =>
      have hn : ¬ (psKernelLevelToOffset b).2 ≤ (psKernelLevelToOffset a).2 := by
        intro hl
        exact h (Nat.ble_eq_true_of_le hl)
      omega

private theorem bool_or_true {a b : Bool}
    (h : (if a then true else b) = true) : a = true ∨ b = true := by
  cases a <;> simp_all

theorem mkMax_eval (a b : PsKernelLevel) :
    evalLevel params metavariables (psKernelLevelMkMax a b) =
      max (evalLevel params metavariables a) (evalLevel params metavariables b) := by
  unfold psKernelLevelMkMax
  split
  · next h =>
      have hs : psKernelLevelIsExplicit a = true ∧ psKernelLevelIsExplicit b = true := by
        cases ha : psKernelLevelIsExplicit a <;> simp_all
      exact explicit_choice_eval params metavariables a b hs.1 hs.2
  · split
    · next h => rw [levelEq_eval params metavariables h, Nat.max_self]
    · split
      · next h => rw [isZero_eval params metavariables h, Nat.zero_max]
      · split
        · next h => rw [isZero_eval params metavariables h, Nat.max_zero]
        · cases b <;> cases a <;>
            simp only [offset_choice_eval]
          all_goals repeat' first
            | (solve | rfl)
            | (solve | apply offset_choice_eval)
            | split
          all_goals
            first
            | (solve | apply offset_choice_eval)
            | (solve |
                rename_i h
                rcases bool_or_true h with h | h <;>
                  have he := levelEq_eval params metavariables h <;>
                  simp only [evalLevel] at he ⊢ <;> omega)

theorem mkIMax_eval (a b : PsKernelLevel) :
    evalLevel params metavariables (psKernelLevelMkIMax a b) =
      evalLevel params metavariables (.imax a b) := by
  unfold psKernelLevelMkIMax
  split
  · next h =>
      rw [mkMax_eval]
      simp [evalLevel, isNotZero_eval params metavariables h]
  · split
    · next h =>
        have hz := isZero_eval params metavariables h
        simp [evalLevel, hz]
    · split
      · next h =>
          have hz := isZero_eval params metavariables h
          simp [evalLevel, hz]
      · cases a with
        | succ a =>
            cases a <;> simp only
            case zero =>
              simp only [evalLevel]
              split <;> omega
            all_goals
              split
              · next h =>
                  have he := levelEq_eval params metavariables h
                  simp only [evalLevel] at he ⊢
                  split <;> omega
              · rfl
        | zero | max _ _ | imax _ _ | param _ | mvar _ =>
            split
            · next h =>
                have he := levelEq_eval params metavariables h
                simp only [evalLevel] at he ⊢
                split <;> omega
            · rfl

end PsKernelSemantics
