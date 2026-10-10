import Ps.KernelCore.API.Session
import Ps.KernelCore.Metatheory.Judgments

/-!
Proofs for checked-session construction and preflight.

The public session constructor and preflight are part of the fail-closed
KernelContract-v1 boundary. No theorem here claims that arbitrary directly
constructed low-level environments are trusted.
-/

theorem psKernelSessionEmpty_rejects_incompatible_provider
    (resources : PsKernelResourcePolicy)
    (provider : PsKernelProviderCapability)
    (h : psKernelProviderCompatible provider = false) :
    psKernelKernelSessionEmpty resources provider =
      Except.error
        (PsKernelError.declinedUnsupported
          "provider target does not match KernelContract-v1") := by
  simp [psKernelKernelSessionEmpty, h]

theorem psKernelSessionEmpty_accepts_compatible_provider
    (resources : PsKernelResourcePolicy)
    (provider : PsKernelProviderCapability)
    (h : psKernelProviderCompatible provider = true) :
    psKernelKernelSessionEmpty resources provider =
      Except.ok
        (PsKernelKernelSession.mk
          psKernelEnvironmentEmpty
          resources
          provider) := by
  simp [psKernelKernelSessionEmpty, h]

theorem psKernelSessionPreflight_rejects_incompatible_provider
    (session : PsKernelKernelSession)
    (h : psKernelProviderCompatible session.provider = false) :
    psKernelKernelSessionPreflight session =
      Except.error
        (PsKernelError.declinedUnsupported
          "provider target does not match KernelContract-v1") := by
  simp [psKernelKernelSessionPreflight, h]

theorem psKernelSessionPreflight_propagates_resource_failure
    (session : PsKernelKernelSession)
    (resource : PsKernelResourceError)
    (hProvider :
      psKernelProviderCompatible session.provider = true)
    (hResource :
      psKernelResourcePreflight session.resources =
        Option.some resource) :
    psKernelKernelSessionPreflight session =
      Except.error
        (PsKernelError.resourceExhausted
          resource
          "resource policy declined operation before entry") := by
  simp [psKernelKernelSessionPreflight, hProvider, hResource]

theorem psKernelSessionPreflight_accepts
    (session : PsKernelKernelSession)
    (hProvider :
      psKernelProviderCompatible session.provider = true)
    (hResource :
      psKernelResourcePreflight session.resources = Option.none) :
    psKernelKernelSessionPreflight session =
      Except.ok Unit.unit := by
  simp [psKernelKernelSessionPreflight, hProvider, hResource]


theorem psKernelKernelSessionEnvironment_preserves_semantic_contract
    (session : PsKernelKernelSession)
    (hIndex :
      PsKernelEnvironmentIndexRefines session.environment) :
    psKernelEnvironmentSemantic
        (psKernelKernelSessionEnvironment session) =
      psKernelEnvironmentSemantic session.environment ∧
    PsKernelEnvironmentIndexRefines
      (psKernelKernelSessionEnvironment session) := by
  unfold psKernelKernelSessionEnvironment
  constructor
  · rfl
  · unfold PsKernelEnvironmentIndexRefines at hIndex ⊢
    intro name
    simpa [psKernelEnvironmentWithNativeEvaluator] using
      hIndex name
