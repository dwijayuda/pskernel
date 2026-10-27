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

#print axioms constructor_injective
#print axioms recursor_injective
#print axioms generated_root_disjoint

end Ps.MinKernel.RegularNames
