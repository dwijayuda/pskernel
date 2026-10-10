import Ps.KernelCore.Checker.Inference.Helpers
import Ps.KernelCore.Metatheory.Judgments
import Ps.KernelCore.Metatheory.CheckerContracts

theorem psKernelCacheInferResult_ineligible
    (state : PsKernelCheckerState)
    (inferOnly : Bool)
    (expr result : PsKernelExpr)
    (h : psKernelInferCacheEligible inferOnly expr = false) :
    psKernelCacheInferResult state inferOnly expr result = state := by
  simp [psKernelCacheInferResult, h]

theorem psKernelEnsureSortWith_sort
    (whnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (level : PsKernelLevel) :
    psKernelEnsureSortWith
        whnf context state (PsKernelExpr.sort level) =
      Except.ok (Prod.mk level state) := by
  rfl

theorem psKernelEnsureForallWith_forall
    (whnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (name : PsKernelName)
    (domain body : PsKernelExpr)
    (binderInfo : PsKernelBinderInfo) :
    psKernelEnsureForallWith
        whnf context state
        (PsKernelExpr.forallE name domain body binderInfo) =
      Except.ok
        (Prod.mk
          (PsKernelForallView.mk name domain body binderInfo)
          state) := by
  rfl

theorem psKernelInferAppOnlyLoopWithFuel_zero
    (whnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (args : List PsKernelExpr)
    (index instantiated : Nat)
    (current : PsKernelExpr) :
    psKernelInferAppOnlyLoopWithFuel
        0 whnf context state args index instantiated current =
      Except.error "kernel inference budget exhausted" := by
  rfl


theorem psKernelCacheInferResult_preserves_nextFresh
    (state : PsKernelCheckerState)
    (inferOnly : Bool)
    (expr result : PsKernelExpr) :
    (psKernelCacheInferResult
      state inferOnly expr result).nextFresh =
      state.nextFresh := by
  cases hEligible :
      psKernelInferCacheEligible inferOnly expr <;>
    cases inferOnly <;>
    simp [
      psKernelCacheInferResult,
      hEligible,
      psKernelCheckerStateWithInferOnly,
      psKernelCheckerStateWithCheckedInfer
    ]

theorem psKernelCacheInferResult_inferOnly_preserves_checked
    (state : PsKernelCheckerState)
    (expr result : PsKernelExpr) :
    (psKernelCacheInferResult
      state true expr result).checkedInfer =
      state.checkedInfer := by
  cases hEligible :
      psKernelInferCacheEligible true expr <;>
    simp [
      psKernelCacheInferResult,
      hEligible,
      psKernelCheckerStateWithInferOnly
    ]

theorem psKernelCacheInferResult_checked_preserves_inferOnly
    (state : PsKernelCheckerState)
    (expr result : PsKernelExpr) :
    (psKernelCacheInferResult
      state false expr result).inferOnly =
      state.inferOnly := by
  cases hEligible :
      psKernelInferCacheEligible false expr <;>
    simp [
      psKernelCacheInferResult,
      hEligible,
      psKernelCheckerStateWithCheckedInfer
    ]

theorem psKernelCacheInferResult_preserves_whnf
    (state : PsKernelCheckerState)
    (inferOnly : Bool)
    (expr result : PsKernelExpr) :
    (psKernelCacheInferResult
      state inferOnly expr result).whnf =
      state.whnf := by
  cases hEligible :
      psKernelInferCacheEligible inferOnly expr <;>
    cases inferOnly <;>
    simp [
      psKernelCacheInferResult,
      hEligible,
      psKernelCheckerStateWithInferOnly,
      psKernelCheckerStateWithCheckedInfer
    ]

theorem psKernelCacheInferResult_preserves_defeq_caches
    (state : PsKernelCheckerState)
    (inferOnly : Bool)
    (expr result : PsKernelExpr) :
    (psKernelCacheInferResult
      state inferOnly expr result).success =
        state.success ∧
    (psKernelCacheInferResult
      state inferOnly expr result).failure =
        state.failure := by
  cases hEligible :
      psKernelInferCacheEligible inferOnly expr <;>
    cases inferOnly <;>
    simp [
      psKernelCacheInferResult,
      hEligible,
      psKernelCheckerStateWithInferOnly,
      psKernelCheckerStateWithCheckedInfer
    ]


theorem psKernelCacheInferResult_preserves_semantic_sound
    (environment : PsKernelEnvironment)
    (localContext : PsKernelLocalContext)
    (state : PsKernelCheckerState)
    (inferOnly : Bool)
    (expr result : PsKernelExpr)
    (hInsert : PsKernelInferenceCacheInsertLaw)
    (hState :
      PsKernelCheckerStateSemanticSound
        environment
        localContext
        state)
    (hTyping :
      PsKernelTypingJudgment
        environment
        localContext
        expr
        result) :
    PsKernelCheckerStateSemanticSound
      environment
      localContext
      (psKernelCacheInferResult
        state
        inferOnly
        expr
        result) := by
  unfold PsKernelCheckerStateSemanticSound at hState ⊢
  rcases hState with
    ⟨hInferOnly, hChecked, hWhnfCore, hWhnf, hUnfold, hSuccess⟩
  cases hEligible :
      psKernelInferCacheEligible inferOnly expr with
  | false =>
      simpa [psKernelCacheInferResult, hEligible] using
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
      cases inferOnly with
      | false =>
          simpa [
            psKernelCacheInferResult,
            hEligible,
            psKernelCheckerStateWithCheckedInfer
          ] using
            (show
              PsKernelInferOnlyCacheIsolated
                  environment localContext state.inferOnly ∧
                PsKernelInferenceCacheSound
                  environment localContext
                  (psKernelExprMapInsert
                    state.checkedInfer expr result) ∧
                PsKernelReductionCacheSound
                  environment localContext state.whnfCore ∧
                PsKernelReductionCacheSound
                  environment localContext state.whnf ∧
                PsKernelReductionCacheSound
                  environment localContext state.unfold ∧
                PsKernelDefEqCacheSound
                  environment localContext state.success
              from
                ⟨
                  hInferOnly,
                  hInsert
                    environment
                    localContext
                    state.checkedInfer
                    expr
                    result
                    hChecked
                    hTyping,
                  hWhnfCore,
                  hWhnf,
                  hUnfold,
                  hSuccess
                ⟩)
      | true =>
          simpa [
            psKernelCacheInferResult,
            hEligible,
            psKernelCheckerStateWithInferOnly
          ] using
            (show
              PsKernelInferOnlyCacheIsolated
                  environment localContext
                  (psKernelExprMapInsert
                    state.inferOnly expr result) ∧
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
                ⟨
                  psKernelInferOnlyCacheIsolated_insert
                    environment
                    localContext
                    state.inferOnly
                    expr
                    result
                    hInferOnly
                    hTyping,
                  hChecked,
                  hWhnfCore,
                  hWhnf,
                  hUnfold,
                  hSuccess
                ⟩)


theorem psKernelInferAppOnlyLoopWithFuel_configuration_preserves
    (whnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String
        (Prod PsKernelExpr PsKernelCheckerState))
    (hWhnf :
      PsKernelWhnfConfigurationSound whnf)
    (fuel : Nat)
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (args : List PsKernelExpr)
    (index instantiated : Nat)
    (current result : PsKernelExpr)
    (hConfig :
      PsKernelCheckerConfigurationSound context state)
    (hSuccess :
      psKernelInferAppOnlyLoopWithFuel
          fuel
          whnf
          context
          state
          args
          index
          instantiated
          current =
        Except.ok (Prod.mk result nextState)) :
    PsKernelCheckerConfigurationSound context nextState := by
  induction fuel generalizing
      state nextState args index instantiated current result with
  | zero =>
      simp [psKernelInferAppOnlyLoopWithFuel] at hSuccess
  | succ remaining ih =>
      cases hMore :
          psKernelNatLt
            index
            (psKernelExprListLength args) with
      | false =>
          simp [
            psKernelInferAppOnlyLoopWithFuel,
            hMore
          ] at hSuccess
          rcases hSuccess with ⟨rfl, rfl⟩
          exact hConfig
      | true =>
          by_cases hForall :
              ∃
                (name : PsKernelName)
                (domain body : PsKernelExpr)
                (binderInfo : PsKernelBinderInfo),
                current =
                  PsKernelExpr.forallE
                    name domain body binderInfo
          · rcases hForall with
              ⟨name, domain, body, binderInfo, rfl⟩
            have hRun :
                psKernelInferAppOnlyLoopWithFuel
                    remaining
                    whnf
                    context
                    state
                    args
                    (Nat.succ index)
                    instantiated
                    body =
                  Except.ok
                    (Prod.mk result nextState) := by
              simpa [
                psKernelInferAppOnlyLoopWithFuel,
                hMore
              ] using hSuccess
            exact
              ih
                state
                nextState
                args
                (Nat.succ index)
                instantiated
                body
                result
                hConfig
                hRun
          · let pending :=
              psKernelExprListTake
                (Nat.sub index instantiated)
                (psKernelExprListDrop instantiated args)
            let fallbackExpr :=
              psKernelExprInstantiateRev
                current
                pending
            have hStep :
                psKernelInferAppOnlyLoopWithFuel
                    (Nat.succ remaining)
                    whnf
                    context
                    state
                    args
                    index
                    instantiated
                    current =
                  match
                      psKernelEnsureForallWith
                        whnf
                        context
                        state
                        fallbackExpr with
                  | Except.error error =>
                      Except.error error
                  | Except.ok forallResult =>
                      psKernelInferAppOnlyLoopWithFuel
                        remaining
                        whnf
                        context
                        (Prod.snd forallResult)
                        args
                        (Nat.succ index)
                        index
                        (Prod.fst forallResult).body := by
              cases current
              case forallE name domain body binderInfo =>
                exact
                  (hForall
                    ⟨name, domain, body, binderInfo, rfl⟩).elim
              all_goals
                simp [
                  psKernelInferAppOnlyLoopWithFuel,
                  hMore,
                  pending,
                  fallbackExpr
                ]
              all_goals rfl
            rw [hStep] at hSuccess
            cases hEnsure :
                psKernelEnsureForallWith
                  whnf
                  context
                  state
                  fallbackExpr with
            | error error =>
                simp [hEnsure] at hSuccess
            | ok forallResult =>
                cases forallResult with
                | mk view forallState =>
                    simp [hEnsure] at hSuccess
                    have hEnsureSemantic :=
                      psKernelEnsureForallWith_configuration_refines
                        whnf
                        hWhnf
                        context
                        state
                        forallState
                        fallbackExpr
                        view
                        hConfig
                        hEnsure
                    exact
                      ih
                        forallState
                        nextState
                        args
                        (Nat.succ index)
                        index
                        view.body
                        result
                        hEnsureSemantic.2
                        hSuccess

