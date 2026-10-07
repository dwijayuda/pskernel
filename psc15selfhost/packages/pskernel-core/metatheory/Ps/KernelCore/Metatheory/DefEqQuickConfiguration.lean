import Ps.KernelCore.Checker.DefEq.Quick
import Ps.KernelCore.Metatheory.DefEqBinderConfiguration
import Ps.KernelCore.Metatheory.ExprEq

/-
Configuration-aware refinement for Lean-style quick definitional equality.

The helper may decide true/false or return undecided.  Only a positive decision
carries DefEq evidence; every successful branch preserves the checker
configuration.
-/

theorem psKernelDefEqQuick_configuration_sound
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String (Prod Bool PsKernelCheckerState))
    (hDefEq : PsKernelDefEqConfigurationSound defeq)
    (hString : PsKernelStringEqSoundLaw) :
    PsKernelOptionalDefEqConfigurationSound
      (psKernelDefEqQuick defeq) := by
  intro
    context state nextState left right answer
    hConfig hSuccess
  have hSuccessCache :
      PsKernelDefEqCacheSound
        context.environment
        context.localContext
        state.success := by
    rcases hConfig.2.2 with
      ⟨_, _, _, _, _, hCache⟩
    exact hCache
  cases hEq : psKernelExprEq left right with
  | true =>
      simp [
        psKernelDefEqQuick,
        hEq
      ] at hSuccess
      rcases hSuccess with ⟨rfl, rfl⟩
      exact
        ⟨
          hConfig,
          psKernelExprEq_true_implies_defeq
            context.environment
            context.localContext
            left
            right
            hEq
        ⟩
  | false =>
      cases hFast :
          (if
              psKernelSemanticPairCacheEligible
                left
                right then
            psKernelExprPairSetContains
              state.success
              left
              right
          else
            false) with
      | true =>
          have hEligible :
              psKernelSemanticPairCacheEligible
                  left
                  right =
                true := by
            cases h :
                psKernelSemanticPairCacheEligible
                  left
                  right with
            | false =>
                simp [h] at hFast
            | true =>
                rfl
          have hCache :
              psKernelExprPairSetContains
                  state.success
                  left
                  right =
                true := by
            simpa [hEligible] using hFast
          simp [
            psKernelDefEqQuick,
            hEq,
            hEligible,
            hCache
          ] at hSuccess
          rcases hSuccess with ⟨rfl, rfl⟩
          exact
            ⟨
              hConfig,
              hSuccessCache left right hCache
            ⟩
      | false =>
          cases left with
          | lam leftName leftDomain leftBody leftInfo =>
              cases right with
              | lam rightName rightDomain rightBody rightInfo =>
                  cases hRun :
                      psKernelDefEqLambdaSpine
                        defeq
                        context
                        state
                        (PsKernelExpr.lam
                          leftName leftDomain leftBody leftInfo)
                        (PsKernelExpr.lam
                          rightName rightDomain rightBody rightInfo) with
                  | error error =>
                      simp [
                        psKernelDefEqQuick,
                        hEq,
                        hFast,
                        hRun
                      ] at hSuccess
                  | ok run =>
                      rcases run with ⟨value, runState⟩
                      have hSemantic :=
                        psKernelDefEqLambdaSpine_configuration_sound
                          defeq hDefEq hString
                          context state runState
                          (PsKernelExpr.lam
                            leftName leftDomain leftBody leftInfo)
                          (PsKernelExpr.lam
                            rightName rightDomain rightBody rightInfo)
                          value
                          hConfig
                          hRun
                      simp [
                        psKernelDefEqQuick,
                        hEq,
                        hFast,
                        hRun
                      ] at hSuccess
                      rcases hSuccess with ⟨rfl, rfl⟩
                      cases value with
                      | false =>
                          exact ⟨hSemantic.1, trivial⟩
                      | true =>
                          exact ⟨hSemantic.1, hSemantic.2 rfl⟩
              | bvar index =>
                  simp [psKernelDefEqQuick, hEq, hFast] at hSuccess
                  rcases hSuccess with ⟨rfl, rfl⟩
                  exact ⟨hConfig, trivial⟩
              | fvar name =>
                  simp [psKernelDefEqQuick, hEq, hFast] at hSuccess
                  rcases hSuccess with ⟨rfl, rfl⟩
                  exact ⟨hConfig, trivial⟩
              | mvar name =>
                  simp [psKernelDefEqQuick, hEq, hFast] at hSuccess
                  rcases hSuccess with ⟨rfl, rfl⟩
                  exact ⟨hConfig, trivial⟩
              | sort level =>
                  simp [psKernelDefEqQuick, hEq, hFast] at hSuccess
                  rcases hSuccess with ⟨rfl, rfl⟩
                  exact ⟨hConfig, trivial⟩
              | const name levels =>
                  simp [psKernelDefEqQuick, hEq, hFast] at hSuccess
                  rcases hSuccess with ⟨rfl, rfl⟩
                  exact ⟨hConfig, trivial⟩
              | app fn arg =>
                  simp [psKernelDefEqQuick, hEq, hFast] at hSuccess
                  rcases hSuccess with ⟨rfl, rfl⟩
                  exact ⟨hConfig, trivial⟩
              | forallE name type body info =>
                  simp [psKernelDefEqQuick, hEq, hFast] at hSuccess
                  rcases hSuccess with ⟨rfl, rfl⟩
                  exact ⟨hConfig, trivial⟩
              | letE name type value body nondep =>
                  simp [psKernelDefEqQuick, hEq, hFast] at hSuccess
                  rcases hSuccess with ⟨rfl, rfl⟩
                  exact ⟨hConfig, trivial⟩
              | lit literal =>
                  simp [psKernelDefEqQuick, hEq, hFast] at hSuccess
                  rcases hSuccess with ⟨rfl, rfl⟩
                  exact ⟨hConfig, trivial⟩
              | mdata metadata body =>
                  simp [psKernelDefEqQuick, hEq, hFast] at hSuccess
                  rcases hSuccess with ⟨rfl, rfl⟩
                  exact ⟨hConfig, trivial⟩
              | proj typeName index body =>
                  simp [psKernelDefEqQuick, hEq, hFast] at hSuccess
                  rcases hSuccess with ⟨rfl, rfl⟩
                  exact ⟨hConfig, trivial⟩
          | forallE leftName leftDomain leftBody leftInfo =>
              cases right with
              | forallE rightName rightDomain rightBody rightInfo =>
                  cases hRun :
                      psKernelDefEqForallSpine
                        defeq
                        context
                        state
                        (PsKernelExpr.forallE
                          leftName leftDomain leftBody leftInfo)
                        (PsKernelExpr.forallE
                          rightName rightDomain rightBody rightInfo) with
                  | error error =>
                      simp [
                        psKernelDefEqQuick,
                        hEq,
                        hFast,
                        hRun
                      ] at hSuccess
                  | ok run =>
                      rcases run with ⟨value, runState⟩
                      have hSemantic :=
                        psKernelDefEqForallSpine_configuration_sound
                          defeq hDefEq hString
                          context state runState
                          (PsKernelExpr.forallE
                            leftName leftDomain leftBody leftInfo)
                          (PsKernelExpr.forallE
                            rightName rightDomain rightBody rightInfo)
                          value
                          hConfig
                          hRun
                      simp [
                        psKernelDefEqQuick,
                        hEq,
                        hFast,
                        hRun
                      ] at hSuccess
                      rcases hSuccess with ⟨rfl, rfl⟩
                      cases value with
                      | false =>
                          exact ⟨hSemantic.1, trivial⟩
                      | true =>
                          exact ⟨hSemantic.1, hSemantic.2 rfl⟩
              | bvar index =>
                  simp [psKernelDefEqQuick, hEq, hFast] at hSuccess
                  rcases hSuccess with ⟨rfl, rfl⟩
                  exact ⟨hConfig, trivial⟩
              | fvar name =>
                  simp [psKernelDefEqQuick, hEq, hFast] at hSuccess
                  rcases hSuccess with ⟨rfl, rfl⟩
                  exact ⟨hConfig, trivial⟩
              | mvar name =>
                  simp [psKernelDefEqQuick, hEq, hFast] at hSuccess
                  rcases hSuccess with ⟨rfl, rfl⟩
                  exact ⟨hConfig, trivial⟩
              | sort level =>
                  simp [psKernelDefEqQuick, hEq, hFast] at hSuccess
                  rcases hSuccess with ⟨rfl, rfl⟩
                  exact ⟨hConfig, trivial⟩
              | const name levels =>
                  simp [psKernelDefEqQuick, hEq, hFast] at hSuccess
                  rcases hSuccess with ⟨rfl, rfl⟩
                  exact ⟨hConfig, trivial⟩
              | app fn arg =>
                  simp [psKernelDefEqQuick, hEq, hFast] at hSuccess
                  rcases hSuccess with ⟨rfl, rfl⟩
                  exact ⟨hConfig, trivial⟩
              | lam name type body info =>
                  simp [psKernelDefEqQuick, hEq, hFast] at hSuccess
                  rcases hSuccess with ⟨rfl, rfl⟩
                  exact ⟨hConfig, trivial⟩
              | letE name type value body nondep =>
                  simp [psKernelDefEqQuick, hEq, hFast] at hSuccess
                  rcases hSuccess with ⟨rfl, rfl⟩
                  exact ⟨hConfig, trivial⟩
              | lit literal =>
                  simp [psKernelDefEqQuick, hEq, hFast] at hSuccess
                  rcases hSuccess with ⟨rfl, rfl⟩
                  exact ⟨hConfig, trivial⟩
              | mdata metadata body =>
                  simp [psKernelDefEqQuick, hEq, hFast] at hSuccess
                  rcases hSuccess with ⟨rfl, rfl⟩
                  exact ⟨hConfig, trivial⟩
              | proj typeName index body =>
                  simp [psKernelDefEqQuick, hEq, hFast] at hSuccess
                  rcases hSuccess with ⟨rfl, rfl⟩
                  exact ⟨hConfig, trivial⟩
          | sort leftLevel =>
              cases right with
              | sort rightLevel =>
                  cases hLevel :
                      psKernelLevelEquivalent leftLevel rightLevel with
                  | false =>
                      simp [
                        psKernelDefEqQuick,
                        hEq,
                        hFast,
                        hLevel
                      ] at hSuccess
                      rcases hSuccess with ⟨rfl, rfl⟩
                      exact ⟨hConfig, trivial⟩
                  | true =>
                      simp [
                        psKernelDefEqQuick,
                        hEq,
                        hFast,
                        hLevel
                      ] at hSuccess
                      rcases hSuccess with ⟨rfl, rfl⟩
                      exact
                        ⟨
                          hConfig,
                          PsKernelDefEqJudgment.sort
                            leftLevel rightLevel hLevel
                        ⟩
              | _ =>
                  simp [psKernelDefEqQuick, hEq, hFast] at hSuccess
                  rcases hSuccess with ⟨rfl, rfl⟩
                  exact ⟨hConfig, trivial⟩
          | mdata leftMetadata leftBody =>
              cases right with
              | mdata rightMetadata rightBody =>
                  cases hRun :
                      defeq context state leftBody rightBody with
                  | error error =>
                      simp [
                        psKernelDefEqQuick,
                        hEq,
                        hFast,
                        hRun
                      ] at hSuccess
                  | ok run =>
                      rcases run with ⟨value, runState⟩
                      have hSemantic :=
                        hDefEq
                          context state runState
                          leftBody rightBody value
                          hConfig hRun
                      simp [
                        psKernelDefEqQuick,
                        hEq,
                        hFast,
                        hRun
                      ] at hSuccess
                      rcases hSuccess with ⟨rfl, rfl⟩
                      cases value with
                      | false =>
                          exact ⟨hSemantic.1, trivial⟩
                      | true =>
                          exact
                            ⟨
                              hSemantic.1,
                              PsKernelDefEqJudgment.metadataLeft
                                leftMetadata
                                leftBody
                                (PsKernelExpr.mdata
                                  rightMetadata
                                  rightBody)
                                (PsKernelDefEqJudgment.metadataRight
                                  rightMetadata
                                  leftBody
                                  rightBody
                                  (hSemantic.2 rfl))
                            ⟩
              | _ =>
                  simp [psKernelDefEqQuick, hEq, hFast] at hSuccess
                  rcases hSuccess with ⟨rfl, rfl⟩
                  exact ⟨hConfig, trivial⟩
          | lit leftLiteral =>
              cases right with
              | lit rightLiteral =>
                  cases hLiteral :
                      psKernelLiteralEq leftLiteral rightLiteral with
                  | false =>
                      simp [
                        psKernelDefEqQuick,
                        hEq,
                        hFast,
                        hLiteral
                      ] at hSuccess
                      rcases hSuccess with ⟨rfl, rfl⟩
                      exact ⟨hConfig, trivial⟩
                  | true =>
                      simp [
                        psKernelDefEqQuick,
                        hEq,
                        hFast,
                        hLiteral
                      ] at hSuccess
                      rcases hSuccess with ⟨rfl, rfl⟩
                      exact
                        ⟨
                          hConfig,
                          PsKernelDefEqJudgment.literal
                            leftLiteral rightLiteral hLiteral
                        ⟩
              | _ =>
                  simp [psKernelDefEqQuick, hEq, hFast] at hSuccess
                  rcases hSuccess with ⟨rfl, rfl⟩
                  exact ⟨hConfig, trivial⟩
          | bvar index =>
              simp [psKernelDefEqQuick, hEq, hFast] at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              exact ⟨hConfig, trivial⟩
          | fvar name =>
              simp [psKernelDefEqQuick, hEq, hFast] at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              exact ⟨hConfig, trivial⟩
          | mvar name =>
              simp [psKernelDefEqQuick, hEq, hFast] at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              exact ⟨hConfig, trivial⟩
          | const name levels =>
              simp [psKernelDefEqQuick, hEq, hFast] at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              exact ⟨hConfig, trivial⟩
          | app fn arg =>
              simp [psKernelDefEqQuick, hEq, hFast] at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              exact ⟨hConfig, trivial⟩
          | letE name type value body nondep =>
              simp [psKernelDefEqQuick, hEq, hFast] at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              exact ⟨hConfig, trivial⟩
          | proj typeName index body =>
              simp [psKernelDefEqQuick, hEq, hFast] at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              exact ⟨hConfig, trivial⟩

