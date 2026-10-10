import Ps.KernelCore.Metatheory.SemanticReferenceAxiomAdmission

/-!
The actual PUBLIC reference admission boundary for modeled axioms.

The theorem is conditional on a genuinely modeled axiom; the public
Lean-compatible kernel can admit unmodeled assumptions. The proof explicitly
passes through preflight, dispatch, resource checks and the returned session's
environment, with no alternate trusted checker implementation.

This is an axiom-only component, NOT full soundness for checked proofs,
inductives, quotient primitives, or arbitrary declaration sequences.
-/
namespace PsKernelSemantics.SetModel
open ConLeche ConLeche.SetTheory
universe u
variable {V : Type u} [SetTheory V]

/-- Invert the real successful public checked-environment API: preflight and
resource bounds were passed, and the returned environment is the actual
dispatch result with native evaluator disabled. -/
theorem referenceCheckedAxiom_dispatch_result
    (session : PsKernelKernelSession) (value : PsKernelAxiomInfo)
    (result : PsKernelEnvironment)
    (run : @psKernelV1CheckedEnvironment psKernelReferenceCachePolicy
      session (.axiomDecl value) = .ok result) :
    ∃ dispatched : PsKernelEnvironment,
      @psKernelV1DispatchDeclaration psKernelReferenceCachePolicy
        session (.axiomDecl value) = .ok dispatched ∧
      result = psKernelEnvironmentWithNativeEvaluator dispatched none := by
  cases hPreflight : psKernelKernelSessionPreflight session with
  | error err =>
      simp [psKernelV1CheckedEnvironment, hPreflight] at run
  | ok valid =>
      cases hDispatch : @psKernelV1DispatchDeclaration psKernelReferenceCachePolicy
          session (.axiomDecl value) with
      | error err =>
          simp [psKernelV1CheckedEnvironment, hPreflight, hDispatch] at run
      | ok dispatched =>
          cases hResource : psKernelResourceAllowsSize session.resources
              (psKernelEnvironmentSize dispatched) with
          | false =>
              simp [psKernelV1CheckedEnvironment, hPreflight,
                hDispatch, hResource] at run
          | true =>
              refine ⟨dispatched, rfl, ?_⟩
              have equality :
                  (Except.ok (psKernelEnvironmentWithNativeEvaluator
                    dispatched none) : Except PsKernelError PsKernelEnvironment) =
                    Except.ok result := by
                simpa [psKernelV1CheckedEnvironment, hPreflight,
                  hDispatch, hResource] using run
              exact (Except.ok.inj equality).symm

/-- Full PUBLIC reference axiom admission returns a modeled session under
the admitted axiom's external semantic justification. No semantic premise
is inferred from the unrestricted syntactic success verdict. -/
theorem referenceAdmitAxiom_preserves_model
    (M : Reading V) (session : PsKernelKernelSession)
    (value : PsKernelAxiomInfo) (outcome : PsKernelAdmissionResult)
    (model : EnvironmentModel M session.environment)
    (allowedAxiom : StoredConstantModeled M (.axiomInfo value))
    (run : @psKernelV1AdmitDeclaration psKernelReferenceCachePolicy
      session (.axiomDecl value) = .ok outcome) :
    EnvironmentModel M outcome.session.environment := by
  cases hCheck : @psKernelV1CheckedEnvironment psKernelReferenceCachePolicy
      session (.axiomDecl value) with
  | error err =>
      simp [psKernelV1AdmitDeclaration, hCheck] at run
  | ok next =>
      have returned :
          PsKernelAdmissionResult.mk
            (PsKernelKernelSession.mk next session.resources session.provider)
            (PsKernelCheckedDeclaration.mk (.axiomDecl value)
              (psKernelV1Receipt session next)) = outcome := by
        simpa [psKernelV1AdmitDeclaration, hCheck] using run
      have hEnv : outcome.session.environment = next := by
        rw [← returned]
      obtain ⟨dispatched, hDispatch, hNext⟩ :=
        referenceCheckedAxiom_dispatch_result session value next hCheck
      have hModeled : EnvironmentModel M dispatched :=
        referenceDispatchAxiom_preserves_model M session value dispatched
          model allowedAxiom hDispatch
      rw [hEnv, hNext]
      exact environmentModel_withNativeEvaluator M dispatched none hModeled

end PsKernelSemantics.SetModel
