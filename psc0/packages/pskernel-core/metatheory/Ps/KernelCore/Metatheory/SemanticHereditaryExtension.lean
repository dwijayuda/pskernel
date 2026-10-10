import Ps.KernelCore.Metatheory.SemanticHereditaryEnvironment
import Ps.KernelCore.Metatheory.SemanticFreshAdmission

/-!
Hereditary validity transport when an actual fresh declaration extends the
same semantic Reading's constant table.

The earlier environment-model extension preserved membership, but a full
checker soundness induction needs the EXACT prior annotation's validity and
function/fibre validity to survive future admissions. These are semantic
preservation theorems over the same annotated constructors, not assertions
about unchecked kernel acceptance or an alternate checker.
-/

namespace PsKernelSemantics.SetModel
open ConLeche ConLeche.SetTheory ConLeche.SetModel AnnotatedExpr
universe u
variable {V : Type u} [SetTheory V]

/-- Hereditary proposition-bit validity is unchanged when the newly assigned
constant does not appear in this actual annotated expression. -/
theorem annotationValid_extendConstant
    (M : Reading V) (fresh : PsKernelName) (value : List Nat → V)
    (e : AnnotatedExpr) (h : AvoidsConstant fresh e) (ρ : Nat → V) :
    AnnotationValid (M.extendConstant fresh value) ρ e ↔
      AnnotationValid M ρ e := by
  induction e generalizing ρ with
  | bvar _ | fvar _ | mvar _ | sort _ | const _ _ | lit _ =>
      rfl
  | app f a ihf iha =>
      simp only [AnnotationValid, ihf h.1, iha h.2]
  | lam n A body bi tag ihA ihBody =>
      simp only [AnnotationValid, ihA h.1,
        interp_extendConstant M fresh value A h.1, ihBody h.2]
  | forallE n A body bi tag ihA ihBody =>
      simp only [AnnotationValid, ihA h.1,
        Reading.extendConstant_level,
        interp_extendConstant M fresh value A h.1,
        ihBody h.2,
        interp_extendConstant M fresh value body h.2]
  | letE n A a body nd ihA iha ihBody =>
      simp only [AnnotationValid, ihA h.1, iha h.2.1,
        interp_extendConstant M fresh value a h.2.1, ihBody h.2.2]
  | mdata md body ih | proj n i body ih =>
      exact ih h ρ

/-- Hereditary function/binder validity, including the actual fibres of
lambda and application, likewise preserves its selected representation. -/
theorem functionValid_extendConstant
    (M : Reading V) (fresh : PsKernelName) (value : List Nat → V)
    (e : AnnotatedExpr) (h : AvoidsConstant fresh e) (ρ : Nat → V) :
    FunctionValid (M.extendConstant fresh value) ρ e ↔
      FunctionValid M ρ e := by
  induction e generalizing ρ with
  | bvar _ | fvar _ | mvar _ | sort _ | const _ _ | lit _ =>
      rfl
  | app f a ihf iha =>
      simp only [FunctionValid, ihf h.1, iha h.2,
        interp_extendConstant M fresh value f h.1,
        interp_extendConstant M fresh value a h.2]
  | lam n A body bi tag ihA ihBody =>
      simp only [FunctionValid, ihA h.1,
        Reading.extendConstant_level,
        interp_extendConstant M fresh value A h.1,
        ihBody h.2,
        interp_extendConstant M fresh value body h.2]
  | forallE n A body bi tag ihA ihBody =>
      simp only [FunctionValid, ihA h.1,
        interp_extendConstant M fresh value A h.1, ihBody h.2]
  | letE n A a body nd ihA iha ihBody =>
      simp only [FunctionValid, ihA h.1, iha h.2.1,
        interp_extendConstant M fresh value a h.2.1, ihBody h.2.2]
  | mdata md body ih | proj n i body ih =>
      exact ih h ρ

/-- A single OLD declaration's unique uniform annotation witness retains
its membership, impredicative universe-regime validity, and function validity
after adding a different fresh constant that is absent from its raw type. -/
theorem hereditaryStored_extendConstant
    (M : Reading V) (info : PsKernelConstantInfo)
    (fresh : PsKernelName) (value : List Nat → V)
    (old : HereditarilyStoredConstant M info)
    (distinct : psKernelConstantInfoName info ≠ fresh)
    (noForward : RawAvoidsConstant fresh (psKernelConstantInfoType info)) :
    HereditarilyStoredConstant (M.extendConstant fresh value) info := by
  obtain ⟨A, erased, valid⟩ := old
  have avoids : AvoidsConstant fresh A :=
    (rawAvoids_erase_iff fresh A).mp
      (by simpa only [erased] using noForward)
  refine ⟨A, erased, ?_⟩
  intro levels arity ρ
  obtain ⟨membership, annotation, functionOK⟩ := valid levels arity ρ
  let before := M.substLevels (psKernelConstantInfoLevelParams info) levels
  have hType :
      interp ((M.extendConstant fresh value).substLevels
        (psKernelConstantInfoLevelParams info) levels) ρ A =
      interp before ρ A := by
    rw [substLevels_extendConstant]
    exact interp_extendConstant before fresh value A avoids ρ
  have hAnnotation : AnnotationValid
      ((M.extendConstant fresh value).substLevels
        (psKernelConstantInfoLevelParams info) levels) ρ A := by
    rw [substLevels_extendConstant]
    exact (annotationValid_extendConstant before fresh value A avoids ρ).mpr
      annotation
  have hFunction : FunctionValid
      ((M.extendConstant fresh value).substLevels
        (psKernelConstantInfoLevelParams info) levels) ρ A := by
    rw [substLevels_extendConstant]
    exact (functionValid_extendConstant before fresh value A avoids ρ).mpr
      functionOK
  refine ⟨?_, hAnnotation, hFunction⟩
  have hLevels :
      levels.map (M.extendConstant fresh value).level =
        levels.map M.level := by
    simp only [Reading.extendConstant_level]
  rw [hLevels, hType]
  simpa [Reading.extendConstant, distinct] using membership

/-- The exact preceding checker environment, including all previously
selected hereditary witnesses, is preserved when its constant table grows.
The False name can be assigned only its pinned empty interpretation. -/
theorem hereditaryEnvironment_extendConstant
    (M : Reading V) (env : PsKernelEnvironment)
    (fresh : PsKernelName) (value : List Nat → V)
    (old : HereditaryEnvironmentModel M env)
    (noForward : ∀ info, info ∈ env.constants →
      RawAvoidsConstant fresh (psKernelConstantInfoType info))
    (distinct : ∀ info, info ∈ env.constants →
      psKernelConstantInfoName info ≠ fresh)
    (preservesFalse : fresh ≠ falseConstantName ∨
      value [] = (empty : V)) :
    HereditaryEnvironmentModel (M.extendConstant fresh value) env := by
  have oldReadings : ∀ info, info ∈ env.constants →
      StoredConstantAvoids M info fresh := by
    intro info present
    exact storedConstantAvoids_of_raw M info fresh
      (old.base.stored info present) (noForward info present)
  refine {
    base := environmentModel_extendConstant_preservingFalse M env
      fresh value old.base oldReadings distinct preservesFalse
    stored := ?_
  }
  intro info present
  exact hereditaryStored_extendConstant M info fresh value
    (old.stored info present) (distinct info present)
    (noForward info present)

end PsKernelSemantics.SetModel
