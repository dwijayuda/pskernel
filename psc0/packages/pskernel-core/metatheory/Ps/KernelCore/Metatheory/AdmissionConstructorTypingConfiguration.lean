import Ps.KernelCore.Metatheory.AdmissionInductiveHeaderConfiguration
import Ps.KernelCore.Admission.Inductive.Ordinary.ConstructorAdmission

/-
Checked constructor-header refinement for the ordinary inductive transaction.

The constructor worker first closes/validates the constructor declaration and
uses a NEW checked session in the current work environment.  Successful
constructor admission must therefore carry independent typing of the
constructor type in that exact work environment and a Sort reduction of its
inferred type, not an infer-only certificate.

This is intentionally a prefix theorem: subsequent field positivity, result
indices, and installation have distinct obligations.  Native reduction and
string-equality laws are preserved as named conditional trust premises.
-/
theorem psKernelAddSimpleConstructorsWithFuel_success_head_checked
    (fuel : Nat)
    (decl : PsKernelSimpleInductiveDecl)
    (safety : PsKernelDefinitionSafety)
    (resultLevel : PsKernelLevel)
    (levels : List PsKernelLevel)
    (params : List PsKernelOpenBinder)
    (numIndices : Nat)
    (headerSession : PsKernelCheckerSession)
    (work : PsKernelEnvironment)
    (index : Nat)
    (ctor : PsKernelSimpleConstructorDecl)
    (rest : List PsKernelSimpleConstructorDecl)
    (result : PsKernelAddConstructorsResult)
    (hIndex : PsKernelEnvironmentIndexRefines work)
    (hNative : PsKernelNativeReductionSoundLaw)
    (hString : PsKernelStringEqSoundLaw)
    (hRun :
      psKernelAddSimpleConstructorsWithFuel
          (Nat.succ fuel) decl safety resultLevel levels
          params numIndices headerSession work index
          (List.cons ctor rest) =
        Except.ok result) :
    ∃ (inferredType : PsKernelExpr) (level : PsKernelLevel),
      PsKernelTypingJudgment
          work psKernelLocalContextEmpty
          ctor.type inferredType ∧
        PsKernelReductionClosure
          work psKernelLocalContextEmpty
          inferredType (PsKernelExpr.sort level) := by
  simp only [psKernelAddSimpleConstructorsWithFuel] at hRun
  cases hClosed :
      psKernelCheckNoMVarNoFVar ctor.type with
  | error message =>
      simp only [hClosed] at hRun
      cases hRun
  | ok closed =>
      simp only [hClosed] at hRun
      cases hLevels :
          psKernelCheckLevelParams
            ctor.type decl.levelParams with
      | error message =>
          simp only [hLevels] at hRun
          cases hRun
      | ok checkedLevels =>
          simp only [hLevels] at hRun
          let closedSession :=
            psKernelMkCheckerSession
              work decl.levelParams safety
              headerSession.context.maxRecDepth
              headerSession.context.maxNatSize
          cases hChecked :
              psKernelSessionCheck
                fuel closedSession ctor.type with
          | error message =>
              simp only [closedSession, hChecked] at hRun
              cases hRun
          | ok checked =>
              rcases checked with ⟨inferredType, checkedSession⟩
              simp only [closedSession, hChecked] at hRun
              cases hSort :
                  psKernelSessionEnsureSort
                    fuel checkedSession inferredType with
              | error message =>
                  simp only [hSort] at hRun
                  cases hRun
              | ok sorted =>
                  rcases sorted with ⟨level, sortedSession⟩
                  have hInitial :
                      PsKernelCheckerConfigurationSound
                        closedSession.context closedSession.state := by
                    exact
                      psKernelMkCheckerSession_configuration_sound
                        work decl.levelParams safety
                        headerSession.context.maxRecDepth
                        headerSession.context.maxNatSize hIndex
                  have hRefines :=
                    psKernelCheckedHeaderSort_configuration_refines
                      fuel hNative hString
                      closedSession checkedSession sortedSession
                      ctor.type inferredType level
                      hInitial hChecked hSort
                  refine ⟨inferredType, level, ?_, ?_⟩
                  · simpa [
                      closedSession, psKernelMkCheckerSession,
                      psKernelCheckerContextEmpty
                    ] using hRefines.1
                  · simpa [
                      closedSession, psKernelMkCheckerSession,
                      psKernelCheckerContextEmpty
                    ] using hRefines.2.1
