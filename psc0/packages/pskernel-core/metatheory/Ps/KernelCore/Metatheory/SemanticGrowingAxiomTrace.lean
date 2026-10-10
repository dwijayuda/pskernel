import Ps.KernelCore.Metatheory.SemanticFreshAdmission
import Ps.KernelCore.Metatheory.SemanticPublicAdmissionSequence

/-!
A growing set model for ACTUAL public reference-mode axiom admissions.

The old modeled-axiom trace fixes one constant interpretation for the entire
stream. That is stronger than necessary and does not construct the value of
a newly introduced constant. Here each successful public axiom admission
extends the actual preceding Reading, keeping its previous interpretations.

Every axiom still requires an INDEPENDENT, mathematically genuine membership
certificate. This does not prove unrestricted Lean-compatible axioms sound,
nor the correctness of checked theorems, definitions, inductives or quotients.
-/

namespace PsKernelSemantics.SetModel
open ConLeche ConLeche.SetTheory ConLeche.SetModel AnnotatedExpr
universe u
variable {V : Type u} [SetTheory V]

/-- The proposed new constant has a fixed annotated type and an assigned
semantic value valid in the PRE-ADMISSION interpretation. The value cannot
be justified by the checker admitting an unrestricted axiom: it is an
explicit allowed-axiom policy obligation. -/
def FreshAxiomValueModeled (M : Reading V)
    (info : PsKernelConstantInfo) (value : List Nat → V) : Prop :=
  ∃ A : AnnotatedExpr,
    A.erase = psKernelConstantInfoType info ∧
    RawAvoidsConstant (psKernelConstantInfoName info)
      (psKernelConstantInfoType info) ∧
    ∀ levels, CorrectUniverseArity info levels →
      ∀ ρ, value (levels.map M.level) ∈ˢ
        interp (M.substLevels (psKernelConstantInfoLevelParams info)
          levels) ρ A

/-- A successful REAL public axiom admission builds a new modeled
environment, with its own Reading, from an independently allowed semantic
interpretation. No step assumes a fresh name's value had been fortuitously
modeled in the pre-admission Reading. -/
theorem referenceAdmitAxiom_constructs_reading
    (M : Reading V) (session : PsKernelKernelSession)
    (axiom : PsKernelAxiomInfo) (outcome : PsKernelAdmissionResult)
    (chosen : List Nat → V)
    (model : EnvironmentModel M session.environment)
    (noForward : ∀ prev, prev ∈ session.environment.constants →
      RawAvoidsConstant (psKernelConstantInfoName (.axiomInfo axiom))
        (psKernelConstantInfoType prev))
    (notReserved : psKernelConstantInfoName (.axiomInfo axiom) ≠
      falseConstantName)
    (allowed : FreshAxiomValueModeled M (.axiomInfo axiom) chosen)
    (run : @psKernelV1AdmitDeclaration psKernelReferenceCachePolicy
      session (.axiomDecl axiom) = .ok outcome) :
    EnvironmentModel
      (M.extendConstant (psKernelConstantInfoName (.axiomInfo axiom)) chosen)
      outcome.session.environment := by
  obtain ⟨A, erased, selfFree, assignment⟩ := allowed
  have sourceModel : EnvironmentModel M
      (psKernelKernelSessionEnvironment session) :=
    environmentModel_withNativeEvaluator M session.environment
      session.provider.nativeEvaluator model
  have sourcePrior : ∀ prev,
      prev ∈ (psKernelKernelSessionEnvironment session).constants →
      RawAvoidsConstant (psKernelConstantInfoName (.axiomInfo axiom))
        (psKernelConstantInfoType prev) := by
    simpa only [psKernelKernelSessionEnvironment,
      psKernelEnvironmentWithNativeEvaluator] using noForward
  apply referenceAdmit_of_dispatch_model
    (M.extendConstant (psKernelConstantInfoName (.axiomInfo axiom)) chosen)
    session (.axiomDecl axiom) outcome ?_ run
  intro dispatched dispatchedRun
  have axiomRun := referenceDispatchAxiom_returns_add
    session axiom dispatched dispatchedRun
  have inserted := referenceAddAxiom_returns_insert
    session.resources.fuel
    (psKernelKernelSessionEnvironment session)
    dispatched axiom session.resources.maxRecDepth
    session.resources.maxNatSize axiomRun
  exact successfulAdd_model_with_fresh_reading M
    (psKernelKernelSessionEnvironment session) dispatched
    (.axiomInfo axiom) chosen A sourceModel
    sourcePrior notReserved erased selfFree assignment inserted

/-- Every constructor step is an ACTUAL public reference API success,
and its modeled new axiom gets one newly constructed constant assignment.
The model may change on each step, unlike the fixed-reading trace. -/
inductive GrowingModeledAxiomTrace :
    Reading V → PsKernelKernelSession →
    Reading V → PsKernelKernelSession → Prop where
  | empty (M : Reading V) (session : PsKernelKernelSession) :
      GrowingModeledAxiomTrace M session M session
  | append (M : Reading V) (session : PsKernelKernelSession)
      (axiom : PsKernelAxiomInfo) (outcome : PsKernelAdmissionResult)
      (chosen : List Nat → V) (finalReading : Reading V)
      (finalSession : PsKernelKernelSession)
      (noForward : ∀ prev, prev ∈ session.environment.constants →
        RawAvoidsConstant (psKernelConstantInfoName (.axiomInfo axiom))
          (psKernelConstantInfoType prev))
      (notReserved : psKernelConstantInfoName (.axiomInfo axiom) ≠
        falseConstantName)
      (allowed : FreshAxiomValueModeled M (.axiomInfo axiom) chosen)
      (accepted : @psKernelV1AdmitDeclaration psKernelReferenceCachePolicy
        session (.axiomDecl axiom) = .ok outcome)
      (rest : GrowingModeledAxiomTrace
        (M.extendConstant (psKernelConstantInfoName (.axiomInfo axiom)) chosen)
        outcome.session finalReading finalSession) :
      GrowingModeledAxiomTrace M session finalReading finalSession

/-- Structural induction over actual public-session receipts; each step
constructs a new EnvironmentModel using only the selected preceding one.
This is not an assumed fixed-M acceptance theorem. -/
theorem GrowingModeledAxiomTrace.preserves
    {M finalReading : Reading V}
    {initial final : PsKernelKernelSession}
    (trace : GrowingModeledAxiomTrace M initial finalReading final) :
    EnvironmentModel M initial.environment →
      EnvironmentModel finalReading final.environment := by
  induction trace with
  | empty M session =>
      intro model
      exact model
  | append M session axiom outcome chosen finalReading finalSession
        noForward notReserved allowed accepted rest ih =>
      intro model
      apply ih
      exact referenceAdmitAxiom_constructs_reading
        M session axiom outcome chosen model noForward
        notReserved allowed accepted

/-- The evolving model of an ACTUAL public axiom-only admission sequence
has no stored zero-parameter literal-False declaration when each axiom is
independently modeled by its selected new semantic value. The initial
interpretation is explicitly constructed from the relative SetTheory V
foundation. This does NOT show no DERIVED proof of False and does not
certify unrestricted Lean axioms or other declaration kinds. -/
theorem growingPublicAxiomTrace_no_literalFalse
    (resources : PsKernelResourcePolicy)
    (provider : PsKernelProviderCapability)
    (initial final : PsKernelKernelSession)
    (finalReading : Reading V)
    (started : psKernelKernelSessionEmpty resources provider = .ok initial)
    (trace : GrowingModeledAxiomTrace
      (initialReading V) initial finalReading final)
    (info : PsKernelConstantInfo)
    (present : info ∈ final.environment.constants)
    (noParams : psKernelConstantInfoLevelParams info = [])
    (declaredFalse : psKernelConstantInfoType info =
      .const falseConstantName []) : False := by
  have initialEmpty : initial.environment = psKernelEnvironmentEmpty :=
    PsKernelSemantics.emptyKernelSession_environment
      resources provider initial started
  have initialModel : EnvironmentModel (initialReading V)
      initial.environment := by
    rw [initialEmpty]
    exact environmentEmpty_model (initialReading V)
      (initialReading_falsePinned V)
  have finalModel : EnvironmentModel finalReading
      final.environment :=
    GrowingModeledAxiomTrace.preserves trace initialModel
  exact no_stored_constant_of_literalFalse
    finalReading final.environment finalModel
    info present noParams declaredFalse

end PsKernelSemantics.SetModel
