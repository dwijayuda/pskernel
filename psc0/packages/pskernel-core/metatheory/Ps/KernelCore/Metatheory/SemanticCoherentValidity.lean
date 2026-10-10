import Ps.KernelCore.Metatheory.SemanticAnnotationCoherence
import Ps.KernelCore.Metatheory.SemanticFunctionValidity

/-!
Guarded structural comparison transports both hereditary predicates. Thus a
later checker visit can retain the same validated reading through the actual
syntax operations, without re-choosing an unrelated annotation witness.
This still requires the public checker to carry and validate those readings.
-/
namespace PsKernelSemantics.SetModel
open ConLeche ConLeche.SetTheory ConLeche.SetModel AnnotatedExpr
universe u
variable {V : Type u} [SetTheory V]

theorem annotationValid_coherent_iff (M : Reading V) {a b : AnnotatedExpr}
    (h : Coherent a b) (ρ : Nat → V) :
    AnnotationValid M ρ a ↔ AnnotationValid M ρ b := by
  induction h generalizing ρ with
  | bvar _ | fvar _ | mvar _ | sort _ | const _ _ | lit _ => rfl
  | app hf ha ihf iha =>
      simp only [AnnotationValid, ihf, iha]
  | lam hv hA ha ihA iha =>
      simp only [AnnotationValid, ihA, iha, checkedExprEq_sound M _ _ hA.checked]
  | forallE hv hA ha ihA iha =>
      have regimes : M.level _ = 0 ↔ M.level _ = 0 :=
        (UniverseRegime.check_spec _ _).mp hv M.levelParams M.levelMetavariables
      simp only [AnnotationValid, ihA, iha, checkedExprEq_sound M _ _ hA.checked,
        checkedExprEq_sound M _ _ ha.checked, regimes]
  | letE hA ha he ihA iha ihe =>
      simp only [AnnotationValid, ihA, iha, ihe, checkedExprEq_sound M _ _ ha.checked]
  | mdata he ih | proj he ih => exact ih ρ

theorem functionValid_coherent_iff (M : Reading V) {a b : AnnotatedExpr}
    (h : Coherent a b) (ρ : Nat → V) :
    FunctionValid M ρ a ↔ FunctionValid M ρ b := by
  induction h generalizing ρ with
  | bvar _ | fvar _ | mvar _ | sort _ | const _ _ | lit _ => rfl
  | app hf ha ihf iha =>
      simp only [FunctionValid, ihf, iha, checkedExprEq_sound M _ _ hf.checked,
        checkedExprEq_sound M _ _ ha.checked]
  | lam hv hA ha ihA iha =>
      have regimes : M.level _ = 0 ↔ M.level _ = 0 :=
        (UniverseRegime.check_spec _ _).mp hv M.levelParams M.levelMetavariables
      simp only [FunctionValid, ihA, iha, checkedExprEq_sound M _ _ hA.checked,
        checkedExprEq_sound M _ _ ha.checked, regimes]
  | forallE hv hA ha ihA iha =>
      simp only [FunctionValid, ihA, iha, checkedExprEq_sound M _ _ hA.checked]
  | letE hA ha he ihA iha ihe =>
      simp only [FunctionValid, ihA, iha, ihe, checkedExprEq_sound M _ _ ha.checked]
  | mdata he ih | proj he ih => exact ih ρ

theorem checkedExprEq_validity (M : Reading V) (a b : AnnotatedExpr)
    (h : checkedExprEq a b = true) (ρ : Nat → V) :
    (AnnotationValid M ρ a ↔ AnnotationValid M ρ b) ∧
      (FunctionValid M ρ a ↔ FunctionValid M ρ b) :=
  ⟨annotationValid_coherent_iff M (coherent_of_checkedExprEq h) ρ,
    functionValid_coherent_iff M (coherent_of_checkedExprEq h) ρ⟩

end PsKernelSemantics.SetModel
