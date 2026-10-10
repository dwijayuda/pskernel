import Ps.KernelCore.Metatheory.SessionConcreteRefinement
import Ps.KernelCore.Metatheory.SessionRefinement
import Ps.KernelCore.Admission.Declaration.Validation

/-
Concrete checked definition-body validation.

Successful validation must establish an independent typing judgment for the
submitted body and an algorithmic DefEq judgment equating the inferred type
with the declared type. The checker configuration remains sound throughout
both stateful session calls.

This result does not, by itself, certify that the containing environment
extension has been admitted: admission transactions must separately prove
their checks and extension/refinement boundary.
-/

theorem psKernelCheckDefinitionBodyWithSession_configuration_refines
    (fuel : Nat)
    (hNative : PsKernelNativeReductionSoundLaw)
    (hString : PsKernelStringEqSoundLaw)
    (session nextSession : PsKernelCheckerSession)
    (value : PsKernelDefinitionInfo)
    (hConfig :
      PsKernelCheckerConfigurationSound
        session.context session.state)
    (hRun :
      psKernelCheckDefinitionBodyWithSession
          fuel session value =
        Except.ok nextSession) :
    ∃ (inferredType : PsKernelExpr),
      PsKernelTypingJudgment
          session.context.environment session.context.localContext
          value.value inferredType ∧
        PsKernelDefEqJudgment
          session.context.environment session.context.localContext
          inferredType value.base.type ∧
        PsKernelCheckerConfigurationSound
          session.context nextSession.state := by
  cases hFree :
      psKernelCheckNoMVarNoFVar value.value with
  | error error =>
      simp [psKernelCheckDefinitionBodyWithSession, hFree] at hRun
  | ok noFree =>
      cases hLevels :
          psKernelCheckLevelParams
            value.value value.base.levelParams with
      | error error =>
          simp [
            psKernelCheckDefinitionBodyWithSession,
            hFree, hLevels
          ] at hRun
      | ok levelsChecked =>
          cases hCheck :
              psKernelSessionCheck
                fuel session value.value with
          | error error =>
              simp [
                psKernelCheckDefinitionBodyWithSession,
                hFree, hLevels, hCheck
              ] at hRun
          | ok checkedRun =>
              rcases checkedRun with ⟨inferredType, checkedSession⟩
              have hChecked :=
                psKernelSessionCheck_concrete_refines_typing
                  fuel hNative hString
                  session checkedSession
                  value.value inferredType hConfig hCheck
              have hContext :
                  checkedSession.context = session.context :=
                psKernelSessionCheck_success_preserves_context_core
                  fuel session checkedSession
                  value.value inferredType hCheck
              have hCheckedConfig :
                  PsKernelCheckerConfigurationSound
                    checkedSession.context checkedSession.state := by
                simpa [hContext] using hChecked.2
              cases hEq :
                  psKernelSessionIsDefEq
                    fuel checkedSession inferredType value.base.type with
              | error error =>
                  simp [
                    psKernelCheckDefinitionBodyWithSession,
                    hFree, hLevels, hCheck, hEq
                  ] at hRun
              | ok comparedRun =>
                  rcases comparedRun with ⟨isEqual, comparedSession⟩
                  cases isEqual with
                  | false =>
                      simp [
                        psKernelCheckDefinitionBodyWithSession,
                        hFree, hLevels, hCheck, hEq
                      ] at hRun
                  | true =>
                      have hCompared :=
                        psKernelSessionIsDefEq_concrete_refines_defeq
                          fuel hNative hString
                          checkedSession comparedSession
                          inferredType value.base.type
                          hCheckedConfig hEq
                      simp [
                        psKernelCheckDefinitionBodyWithSession,
                        hFree, hLevels, hCheck, hEq
                      ] at hRun
                      rcases hRun with rfl
                      refine ⟨inferredType, hChecked.1, ?_, ?_⟩
                      · simpa [hContext] using hCompared.1
                      · simpa [hContext] using hCompared.2
