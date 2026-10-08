import Ps.KernelCore.Metatheory.SessionConcreteRefinement
import Ps.KernelCore.Metatheory.SessionRefinement
import Ps.KernelCore.Admission.Declaration.Validation

/-
Concrete validated declaration header refinement.

A successfully checked constant base is independently well-typed, and its
inferred type reduces to the Sort confirmed by the executable validator.
This deliberately does not yet assert that the full declaration has been
admitted or that an arbitrary environment extension is well formed.
-/

theorem psKernelCheckConstantBaseWithSession_configuration_refines
    (fuel : Nat)
    (hNative : PsKernelNativeReductionSoundLaw)
    (hString : PsKernelStringEqSoundLaw)
    (session nextSession : PsKernelCheckerSession)
    (base : PsKernelConstantBase)
    (hConfig :
      PsKernelCheckerConfigurationSound
        session.context session.state)
    (hRun :
      psKernelCheckConstantBaseWithSession
          fuel session base =
        Except.ok nextSession) :
    ∃ (inferredType : PsKernelExpr) (level : PsKernelLevel),
      PsKernelTypingJudgment
          session.context.environment session.context.localContext
          base.type inferredType ∧
        PsKernelReductionClosure
          session.context.environment session.context.localContext
          inferredType (PsKernelExpr.sort level) ∧
        PsKernelCheckerConfigurationSound
          session.context nextSession.state := by
  cases hContains :
      psKernelEnvironmentContains
        session.context.environment base.name with
  | true =>
      simp [psKernelCheckConstantBaseWithSession, hContains] at hRun
  | false =>
      cases hDup : psKernelNameHasDuplicates base.levelParams with
      | true =>
          simp [
            psKernelCheckConstantBaseWithSession,
            hContains, hDup
          ] at hRun
      | false =>
          cases hNoFree :
              psKernelCheckNoMVarNoFVar base.type with
          | error error =>
              simp [
                psKernelCheckConstantBaseWithSession,
                hContains, hDup, hNoFree
              ] at hRun
          | ok noFree =>
              cases hLevels :
                  psKernelCheckLevelParams
                    base.type base.levelParams with
              | error error =>
                  simp [
                    psKernelCheckConstantBaseWithSession,
                    hContains, hDup, hNoFree, hLevels
                  ] at hRun
              | ok levelsChecked =>
                  cases hCheck :
                      psKernelSessionCheck fuel session base.type with
                  | error error =>
                      simp [
                        psKernelCheckConstantBaseWithSession,
                        hContains, hDup, hNoFree, hLevels, hCheck
                      ] at hRun
                  | ok checkedRun =>
                      rcases checkedRun with
                        ⟨inferredType, checkedSession⟩
                      have hChecked :=
                        psKernelSessionCheck_concrete_refines_typing
                          fuel hNative hString
                          session checkedSession
                          base.type inferredType hConfig hCheck
                      have hContext :
                          checkedSession.context = session.context :=
                        psKernelSessionCheck_success_preserves_context_core
                          fuel session checkedSession
                          base.type inferredType hCheck
                      have hCheckedConfig :
                          PsKernelCheckerConfigurationSound
                            checkedSession.context checkedSession.state := by
                        simpa [hContext] using hChecked.2
                      cases hSort :
                          psKernelSessionEnsureSort
                            fuel checkedSession inferredType with
                      | error error =>
                          simp [
                            psKernelCheckConstantBaseWithSession,
                            hContains, hDup, hNoFree, hLevels,
                            hCheck, hSort
                          ] at hRun
                      | ok sortRun =>
                          rcases sortRun with ⟨level, sortSession⟩
                          have hSortSound :=
                            psKernelSessionEnsureSort_concrete_refines_reduction
                              fuel hNative hString
                              checkedSession sortSession
                              inferredType level hCheckedConfig hSort
                          simp [
                            psKernelCheckConstantBaseWithSession,
                            hContains, hDup, hNoFree, hLevels,
                            hCheck, hSort
                          ] at hRun
                          rcases hRun with rfl
                          refine
                            ⟨inferredType, level, hChecked.1, ?_, ?_⟩
                          · simpa [hContext] using hSortSound.1
                          · simpa [hContext] using hSortSound.2


/-
Header validation threads checker state but never changes the session context.
This is required to transport the successful header's configuration invariant
into the body validator in the same authoritative environment.
-/
theorem psKernelCheckConstantBaseWithSession_success_preserves_context
    (fuel : Nat)
    (session nextSession : PsKernelCheckerSession)
    (base : PsKernelConstantBase)
    (hRun :
      psKernelCheckConstantBaseWithSession fuel session base =
        Except.ok nextSession) :
    nextSession.context = session.context := by
  cases hContains :
      psKernelEnvironmentContains
        session.context.environment base.name with
  | true =>
      simp [psKernelCheckConstantBaseWithSession, hContains] at hRun
  | false =>
      cases hDup : psKernelNameHasDuplicates base.levelParams with
      | true =>
          simp [psKernelCheckConstantBaseWithSession, hContains, hDup] at hRun
      | false =>
          cases hNoFree : psKernelCheckNoMVarNoFVar base.type with
          | error error =>
              simp [
                psKernelCheckConstantBaseWithSession,
                hContains, hDup, hNoFree
              ] at hRun
          | ok noFree =>
              cases hLevels :
                  psKernelCheckLevelParams base.type base.levelParams with
              | error error =>
                  simp [
                    psKernelCheckConstantBaseWithSession,
                    hContains, hDup, hNoFree, hLevels
                  ] at hRun
              | ok checkedLevels =>
                  cases hCheck :
                      psKernelSessionCheck fuel session base.type with
                  | error error =>
                      simp [
                        psKernelCheckConstantBaseWithSession,
                        hContains, hDup, hNoFree, hLevels, hCheck
                      ] at hRun
                  | ok checkedRun =>
                      rcases checkedRun with ⟨inferredType, checkedSession⟩
                      have hCheckContext :=
                        psKernelSessionCheck_success_preserves_context_core
                          fuel session checkedSession
                          base.type inferredType hCheck
                      cases hSort :
                          psKernelSessionEnsureSort
                            fuel checkedSession inferredType with
                      | error error =>
                          simp [
                            psKernelCheckConstantBaseWithSession,
                            hContains, hDup, hNoFree,
                            hLevels, hCheck, hSort
                          ] at hRun
                      | ok sortRun =>
                          rcases sortRun with ⟨level, sortSession⟩
                          have hSortContext :=
                            psKernelSessionEnsureSort_success_preserves_context_core
                              fuel checkedSession sortSession
                              inferredType level hSort
                          simp [
                            psKernelCheckConstantBaseWithSession,
                            hContains, hDup, hNoFree,
                            hLevels, hCheck, hSort
                          ] at hRun
                          rcases hRun with rfl
                          exact hSortContext.trans hCheckContext
