import OperationalSoundness
import CoreIngress
import Ps.MinKernel.Profile.RegularIngressBytes

namespace Ps.MinKernel.RegularIngressModel
open Ps.MinKernel.CoreIngress
open Ps.MinKernel.RegularModel
open Ps.MinKernel.RegularProofs

-- This module records the backend boundary. Raw source interpretation and the
-- streaming wire grammar are separate obligations and are not claimed by it.
theorem decode_preserves_source (bytes : List Nat) (candidate source : List PsMinRegCoreEntry)
    (h : psMinRegCoreDecodeCertificate bytes candidate = some source) :
    source = candidate ∧ bytes.length ≤ psMinRegCoreByteBudget ∧
      psMinRegCoreEntriesValid 512 source = true ∧ psMinRegBytePacket source bytes = some [] := by
  unfold psMinRegCoreDecodeCertificate at h
  split at h
  next bounded =>
    split at h
    next valid =>
      cases hp : psMinRegBytePacket candidate bytes with
      | none => simp [hp] at h
      | some rest =>
        cases rest with
        | nil =>
          simp only [hp, Option.some.injEq] at h
          subst source
          exact ⟨rfl, lengthAtMost_sound _ _ bounded, valid, hp⟩
        | cons head tail => simp [hp] at h
    next => contradiction
  next => contradiction

theorem checked_entries_has_normalized_model (entries : List PsMinRegCoreEntry)
    (result : PsMinRegCoreChecked) (h : psMinRegCoreCheckEntries entries = some result) :
    Nonempty (Model (dataModel (psMinRegCoreSpecs result.plans.groups)) result.types) ∧
    ∃ output, OperationalProofs.DefinitionHistory 512 (psMinRegCoreSpecs result.plans.groups)
      [] result.normalized result.types (emptyModel (dataModel (psMinRegCoreSpecs result.plans.groups))) output := by
  unfold psMinRegCoreCheckEntries at h
  cases hp : psMinRegCorePlans entries with
  | none => simp [hp] at h
  | some state =>
    simp only [hp] at h
    split at h
    next signatures =>
      cases ht : psMinRegCoreTranslateEntries 512 state.count 0 state.groups [] entries with
      | none => simp [ht] at h
      | some normalized =>
        cases hc : psMinOpCheckEnvironment 512 512 (psMinRegCoreSpecs state.groups) normalized with
        | none => simp [ht, hc] at h
        | some types =>
          simp only [ht, hc, Option.some.injEq] at h
          subst result
          exact ⟨OperationalProofs.operational_hasModel _ _ _ _ _ hc,
            OperationalProofs.operational_hasBodyHistory _ _ _ _ _ hc⟩
    next => contradiction

theorem regular_byte_admission_has_normalized_model (bytes : List Nat) (candidate : List PsMinRegCoreEntry)
    (accepted : PsMinRegCoreAdmission) (h : psMinRegCoreAdmit bytes candidate = some accepted) :
    accepted.source = candidate ∧
    Nonempty (Model (dataModel (psMinRegCoreSpecs accepted.checked.plans.groups)) accepted.checked.types) := by
  unfold psMinRegCoreAdmit at h
  cases hd : psMinRegCoreDecodeCertificate bytes candidate with
  | none => simp [hd] at h
  | some source =>
    cases hc : psMinRegCoreCheckEntries source with
    | none => simp [hd, hc] at h
    | some checked =>
      simp only [hd, hc, Option.some.injEq] at h
      subst accepted
      exact ⟨(decode_preserves_source _ _ _ hd).1, (checked_entries_has_normalized_model _ _ hc).1⟩

theorem regular_no_normalized_empty_constant (bytes : List Nat) (candidate : List PsMinRegCoreEntry)
    (accepted : PsMinRegCoreAdmission) (h : psMinRegCoreAdmit bytes candidate = some accepted) (index : Nat) :
    psMinRegLookup accepted.checked.types index ≠ some PsMinRegTy.empty := by
  intro impossible
  obtain ⟨_, model⟩ := regular_byte_admission_has_normalized_model bytes candidate accepted h
  obtain ⟨model⟩ := model
  exact Empty.elim (model index .empty impossible)

inductive ConstructorSignatures (total visible : Nat) (groups : List PsMinRegCorePlan)
    (specs : List PsMinRegSpec) (slot : Nat) :
    Nat → List PsMinRegCoreConstructor → Prop where
  | nil (index) : ConstructorSignatures total visible groups specs slot index []
  | cons (index) (ctor : PsMinRegCoreConstructor) (rest) (type)
      (source : psMinRegCoreType 256 total visible groups ctor.type = some type)
      (derived : psMinRegCtorTypeAt specs slot index = some type)
      (tail : ConstructorSignatures total visible groups specs slot (Nat.succ index) rest) :
      ConstructorSignatures total visible groups specs slot index (ctor :: rest)

theorem actual_constructor_signatures (fuel total visible : Nat) (groups : List PsMinRegCorePlan)
    (specs : List PsMinRegSpec) (slot index : Nat) (constructors : List PsMinRegCoreConstructor)
    (h : psMinRegCoreCheckConstructors fuel total visible groups specs slot index constructors = true) :
    ConstructorSignatures total visible groups specs slot index constructors := by
  induction fuel generalizing index constructors with
  | zero =>
    cases constructors with
    | nil => exact .nil index
    | cons ctor rest => simp [psMinRegCoreCheckConstructors] at h
  | succ fuel ih =>
    cases constructors with
    | nil => exact .nil index
    | cons ctor rest =>
      cases ht : psMinRegCoreType 256 total visible groups ctor.type with
      | none => simp [psMinRegCoreCheckConstructors, ht] at h
      | some sourceType =>
        cases hd : psMinRegCtorTypeAt specs slot index with
        | none => simp [psMinRegCoreCheckConstructors, ht, hd] at h
        | some derived =>
          cases same : psMinRegTyEq 512 sourceType derived with
          | false => simp [psMinRegCoreCheckConstructors, ht, hd, same] at h
          | true =>
            have equal := typeEq_sound 512 _ _ same
            subst derived
            apply ConstructorSignatures.cons index ctor rest sourceType ht hd
            apply ih (Nat.succ index) rest
            simpa [psMinRegCoreCheckConstructors, ht, hd, same] using h

theorem group_slot_identity (total visible : Nat) (groups : List PsMinRegCorePlan)
    (name : PsMinCoreName) (slot : Nat)
    (h : psMinRegCoreGroupSlot total visible groups name = some slot) :
    ∃ plan ∈ groups, name = plan.source.name ∧ plan.ordinal < visible ∧ plan.ordinal < total ∧
      slot = total - (plan.ordinal + 1) := by
  induction groups with
  | nil => simp [psMinRegCoreGroupSlot] at h
  | cons plan rest ih =>
    simp only [psMinRegCoreGroupSlot] at h
    split at h
    next same =>
      split at h
      next seen =>
        split at h
        next bound =>
          simp only [Option.some.injEq] at h
          exact ⟨plan, List.mem_cons_self, nameEq_sound _ _ same,
            by simpa only [Nat.blt_eq] using seen, by simpa only [Nat.blt_eq] using bound,
            by simpa only [Nat.sub_eq, Nat.succ_eq_add_one] using h.symm⟩
        next => contradiction
      next => contradiction
    next =>
      obtain ⟨found, member, identity, seen, bound, position⟩ := ih h
      exact ⟨found, List.mem_cons_of_mem plan member, identity, seen, bound, position⟩

#print axioms decode_preserves_source
#print axioms checked_entries_has_normalized_model
#print axioms regular_byte_admission_has_normalized_model
#print axioms regular_no_normalized_empty_constant
#print axioms actual_constructor_signatures
#print axioms group_slot_identity
end Ps.MinKernel.RegularIngressModel
