import Ps.KernelCore.Checker.Knot
import Ps.KernelCore.Metatheory.Judgments

theorem psKernelIsDefEqWithFuel_zero
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (left right : PsKernelExpr) :
    psKernelIsDefEqWithFuel 0 context state left right =
      Except.error
        "kernel definitional equality budget exhausted" := by
  rfl

theorem psKernelIsDefEq_def
    (fuel : Nat)
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (left right : PsKernelExpr) :
    psKernelIsDefEq fuel context state left right =
      psKernelIsDefEqWithFuel fuel context state left right := by
  rfl

theorem psKernelCheckerInfer_def
    (fuel : Nat)
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (expr : PsKernelExpr) :
    psKernelCheckerInfer fuel context state expr =
      psKernelInferWithRecursorFuel
        fuel
        (psKernelIsDefEqWithFuel fuel)
        context
        state
        expr := by
  rfl

theorem psKernelCheckerWhnf_def
    (fuel : Nat)
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (expr : PsKernelExpr) :
    psKernelCheckerWhnf fuel context state expr =
      psKernelWhnfWithRecursorFuel
        fuel
        (psKernelIsDefEqWithFuel fuel)
        context
        state
        expr := by
  rfl


theorem psKernelCheckerInfer_refines_typing
    (fuel : Nat)
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (expr result : PsKernelExpr)
    (hCore :
      PsKernelInferenceCoreSound
        (psKernelWhnfWithRecursorFuel
          fuel
          (psKernelIsDefEqWithFuel fuel))
        (psKernelIsDefEqWithFuel fuel))
    (hSuccess :
      psKernelCheckerInfer
          fuel context state expr =
        Except.ok (Prod.mk result nextState)) :
    PsKernelTypingJudgment
      context.environment
      context.localContext
      expr
      result := by
  unfold psKernelCheckerInfer at hSuccess
  unfold psKernelInferWithRecursorFuel at hSuccess
  unfold psKernelInferWithFuel at hSuccess
  exact
    hCore
      fuel
      context
      state
      nextState
      expr
      result
      true
      hSuccess

theorem psKernelCheckerCheck_refines_typing
    (fuel : Nat)
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (expr result : PsKernelExpr)
    (hCore :
      PsKernelInferenceCoreSound
        (psKernelWhnfWithRecursorFuel
          fuel
          (psKernelIsDefEqWithFuel fuel))
        (psKernelIsDefEqWithFuel fuel))
    (hSuccess :
      psKernelCheckerCheck
          fuel context state expr =
        Except.ok (Prod.mk result nextState)) :
    PsKernelTypingJudgment
      context.environment
      context.localContext
      expr
      result := by
  unfold psKernelCheckerCheck at hSuccess
  unfold psKernelCheckWithFuel at hSuccess
  exact
    hCore
      fuel
      context
      state
      nextState
      expr
      result
      false
      hSuccess

theorem psKernelCheckerWhnf_refines_reduction
    (fuel : Nat)
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (expr result : PsKernelExpr)
    (hWhnf :
      PsKernelWhnfSound
        (psKernelWhnfWithRecursorFuel
          fuel
          (psKernelIsDefEqWithFuel fuel)))
    (hSuccess :
      psKernelCheckerWhnf
          fuel context state expr =
        Except.ok (Prod.mk result nextState)) :
    PsKernelReductionClosure
      context.environment
      context.localContext
      expr
      result := by
  unfold psKernelCheckerWhnf at hSuccess
  exact
    hWhnf
      context
      state
      nextState
      expr
      result
      hSuccess

theorem psKernelIsDefEq_refines_defeq
    (fuel : Nat)
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (left right : PsKernelExpr)
    (hDefEq :
      PsKernelDefEqSound
        (psKernelIsDefEqWithFuel fuel))
    (hSuccess :
      psKernelIsDefEq
          fuel context state left right =
        Except.ok (Prod.mk true nextState)) :
    PsKernelDefEqJudgment
      context.environment
      context.localContext
      left
      right := by
  unfold psKernelIsDefEq at hSuccess
  exact
    hDefEq
      context
      state
      nextState
      left
      right
      hSuccess


theorem psKernelCheckerInfer_semantic_sound
    (fuel : Nat)
    (hCore :
      PsKernelInferenceCoreSound
        (psKernelWhnfWithRecursorFuel
          fuel
          (psKernelIsDefEqWithFuel fuel))
        (psKernelIsDefEqWithFuel fuel)) :
    PsKernelInferenceSound
      (psKernelCheckerInfer fuel) := by
  intro context state nextState expr result hSuccess
  exact
    psKernelCheckerInfer_refines_typing
      fuel context state nextState expr result
      hCore hSuccess

theorem psKernelCheckerCheck_semantic_sound
    (fuel : Nat)
    (hCore :
      PsKernelInferenceCoreSound
        (psKernelWhnfWithRecursorFuel
          fuel
          (psKernelIsDefEqWithFuel fuel))
        (psKernelIsDefEqWithFuel fuel)) :
    PsKernelInferenceSound
      (psKernelCheckerCheck fuel) := by
  intro context state nextState expr result hSuccess
  exact
    psKernelCheckerCheck_refines_typing
      fuel context state nextState expr result
      hCore hSuccess

theorem psKernelCheckerWhnf_semantic_sound
    (fuel : Nat)
    (hWhnf :
      PsKernelWhnfSound
        (psKernelWhnfWithRecursorFuel
          fuel
          (psKernelIsDefEqWithFuel fuel))) :
    PsKernelWhnfSound
      (psKernelCheckerWhnf fuel) := by
  intro context state nextState expr result hSuccess
  exact
    psKernelCheckerWhnf_refines_reduction
      fuel context state nextState expr result
      hWhnf hSuccess
