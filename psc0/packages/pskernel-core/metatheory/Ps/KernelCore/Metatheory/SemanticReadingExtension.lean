import Ps.KernelCore.Metatheory.SemanticEnvironmentAdmission
import Ps.KernelCore.Metatheory.SemanticExtension

/-!
Transport a PSKernel-owned environment model when an actual fresh constant is
given a new set-theoretic interpretation.

Unlike a fixed-reading insertion theorem, this supports a NEW interpretation
for the admitted constant while retaining interpretations of the prefix.
Con Leche supplies only pure mathematical set operations, not this checker
or admission-soundness lemma.

The old annotations must *actually* avoid the new constant, old names must
not collide, and the pinned False name must remain unchanged. Those inputs
will ultimately follow from real admission freshness and expression checks.
The new constant's modeled type remains a separate, explicit obligation.
-/
namespace PsKernelSemantics.SetModel
open ConLeche ConLeche.SetTheory ConLeche.SetModel AnnotatedExpr
universe u
variable {V : Type u} [SetTheory V]

/-- The two real reading transformations commute: universe parameter
instantiation does not modify the constant table, and constant insertion
does not modify universe level interpretation. -/
theorem substLevels_extendConstant (M : Reading V)
    (fresh : PsKernelName) (value : List Nat → V)
    (params : List PsKernelName) (levels : List PsKernelLevel) :
    (M.extendConstant fresh value).substLevels params levels =
      (M.substLevels params levels).extendConstant fresh value := by
  rfl

/-- The very same annotation witness is fixed BEFORE the new constant is
introduced, and contains no reference to its fresh name. -/
def StoredConstantAvoids (M : Reading V)
    (info : PsKernelConstantInfo) (fresh : PsKernelName) : Prop :=
  ∃ A : AnnotatedExpr,
    A.erase = psKernelConstantInfoType info ∧
    AvoidsConstant fresh A ∧
    ∀ levels, CorrectUniverseArity info levels →
      ∀ ρ, M.constants (psKernelConstantInfoName info)
        (levels.map M.level) ∈ˢ
          interp (M.substLevels (psKernelConstantInfoLevelParams info)
            levels) ρ A

/-- A prefix declaration's exact witness stays a valid witness when the
new constant has a fresh different name and was absent from its annotated
source type. -/
theorem storedConstant_extendConstant (M : Reading V)
    (info : PsKernelConstantInfo) (fresh : PsKernelName)
    (value : List Nat → V)
    (differentName : psKernelConstantInfoName info ≠ fresh)
    (old : StoredConstantAvoids M info fresh) :
    StoredConstantModeled (M.extendConstant fresh value) info := by
  obtain ⟨A, erased, avoids, membership⟩ := old
  refine ⟨A, erased, ?_⟩
  intro levels arity ρ
  have hOld := membership levels arity ρ
  have hLevels :
      levels.map (M.extendConstant fresh value).level = levels.map M.level := by
    simp only [Reading.extendConstant_level]
  have hType :
      interp ((M.extendConstant fresh value).substLevels
        (psKernelConstantInfoLevelParams info) levels) ρ A =
      interp (M.substLevels (psKernelConstantInfoLevelParams info)
        levels) ρ A := by
    rw [substLevels_extendConstant]
    exact interp_extendConstant
      (M.substLevels (psKernelConstantInfoLevelParams info) levels)
      fresh value A avoids ρ
  rw [hLevels, hType]
  simpa [Reading.extendConstant, differentName] using hOld

/-- Transport the whole existing indexed/history model under a fresh
semantic constant assignment. The model's False pin remains protected.
Nothing here changes executable kernel checking behavior. -/
theorem environmentModel_extendConstant (M : Reading V)
    (env : PsKernelEnvironment) (fresh : PsKernelName)
    (value : List Nat → V) (old : EnvironmentModel M env)
    (oldReadings : ∀ info, info ∈ env.constants →
      StoredConstantAvoids M info fresh)
    (oldNames : ∀ info, info ∈ env.constants →
      psKernelConstantInfoName info ≠ fresh)
    (reserved : fresh ≠ falseConstantName) :
    EnvironmentModel (M.extendConstant fresh value) env := by
  refine {
    lookupCanonical := old.lookupCanonical
    lookupInHistory := old.lookupInHistory
    lookupName := old.lookupName
    stored := ?_
    falsePinned := ?_
  }
  · intro info present
    exact storedConstant_extendConstant M info fresh value
      (oldNames info present) (oldReadings info present)
  · have hDistinct : falseConstantName ≠ fresh := Ne.symm reserved
    simpa [Reading.extendConstant, hDistinct] using old.falsePinned

/-- The actual environment insertion composes with semantic reading
extension, under all explicitly named obligations for the new declaration.
The missing soundness theorem must derive newStored from the CHECKED source
rather than adding it as an axiom. -/
theorem addUnchecked_model_with_new_reading (M : Reading V)
    (env : PsKernelEnvironment) (info : PsKernelConstantInfo)
    (value : List Nat → V) (old : EnvironmentModel M env)
    (oldReadings : ∀ prev, prev ∈ env.constants →
      StoredConstantAvoids M prev (psKernelConstantInfoName info))
    (oldNames : ∀ prev, prev ∈ env.constants →
      psKernelConstantInfoName prev ≠ psKernelConstantInfoName info)
    (reserved : psKernelConstantInfoName info ≠ falseConstantName)
    (newStored : StoredConstantModeled
      (M.extendConstant (psKernelConstantInfoName info) value) info) :
    EnvironmentModel
      (M.extendConstant (psKernelConstantInfoName info) value)
      (psKernelEnvironmentAddUnchecked env info) := by
  apply addUnchecked_model
  · exact environmentModel_extendConstant M env
      (psKernelConstantInfoName info) value old oldReadings
      oldNames reserved
  · exact newStored

end PsKernelSemantics.SetModel
