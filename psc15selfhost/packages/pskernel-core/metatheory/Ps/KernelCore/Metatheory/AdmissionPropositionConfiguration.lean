import Ps.KernelCore.Metatheory.AdmissionValueConfiguration

/-
Concrete proposition classification before theorem admission.

The infer-only stage preserves configuration but is not a typing certificate.
A positive result witnesses WHNF reduction of its inferred type to a Sort whose
universe level normalizes to zero; separate checked-header evidence is required
before theorem admission may claim a well-typed proposition.
-/
theorem psKernelSessionIsProp_true_configuration_refines
    (fuel : Nat)
    (hNative : PsKernelNativeReductionSoundLaw)
    (hString : PsKernelStringEqSoundLaw)
    (session nextSession : PsKernelCheckerSession)
    (expr : PsKernelExpr)
    (hConfig :
      PsKernelCheckerConfigurationSound
        session.context session.state)
    (hRun :
      psKernelSessionIsProp fuel session expr =
        Except.ok (Prod.mk true nextSession)) :
    ∃ (inferredType : PsKernelExpr) (level : PsKernelLevel),
      PsKernelReductionClosure
          session.context.environment
          session.context.localContext
          inferredType (PsKernelExpr.sort level) ∧
        psKernelLevelNormalizesToZero level = true ∧
        PsKernelCheckerConfigurationSound
          session.context nextSession.state ∧
        nextSession.context = session.context := by
  cases hInfer :
      psKernelSessionInfer fuel session expr with
  | error error =>
      simp [psKernelSessionIsProp, hInfer] at hRun
  | ok inferRun =>
      rcases inferRun with ⟨inferredType, inferredSession⟩
      have hInferredConfig :=
        psKernelSessionInfer_concrete_preserves_configuration
          fuel hNative hString
          session inferredSession expr inferredType
          hConfig hInfer
      have hInferredContext :
          inferredSession.context = session.context :=
        psKernelSessionInfer_success_preserves_context_core
          fuel session inferredSession expr inferredType hInfer
      have hInferConfig :
          PsKernelCheckerConfigurationSound
            inferredSession.context inferredSession.state := by
        simpa [hInferredContext] using hInferredConfig
      cases hSort :
          psKernelSessionEnsureSort
            fuel inferredSession inferredType with
      | error error =>
          simp [psKernelSessionIsProp, hInfer, hSort] at hRun
      | ok sortRun =>
          rcases sortRun with ⟨level, sortSession⟩
          have hSortSound :=
            psKernelSessionEnsureSort_concrete_refines_reduction
              fuel hNative hString
              inferredSession sortSession inferredType level
              hInferConfig hSort
          have hSortContext :
              sortSession.context = inferredSession.context :=
            psKernelSessionEnsureSort_success_preserves_context_core
              fuel inferredSession sortSession inferredType level hSort
          have hResult :
              Prod.mk
                  (psKernelLevelNormalizesToZero level)
                  sortSession =
                Prod.mk true nextSession := by
            simpa [psKernelSessionIsProp, hInfer, hSort] using hRun
          have hZero :
              psKernelLevelNormalizesToZero level = true :=
            congrArg Prod.fst hResult
          have hNext : sortSession = nextSession :=
            congrArg Prod.snd hResult
          subst nextSession
          refine ⟨inferredType, level, ?_, hZero, ?_, ?_⟩
          · simpa [hInferredContext] using hSortSound.1
          · simpa [hInferredContext] using hSortSound.2
          · exact hSortContext.trans hInferredContext
