import Ps.KernelCore.Metatheory.SemanticPublicAxiomAdmission

/-!
A successful *public reference* axiom-only admission trace is a sequence of
actual PSKernel API calls, not a separate executable checker.

Each new axiom is supplied with an explicit, fixed-interpretation model
certificate. This is necessary for Lean compatibility: the normal kernel
accepts user axioms as assumptions, including possibly False, and cannot
claim their model from syntactic acceptance alone.

The end theorem is a consistency corollary for that restricted trace, NOT
soundness for checked theorem bodies, definitions, inductives or quotients.
-/
namespace PsKernelSemantics.SetModel
open ConLeche ConLeche.SetTheory
universe u
variable {V : Type u} [SetTheory V]

/-- Every step is a SUCCESS of the *real* public admission API in reference
mode, and the given axiom has been independently interpreted under one
fixed reading. All resource and header checks remain part of that API call. -/
inductive ModeledReferenceAxiomTrace (M : Reading V) :
    PsKernelKernelSession → PsKernelKernelSession → Prop where
  | empty (session : PsKernelKernelSession) :
      ModeledReferenceAxiomTrace M session session
  | append (session : PsKernelKernelSession)
      (value : PsKernelAxiomInfo) (accepted : PsKernelAdmissionResult)
      (final : PsKernelKernelSession)
      (modeled : StoredConstantModeled M (.axiomInfo value))
      (run : @psKernelV1AdmitDeclaration psKernelReferenceCachePolicy
        session (.axiomDecl value) = .ok accepted)
      (tail : ModeledReferenceAxiomTrace M accepted.session final) :
      ModeledReferenceAxiomTrace M session final

/-- Inductively transport PSKernel's genuine indexed declaration-history
model through a sequence of actual successful, separately modeled axiom
admissions. No cached acceptance theorem or new trusted step is inserted. -/
theorem ModeledReferenceAxiomTrace.preserves (M : Reading V)
    {initial final : PsKernelKernelSession}
    (trace : ModeledReferenceAxiomTrace M initial final) :
    EnvironmentModel M initial.environment →
      EnvironmentModel M final.environment := by
  induction trace with
  | empty session =>
      intro modeled
      exact modeled
  | append session value accepted final allowed run tail ih =>
      intro modeled
      apply ih
      exact referenceAdmitAxiom_preserves_model M session value accepted
        modeled allowed run

/-- The first end-to-end *axiom-only* relative consistency corollary for
actual public PSKernel reference admissions with explicit modeled axioms.
It says nothing about unrestricted Lean-compatible axioms or theorem,
definition, inductive, quotient and native-reduction admission. -/
theorem modeledPublicAxiomTrace_no_literalFalse
    (M : Reading V)
    (pin : M.constants falseConstantName [] = (empty : V))
    (resources : PsKernelResourcePolicy)
    (provider : PsKernelProviderCapability)
    (initial final : PsKernelKernelSession)
    (started : psKernelKernelSessionEmpty resources provider = .ok initial)
    (trace : ModeledReferenceAxiomTrace M initial final)
    (info : PsKernelConstantInfo) (present : info ∈ final.environment.constants)
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
    ModeledReferenceAxiomTrace.preserves M trace initialModel
  exact no_stored_constant_of_literalFalse M final.environment
    finalModel info present noParams declaredFalse

end PsKernelSemantics.SetModel
