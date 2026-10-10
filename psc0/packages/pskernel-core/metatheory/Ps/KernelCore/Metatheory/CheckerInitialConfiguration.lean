import Ps.KernelCore.Checker.Session
import Ps.KernelCore.Metatheory.ContextState

/-
Initial checker-session soundness for admission.

The constructor has an empty local context and all semantic caches empty.
Its configuration invariant therefore follows from the independent
authoritative-environment index invariant, not from trusting an unchecked
session or assuming that its caches are sound.
-/

theorem psKernelCheckerStateEmpty_semantic_initial
    (environment : PsKernelEnvironment)
    (localContext : PsKernelLocalContext) :
    PsKernelCheckerStateSemanticSound
      environment localContext psKernelCheckerStateEmpty := by
  unfold PsKernelCheckerStateSemanticSound
  refine ⟨?_, ?_, ?_, ?_, ?_, ?_⟩
  · exact
      psKernelInferOnlyCacheIsolated_empty
        environment localContext
  · intro expr result hCache
    simp [
      psKernelCheckerStateEmpty, psKernelExprMapEmpty,
      psKernelExprMapGet, psKernelExprMapGetIn
    ] at hCache
  · intro expr result hCache
    simp [
      psKernelCheckerStateEmpty, psKernelExprMapEmpty,
      psKernelExprMapGet, psKernelExprMapGetIn
    ] at hCache
  · intro expr result hCache
    simp [
      psKernelCheckerStateEmpty, psKernelExprMapEmpty,
      psKernelExprMapGet, psKernelExprMapGetIn
    ] at hCache
  · intro expr result hCache
    simp [
      psKernelCheckerStateEmpty, psKernelExprMapEmpty,
      psKernelExprMapGet, psKernelExprMapGetIn
    ] at hCache
  · intro left right hCache
    simp [
      psKernelCheckerStateEmpty, psKernelExprPairSetEmpty,
      psKernelExprPairSetContains, psKernelExprPairSetContainsIn
    ] at hCache


theorem psKernelMkCheckerSession_configuration_sound
    (environment : PsKernelEnvironment)
    (levelParams : List PsKernelName)
    (safety : PsKernelDefinitionSafety)
    (maxRecDepth maxNatSize : Nat)
    (hIndex : PsKernelEnvironmentIndexRefines environment) :
    PsKernelCheckerConfigurationSound
      (psKernelMkCheckerSession
        environment levelParams safety
        maxRecDepth maxNatSize).context
      (psKernelMkCheckerSession
        environment levelParams safety
        maxRecDepth maxNatSize).state := by
  change
    PsKernelEnvironmentIndexRefines environment ∧
      PsKernelLocalContextFreshBound psKernelLocalContextEmpty 0 ∧
      PsKernelCheckerStateSemanticSound
        environment psKernelLocalContextEmpty psKernelCheckerStateEmpty
  exact
    ⟨hIndex,
      psKernelLocalContextEmpty_freshBound 0,
      psKernelCheckerStateEmpty_semantic_initial
        environment psKernelLocalContextEmpty⟩
