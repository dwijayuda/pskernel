import Ps.KernelCore.Checker.DefEq.BinderSpines
import Ps.KernelCore.Metatheory.CheckerContracts

/-
Configuration-aware refinement for application congruence.

The executable checker flattens applications, compares the heads once, and
then compares argument lists pairwise.  The Assurance Plane mirrors that
structure without adding general DefEq transitivity.
-/

def psKernelSemanticApplyArgs
    (fn : PsKernelExpr) :
    List PsKernelExpr -> PsKernelExpr
  | List.nil =>
      fn
  | List.cons arg rest =>
      psKernelSemanticApplyArgs
        (PsKernelExpr.app fn arg)
        rest


inductive PsKernelExprListDefEq
    (environment : PsKernelEnvironment)
    (localContext : PsKernelLocalContext) :
    List PsKernelExpr ->
    List PsKernelExpr ->
    Prop
  | nil :
      PsKernelExprListDefEq
        environment
        localContext
        List.nil
        List.nil
  | cons
      (left right : PsKernelExpr)
      (leftRest rightRest : List PsKernelExpr)
      (hHead :
        PsKernelDefEqJudgment
          environment
          localContext
          left
          right)
      (hRest :
        PsKernelExprListDefEq
          environment
          localContext
          leftRest
          rightRest) :
      PsKernelExprListDefEq
        environment
        localContext
        (List.cons left leftRest)
        (List.cons right rightRest)


theorem psKernelSemanticApplyArgs_getAppArgsWorker
    (expr : PsKernelExpr)
    (suffix : List PsKernelExpr) :
    psKernelSemanticApplyArgs
        (psKernelExprGetAppFn expr)
        (psKernelExprGetAppArgsWorker expr suffix) =
      psKernelSemanticApplyArgs expr suffix := by
  induction expr generalizing suffix with
  | app fn arg ihFn ihArg =>
      simpa [
        psKernelExprGetAppFn,
        psKernelExprGetAppArgsWorker,
        psKernelSemanticApplyArgs
      ] using ihFn (List.cons arg suffix)
  | bvar index =>
      rfl
  | fvar name =>
      rfl
  | mvar name =>
      rfl
  | sort level =>
      rfl
  | const name levels =>
      rfl
  | lam name type body binderInfo ihType ihBody =>
      rfl
  | forallE name type body binderInfo ihType ihBody =>
      rfl
  | letE name type value body nondep ihType ihValue ihBody =>
      rfl
  | lit literal =>
      rfl
  | mdata metadata body ihBody =>
      rfl
  | proj typeName index body ihBody =>
      rfl


theorem psKernelSemanticApplyArgs_getApp_reconstruct
    (expr : PsKernelExpr) :
    psKernelSemanticApplyArgs
        (psKernelExprGetAppFn expr)
        (psKernelExprGetAppArgs expr) =
      expr := by
  simpa [
    psKernelExprGetAppArgs,
    psKernelSemanticApplyArgs
  ] using
    psKernelSemanticApplyArgs_getAppArgsWorker
      expr
      List.nil


theorem psKernelSemanticApplyArgs_defeq
    (environment : PsKernelEnvironment)
    (localContext : PsKernelLocalContext)
    (leftFn rightFn : PsKernelExpr)
    (leftArgs rightArgs : List PsKernelExpr)
    (hHead :
      PsKernelDefEqJudgment
        environment
        localContext
        leftFn
        rightFn)
    (hArgs :
      PsKernelExprListDefEq
        environment
        localContext
        leftArgs
        rightArgs) :
    PsKernelDefEqJudgment
      environment
      localContext
      (psKernelSemanticApplyArgs leftFn leftArgs)
      (psKernelSemanticApplyArgs rightFn rightArgs) := by
  induction hArgs generalizing leftFn rightFn with
  | nil =>
      simpa [psKernelSemanticApplyArgs] using hHead
  | cons left right leftRest rightRest hArg hRest ih =>
      apply ih
      exact
        PsKernelDefEqJudgment.app
          leftFn
          left
          rightFn
          right
          hHead
          hArg


def PsKernelExprListDefEqConfigurationSound
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
    (left right : List PsKernelExpr)
    (value : Bool),
    PsKernelCheckerConfigurationSound context state ->
    psKernelDefEqCompareExprListsWithFuel
        fuel
        defeq
        context
        state
        left
        right =
      Except.ok (Prod.mk value nextState) ->
    PsKernelCheckerConfigurationSound context nextState ∧
      (value = true ->
        PsKernelExprListDefEq
          context.environment
          context.localContext
          left
          right)


theorem psKernelDefEqCompareExprListsWithFuel_configuration_sound
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String (Prod Bool PsKernelCheckerState))
    (hDefEq :
      PsKernelDefEqConfigurationSound defeq) :
    PsKernelExprListDefEqConfigurationSound defeq := by
  intro fuel
  induction fuel with
  | zero =>
      intro
        context state nextState left right value
        hConfig hSuccess
      simp [psKernelDefEqCompareExprListsWithFuel] at hSuccess
  | succ remaining ih =>
      intro
        context state nextState left right value
        hConfig hSuccess
      cases left with
      | nil =>
          cases right with
          | nil =>
              simp [psKernelDefEqCompareExprListsWithFuel] at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              exact
                ⟨
                  hConfig,
                  fun _ => PsKernelExprListDefEq.nil
                ⟩
          | cons rightHead rightTail =>
              simp [psKernelDefEqCompareExprListsWithFuel] at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              exact ⟨hConfig, by simp⟩
      | cons leftHead leftTail =>
          cases right with
          | nil =>
              simp [psKernelDefEqCompareExprListsWithFuel] at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              exact ⟨hConfig, by simp⟩
          | cons rightHead rightTail =>
              cases hHeadRun :
                  defeq
                    context
                    state
                    leftHead
                    rightHead with
              | error error =>
                  simp [
                    psKernelDefEqCompareExprListsWithFuel,
                    hHeadRun
                  ] at hSuccess
              | ok headRun =>
                  rcases headRun with
                    ⟨headValue, headState⟩
                  have hHeadSemantic :=
                    hDefEq
                      context
                      state
                      headState
                      leftHead
                      rightHead
                      headValue
                      hConfig
                      hHeadRun
                  cases headValue with
                  | false =>
                      simp [
                        psKernelDefEqCompareExprListsWithFuel,
                        hHeadRun
                      ] at hSuccess
                      rcases hSuccess with ⟨rfl, rfl⟩
                      exact ⟨hHeadSemantic.1, by simp⟩
                  | true =>
                      cases hRestRun :
                          psKernelDefEqCompareExprListsWithFuel
                            remaining
                            defeq
                            context
                            headState
                            leftTail
                            rightTail with
                      | error error =>
                          simp [
                            psKernelDefEqCompareExprListsWithFuel,
                            hHeadRun,
                            hRestRun
                          ] at hSuccess
                      | ok restRun =>
                          rcases restRun with
                            ⟨restValue, restState⟩
                          have hRestSemantic :=
                            ih
                              context
                              headState
                              restState
                              leftTail
                              rightTail
                              restValue
                              hHeadSemantic.1
                              hRestRun
                          simp [
                            psKernelDefEqCompareExprListsWithFuel,
                            hHeadRun,
                            hRestRun
                          ] at hSuccess
                          rcases hSuccess with ⟨rfl, rfl⟩
                          cases restValue with
                          | false =>
                              exact ⟨hRestSemantic.1, by simp⟩
                          | true =>
                              exact
                                ⟨
                                  hRestSemantic.1,
                                  fun _ =>
                                    PsKernelExprListDefEq.cons
                                      leftHead
                                      rightHead
                                      leftTail
                                      rightTail
                                      (hHeadSemantic.2 rfl)
                                      (hRestSemantic.2 rfl)
                                ⟩


theorem psKernelDefEqCompareExprLists_configuration_sound
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String (Prod Bool PsKernelCheckerState))
    (hDefEq :
      PsKernelDefEqConfigurationSound defeq)
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (left right : List PsKernelExpr)
    (value : Bool)
    (hConfig :
      PsKernelCheckerConfigurationSound context state)
    (hSuccess :
      psKernelDefEqCompareExprLists
          defeq
          context
          state
          left
          right =
        Except.ok (Prod.mk value nextState)) :
    PsKernelCheckerConfigurationSound context nextState ∧
      (value = true ->
        PsKernelExprListDefEq
          context.environment
          context.localContext
          left
          right) := by
  unfold psKernelDefEqCompareExprLists at hSuccess
  exact
    psKernelDefEqCompareExprListsWithFuel_configuration_sound
      defeq
      hDefEq
      (Nat.succ
        (Nat.add
          (psKernelExprListLength left)
          (psKernelExprListLength right)))
      context
      state
      nextState
      left
      right
      value
      hConfig
      hSuccess


theorem psKernelDefEqApp_configuration_sound
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String (Prod Bool PsKernelCheckerState))
    (hDefEq :
      PsKernelDefEqConfigurationSound defeq)
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (left right : PsKernelExpr)
    (value : Bool)
    (hConfig :
      PsKernelCheckerConfigurationSound context state)
    (hSuccess :
      psKernelDefEqApp
          defeq
          context
          state
          left
          right =
        Except.ok (Prod.mk value nextState)) :
    PsKernelCheckerConfigurationSound context nextState ∧
      (value = true ->
        PsKernelDefEqJudgment
          context.environment
          context.localContext
          left
          right) := by
  cases hHeadRun :
      defeq
        context
        state
        (psKernelExprGetAppFn left)
        (psKernelExprGetAppFn right) with
  | error error =>
      simp [
        psKernelDefEqApp,
        hHeadRun
      ] at hSuccess
  | ok headRun =>
      rcases headRun with ⟨headValue, headState⟩
      have hHeadSemantic :=
        hDefEq
          context
          state
          headState
          (psKernelExprGetAppFn left)
          (psKernelExprGetAppFn right)
          headValue
          hConfig
          hHeadRun
      cases headValue with
      | false =>
          simp [
            psKernelDefEqApp,
            hHeadRun
          ] at hSuccess
          rcases hSuccess with ⟨rfl, rfl⟩
          exact ⟨hHeadSemantic.1, by simp⟩
      | true =>
          let leftArgs :=
            psKernelExprGetAppArgs left
          let rightArgs :=
            psKernelExprGetAppArgs right
          cases hLength :
              Nat.beq
                (psKernelExprListLength leftArgs)
                (psKernelExprListLength rightArgs) with
          | false =>
              simp [
                psKernelDefEqApp,
                hHeadRun,
                leftArgs,
                rightArgs,
                hLength
              ] at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              exact ⟨hHeadSemantic.1, by simp⟩
          | true =>
              cases hArgsRun :
                  psKernelDefEqCompareExprLists
                    defeq
                    context
                    headState
                    leftArgs
                    rightArgs with
              | error error =>
                  simp [
                    psKernelDefEqApp,
                    hHeadRun,
                    leftArgs,
                    rightArgs,
                    hLength,
                    hArgsRun
                  ] at hSuccess
              | ok argsRun =>
                  rcases argsRun with
                    ⟨argsValue, argsState⟩
                  have hArgsSemantic :=
                    psKernelDefEqCompareExprLists_configuration_sound
                      defeq
                      hDefEq
                      context
                      headState
                      argsState
                      leftArgs
                      rightArgs
                      argsValue
                      hHeadSemantic.1
                      hArgsRun
                  simp [
                    psKernelDefEqApp,
                    hHeadRun,
                    leftArgs,
                    rightArgs,
                    hLength,
                    hArgsRun
                  ] at hSuccess
                  rcases hSuccess with ⟨rfl, rfl⟩
                  cases argsValue with
                  | false =>
                      exact ⟨hArgsSemantic.1, by simp⟩
                  | true =>
                      refine ⟨hArgsSemantic.1, ?_⟩
                      intro _
                      have hApplied :=
                        psKernelSemanticApplyArgs_defeq
                          context.environment
                          context.localContext
                          (psKernelExprGetAppFn left)
                          (psKernelExprGetAppFn right)
                          leftArgs
                          rightArgs
                          (hHeadSemantic.2 rfl)
                          (hArgsSemantic.2 rfl)
                      have hLeft :=
                        psKernelSemanticApplyArgs_getApp_reconstruct
                          left
                      have hRight :=
                        psKernelSemanticApplyArgs_getApp_reconstruct
                          right
                      dsimp [leftArgs, rightArgs] at hApplied
                      rw [hLeft, hRight] at hApplied
                      exact hApplied
