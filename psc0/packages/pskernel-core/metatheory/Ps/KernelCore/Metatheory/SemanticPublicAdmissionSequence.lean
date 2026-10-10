import Ps.KernelCore.Metatheory.SemanticPublicAdmissionBoundary

/-!
Full public-reference admission induction *interface* for PSKernel's one real
checker. All accepted requests use the actual public API. This is a modular
theorem that reduces end-to-end consistency to per-kind dispatch/model
preservation, rather than pretending those still-open premises are proved.

Per-kind certificates are explicit constructors' arguments; the full kernel
proof will produce them from actual inference/DefEq/admission executions.
No executable second checker, fallback or custom mathematical axiom exists.
-/
namespace PsKernelSemantics.SetModel
open ConLeche ConLeche.SetTheory
universe u
variable {V : Type u} [SetTheory V]

/-- Each step is an actual successful reference public admission and a
model-preservation *proof* for its particular dispatch branch; this proof
is not automatically obtained from successful checking. -/
inductive ModeledPublicReferenceTrace (M : Reading V) :
    PsKernelKernelSession → PsKernelKernelSession → Prop where
  | empty (session : PsKernelKernelSession) :
      ModeledPublicReferenceTrace M session session
  | append (session : PsKernelKernelSession)
      (request : PsKernelDeclarationRequest)
      (result : PsKernelAdmissionResult)
      (final : PsKernelKernelSession)
      (accepted : @psKernelV1AdmitDeclaration psKernelReferenceCachePolicy
        session request = .ok result)
      (stepSound : EnvironmentModel M session.environment →
        ∀ dispatched : PsKernelEnvironment,
          @psKernelV1DispatchDeclaration psKernelReferenceCachePolicy
            session request = .ok dispatched →
          EnvironmentModel M dispatched)
      (rest : ModeledPublicReferenceTrace M result.session final) :
      ModeledPublicReferenceTrace M session final

/-- A sequence of genuine public accepting calls preserves the environment
model once each dispatch model obligation is independently discharged.
This proves the public API composition step for EVERY request constructor,
not the yet-open correctness of all constructors. -/
theorem ModeledPublicReferenceTrace.preserves (M : Reading V)
    {initial final : PsKernelKernelSession}
    (trace : ModeledPublicReferenceTrace M initial final) :
    EnvironmentModel M initial.environment →
      EnvironmentModel M final.environment := by
  induction trace with
  | empty session =>
      intro model
      exact model
  | append session request result final accepted stepSound rest ih =>
      intro model
      apply ih
      exact referenceAdmit_of_dispatch_model M session request result
        (stepSound model) accepted

/-- The public result is relatively consistent for any stream whose
per-constructor semantic admission proofs exist, starting from the actual
empty session and an explicitly pinned False-as-empty interpretation.
It is NOT an unconditional proof of full public checker soundness. -/
theorem modeledPublicReferenceTrace_no_literalFalse
    (M : Reading V)
    (pin : M.constants falseConstantName [] = (empty : V))
    (resources : PsKernelResourcePolicy)
    (provider : PsKernelProviderCapability)
    (initial final : PsKernelKernelSession)
    (started : psKernelKernelSessionEmpty resources provider = .ok initial)
    (trace : ModeledPublicReferenceTrace M initial final)
    (info : PsKernelConstantInfo)
    (present : info ∈ final.environment.constants)
    (noParams : psKernelConstantInfoLevelParams info = [])
    (declaredFalse :
      psKernelConstantInfoType info = .const falseConstantName []) : False := by
  have initialEmpty : initial.environment = psKernelEnvironmentEmpty :=
    PsKernelSemantics.emptyKernelSession_environment resources provider
      initial started
  have initialModel : EnvironmentModel M initial.environment := by
    rw [initialEmpty]
    exact environmentEmpty_model M pin
  have finalModel : EnvironmentModel M final.environment :=
    ModeledPublicReferenceTrace.preserves M trace initialModel
  exact no_stored_constant_of_literalFalse M final.environment
    finalModel info present noParams declaredFalse

end PsKernelSemantics.SetModel
