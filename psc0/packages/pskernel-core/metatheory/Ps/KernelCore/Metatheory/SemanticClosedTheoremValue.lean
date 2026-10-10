import Ps.KernelCore.Metatheory.SemanticFreshAdmission
import Ps.KernelCore.Metatheory.SemanticReferenceTheoremTrace

/-!
A concrete monomorphic theorem-value interpretation.

The successful ACTUAL reference theorem-admission path has already been
inverted into its exact checker proof run and DefEq trace. For the monomorphic
subcase, IF the future joint checker theorem establishes a CheckedReading
for the very same submitted proof and declared type (and those readings are
closed), this module constructs the new constant's set denotation from that
proof term. It removes the earlier opaque StoredConstantModeled assumption.

This is an explicit one-step reduction of the still-open joint recursive
checker/DefEq soundness and raw hygiene obligations, NOT an assertion that
the current kernel globally provides these checked semantic readings.
-/

namespace PsKernelSemantics.SetModel
open ConLeche ConLeche.SetTheory ConLeche.SetModel AnnotatedExpr
universe u
variable {V : Type u} [SetTheory V]

/-- No universe parameter substitution changes any semantic Reading. -/
theorem Reading.substLevels_nil (M : Reading V) :
    M.substLevels [] [] = M := by
  cases M
  rfl

/-- The denotation of an actual CLOSED proof term at a fixed valuation.
Closure makes this selection independent of other bound-variable valuations.
For the monomorphic case there are no universe-valued parameters either. -/
noncomputable def closedProofValue (M : Reading V)
    (proof : AnnotatedExpr) : List Nat → V :=
  fun _ => interp M (fun _ => (empty : V)) proof

/-- An exactly selected CLOSED checked proof supplies the new theorem's
semantic membership uniformly in every allowed monomorphic instantiation.
This is a mathematical consequence of the concrete hereditary reading,
not a new assumption that every checker execution has one. -/
theorem checkedClosedProof_monomorphic_assignment (M : Reading V)
    (info : PsKernelConstantInfo)
    (proof type : AnnotatedExpr)
    (noParams : psKernelConstantInfoLevelParams info = [])
    (closed : proof.Scoped 0)
    (checked : CheckedReading M [] proof type) :
    ∀ levels, CorrectUniverseArity info levels →
      ∀ ρ, closedProofValue M proof (levels.map M.level) ∈ˢ
        interp (M.substLevels (psKernelConstantInfoLevelParams info)
          levels) ρ type := by
  intro levels arity ρ
  have hNil : levels = [] := by
    cases levels with
    | nil => rfl
    | cons level rest =>
        simp [CorrectUniverseArity, noParams,
          psKernelNameListLength, psKernelLevelListLength] at arity
  subst levels
  have hTyped : interp M ρ proof ∈ˢ interp M ρ type :=
    checked.typed ρ True.intro
  have hClosed : interp M ρ proof =
      interp M (fun _ => (empty : V)) proof :=
    interp_closed M proof closed ρ (fun _ => (empty : V))
  rw [hClosed] at hTyped
  simpa [closedProofValue, noParams, Reading.substLevels_nil] using hTyped

/-- Actual successful safe-theorem insertion receives a CONSTRUCTED new
constant interpretation equal to the denotation of its own submitted
closed proof term. The public/checker soundness gap is narrowed to a
concrete CheckedReading of that SAME proof against that SAME header type,
plus actual source hygiene; no arbitrary new-store model is assumed.

This scoped theorem concerns monomorphic definitions only. Universe
parametricity, induction, WHNF/DefEq certification, and full public
admission remain unproved, and are not silently assumed here. -/
theorem referenceAddTheorem_monomorphic_constructs_reading
    (M : Reading V) (fuel : Nat)
    (env next : PsKernelEnvironment) (value : PsKernelTheoremInfo)
    (maxDepth maxNatSize : Nat)
    (old : EnvironmentModel M env)
    (noParams : value.base.levelParams = [])
    (proof type : AnnotatedExpr)
    (proofSource : proof.erase = value.value)
    (typeSource : type.erase = value.base.type)
    (closed : proof.Scoped 0)
    (checked : CheckedReading M [] proof type)
    (oldNoForward : ∀ prev, prev ∈ env.constants →
      RawAvoidsConstant (psKernelConstantInfoName (.thmInfo value))
        (psKernelConstantInfoType prev))
    (notReserved : psKernelConstantInfoName (.thmInfo value) ≠
      falseConstantName)
    (newSelfFree : RawAvoidsConstant
      (psKernelConstantInfoName (.thmInfo value))
      (psKernelConstantInfoType (.thmInfo value)))
    (accepted : @psKernelAddTheorem psKernelReferenceCachePolicy fuel
      env value maxDepth maxNatSize = .ok next) :
    EnvironmentModel
      (M.extendConstant (psKernelConstantInfoName (.thmInfo value))
        (closedProofValue M proof))
      next := by
  have admitted :=
    referenceAddTheorem_returns_insert fuel env next value
      maxDepth maxNatSize accepted
  have hParams : psKernelConstantInfoLevelParams (.thmInfo value) = [] := by
    exact noParams
  have hType : type.erase = psKernelConstantInfoType (.thmInfo value) := by
    exact typeSource
  exact successfulAdd_model_with_fresh_reading M env next
    (.thmInfo value) (closedProofValue M proof) type old oldNoForward
    notReserved hType newSelfFree
    (checkedClosedProof_monomorphic_assignment M (.thmInfo value)
      proof type hParams closed checked)
    admitted

end PsKernelSemantics.SetModel
