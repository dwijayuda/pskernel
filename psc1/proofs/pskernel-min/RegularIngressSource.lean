import RegularIngressTerms
import RegularIngressOperationalModel
import RegularIngressEncoding

namespace Ps.MinKernel.RegularIngressSource
open Ps.MinKernel.CoreIngress
open Ps.MinKernel.CoreTranslation
open Ps.MinKernel.RegularIngressTranslation
open Ps.MinKernel.RegularIngressTerms
open Ps.MinKernel.RegularIngressOperationalModel

inductive TermImage (total visible : Nat) (groups : List PsMinRegCorePlan)
    (names : List PsMinCoreName) : PsMinCoreExpr → PsMinRegCoreTerm → Prop where
  | variable (index) : TermImage total visible groups names (.bvar index) (.ordinary (.base (.var index)))
  | natural (value) : TermImage total visible groups names (.natural value) (.ordinary (.base (.nat value)))
  | constant (name index) (identity : nameAt names index = some name) :
      TermImage total visible groups names (.constant name []) (.ordinary (.base (.constant index)))
  | primitive (source term) (image : RegularIngressTerms.PrimitiveImage total visible groups source term) :
      TermImage total visible groups names source (.ordinary term)
  | recursor (source term) (image : RecursorImage total visible groups source term) :
      TermImage total visible groups names source term
  | construct (name slot index) (binding : ConstructorBinding total visible groups name slot index) :
      TermImage total visible groups names (.constant name []) (.ordinary (.base (.ctor slot index)))
  | app (fn arg f a) (hf : TermImage total visible groups names fn f)
      (ha : TermImage total visible groups names arg a) :
      TermImage total visible groups names (.app fn arg) (.app f a)
  | lam (name binder type body t b) (ht : RegularIngressTranslation.TypeImage total visible groups type t)
      (hb : TermImage total visible groups names body b) :
      TermImage total visible groups names (.lam name binder type body) (.lam t b)
  | letE (name type value body t v b) (ht : RegularIngressTranslation.TypeImage total visible groups type t)
      (hv : TermImage total visible groups names value v) (hb : TermImage total visible groups names body b) :
      TermImage total visible groups names (.letE name type value body) (.letE t v b)
  | projection (owner field major slot value)
      (ownerType : RegularIngressTranslation.TypeImage total visible groups (.constant owner []) (.data slot))
      (majorValue : TermImage total visible groups names major value) :
      TermImage total visible groups names (.projection owner field major)
        (.app (.ordinary (.projection slot field)) value)
  | conditional (type left right yes no t l r y n)
      (ht : RegularIngressTranslation.TypeImage total visible groups type t) (sort : sourceSort t = 1)
      (hl : TermImage total visible groups names left l) (hr : TermImage total visible groups names right r)
      (hy : TermImage total visible groups names yes y) (hn : TermImage total visible groups names no n) :
      TermImage total visible groups names (conditionalSyntax type left right yes no)
        (.app (.app (.app (.app (.ordinary (.primitive (.boolEqIte t) 1 1 0 0 0)) l) r) y) n)

theorem projection_owner_image (total visible : Nat) (groups : List PsMinRegCorePlan)
    (owner : PsMinCoreName) (slot : Nat) (h : psMinRegCoreGroupSlot total visible groups owner = some slot) :
    RegularIngressTranslation.TypeImage total visible groups (.constant owner []) (.data slot) := by
  obtain ⟨plan, member, identity, seen, bounded, position⟩ :=
    RegularIngressModel.group_slot_identity _ _ _ _ _ h
  rw [position]
  exact .nominal owner plan member identity seen bounded

theorem term_translation (fuel total visible : Nat) (groups : List PsMinRegCorePlan) (names : List PsMinCoreName)
    (source : PsMinCoreExpr) (term : PsMinRegCoreTerm)
    (h : psMinRegCoreTranslate fuel total visible groups names source = some term) : TermImage total visible groups names source term := by
  induction fuel generalizing source term with
  | zero => simp [psMinRegCoreTranslate] at h
  | succ fuel ih =>
    cases hv : psMinCoreConditionalView source with
    | some view =>
      simp only [psMinRegCoreTranslate, hv] at h
      cases ht : psMinRegCoreType 256 total visible groups view.type with
      | none => simp [ht] at h
      | some t =>
        simp only [ht] at h
        split at h
        next sort =>
          cases hl : psMinRegCoreTranslate fuel total visible groups names view.left with
          | none => simp [ht, hl] at h
          | some l =>
            cases hr : psMinRegCoreTranslate fuel total visible groups names view.right with
            | none => simp [ht, hl, hr] at h
            | some r =>
              cases hy : psMinRegCoreTranslate fuel total visible groups names view.yes with
              | none => simp [ht, hl, hr, hy] at h
              | some y =>
                cases hn : psMinRegCoreTranslate fuel total visible groups names view.no with
                | none => simp [ht, hl, hr, hy, hn] at h
                | some n =>
                  simp only [ht, hl, hr, hy, hn, Option.some.injEq] at h
                  subst term
                  rw [conditional_exact _ _ hv]
                  exact .conditional _ _ _ _ _ _ _ _ _ _ (RegularIngressTranslation.type_translation _ _ _ _ _ _ ht) ((isType_iff t).mp sort)
                    (ih _ _ hl) (ih _ _ hr) (ih _ _ hy) (ih _ _ hn)
        next => contradiction
    | none =>
      cases hp : psMinRegCoreTypedPrimitive total visible groups source with
      | some p =>
        simp only [psMinRegCoreTranslate, hv, hp, Option.some.injEq] at h
        subst term
        exact .primitive _ _ (RegularIngressTerms.typed_primitive_translation _ _ _ _ _ hp)
      | none =>
        cases hrec : psMinRegCoreRecursor total visible groups source with
        | some primitive =>
          simp only [psMinRegCoreTranslate, hv, hp, hrec, Option.some.injEq] at h
          subst term
          exact .recursor _ _ (recursor_translation _ _ _ _ _ hrec)
        | none =>
          cases source with
          | bvar index =>
            simp only [psMinRegCoreTranslate, hv, hp, hrec, Option.some.injEq] at h
            subst term
            exact .variable index
          | natural value =>
            simp only [psMinRegCoreTranslate, hv, hp, hrec, Option.some.injEq] at h
            subst term
            exact .natural value
          | constant name levels =>
            simp only [psMinRegCoreTranslate, hv, hp, hrec] at h
            split at h
            next emptyLevels =>
              have hl := byteEq_sound _ _ emptyLevels
              subst levels
              cases hb : psMinCorePrimitive name with
              | some p =>
                simp only [hb, Option.some.injEq] at h
                subst term
                exact .primitive _ _ (RegularIngressTerms.primitive_translation _ _ _ _ _ hb)
              | none =>
                cases hc : psMinRegCoreFindConstructor total visible groups name with
                | some binding =>
                  simp only [hb, hc, Option.some.injEq] at h
                  subst term
                  exact .construct name binding.slot binding.index
                    (constructor_binding _ _ _ _ _ hc)
                | none =>
                  cases hr : psMinCoreResolve names name with
                  | none => simp [hb, hc, hr] at h
                  | some index =>
                    simp only [hb, hc, hr, Option.some.injEq] at h
                    subst term
                    exact .constant _ _ (resolve_preserves_identity _ _ _ hr)
            next => contradiction
          | app fn arg =>
            cases hf : psMinRegCoreTranslate fuel total visible groups names fn with
            | none => simp [psMinRegCoreTranslate, hv, hp, hrec, hf] at h
            | some f =>
              cases ha : psMinRegCoreTranslate fuel total visible groups names arg with
              | none => simp [psMinRegCoreTranslate, hv, hp, hrec, hf, ha] at h
              | some a =>
                simp only [psMinRegCoreTranslate, hv, hp, hrec, hf, ha, Option.some.injEq] at h
                subst term
                exact .app _ _ _ _ (ih _ _ hf) (ih _ _ ha)
          | lam name binder type body =>
            cases ht : psMinRegCoreType 256 total visible groups type with
            | none => simp [psMinRegCoreTranslate, hv, hp, hrec, ht] at h
            | some t =>
              cases hb : psMinRegCoreTranslate fuel total visible groups names body with
              | none => simp [psMinRegCoreTranslate, hv, hp, hrec, ht, hb] at h
              | some b =>
                simp only [psMinRegCoreTranslate, hv, hp, hrec, ht, hb, Option.some.injEq] at h
                subst term
                exact .lam _ _ _ _ _ _ (RegularIngressTranslation.type_translation _ _ _ _ _ _ ht) (ih _ _ hb)
          | letE name type value body =>
            cases ht : psMinRegCoreType 256 total visible groups type with
            | none => simp [psMinRegCoreTranslate, hv, hp, hrec, ht] at h
            | some t =>
              cases hvv : psMinRegCoreTranslate fuel total visible groups names value with
              | none => simp [psMinRegCoreTranslate, hv, hp, hrec, ht, hvv] at h
              | some v =>
                cases hb : psMinRegCoreTranslate fuel total visible groups names body with
                | none => simp [psMinRegCoreTranslate, hv, hp, hrec, ht, hvv, hb] at h
                | some b =>
                  simp only [psMinRegCoreTranslate, hv, hp, hrec, ht, hvv, hb, Option.some.injEq] at h
                  subst term
                  exact .letE _ _ _ _ _ _ _ (RegularIngressTranslation.type_translation _ _ _ _ _ _ ht) (ih _ _ hvv) (ih _ _ hb)
          | projection owner field major =>
            cases ho : psMinRegCoreGroupSlot total visible groups owner with
            | none => simp [psMinRegCoreTranslate, hv, hp, hrec, ho] at h
            | some slot =>
              cases hm : psMinRegCoreTranslate fuel total visible groups names major with
              | none => simp [psMinRegCoreTranslate, hv, hp, hrec, ho, hm] at h
              | some value =>
                simp only [psMinRegCoreTranslate, hv, hp, hrec, ho, hm, Option.some.injEq] at h
                subst term
                exact .projection owner field major slot value
                  (projection_owner_image _ _ _ _ _ ho) (ih _ _ hm)
          | _ => simp [psMinRegCoreTranslate, hv, hp, hrec] at h


#print axioms projection_owner_image
#print axioms term_translation
end Ps.MinKernel.RegularIngressSource
