import Ps.KernelCore.Metatheory.SemanticReferenceAxiomAdmission

/-!
One public admission boundary theorem for ALL PSKernel declaration request
constructors: check preflight, executed dispatch, resource guard and returned
session agree with the selected real program.

This is not a global soundness theorem. Every *dispatch kind* must separately
prove its resulting environment is semantically modeled, with correct axioms,
checked terms, inductive rules, quotients, native reductions and erasure.
The theorem does not turn an unknown/uncertified dispatch result into a model.
-/
namespace PsKernelSemantics.SetModel
open ConLeche ConLeche.SetTheory
universe u
variable {V : Type u} [SetTheory V]

/-- A successful reference checked-environment request, of ANY declaration
kind, comes from its concrete successful dispatch, then clears the native
evaluator after the actual public resource checks. -/
theorem referenceChecked_dispatch_result
    (session : PsKernelKernelSession)
    (request : PsKernelDeclarationRequest)
    (result : PsKernelEnvironment)
    (run : @psKernelV1CheckedEnvironment psKernelReferenceCachePolicy
      session request = .ok result) :
    ∃ dispatched : PsKernelEnvironment,
      @psKernelV1DispatchDeclaration psKernelReferenceCachePolicy
        session request = .ok dispatched ∧
      result = psKernelEnvironmentWithNativeEvaluator dispatched none := by
  cases hPreflight : psKernelKernelSessionPreflight session with
  | error err =>
      simp [psKernelV1CheckedEnvironment, hPreflight] at run
  | ok valid =>
      cases hDispatch : @psKernelV1DispatchDeclaration psKernelReferenceCachePolicy
          session request with
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

/-- Inverting the real reference public admission returns the exact successful
dispatch environment plus its native-evaluator-cleared representation. -/
theorem referenceAdmit_dispatch_result
    (session : PsKernelKernelSession)
    (request : PsKernelDeclarationRequest)
    (outcome : PsKernelAdmissionResult)
    (run : @psKernelV1AdmitDeclaration psKernelReferenceCachePolicy
      session request = .ok outcome) :
    ∃ dispatched : PsKernelEnvironment,
      @psKernelV1DispatchDeclaration psKernelReferenceCachePolicy
        session request = .ok dispatched ∧
      outcome.session.environment =
        psKernelEnvironmentWithNativeEvaluator dispatched none := by
  cases hCheck : @psKernelV1CheckedEnvironment psKernelReferenceCachePolicy
      session request with
  | error err =>
      simp [psKernelV1AdmitDeclaration, hCheck] at run
  | ok next =>
      have returned :
          PsKernelAdmissionResult.mk
            (PsKernelKernelSession.mk next session.resources session.provider)
            (PsKernelCheckedDeclaration.mk request
              (psKernelV1Receipt session next)) = outcome := by
        simpa [psKernelV1AdmitDeclaration, hCheck] using run
      have hEnv : outcome.session.environment = next := by
        rw [← returned]
      obtain ⟨dispatched, hDispatch, hNext⟩ :=
        referenceChecked_dispatch_result session request next hCheck
      exact ⟨dispatched, hDispatch, hEnv.trans hNext⟩

/-- Compositional public soundness bridge. The caller MUST prove the
per-constructor dispatch model theorem from the actual checker operations;
merely positing it does not establish that PSKernel is sound.

This is the single public admission wrapper target for the full proof. -/
theorem referenceAdmit_of_dispatch_model
    (M : Reading V) (session : PsKernelKernelSession)
    (request : PsKernelDeclarationRequest)
    (outcome : PsKernelAdmissionResult)
    (dispatchSound : ∀ env : PsKernelEnvironment,
      @psKernelV1DispatchDeclaration psKernelReferenceCachePolicy
        session request = .ok env → EnvironmentModel M env)
    (run : @psKernelV1AdmitDeclaration psKernelReferenceCachePolicy
      session request = .ok outcome) :
    EnvironmentModel M outcome.session.environment := by
  obtain ⟨dispatched, hDispatch, hEnv⟩ :=
    referenceAdmit_dispatch_result session request outcome run
  rw [hEnv]
  exact environmentModel_withNativeEvaluator M dispatched none
    (dispatchSound dispatched hDispatch)

end PsKernelSemantics.SetModel
