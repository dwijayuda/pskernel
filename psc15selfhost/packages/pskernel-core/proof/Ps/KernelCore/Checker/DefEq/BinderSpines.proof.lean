import Ps.KernelCore.Checker.DefEq.BinderSpines
import Ps.KernelCore.Metatheory.ContextState
import Ps.KernelCore.Metatheory.CacheSemantic
import Ps.KernelCore.Metatheory.CheckerContracts

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


theorem psKernelDefEqLambdaSpineWithFuel_preserves_configuration
    (fuel : Nat)
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String (Prod Bool PsKernelCheckerState))
    (hDefEq :
      PsKernelDefEqConfigurationSound defeq)
    (hString : PsKernelStringEqSoundLaw)
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (left right : PsKernelExpr)
    (subst : List PsKernelExpr)
    (value : Bool)
    (hConfig :
      PsKernelCheckerConfigurationSound context state)
    (hSuccess :
      psKernelDefEqLambdaSpineWithFuel
          fuel defeq context state left right subst =
        Except.ok (Prod.mk value nextState)) :
    PsKernelCheckerConfigurationSound context nextState := by
  induction fuel generalizing
      context state nextState left right subst value with
  | zero =>
      simp [psKernelDefEqLambdaSpineWithFuel] at hSuccess
  | succ remaining ih =>
      cases left <;> try
        exact
          (hDefEq
            context
            state
            nextState
            _
            _
            value
            hConfig
            (by
              simpa [psKernelDefEqLambdaSpineWithFuel]
                using hSuccess)).1
      case lam leftName leftDomain leftBody leftInfo =>
        cases right <;> try
          exact
            (hDefEq
              context
              state
              nextState
              _
              _
              value
              hConfig
              (by
                simpa [psKernelDefEqLambdaSpineWithFuel]
                  using hSuccess)).1
        case lam rightName rightDomain rightBody rightInfo =>
          let leftOpened :=
            psKernelExprInstantiateRev leftDomain subst
          let rightOpened :=
            psKernelExprInstantiateRev rightDomain subst
          let continueAfterDomain :=
            fun (domainState : PsKernelCheckerState) =>
              if
                  if psKernelExprHasLooseBVar leftBody then
                    true
                  else
                    psKernelExprHasLooseBVar rightBody then
                let openedLocal :=
                  psKernelDefEqWithLocal
                    context
                    domainState
                    rightName
                    rightOpened
                    rightInfo
                let fresh :=
                  Prod.fst openedLocal
                let child :=
                  Prod.fst (Prod.snd openedLocal)
                let freshState :=
                  Prod.snd (Prod.snd openedLocal)
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
                      List.nil))
          have hReady :
              (∃ domainState : PsKernelCheckerState,
                PsKernelCheckerConfigurationSound
                    context
                    domainState ∧
                  continueAfterDomain domainState =
                    Except.ok (Prod.mk value nextState)) ∨
                PsKernelCheckerConfigurationSound
                  context
                  nextState := by
            cases hDomainEq :
                psKernelExprEq leftDomain rightDomain with
            | true =>
                exact
                  Or.inl
                    ⟨
                      state,
                      hConfig,
                      by
                        simpa [
                          psKernelDefEqLambdaSpineWithFuel,
                          leftOpened,
                          rightOpened,
                          continueAfterDomain,
                          hDomainEq
                        ] using hSuccess
                    ⟩
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
                        exact Or.inr hDomainSemantic.1
                    | true =>
                        exact
                          Or.inl
                            ⟨
                              domainState,
                              hDomainSemantic.1,
                              by
                                simpa [
                                  psKernelDefEqLambdaSpineWithFuel,
                                  leftOpened,
                                  rightOpened,
                                  continueAfterDomain,
                                  hDomainEq,
                                  hDomainRun
                                ] using hSuccess
                            ⟩
          rcases hReady with
            ⟨domainState, hDomainConfig, hContinue⟩ |
            hDone
          · cases hLeftLoose :
                psKernelExprHasLooseBVar leftBody with
            | true =>
                let freshResult :=
                  psKernelCheckerStateFreshName
                    domainState
                    rightName
                let fresh :=
                  Prod.fst freshResult
                let freshState :=
                  Prod.snd freshResult
                let childLocal :=
                  psKernelLocalContextAddLocal
                    context.localContext
                    fresh
                    rightName
                    rightOpened
                    rightInfo
                let child :=
                  psKernelCheckerContextWithLocalContext
                    context
                    childLocal
                let nextSubst :=
                  psKernelExprListAppend
                    subst
                    (List.cons
                      (PsKernelExpr.fvar fresh)
                      List.nil)
                have hParentFresh :
                    PsKernelCheckerConfigurationSound
                      context
                      freshState := by
                  simpa [
                    freshResult,
                    freshState
                  ] using
                    psKernelCheckerStateFreshName_preserves_configuration
                      context
                      domainState
                      rightName
                      hDomainConfig
                have hChild :
                    PsKernelCheckerConfigurationSound
                      child
                      freshState := by
                  simpa [
                    psKernelDefEqWithLocal,
                    freshResult,
                    fresh,
                    freshState,
                    childLocal,
                    child
                  ] using
                    psKernelCheckerFreshLocal_preserves_configuration
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
                      continueAfterDomain,
                      hLeftLoose,
                      psKernelDefEqWithLocal,
                      freshResult,
                      fresh,
                      freshState,
                      childLocal,
                      child,
                      nextSubst,
                      hRest
                    ] at hContinue
                | ok restRun =>
                    rcases restRun with
                      ⟨restValue, childFinal⟩
                    have _hChildFinal :=
                      ih
                        defeq
                        hDefEq
                        hString
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
                      continueAfterDomain,
                      hLeftLoose,
                      psKernelDefEqWithLocal,
                      freshResult,
                      fresh,
                      freshState,
                      childLocal,
                      child,
                      nextSubst,
                      hRest
                    ] at hContinue
                    rcases hContinue with ⟨rfl, rfl⟩
                    exact hExit
            | false =>
                cases hRightLoose :
                    psKernelExprHasLooseBVar rightBody with
                | true =>
                    let freshResult :=
                      psKernelCheckerStateFreshName
                        domainState
                        rightName
                    let fresh :=
                      Prod.fst freshResult
                    let freshState :=
                      Prod.snd freshResult
                    let childLocal :=
                      psKernelLocalContextAddLocal
                        context.localContext
                        fresh
                        rightName
                        rightOpened
                        rightInfo
                    let child :=
                      psKernelCheckerContextWithLocalContext
                        context
                        childLocal
                    let nextSubst :=
                      psKernelExprListAppend
                        subst
                        (List.cons
                          (PsKernelExpr.fvar fresh)
                          List.nil)
                    have hParentFresh :
                        PsKernelCheckerConfigurationSound
                          context
                          freshState := by
                      simpa [
                        freshResult,
                        freshState
                      ] using
                        psKernelCheckerStateFreshName_preserves_configuration
                          context
                          domainState
                          rightName
                          hDomainConfig
                    have hChild :
                        PsKernelCheckerConfigurationSound
                          child
                          freshState := by
                      simpa [
                        psKernelDefEqWithLocal,
                        freshResult,
                        fresh,
                        freshState,
                        childLocal,
                        child
                      ] using
                        psKernelCheckerFreshLocal_preserves_configuration
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
                          continueAfterDomain,
                          hLeftLoose,
                          hRightLoose,
                          psKernelDefEqWithLocal,
                          freshResult,
                          fresh,
                          freshState,
                          childLocal,
                          child,
                          nextSubst,
                          hRest
                        ] at hContinue
                    | ok restRun =>
                        rcases restRun with
                          ⟨restValue, childFinal⟩
                        have _hChildFinal :=
                          ih
                            defeq
                            hDefEq
                            hString
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
                          continueAfterDomain,
                          hLeftLoose,
                          hRightLoose,
                          psKernelDefEqWithLocal,
                          freshResult,
                          fresh,
                          freshState,
                          childLocal,
                          child,
                          nextSubst,
                          hRest
                        ] at hContinue
                        rcases hContinue with ⟨rfl, rfl⟩
                        exact hExit
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
                          continueAfterDomain,
                          hLeftLoose,
                          hRightLoose,
                          nextSubst,
                          hRest
                        ] at hContinue
                    | ok restRun =>
                        rcases restRun with
                          ⟨restValue, restState⟩
                        have hRestConfig :=
                          ih
                            defeq
                            hDefEq
                            hString
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
                          continueAfterDomain,
                          hLeftLoose,
                          hRightLoose,
                          nextSubst,
                          hRest
                        ] at hContinue
                        rcases hContinue with ⟨rfl, rfl⟩
                        exact hRestConfig
          · exact hDone


theorem psKernelDefEqFinish_false
    (state : PsKernelCheckerState)
    (left right : PsKernelExpr) :
    psKernelDefEqFinish state left right false =
      Prod.mk false state := by
  rfl

theorem psKernelDefEqFinish_true_value
    (state : PsKernelCheckerState)
    (left right : PsKernelExpr) :
    Prod.fst (psKernelDefEqFinish state left right true) =
      true := by
  cases hEligible :
      psKernelSemanticPairCacheEligible left right <;>
    simp [psKernelDefEqFinish, hEligible]

theorem psKernelDefEqFinish_true_preserves_failure
    (state : PsKernelCheckerState)
    (left right : PsKernelExpr) :
    (Prod.snd
      (psKernelDefEqFinish state left right true)).failure =
      state.failure := by
  cases hEligible :
      psKernelSemanticPairCacheEligible left right <;>
    simp [
      psKernelDefEqFinish,
      hEligible,
      psKernelCheckerStateWithSuccess
    ]

theorem psKernelDefEqLambdaSpineWithFuel_zero
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String (Prod Bool PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (left right : PsKernelExpr)
    (subst : List PsKernelExpr) :
    psKernelDefEqLambdaSpineWithFuel
        0 defeq context state left right subst =
      Except.error
        "kernel defeq lambda-spine budget exhausted" := by
  rfl


theorem psKernelDefEqFinish_preserves_semantic_sound
    (environment : PsKernelEnvironment)
    (localContext : PsKernelLocalContext)
    (state : PsKernelCheckerState)
    (left right : PsKernelExpr)
    (value : Bool)
    (hInsert : PsKernelDefEqCacheInsertLaw)
    (hState :
      PsKernelCheckerStateSemanticSound
        environment
        localContext
        state)
    (hDefEq :
      PsKernelDefEqJudgment
        environment
        localContext
        left
        right) :
    PsKernelCheckerStateSemanticSound
      environment
      localContext
      (Prod.snd
        (psKernelDefEqFinish
          state
          left
          right
          value)) := by
  unfold PsKernelCheckerStateSemanticSound at hState ⊢
  rcases hState with
    ⟨hInferOnly, hChecked, hWhnfCore, hWhnf, hUnfold, hSuccess⟩
  cases value with
  | false =>
      simpa [psKernelDefEqFinish] using
        (show
          PsKernelInferOnlyCacheIsolated
              environment localContext state.inferOnly ∧
            PsKernelInferenceCacheSound
              environment localContext state.checkedInfer ∧
            PsKernelReductionCacheSound
              environment localContext state.whnfCore ∧
            PsKernelReductionCacheSound
              environment localContext state.whnf ∧
            PsKernelReductionCacheSound
              environment localContext state.unfold ∧
            PsKernelDefEqCacheSound
              environment localContext state.success
          from
            ⟨hInferOnly, hChecked, hWhnfCore, hWhnf, hUnfold, hSuccess⟩)
  | true =>
      cases hEligible :
          psKernelSemanticPairCacheEligible left right with
      | false =>
          simpa [
            psKernelDefEqFinish,
            hEligible
          ] using
            (show
              PsKernelInferOnlyCacheIsolated
                  environment localContext state.inferOnly ∧
                PsKernelInferenceCacheSound
                  environment localContext state.checkedInfer ∧
                PsKernelReductionCacheSound
                  environment localContext state.whnfCore ∧
                PsKernelReductionCacheSound
                  environment localContext state.whnf ∧
                PsKernelReductionCacheSound
                  environment localContext state.unfold ∧
                PsKernelDefEqCacheSound
                  environment localContext state.success
              from
                ⟨hInferOnly, hChecked, hWhnfCore, hWhnf, hUnfold, hSuccess⟩)
      | true =>
          simpa [
            psKernelDefEqFinish,
            hEligible,
            psKernelCheckerStateWithSuccess
          ] using
            (show
              PsKernelInferOnlyCacheIsolated
                  environment localContext state.inferOnly ∧
                PsKernelInferenceCacheSound
                  environment localContext state.checkedInfer ∧
                PsKernelReductionCacheSound
                  environment localContext state.whnfCore ∧
                PsKernelReductionCacheSound
                  environment localContext state.whnf ∧
                PsKernelReductionCacheSound
                  environment localContext state.unfold ∧
                PsKernelDefEqCacheSound
                  environment localContext
                  (psKernelExprPairSetInsert
                    state.success left right)
              from
                ⟨
                  hInferOnly,
                  hChecked,
                  hWhnfCore,
                  hWhnf,
                  hUnfold,
                  hInsert
                    environment
                    localContext
                    state.success
                    left
                    right
                    hSuccess
                    hDefEq
                ⟩)



theorem psKernelDefEqFinish_value
    (state : PsKernelCheckerState)
    (left right : PsKernelExpr)
    (value : Bool) :
    Prod.fst
        (psKernelDefEqFinish
          state left right value) =
      value := by
  cases value with
  | false =>
      rfl
  | true =>
      exact psKernelDefEqFinish_true_value state left right


theorem psKernelDefEqFinish_preserves_configuration
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (left right : PsKernelExpr)
    (value : Bool)
    (hConfig :
      PsKernelCheckerConfigurationSound
        context
        state)
    (hDefEq :
      PsKernelDefEqJudgment
        context.environment
        context.localContext
        left
        right) :
    PsKernelCheckerConfigurationSound
      context
      (Prod.snd
        (psKernelDefEqFinish
          state
          left
          right
          value)) := by
  rcases hConfig with
    ⟨hIndex, hFresh, hState⟩
  refine ⟨hIndex, ?_, ?_⟩
  · have hNext :
        (Prod.snd
          (psKernelDefEqFinish
            state left right value)).nextFresh =
          state.nextFresh := by
      cases value with
      | false =>
          rfl
      | true =>
          cases hEligible :
              psKernelSemanticPairCacheEligible
                left
                right <;>
            simp [
              psKernelDefEqFinish,
              hEligible,
              psKernelCheckerStateWithSuccess
            ]
    simpa [hNext] using hFresh
  · exact
      psKernelDefEqFinish_preserves_semantic_sound
        context.environment
        context.localContext
        state
        left
        right
        value
        psKernelDefEqCacheInsertLaw_all
        hState
        hDefEq


theorem psKernelDefEqFinish_configuration_refines
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (left right : PsKernelExpr)
    (value : Bool)
    (hConfig :
      PsKernelCheckerConfigurationSound
        context
        state)
    (hDefEq :
      value = true ->
        PsKernelDefEqJudgment
          context.environment
          context.localContext
          left
          right) :
    PsKernelCheckerConfigurationSound
        context
        (Prod.snd
          (psKernelDefEqFinish
            state left right value)) ∧
      (Prod.fst
          (psKernelDefEqFinish
            state left right value) =
        true ->
        PsKernelDefEqJudgment
          context.environment
          context.localContext
          left
          right) := by
  cases value with
  | false =>
      constructor
      · simpa [psKernelDefEqFinish] using hConfig
      · simp [psKernelDefEqFinish]
  | true =>
      have hSemantic := hDefEq rfl
      constructor
      · exact
          psKernelDefEqFinish_preserves_configuration
            context state left right true hConfig hSemantic
      · intro _
        exact hSemantic


theorem psKernelDefEqFinish_fvar_pair_not_cached
    (state : PsKernelCheckerState)
    (name : PsKernelName)
    (right : PsKernelExpr) :
    psKernelDefEqFinish
        state
        (PsKernelExpr.fvar name)
        right
        true =
      Prod.mk true state := by
  simp [
    psKernelDefEqFinish,
    psKernelSemanticPairCacheEligible,
    psKernelSemanticCacheEligible,
    psKernelExprHasFVar
  ]
