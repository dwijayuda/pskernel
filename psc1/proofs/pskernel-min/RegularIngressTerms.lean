import RegularIngressTranslation

namespace Ps.MinKernel.RegularIngressTerms
open Ps.MinKernel.CoreIngress
open Ps.MinKernel.CoreTranslation
open Ps.MinKernel.RegularIngressTranslation

inductive ConstructorAt : List PsMinRegCoreConstructor → Nat → PsMinRegCoreConstructor → Prop where
  | here (head tail) : ConstructorAt (head :: tail) 0 head
  | there (head tail index found) (rest : ConstructorAt tail index found) :
      ConstructorAt (head :: tail) (Nat.succ index) found

theorem constructor_index_identity (constructors : List PsMinRegCoreConstructor)
    (name : PsMinCoreName) (index : Nat)
    (h : psMinRegCoreFindConstructorIndex constructors name = some index) :
    ∃ ctor, ConstructorAt constructors index ctor ∧ name = ctor.name := by
  induction constructors generalizing index with
  | nil => simp [psMinRegCoreFindConstructorIndex] at h
  | cons head tail ih =>
    simp only [psMinRegCoreFindConstructorIndex] at h
    split at h
    next same =>
      cases h
      exact ⟨head, .here head tail, nameEq_sound _ _ same⟩
    next =>
      cases hn : psMinRegCoreFindConstructorIndex tail name with
      | none => simp [hn] at h
      | some next =>
        simp only [hn, Option.some.injEq] at h
        subst index
        obtain ⟨ctor, member, identity⟩ := ih next hn
        exact ⟨ctor, .there head tail next ctor member, identity⟩

inductive ConstructorBinding (total visible : Nat) (groups : List PsMinRegCorePlan) :
    PsMinCoreName → Nat → Nat → Prop where
  | bound (plan : PsMinRegCorePlan) (ctor : PsMinRegCoreConstructor) (index : Nat)
      (member : plan ∈ groups) (position : ConstructorAt plan.source.constructors index ctor)
      (seen : plan.ordinal < visible) (bounded : plan.ordinal < total) :
      ConstructorBinding total visible groups ctor.name (total - (plan.ordinal + 1)) index

theorem constructor_binding (total visible : Nat) (groups : List PsMinRegCorePlan)
    (name : PsMinCoreName) (binding : PsMinRegCoreConstructorBinding)
    (h : psMinRegCoreFindConstructor total visible groups name = some binding) :
    ConstructorBinding total visible groups name binding.slot binding.index := by
  induction groups with
  | nil => simp [psMinRegCoreFindConstructor] at h
  | cons plan tail ih =>
    simp only [psMinRegCoreFindConstructor] at h
    split at h
    next seen =>
      split at h
      next bounded =>
        cases hc : psMinRegCoreFindConstructorIndex plan.source.constructors name with
        | some index =>
          simp only [hc, Option.some.injEq] at h
          subst binding
          obtain ⟨ctor, position, identity⟩ := constructor_index_identity _ _ _ hc
          rw [identity]
          exact .bound plan ctor index List.mem_cons_self position
            (by simpa only [Nat.blt_eq] using seen)
            (by simpa only [Nat.blt_eq] using bounded)
        | none =>
          have rest := ih (by simpa only [hc] using h)
          cases rest with
          | bound found ctor index member position visible bound =>
            exact .bound found ctor index (List.mem_cons_of_mem plan member) position visible bound
      next =>
        have rest := ih h
        cases rest with
        | bound found ctor index member position visible bound =>
          exact .bound found ctor index (List.mem_cons_of_mem plan member) position visible bound
    next =>
      have rest := ih h
      cases rest with
      | bound found ctor index member position visible bound =>
        exact .bound found ctor index (List.mem_cons_of_mem plan member) position visible bound

inductive RecursorBinding (total visible : Nat) (groups : List PsMinRegCorePlan) :
    PsMinCoreName → PsMinCoreName → Nat → Nat → Prop where
  | bound (plan : PsMinRegCorePlan) (member : plan ∈ groups)
      (seen : plan.ordinal < visible) (bounded : plan.ordinal < total) :
      RecursorBinding total visible groups (psMinRegCoreRecName plan.source.name)
        plan.source.name (total - (plan.ordinal + 1)) plan.spec.minors

theorem recursor_binding (total visible : Nat) (groups : List PsMinRegCorePlan)
    (name : PsMinCoreName) (binding : PsMinRegCoreRecursorBinding)
    (h : psMinRegCoreFindRecursor total visible groups name = some binding) :
    RecursorBinding total visible groups name binding.owner binding.slot binding.minors := by
  induction groups with
  | nil => simp [psMinRegCoreFindRecursor] at h
  | cons plan tail ih =>
    simp only [psMinRegCoreFindRecursor] at h
    split at h
    next same =>
      split at h
      next seen =>
        split at h
        next bounded =>
          cases h
          rw [nameEq_sound _ _ same]
          exact .bound plan List.mem_cons_self
            (by simpa only [Nat.blt_eq] using seen) (by simpa only [Nat.blt_eq] using bounded)
        next => contradiction
      next => contradiction
    next =>
      have rest := ih h
      cases rest with
      | bound found member seen bounded =>
        exact .bound found (List.mem_cons_of_mem plan member) seen bounded

inductive MotiveImage (total visible : Nat) (groups : List PsMinRegCorePlan)
    (domain : PsMinCoreExpr) : PsMinCoreExpr → PsMinRegTy → Prop where
  | constant (name binder body code)
      (meaning : RegularIngressTranslation.TypeImage total visible groups body code)
      (sort : sourceSort code = 1) :
      MotiveImage total visible groups domain (.lam name binder domain body) code

theorem motive_translation (total visible : Nat) (groups : List PsMinRegCorePlan)
    (domain motive : PsMinCoreExpr) (code : PsMinRegTy)
    (h : psMinRegCoreMotiveType total visible groups domain motive = some code) :
    MotiveImage total visible groups domain motive code := by
  cases motive with
  | lam name binder annotation body =>
    simp only [psMinRegCoreMotiveType] at h
    split at h
    next correctDomain =>
      have he := exprEq_sound _ _ _ correctDomain
      subst annotation
      cases ht : psMinRegCoreType 256 total visible groups body with
      | none => simp [ht] at h
      | some result =>
        simp only [ht] at h
        split at h
        next sort =>
          cases h
          exact .constant name binder body code
            (RegularIngressTranslation.type_translation _ _ _ _ _ _ ht)
            ((isType_iff code).mp sort)
        next => contradiction
    next => contradiction
  | _ => simp [psMinRegCoreMotiveType] at h

inductive PrimitiveImage (total visible : Nat) (groups : List PsMinRegCorePlan) : PsMinCoreExpr → PsMinOpTerm → Prop where
  | head0 : PrimitiveImage total visible groups (.constant (.str (.str PsMinCoreName.anonymous [85, 110, 105, 116]) [117, 110, 105, 116]) []) (.base .unit)
  | head1 : PrimitiveImage total visible groups (.constant (.str (.str PsMinCoreName.anonymous [66, 111, 111, 108]) [102, 97, 108, 115, 101]) []) (.base (.boolean false))
  | head2 : PrimitiveImage total visible groups (.constant (.str (.str PsMinCoreName.anonymous [66, 111, 111, 108]) [116, 114, 117, 101]) []) (.base (.boolean true))
  | head3 : PrimitiveImage total visible groups (.constant (.str (.str PsMinCoreName.anonymous [78, 97, 116]) [122, 101, 114, 111]) []) (.base (.nat 0))
  | head4 : PrimitiveImage total visible groups (.constant (.str (.str PsMinCoreName.anonymous [78, 97, 116]) [115, 117, 99, 99]) []) (.primitive .natSucc 0 0 0 0 0)
  | head5 : PrimitiveImage total visible groups (.constant (.str (.str PsMinCoreName.anonymous [78, 97, 116]) [97, 100, 100]) []) (.primitive .natAdd 0 0 0 0 0)
  | head6 : PrimitiveImage total visible groups (.constant (.str (.str PsMinCoreName.anonymous [78, 97, 116]) [115, 117, 98]) []) (.primitive .natSub 0 0 0 0 0)
  | head7 : PrimitiveImage total visible groups (.constant (.str (.str PsMinCoreName.anonymous [78, 97, 116]) [98, 101, 113]) []) (.primitive .natBeq 0 0 0 0 0)
  | head8 : PrimitiveImage total visible groups (.constant (.str (.str PsMinCoreName.anonymous [78, 97, 116]) [98, 108, 116]) []) (.primitive .natBlt 0 0 0 0 0)
  | listNil (element a) (ha : RegularIngressTranslation.TypeImage total visible groups element a) (sort : sourceSort a = 1) :
      PrimitiveImage total visible groups (.app (.constant (.str (.str PsMinCoreName.anonymous [76, 105, 115, 116]) [110, 105, 108]) []) element) (.primitive (.listNil a) 0 1 0 0 0)
  | listCons (element a) (ha : RegularIngressTranslation.TypeImage total visible groups element a) (sort : sourceSort a = 1) :
      PrimitiveImage total visible groups (.app (.constant (.str (.str PsMinCoreName.anonymous [76, 105, 115, 116]) [99, 111, 110, 115]) []) element) (.primitive (.listCons a) 0 1 0 0 0)
  | optionNone (element a) (ha : RegularIngressTranslation.TypeImage total visible groups element a) (sort : sourceSort a = 1) :
      PrimitiveImage total visible groups (.app (.constant (.str (.str PsMinCoreName.anonymous [79, 112, 116, 105, 111, 110]) [110, 111, 110, 101]) []) element) (.primitive (.optionNone a) 0 1 0 0 0)
  | optionSome (element a) (ha : RegularIngressTranslation.TypeImage total visible groups element a) (sort : sourceSort a = 1) :
      PrimitiveImage total visible groups (.app (.constant (.str (.str PsMinCoreName.anonymous [79, 112, 116, 105, 111, 110]) [115, 111, 109, 101]) []) element) (.primitive (.optionSome a) 0 1 0 0 0)

theorem primitive_translation (total visible : Nat) (groups : List PsMinRegCorePlan) (name : PsMinCoreName) (term : PsMinOpTerm)
    (h : psMinCorePrimitive name = some term) : PrimitiveImage total visible groups (.constant name []) term := by
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

theorem typed_primitive_translation (total visible : Nat) (groups : List PsMinRegCorePlan) (source : PsMinCoreExpr) (term : PsMinOpTerm)
    (h : psMinRegCoreTypedPrimitive total visible groups source = some term) : PrimitiveImage total visible groups source term := by
  cases source with
  | app fn element =>
    cases fn with
    | constant name levels =>
      simp only [psMinRegCoreTypedPrimitive] at h
      split at h
      next correctLevels =>
        have hl := byteEq_sound _ _ correctLevels
        subst levels
        cases ht : psMinRegCoreType 256 total visible groups element with
        | none => simp [ht] at h
        | some a =>
          simp only [ht] at h
          repeat' split at h
          all_goals try contradiction
          all_goals cases h
          all_goals first
            | simpa only [nameEq_sound _ _ (by assumption)] using PrimitiveImage.listNil element a (RegularIngressTranslation.type_translation _ _ _ _ _ _ ht) ((isType_iff a).mp (by assumption))
            | simpa only [nameEq_sound _ _ (by assumption)] using PrimitiveImage.listCons element a (RegularIngressTranslation.type_translation _ _ _ _ _ _ ht) ((isType_iff a).mp (by assumption))
            | simpa only [nameEq_sound _ _ (by assumption)] using PrimitiveImage.optionNone element a (RegularIngressTranslation.type_translation _ _ _ _ _ _ ht) ((isType_iff a).mp (by assumption))
            | simpa only [nameEq_sound _ _ (by assumption)] using PrimitiveImage.optionSome element a (RegularIngressTranslation.type_translation _ _ _ _ _ _ ht) ((isType_iff a).mp (by assumption))
      next => contradiction
    | _ => simp [psMinRegCoreTypedPrimitive] at h
  | _ => simp [psMinRegCoreTypedPrimitive] at h


#print axioms constructor_index_identity
#print axioms constructor_binding
#print axioms recursor_binding
#print axioms motive_translation
#print axioms primitive_translation
#print axioms typed_primitive_translation
end Ps.MinKernel.RegularIngressTerms
