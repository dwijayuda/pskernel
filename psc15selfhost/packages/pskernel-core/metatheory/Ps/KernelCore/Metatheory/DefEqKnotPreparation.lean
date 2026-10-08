import Ps.KernelCore.Metatheory.DefEqProjectionShortcutConfiguration
import Ps.KernelCore.Metatheory.ExprEq
import Ps.KernelCore.Metatheory.ContextState

/-
Reusable concrete DefEq knot boundaries.

These small facts are shared by the concrete fuel induction: exhaustion
cannot report success; a successful structural comparison and a successful
cache hit have independently justified DefEq evidence; and publication
of a reduced comparison is justified by explicit reduction closures.

None of these rules introduces general DefEq transitivity.
-/

theorem psKernelDefEqKnot_zero_configuration_sound :
    PsKernelDefEqConfigurationSound
      (psKernelIsDefEqWithFuel 0) := by
  intro context state nextState left right value hConfig hRun
  simp [psKernelIsDefEqWithFuel] at hRun


theorem psKernelDefEqKnot_structural_branch_sound
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (left right : PsKernelExpr)
    (hConfig :
      PsKernelCheckerConfigurationSound context state)
    (hEq : psKernelExprEq left right = true)
    (hRun :
      (Except.ok
          (psKernelDefEqFinish state left right true) :
        Except String (Prod Bool PsKernelCheckerState)) =
      Except.ok (Prod.mk true nextState)) :
    PsKernelCheckerConfigurationSound context nextState ∧
      PsKernelDefEqJudgment
        context.environment context.localContext left right := by
  have hSemantic :=
    psKernelExprEq_true_implies_defeq
      context.environment context.localContext left right hEq
  have hResult :=
    psKernelDefEqFinish_result_sound_ok
      context state nextState left right true true
      hConfig (fun _ => hSemantic) hRun
  exact ⟨hResult.1, hResult.2 rfl⟩


theorem psKernelDefEqKnot_success_cache_sound
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (left right : PsKernelExpr)
    (hConfig :
      PsKernelCheckerConfigurationSound context state)
    (hHit :
      psKernelExprPairSetContains state.success left right = true) :
    PsKernelCheckerConfigurationSound context state ∧
      PsKernelDefEqJudgment
        context.environment context.localContext left right := by
  have hCache :
      PsKernelDefEqCacheSound
        context.environment context.localContext state.success := by
    rcases hConfig.2.2 with
      ⟨_, _, _, _, _, hSuccessCache⟩
    exact hSuccessCache
  exact ⟨hConfig, hCache left right hHit⟩


theorem psKernelDefEqKnot_lift_optional
    (context : PsKernelCheckerContext)
    (nextState : PsKernelCheckerState)
    (originalLeft originalRight left right : PsKernelExpr)
    (answer : Option Bool)
    (hLeft :
      PsKernelReductionClosure
        context.environment context.localContext originalLeft left)
    (hRight :
      PsKernelReductionClosure
        context.environment context.localContext originalRight right)
    (hPost :
      PsKernelOptionalDefEqPostcondition
        context nextState left right answer) :
    PsKernelCheckerConfigurationSound context nextState ∧
      (answer = Option.some true ->
        PsKernelDefEqJudgment
          context.environment context.localContext
          originalLeft originalRight) := by
  refine ⟨hPost.1, ?_⟩
  cases answer with
  | none =>
      intro hImpossible
      cases hImpossible
  | some value =>
      cases value with
      | false =>
          intro hImpossible
          cases hImpossible
      | true =>
          intro _
          exact
            PsKernelDefEqJudgment.reduceCompare
              originalLeft originalRight left right
              hLeft hRight hPost.2


theorem psKernelDefEqKnot_finish_after_reduction
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (originalLeft originalRight left right : PsKernelExpr)
    (inputValue outputValue : Bool)
    (hConfig :
      PsKernelCheckerConfigurationSound context state)
    (hLeft :
      PsKernelReductionClosure
        context.environment context.localContext originalLeft left)
    (hRight :
      PsKernelReductionClosure
        context.environment context.localContext originalRight right)
    (hSemantic :
      inputValue = true ->
        PsKernelDefEqJudgment
          context.environment context.localContext left right)
    (hRun :
      (Except.ok
          (psKernelDefEqFinish
            state originalLeft originalRight inputValue) :
        Except String (Prod Bool PsKernelCheckerState)) =
      Except.ok (Prod.mk outputValue nextState)) :
    PsKernelCheckerConfigurationSound context nextState ∧
      (outputValue = true ->
        PsKernelDefEqJudgment
          context.environment context.localContext
          originalLeft originalRight) := by
  exact
    psKernelDefEqFinish_result_sound_ok
      context state nextState
      originalLeft originalRight inputValue outputValue
      hConfig
      (fun hTrue =>
        PsKernelDefEqJudgment.reduceCompare
          originalLeft originalRight left right
          hLeft hRight (hSemantic hTrue))
      hRun
