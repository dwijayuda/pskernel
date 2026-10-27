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

theorem denote_prefix_lift (prefix data : List Type) (type : PsMinRegTy) :
    Denote (prefix ++ data) (psMinRegCoreLiftCode type prefix.length) = Denote data type := by
  induction prefix with
  | nil => rw [lift_zero]; rfl
  | cons head tail ih =>
    change Denote (head :: (tail ++ data)) (psMinRegCoreLiftCode type (Nat.succ tail.length)) = Denote data type
    rw [lift_succ, denote_lift]
    exact ih

theorem denote_self (prefix data : List Type) (self : Type) :
    Denote (prefix ++ (self :: data)) (.data prefix.length) = self := by
  induction prefix with
  | nil => rfl
  | cons head tail ih => exact ih

theorem denote_ground (prefix data : List Type) (self : Type) (type : PsMinRegTy) :
    Denote (prefix ++ (self :: data)) (psMinRegCoreLiftCode type (Nat.succ prefix.length)) =
      Denote data type := by
  rw [lift_input, denote_prefix_lift, denote_lift]

theorem denote_fields (prefix data : List Type) (self : Type) (fields : List PsMinRegField)
    (result : PsMinRegTy) :
    Denote (prefix ++ (self :: data)) (psMinRegCoreAmbientFields prefix.length fields result) =
      FieldArrow data self fields (Denote (prefix ++ (self :: data)) result) := by
  induction fields with
  | nil => rfl
  | cons field rest ih =>
    cases field with
    | ground type =>
      change (Denote (prefix ++ (self :: data)) (psMinRegCoreLiftCode type (Nat.succ prefix.length)) →
        Denote (prefix ++ (self :: data)) (psMinRegCoreAmbientFields prefix.length rest result)) =
        (Denote data type → FieldArrow data self rest (Denote (prefix ++ (self :: data)) result))
      rw [denote_ground, ih]
    | recursive =>
      change (Denote (prefix ++ (self :: data)) (.data prefix.length) →
        Denote (prefix ++ (self :: data)) (psMinRegCoreAmbientFields prefix.length rest result)) =
        (self → FieldArrow data self rest (Denote (prefix ++ (self :: data)) result))
      rw [denote_self, ih]

theorem denote_branch (prefix data : List Type) (self : Type) (fields : List PsMinRegField)
    (result : PsMinRegTy) :
    Denote (prefix ++ (self :: data)) (psMinRegCoreAmbientBranch prefix.length result fields) =
      Minor data self (Denote (prefix ++ (self :: data)) result) fields := by
  change Denote (prefix ++ (self :: data)) (psMinRegCoreAmbientFields prefix.length fields
    (psMinRegRepeatArrow (psMinRegSelfCount fields) result result)) = _
  rw [denote_fields, denote_repeat]
  rfl

theorem denote_branches (prefix data : List Type) (self : Type) (constructors : List (List PsMinRegField))
    (result : PsMinRegTy) :
    Denote (prefix ++ (self :: data)) (psMinRegCoreAmbientBranches prefix.length result constructors) =
      BranchArrow data self (Denote (prefix ++ (self :: data)) result) constructors := by
  induction constructors with
  | nil =>
    change (Denote (prefix ++ (self :: data)) (.data prefix.length) →
      Denote (prefix ++ (self :: data)) result) = _
    rw [denote_self]
    rfl
  | cons fields rest ih =>
    change (Denote (prefix ++ (self :: data)) (psMinRegCoreAmbientBranch prefix.length result fields) →
      Denote (prefix ++ (self :: data)) (psMinRegCoreAmbientBranches prefix.length result rest)) = _
    rw [denote_branch, ih]
    rfl

-- The existing positive carrier folds into the actual ambient result type.
-- It does not require that result to belong to the selected family's prefix.
noncomputable def ambientValue (prefix : List Type) (specs : List PsMinRegSpec)
    (slot : Nat) (result : PsMinRegTy) (selected : PsMinRegSpec)
    (h : psMinRegCoreSpecAt specs slot = some selected) :
    Denote (prefix ++ dataModel specs)
      (psMinRegCoreAmbientBranches (prefix.length + slot) result selected.constructors) := by
  induction specs generalizing prefix slot with
  | nil => simp [psMinRegCoreSpecAt] at h
  | cons spec rest ih =>
    cases slot with
    | zero =>
      have equal : spec = selected := Option.some.inj h
      subst selected
      change Denote (prefix ++ (Carrier spec (dataModel rest) :: dataModel rest))
        (psMinRegCoreAmbientBranches prefix.length result spec.constructors)
      exact cast (denote_branches prefix (dataModel rest) (Carrier spec (dataModel rest))
        spec.constructors result).symm
        (recursor spec (dataModel rest)
          (Denote (prefix ++ (Carrier spec (dataModel rest) :: dataModel rest)) result))
    | succ slot =>
      have next : psMinRegCoreSpecAt rest slot = some selected := h
      have value := ih (prefix ++ [Carrier spec (dataModel rest)]) slot next
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
