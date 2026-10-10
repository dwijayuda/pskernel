import Ps.KernelCore.Metatheory.SemanticLevelConstructors
import Ps.KernelCore.Metatheory.SemanticContext

/-!
Universe instantiation commutes with the PSKernel set reading, including
binder annotations. The operation is the production substitution, so its
first-match behavior also remains explicit for duplicate or missing parameters.
Admission still has to establish its separate arity and scope checks.
-/

namespace PsKernelSemantics

def substLevelValuation (params metavariables : PsKernelName → Nat)
    (names : List PsKernelName) (values : List PsKernelLevel) : PsKernelName → Nat :=
  fun n => match psKernelNameLookupLevel n names values with
    | some l => evalLevel params metavariables l
    | none => params n

private theorem eq_eval (params metavariables : PsKernelName → Nat)
    {a b : PsKernelLevel} (h : psKernelLevelEq a b = true) :
    evalLevel params metavariables a = evalLevel params metavariables b :=
  congrArg (evalLevel params metavariables)
    (psKernelLevelEq_sound_of_string_law psKernelStringEq_sound_lean435 a b h)

private theorem and_true {a b : Bool}
    (h : (if a then b else false) = true) : a = true ∧ b = true := by
  cases a <;> simp_all

theorem instantiateParams_eval (params metavariables : PsKernelName → Nat)
    (l : PsKernelLevel) (names : List PsKernelName) (values : List PsKernelLevel) :
    evalLevel params metavariables (psKernelLevelInstantiateParams l names values) =
      evalLevel (substLevelValuation params metavariables names values) metavariables l := by
  induction l with
  | zero | mvar _ => rfl
  | param n =>
      simp only [psKernelLevelInstantiateParams, evalLevel, substLevelValuation]
      cases psKernelNameLookupLevel n names values <;> rfl
  | succ l ih =>
      simp only [psKernelLevelInstantiateParams]
      by_cases h : psKernelLevelEq l (psKernelLevelInstantiateParams l names values) = true
      · rw [if_pos h]
        have he := eq_eval params metavariables h
        simp only [evalLevel]
        rw [he, ih]
      · rw [if_neg h]
        simp only [evalLevel, ih]
  | max a b iha ihb =>
      simp only [psKernelLevelInstantiateParams]
      by_cases h :
        (if psKernelLevelEq a (psKernelLevelInstantiateParams a names values)
          then psKernelLevelEq b (psKernelLevelInstantiateParams b names values)
          else false) = true
      · rw [if_pos h]
        obtain ⟨ha, hb⟩ := and_true h
        have ea := eq_eval params metavariables ha
        have eb := eq_eval params metavariables hb
        simp only [evalLevel]
        rw [ea, eb, iha, ihb]
      · rw [if_neg h, mkMax_eval, iha, ihb]
        rfl
  | imax a b iha ihb =>
      simp only [psKernelLevelInstantiateParams]
      by_cases h :
        (if psKernelLevelEq a (psKernelLevelInstantiateParams a names values)
          then psKernelLevelEq b (psKernelLevelInstantiateParams b names values)
          else false) = true
      · rw [if_pos h]
        obtain ⟨ha, hb⟩ := and_true h
        have ea := eq_eval params metavariables ha
        have eb := eq_eval params metavariables hb
        simp only [evalLevel]
        rw [ea, eb, iha, ihb]
      · rw [if_neg h, mkIMax_eval]
        simp only [evalLevel, iha, ihb]

namespace AnnotatedExpr

def instLevels (names : List PsKernelName) (values : List PsKernelLevel) :
    AnnotatedExpr → AnnotatedExpr
  | .sort l => .sort (psKernelLevelInstantiateParams l names values)
  | .const n ls => .const n (psKernelInstantiateLevelList ls names values)
  | .app f a => .app (instLevels names values f) (instLevels names values a)
  | .lam n A b bi v =>
      .lam n (instLevels names values A) (instLevels names values b) bi
        (psKernelLevelInstantiateParams v names values)
  | .forallE n A B bi v =>
      .forallE n (instLevels names values A) (instLevels names values B) bi
        (psKernelLevelInstantiateParams v names values)
  | .letE n A a b nd =>
      .letE n (instLevels names values A) (instLevels names values a)
        (instLevels names values b) nd
  | .mdata md e => .mdata md (instLevels names values e)
  | .proj n i e => .proj n i (instLevels names values e)
  | e => e

theorem erase_instLevels (e : AnnotatedExpr)
    (names : List PsKernelName) (values : List PsKernelLevel) :
    (instLevels names values e).erase =
      psKernelExprInstantiateLevelParams e.erase names values := by
  induction e <;> simp_all [instLevels, erase, psKernelExprInstantiateLevelParams]

end AnnotatedExpr

namespace SetModel
open ConLeche AnnotatedExpr
universe u
variable {V : Type u} [SetTheory V]

def Reading.substLevels (M : Reading V)
    (names : List PsKernelName) (values : List PsKernelLevel) : Reading V :=
  { M with levelParams := substLevelValuation M.levelParams M.levelMetavariables names values }

theorem Reading.substLevels_eval (M : Reading V)
    (names : List PsKernelName) (values : List PsKernelLevel) (l : PsKernelLevel) :
    M.level (psKernelLevelInstantiateParams l names values) =
      (M.substLevels names values).level l :=
  instantiateParams_eval M.levelParams M.levelMetavariables l names values

theorem Reading.substLevels_list (M : Reading V)
    (names : List PsKernelName) (values levels : List PsKernelLevel) :
    (psKernelInstantiateLevelList levels names values).map M.level =
      levels.map (M.substLevels names values).level := by
  induction levels <;> simp_all [psKernelInstantiateLevelList, Reading.substLevels_eval]

theorem interp_instLevels (M : Reading V) (e : AnnotatedExpr)
    (names : List PsKernelName) (values : List PsKernelLevel) (ρ : Nat → V) :
    interp M ρ (instLevels names values e) =
      interp (M.substLevels names values) ρ e := by
  induction e generalizing ρ with
  | bvar _ | fvar _ | mvar _ | lit _ => rfl
  | sort l =>
      exact congrArg ConLeche.SetTheory.univ (M.substLevels_eval names values l)
  | const n ls =>
      exact congrArg (M.constants n) (M.substLevels_list names values ls)
  | app f a ihf iha => simp only [instLevels, interp, ihf, iha]
  | lam n A b bi v ihA ihb | forallE n A b bi v ihA ihb =>
      simp only [instLevels, interp, Reading.substLevels_eval, ihA, ihb]
  | letE n A a b nd ihA iha ihb => simp only [instLevels, interp, iha, ihb]
  | mdata md e ih => exact ih ρ
  | proj n i e ih => exact congrArg (M.projections n i) (ih ρ)

theorem satisfies_instLevels (M : Reading V) (Γ : List AnnotatedExpr)
    (names : List PsKernelName) (values : List PsKernelLevel) (ρ : Nat → V) :
    Satisfies M (Γ.map (instLevels names values)) ρ ↔
      Satisfies (M.substLevels names values) Γ ρ := by
  induction Γ generalizing ρ <;> simp_all [Satisfies, interp_instLevels]

theorem modelsType_instLevels (M : Reading V) (Γ : List AnnotatedExpr)
    (names : List PsKernelName) (values : List PsKernelLevel) (e A : AnnotatedExpr)
    (h : ModelsType (M.substLevels names values) Γ e A) :
    ModelsType M (Γ.map (instLevels names values))
      (instLevels names values e) (instLevels names values A) := by
  intro ρ hρ
  rw [interp_instLevels, interp_instLevels]
  exact h ρ ((satisfies_instLevels M Γ names values ρ).mp hρ)

/-- Exact semantic reading of the production universe substitution applied to
a declaration type. Constant admission must establish typing at all permitted
valuations before this theorem can instantiate that typing. -/
theorem instantiateLevelParams_has_reading (M : Reading V) (e : AnnotatedExpr)
    (names : List PsKernelName) (values : List PsKernelLevel) (ρ : Nat → V) :
    ∃ r : AnnotatedExpr,
      r.erase = psKernelExprInstantiateLevelParams e.erase names values ∧
      interp M ρ r = interp (M.substLevels names values) ρ e :=
  ⟨instLevels names values e, erase_instLevels e names values,
    interp_instLevels M e names values ρ⟩

end SetModel
end PsKernelSemantics
