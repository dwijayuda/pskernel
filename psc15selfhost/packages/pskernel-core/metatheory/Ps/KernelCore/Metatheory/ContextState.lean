import Ps.KernelCore.Metatheory.Judgments

theorem psKernelInferenceCacheSound_contextWeaken
    (environment : PsKernelEnvironment)
    (older newer : PsKernelLocalContext)
    (cache : PsKernelExprMap)
    (hExt :
      PsKernelLocalContextExtends older newer)
    (hCache :
      PsKernelInferenceCacheSound
        environment
        older
        cache) :
    PsKernelInferenceCacheSound
      environment
      newer
      cache := by
  intro expr result hGet
  exact
    PsKernelTypingJudgment.contextWeaken
      expr
      result
      hExt
      (hCache expr result hGet)

theorem psKernelReductionCacheSound_contextWeaken
    (environment : PsKernelEnvironment)
    (older newer : PsKernelLocalContext)
    (cache : PsKernelExprMap)
    (hExt :
      PsKernelLocalContextExtends older newer)
    (hCache :
      PsKernelReductionCacheSound
        environment
        older
        cache) :
    PsKernelReductionCacheSound
      environment
      newer
      cache := by
  intro expr result hGet
  exact
    PsKernelReductionClosure.contextWeaken
      older
      expr
      result
      hExt
      (hCache expr result hGet)

theorem psKernelDefEqCacheSound_contextWeaken
    (environment : PsKernelEnvironment)
    (older newer : PsKernelLocalContext)
    (cache : PsKernelExprPairSet)
    (hExt :
      PsKernelLocalContextExtends older newer)
    (hCache :
      PsKernelDefEqCacheSound
        environment
        older
        cache) :
    PsKernelDefEqCacheSound
      environment
      newer
      cache := by
  intro left right hGet
  exact
    PsKernelDefEqJudgment.contextWeaken
      older
      left
      right
      hExt
      (hCache left right hGet)

theorem psKernelCheckerStateSemanticSound_contextWeaken
    (environment : PsKernelEnvironment)
    (older newer : PsKernelLocalContext)
    (state : PsKernelCheckerState)
    (hExt :
      PsKernelLocalContextExtends older newer)
    (hState :
      PsKernelCheckerStateSemanticSound
        environment
        older
        state) :
    PsKernelCheckerStateSemanticSound
      environment
      newer
      state := by
  unfold PsKernelCheckerStateSemanticSound at hState ⊢
  rcases hState with
    ⟨hInferOnly, hChecked, hWhnfCore, hWhnf, hUnfold, hSuccess⟩
  exact
    ⟨
      psKernelInferenceCacheSound_contextWeaken
        environment older newer state.inferOnly hExt hInferOnly,
      psKernelInferenceCacheSound_contextWeaken
        environment older newer state.checkedInfer hExt hChecked,
      psKernelReductionCacheSound_contextWeaken
        environment older newer state.whnfCore hExt hWhnfCore,
      psKernelReductionCacheSound_contextWeaken
        environment older newer state.whnf hExt hWhnf,
      psKernelReductionCacheSound_contextWeaken
        environment older newer state.unfold hExt hUnfold,
      psKernelDefEqCacheSound_contextWeaken
        environment older newer state.success hExt hSuccess
    ⟩

theorem psKernelCheckerContextWithLocal_preserves_semantic_state
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (userName : PsKernelName)
    (type : PsKernelExpr)
    (binderInfo : PsKernelBinderInfo)
    (hString : PsKernelStringEqSoundLaw)
    (hCanonical :
      PsKernelLocalContextCanonical
        context.localContext)
    (hState :
      PsKernelCheckerStateSemanticSound
        context.environment
        context.localContext
        state) :
    PsKernelCheckerStateSemanticSound
      context.environment
      (Prod.snd
        (psKernelCheckerContextWithLocal
          context
          userName
          type
          binderInfo)).localContext
      state := by
  exact
    psKernelCheckerStateSemanticSound_contextWeaken
      context.environment
      context.localContext
      (Prod.snd
        (psKernelCheckerContextWithLocal
          context
          userName
          type
          binderInfo)).localContext
      state
      (psKernelCheckerContextWithLocal_extends
        context
        userName
        type
        binderInfo
        hString
        hCanonical)
      hState

theorem psKernelCheckerContextWithLet_preserves_semantic_state
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (userName : PsKernelName)
    (type value : PsKernelExpr)
    (hString : PsKernelStringEqSoundLaw)
    (hCanonical :
      PsKernelLocalContextCanonical
        context.localContext)
    (hState :
      PsKernelCheckerStateSemanticSound
        context.environment
        context.localContext
        state) :
    PsKernelCheckerStateSemanticSound
      context.environment
      (Prod.snd
        (psKernelCheckerContextWithLet
          context
          userName
          type
          value)).localContext
      state := by
  exact
    psKernelCheckerStateSemanticSound_contextWeaken
      context.environment
      context.localContext
      (Prod.snd
        (psKernelCheckerContextWithLet
          context
          userName
          type
          value)).localContext
      state
      (psKernelCheckerContextWithLet_extends
        context
        userName
        type
        value
        hString
        hCanonical)
      hState
