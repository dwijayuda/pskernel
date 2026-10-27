import Ps.MinKernel.Profile.CoreIngress
import OperationalSoundness

namespace Ps.MinKernel.CoreIngress

theorem byteEq_sound (left right : List Nat) (h : psMinByteEq left right = true) : left = right := by
  induction left generalizing right with
  | nil => cases right <;> simp_all [psMinByteEq]
  | cons head tail ih =>
    cases right with
    | nil => simp [psMinByteEq] at h
    | cons other rest =>
      simp only [psMinByteEq] at h
      split at h
      next same => exact congrArg2 List.cons (Nat.eq_of_beq_eq_true same) (ih rest h)
      next => contradiction

theorem byteEq_refl (bytes : List Nat) : psMinByteEq bytes bytes = true := by
  induction bytes <;> simp_all [psMinByteEq]

theorem nameEq_sound (left right : PsMinCoreName) (h : psMinCoreNameEq left right = true) :
    left = right := by
  induction left generalizing right with
  | anonymous => cases right <;> simp_all [psMinCoreNameEq]
  | str parent bytes ih =>
    cases right with
    | str other rest =>
      simp only [psMinCoreNameEq] at h
      split at h
      next same => exact congrArg2 PsMinCoreName.str (ih other same) (byteEq_sound _ _ h)
      next => contradiction
    | _ => simp [psMinCoreNameEq] at h
  | num parent value ih =>
    cases right with
    | num other number =>
      simp only [psMinCoreNameEq] at h
      split at h
      next same => exact congrArg2 PsMinCoreName.num (ih other same) (Nat.eq_of_beq_eq_true h)
      next => contradiction
    | _ => simp [psMinCoreNameEq] at h

theorem nameEq_refl (name : PsMinCoreName) : psMinCoreNameEq name name = true := by
  induction name <;> simp_all [psMinCoreNameEq, byteEq_refl]

theorem exprEq_sound (fuel : Nat) (left right : PsMinCoreExpr)
    (h : psMinCoreExprEq fuel left right = true) : left = right := by
  induction fuel generalizing left right with
  | zero => simp [psMinCoreExprEq] at h
  | succ fuel ih =>
    cases left <;> cases right <;> simp only [psMinCoreExprEq] at h
    all_goals try contradiction
    all_goals repeat' split at h
    all_goals try contradiction
    all_goals first
      | exact congrArg PsMinCoreExpr.bvar (Nat.eq_of_beq_eq_true h)
      | exact congrArg PsMinCoreExpr.natural (Nat.eq_of_beq_eq_true h)
      | exact congrArg2 PsMinCoreExpr.constant (nameEq_sound _ _ (by assumption)) (byteEq_sound _ _ h)
      | congr 1 <;> first
          | exact nameEq_sound _ _ (by assumption)
          | exact Nat.eq_of_beq_eq_true (by assumption)
          | exact ih _ _ (by assumption)

theorem lengthAtMost_sound (fuel : Nat) (bytes : List Nat)
    (h : psMinByteLengthAtMost fuel bytes = true) : bytes.length ≤ fuel := by
  induction fuel generalizing bytes with
  | zero => cases bytes <;> simp_all [psMinByteLengthAtMost]
  | succ fuel ih =>
    cases bytes with
    | nil => simp
    | cons head tail =>
      exact Nat.succ_le_succ (ih tail h)

-- This format is an explicit canonical JSON grammar, not a hash assertion.
-- All object fields and tags are fixed by the encoder; every name/type/body and
-- declaration position is retained. The validity guard excludes escaping,
-- Unicode, numeric overflow, excessive depth and unsupported level instances.
structure WellFormedBytes (bytes : List Nat) (source : List PsMinCoreDeclaration) : Prop where
  byteBound : bytes.length ≤ 65536
  syntaxBound : psMinCoreDeclarationsValid 128 source = true
  exactBytes : bytes = psMinCoreEncode source

theorem decode_success_is_well_formed (bytes : List Nat)
    (candidate source : List PsMinCoreDeclaration)
    (h : psMinCoreDecodeCertificate bytes candidate = some source) :
    candidate = source ∧ WellFormedBytes bytes source := by
  unfold psMinCoreDecodeCertificate at h
  split at h
  next bounded =>
    split at h
    next valid =>
      split at h
      next same =>
        cases h
        exact ⟨rfl, ⟨lengthAtMost_sound _ _ bounded, valid, byteEq_sound _ _ same⟩⟩
      next => contradiction
    next => contradiction
  next => contradiction

def nameAt : List PsMinCoreName → Nat → Option PsMinCoreName
  | [], _ => none
  | head :: _, 0 => some head
  | _ :: rest, Nat.succ index => nameAt rest index

theorem resolve_preserves_identity (names : List PsMinCoreName) (name : PsMinCoreName)
    (index : Nat) (h : psMinCoreResolve names name = some index) :
    nameAt names index = some name := by
  induction names generalizing index with
  | nil => simp [psMinCoreResolve] at h
  | cons head rest ih =>
    simp only [psMinCoreResolve] at h
    split at h
    next same =>
      have hn := nameEq_sound _ _ same
      cases h
      simpa [nameAt, hn]
    next =>
      cases hr : psMinCoreResolve rest name with
      | none => simp [hr] at h
      | some previous =>
        simp only [hr, Option.some.injEq] at h
        subst index
        exact ih previous hr

theorem member_iff (names : List PsMinCoreName) (name : PsMinCoreName) :
    psMinCoreNameMember names name = true ↔ name ∈ names := by
  induction names with
  | nil => simp [psMinCoreNameMember]
  | cons head rest ih =>
    by_cases heq : name = head
    · subst head
      simp [psMinCoreNameMember, nameEq_refl]
    · have hb : psMinCoreNameEq name head = false := by
        cases h : psMinCoreNameEq name head with
        | false => rfl
        | true => exact False.elim (heq (nameEq_sound _ _ h))
      simp [psMinCoreNameMember, hb, ih, heq]

theorem fresh_no_shadowing (names : List PsMinCoreName) (name : PsMinCoreName)
    (h : psMinCoreFresh names name = true) :
    name ≠ .anonymous ∧ name ∉ names ∧ psMinCoreNameRoot name ∉ psMinCoreReservedRoots := by
  cases name <;> simp only [psMinCoreFresh] at h
  all_goals try contradiction
  all_goals repeat' split at h
  all_goals try contradiction
  all_goals simp_all [← member_iff]

-- Each step keeps the original declaration (including name, height, type and
-- body), its definition-time newest-first name context, and both translations.
inductive DeclarationCorrespondence (termFuel : Nat) :
    List PsMinCoreName → List PsMinCoreDeclaration → List PsMinOpDeclaration → Prop where
  | nil (names) : DeclarationCorrespondence termFuel names [] []
  | step (names) (decl : PsMinCoreDeclaration) (tail) (type value) (rest)
      (fresh : psMinCoreFresh names decl.name = true)
      (typeIdentity : psMinCoreType termFuel decl.type = some type)
      (bodyIdentity : psMinCoreTranslate termFuel names decl.value = some value)
      (next : DeclarationCorrespondence termFuel (decl.name :: names) tail rest) :
      DeclarationCorrespondence termFuel names (decl :: tail) (.mk type value :: rest)

theorem translate_environment_preserves_identity (termFuel declarationFuel : Nat)
    (names : List PsMinCoreName) (source : List PsMinCoreDeclaration)
    (normalized : List PsMinOpDeclaration)
    (h : psMinCoreTranslateDeclarations termFuel declarationFuel names source = some normalized) :
    DeclarationCorrespondence termFuel names source normalized := by
  induction declarationFuel generalizing names source normalized with
  | zero =>
    cases source with
    | nil => cases h; exact .nil names
    | cons head tail => simp [psMinCoreTranslateDeclarations] at h
  | succ fuel ih =>
    cases source with
    | nil => cases h; exact .nil names
    | cons decl tail =>
      simp only [psMinCoreTranslateDeclarations] at h
      split at h
      next fresh =>
        cases ht : psMinCoreType termFuel decl.type with
        | none => simp [ht] at h
        | some type =>
          cases hb : psMinCoreTranslate termFuel names decl.value with
          | none => simp [ht, hb] at h
          | some value =>
            cases hn : psMinCoreTranslateDeclarations termFuel fuel (decl.name :: names) tail with
            | none => simp [ht, hb, hn] at h
            | some rest =>
              simp only [ht, hb, hn, Option.some.injEq] at h
              subst normalized
              exact .step names decl tail type value rest fresh ht hb (ih _ _ _ hn)
      next => contradiction

theorem canonical_admission_has_model (bytes : List Nat) (candidate : List PsMinCoreDeclaration)
    (accepted : PsMinCoreAdmission) (h : psMinCoreAdmit bytes candidate = some accepted) :
    WellFormedBytes bytes accepted.source ∧
    DeclarationCorrespondence 64 [] accepted.source accepted.normalized ∧
    Nonempty (RegularProofs.Model (RegularModel.dataModel []) accepted.types) ∧
    ∃ model, OperationalProofs.DefinitionHistory 128 [] [] accepted.normalized accepted.types
      (RegularProofs.emptyModel (RegularModel.dataModel [])) model := by
  unfold psMinCoreAdmit at h
  cases hd : psMinCoreDecodeCertificate bytes candidate with
  | none => simp [hd] at h
  | some source =>
    cases ht : psMinCoreTranslateDeclarations 64 128 [] source with
    | none => simp [hd, ht] at h
    | some normalized =>
      cases hc : psMinOpCheckEnvironment 128 128 [] normalized with
      | none => simp [hd, ht, hc] at h
      | some types =>
        simp only [hd, ht, hc, Option.some.injEq] at h
        subst accepted
        exact ⟨(decode_success_is_well_formed _ _ _ hd).2,
          translate_environment_preserves_identity _ _ _ _ _ ht,
          OperationalProofs.operational_hasModel _ _ _ _ _ hc,
          OperationalProofs.operational_hasBodyHistory _ _ _ _ _ hc⟩

#print axioms byteEq_sound
#print axioms nameEq_sound
#print axioms exprEq_sound
#print axioms decode_success_is_well_formed
#print axioms resolve_preserves_identity
#print axioms fresh_no_shadowing
#print axioms translate_environment_preserves_identity
#print axioms canonical_admission_has_model
end Ps.MinKernel.CoreIngress
