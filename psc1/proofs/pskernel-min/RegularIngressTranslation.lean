import RegularIngressModel
import Ps.MinKernel.Profile.RegularIngressOperational
import CoreTranslation

-- A user recursor's result code belongs to its own family/older prefix.
-- Lowering is partial: references to newer families cannot be represented by R2.
def psMinRegCoreLowerType (fuel amount : Nat) (type : PsMinRegTy) : Option PsMinRegTy :=
  match fuel with
  | Nat.zero => Option.none
  | Nat.succ remaining =>
    match type with
    | .empty => Option.some PsMinRegTy.empty
    | .unit => Option.some PsMinRegTy.unit
    | .nat => Option.some PsMinRegTy.nat
    | .boolean => Option.some PsMinRegTy.boolean
    | .data index => if Nat.blt index amount then Option.none else
        Option.some (PsMinRegTy.data (Nat.sub index amount))
    | .arr domain result =>
      match psMinRegCoreLowerType remaining amount domain with
      | Option.none => Option.none
      | Option.some a => match psMinRegCoreLowerType remaining amount result with
        | Option.none => Option.none
        | Option.some b => Option.some (PsMinRegTy.arr a b)
    | .list element => match psMinRegCoreLowerType remaining amount element with
      | Option.none => Option.none
      | Option.some a => Option.some (PsMinRegTy.list a)
    | .option element => match psMinRegCoreLowerType remaining amount element with
      | Option.none => Option.none
      | Option.some a => Option.some (PsMinRegTy.option a)


namespace Ps.MinKernel.RegularIngressTranslation
open Ps.MinKernel.CoreIngress
open Ps.MinKernel.CoreTranslation
open Ps.MinKernel.RegularIngressModel

-- Nominal source identities and declaration visibility are retained separately
-- from the relative data code used by the normalized checker.
inductive TypeImage (total visible : Nat) (groups : List PsMinRegCorePlan) :
    PsMinCoreExpr → PsMinRegTy → Prop where
  | foundation (source code) (meaning : CoreTranslation.TypeImage source code) :
      TypeImage total visible groups source code
  | nominal (name : PsMinCoreName) (plan : PsMinRegCorePlan)
      (member : plan ∈ groups) (identity : name = plan.source.name)
      (seen : plan.ordinal < visible) (bounded : plan.ordinal < total) :
      TypeImage total visible groups (.constant name [])
        (.data (total - (plan.ordinal + 1)))
  | arr (name binder domain body a b)
      (ha : TypeImage total visible groups domain a)
      (hb : TypeImage total visible groups body b) :
      TypeImage total visible groups (.forallE name binder domain body) (.arr a b)
  | list (element a) (ha : TypeImage total visible groups element a) (sort : sourceSort a = 1) :
      TypeImage total visible groups
        (.app (.constant (.str PsMinCoreName.anonymous [76,105,115,116]) []) element) (.list a)
  | option (element a) (ha : TypeImage total visible groups element a) (sort : sourceSort a = 1) :
      TypeImage total visible groups
        (.app (.constant (.str PsMinCoreName.anonymous [79,112,116,105,111,110]) []) element) (.option a)

theorem type_translation (fuel total visible : Nat) (groups : List PsMinRegCorePlan)
    (source : PsMinCoreExpr) (code : PsMinRegTy)
    (h : psMinRegCoreType fuel total visible groups source = some code) :
    TypeImage total visible groups source code := by
  induction fuel generalizing source code with
  | zero => simp [psMinRegCoreType] at h
  | succ fuel ih =>
    cases source with
    | constant name levels =>
      simp only [psMinRegCoreType] at h
      split at h
      next correctLevels =>
        have hl := byteEq_sound _ _ correctLevels
        subst levels
        cases hb : psMinCoreType (Nat.succ fuel) (.constant name []) with
        | some base =>
          simp only [hb, Option.some.injEq] at h
          subst code
          exact .foundation _ _ (CoreTranslation.type_translation _ _ _ hb)
        | none =>
          cases hn : psMinRegCoreGroupSlot total visible groups name with
          | none => simp [hb, hn] at h
          | some slot =>
            simp only [hb, hn, Option.some.injEq] at h
            subst code
            obtain ⟨plan, member, identity, seen, bounded, position⟩ :=
              group_slot_identity _ _ _ _ _ hn
            rw [position]
            exact .nominal name plan member identity seen bounded
      next => contradiction
    | forallE name binder domain body =>
      cases hd : psMinRegCoreType fuel total visible groups domain with
      | none => simp [psMinRegCoreType, hd] at h
      | some a =>
        cases hb : psMinRegCoreType fuel total visible groups body with
        | none => simp [psMinRegCoreType, hd, hb] at h
        | some b =>
          simp only [psMinRegCoreType, hd, hb, Option.some.injEq] at h
          subst code
          exact .arr name binder domain body a b (ih _ _ hd) (ih _ _ hb)
    | app fn element =>
      cases fn with
      | constant name levels =>
        simp only [psMinRegCoreType] at h
        split at h
        next correctLevels =>
          have hl := byteEq_sound _ _ correctLevels
          subst levels
          cases ht : psMinRegCoreType fuel total visible groups element with
          | none => simp [ht] at h
          | some a =>
            simp only [ht] at h
            repeat' split at h
            all_goals try contradiction
            all_goals cases h
            all_goals first
              | simpa only [nameEq_sound _ _ (by assumption)] using
                  TypeImage.list element a (ih _ _ ht) ((isType_iff a).mp (by assumption))
              | simpa only [nameEq_sound _ _ (by assumption)] using
                  TypeImage.option element a (ih _ _ ht) ((isType_iff a).mp (by assumption))
        next => contradiction
      | _ => simp [psMinRegCoreType] at h
    | _ => simp [psMinRegCoreType] at h

theorem type_closed (total visible : Nat) (groups : List PsMinRegCorePlan)
    (source : PsMinCoreExpr) (code : PsMinRegTy) (h : TypeImage total visible groups source code) :
    noTypeVariables source := by
  induction h with
  | foundation source code meaning => exact CoreTranslation.type_closed _ _ meaning
  | nominal => trivial
  | arr => exact ⟨by assumption, by assumption⟩
  | list => exact ⟨trivial, by assumption⟩
  | option => exact ⟨trivial, by assumption⟩

inductive FieldImage (older : Nat) (groups : List PsMinRegCorePlan) (owner : PsMinCoreName) :
    PsMinCoreExpr → PsMinRegField → Prop where
  | recursive : FieldImage older groups owner (.constant owner []) .recursive
  | ground (source code) (meaning : TypeImage older older groups source code)
      (notSelf : psMinRegCoreNoOwner 256 owner source = true) :
      FieldImage older groups owner source (.ground code)

theorem ground_field_translation (older : Nat) (groups : List PsMinRegCorePlan) (owner : PsMinCoreName)
    (source : PsMinCoreExpr) (field : PsMinRegField)
    (h : psMinRegCoreGroundField older groups owner source = some field) :
    FieldImage older groups owner source field := by
  unfold psMinRegCoreGroundField at h
  split at h
  next notSelf =>
    cases ht : psMinRegCoreType 256 older older groups source with
    | none => simp [ht] at h
    | some code =>
      simp only [ht, Option.some.injEq] at h
      subst field
      exact .ground source code (type_translation _ _ _ _ _ _ ht) notSelf
  next => contradiction

theorem field_translation (older : Nat) (groups : List PsMinRegCorePlan) (owner : PsMinCoreName)
    (source : PsMinCoreExpr) (field : PsMinRegField)
    (h : psMinRegCoreField older groups owner source = some field) :
    FieldImage older groups owner source field := by
  cases source with
  | constant name levels =>
    simp only [psMinRegCoreField] at h
    split at h
    next levelsEmpty =>
      have hl := byteEq_sound _ _ levelsEmpty
      subst levels
      split at h
      next same =>
        have hn := nameEq_sound _ _ same
        subst name
        cases h
        exact .recursive
      next => exact ground_field_translation _ _ _ _ _ h
    next => contradiction
  | _ => exact ground_field_translation _ _ _ _ _ h

inductive ConstructorFields (older : Nat) (groups : List PsMinRegCorePlan) (owner : PsMinCoreName) :
    PsMinCoreExpr → List PsMinRegField → Prop where
  | result : ConstructorFields older groups owner (.constant owner []) []
  | field (name binder domain body code rest)
      (first : FieldImage older groups owner domain code)
      (tail : ConstructorFields older groups owner body rest) :
      ConstructorFields older groups owner (.forallE name binder domain body) (code :: rest)

theorem constructor_fields_translation (fuel older : Nat) (groups : List PsMinRegCorePlan)
    (owner : PsMinCoreName) (source : PsMinCoreExpr) (fields : List PsMinRegField)
    (h : psMinRegCoreConstructorFields fuel older groups owner source = some fields) :
    ConstructorFields older groups owner source fields := by
  induction fuel generalizing source fields with
  | zero => simp [psMinRegCoreConstructorFields] at h
  | succ fuel ih =>
    cases source with
    | constant name levels =>
      simp only [psMinRegCoreConstructorFields] at h
      repeat' split at h
      all_goals try contradiction
      all_goals have hl := byteEq_sound levels [] (by assumption)
      all_goals have hn := nameEq_sound name owner (by assumption)
      all_goals subst levels; subst name; cases h; exact .result
    | forallE name binder domain body =>
      cases hd : psMinRegCoreField older groups owner domain with
      | none => simp [psMinRegCoreConstructorFields, hd] at h
      | some field =>
        cases hb : psMinRegCoreConstructorFields fuel older groups owner body with
        | none => simp [psMinRegCoreConstructorFields, hd, hb] at h
        | some tail =>
          simp only [psMinRegCoreConstructorFields, hd, hb, Option.some.injEq] at h
          subst fields
          exact .field name binder domain body field tail
            (field_translation _ _ _ _ _ hd) (ih _ _ hb)
    | _ => simp [psMinRegCoreConstructorFields] at h



inductive AllConstructorFields (older : Nat) (groups : List PsMinRegCorePlan) (owner : PsMinCoreName) :
    List PsMinRegCoreConstructor → List (List PsMinRegField) → Prop where
  | nil : AllConstructorFields older groups owner [] []
  | cons (ctor : PsMinRegCoreConstructor) (rest fields tail)
      (head : ConstructorFields older groups owner ctor.type fields)
      (next : AllConstructorFields older groups owner rest tail) :
      AllConstructorFields older groups owner (ctor :: rest) (fields :: tail)

theorem all_constructor_fields_translation (older : Nat) (groups : List PsMinRegCorePlan)
    (owner : PsMinCoreName) (constructors : List PsMinRegCoreConstructor) (fields : List (List PsMinRegField))
    (h : psMinRegCoreAllFields older groups owner constructors = some fields) :
    AllConstructorFields older groups owner constructors fields := by
  induction constructors generalizing fields with
  | nil =>
    cases h
    exact .nil
  | cons ctor rest ih =>
    cases hh : psMinRegCoreConstructorFields 256 older groups owner ctor.type with
    | none => simp [psMinRegCoreAllFields, hh] at h
    | some head =>
      cases ht : psMinRegCoreAllFields older groups owner rest with
      | none => simp [psMinRegCoreAllFields, hh, ht] at h
      | some tail =>
        simp only [psMinRegCoreAllFields, hh, ht, Option.some.injEq] at h
        subst fields
        exact .cons ctor rest head tail (constructor_fields_translation _ _ _ _ _ _ hh) (ih _ ht)

theorem constructor_count_exact (constructors : List PsMinRegCoreConstructor) :
    psMinRegCoreConstructorCount constructors = constructors.length := by
  induction constructors with
  | nil => rfl
  | cons head rest ih => exact congrArg Nat.succ ih

inductive GroupImage (older : Nat) (groups : List PsMinRegCorePlan)
    (source : PsMinRegCoreGroup) : PsMinRegSpec → Prop where
  | regular (fields : List (List PsMinRegField))
      (sourceType : source.type = .sort 1)
      (constructorTypes : AllConstructorFields older groups source.name source.constructors fields) :
      GroupImage older groups source ⟨0, 0, 0, 1, source.constructors.length, fields⟩

theorem group_translation (initial final : PsMinRegCoreState) (source : PsMinRegCoreGroup)
    (h : psMinRegCoreBuildGroup initial source = some final) :
    ∃ spec, GroupImage initial.count initial.groups source spec ∧
      final.groups = ⟨source, spec, initial.count⟩ :: initial.groups ∧
      final.count = Nat.succ initial.count := by
  unfold psMinRegCoreBuildGroup at h
  split at h
  next freshOwner =>
    split at h
    next exactType =>
      cases hr : psMinRegCoreReserveConstructors source.constructors (source.name :: initial.used) with
      | none => simp [hr] at h
      | some used =>
        simp only [hr] at h
        split at h
        next freshRecursor =>
          cases hf : psMinRegCoreAllFields initial.count initial.groups source.name source.constructors with
          | none => simp [hf] at h
          | some fields =>
            simp only [hf] at h
            split at h
            next valid =>
              cases h
              rw [constructor_count_exact]
              exact ⟨_, .regular fields (exprEq_sound _ _ _ exactType)
                (all_constructor_fields_translation _ _ _ _ _ hf), rfl, rfl⟩
            next => contradiction
        next => contradiction
    next => contradiction
  next => contradiction

#print axioms all_constructor_fields_translation
#print axioms constructor_count_exact
#print axioms group_translation


inductive OrderedPlans : Nat → List PsMinRegCorePlan → Prop where
  | nil : OrderedPlans 0 []
  | cons (count : Nat) (source : PsMinRegCoreGroup) (spec : PsMinRegSpec)
      (groups : List PsMinRegCorePlan) (rest : OrderedPlans count groups) :
      OrderedPlans (Nat.succ count) (⟨source, spec, count⟩ :: groups)

theorem ordered_member_bound (count : Nat) (groups : List PsMinRegCorePlan)
    (order : OrderedPlans count groups) (plan : PsMinRegCorePlan) (member : plan ∈ groups) :
    plan.ordinal < count := by
  induction order with
  | nil => cases member
  | cons count source spec groups rest ih =>
    cases member with
    | head => exact Nat.lt_succ_self count
    | tail _ member => exact Nat.lt_trans (ih member) (Nat.lt_succ_self count)

theorem ordered_member_spec (count : Nat) (groups : List PsMinRegCorePlan)
    (order : OrderedPlans count groups) (plan : PsMinRegCorePlan) (member : plan ∈ groups) :
    psMinRegCoreSpecAt (psMinRegCoreSpecs groups) (count - (plan.ordinal + 1)) = some plan.spec := by
  induction order with
  | nil => cases member
  | cons count source spec groups rest ih =>
    cases member with
    | head =>
      simp only [Nat.succ_eq_add_one, Nat.sub_self, psMinRegCoreSpecs, psMinRegCoreSpecAt]
    | tail _ member =>
      have bounded : plan.ordinal + 1 ≤ count :=
        Nat.succ_le_of_lt (ordered_member_bound count groups rest plan member)
      have position : Nat.succ count - (plan.ordinal + 1) = Nat.succ (count - (plan.ordinal + 1)) :=
        Nat.succ_sub bounded
      rw [position]
      exact ih member

theorem build_plans_order (fuel : Nat) (entries : List PsMinRegCoreEntry)
    (initial final : PsMinRegCoreState) (order : OrderedPlans initial.count initial.groups)
    (h : psMinRegCoreBuildPlans fuel entries initial = some final) :
    OrderedPlans final.count final.groups := by
  induction fuel generalizing entries initial final with
  | zero =>
    cases entries with
    | nil => cases h; exact order
    | cons entry rest => simp [psMinRegCoreBuildPlans] at h
  | succ fuel ih =>
    cases entries with
    | nil => cases h; exact order
    | cons entry rest =>
      cases entry with
      | definition declaration =>
        simp only [psMinRegCoreBuildPlans] at h
        split at h
        next fresh => exact ih rest
          (PsMinRegCoreState.mk initial.groups (declaration.name :: initial.used) initial.count) final order h
        next => contradiction
      | inductiveE group =>
        cases hg : psMinRegCoreBuildGroup initial group with
        | none => simp [psMinRegCoreBuildPlans, hg] at h
        | some next =>
          have tail : psMinRegCoreBuildPlans fuel rest next = some final := by
            simpa only [psMinRegCoreBuildPlans, hg] using h
          obtain ⟨spec, image, groups, count⟩ := group_translation initial next group hg
          have nextOrder : OrderedPlans next.count next.groups := by
            rw [groups, count]
            exact .cons initial.count group spec initial.groups order
          exact ih rest next final nextOrder tail

theorem actual_plans_order (entries : List PsMinRegCoreEntry) (state : PsMinRegCoreState)
    (h : psMinRegCorePlans entries = some state) : OrderedPlans state.count state.groups :=
  build_plans_order 512 entries _ state OrderedPlans.nil h

#print axioms ordered_member_bound
#print axioms ordered_member_spec
#print axioms build_plans_order
#print axioms actual_plans_order

-- A mathematical ambient-code lift, independent of the partial lowering code.
def liftCode (amount : Nat) : PsMinRegTy → PsMinRegTy
  | .empty => .empty
  | .unit => .unit
  | .nat => .nat
  | .boolean => .boolean
  | .data index => .data (index + amount)
  | .arr domain result => .arr (liftCode amount domain) (liftCode amount result)
  | .list element => .list (liftCode amount element)
  | .option element => .option (liftCode amount element)

theorem liftCode_zero (type : PsMinRegTy) : liftCode 0 type = type := by
  induction type <;> simp_all [liftCode]

theorem liftCode_one (type : PsMinRegTy) : liftCode 1 type = psMinRegLiftTy type := by
  induction type <;> simp_all [liftCode, psMinRegLiftTy]

theorem liftCode_add (a b : Nat) (type : PsMinRegTy) :
    liftCode (a + b) type = liftCode b (liftCode a type) := by
  induction type <;> simp_all [liftCode, Nat.add_assoc]

theorem lower_type_restores (fuel amount : Nat) (type lowered : PsMinRegTy)
    (h : psMinRegCoreLowerType fuel amount type = some lowered) :
    liftCode amount lowered = type := by
  induction fuel generalizing type lowered with
  | zero => simp [psMinRegCoreLowerType] at h
  | succ fuel ih =>
    cases type with
    | data index =>
      simp only [psMinRegCoreLowerType] at h
      split at h
      next => contradiction
      next bounded =>
        cases h
        have bound : amount ≤ index := Nat.le_of_not_gt (by simpa only [Nat.blt_eq] using bounded)
        exact congrArg PsMinRegTy.data (Nat.sub_add_cancel bound)
    | arr domain result =>
      cases hd : psMinRegCoreLowerType fuel amount domain with
      | none => simp [psMinRegCoreLowerType, hd] at h
      | some a =>
        cases hr : psMinRegCoreLowerType fuel amount result with
        | none => simp [psMinRegCoreLowerType, hd, hr] at h
        | some b =>
          simp only [psMinRegCoreLowerType, hd, hr, Option.some.injEq] at h
          subst lowered
          exact congr_binary PsMinRegTy.arr (ih _ _ hd) (ih _ _ hr)
    | list element =>
      cases ht : psMinRegCoreLowerType fuel amount element with
      | none => simp [psMinRegCoreLowerType, ht] at h
      | some a =>
        simp only [psMinRegCoreLowerType, ht, Option.some.injEq] at h
        subst lowered
        exact congrArg PsMinRegTy.list (ih _ _ ht)
    | option element =>
      cases ht : psMinRegCoreLowerType fuel amount element with
      | none => simp [psMinRegCoreLowerType, ht] at h
      | some a =>
        simp only [psMinRegCoreLowerType, ht, Option.some.injEq] at h
        subst lowered
        exact congrArg PsMinRegTy.option (ih _ _ ht)
    | _ =>
      simp only [psMinRegCoreLowerType, Option.some.injEq] at h
      subst lowered
      rfl

#print axioms liftCode_zero
#print axioms liftCode_one
#print axioms liftCode_add
#print axioms lower_type_restores

#print axioms type_translation
#print axioms type_closed
#print axioms ground_field_translation
#print axioms field_translation
#print axioms constructor_fields_translation
end Ps.MinKernel.RegularIngressTranslation
