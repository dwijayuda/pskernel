import Ps.MinKernel.Profile.RegularNames

namespace Ps.MinKernel.RegularNames

theorem data_injective (left right : Nat) (h : psMinRegDataName left = psMinRegDataName right) : left = right := by
  exact (PsName.num.inj h).2

theorem constructor_injective (left right a b : Nat)
    (h : psMinRegConstructorName left a = psMinRegConstructorName right b) : left = right ∧ a = b := by
  have hh : psMinRegDataName left = psMinRegDataName right ∧ a = b := by
    exact PsName.num.inj h
  exact ⟨data_injective left right hh.1, hh.2⟩

theorem recursor_injective (left right : Nat)
    (h : psMinRegRecursorName left = psMinRegRecursorName right) : left = right := by
  have hh : psMinRegDataName left = psMinRegDataName right := by
    exact (PsName.str.inj h).1
  exact data_injective left right hh

theorem data_constructor_disjoint (left right index : Nat) :
    psMinRegDataName left ≠ psMinRegConstructorName right index := by
  simp [psMinRegDataName, psMinRegConstructorName]

theorem data_recursor_disjoint (left right : Nat) :
    psMinRegDataName left ≠ psMinRegRecursorName right := by
  simp [psMinRegDataName, psMinRegRecursorName]

theorem constructor_recursor_disjoint (left right index : Nat) :
    psMinRegConstructorName left index ≠ psMinRegRecursorName right := by
  simp [psMinRegConstructorName, psMinRegRecursorName]

theorem generated_root_disjoint (index constructor : Nat) (text : String) :
    psMinRegDataName index ≠ PsName.str PsName.anonymous text ∧
    psMinRegConstructorName index constructor ≠ PsName.str PsName.anonymous text ∧
    psMinRegRecursorName index ≠ PsName.str PsName.anonymous text := by
  simp [psMinRegDataName, psMinRegConstructorName, psMinRegRecursorName]

theorem ordinal_stable (count index : Nat) :
    psMinRegOrdinal (Nat.succ count) (Nat.succ index) = psMinRegOrdinal count index := by
  simp only [psMinRegOrdinal, Nat.succ_sub_succ]

theorem ordinal_injective (count left right : Nat) (hl : left < count) (hr : right < count)
    (h : psMinRegOrdinal count left = psMinRegOrdinal count right) : left = right := by
  have recover := congrArg (fun value : Nat => Nat.sub count value) h
  have eq : Nat.succ left = Nat.succ right := by
    simpa only [psMinRegOrdinal, Nat.sub_sub_self (Nat.succ_le_of_lt hl),
      Nat.sub_sub_self (Nat.succ_le_of_lt hr)] using recover
  exact Nat.succ.inj eq

theorem slot_name_stable (count index : Nat) :
    psMinRegSlotName (Nat.succ count) (Nat.succ index) = psMinRegSlotName count index := by
  simp only [psMinRegSlotName, Nat.blt_eq, Nat.succ_lt_succ_iff, ordinal_stable]

theorem slot_name_injective (count left right : Nat) (name : PsName)
    (hl : psMinRegSlotName count left = some name) (hr : psMinRegSlotName count right = some name) :
    left = right := by
  by_cases hleft : Nat.blt left count = true
  · by_cases hright : Nat.blt right count = true
    · have nl : psMinRegDataName (psMinRegOrdinal count left) = name := by
        simpa [psMinRegSlotName, hleft] using hl
      have nr : psMinRegDataName (psMinRegOrdinal count right) = name := by
        simpa [psMinRegSlotName, hright] using hr
      exact ordinal_injective count left right
        (by simpa only [Nat.blt_eq] using hleft) (by simpa only [Nat.blt_eq] using hright)
        (data_injective _ _ (nl.trans nr.symm))
    · simp [psMinRegSlotName, hright] at hr
  · simp [psMinRegSlotName, hleft] at hl

theorem generated_child_disjoint (index constructor : Nat) (root label : String) :
    psMinRegDataName index ≠ PsName.str (PsName.str PsName.anonymous root) label ∧
    psMinRegConstructorName index constructor ≠ PsName.str (PsName.str PsName.anonymous root) label ∧
    psMinRegRecursorName index ≠ PsName.str (PsName.str PsName.anonymous root) label := by
  simp [psMinRegDataName, psMinRegConstructorName, psMinRegRecursorName]

#print axioms constructor_injective
#print axioms recursor_injective
#print axioms generated_root_disjoint
#print axioms slot_name_stable
#print axioms slot_name_injective
#print axioms generated_child_disjoint

end Ps.MinKernel.RegularNames
