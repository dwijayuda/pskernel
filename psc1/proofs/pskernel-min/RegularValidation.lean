import RegularSoundness

namespace Ps.MinKernel.RegularValidation
open Ps.MinKernel.RegularModel

def Closed (bound : Nat) : PsMinRegTy → Prop
  | .empty | .unit | .nat | .boolean => True
  | .data index => index < bound
  | .arr domain result => Closed bound domain ∧ Closed bound result
  | .list element | .option element => Closed bound element

def FieldsClosed (bound : Nat) : List PsMinRegField → Prop
  | [] => True
  | .ground type :: rest => Closed bound type ∧ FieldsClosed bound rest
  | .recursive :: rest => FieldsClosed bound rest

def ConstructorsClosed (bound : Nat) : List (List PsMinRegField) → Prop
  | [] => True
  | fields :: rest => FieldsClosed bound fields ∧ ConstructorsClosed bound rest

def SpecClosed (bound : Nat) (spec : PsMinRegSpec) : Prop :=
  spec.levelParameters = 0 ∧ spec.parameters = 0 ∧ spec.indices = 0 ∧
  spec.motives = 1 ∧ spec.minors = psMinRegCtorCount spec.constructors ∧ ConstructorsClosed bound spec.constructors

def RegistryClosed : List PsMinRegSpec → Prop
  | [] => True
  | spec :: rest => RegistryClosed rest ∧ SpecClosed (psMinRegSpecCount rest) spec

theorem typeValid_sound (fuel bound : Nat) (type : PsMinRegTy)
    (h : psMinRegTyValid fuel bound type = true) : Closed bound type := by
  induction fuel generalizing type with
  | zero => simp [psMinRegTyValid] at h
  | succ remaining ih =>
    cases type with
    | empty => trivial
    | unit => trivial
    | nat => trivial
    | boolean => trivial
    | data index => simpa only [psMinRegTyValid, Nat.blt_eq, Closed] using h
    | list element => exact ih element h
    | option element => exact ih element h
    | arr domain result =>
      cases hd : psMinRegTyValid remaining bound domain with
      | false => simp [psMinRegTyValid, hd] at h
      | true =>
        have hr : psMinRegTyValid remaining bound result = true := by simpa [psMinRegTyValid, hd] using h
        exact ⟨ih domain hd, ih result hr⟩

theorem fieldsValid_sound (fuel bound : Nat) (fields : List PsMinRegField)
    (h : psMinRegFieldsValid fuel bound fields = true) : FieldsClosed bound fields := by
  induction fields with
  | nil => trivial
  | cons field rest ih =>
    cases field with
    | recursive => exact ih h
    | ground type =>
      cases ht : psMinRegTyValid fuel bound type with
      | false => simp [psMinRegFieldsValid, ht] at h
      | true =>
        have hr : psMinRegFieldsValid fuel bound rest = true := by simpa [psMinRegFieldsValid, ht] using h
        exact ⟨typeValid_sound fuel bound type ht, ih hr⟩

theorem constructorsValid_sound (fuel bound : Nat) (constructors : List (List PsMinRegField))
    (h : psMinRegConstructorsValid fuel bound constructors = true) : ConstructorsClosed bound constructors := by
  induction constructors with
  | nil => trivial
  | cons fields rest ih =>
    cases hf : psMinRegFieldsValid fuel bound fields with
    | false => simp [psMinRegConstructorsValid, hf] at h
    | true =>
      have hr : psMinRegConstructorsValid fuel bound rest = true := by simpa [psMinRegConstructorsValid, hf] using h
      exact ⟨fieldsValid_sound fuel bound fields hf, ih hr⟩

theorem specValid_sound (fuel bound : Nat) (spec : PsMinRegSpec)
    (h : psMinRegSpecValid fuel bound spec = true) : SpecClosed bound spec := by
  cases h0 : Nat.beq spec.levelParameters 0 with
  | false => simp [psMinRegSpecValid, h0] at h
  | true =>
      cases h1 : Nat.beq spec.parameters 0 with
      | false => simp [psMinRegSpecValid, h0, h1] at h
      | true =>
          cases h2 : Nat.beq spec.indices 0 with
          | false => simp [psMinRegSpecValid, h0, h1, h2] at h
          | true =>
              cases h3 : Nat.beq spec.motives 1 with
              | false => simp [psMinRegSpecValid, h0, h1, h2, h3] at h
              | true =>
                  cases h4 : Nat.beq spec.minors (psMinRegCtorCount spec.constructors) with
                  | false => simp [psMinRegSpecValid, h0, h1, h2, h3, h4] at h
                  | true =>
                      have hc : psMinRegConstructorsValid fuel bound spec.constructors = true := by
                        simpa [psMinRegSpecValid, h0, h1, h2, h3, h4] using h
                      exact ⟨(by simpa only [Nat.beq_eq] using h0), (by simpa only [Nat.beq_eq] using h1), (by simpa only [Nat.beq_eq] using h2), (by simpa only [Nat.beq_eq] using h3), (by simpa only [Nat.beq_eq] using h4), constructorsValid_sound fuel bound spec.constructors hc⟩

theorem registryValid_sound (fuel : Nat) (specs : List PsMinRegSpec)
    (h : psMinRegRegistryValid fuel specs = true) : RegistryClosed specs := by
  induction fuel generalizing specs with
  | zero => cases specs <;> simp_all [psMinRegRegistryValid, RegistryClosed]
  | succ remaining ih =>
    cases specs with
    | nil => trivial
    | cons spec rest =>
      cases hr : psMinRegRegistryValid remaining rest with
      | false => simp [psMinRegRegistryValid, hr] at h
      | true =>
        have hs : psMinRegSpecValid remaining (psMinRegSpecCount rest) spec = true := by
          simpa [psMinRegRegistryValid, hr] using h
        exact ⟨ih rest hr, specValid_sound remaining (psMinRegSpecCount rest) spec hs⟩

theorem ctorCount_length (constructors : List (List PsMinRegField)) :
    psMinRegCtorCount constructors = constructors.length := by
  induction constructors with
  | nil => rfl
  | cons head rest ih => simp only [psMinRegCtorCount, List.length_cons, ih]

theorem registry_hasModel (fuel : Nat) (specs : List PsMinRegSpec)
    (h : psMinRegRegistryValid fuel specs = true) :
    RegistryClosed specs ∧ Nonempty (SignatureModel specs (dataModel specs)) :=
  ⟨registryValid_sound fuel specs h, ⟨signatures specs⟩⟩

#print axioms typeValid_sound
#print axioms registryValid_sound
#print axioms registry_hasModel

end Ps.MinKernel.RegularValidation
