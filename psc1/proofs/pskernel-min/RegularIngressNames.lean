import RegularIngressTranslation

namespace Ps.MinKernel.RegularIngressNames
open Ps.MinKernel.CoreIngress
open Ps.MinKernel.RegularIngressTranslation

def FreshName (used : List PsMinCoreName) (name : PsMinCoreName) : Prop :=
  name ≠ .anonymous ∧ name ∉ used ∧ psMinCoreNameRoot name ∉ psMinCoreReservedRoots

inductive UniqueNames : List PsMinCoreName → Prop where
  | nil : UniqueNames []
  | cons (name used) (fresh : name ∉ used) (tail : UniqueNames used) :
      UniqueNames (name :: used)

inductive Reservations : List PsMinCoreName → List PsMinRegCoreConstructor → List PsMinCoreName → Prop where
  | nil (used) : Reservations used [] used
  | cons (used) (ctor : PsMinRegCoreConstructor) (rest final)
      (fresh : FreshName used ctor.name)
      (tail : Reservations (ctor.name :: used) rest final) :
      Reservations used (ctor :: rest) final

theorem constructor_reservations (constructors : List PsMinRegCoreConstructor)
    (initial final : List PsMinCoreName)
    (h : psMinRegCoreReserveConstructors constructors initial = some final) :
    Reservations initial constructors final := by
  induction constructors generalizing initial final with
  | nil => cases h; exact .nil initial
  | cons ctor rest ih =>
    simp only [psMinRegCoreReserveConstructors] at h
    split at h
    next fresh =>
      exact .cons initial ctor rest final (fresh_no_shadowing _ _ fresh) (ih _ _ h)
    next => contradiction

theorem reservations_unique (initial final : List PsMinCoreName) (constructors : List PsMinRegCoreConstructor)
    (history : Reservations initial constructors final) (unique : UniqueNames initial) :
    UniqueNames final := by
  revert unique
  induction history with
  | nil => intro unique; exact unique
  | cons used ctor rest final fresh tail ih =>
    intro unique
    exact ih (.cons ctor.name used fresh.2.1 unique)

inductive GroupStep (initial : PsMinRegCoreState) (source : PsMinRegCoreGroup) :
    PsMinRegCoreState → Prop where
  | regular (reserved : List PsMinCoreName) (spec : PsMinRegSpec)
      (owner : FreshName initial.used source.name)
      (constructors : Reservations (source.name :: initial.used) source.constructors reserved)
      (recursor : FreshName reserved (psMinRegCoreRecName source.name))
      (meaning : GroupImage initial.count initial.groups source spec) :
      GroupStep initial source
        ⟨⟨source,spec,initial.count⟩ :: initial.groups,
          psMinRegCoreRecName source.name :: reserved, Nat.succ initial.count⟩

theorem actual_group_step (initial final : PsMinRegCoreState) (source : PsMinRegCoreGroup)
    (h : psMinRegCoreBuildGroup initial source = some final) : GroupStep initial source final := by
  unfold psMinRegCoreBuildGroup at h
  split at h
  next owner =>
    split at h
    next exactType =>
      cases hr : psMinRegCoreReserveConstructors source.constructors (source.name :: initial.used) with
      | none => simp [hr] at h
      | some reserved =>
        simp only [hr] at h
        split at h
        next recursor =>
          cases hf : psMinRegCoreAllFields initial.count initial.groups source.name source.constructors with
          | none => simp [hf] at h
          | some fields =>
            simp only [hf] at h
            split at h
            next valid =>
              cases h
              apply GroupStep.regular reserved
                ⟨0,0,0,1,psMinRegCoreConstructorCount source.constructors,fields⟩
              · exact fresh_no_shadowing _ _ owner
              · exact constructor_reservations _ _ _ hr
              · exact fresh_no_shadowing _ _ recursor
              · rw [constructor_count_exact]
                exact .regular fields (exprEq_sound _ _ _ exactType)
                  (all_constructor_fields_translation _ _ _ _ _ hf)
            next => contradiction
        next => contradiction
    next => contradiction
  next => contradiction

theorem group_step_unique (initial final : PsMinRegCoreState) (source : PsMinRegCoreGroup)
    (step : GroupStep initial source final) (unique : UniqueNames initial.used) :
    UniqueNames final.used := by
  cases step with
  | regular reserved spec owner constructors recursor meaning =>
    apply UniqueNames.cons (psMinRegCoreRecName source.name) reserved recursor.2.1
    exact reservations_unique _ _ _ constructors (.cons source.name initial.used owner.2.1 unique)

inductive PlanHistory : PsMinRegCoreState → List PsMinRegCoreEntry → PsMinRegCoreState → Prop where
  | nil (state) : PlanHistory state [] state
  | definition (initial final : PsMinRegCoreState) (source : PsMinCoreDeclaration) (rest)
      (fresh : FreshName initial.used source.name)
      (tail : PlanHistory ⟨initial.groups,source.name :: initial.used,initial.count⟩ rest final) :
      PlanHistory initial (.definition source :: rest) final
  | group (initial next final : PsMinRegCoreState) (source : PsMinRegCoreGroup) (rest)
      (step : GroupStep initial source next) (tail : PlanHistory next rest final) :
      PlanHistory initial (.inductiveE source :: rest) final

theorem build_plans_history (fuel : Nat) (entries : List PsMinRegCoreEntry)
    (initial final : PsMinRegCoreState)
    (h : psMinRegCoreBuildPlans fuel entries initial = some final) :
    PlanHistory initial entries final := by
  induction fuel generalizing entries initial final with
  | zero =>
    cases entries with
    | nil => cases h; exact .nil initial
    | cons entry rest => simp [psMinRegCoreBuildPlans] at h
  | succ fuel ih =>
    cases entries with
    | nil => cases h; exact .nil initial
    | cons entry rest =>
      cases entry with
      | definition source =>
        simp only [psMinRegCoreBuildPlans] at h
        split at h
        next fresh =>
          exact .definition initial final source rest (fresh_no_shadowing _ _ fresh)
            (ih rest ⟨initial.groups,source.name :: initial.used,initial.count⟩ final h)
        next => contradiction
      | inductiveE source =>
        cases hg : psMinRegCoreBuildGroup initial source with
        | none => simp [psMinRegCoreBuildPlans, hg] at h
        | some next =>
          have tail : psMinRegCoreBuildPlans fuel rest next = some final := by
            simpa only [psMinRegCoreBuildPlans, hg] using h
          exact .group initial next final source rest (actual_group_step _ _ _ hg) (ih rest next final tail)

theorem history_unique (initial final : PsMinRegCoreState) (entries : List PsMinRegCoreEntry)
    (history : PlanHistory initial entries final) (unique : UniqueNames initial.used) :
    UniqueNames final.used := by
  revert unique
  induction history with
  | nil => intro unique; exact unique
  | definition initial final source rest fresh tail ih =>
    intro unique
    exact ih (.cons source.name initial.used fresh.2.1 unique)
  | group initial next final source rest step tail ih =>
    intro unique
    exact ih (group_step_unique _ _ _ step unique)

theorem actual_plans_history (entries : List PsMinRegCoreEntry) (state : PsMinRegCoreState)
    (h : psMinRegCorePlans entries = some state) :
    PlanHistory ⟨[],[],0⟩ entries state :=
  build_plans_history 512 entries _ state h

theorem actual_plans_no_shadowing (entries : List PsMinRegCoreEntry) (state : PsMinRegCoreState)
    (h : psMinRegCorePlans entries = some state) : UniqueNames state.used :=
  history_unique _ _ _ (actual_plans_history entries state h) UniqueNames.nil

#print axioms constructor_reservations
#print axioms reservations_unique
#print axioms actual_group_step
#print axioms group_step_unique
#print axioms build_plans_history
#print axioms history_unique
#print axioms actual_plans_history
#print axioms actual_plans_no_shadowing
end Ps.MinKernel.RegularIngressNames
