import Ps.KernelCore.Metatheory.SemanticAbstraction
import Ps.KernelCore.Metatheory.SemanticUniverseRegime
import Ps.KernelCore.Metatheory.SemanticStructuralEquality

/-!
Checked symbolic annotation agreement. A successful guard derives the semantic
RegimesAgree premise for every model reading. It therefore rejects the
empty-domain counterexample without assuming that semantic validity implies
coherence.

This assurance check is not yet part of public raw-expression acceptance.
It validates agreement between supplied readings, not their typing or the
correctness of their annotation provenance.
-/
namespace PsKernelSemantics.AnnotatedExpr

def checkRegimes : AnnotatedExpr → AnnotatedExpr → Bool
  | .lam _ A b _ v, .lam _ A' b' _ v'
  | .forallE _ A b _ v, .forallE _ A' b' _ v' =>
      UniverseRegime.check v v' && (checkRegimes A A' && checkRegimes b b')
  | .app f a, .app f' a' => checkRegimes f f' && checkRegimes a a'
  | .letE _ A a b _, .letE _ A' a' b' _ =>
      checkRegimes A A' && (checkRegimes a a' && checkRegimes b b')
  | .mdata _ e, .mdata _ e' | .proj _ _ e, .proj _ _ e' => checkRegimes e e'
  | _, _ => true

/-- The raw production comparison still checks shape and payloads. The new
guard checks only the additional binder annotation information. -/
def checkedExprEq (a b : AnnotatedExpr) : Bool :=
  psKernelExprEq a.erase b.erase && checkRegimes a b

theorem checkRegimes_refl (a : AnnotatedExpr) : checkRegimes a a = true := by
  induction a <;> simp_all [checkRegimes, UniverseRegime.check_refl]

theorem checkedExprEq_refl (a : AnnotatedExpr) : checkedExprEq a a = true := by
  simp [checkedExprEq, checkRegimes_refl, PsKernelSharing.expr_reflexive]

theorem checkRegimes_liftN (a b : AnnotatedExpr) (amount cut : Nat)
    (h : checkRegimes a b = true) :
    checkRegimes (liftN amount a cut) (liftN amount b cut) = true := by
  induction a generalizing b cut <;> cases b <;> simp_all [liftN, checkRegimes]

theorem checkRegimes_instLevels (a b : AnnotatedExpr)
    (names : List PsKernelName) (values : List PsKernelLevel)
    (h : checkRegimes a b = true) :
    checkRegimes (instLevels names values a) (instLevels names values b) = true := by
  induction a generalizing b <;> cases b <;>
    simp_all [instLevels, checkRegimes, UniverseRegime.check_instParams]

theorem checkRegimes_close (a b : AnnotatedExpr) (name : PsKernelName) (cut : Nat)
    (h : checkRegimes a b = true) :
    checkRegimes (close name a cut) (close name b cut) = true := by
  induction a generalizing b cut <;> cases b <;> simp_all [close, checkRegimes]
  all_goals split <;> simp_all [checkRegimes]

theorem checkRegimes_rejects_conflicting_lambdas
    (n n' : PsKernelName) (A b A' b' : AnnotatedExpr)
    (bi bi' : PsKernelBinderInfo) (v : PsKernelLevel) :
    checkRegimes (.lam n A b bi .zero) (.lam n' A' b' bi' (.succ v)) = false := rfl

theorem checkRegimes_rejects_conflicting_products
    (n n' : PsKernelName) (A B A' B' : AnnotatedExpr)
    (bi bi' : PsKernelBinderInfo) (v : PsKernelLevel) :
    checkRegimes (.forallE n A B bi .zero)
      (.forallE n' A' B' bi' (.succ v)) = false := rfl

end PsKernelSemantics.AnnotatedExpr

namespace PsKernelSemantics.SetModel
open ConLeche ConLeche.SetModel AnnotatedExpr
universe w
variable {V : Type w} [SetTheory V]

theorem checkRegimes_sound (M : Reading V) (a b : AnnotatedExpr)
    (h : checkRegimes a b = true) : RegimesAgree M a b := by
  induction a generalizing b with
  | bvar _ | fvar _ | mvar _ | sort _ | const _ _ | lit _ =>
      cases b <;> trivial
  | app f a ihf iha =>
      cases b <;> try trivial
      rename_i f' a'
      obtain ⟨hf, ha⟩ := Bool.and_eq_true.mp h
      exact ⟨ihf f' hf, iha a' ha⟩
  | lam n A body bi v ihA ihb | forallE n A body bi v ihA ihb =>
      cases b <;> try trivial
      rename_i n' A' body' bi' v'
      obtain ⟨hv, hA, hb⟩ : UniverseRegime.check v v' = true ∧
          checkRegimes A A' = true ∧ checkRegimes body body' = true := by
        simpa only [checkRegimes, Bool.and_eq_true] using h
      exact ⟨(UniverseRegime.check_spec v v').mp hv M.levelParams M.levelMetavariables,
        ihA A' hA, ihb body' hb⟩
  | letE n A a body nd ihA iha ihb =>
      cases b <;> try trivial
      rename_i n' A' a' body' nd'
      obtain ⟨hA, ha, hb⟩ : checkRegimes A A' = true ∧
          checkRegimes a a' = true ∧ checkRegimes body body' = true := by
        simpa only [checkRegimes, Bool.and_eq_true] using h
      exact ⟨ihA A' hA, iha a' ha, ihb body' hb⟩
  | mdata md e ih | proj n i e ih =>
      cases b <;> try trivial
      exact ih _ h

/-- Structural comparison now has an executable sufficient guard, with no
assumed semantic coherence premise. This does not establish that the raw
reference checker performed the extra guard. -/
theorem checkedExprEq_sound (M : Reading V) (a b : AnnotatedExpr)
    (h : checkedExprEq a b = true) (ρ : Nat → V) :
    interp M ρ a = interp M ρ b := by
  obtain ⟨raw, regimes⟩ := Bool.and_eq_true.mp h
  exact exprEq_preserves_interp M a b raw (checkRegimes_sound M a b regimes) ρ

theorem checkedExprEq_models_equal (M : Reading V) (Γ : List AnnotatedExpr)
    (a b : AnnotatedExpr) (h : checkedExprEq a b = true) :
    ModelsEqual M Γ a b :=
  fun ρ _ => checkedExprEq_sound M a b h ρ

theorem models_convert_checked (M : Reading V) (Γ : List AnnotatedExpr)
    (e A B : AnnotatedExpr) (typed : ModelsType M Γ e A)
    (comparison : checkedExprEq A B = true) : ModelsType M Γ e B :=
  models_convert M Γ e A B typed (checkedExprEq_models_equal M Γ A B comparison)

/-- Independently supplied, checked replacement and body readings preserve
semantic equality under the actual de Bruijn substitution interpretation. -/
theorem checkedExprEq_substitution_sound (M : Reading V) (e f a b : AnnotatedExpr)
    (bodies : checkedExprEq e f = true) (args : checkedExprEq a b = true)
    (cut : Nat) (ρ : Nat → V) :
    interp M ρ (inst a e cut) = interp M ρ (inst b f cut) := by
  rw [interp_inst, interp_inst, checkedExprEq_sound M a b args]
  exact checkedExprEq_sound M e f bodies _

theorem checkedExprEq_instLevels_sound (M : Reading V) (a b : AnnotatedExpr)
    (names : List PsKernelName) (values : List PsKernelLevel)
    (h : checkedExprEq a b = true) (ρ : Nat → V) :
    interp M ρ (instLevels names values a) =
      interp M ρ (instLevels names values b) := by
  rw [interp_instLevels, interp_instLevels]
  exact checkedExprEq_sound (M.substLevels names values) a b h ρ

end PsKernelSemantics.SetModel
