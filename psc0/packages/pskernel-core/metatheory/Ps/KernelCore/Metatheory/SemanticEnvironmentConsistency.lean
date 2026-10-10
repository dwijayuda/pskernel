import Ps.KernelCore.Metatheory.SemanticEnvironmentModel

/-!
First substantive consistency corollary for *modeled* actual declaration
histories: a fixed, well-modeled stored constant cannot have literal type
False, provided the reserved False name denotes the empty set.

No public acceptance theorem is assumed. In particular, Lean's normal
axiom-admission mode need not preserve this restricted model predicate.
-/
namespace PsKernelSemantics.SetModel
open ConLeche ConLeche.SetTheory ConLeche.SetModel AnnotatedExpr
universe u
variable {V : Type u} [SetTheory V]

/-- Erasure cannot hide a binder annotation inside an unadorned constant. -/
theorem erase_const_injective_at (A : AnnotatedExpr)
    (name : PsKernelName) (levels : List PsKernelLevel)
    (erasure : A.erase = .const name levels) :
    A = .const name levels := by
  cases A <;> cases erasure <;> rfl

/-- This is a relative consistency statement for a genuinely modeled
environment: there is no *stored* declaration, at zero universe parameters,
whose literal type is the pinned empty False. It does not assert that
successful public checking preserves EnvironmentModel. -/
theorem no_stored_constant_of_literalFalse (M : Reading V)
    (env : PsKernelEnvironment) (model : EnvironmentModel M env)
    (info : PsKernelConstantInfo) (present : info ∈ env.constants)
    (noParams : psKernelConstantInfoLevelParams info = [])
    (declaredFalse : psKernelConstantInfoType info =
      .const falseConstantName []) : False := by
  obtain ⟨A, erased, instances⟩ := model.stored info present
  have arity : CorrectUniverseArity info [] := by
    simp [CorrectUniverseArity, noParams, psKernelNameListLength,
      psKernelLevelListLength]
  have exactType : A = .const falseConstantName [] :=
    erase_const_injective_at A falseConstantName [] (erased.trans declaredFalse)
  have instantiated := instances [] arity (fun _ => empty)
  have interpretedFalse : ∀ ρ : Nat → V,
      interp M ρ (.const falseConstantName []) = (empty : V) := by
    intro ρ
    simpa only [interp, List.map_nil] using model.falsePinned
  have typed : ModelsType M []
      (.const (psKernelConstantInfoName info) [])
      (.const falseConstantName []) := by
    intro ρ _
    have h := instances [] arity ρ
    simpa only [exactType, interp, Reading.substLevels, List.map_nil] using h
  exact (no_closed_empty_type M (.const (psKernelConstantInfoName info) [])
    (.const falseConstantName []) interpretedFalse) typed

end PsKernelSemantics.SetModel
