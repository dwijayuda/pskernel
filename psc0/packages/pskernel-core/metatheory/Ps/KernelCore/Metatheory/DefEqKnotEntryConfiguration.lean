import Ps.KernelCore.Metatheory.DefEqKnotPreparation

/-
The outer executable checker-knot fuel step splits into three semantically
distinct paths:

  1. structural equality of the original pair;
  2. an independently sound success-cache hit;
  3. the complete comparison pipeline after both fast paths miss.

The third obligation is left as an *explicit theorem parameter*, not an axiom.
This theorem proves that discharging only that obligation suffices to close
the concrete successor-fuel step. The recursive checker proof must still
supply it; neither its implementation nor acceptance requirements are weakened.
-/

def PsKernelDefEqKnotMissConfigurationSound (fuel : Nat) : Prop :=
  ∀ (context nextContext : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (left right : PsKernelExpr)
    (value : Bool),
    PsKernelCheckerConfigurationSound nextContext state ->
    psKernelCheckerContextEnterRecDepth context =
      Except.ok nextContext ->
    psKernelExprEq left right = false ->
    psKernelDefEqSuccessCacheHit state left right = false ->
    psKernelIsDefEqWithFuel
        (Nat.succ fuel) context state left right =
      Except.ok (Prod.mk value nextState) ->
    PsKernelCheckerConfigurationSound nextContext nextState ∧
      (value = true ->
        PsKernelDefEqJudgment
          nextContext.environment nextContext.localContext
          left right)


theorem psKernelIsDefEqWithFuel_succ_configuration_sound_of_miss
    (fuel : Nat)
    (hMiss : PsKernelDefEqKnotMissConfigurationSound fuel) :
    PsKernelDefEqConfigurationSound
      (psKernelIsDefEqWithFuel (Nat.succ fuel)) := by
  intro context state nextState left right value hConfig hRun
  cases hEnter :
      psKernelCheckerContextEnterRecDepth context with
  | error error =>
      simp [
        psKernelIsDefEqWithFuel,
        hEnter
      ] at hRun
  | ok nextContext =>
      by_cases hSame : psKernelExprEq left right = true
      · have hFinish :
            (Except.ok
                (psKernelDefEqFinish state left right true) :
              Except String (Prod Bool PsKernelCheckerState)) =
            Except.ok (Prod.mk value nextState) := by
          simpa [
            psKernelIsDefEqWithFuel,
            hEnter,
            hSame
          ] using hRun
        have hSemantic :=
          psKernelExprEq_true_implies_defeq
            context.environment context.localContext
            left right hSame
        exact
          psKernelDefEqFinish_result_sound_ok
            context state nextState
            left right true value hConfig
            (fun _ => hSemantic) hFinish
      · have hDifferent :
            psKernelExprEq left right = false := by
          cases hBool : psKernelExprEq left right with
          | false => rfl
          | true => exact False.elim (hSame hBool)
        by_cases hCached :
            psKernelDefEqSuccessCacheHit state left right = true
        · have hCachedRun :
              (Except.ok (Prod.mk true state) :
                Except String (Prod Bool PsKernelCheckerState)) =
              Except.ok (Prod.mk value nextState) := by
            simpa [
              psKernelIsDefEqWithFuel,
              hEnter, hDifferent, hCached
            ] using hRun
          simp at hCachedRun
          rcases hCachedRun with ⟨rfl, rfl⟩
          have hCacheSound :=
            psKernelDefEqKnot_success_cache_sound
              context state left right hConfig hCached
          exact ⟨hCacheSound.1, fun _ => hCacheSound.2⟩
        · have hUncached :
              psKernelDefEqSuccessCacheHit state left right = false := by
            cases hBool :
                psKernelDefEqSuccessCacheHit state left right with
            | false => rfl
            | true => exact False.elim (hCached hBool)
          have hNextConfig :=
            psKernelCheckerContextEnterRecDepth_preserves_configuration
              context nextContext state hConfig hEnter
          have hRemaining :=
            hMiss
              context nextContext state nextState
              left right value
              hNextConfig hEnter hDifferent hUncached hRun
          exact
            ⟨
              psKernelCheckerConfigurationSound_enterRecDepth_back
                context nextContext nextState hEnter
                hRemaining.1,
              fun hValue =>
                psKernelDefEqJudgment_enterRecDepth_back
                  context nextContext left right hEnter
                  (hRemaining.2 hValue)
            ⟩
