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


theorem psKernelDefEqLambdaSpineWithFuel_configuration_sound
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String (Prod Bool PsKernelCheckerState))
    (hDefEq :
      PsKernelDefEqConfigurationSound defeq)
    (hString : PsKernelStringEqSoundLaw) :
    PsKernelLambdaSpineConfigurationSound defeq := by
  intro fuel
  induction fuel with
  | zero =>
      intro
        context state nextState left right subst value
        hConfig hSuccess
      simp [psKernelDefEqLambdaSpineWithFuel] at hSuccess
  | succ remaining ih =>
      intro
        context state nextState left right subst value
        hConfig hSuccess
      cases left <;> try
        · have hCore :=
            hDefEq
              context state nextState
              (psKernelExprInstantiateRev _ subst)
              (psKernelExprInstantiateRev right subst)
              value
              hConfig
              (by
                simpa [psKernelDefEqLambdaSpineWithFuel]
                  using hSuccess)
          refine ⟨hCore.1, ?_⟩
          intro hTrue
          exact
            PsKernelLambdaSpineJudgment.terminal
              _ _ subst
              (hCore.2 hTrue)
      case lam leftName leftDomain leftBody leftInfo =>
        cases right <;> try
          · have hCore :=
              hDefEq
                context state nextState
                (psKernelExprInstantiateRev
                  (PsKernelExpr.lam
                    leftName leftDomain leftBody leftInfo)
                  subst)
                (psKernelExprInstantiateRev _ subst)
                value
                hConfig
                (by
                  simpa [psKernelDefEqLambdaSpineWithFuel]
                    using hSuccess)
            refine ⟨hCore.1, ?_⟩
            intro hTrue
            exact
              PsKernelLambdaSpineJudgment.terminal
                _ _ subst
                (hCore.2 hTrue)
        case lam rightName rightDomain rightBody rightInfo =>
          let leftOpened :=
            psKernelExprInstantiateRev leftDomain subst
          let rightOpened :=
            psKernelExprInstantiateRev rightDomain subst
          have finishAfterDomain :
              ∀
                (domainState : PsKernelCheckerState),
                PsKernelCheckerConfigurationSound
                    context domainState ->
                PsKernelBinderDomainJudgment
                    context.environment
                    context.localContext
                    leftDomain
                    rightDomain
                    subst ->
                (if
                    if psKernelExprHasLooseBVar leftBody then
                      true
                    else
                      psKernelExprHasLooseBVar rightBody then
                  let opened :=
                    psKernelDefEqWithLocal
                      context
                      domainState
                      rightName
                      rightOpened
                      rightInfo
                  let fresh := Prod.fst opened
                  let child := Prod.fst (Prod.snd opened)
                  let freshState := Prod.snd (Prod.snd opened)
                  match
                      psKernelDefEqLambdaSpineWithFuel
                        remaining
                        defeq
                        child
                        freshState
                        leftBody
                        rightBody
                        (psKernelExprListAppend
                          subst
                          (List.cons
                            (PsKernelExpr.fvar fresh)
                            List.nil)) with
                  | Except.error error =>
                      Except.error error
                  | Except.ok childResult =>
                      Except.ok
                        (Prod.mk
                          (Prod.fst childResult)
                          (psKernelCheckerStateExitLocalScope
                            freshState
                            (Prod.snd childResult)))
                else
                  psKernelDefEqLambdaSpineWithFuel
                    remaining
                    defeq
                    context
                    domainState
                    leftBody
                    rightBody
                    (psKernelExprListAppend
                      subst
                      (List.cons
                        (PsKernelExpr.sort PsKernelLevel.zero)
                        List.nil))) =
                  Except.ok (Prod.mk value nextState) ->
                PsKernelCheckerConfigurationSound
                    context nextState ∧
                  (value = true ->
                    PsKernelLambdaSpineJudgment
                      context.environment
                      context.localContext
                      (PsKernelExpr.lam
                        leftName leftDomain leftBody leftInfo)
                      (PsKernelExpr.lam
                        rightName rightDomain rightBody rightInfo)
                      subst) := by
            intro domainState hDomainConfig hDomain hTail
            cases hDependent :
                (if psKernelExprHasLooseBVar leftBody then
                   true
                 else
                   psKernelExprHasLooseBVar rightBody) with
            | false =>
                let nextSubst :=
                  psKernelExprListAppend
                    subst
                    (List.cons
                      (PsKernelExpr.sort PsKernelLevel.zero)
                      List.nil)
                cases hRest :
                    psKernelDefEqLambdaSpineWithFuel
                      remaining
                      defeq
                      context
                      domainState
                      leftBody
                      rightBody
                      nextSubst with
                | error error =>
                    simp [
                      hDependent,
                      nextSubst,
                      hRest
                    ] at hTail
                | ok rest =>
                    rcases rest with ⟨restValue, restState⟩
                    have hRestSemantic :=
                      ih
                        context
                        domainState
                        restState
                        leftBody
                        rightBody
                        nextSubst
                        restValue
                        hDomainConfig
                        hRest
                    simp [
                      hDependent,
                      nextSubst,
                      hRest
                    ] at hTail
                    rcases hTail with ⟨rfl, rfl⟩
                    refine ⟨hRestSemantic.1, ?_⟩
                    intro hTrue
                    have hLeftClosed :
                        psKernelExprHasLooseBVar leftBody = false := by
                      cases hLeft :
                          psKernelExprHasLooseBVar leftBody with
                      | false => rfl
                      | true =>
                          simp [hLeft] at hDependent
                    have hRightClosed :
                        psKernelExprHasLooseBVar rightBody = false := by
                      cases hRight :
                          psKernelExprHasLooseBVar rightBody with
                      | false => rfl
                      | true =>
                          simp [hLeftClosed, hRight] at hDependent
                    exact
                      PsKernelLambdaSpineJudgment.stepClosed
                        leftName rightName
                        leftDomain rightDomain
                        leftBody rightBody
                        leftInfo rightInfo
                        subst
                        hDomain
                        hLeftClosed
                        hRightClosed
                        (hRestSemantic.2 hTrue)
            | true =>
                let opened :=
                  psKernelDefEqWithLocal
                    context
                    domainState
                    rightName
                    rightOpened
                    rightInfo
                let fresh := Prod.fst opened
                let child := Prod.fst (Prod.snd opened)
                let freshState := Prod.snd (Prod.snd opened)
                let nextSubst :=
                  psKernelExprListAppend
                    subst
                    (List.cons
                      (PsKernelExpr.fvar fresh)
                      List.nil)
                have hParentFresh :
                    PsKernelCheckerConfigurationSound
                      context freshState := by
                  simpa [
                    opened,
                    freshState
                  ] using
                    psKernelDefEqWithLocal_parent_configuration
                      context
                      domainState
                      rightName
                      rightOpened
                      rightInfo
                      hDomainConfig
                have hChild :
                    PsKernelCheckerConfigurationSound
                      child freshState := by
                  simpa [
                    opened,
                    child,
                    freshState
                  ] using
                    psKernelDefEqWithLocal_child_configuration
                      context
                      domainState
                      rightName
                      rightOpened
                      rightInfo
                      hString
                      hDomainConfig
                have hFresh :
                    psKernelLocalContextFind
                        context.localContext
                        fresh =
                      Option.none := by
                  simpa [
                    opened,
                    fresh
                  ] using
                    psKernelDefEqWithLocal_fresh_absent
                      context
                      domainState
                      rightName
                      rightOpened
                      rightInfo
                      hString
                      hDomainConfig
                cases hRest :
                    psKernelDefEqLambdaSpineWithFuel
                      remaining
                      defeq
                      child
                      freshState
                      leftBody
                      rightBody
                      nextSubst with
                | error error =>
                    simp [
                      hDependent,
                      opened,
                      fresh,
                      child,
                      freshState,
                      nextSubst,
                      hRest
                    ] at hTail
                | ok rest =>
                    rcases rest with ⟨restValue, childFinal⟩
                    have hRestSemantic :=
                      ih
                        child
                        freshState
                        childFinal
                        leftBody
                        rightBody
                        nextSubst
                        restValue
                        hChild
                        hRest
                    have hExit :
                        PsKernelCheckerConfigurationSound
                          context
                          (psKernelCheckerStateExitLocalScope
                            freshState
                            childFinal) :=
                      psKernelCheckerStateExitLocalScope_preserves_configuration
                        context
                        freshState
                        childFinal
                        hParentFresh
                    simp [
                      hDependent,
                      opened,
                      fresh,
                      child,
                      freshState,
                      nextSubst,
                      hRest
                    ] at hTail
                    rcases hTail with ⟨rfl, rfl⟩
                    refine ⟨hExit, ?_⟩
                    intro hTrue
                    have hRestJudgment :
                        PsKernelLambdaSpineJudgment
                          context.environment
                          (psKernelLocalContextAddLocal
                            context.localContext
                            fresh
                            rightName
                            rightOpened
                            rightInfo)
                          leftBody
                          rightBody
                          nextSubst := by
                      simpa [
                        opened,
                        fresh,
                        child,
                        psKernelDefEqWithLocal,
                        psKernelCheckerContextWithLocalContext
                      ] using hRestSemantic.2 hTrue
                    exact
                      PsKernelLambdaSpineJudgment.stepOpen
                        leftName rightName fresh
                        leftDomain rightDomain
                        leftBody rightBody
                        leftInfo rightInfo
                        subst
                        hDomain
                        hDependent
                        hFresh
                        hRestJudgment
          cases hDomainEq :
              psKernelExprEq leftDomain rightDomain with
          | true =>
              have hDomain :
                  PsKernelBinderDomainJudgment
                    context.environment
                    context.localContext
                    leftDomain
                    rightDomain
                    subst :=
                PsKernelBinderDomainJudgment.structural
                  leftDomain rightDomain subst hDomainEq
              exact
                finishAfterDomain
                  state
                  hConfig
                  hDomain
                  (by
                    simpa only [
                      psKernelDefEqLambdaSpineWithFuel,
                      leftOpened,
                      rightOpened,
                      hDomainEq,
                      Bool.true_eq,
                      ite_true
                    ] using hSuccess)
          | false =>
              cases hDomainRun :
                  defeq
                    context
                    state
                    leftOpened
                    rightOpened with
              | error error =>
                  simp [
                    psKernelDefEqLambdaSpineWithFuel,
                    leftOpened,
                    rightOpened,
                    hDomainEq,
                    hDomainRun
                  ] at hSuccess
              | ok domainRun =>
                  rcases domainRun with
                    ⟨domainValue, domainState⟩
                  have hDomainSemantic :=
                    hDefEq
                      context
                      state
                      domainState
                      leftOpened
                      rightOpened
                      domainValue
                      hConfig
                      hDomainRun
                  cases domainValue with
                  | false =>
                      simp [
                        psKernelDefEqLambdaSpineWithFuel,
                        leftOpened,
                        rightOpened,
                        hDomainEq,
                        hDomainRun
                      ] at hSuccess
                      rcases hSuccess with ⟨rfl, rfl⟩
                      refine ⟨hDomainSemantic.1, ?_⟩
                      intro hImpossible
                      simp at hImpossible
                  | true =>
                      have hDomain :
                          PsKernelBinderDomainJudgment
                            context.environment
                            context.localContext
                            leftDomain
                            rightDomain
                            subst :=
                        PsKernelBinderDomainJudgment.defeq
                          leftDomain
                          rightDomain
                          subst
                          (hDomainSemantic.2 rfl)
                      exact
                        finishAfterDomain
                          domainState
                          hDomainSemantic.1
                          hDomain
                          (by
                            simpa only [
                              psKernelDefEqLambdaSpineWithFuel,
                              leftOpened,
                              rightOpened,
                              hDomainEq,
                              hDomainRun,
                              Bool.false_eq_true,
                              ite_false,
                              ite_true
                            ] using hSuccess)


theorem psKernelDefEqForallSpineWithFuel_configuration_sound
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String (Prod Bool PsKernelCheckerState))
    (hDefEq :
      PsKernelDefEqConfigurationSound defeq)
    (hString : PsKernelStringEqSoundLaw) :
    PsKernelForallSpineConfigurationSound defeq := by
  intro fuel
  induction fuel with
  | zero =>
      intro
        context state nextState left right subst value
        hConfig hSuccess
      simp [psKernelDefEqForallSpineWithFuel] at hSuccess
  | succ remaining ih =>
      intro
        context state nextState left right subst value
        hConfig hSuccess
      cases left <;> try
        · have hCore :=
            hDefEq
              context state nextState
              (psKernelExprInstantiateRev _ subst)
              (psKernelExprInstantiateRev right subst)
              value
              hConfig
              (by
                simpa [psKernelDefEqForallSpineWithFuel]
                  using hSuccess)
          refine ⟨hCore.1, ?_⟩
          intro hTrue
          exact
            PsKernelForallSpineJudgment.terminal
              _ _ subst
              (hCore.2 hTrue)
      case forallE leftName leftDomain leftBody leftInfo =>
        cases right <;> try
          · have hCore :=
              hDefEq
                context state nextState
                (psKernelExprInstantiateRev
                  (PsKernelExpr.forallE
                    leftName leftDomain leftBody leftInfo)
                  subst)
                (psKernelExprInstantiateRev _ subst)
                value
                hConfig
                (by
                  simpa [psKernelDefEqForallSpineWithFuel]
                    using hSuccess)
            refine ⟨hCore.1, ?_⟩
            intro hTrue
            exact
              PsKernelForallSpineJudgment.terminal
                _ _ subst
                (hCore.2 hTrue)
        case forallE rightName rightDomain rightBody rightInfo =>
          let leftOpened :=
            psKernelExprInstantiateRev leftDomain subst
          let rightOpened :=
            psKernelExprInstantiateRev rightDomain subst
          have finishAfterDomain :
              ∀
                (domainState : PsKernelCheckerState),
                PsKernelCheckerConfigurationSound
                    context domainState ->
                PsKernelBinderDomainJudgment
                    context.environment
                    context.localContext
                    leftDomain
                    rightDomain
                    subst ->
                (if
                    if psKernelExprHasLooseBVar leftBody then
                      true
                    else
                      psKernelExprHasLooseBVar rightBody then
                  let opened :=
                    psKernelDefEqWithLocal
                      context
                      domainState
                      rightName
                      rightOpened
                      rightInfo
                  let fresh := Prod.fst opened
                  let child := Prod.fst (Prod.snd opened)
                  let freshState := Prod.snd (Prod.snd opened)
                  match
                      psKernelDefEqForallSpineWithFuel
                        remaining
                        defeq
                        child
                        freshState
                        leftBody
                        rightBody
                        (psKernelExprListAppend
                          subst
                          (List.cons
                            (PsKernelExpr.fvar fresh)
                            List.nil)) with
                  | Except.error error =>
                      Except.error error
                  | Except.ok childResult =>
                      Except.ok
                        (Prod.mk
                          (Prod.fst childResult)
                          (psKernelCheckerStateExitLocalScope
                            freshState
                            (Prod.snd childResult)))
                else
                  psKernelDefEqForallSpineWithFuel
                    remaining
                    defeq
                    context
                    domainState
                    leftBody
                    rightBody
                    (psKernelExprListAppend
                      subst
                      (List.cons
                        (PsKernelExpr.sort PsKernelLevel.zero)
                        List.nil))) =
                  Except.ok (Prod.mk value nextState) ->
                PsKernelCheckerConfigurationSound
                    context nextState ∧
                  (value = true ->
                    PsKernelForallSpineJudgment
                      context.environment
                      context.localContext
                      (PsKernelExpr.forallE
                        leftName leftDomain leftBody leftInfo)
                      (PsKernelExpr.forallE
                        rightName rightDomain rightBody rightInfo)
                      subst) := by
            intro domainState hDomainConfig hDomain hTail
            cases hDependent :
                (if psKernelExprHasLooseBVar leftBody then
                   true
                 else
                   psKernelExprHasLooseBVar rightBody) with
            | false =>
                let nextSubst :=
                  psKernelExprListAppend
                    subst
                    (List.cons
                      (PsKernelExpr.sort PsKernelLevel.zero)
                      List.nil)
                cases hRest :
                    psKernelDefEqForallSpineWithFuel
                      remaining
                      defeq
                      context
                      domainState
                      leftBody
                      rightBody
                      nextSubst with
                | error error =>
                    simp [
                      hDependent,
                      nextSubst,
                      hRest
                    ] at hTail
                | ok rest =>
                    rcases rest with ⟨restValue, restState⟩
                    have hRestSemantic :=
                      ih
                        context
                        domainState
                        restState
                        leftBody
                        rightBody
                        nextSubst
                        restValue
                        hDomainConfig
                        hRest
                    simp [
                      hDependent,
                      nextSubst,
                      hRest
                    ] at hTail
                    rcases hTail with ⟨rfl, rfl⟩
                    refine ⟨hRestSemantic.1, ?_⟩
                    intro hTrue
                    have hLeftClosed :
                        psKernelExprHasLooseBVar leftBody = false := by
                      cases hLeft :
                          psKernelExprHasLooseBVar leftBody with
                      | false => rfl
                      | true =>
                          simp [hLeft] at hDependent
                    have hRightClosed :
                        psKernelExprHasLooseBVar rightBody = false := by
                      cases hRight :
                          psKernelExprHasLooseBVar rightBody with
                      | false => rfl
                      | true =>
                          simp [hLeftClosed, hRight] at hDependent
                    exact
                      PsKernelForallSpineJudgment.stepClosed
                        leftName rightName
                        leftDomain rightDomain
                        leftBody rightBody
                        leftInfo rightInfo
                        subst
                        hDomain
                        hLeftClosed
                        hRightClosed
                        (hRestSemantic.2 hTrue)
            | true =>
                let opened :=
                  psKernelDefEqWithLocal
                    context
                    domainState
                    rightName
                    rightOpened
                    rightInfo
                let fresh := Prod.fst opened
                let child := Prod.fst (Prod.snd opened)
                let freshState := Prod.snd (Prod.snd opened)
                let nextSubst :=
                  psKernelExprListAppend
                    subst
                    (List.cons
                      (PsKernelExpr.fvar fresh)
                      List.nil)
                have hParentFresh :
                    PsKernelCheckerConfigurationSound
                      context freshState := by
                  simpa [
                    opened,
                    freshState
                  ] using
                    psKernelDefEqWithLocal_parent_configuration
                      context
                      domainState
                      rightName
                      rightOpened
                      rightInfo
                      hDomainConfig
                have hChild :
                    PsKernelCheckerConfigurationSound
                      child freshState := by
                  simpa [
                    opened,
                    child,
                    freshState
                  ] using
                    psKernelDefEqWithLocal_child_configuration
                      context
                      domainState
                      rightName
                      rightOpened
                      rightInfo
                      hString
                      hDomainConfig
                have hFresh :
                    psKernelLocalContextFind
                        context.localContext
                        fresh =
                      Option.none := by
                  simpa [
                    opened,
                    fresh
                  ] using
                    psKernelDefEqWithLocal_fresh_absent
                      context
                      domainState
                      rightName
                      rightOpened
                      rightInfo
                      hString
                      hDomainConfig
                cases hRest :
                    psKernelDefEqForallSpineWithFuel
                      remaining
                      defeq
                      child
                      freshState
                      leftBody
                      rightBody
                      nextSubst with
                | error error =>
                    simp [
                      hDependent,
                      opened,
                      fresh,
                      child,
                      freshState,
                      nextSubst,
                      hRest
                    ] at hTail
                | ok rest =>
                    rcases rest with ⟨restValue, childFinal⟩
                    have hRestSemantic :=
                      ih
                        child
                        freshState
                        childFinal
                        leftBody
                        rightBody
                        nextSubst
                        restValue
                        hChild
                        hRest
                    have hExit :
                        PsKernelCheckerConfigurationSound
                          context
                          (psKernelCheckerStateExitLocalScope
                            freshState
                            childFinal) :=
                      psKernelCheckerStateExitLocalScope_preserves_configuration
                        context
                        freshState
                        childFinal
                        hParentFresh
                    simp [
                      hDependent,
                      opened,
                      fresh,
                      child,
                      freshState,
                      nextSubst,
                      hRest
                    ] at hTail
                    rcases hTail with ⟨rfl, rfl⟩
                    refine ⟨hExit, ?_⟩
                    intro hTrue
                    have hRestJudgment :
                        PsKernelForallSpineJudgment
                          context.environment
                          (psKernelLocalContextAddLocal
                            context.localContext
                            fresh
                            rightName
                            rightOpened
                            rightInfo)
                          leftBody
                          rightBody
                          nextSubst := by
                      simpa [
                        opened,
                        fresh,
                        child,
                        psKernelDefEqWithLocal,
                        psKernelCheckerContextWithLocalContext
                      ] using hRestSemantic.2 hTrue
                    exact
                      PsKernelForallSpineJudgment.stepOpen
                        leftName rightName fresh
                        leftDomain rightDomain
                        leftBody rightBody
                        leftInfo rightInfo
                        subst
                        hDomain
                        hDependent
                        hFresh
                        hRestJudgment
          cases hDomainEq :
              psKernelExprEq leftDomain rightDomain with
          | true =>
              have hDomain :
                  PsKernelBinderDomainJudgment
                    context.environment
                    context.localContext
                    leftDomain
                    rightDomain
                    subst :=
                PsKernelBinderDomainJudgment.structural
                  leftDomain rightDomain subst hDomainEq
              exact
                finishAfterDomain
                  state
                  hConfig
                  hDomain
                  (by
                    simpa only [
                      psKernelDefEqForallSpineWithFuel,
                      leftOpened,
                      rightOpened,
                      hDomainEq,
                      Bool.true_eq,
                      ite_true
                    ] using hSuccess)
          | false =>
              cases hDomainRun :
                  defeq
                    context
                    state
                    leftOpened
                    rightOpened with
              | error error =>
                  simp [
                    psKernelDefEqForallSpineWithFuel,
                    leftOpened,
                    rightOpened,
                    hDomainEq,
                    hDomainRun
                  ] at hSuccess
              | ok domainRun =>
                  rcases domainRun with
                    ⟨domainValue, domainState⟩
                  have hDomainSemantic :=
                    hDefEq
                      context
                      state
                      domainState
                      leftOpened
                      rightOpened
                      domainValue
                      hConfig
                      hDomainRun
                  cases domainValue with
                  | false =>
                      simp [
                        psKernelDefEqForallSpineWithFuel,
                        leftOpened,
                        rightOpened,
                        hDomainEq,
                        hDomainRun
                      ] at hSuccess
                      rcases hSuccess with ⟨rfl, rfl⟩
                      refine ⟨hDomainSemantic.1, ?_⟩
                      intro hImpossible
                      simp at hImpossible
                  | true =>
                      have hDomain :
                          PsKernelBinderDomainJudgment
                            context.environment
                            context.localContext
                            leftDomain
                            rightDomain
                            subst :=
                        PsKernelBinderDomainJudgment.defeq
                          leftDomain
                          rightDomain
                          subst
                          (hDomainSemantic.2 rfl)
                      exact
                        finishAfterDomain
                          domainState
                          hDomainSemantic.1
                          hDomain
                          (by
                            simpa only [
                              psKernelDefEqForallSpineWithFuel,
                              leftOpened,
                              rightOpened,
                              hDomainEq,
                              hDomainRun,
                              Bool.false_eq_true,
                              ite_false,
                              ite_true
                            ] using hSuccess)
