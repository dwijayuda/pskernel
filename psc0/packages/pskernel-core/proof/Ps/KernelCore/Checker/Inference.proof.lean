import Ps.KernelCore.Checker.Inference
import Ps.KernelCore.Metatheory.Judgments
import Ps.KernelCore.Metatheory.CheckedInferenceConfiguration

theorem psKernelInferWithFuel_is_inferOnly_core
    (fuel : Nat)
    (whnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String (Prod Bool PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (expr : PsKernelExpr) :
    psKernelInferWithFuel fuel whnf defeq context state expr =
      psKernelInferCoreWithFuel
        fuel whnf defeq context state expr true := by
  rfl

theorem psKernelCheckWithFuel_is_checked_core
    (fuel : Nat)
    (whnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String (Prod Bool PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (expr : PsKernelExpr) :
    psKernelCheckWithFuel fuel whnf defeq context state expr =
      psKernelInferCoreWithFuel
        fuel whnf defeq context state expr false := by
  rfl

theorem psKernelInferWithFuel_zero
    (whnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String (Prod Bool PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (expr : PsKernelExpr) :
    psKernelInferWithFuel 0 whnf defeq context state expr =
      Except.error "kernel inference budget exhausted" := by
  rfl

theorem psKernelCheckWithFuel_zero
    (whnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String (Prod Bool PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (expr : PsKernelExpr) :
    psKernelCheckWithFuel 0 whnf defeq context state expr =
      Except.error "kernel inference budget exhausted" := by
  rfl


theorem psKernelInferWithFuel_refines_typing
    (fuel : Nat)
    (whnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String (Prod Bool PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (expr result : PsKernelExpr)
    (hSound : PsKernelInferenceCoreSound whnf defeq)
    (hSuccess :
      psKernelInferWithFuel
          fuel whnf defeq context state expr =
        Except.ok (Prod.mk result nextState)) :
    PsKernelTypingJudgment
      context.environment
      context.localContext
      expr
      result := by
  exact
    hSound
      fuel
      context
      state
      nextState
      expr
      result
      true
      hSuccess

theorem psKernelCheckWithFuel_refines_typing
    (fuel : Nat)
    (whnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String (Prod Bool PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (expr result : PsKernelExpr)
    (hSound : PsKernelInferenceCoreSound whnf defeq)
    (hSuccess :
      psKernelCheckWithFuel
          fuel whnf defeq context state expr =
        Except.ok (Prod.mk result nextState)) :
    PsKernelTypingJudgment
      context.environment
      context.localContext
      expr
      result := by
  exact
    hSound
      fuel
      context
      state
      nextState
      expr
      result
      false
      hSuccess


theorem psKernelCheckWithFuel_configuration_sound_contract
    (fuel : Nat)
    (whnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String (Prod Bool PsKernelCheckerState))
    (hString : PsKernelStringEqSoundLaw)
    (hWhnf : PsKernelWhnfConfigurationSound whnf)
    (hDefEq : PsKernelDefEqConfigurationSound defeq) :
    PsKernelCheckedInferenceConfigurationSound
      (fun context state expr =>
        psKernelCheckWithFuel
          fuel
          whnf
          defeq
          context
          state
          expr) := by
  have hCore :=
    psKernelCheckedInferenceCoreConfigurationSound_contract
      whnf
      defeq
      hString
      hWhnf
      hDefEq
  intro context state nextState expr result hConfig hSuccess
  exact
    hCore
      fuel
      context
      state
      nextState
      expr
      result
      hConfig
      hSuccess
