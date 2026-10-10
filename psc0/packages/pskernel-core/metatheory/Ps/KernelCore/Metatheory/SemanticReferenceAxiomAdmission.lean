import Ps.KernelCore.Metatheory.SemanticEnvironmentAdmission
import Ps.KernelCore.Admission.Declaration.Admission
import Ps.KernelCore.API.Reference

/-!
Connect the actual reference-mode axiom checking/dispatch code to the
semantic declaration-history model. The *new axiom's interpretation* remains
a visibly separate allowed-axiom premise. Normal Lean-compatible checking
can admit arbitrary axioms and must not be misrepresented as consistent
without the corresponding model policy.

These theorems follow executed header validation, checked insertion and
public dispatch, not a copied abstract checking algorithm.
-/
namespace PsKernelSemantics.SetModel
open ConLeche ConLeche.SetTheory
universe u
variable {V : Type u} [SetTheory V]

/-- Runtime native-evaluator configuration does not change the semantic
declaration history or indexed lookup. This is NOT native-reduction soundness. -/
theorem environmentModel_withNativeEvaluator (M : Reading V)
    (env : PsKernelEnvironment) (native : Option PsKernelNativeEvaluator)
    (model : EnvironmentModel M env) :
    EnvironmentModel M (psKernelEnvironmentWithNativeEvaluator env native) := by
  refine {
    lookupCanonical := ?_
    lookupInHistory := ?_
    lookupName := ?_
    stored := ?_
    falsePinned := model.falsePinned
  }
  · intro name
    simpa [psKernelEnvironmentWithNativeEvaluator, psKernelEnvironmentFind]
      using model.lookupCanonical name
  · intro name info found
    have prior : psKernelEnvironmentFind env name = some info := by
      simpa [psKernelEnvironmentWithNativeEvaluator, psKernelEnvironmentFind]
        using found
    exact model.lookupInHistory name info prior
  · intro name info found
    have prior : psKernelEnvironmentFind env name = some info := by
      simpa [psKernelEnvironmentWithNativeEvaluator, psKernelEnvironmentFind]
        using found
    exact model.lookupName name info prior
  · intro info present
    exact model.stored info present

/-- The real reference axiom checking entry can only return the result of
the guarded environment insertion, following successful header checking. -/
theorem referenceAddAxiom_returns_insert
    (fuel : Nat) (env next : PsKernelEnvironment)
    (value : PsKernelAxiomInfo) (maxDepth maxNatSize : Nat)
    (run : @psKernelAddAxiom psKernelReferenceCachePolicy
      fuel env value maxDepth maxNatSize = .ok next) :
    psKernelEnvironmentAdd env (.axiomInfo value) = .ok next := by
  cases hUnsafe : value.isUnsafe with
  | false =>
      cases hHeader : psKernelCheckConstantBaseWithSession fuel
          (psKernelMkCheckerSession env value.base.levelParams
            PsKernelDefinitionSafety.safe maxDepth maxNatSize)
          value.base with
      | error err =>
          simp [psKernelAddAxiom, hUnsafe, hHeader] at run
      | ok checked =>
          simpa [psKernelAddAxiom, hUnsafe, hHeader] using run
  | true =>
      cases hHeader : psKernelCheckConstantBaseWithSession fuel
          (psKernelMkCheckerSession env value.base.levelParams
            PsKernelDefinitionSafety.unsafeDef maxDepth maxNatSize)
          value.base with
      | error err =>
          simp [psKernelAddAxiom, hUnsafe, hHeader] at run
      | ok checked =>
          simpa [psKernelAddAxiom, hUnsafe, hHeader] using run

/-- An actual successful reference axiom check preserves the modeled history
*provided* the caller independently models the axiom. Mere success of the
unrestricted Lean-compatible axiom rule is not that premise. -/
theorem referenceAddAxiom_preserves_model
    (M : Reading V) (fuel : Nat)
    (env next : PsKernelEnvironment) (value : PsKernelAxiomInfo)
    (maxDepth maxNatSize : Nat)
    (model : EnvironmentModel M env)
    (allowedAxiom : StoredConstantModeled M (.axiomInfo value))
    (run : @psKernelAddAxiom psKernelReferenceCachePolicy
      fuel env value maxDepth maxNatSize = .ok next) :
    EnvironmentModel M next :=
  add_success_preserves_model M env next (.axiomInfo value)
    model allowedAxiom
    (referenceAddAxiom_returns_insert fuel env next value maxDepth maxNatSize run)

/-- Invert the publicly used PSKernel v1 dispatch for the actual axiom
request. The branch's error conversion cannot fabricate a successful result. -/
theorem referenceDispatchAxiom_returns_add
    (session : PsKernelKernelSession) (value : PsKernelAxiomInfo)
    (next : PsKernelEnvironment)
    (run : @psKernelV1DispatchDeclaration psKernelReferenceCachePolicy
      session (.axiomDecl value) = .ok next) :
    @psKernelAddAxiom psKernelReferenceCachePolicy
      session.resources.fuel (psKernelKernelSessionEnvironment session)
      value session.resources.maxRecDepth session.resources.maxNatSize =
        .ok next := by
  cases h : @psKernelAddAxiom psKernelReferenceCachePolicy
      session.resources.fuel (psKernelKernelSessionEnvironment session)
      value session.resources.maxRecDepth session.resources.maxNatSize with
  | error error =>
      simp [psKernelV1DispatchDeclaration, psKernelV1EnvironmentOutcome, h] at run
  | ok candidate =>
      have equal : candidate = next := by
        simpa [psKernelV1DispatchDeclaration, psKernelV1EnvironmentOutcome, h] using run
      cases equal
      rfl

/-- The actual reference public AXIOM dispatch preserves the stronger model
when that axiom belongs to the *explicit* modeled policy. It is not yet a
theorem for definitions, theorems, inductives, or arbitrary axiom streams. -/
theorem referenceDispatchAxiom_preserves_model
    (M : Reading V) (session : PsKernelKernelSession)
    (value : PsKernelAxiomInfo) (next : PsKernelEnvironment)
    (model : EnvironmentModel M session.environment)
    (allowedAxiom : StoredConstantModeled M (.axiomInfo value))
    (run : @psKernelV1DispatchDeclaration psKernelReferenceCachePolicy
      session (.axiomDecl value) = .ok next) :
    EnvironmentModel M next := by
  have sourceModel : EnvironmentModel M
      (psKernelKernelSessionEnvironment session) :=
    environmentModel_withNativeEvaluator M session.environment
      session.provider.nativeEvaluator model
  exact referenceAddAxiom_preserves_model
    M session.resources.fuel (psKernelKernelSessionEnvironment session)
    next value session.resources.maxRecDepth session.resources.maxNatSize
    sourceModel allowedAxiom
    (referenceDispatchAxiom_returns_add session value next run)

end PsKernelSemantics.SetModel
