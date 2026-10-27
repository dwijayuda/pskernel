import RegularModel
import Ps.MinKernel.Profile.OperationalProfile

namespace Ps.MinKernel.OperationalProjection
open Ps.MinKernel.RegularModel

def singleSpec (fields : List PsMinRegField) : PsMinRegSpec :=
  ⟨0, 0, 0, 1, 1, [fields]⟩

theorem single_get (fields : List PsMinRegField) (index : Fin ([fields].length)) :
    [fields].get index = fields := by
  rcases index with ⟨index, bound⟩
  cases index with
  | zero => rfl
  | succ index => simp at bound

def recordArgs (fields : List PsMinRegField) (data : List Type)
    (value : Carrier (singleSpec fields) data) :
    Args data (Carrier (singleSpec fields) data) fields :=
  match value with
  | .node tag children =>
    cast (congrArg (Args data (Carrier (singleSpec fields) data)) (single_get fields tag.1))
      (joinArgs data (Carrier (singleSpec fields) data) ([fields].get tag.1) tag.2 children)

theorem recordArgs_construct (fields : List PsMinRegField) (data : List Type)
    (args : Args data (Carrier (singleSpec fields) data) fields) :
    recordArgs fields data (construct (singleSpec fields) data ⟨0, by simp [singleSpec]⟩ args) = args := by
  change joinArgs data (Carrier (singleSpec fields) data) fields
    (splitArgs data (Carrier (singleSpec fields) data) fields args).1
    (splitArgs data (Carrier (singleSpec fields) data) fields args).2 = args
  exact join_split _ _ _ args

noncomputable def fieldValue (data : List Type) (self : Type) (fields : List PsMinRegField)
    (index : Nat) (type : PsMinRegTy)
    (h : psMinOpFieldType fields index = some type) (args : Args data self fields) :
    Denote (self :: data) type := by
  induction fields generalizing index with
  | nil => simp [psMinOpFieldType] at h
  | cons field rest ih =>
    cases index with
    | zero =>
      cases field with
      | ground code =>
        have ht : psMinRegLiftTy code = type := by simpa [psMinOpFieldType] using h
        cases ht
        exact cast (denote_lift self data code).symm args.1
      | recursive =>
        have ht : PsMinRegTy.data 0 = type := by simpa [psMinOpFieldType] using h
        cases ht
        exact args.1
    | succ index => cases field <;> exact ih index h args.2

def headLookup (fields : List PsMinRegField) (index : Nat) : Option PsMinRegTy :=
  psMinOpProjectionType [singleSpec fields] 0 index

theorem head_signature (fields : List PsMinRegField) (index : Nat) (type : PsMinRegTy)
    (h : headLookup fields index = some type) :
    ∃ result, psMinOpFieldType fields index = some result ∧ type = .arr (.data 0) result := by
  cases hf : psMinOpFieldType fields index with
  | none => simp [headLookup, psMinOpProjectionType, singleSpec, hf] at h
  | some result =>
    have ht : PsMinRegTy.arr (.data 0) result = type := by
      simpa [headLookup, psMinOpProjectionType, singleSpec, hf] using h
    exact ⟨result, hf, ht.symm⟩

theorem head_arrow_signature (fields : List PsMinRegField) (index : Nat)
    (domain result : PsMinRegTy) (h : headLookup fields index = some (.arr domain result)) :
    domain = .data 0 ∧ psMinOpFieldType fields index = some result := by
  obtain ⟨actual, hf, ht⟩ := head_signature fields index _ h
  have eqs := PsMinRegTy.arr.inj ht
  exact ⟨eqs.1, by simpa only [eqs.2] using hf⟩

-- Select the result from the supplied arrow code, never by eliminating a
-- computed Option into Type. All lookup evidence below stays in Prop.
noncomputable def headModel (fields : List PsMinRegField) (data : List Type)
    (index : Nat) (type : PsMinRegTy) (h : headLookup fields index = some type) :
    Denote (Carrier (singleSpec fields) data :: data) type := by
  cases type with
  | arr domain result =>
    have facts := head_arrow_signature fields index domain result h
    cases facts.1
    exact fun value => fieldValue data (Carrier (singleSpec fields) data)
      fields index result facts.2 (recordArgs fields data value)
  | empty =>
    exfalso
    obtain ⟨result, hf, ht⟩ := head_signature fields index _ h
    cases ht
  | unit =>
    exfalso
    obtain ⟨result, hf, ht⟩ := head_signature fields index _ h
    cases ht
  | nat =>
    exfalso
    obtain ⟨result, hf, ht⟩ := head_signature fields index _ h
    cases ht
  | boolean =>
    exfalso
    obtain ⟨result, hf, ht⟩ := head_signature fields index _ h
    cases ht
  | data slot =>
    exfalso
    obtain ⟨result, hf, ht⟩ := head_signature fields index _ h
    cases ht
  | list element =>
    exfalso
    obtain ⟨result, hf, ht⟩ := head_signature fields index _ h
    cases ht
  | option element =>
    exfalso
    obtain ⟨result, hf, ht⟩ := head_signature fields index _ h
    cases ht

noncomputable def projectionModel (specs : List PsMinRegSpec) :
    (slot field : Nat) → (type : PsMinRegTy) →
      psMinOpProjectionType specs slot field = some type → Denote (dataModel specs) type := by
  cases specs with
  | nil => intro slot field type h; simp [psMinOpProjectionType] at h
  | cons spec rest =>
    let ih := projectionModel rest
    intro slot field type h
    cases slot with
    | succ slot =>
      cases hp : psMinOpProjectionType rest slot field with
      | none => simp [psMinOpProjectionType, hp] at h
      | some prior =>
        have ht : psMinRegLiftTy prior = type := by simpa [psMinOpProjectionType, hp] using h
        cases ht
        exact cast (denote_lift (Carrier spec (dataModel rest)) (dataModel rest) prior).symm
          (ih slot field prior hp)
    | zero =>
      cases spec with
      | mk levels parameters indices motives minors constructors =>
        cases constructors with
        | nil => simp [psMinOpProjectionType] at h
        | cons fields others =>
          cases others with
          | cons other more => simp [psMinOpProjectionType] at h
          | nil =>
            exact headModel fields (dataModel rest) field type
              (by simpa only [headLookup, psMinOpProjectionType, singleSpec] using h)
termination_by structural specs

theorem projection_iota (fields : List PsMinRegField) (data : List Type)
    (index : Nat) (type : PsMinRegTy) (h : psMinOpFieldType fields index = some type)
    (args : Args data (Carrier (singleSpec fields) data) fields) :
    fieldValue data (Carrier (singleSpec fields) data) fields index type h
      (recordArgs fields data (construct (singleSpec fields) data ⟨0, by simp [singleSpec]⟩ args)) =
      fieldValue data (Carrier (singleSpec fields) data) fields index type h args := by
  rw [recordArgs_construct]

theorem projection_head_type (fields : List PsMinRegField) (rest : List PsMinRegSpec)
    (index : Nat) (type : PsMinRegTy) (h : psMinOpFieldType fields index = some type) :
    psMinOpProjectionType (singleSpec fields :: rest) 0 index = some (.arr (.data 0) type) := by
  simpa only [psMinOpProjectionType, singleSpec, h]

theorem actual_projection_iota (fields : List PsMinRegField) (rest : List PsMinRegSpec)
    (index : Nat) (type : PsMinRegTy) (h : psMinOpFieldType fields index = some type)
    (args : Args (dataModel rest) (Carrier (singleSpec fields) (dataModel rest)) fields) :
    projectionModel (singleSpec fields :: rest) 0 index (.arr (.data 0) type)
      (projection_head_type fields rest index type h)
      (construct (singleSpec fields) (dataModel rest) ⟨0, by simp [singleSpec]⟩ args) =
      fieldValue (dataModel rest) (Carrier (singleSpec fields) (dataModel rest)) fields index type h args := by
  unfold projectionModel
  dsimp only [singleSpec, Nat.casesAuxOn]
  simpa -implicitDefEqProofs only [headModel] using!
    projection_iota fields (dataModel rest) index type h args

#print axioms projectionModel
#print axioms projection_iota
#print axioms actual_projection_iota
end Ps.MinKernel.OperationalProjection
