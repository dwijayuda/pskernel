import Ps.KernelCore.Checker.DefEq.BinderSpines
import Ps.KernelCore.Metatheory.ContextState
import Ps.KernelCore.Metatheory.CheckerContracts

/-
Reusable configuration infrastructure for DefEq binder spines.

The executable lambda/forall spine workers may open a fresh local scope while
comparing dependent bodies.  These lemmas expose the parent/child
configuration facts independently of the recursive spine proof.
-/

theorem psKernelDefEqWithLocal_parent_configuration
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (userName : PsKernelName)
    (type : PsKernelExpr)
    (binderInfo : PsKernelBinderInfo)
    (hConfig :
      PsKernelCheckerConfigurationSound context state) :
    let opened :=
      psKernelDefEqWithLocal
        context state userName type binderInfo
    PsKernelCheckerConfigurationSound
      context
      (Prod.snd (Prod.snd opened)) := by
  intro opened
  simpa [
    opened,
    psKernelDefEqWithLocal
  ] using
    psKernelCheckerStateFreshName_preserves_configuration
      context
      state
      userName
      hConfig


theorem psKernelDefEqWithLocal_child_configuration
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (userName : PsKernelName)
    (type : PsKernelExpr)
    (binderInfo : PsKernelBinderInfo)
    (hString : PsKernelStringEqSoundLaw)
    (hConfig :
      PsKernelCheckerConfigurationSound context state) :
    let opened :=
      psKernelDefEqWithLocal
        context state userName type binderInfo
    PsKernelCheckerConfigurationSound
      (Prod.fst (Prod.snd opened))
      (Prod.snd (Prod.snd opened)) := by
  intro opened
  simpa [
    opened,
    psKernelDefEqWithLocal
  ] using
    psKernelCheckerFreshLocal_preserves_configuration
      context
      state
      userName
      type
      binderInfo
      hString
      hConfig


theorem psKernelDefEqWithLocal_fresh_absent
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (userName : PsKernelName)
    (type : PsKernelExpr)
    (binderInfo : PsKernelBinderInfo)
    (hString : PsKernelStringEqSoundLaw)
    (hConfig :
      PsKernelCheckerConfigurationSound context state) :
    let opened :=
      psKernelDefEqWithLocal
        context state userName type binderInfo
    psKernelLocalContextFind
        context.localContext
        (Prod.fst opened) =
      Option.none := by
  intro opened
  have hFresh :
      psKernelCheckerStateFreshName state userName =
        Prod.mk
          (Prod.fst opened)
          (Prod.snd (Prod.snd opened)) := by
    simpa [
      opened,
      psKernelDefEqWithLocal
    ]
  exact
    psKernelCheckerStateFreshName_absent_of_configuration
      context
      state
      (Prod.snd (Prod.snd opened))
      userName
      (Prod.fst opened)
      hString
      hConfig
      hFresh


def PsKernelLambdaSpineConfigurationSound
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String (Prod Bool PsKernelCheckerState)) : Prop :=
  ∀
    (fuel : Nat)
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (left right : PsKernelExpr)
    (subst : List PsKernelExpr)
    (value : Bool),
    PsKernelCheckerConfigurationSound context state ->
    psKernelDefEqLambdaSpineWithFuel
        fuel defeq context state left right subst =
      Except.ok (Prod.mk value nextState) ->
    PsKernelCheckerConfigurationSound context nextState ∧
      (value = true ->
        PsKernelLambdaSpineJudgment
          context.environment
          context.localContext
          left
          right
          subst)


def PsKernelForallSpineConfigurationSound
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String (Prod Bool PsKernelCheckerState)) : Prop :=
  ∀
    (fuel : Nat)
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (left right : PsKernelExpr)
    (subst : List PsKernelExpr)
    (value : Bool),
    PsKernelCheckerConfigurationSound context state ->
    psKernelDefEqForallSpineWithFuel
        fuel defeq context state left right subst =
      Except.ok (Prod.mk value nextState) ->
    PsKernelCheckerConfigurationSound context nextState ∧
      (value = true ->
        PsKernelForallSpineJudgment
          context.environment
          context.localContext
          left
          right
          subst)
