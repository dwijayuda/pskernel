import RegularModel
import Ps.MinKernel.Profile.RegularIngressOperational

namespace Ps.MinKernel.RegularIngressAmbient
open Ps.MinKernel.RegularModel

theorem lift_zero (type : PsMinRegTy) : psMinRegCoreLiftCode type 0 = type := by
  induction type with
  | empty => rfl
  | unit => rfl
  | nat => rfl
  | boolean => rfl
  | data index => exact congrArg PsMinRegTy.data (Nat.add_zero index)
  | arr a b iha ihb =>
    change PsMinRegTy.arr (psMinRegCoreLiftCode a 0) (psMinRegCoreLiftCode b 0) = .arr a b
    rw [iha, ihb]
  | list a ih => exact congrArg PsMinRegTy.list ih
  | option a ih => exact congrArg PsMinRegTy.option ih

theorem lift_succ (type : PsMinRegTy) (amount : Nat) :
    psMinRegCoreLiftCode type (Nat.succ amount) = psMinRegLiftTy (psMinRegCoreLiftCode type amount) := by
  induction type with
  | empty => rfl
  | unit => rfl
  | nat => rfl
  | boolean => rfl
  | data index => exact congrArg PsMinRegTy.data (Nat.add_succ index amount)
  | arr a b iha ihb =>
    change PsMinRegTy.arr (psMinRegCoreLiftCode a (Nat.succ amount)) (psMinRegCoreLiftCode b (Nat.succ amount)) =
      .arr (psMinRegLiftTy (psMinRegCoreLiftCode a amount)) (psMinRegLiftTy (psMinRegCoreLiftCode b amount))
    rw [iha, ihb]
  | list a ih => exact congrArg PsMinRegTy.list ih
  | option a ih => exact congrArg PsMinRegTy.option ih

theorem lift_input (type : PsMinRegTy) (amount : Nat) :
    psMinRegCoreLiftCode type (Nat.succ amount) = psMinRegCoreLiftCode (psMinRegLiftTy type) amount := by
  induction type with
  | empty => rfl
  | unit => rfl
  | nat => rfl
  | boolean => rfl
  | data index =>
    change PsMinRegTy.data (index + Nat.succ amount) = .data (Nat.succ index + amount)
    rw [Nat.add_succ, Nat.succ_add]
  | arr a b iha ihb =>
    change PsMinRegTy.arr (psMinRegCoreLiftCode a (Nat.succ amount)) (psMinRegCoreLiftCode b (Nat.succ amount)) =
      .arr (psMinRegCoreLiftCode (psMinRegLiftTy a) amount) (psMinRegCoreLiftCode (psMinRegLiftTy b) amount)
    rw [iha, ihb]
  | list a ih => exact congrArg PsMinRegTy.list ih
  | option a ih => exact congrArg PsMinRegTy.option ih

theorem denote_prefix_lift (heads data : List Type) (type : PsMinRegTy) :
    Denote (heads ++ data) (psMinRegCoreLiftCode type heads.length) = Denote data type := by
  induction heads with
  | nil =>
    change Denote data (psMinRegCoreLiftCode type 0) = Denote data type
    rw [lift_zero]
  | cons head tail ih =>
    change Denote (head :: (tail ++ data)) (psMinRegCoreLiftCode type (Nat.succ tail.length)) = Denote data type
    rw [lift_succ, denote_lift]
    exact ih

theorem denote_self (heads data : List Type) (self : Type) :
    Denote (heads ++ (self :: data)) (.data heads.length) = self := by
  induction heads with
  | nil => rfl
  | cons head tail ih => exact ih

theorem denote_ground (heads data : List Type) (self : Type) (type : PsMinRegTy) :
    Denote (heads ++ (self :: data)) (psMinRegCoreLiftCode type (Nat.succ heads.length)) =
      Denote data type := by
  rw [lift_input, denote_prefix_lift, denote_lift]

theorem denote_fields (heads data : List Type) (self : Type) (fields : List PsMinRegField)
    (result : PsMinRegTy) :
    Denote (heads ++ (self :: data)) (psMinRegCoreAmbientFields heads.length fields result) =
      FieldArrow data self fields (Denote (heads ++ (self :: data)) result) := by
  induction fields with
  | nil => rfl
  | cons field rest ih =>
    cases field with
    | ground type =>
      change (Denote (heads ++ (self :: data)) (psMinRegCoreLiftCode type (Nat.succ heads.length)) →
        Denote (heads ++ (self :: data)) (psMinRegCoreAmbientFields heads.length rest result)) =
        (Denote data type → FieldArrow data self rest (Denote (heads ++ (self :: data)) result))
      rw [denote_ground, ih]
    | recursive =>
      change (Denote (heads ++ (self :: data)) (.data heads.length) →
        Denote (heads ++ (self :: data)) (psMinRegCoreAmbientFields heads.length rest result)) =
        (self → FieldArrow data self rest (Denote (heads ++ (self :: data)) result))
      rw [denote_self, ih]

theorem denote_branch (heads data : List Type) (self : Type) (fields : List PsMinRegField)
    (result : PsMinRegTy) :
    Denote (heads ++ (self :: data)) (psMinRegCoreAmbientBranch heads.length result fields) =
      Minor data self (Denote (heads ++ (self :: data)) result) fields := by
  change Denote (heads ++ (self :: data)) (psMinRegCoreAmbientFields heads.length fields
    (psMinRegRepeatArrow (psMinRegSelfCount fields) result result)) = _
  rw [denote_fields, denote_repeat]
  rfl

theorem denote_branches (heads data : List Type) (self : Type) (constructors : List (List PsMinRegField))
    (result : PsMinRegTy) :
    Denote (heads ++ (self :: data)) (psMinRegCoreAmbientBranches heads.length result constructors) =
      BranchArrow data self (Denote (heads ++ (self :: data)) result) constructors := by
  induction constructors with
  | nil =>
    change (Denote (heads ++ (self :: data)) (.data heads.length) →
      Denote (heads ++ (self :: data)) result) = _
    rw [denote_self]
    rfl
  | cons fields rest ih =>
    change (Denote (heads ++ (self :: data)) (psMinRegCoreAmbientBranch heads.length result fields) →
      Denote (heads ++ (self :: data)) (psMinRegCoreAmbientBranches heads.length result rest)) = _
    rw [denote_branch, ih]
    rfl

-- The existing positive carrier folds into the actual ambient result type.
-- It does not require that result to belong to the selected family's heads.
noncomputable def ambientValue (heads : List Type) (specs : List PsMinRegSpec)
    (slot : Nat) (result : PsMinRegTy) (selected : PsMinRegSpec)
    (h : psMinRegCoreSpecAt specs slot = some selected) :
    Denote (heads ++ dataModel specs)
      (psMinRegCoreAmbientBranches (heads.length + slot) result selected.constructors) := by
  induction specs generalizing heads slot with
  | nil => simp [psMinRegCoreSpecAt] at h
  | cons spec rest ih =>
    cases slot with
    | zero =>
      have equal : spec = selected := Option.some.inj h
      subst selected
      change Denote (heads ++ (Carrier spec (dataModel rest) :: dataModel rest))
        (psMinRegCoreAmbientBranches heads.length result spec.constructors)
      exact cast (denote_branches heads (dataModel rest) (Carrier spec (dataModel rest))
        spec.constructors result).symm
        (recursor spec (dataModel rest)
          (Denote (heads ++ (Carrier spec (dataModel rest) :: dataModel rest)) result))
    | succ slot =>
      have next : psMinRegCoreSpecAt rest slot = some selected := h
      have value := ih (heads ++ [Carrier spec (dataModel rest)]) slot next
      simpa only [List.length_append, List.length_cons, List.length_nil, Nat.add_zero,
        Nat.add_succ, Nat.succ_add, List.append_assoc, List.cons_append, List.nil_append, dataModel] using value

noncomputable def recursorModel (specs : List PsMinRegSpec) (slot : Nat)
    (result type : PsMinRegTy) (h : psMinRegCoreAmbientRecursorType specs slot result = some type) :
    Denote (dataModel specs) type := by
  cases hs : psMinRegCoreSpecAt specs slot with
  | none => simp [psMinRegCoreAmbientRecursorType, hs] at h
  | some selected =>
    have equal : psMinRegCoreAmbientBranches slot result selected.constructors = type := by
      simpa only [psMinRegCoreAmbientRecursorType, hs, Option.some.injEq] using h
    subst type
    simpa only [List.length_nil, Nat.zero_add, List.nil_append] using
      ambientValue [] specs slot result selected hs

#print axioms lift_zero
#print axioms lift_succ
#print axioms lift_input
#print axioms denote_prefix_lift
#print axioms denote_self
#print axioms denote_ground
#print axioms denote_fields
#print axioms denote_branch
#print axioms denote_branches
#print axioms ambientValue
#print axioms recursorModel
end Ps.MinKernel.RegularIngressAmbient
