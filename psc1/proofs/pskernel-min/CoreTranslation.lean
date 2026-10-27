import CoreIngress
import OperationalSource

namespace Ps.MinKernel.CoreTranslation
open Ps.MinKernel.CoreIngress

-- Independent grammar for the first canonical domain. There is no axiom,
-- arbitrary name/hash predicate, dependent alias or generic proof erasure rule.
inductive TypeImage : PsMinCoreExpr → PsMinRegTy → Prop where
  | empty : TypeImage (.constant (.str PsMinCoreName.anonymous [95, 112, 115, 99, 49, 79, 114, 100, 101, 114, 70, 97, 108, 115, 101]) []) .empty
  | unit : TypeImage (.constant (.str PsMinCoreName.anonymous [85, 110, 105, 116]) []) .unit
  | nat : TypeImage (.constant (.str PsMinCoreName.anonymous [78, 97, 116]) []) .nat
  | boolean : TypeImage (.constant (.str PsMinCoreName.anonymous [66, 111, 111, 108]) []) .boolean
  | arr (name binder domain body a b) (ha : TypeImage domain a) (hb : TypeImage body b) :
      TypeImage (.forallE name binder domain body) (.arr a b)
  | list (element a) (ha : TypeImage element a) :
      TypeImage (.app (.constant (.str PsMinCoreName.anonymous [76, 105, 115, 116]) []) element) (.list a)
  | option (element a) (ha : TypeImage element a) :
      TypeImage (.app (.constant (.str PsMinCoreName.anonymous [79, 112, 116, 105, 111, 110]) []) element) (.option a)

theorem type_translation (fuel : Nat) (expr : PsMinCoreExpr) (code : PsMinRegTy)
    (h : psMinCoreType fuel expr = some code) : TypeImage expr code := by
  induction fuel generalizing expr code with
  | zero => simp [psMinCoreType] at h
  | succ fuel ih =>
    cases expr with
    | constant name levels =>
      simp only [psMinCoreType] at h
      split at h
      next levelsEmpty =>
        have hl := byteEq_sound _ _ levelsEmpty
        subst levels
        repeat' split at h
        all_goals try contradiction
        all_goals cases h
        all_goals first
          | simpa only [nameEq_sound _ _ (by assumption)] using TypeImage.empty
          | simpa only [nameEq_sound _ _ (by assumption)] using TypeImage.unit
          | simpa only [nameEq_sound _ _ (by assumption)] using TypeImage.nat
          | simpa only [nameEq_sound _ _ (by assumption)] using TypeImage.boolean
      next => contradiction
    | forallE name binder domain body =>
      cases hd : psMinCoreType fuel domain with
      | none => simp [psMinCoreType, hd] at h
      | some a =>
        cases hb : psMinCoreType fuel body with
        | none => simp [psMinCoreType, hd, hb] at h
        | some b =>
          simp only [psMinCoreType, hd, hb, Option.some.injEq] at h
          subst code
          exact .arr name binder domain body a b (ih _ _ hd) (ih _ _ hb)
    | app fn arg =>
      cases fn with
      | constant name levels =>
        simp only [psMinCoreType] at h
        split at h
        next correctLevels =>
          have hl := byteEq_sound _ _ correctLevels
          subst levels
          cases ht : psMinCoreType fuel arg with
          | none => simp [ht] at h
          | some a =>
            simp only [ht] at h
            repeat' split at h
            all_goals try contradiction
            all_goals cases h
            all_goals first
              | simpa only [nameEq_sound _ _ (by assumption)] using TypeImage.list arg a (ih _ _ ht)
              | simpa only [nameEq_sound _ _ (by assumption)] using TypeImage.option arg a (ih _ _ ht)
        next => contradiction
      | _ => simp [psMinCoreType] at h
    | _ => simp [psMinCoreType] at h

def noTypeVariables : PsMinCoreExpr → Prop
  | .bvar _ => False
  | .constant _ _ => True
  | .app fn arg => noTypeVariables fn ∧ noTypeVariables arg
  | .forallE _ _ domain body => noTypeVariables domain ∧ noTypeVariables body
  | _ => False

theorem type_closed (source : PsMinCoreExpr) (code : PsMinRegTy) (h : TypeImage source code) :
    noTypeVariables source := by
  induction h <;> simp_all [noTypeVariables]

inductive PrimitiveImage : PsMinCoreExpr → PsMinOpTerm → Prop where
  | head0 : PrimitiveImage (.constant (.str (.str PsMinCoreName.anonymous [85, 110, 105, 116]) [117, 110, 105, 116]) []) (.base .unit)
  | head1 : PrimitiveImage (.constant (.str (.str PsMinCoreName.anonymous [66, 111, 111, 108]) [102, 97, 108, 115, 101]) []) (.base (.boolean false))
  | head2 : PrimitiveImage (.constant (.str (.str PsMinCoreName.anonymous [66, 111, 111, 108]) [116, 114, 117, 101]) []) (.base (.boolean true))
  | head3 : PrimitiveImage (.constant (.str (.str PsMinCoreName.anonymous [78, 97, 116]) [122, 101, 114, 111]) []) (.base (.nat 0))
  | head4 : PrimitiveImage (.constant (.str (.str PsMinCoreName.anonymous [78, 97, 116]) [115, 117, 99, 99]) []) (.primitive .natSucc 0 0 0 0 0)
  | head5 : PrimitiveImage (.constant (.str (.str PsMinCoreName.anonymous [78, 97, 116]) [97, 100, 100]) []) (.primitive .natAdd 0 0 0 0 0)
  | head6 : PrimitiveImage (.constant (.str (.str PsMinCoreName.anonymous [78, 97, 116]) [115, 117, 98]) []) (.primitive .natSub 0 0 0 0 0)
  | head7 : PrimitiveImage (.constant (.str (.str PsMinCoreName.anonymous [78, 97, 116]) [98, 101, 113]) []) (.primitive .natBeq 0 0 0 0 0)
  | head8 : PrimitiveImage (.constant (.str (.str PsMinCoreName.anonymous [78, 97, 116]) [98, 108, 116]) []) (.primitive .natBlt 0 0 0 0 0)
  | listNil (element a) (ha : TypeImage element a) :
      PrimitiveImage (.app (.constant (.str (.str PsMinCoreName.anonymous [76, 105, 115, 116]) [110, 105, 108]) []) element) (.primitive (.listNil a) 0 1 0 0 0)
  | listCons (element a) (ha : TypeImage element a) :
      PrimitiveImage (.app (.constant (.str (.str PsMinCoreName.anonymous [76, 105, 115, 116]) [99, 111, 110, 115]) []) element) (.primitive (.listCons a) 0 1 0 0 0)
  | optionNone (element a) (ha : TypeImage element a) :
      PrimitiveImage (.app (.constant (.str (.str PsMinCoreName.anonymous [79, 112, 116, 105, 111, 110]) [110, 111, 110, 101]) []) element) (.primitive (.optionNone a) 0 1 0 0 0)
  | optionSome (element a) (ha : TypeImage element a) :
      PrimitiveImage (.app (.constant (.str (.str PsMinCoreName.anonymous [79, 112, 116, 105, 111, 110]) [115, 111, 109, 101]) []) element) (.primitive (.optionSome a) 0 1 0 0 0)

theorem primitive_translation (name : PsMinCoreName) (term : PsMinOpTerm)
    (h : psMinCorePrimitive name = some term) : PrimitiveImage (.constant name []) term := by
  unfold psMinCorePrimitive at h
  repeat' split at h
  all_goals try contradiction
  all_goals cases h
  all_goals first
    | simpa only [nameEq_sound _ _ (by assumption)] using PrimitiveImage.head0
    | simpa only [nameEq_sound _ _ (by assumption)] using PrimitiveImage.head1
    | simpa only [nameEq_sound _ _ (by assumption)] using PrimitiveImage.head2
    | simpa only [nameEq_sound _ _ (by assumption)] using PrimitiveImage.head3
    | simpa only [nameEq_sound _ _ (by assumption)] using PrimitiveImage.head4
    | simpa only [nameEq_sound _ _ (by assumption)] using PrimitiveImage.head5
    | simpa only [nameEq_sound _ _ (by assumption)] using PrimitiveImage.head6
    | simpa only [nameEq_sound _ _ (by assumption)] using PrimitiveImage.head7
    | simpa only [nameEq_sound _ _ (by assumption)] using PrimitiveImage.head8

theorem typed_primitive_translation (fuel : Nat) (source : PsMinCoreExpr) (term : PsMinOpTerm)
    (h : psMinCoreTypedPrimitive fuel source = some term) : PrimitiveImage source term := by
  cases source with
  | app fn element =>
    cases fn with
    | constant name levels =>
      simp only [psMinCoreTypedPrimitive] at h
      split at h
      next correctLevels =>
        have hl := byteEq_sound _ _ correctLevels
        subst levels
        cases ht : psMinCoreType fuel element with
        | none => simp [ht] at h
        | some a =>
          simp only [ht] at h
          repeat' split at h
          all_goals try contradiction
          all_goals cases h
          all_goals first
            | simpa only [nameEq_sound _ _ (by assumption)] using PrimitiveImage.listNil element a (type_translation _ _ _ ht)
            | simpa only [nameEq_sound _ _ (by assumption)] using PrimitiveImage.listCons element a (type_translation _ _ _ ht)
            | simpa only [nameEq_sound _ _ (by assumption)] using PrimitiveImage.optionNone element a (type_translation _ _ _ ht)
            | simpa only [nameEq_sound _ _ (by assumption)] using PrimitiveImage.optionSome element a (type_translation _ _ _ ht)
      next => contradiction
    | _ => simp [psMinCoreTypedPrimitive] at h
  | _ => simp [psMinCoreTypedPrimitive] at h

def conditionalSyntax (type left right yes no : PsMinCoreExpr) : PsMinCoreExpr :=
  .app (.app (.app (.app (.app (.constant (.str PsMinCoreName.anonymous [105, 116, 101]) [1]) type)
    (psMinCoreEquality left right)) (psMinCoreDecision left right)) yes) no

theorem conditional_exact (source : PsMinCoreExpr) (view : PsMinCoreConditional)
    (h : psMinCoreConditionalView source = some view) :
    source = conditionalSyntax view.type view.left view.right view.yes view.no := by
  cases source <;> simp only [psMinCoreConditionalView] at h
  all_goals try contradiction
  all_goals split at h
  all_goals try contradiction
  all_goals split at h
  all_goals try contradiction
  all_goals split at h
  all_goals try contradiction
  all_goals split at h
  all_goals try contradiction
  all_goals split at h
  all_goals try contradiction
  all_goals repeat' split at h
  all_goals try contradiction
  all_goals cases h
  all_goals unfold conditionalSyntax psMinCoreDecision
  all_goals congr 12
  all_goals first
    | exact nameEq_sound _ _ (by assumption)
    | exact byteEq_sound _ _ (by assumption)
    | exact exprEq_sound _ _ _ (by assumption)
    | rfl

inductive TermImage (names : List PsMinCoreName) : PsMinCoreExpr → PsMinOpTerm → Prop where
  | variable (index) : TermImage names (.bvar index) (.base (.var index))
  | natural (value) : TermImage names (.natural value) (.base (.nat value))
  | constant (name index) (identity : nameAt names index = some name) :
      TermImage names (.constant name []) (.base (.constant index))
  | primitive (source term) (image : PrimitiveImage source term) : TermImage names source term
  | app (fn arg f a) (hf : TermImage names fn f) (ha : TermImage names arg a) :
      TermImage names (.app fn arg) (.app f a)
  | lam (name binder type body t b) (ht : TypeImage type t) (hb : TermImage names body b) :
      TermImage names (.lam name binder type body) (.lam t b)
  | letE (name type value body t v b) (ht : TypeImage type t)
      (hv : TermImage names value v) (hb : TermImage names body b) :
      TermImage names (.letE name type value body) (.letE t v b)
  | conditional (type left right yes no t l r y n) (ht : TypeImage type t)
      (hl : TermImage names left l) (hr : TermImage names right r)
      (hy : TermImage names yes y) (hn : TermImage names no n) :
      TermImage names (conditionalSyntax type left right yes no)
        (.app (.app (.app (.app (.primitive (.boolEqIte t) 1 1 0 0 0) l) r) y) n)

theorem term_translation (fuel : Nat) (names : List PsMinCoreName)
    (source : PsMinCoreExpr) (term : PsMinOpTerm)
    (h : psMinCoreTranslate fuel names source = some term) : TermImage names source term := by
  induction fuel generalizing source term with
  | zero => simp [psMinCoreTranslate] at h
  | succ fuel ih =>
    cases hv : psMinCoreConditionalView source with
    | some view =>
      simp only [psMinCoreTranslate, hv] at h
      cases ht : psMinCoreType fuel view.type with
      | none => simp [ht] at h
      | some t =>
        cases hl : psMinCoreTranslate fuel names view.left with
        | none => simp [ht, hl] at h
        | some l =>
          cases hr : psMinCoreTranslate fuel names view.right with
          | none => simp [ht, hl, hr] at h
          | some r =>
            cases hy : psMinCoreTranslate fuel names view.yes with
            | none => simp [ht, hl, hr, hy] at h
            | some y =>
              cases hn : psMinCoreTranslate fuel names view.no with
              | none => simp [ht, hl, hr, hy, hn] at h
              | some n =>
                simp only [ht, hl, hr, hy, hn, Option.some.injEq] at h
                subst term
                rw [conditional_exact _ _ hv]
                exact .conditional _ _ _ _ _ _ _ _ _ _ (type_translation _ _ _ ht)
                  (ih _ _ hl) (ih _ _ hr) (ih _ _ hy) (ih _ _ hn)
    | none =>
      cases hp : psMinCoreTypedPrimitive fuel source with
      | some p =>
        simp only [psMinCoreTranslate, hv, hp, Option.some.injEq] at h
        subst term
        exact .primitive _ _ (typed_primitive_translation _ _ _ hp)
      | none =>
        cases source with
        | bvar index =>
          simp only [psMinCoreTranslate, hv, hp, Option.some.injEq] at h
          subst term
          exact .variable index
        | natural value =>
          simp only [psMinCoreTranslate, hv, hp, Option.some.injEq] at h
          subst term
          exact .natural value
        | constant name levels =>
          simp only [psMinCoreTranslate, hv, hp] at h
          split at h
          next emptyLevels =>
            have hl := byteEq_sound _ _ emptyLevels
            subst levels
            cases hb : psMinCorePrimitive name with
            | some p =>
              simp only [hb, Option.some.injEq] at h
              subst term
              exact .primitive _ _ (primitive_translation _ _ hb)
            | none =>
              cases hr : psMinCoreResolve names name with
              | none => simp [hb, hr] at h
              | some index =>
                simp only [hb, hr, Option.some.injEq] at h
                subst term
                exact .constant _ _ (resolve_preserves_identity _ _ _ hr)
          next => contradiction
        | app fn arg =>
          cases hf : psMinCoreTranslate fuel names fn with
          | none => simp [psMinCoreTranslate, hv, hp, hf] at h
          | some f =>
            cases ha : psMinCoreTranslate fuel names arg with
            | none => simp [psMinCoreTranslate, hv, hp, hf, ha] at h
            | some a =>
              simp only [psMinCoreTranslate, hv, hp, hf, ha, Option.some.injEq] at h
              subst term
              exact .app _ _ _ _ (ih _ _ hf) (ih _ _ ha)
        | lam name binder type body =>
          cases ht : psMinCoreType fuel type with
          | none => simp [psMinCoreTranslate, hv, hp, ht] at h
          | some t =>
            cases hb : psMinCoreTranslate fuel names body with
            | none => simp [psMinCoreTranslate, hv, hp, ht, hb] at h
            | some b =>
              simp only [psMinCoreTranslate, hv, hp, ht, hb, Option.some.injEq] at h
              subst term
              exact .lam _ _ _ _ _ _ (type_translation _ _ _ ht) (ih _ _ hb)
        | letE name type value body =>
          cases ht : psMinCoreType fuel type with
          | none => simp [psMinCoreTranslate, hv, hp, ht] at h
          | some t =>
            cases hvv : psMinCoreTranslate fuel names value with
            | none => simp [psMinCoreTranslate, hv, hp, ht, hvv] at h
            | some v =>
              cases hb : psMinCoreTranslate fuel names body with
              | none => simp [psMinCoreTranslate, hv, hp, ht, hvv, hb] at h
              | some b =>
                simp only [psMinCoreTranslate, hv, hp, ht, hvv, hb, Option.some.injEq] at h
                subst term
                exact .letE _ _ _ _ _ _ _ (type_translation _ _ _ ht) (ih _ _ hvv) (ih _ _ hb)
        | _ => simp [psMinCoreTranslate, hv, hp] at h

-- Every translated declaration has the independent type/term grammar above.
inductive EnvironmentImage :
    List PsMinCoreName → List PsMinCoreDeclaration → List PsMinOpDeclaration → Prop where
  | nil (names) : EnvironmentImage names [] []
  | step (names) (decl : PsMinCoreDeclaration) (tail type value rest)
      (fresh : psMinCoreFresh names decl.name = true)
      (ht : TypeImage decl.type type) (hv : TermImage names decl.value value)
      (next : EnvironmentImage (decl.name :: names) tail rest) :
      EnvironmentImage names (decl :: tail) (.mk type value :: rest)

theorem environment_translation (fuel : Nat) (names source normalized)
    (h : DeclarationCorrespondence fuel names source normalized) :
    EnvironmentImage names source normalized := by
  induction h with
  | nil names => exact .nil names
  | step names decl tail type value rest fresh ht hv next ih =>
    exact .step names decl tail type value rest fresh
      (type_translation _ _ _ ht) (term_translation _ _ _ _ hv) ih

#print axioms type_translation
#print axioms type_closed
#print axioms primitive_translation
#print axioms typed_primitive_translation
#print axioms conditional_exact
#print axioms term_translation
#print axioms environment_translation
end Ps.MinKernel.CoreTranslation
