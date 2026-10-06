import Ps.KernelCore.Metatheory.ContextState
import Ps.KernelCore.Metatheory.CacheSemantic
import Ps.KernelCore.Checker.Inference.Helpers
import Ps.KernelCore.Checker.Reduction.WhnfCore
import Ps.KernelCore.Checker.DefEq.BinderSpines

/-
Final configuration-level contracts for the concrete checker.

Unlike the earlier result-only contracts, these require every successful call
to preserve the complete checker configuration invariant: authoritative index
refinement, generated-name freshness, and all semantic caches.
-/

def PsKernelInferenceCoreConfigurationSound
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
      Except String (Prod Bool PsKernelCheckerState)) : Prop :=
  ∀
    (fuel : Nat)
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (expr result : PsKernelExpr)
    (inferOnly : Bool),
    PsKernelCheckerConfigurationSound context state ->
    psKernelInferCoreWithFuel
        fuel whnf defeq
        context state expr inferOnly =
      Except.ok (Prod.mk result nextState) ->
    PsKernelTypingJudgment
        context.environment
        context.localContext
        expr
        result ∧
      PsKernelCheckerConfigurationSound
        context
        nextState

def PsKernelInferenceConfigurationSound
    (infer :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState)) : Prop :=
  ∀
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (expr result : PsKernelExpr),
    PsKernelCheckerConfigurationSound context state ->
    infer context state expr =
      Except.ok (Prod.mk result nextState) ->
    PsKernelTypingJudgment
        context.environment
        context.localContext
        expr
        result ∧
      PsKernelCheckerConfigurationSound
        context
        nextState

def PsKernelWhnfCoreConfigurationSound
    (coreWhnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Bool ->
      Bool ->
      Except String (Prod PsKernelExpr PsKernelCheckerState)) : Prop :=
  ∀
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (expr result : PsKernelExpr)
    (cheapRec cheapProj : Bool),
    PsKernelCheckerConfigurationSound context state ->
    coreWhnf
        context state expr cheapRec cheapProj =
      Except.ok (Prod.mk result nextState) ->
    PsKernelReductionClosure
        context.environment
        context.localContext
        expr
        result ∧
      PsKernelCheckerConfigurationSound
        context
        nextState

def PsKernelWhnfConfigurationSound
    (whnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState)) : Prop :=
  ∀
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (expr result : PsKernelExpr),
    PsKernelCheckerConfigurationSound context state ->
    whnf context state expr =
      Except.ok (Prod.mk result nextState) ->
    PsKernelReductionClosure
        context.environment
        context.localContext
        expr
        result ∧
      PsKernelCheckerConfigurationSound
        context
        nextState

def PsKernelDefEqConfigurationSound
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String (Prod Bool PsKernelCheckerState)) : Prop :=
  ∀
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (left right : PsKernelExpr)
    (value : Bool),
    PsKernelCheckerConfigurationSound context state ->
    defeq context state left right =
      Except.ok (Prod.mk value nextState) ->
    PsKernelCheckerConfigurationSound
        context
        nextState ∧
      (value = true ->
        PsKernelDefEqJudgment
          context.environment
          context.localContext
          left
          right)


/-
Final checker contracts used by the implementation-refinement theorem.

The executable kernel intentionally distinguishes inference-only from checked
inference.  Inference-only skips argument validation in application spines, so
it must not be given the same unconditional TypingJudgment contract as the
checked path.  The final proof therefore targets the two contracts separately.
-/

def PsKernelCheckedInferenceCoreConfigurationSound
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
      Except String (Prod Bool PsKernelCheckerState)) : Prop :=
  ∀
    (fuel : Nat)
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (expr result : PsKernelExpr),
    PsKernelCheckerConfigurationSound context state ->
    psKernelInferCoreWithFuel
        fuel whnf defeq
        context state expr false =
      Except.ok (Prod.mk result nextState) ->
    PsKernelTypingJudgment
        context.environment
        context.localContext
        expr
        result ∧
      PsKernelCheckerConfigurationSound
        context
        nextState

def PsKernelInferOnlyCoreConfigurationPreserves
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
      Except String (Prod Bool PsKernelCheckerState)) : Prop :=
  ∀
    (fuel : Nat)
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (expr result : PsKernelExpr),
    PsKernelCheckerConfigurationSound context state ->
    psKernelInferCoreWithFuel
        fuel whnf defeq
        context state expr true =
      Except.ok (Prod.mk result nextState) ->
    PsKernelCheckerConfigurationSound
      context
      nextState

def PsKernelCheckedInferenceConfigurationSound
    (check :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState)) : Prop :=
  ∀
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (expr result : PsKernelExpr),
    PsKernelCheckerConfigurationSound context state ->
    check context state expr =
      Except.ok (Prod.mk result nextState) ->
    PsKernelTypingJudgment
        context.environment
        context.localContext
        expr
        result ∧
      PsKernelCheckerConfigurationSound
        context
        nextState

def PsKernelInferOnlyConfigurationPreserves
    (infer :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState)) : Prop :=
  ∀
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (expr result : PsKernelExpr),
    PsKernelCheckerConfigurationSound context state ->
    infer context state expr =
      Except.ok (Prod.mk result nextState) ->
    PsKernelCheckerConfigurationSound
      context
      nextState

def PsKernelProjectionConfigurationSound
    (whnf inferType :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState)) : Prop :=
  ∀
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (typeName : PsKernelName)
    (index : Nat)
    (structValue result : PsKernelExpr),
    PsKernelCheckerConfigurationSound context state ->
    psKernelInferProjectionWith
        whnf
        inferType
        context
        state
        typeName
        index
        structValue =
      Except.ok (Prod.mk result nextState) ->
    PsKernelTypingJudgment
        context.environment
        context.localContext
        (PsKernelExpr.proj typeName index structValue)
        result ∧
      PsKernelCheckerConfigurationSound
        context
        nextState


def PsKernelDefEqCheckedConfigurationSound
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String (Prod Bool PsKernelCheckerState)) : Prop :=
  ∀
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (left right leftType rightType : PsKernelExpr)
    (value : Bool),
    PsKernelCheckerConfigurationSound context state ->
    PsKernelTypingJudgment
        context.environment
        context.localContext
        left
        leftType ->
    PsKernelTypingJudgment
        context.environment
        context.localContext
        right
        rightType ->
    defeq context state left right =
      Except.ok (Prod.mk value nextState) ->
    PsKernelCheckerConfigurationSound
        context
        nextState ∧
      (value = true ->
        PsKernelDefEqJudgment
          context.environment
          context.localContext
          left
          right)


theorem psKernelEnsureSortWith_configuration_refines
    (whnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (hWhnf :
      PsKernelWhnfConfigurationSound whnf)
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (type : PsKernelExpr)
    (level : PsKernelLevel)
    (hConfig :
      PsKernelCheckerConfigurationSound
        context
        state)
    (hSuccess :
      psKernelEnsureSortWith
          whnf
          context
          state
          type =
        Except.ok (Prod.mk level nextState)) :
    PsKernelDefEqJudgment
        context.environment
        context.localContext
        type
        (PsKernelExpr.sort level) ∧
      PsKernelCheckerConfigurationSound
        context
        nextState := by
  by_cases hDirect :
      ∃ directLevel : PsKernelLevel,
        type = PsKernelExpr.sort directLevel
  · rcases hDirect with ⟨directLevel, rfl⟩
    simp [psKernelEnsureSortWith] at hSuccess
    rcases hSuccess with ⟨rfl, rfl⟩
    exact
      ⟨
        PsKernelDefEqJudgment.refl
          (PsKernelExpr.sort directLevel),
        hConfig
      ⟩
  · have hFallback :
        psKernelEnsureSortWith
            whnf
            context
            state
            type =
          match whnf context state type with
          | Except.error error =>
              Except.error error
          | Except.ok result =>
              match Prod.fst result with
              | PsKernelExpr.sort found =>
                  Except.ok
                    (Prod.mk found (Prod.snd result))
              | _ =>
                  Except.error "expected sort" := by
      cases type with
      | sort directLevel =>
          exfalso
          exact hDirect ⟨directLevel, rfl⟩
      | bvar index => rfl
      | fvar name => rfl
      | mvar name => rfl
      | const name levels => rfl
      | app fn arg => rfl
      | lam name domain body binderInfo => rfl
      | forallE name domain body binderInfo => rfl
      | letE name type value body nondep => rfl
      | lit literal => rfl
      | mdata metadata body => rfl
      | proj typeName index body => rfl
    rw [hFallback] at hSuccess
    cases hRun : whnf context state type with
    | error error =>
        simp [hRun] at hSuccess
    | ok result =>
        cases result with
        | mk reduced reducedState =>
            rw [hRun] at hSuccess
            cases reduced <;> simp at hSuccess
            case sort found =>
              rcases hSuccess with ⟨rfl, rfl⟩
              have hSemantic :=
                hWhnf
                  context
                  state
                  reducedState
                  type
                  (PsKernelExpr.sort found)
                  hConfig
                  hRun
              exact
                ⟨
                  PsKernelDefEqJudgment.reductionClosure
                    type
                    (PsKernelExpr.sort found)
                    hSemantic.1,
                  hSemantic.2
                ⟩

theorem psKernelEnsureForallWith_configuration_refines
    (whnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (hWhnf :
      PsKernelWhnfConfigurationSound whnf)
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (type : PsKernelExpr)
    (view : PsKernelForallView)
    (hConfig :
      PsKernelCheckerConfigurationSound
        context
        state)
    (hSuccess :
      psKernelEnsureForallWith
          whnf
          context
          state
          type =
        Except.ok (Prod.mk view nextState)) :
    PsKernelDefEqJudgment
        context.environment
        context.localContext
        type
        (PsKernelExpr.forallE
          view.name
          view.domain
          view.body
          view.binderInfo) ∧
      PsKernelCheckerConfigurationSound
        context
        nextState := by
  by_cases hDirect :
      ∃
        (name : PsKernelName)
        (domain body : PsKernelExpr)
        (binderInfo : PsKernelBinderInfo),
        type =
          PsKernelExpr.forallE
            name domain body binderInfo
  · rcases hDirect with
      ⟨name, domain, body, binderInfo, rfl⟩
    simp [psKernelEnsureForallWith] at hSuccess
    rcases hSuccess with ⟨rfl, rfl⟩
    exact
      ⟨
        PsKernelDefEqJudgment.refl
          (PsKernelExpr.forallE
            name domain body binderInfo),
        hConfig
      ⟩
  · have hFallback :
        psKernelEnsureForallWith
            whnf
            context
            state
            type =
          match whnf context state type with
          | Except.error error =>
              Except.error error
          | Except.ok result =>
              match Prod.fst result with
              | PsKernelExpr.forallE
                  name domain body binderInfo =>
                  Except.ok
                    (Prod.mk
                      (PsKernelForallView.mk
                        name domain body binderInfo)
                      (Prod.snd result))
              | _ =>
                  Except.error "expected function type" := by
      cases type with
      | forallE name domain body binderInfo =>
          exfalso
          exact
            hDirect
              ⟨name, domain, body, binderInfo, rfl⟩
      | bvar index => rfl
      | fvar name => rfl
      | mvar name => rfl
      | sort level => rfl
      | const name levels => rfl
      | app fn arg => rfl
      | lam name domain body binderInfo => rfl
      | letE name ty value body nondep => rfl
      | lit literal => rfl
      | mdata metadata body => rfl
      | proj typeName index body => rfl
    rw [hFallback] at hSuccess
    cases hRun : whnf context state type with
    | error error =>
        simp [hRun] at hSuccess
    | ok result =>
        cases result with
        | mk reduced reducedState =>
            rw [hRun] at hSuccess
            cases reduced <;> simp at hSuccess
            case forallE name domain body binderInfo =>
              rcases hSuccess with ⟨rfl, rfl⟩
              have hSemantic :=
                hWhnf
                  context
                  state
                  reducedState
                  type
                  (PsKernelExpr.forallE
                    name domain body binderInfo)
                  hConfig
                  hRun
              exact
                ⟨
                  PsKernelDefEqJudgment.reductionClosure
                    type
                    (PsKernelExpr.forallE
                      name domain body binderInfo)
                    hSemantic.1,
                  hSemantic.2
                ⟩


theorem psKernelCacheInferResult_preserves_configuration
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (inferOnly : Bool)
    (expr result : PsKernelExpr)
    (hConfig :
      PsKernelCheckerConfigurationSound
        context
        state)
    (hTyping :
      PsKernelTypingJudgment
        context.environment
        context.localContext
        expr
        result) :
    PsKernelCheckerConfigurationSound
      context
      (psKernelCacheInferResult
        state inferOnly expr result) := by
  rcases hConfig with
    ⟨hIndex, hBound, hState⟩
  refine ⟨hIndex, ?_, ?_⟩
  · have hNext :
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
    simpa [hNext] using hBound
  · unfold PsKernelCheckerStateSemanticSound at hState ⊢
    rcases hState with
      ⟨hInferOnly, hChecked, hWhnfCore, hWhnf, hUnfold, hSuccess⟩
    cases hEligible :
        psKernelInferCacheEligible inferOnly expr with
    | false =>
        simpa [psKernelCacheInferResult, hEligible] using
          (show
            PsKernelInferenceCacheSound
                context.environment context.localContext state.inferOnly ∧
              PsKernelInferenceCacheSound
                context.environment context.localContext state.checkedInfer ∧
              PsKernelReductionCacheSound
                context.environment context.localContext state.whnfCore ∧
              PsKernelReductionCacheSound
                context.environment context.localContext state.whnf ∧
              PsKernelReductionCacheSound
                context.environment context.localContext state.unfold ∧
              PsKernelDefEqCacheSound
                context.environment context.localContext state.success
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
                PsKernelInferenceCacheSound
                    context.environment context.localContext state.inferOnly ∧
                  PsKernelInferenceCacheSound
                    context.environment context.localContext
                    (psKernelExprMapInsert state.checkedInfer expr result) ∧
                  PsKernelReductionCacheSound
                    context.environment context.localContext state.whnfCore ∧
                  PsKernelReductionCacheSound
                    context.environment context.localContext state.whnf ∧
                  PsKernelReductionCacheSound
                    context.environment context.localContext state.unfold ∧
                  PsKernelDefEqCacheSound
                    context.environment context.localContext state.success
                from
                  ⟨
                    hInferOnly,
                    psKernelInferenceCacheInsertLaw_all
                      context.environment
                      context.localContext
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
                PsKernelInferenceCacheSound
                    context.environment context.localContext
                    (psKernelExprMapInsert state.inferOnly expr result) ∧
                  PsKernelInferenceCacheSound
                    context.environment context.localContext state.checkedInfer ∧
                  PsKernelReductionCacheSound
                    context.environment context.localContext state.whnfCore ∧
                  PsKernelReductionCacheSound
                    context.environment context.localContext state.whnf ∧
                  PsKernelReductionCacheSound
                    context.environment context.localContext state.unfold ∧
                  PsKernelDefEqCacheSound
                    context.environment context.localContext state.success
                from
                  ⟨
                    psKernelInferenceCacheInsertLaw_all
                      context.environment
                      context.localContext
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

theorem psKernelWhnfCoreFinish_preserves_configuration
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (original result : PsKernelExpr)
    (cheapProj : Bool)
    (hConfig :
      PsKernelCheckerConfigurationSound context state)
    (hReduction :
      PsKernelReductionClosure
        context.environment
        context.localContext
        original
        result) :
    PsKernelCheckerConfigurationSound
      context
      (if cheapProj then
        state
      else
        psKernelCheckerStateWithWhnfCore
          state
          (psKernelExprMapInsert
            state.whnfCore original result)) := by
  rcases hConfig with
    ⟨hIndex, hBound, hState⟩
  cases cheapProj with
  | true =>
      exact ⟨hIndex, hBound, hState⟩
  | false =>
      refine ⟨hIndex, ?_, ?_⟩
      · simpa [psKernelCheckerStateWithWhnfCore] using hBound
      · unfold PsKernelCheckerStateSemanticSound at hState ⊢
        rcases hState with
          ⟨hInferOnly, hChecked, hWhnfCore, hWhnf, hUnfold, hSuccess⟩
        simpa [psKernelCheckerStateWithWhnfCore] using
          (show
            PsKernelInferenceCacheSound
                context.environment context.localContext state.inferOnly ∧
              PsKernelInferenceCacheSound
                context.environment context.localContext state.checkedInfer ∧
              PsKernelReductionCacheSound
                context.environment context.localContext
                (psKernelExprMapInsert state.whnfCore original result) ∧
              PsKernelReductionCacheSound
                context.environment context.localContext state.whnf ∧
              PsKernelReductionCacheSound
                context.environment context.localContext state.unfold ∧
              PsKernelDefEqCacheSound
                context.environment context.localContext state.success
            from
              ⟨
                hInferOnly,
                hChecked,
                psKernelReductionCacheInsertLaw_all
                  context.environment
                  context.localContext
                  state.whnfCore
                  original
                  result
                  hWhnfCore
                  hReduction,
                hWhnf,
                hUnfold,
                hSuccess
              ⟩)

theorem psKernelWhnfFinish_preserves_configuration
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (original result : PsKernelExpr)
    (hConfig :
      PsKernelCheckerConfigurationSound context state)
    (hReduction :
      PsKernelReductionClosure
        context.environment
        context.localContext
        original
        result) :
    PsKernelCheckerConfigurationSound
      context
      (psKernelCheckerStateWithWhnf
        state
        (psKernelExprMapInsert
          state.whnf original result)) := by
  rcases hConfig with
    ⟨hIndex, hBound, hState⟩
  refine ⟨hIndex, ?_, ?_⟩
  · simpa [psKernelCheckerStateWithWhnf] using hBound
  · unfold PsKernelCheckerStateSemanticSound at hState ⊢
    rcases hState with
      ⟨hInferOnly, hChecked, hWhnfCore, hWhnf, hUnfold, hSuccess⟩
    simpa [psKernelCheckerStateWithWhnf] using
      (show
        PsKernelInferenceCacheSound
            context.environment context.localContext state.inferOnly ∧
          PsKernelInferenceCacheSound
            context.environment context.localContext state.checkedInfer ∧
          PsKernelReductionCacheSound
            context.environment context.localContext state.whnfCore ∧
          PsKernelReductionCacheSound
            context.environment context.localContext
            (psKernelExprMapInsert state.whnf original result) ∧
          PsKernelReductionCacheSound
            context.environment context.localContext state.unfold ∧
          PsKernelDefEqCacheSound
            context.environment context.localContext state.success
        from
          ⟨
            hInferOnly,
            hChecked,
            hWhnfCore,
            psKernelReductionCacheInsertLaw_all
              context.environment
              context.localContext
              state.whnf
              original
              result
              hWhnf
              hReduction,
            hUnfold,
            hSuccess
          ⟩)

theorem psKernelDefEqFinish_preserves_configuration
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (left right : PsKernelExpr)
    (value : Bool)
    (hConfig :
      PsKernelCheckerConfigurationSound context state)
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
          state left right value)) := by
  cases value with
  | false =>
      simpa [psKernelDefEqFinish] using hConfig
  | true =>
      rcases hConfig with
        ⟨hIndex, hBound, hState⟩
      have hEq :
          PsKernelDefEqJudgment
            context.environment
            context.localContext
            left
            right :=
        hDefEq rfl
      refine ⟨hIndex, ?_, ?_⟩
      · simpa [
          psKernelDefEqFinish,
          psKernelCheckerStateWithSuccess
        ] using hBound
      · unfold PsKernelCheckerStateSemanticSound at hState ⊢
        rcases hState with
          ⟨hInferOnly, hChecked, hWhnfCore, hWhnf, hUnfold, hSuccess⟩
        simpa [
          psKernelDefEqFinish,
          psKernelCheckerStateWithSuccess
        ] using
          (show
            PsKernelInferenceCacheSound
                context.environment context.localContext state.inferOnly ∧
              PsKernelInferenceCacheSound
                context.environment context.localContext state.checkedInfer ∧
              PsKernelReductionCacheSound
                context.environment context.localContext state.whnfCore ∧
              PsKernelReductionCacheSound
                context.environment context.localContext state.whnf ∧
              PsKernelReductionCacheSound
                context.environment context.localContext state.unfold ∧
              PsKernelDefEqCacheSound
                context.environment context.localContext
                (psKernelExprPairSetInsert state.success left right)
            from
              ⟨
                hInferOnly,
                hChecked,
                hWhnfCore,
                hWhnf,
                hUnfold,
                psKernelDefEqCacheInsertLaw_all
                  context.environment
                  context.localContext
                  state.success
                  left
                  right
                  hSuccess
                  hEq
              ⟩)
