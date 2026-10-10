import Ps.KernelCore.Metatheory.SemanticContext

/-!
An independently modeled declarative dependent-function fragment.

This is a sound replacement target for the legacy collapsed judgment, not a
claim that the full checker refines it. It covers sorts, bound variables,
dependent functions, application, lets, conversion, beta/eta and proof
irrelevance. Constants, free-variable declarations, literals, projections,
quotients and inductive admission are not rules of this fragment.

Semantic equality has symmetry and transitivity. No transitivity result is
asserted for PSKernel's algorithmic equality or its pair cache.
-/

namespace PsKernelSemantics.Declarative
open AnnotatedExpr

inductive Claim where
  | typing (term type : AnnotatedExpr)
  | equal (left right : AnnotatedExpr)

/-- Every proof-irrelevance or beta shortcut carries the actual typing premises.
There is no constructor asserting checker soundness, nor a universal model law. -/
inductive Derives : List AnnotatedExpr → Claim → Prop where
  | sort (Γ l) : Derives Γ (.typing (.sort l) (.sort (.succ l)))
  | varZero (Γ A) : Derives (A :: Γ) (.typing (.bvar 0) (liftN 1 A 0))
  | weaken {Γ e A} (B) (h : Derives Γ (.typing e A)) :
      Derives (B :: Γ) (.typing (liftN 1 e 0) (liftN 1 A 0))
  | forallE {Γ n A B bi u v}
      (hA : Derives Γ (.typing A (.sort u)))
      (hB : Derives (A :: Γ) (.typing B (.sort v))) :
      Derives Γ (.typing (.forallE n A B bi v) (.sort (.imax u v)))
  | lam {Γ n A b B bi u v}
      (hA : Derives Γ (.typing A (.sort u)))
      (hb : Derives (A :: Γ) (.typing b B))
      (hB : Derives (A :: Γ) (.typing B (.sort v))) :
      Derives Γ (.typing (.lam n A b bi v) (.forallE n A B bi v))
  | app {Γ n f a A B bi v}
      (hf : Derives Γ (.typing f (.forallE n A B bi v)))
      (ha : Derives Γ (.typing a A))
      (hB : Derives (A :: Γ) (.typing B (.sort v))) :
      Derives Γ (.typing (.app f a) (inst a B 0))
  | letE {Γ n A a b B nd}
      (ha : Derives Γ (.typing a A))
      (hb : Derives (A :: Γ) (.typing b B)) :
      Derives Γ (.typing (.letE n A a b nd) (inst a B 0))
  | convert {Γ e A B u}
      (he : Derives Γ (.typing e A))
      (hAB : Derives Γ (.equal A B))
      (hB : Derives Γ (.typing B (.sort u))) :
      Derives Γ (.typing e B)
  | substitute {Γ A a e B}
      (ha : Derives Γ (.typing a A))
      (he : Derives (A :: Γ) (.typing e B)) :
      Derives Γ (.typing (inst a e 0) (inst a B 0))
  | mdata {Γ e A} (md) (h : Derives Γ (.typing e A)) :
      Derives Γ (.typing (.mdata md e) A)
  | refl (Γ e) : Derives Γ (.equal e e)
  | symm {Γ e f} (h : Derives Γ (.equal e f)) : Derives Γ (.equal f e)
  | trans {Γ e f g} (h : Derives Γ (.equal e f)) (h' : Derives Γ (.equal f g)) :
      Derives Γ (.equal e g)
  | appCongr {Γ f f' a a'}
      (hf : Derives Γ (.equal f f')) (ha : Derives Γ (.equal a a')) :
      Derives Γ (.equal (.app f a) (.app f' a'))
  | proofIrrelevance {Γ a b P}
      (hP : Derives Γ (.typing P (.sort .zero)))
      (ha : Derives Γ (.typing a P)) (hb : Derives Γ (.typing b P)) :
      Derives Γ (.equal a b)
  | beta {Γ n A a b B bi v}
      (ha : Derives Γ (.typing a A))
      (hb : Derives (A :: Γ) (.typing b B))
      (hB : Derives (A :: Γ) (.typing B (.sort v))) :
      Derives Γ (.equal (.app (.lam n A b bi v) a) (inst a b 0))
  | eta {Γ n A f B bi v}
      (hf : Derives Γ (.typing f (.forallE n A B bi v))) :
      Derives Γ (.equal (.lam n A (.app (liftN 1 f 0) (.bvar 0)) bi v) f)
  | zeta (Γ n A a b nd) :
      Derives Γ (.equal (.letE n A a b nd) (inst a b 0))
  | metadata (Γ md e) : Derives Γ (.equal (.mdata md e) e)

open ConLeche SetModel
universe u
variable {V : Type u} [SetTheory V]

def Claim.Models (M : Reading V) (Γ : List AnnotatedExpr) : Claim → Prop
  | .typing e A => ModelsType M Γ e A
  | .equal e f => ModelsEqual M Γ e f

/-- Soundness is an induction over the rules, not an assumed model field. -/
theorem sound (M : Reading V) {Γ : List AnnotatedExpr} {c : Claim}
    (h : Derives Γ c) : c.Models M Γ := by
  induction h with
  | sort Γ l => exact models_sort M Γ l
  | varZero Γ A => exact models_variable_zero M Γ A
  | weaken B h ih => exact models_weaken M _ _ _ B ih
  | forallE hA hB ihA ihB => exact models_forall M _ _ _ _ _ _ _ ihA ihB
  | lam hA hb hB ihA ihb ihB => exact models_lam M _ _ _ _ _ _ _ ihb
  | app hf ha hB ihf iha ihB => exact models_app M _ _ _ _ _ _ _ _ ihf iha ihB
  | letE ha hb iha ihb => exact models_let M _ _ _ _ _ _ _ iha ihb
  | convert he hAB hB ihe ihAB ihB => exact models_convert M _ _ _ _ ihe ihAB
  | substitute ha he iha ihe => exact models_substitution M _ _ _ _ _ iha ihe
  | mdata md h ih => exact ih
  | refl Γ e => intro _ _; rfl
  | symm h ih => intro ρ hρ; exact (ih ρ hρ).symm
  | trans h h' ih ih' => intro ρ hρ; exact (ih ρ hρ).trans (ih' ρ hρ)
  | appCongr hf ha ihf iha =>
      intro ρ hρ
      simp only [interp]
      rw [ihf ρ hρ, iha ρ hρ]
  | proofIrrelevance hP ha hb ihP iha ihb =>
      exact models_proof_irrelevance M _ _ _ _ ihP iha ihb
  | beta ha hb hB iha ihb ihB => exact models_beta M _ _ _ _ _ _ _ _ iha ihb ihB
  | eta hf ihf => exact models_eta M _ _ _ _ _ _ _ ihf
  | zeta Γ n A a b nd => exact models_zeta M Γ n A a b nd
  | metadata Γ md e => intro _ _; rfl

/-- The fragment has an actual closed typing derivation. -/
theorem identity_derives :
    Derives [] (.typing
      (.lam .anonymous (.sort .zero) (.bvar 0) .default (.succ .zero))
      (.forallE .anonymous (.sort .zero) (.sort .zero) .default (.succ .zero))) :=
  .lam (.sort [] .zero) (.varZero [] (.sort .zero)) (.sort [.sort .zero] .zero)

/-- Relative consistency of this stated fragment, at the closed contradiction
type. This is deliberately not named full-kernel consistency. -/
theorem no_allProps (M : Reading V) (e : AnnotatedExpr) :
    ¬ Derives [] (.typing e allProps) :=
  fun h => no_closed_allProps M e (sound M h)

theorem no_empty (M : Reading V) (e A : AnnotatedExpr)
    (hA : ∀ ρ, interp M ρ A = (ConLeche.SetTheory.empty : V)) :
    ¬ Derives [] (.typing e A) :=
  fun h => no_closed_empty_type M e A hA (sound M h)

/-- A reading is actually constructed for the constant-free fragment. Its
unused global tables are empty-valued; this is not a model of the production
initial environment or of global constant admission. -/
noncomputable def fragmentReading (V : Type u) [SetTheory V] : Reading V where
  levelParams := fun _ => 0
  levelMetavariables := fun _ => 0
  freeVars := fun _ => ConLeche.SetTheory.empty
  metavariables := fun _ => ConLeche.SetTheory.empty
  constants := fun _ _ => ConLeche.SetTheory.empty
  literals := fun _ => ConLeche.SetTheory.empty
  projections := fun _ _ _ => ConLeche.SetTheory.empty

/-- Relative consistency with the interpretation parameter discharged by
construction. The only remaining mathematical parameter is the explicit set
foundation; full-kernel inference and admission are not part of this fragment. -/
theorem relative_consistency (V : Type u) [SetTheory V] :
    ¬ ∃ e : AnnotatedExpr, Derives [] (.typing e allProps) := by
  rintro ⟨e, he⟩
  exact no_allProps (fragmentReading V) e he

end PsKernelSemantics.Declarative
