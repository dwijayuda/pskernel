import Ps.KernelCore.Metatheory.Judgments

theorem psKernelReductionStep_contextWeaken
    (environment : PsKernelEnvironment)
    (older newer : PsKernelLocalContext)
    (left right : PsKernelExpr)
    (hExt : PsKernelLocalContextExtends older newer)
    (hStep :
      PsKernelReductionStep
        environment older left right) :
    PsKernelReductionStep
      environment newer left right := by
  cases hStep <;>
    constructor <;>
    try assumption
  all_goals
    apply hExt <;>
    assumption

mutual
theorem psKernelReductionClosure_contextWeaken
    (environment : PsKernelEnvironment)
    (older newer : PsKernelLocalContext)
    (left right : PsKernelExpr)
    (hExt : PsKernelLocalContextExtends older newer)
    (hReduction :
      PsKernelReductionClosure
        environment older left right) :
    PsKernelReductionClosure
      environment newer left right := by
  cases hReduction with
  | refl expr =>
      exact PsKernelReductionClosure.refl expr
  | presentationSource source query result hPresentation hStored =>
      exact
        PsKernelReductionClosure.presentationSource
          source query result
          hPresentation
          (psKernelReductionClosure_contextWeaken
            environment older newer source result hExt hStored)
  | cons first middle last hStep hRest =>
      exact
        PsKernelReductionClosure.cons
          first middle last
          (psKernelReductionStep_contextWeaken
            environment older newer first middle hExt hStep)
          (psKernelReductionClosure_contextWeaken
            environment older newer middle last hExt hRest)
  | trans first middle last hLeft hRight =>
      exact
        PsKernelReductionClosure.trans
          first middle last
          (psKernelReductionClosure_contextWeaken
            environment older newer first middle hExt hLeft)
          (psKernelReductionClosure_contextWeaken
            environment older newer middle last hExt hRight)
  | appFn leftFn rightFn arg hFn =>
      exact
        PsKernelReductionClosure.appFn
          leftFn rightFn arg
          (psKernelReductionClosure_contextWeaken
            environment older newer leftFn rightFn hExt hFn)
  | appArg fn leftArg rightArg hArg =>
      exact
        PsKernelReductionClosure.appArg
          fn leftArg rightArg
          (psKernelReductionClosure_contextWeaken
            environment older newer leftArg rightArg hExt hArg)
  | projectionMajor typeName index left right hMajor =>
      exact
        PsKernelReductionClosure.projectionMajor
          typeName index left right
          (psKernelReductionClosure_contextWeaken
            environment older newer left right hExt hMajor)
  | quotLift
      expr fnName mkName levels mkLevels args mkArgs
      major majorReduced representative fnValue
      hInitialized hHead hLift hArgs hMajor hMajorReduction
      hMkHead hMk hMkArity hMkArgs hRepresentative hFnValue =>
      exact
        PsKernelReductionClosure.quotLift
          expr fnName mkName levels mkLevels args mkArgs
          major majorReduced representative fnValue
          hInitialized hHead hLift hArgs hMajor
          (psKernelReductionClosure_contextWeaken
            environment older newer major majorReduced hExt hMajorReduction)
          hMkHead hMk hMkArity hMkArgs hRepresentative hFnValue
  | quotInd
      expr fnName mkName levels mkLevels args mkArgs
      major majorReduced representative fnValue
      hInitialized hHead hInd hArgs hMajor hMajorReduction
      hMkHead hMk hMkArity hMkArgs hRepresentative hFnValue =>
      exact
        PsKernelReductionClosure.quotInd
          expr fnName mkName levels mkLevels args mkArgs
          major majorReduced representative fnValue
          hInitialized hHead hInd hArgs hMajor
          (psKernelReductionClosure_contextWeaken
            environment older newer major majorReduced hExt hMajorReduction)
          hMkHead hMk hMkArity hMkArgs hRepresentative hFnValue
  | recursorIota
      expr recName ctorName recLevels ctorLevels recArgs majorArgs
      recursor rule major0 prepared majorReduced major
      hHead hArgs hFind hMajor hPrepared hMajorConversion
      hNormalize hCtorHead hMajorArgs hRuleMem hRuleCtor hFields hLevels =>
      exact
        PsKernelReductionClosure.recursorIota
          expr recName ctorName recLevels ctorLevels recArgs majorArgs
          recursor rule major0 prepared majorReduced major
          hHead hArgs hFind hMajor
          (psKernelDefEqJudgment_contextWeaken
            environment older newer major0 prepared hExt hPrepared)
          (psKernelDefEqJudgment_contextWeaken
            environment older newer prepared majorReduced hExt hMajorConversion)
          hNormalize hCtorHead hMajorArgs hRuleMem hRuleCtor hFields hLevels

theorem psKernelDefEqJudgment_contextWeaken
    (environment : PsKernelEnvironment)
    (older newer : PsKernelLocalContext)
    (left right : PsKernelExpr)
    (hExt : PsKernelLocalContextExtends older newer)
    (hDefEq :
      PsKernelDefEqJudgment
        environment older left right) :
    PsKernelDefEqJudgment
      environment newer left right := by
  cases hDefEq with
  | refl expr =>
      exact PsKernelDefEqJudgment.refl expr
  | symm left right h =>
      exact
        PsKernelDefEqJudgment.symm
          left right
          (psKernelDefEqJudgment_contextWeaken
            environment older newer left right hExt h)
  | presentation storedLeft storedRight queryLeft queryRight hLeft hStored hRight =>
      exact
        PsKernelDefEqJudgment.presentation
          storedLeft storedRight queryLeft queryRight
          hLeft
          (psKernelDefEqJudgment_contextWeaken
            environment older newer storedLeft storedRight hExt hStored)
          hRight
  | structural left right h =>
      exact PsKernelDefEqJudgment.structural left right h
  | reduction left right h =>
      exact
        PsKernelDefEqJudgment.reduction
          left right
          (psKernelReductionStep_contextWeaken
            environment older newer left right hExt h)
  | reductionClosure left right h =>
      exact
        PsKernelDefEqJudgment.reductionClosure
          left right
          (psKernelReductionClosure_contextWeaken
            environment older newer left right hExt h)
  | sort left right h =>
      exact PsKernelDefEqJudgment.sort left right h
  | literal left right h =>
      exact PsKernelDefEqJudgment.literal left right h
  | app leftFn leftArg rightFn rightArg hFn hArg =>
      exact
        PsKernelDefEqJudgment.app
          leftFn leftArg rightFn rightArg
          (psKernelDefEqJudgment_contextWeaken
            environment older newer leftFn rightFn hExt hFn)
          (psKernelDefEqJudgment_contextWeaken
            environment older newer leftArg rightArg hExt hArg)
  | proofIrrelevance left right leftType rightType level
      hLeft hRight hLeftType hProp hTypes =>
      exact
        PsKernelDefEqJudgment.proofIrrelevance
          left right leftType rightType level
          (PsKernelTypingJudgment.contextWeaken
            left leftType hExt hLeft)
          (PsKernelTypingJudgment.contextWeaken
            right rightType hExt hRight)
          (PsKernelTypingJudgment.contextWeaken
            leftType (PsKernelExpr.sort level) hExt hLeftType)
          hProp
          (psKernelDefEqJudgment_contextWeaken
            environment older newer leftType rightType hExt hTypes)
  | structureEta
      value valueType etaValue inductName ctorName levels
      typeArgs params fields inductInfo ctorInfo
      hValue hTypeHead hTypeArgs hInduct hNonRec hNoIndices
      hCtors hCtor hCtorInduct hParams hFields hEta =>
      exact
        PsKernelDefEqJudgment.structureEta
          value valueType etaValue inductName ctorName levels
          typeArgs params fields inductInfo ctorInfo
          (PsKernelTypingJudgment.contextWeaken
            value valueType hExt hValue)
          hTypeHead hTypeArgs hInduct hNonRec hNoIndices
          hCtors hCtor hCtorInduct hParams hFields hEta
  | metadataLeft metadata left right h =>
      exact
        PsKernelDefEqJudgment.metadataLeft
          metadata left right
          (psKernelDefEqJudgment_contextWeaken
            environment older newer left right hExt h)
  | metadataRight metadata left right h =>
      exact
        PsKernelDefEqJudgment.metadataRight
          metadata left right
          (psKernelDefEqJudgment_contextWeaken
            environment older newer left right hExt h)
end


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
    psKernelReductionClosure_contextWeaken
      environment
      older
      newer
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
    psKernelDefEqJudgment_contextWeaken
      environment
      older
      newer
      left
      right
      hExt
      (hCache left right hGet)

theorem psKernelInferOnlyCacheIsolated_contextWeaken
    (environment : PsKernelEnvironment)
    (older newer : PsKernelLocalContext)
    (cache : PsKernelExprMap)
    (_hExt : PsKernelLocalContextExtends older newer)
    (_hCache :
      PsKernelInferOnlyCacheIsolated
        environment
        older
        cache) :
    PsKernelInferOnlyCacheIsolated
      environment
      newer
      cache := by
  trivial

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
      psKernelInferOnlyCacheIsolated_contextWeaken
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


def PsKernelCheckerConfigurationSound
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState) : Prop :=
  PsKernelEnvironmentIndexRefines
      context.environment ∧
  PsKernelLocalContextFreshBound
      context.localContext
      state.nextFresh ∧
  PsKernelCheckerStateSemanticSound
      context.environment
      context.localContext
      state

theorem psKernelCheckerStateFreshName_preserves_semantic_state
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (base : PsKernelName)
    (hState :
      PsKernelCheckerStateSemanticSound
        context.environment
        context.localContext
        state) :
    PsKernelCheckerStateSemanticSound
      context.environment
      context.localContext
      (Prod.snd
        (psKernelCheckerStateFreshName
          state
          base)) := by
  simpa [
    psKernelCheckerStateFreshName,
    PsKernelCheckerStateSemanticSound
  ] using hState

theorem psKernelCheckerStateFreshName_preserves_configuration
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (base : PsKernelName)
    (hConfig :
      PsKernelCheckerConfigurationSound
        context
        state) :
    PsKernelCheckerConfigurationSound
      context
      (Prod.snd
        (psKernelCheckerStateFreshName
          state
          base)) := by
  rcases hConfig with
    ⟨hIndex, hBound, hState⟩
  refine
    ⟨
      hIndex,
      psKernelLocalContextFreshBound_mono
        context.localContext
        state.nextFresh
        (Nat.succ state.nextFresh)
        hBound
        (Nat.le_succ state.nextFresh),
      ?_
    ⟩
  simpa [psKernelCheckerStateFreshName] using
    psKernelCheckerStateFreshName_preserves_semantic_state
      context
      state
      base
      hState

theorem psKernelCheckerStateFreshName_absent_of_configuration
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (base fresh : PsKernelName)
    (hString : PsKernelStringEqSoundLaw)
    (hConfig :
      PsKernelCheckerConfigurationSound
        context
        state)
    (hFresh :
      psKernelCheckerStateFreshName
          state
          base =
        Prod.mk fresh nextState) :
    psKernelLocalContextFind
        context.localContext
        fresh =
      Option.none := by
  rcases hConfig with
    ⟨_hIndex, hBound, _hState⟩
  unfold psKernelCheckerStateFreshName at hFresh
  simp at hFresh
  rcases hFresh with ⟨rfl, _⟩
  exact
    psKernelLocalContextFreshBound_name_absent
      context.localContext
      state.nextFresh
      base
      hString
      hBound


theorem psKernelCheckerFreshLocal_preserves_configuration
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (userName : PsKernelName)
    (type : PsKernelExpr)
    (binderInfo : PsKernelBinderInfo)
    (hString : PsKernelStringEqSoundLaw)
    (hConfig :
      PsKernelCheckerConfigurationSound
        context
        state) :
    let freshResult :=
      psKernelCheckerStateFreshName
        state
        userName
    let fresh :=
      Prod.fst freshResult
    let nextState :=
      Prod.snd freshResult
    let nextLocal :=
      psKernelLocalContextAddLocal
        context.localContext
        fresh
        userName
        type
        binderInfo
    let nextContext :=
      psKernelCheckerContextWithLocalContext
        context
        nextLocal
    PsKernelCheckerConfigurationSound
      nextContext
      nextState := by
  intro freshResult fresh nextState nextLocal nextContext
  rcases hConfig with
    ⟨hIndex, hBound, hState⟩
  have hStateOld :
      PsKernelCheckerStateSemanticSound
        context.environment
        context.localContext
        nextState := by
    simpa [
      freshResult,
      nextState
    ] using
      psKernelCheckerStateFreshName_preserves_semantic_state
        context
        state
        userName
        hState
  have hExt :
      PsKernelLocalContextExtends
        context.localContext
        nextLocal := by
    simpa [
      freshResult,
      fresh,
      nextState,
      nextLocal,
      psKernelCheckerStateFreshName
    ] using
      psKernelLocalContextAddLocal_extends_freshBound
        context.localContext
        state.nextFresh
        userName
        userName
        type
        binderInfo
        hString
        hBound
  have hStateNew :
      PsKernelCheckerStateSemanticSound
        context.environment
        nextLocal
        nextState :=
    psKernelCheckerStateSemanticSound_contextWeaken
      context.environment
      context.localContext
      nextLocal
      nextState
      hExt
      hStateOld
  have hBoundNew :
      PsKernelLocalContextFreshBound
        nextLocal
        nextState.nextFresh := by
    simpa [
      freshResult,
      fresh,
      nextState,
      nextLocal,
      psKernelCheckerStateFreshName
    ] using
      psKernelLocalContextAddLocal_preserves_freshBound
        context.localContext
        state.nextFresh
        userName
        userName
        type
        binderInfo
        hBound
  simpa [
    PsKernelCheckerConfigurationSound,
    nextContext,
    psKernelCheckerContextWithLocalContext
  ] using
    (show
      PsKernelEnvironmentIndexRefines context.environment ∧
        PsKernelLocalContextFreshBound nextLocal nextState.nextFresh ∧
        PsKernelCheckerStateSemanticSound
          context.environment
          nextLocal
          nextState
      from ⟨hIndex, hBoundNew, hStateNew⟩)

theorem psKernelCheckerFreshLet_preserves_configuration
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (userName : PsKernelName)
    (type value : PsKernelExpr)
    (hString : PsKernelStringEqSoundLaw)
    (hConfig :
      PsKernelCheckerConfigurationSound
        context
        state) :
    let freshResult :=
      psKernelCheckerStateFreshName
        state
        userName
    let fresh :=
      Prod.fst freshResult
    let nextState :=
      Prod.snd freshResult
    let nextLocal :=
      psKernelLocalContextAddLet
        context.localContext
        fresh
        userName
        type
        value
    let nextContext :=
      psKernelCheckerContextWithLocalContext
        context
        nextLocal
    PsKernelCheckerConfigurationSound
      nextContext
      nextState := by
  intro freshResult fresh nextState nextLocal nextContext
  rcases hConfig with
    ⟨hIndex, hBound, hState⟩
  have hStateOld :
      PsKernelCheckerStateSemanticSound
        context.environment
        context.localContext
        nextState := by
    simpa [
      freshResult,
      nextState
    ] using
      psKernelCheckerStateFreshName_preserves_semantic_state
        context
        state
        userName
        hState
  have hExt :
      PsKernelLocalContextExtends
        context.localContext
        nextLocal := by
    simpa [
      freshResult,
      fresh,
      nextState,
      nextLocal,
      psKernelCheckerStateFreshName
    ] using
      psKernelLocalContextAddLet_extends_freshBound
        context.localContext
        state.nextFresh
        userName
        userName
        type
        value
        hString
        hBound
  have hStateNew :
      PsKernelCheckerStateSemanticSound
        context.environment
        nextLocal
        nextState :=
    psKernelCheckerStateSemanticSound_contextWeaken
      context.environment
      context.localContext
      nextLocal
      nextState
      hExt
      hStateOld
  have hBoundNew :
      PsKernelLocalContextFreshBound
        nextLocal
        nextState.nextFresh := by
    simpa [
      freshResult,
      fresh,
      nextState,
      nextLocal,
      psKernelCheckerStateFreshName
    ] using
      psKernelLocalContextAddLet_preserves_freshBound
        context.localContext
        state.nextFresh
        userName
        userName
        type
        value
        hBound
  simpa [
    PsKernelCheckerConfigurationSound,
    nextContext,
    psKernelCheckerContextWithLocalContext
  ] using
    (show
      PsKernelEnvironmentIndexRefines context.environment ∧
        PsKernelLocalContextFreshBound nextLocal nextState.nextFresh ∧
        PsKernelCheckerStateSemanticSound
          context.environment
          nextLocal
          nextState
      from ⟨hIndex, hBoundNew, hStateNew⟩)


theorem psKernelCheckerContextWithEagerReduce_preserves_configuration
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (eagerReduce : Bool)
    (hConfig :
      PsKernelCheckerConfigurationSound context state) :
    PsKernelCheckerConfigurationSound
      (psKernelCheckerContextWithEagerReduce
        context
        eagerReduce)
      state := by
  rcases hConfig with
    ⟨hIndex, hBound, hState⟩
  exact
    ⟨
      hIndex,
      hBound,
      hState
    ⟩

theorem psKernelCheckerContextWithNativeEvaluator_preserves_configuration
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (nativeEvaluator : Option PsKernelNativeEvaluator)
    (hConfig :
      PsKernelCheckerConfigurationSound context state) :
    PsKernelCheckerConfigurationSound
      (psKernelCheckerContextWithNativeEvaluator
        context
        nativeEvaluator)
      state := by
  rcases hConfig with
    ⟨hIndex, hBound, hState⟩
  exact
    ⟨
      hIndex,
      hBound,
      hState
    ⟩

theorem psKernelCheckerContextEnterRecDepth_preserves_semantic_view
    (context nextContext : PsKernelCheckerContext)
    (hEnter :
      psKernelCheckerContextEnterRecDepth context =
        Except.ok nextContext) :
    nextContext.environment = context.environment ∧
      nextContext.localContext = context.localContext := by
  unfold psKernelCheckerContextEnterRecDepth at hEnter
  cases hUnlimited :
      Nat.beq context.maxRecDepth 0 with
  | true =>
      rw [hUnlimited] at hEnter
      simp at hEnter
      subst nextContext
      exact ⟨rfl, rfl⟩
  | false =>
      rw [hUnlimited] at hEnter
      simp only [Bool.false_eq_true, if_false] at hEnter
      cases hTooDeep :
          psKernelNatGt
            (Nat.add context.recDepth 1)
            (Nat.mul
              context.maxRecDepth
              psKernelRecDepthFactor) with
      | true =>
          rw [hTooDeep] at hEnter
          simp at hEnter
      | false =>
          rw [hTooDeep] at hEnter
          simp at hEnter
          subst nextContext
          exact ⟨rfl, rfl⟩


theorem psKernelTypingJudgment_enterRecDepth_back
    (context nextContext : PsKernelCheckerContext)
    (expr type : PsKernelExpr)
    (hEnter :
      psKernelCheckerContextEnterRecDepth context =
        Except.ok nextContext)
    (hTyping :
      PsKernelTypingJudgment
        nextContext.environment
        nextContext.localContext
        expr
        type) :
    PsKernelTypingJudgment
      context.environment
      context.localContext
      expr
      type := by
  have hView :=
    psKernelCheckerContextEnterRecDepth_preserves_semantic_view
      context nextContext hEnter
  rw [hView.1, hView.2] at hTyping
  exact hTyping

theorem psKernelDefEqJudgment_enterRecDepth_back
    (context nextContext : PsKernelCheckerContext)
    (left right : PsKernelExpr)
    (hEnter :
      psKernelCheckerContextEnterRecDepth context =
        Except.ok nextContext)
    (hDefEq :
      PsKernelDefEqJudgment
        nextContext.environment
        nextContext.localContext
        left
        right) :
    PsKernelDefEqJudgment
      context.environment
      context.localContext
      left
      right := by
  have hView :=
    psKernelCheckerContextEnterRecDepth_preserves_semantic_view
      context nextContext hEnter
  rw [hView.1, hView.2] at hDefEq
  exact hDefEq

theorem psKernelReductionClosure_enterRecDepth_back
    (context nextContext : PsKernelCheckerContext)
    (expr result : PsKernelExpr)
    (hEnter :
      psKernelCheckerContextEnterRecDepth context =
        Except.ok nextContext)
    (hReduction :
      PsKernelReductionClosure
        nextContext.environment
        nextContext.localContext
        expr
        result) :
    PsKernelReductionClosure
      context.environment
      context.localContext
      expr
      result := by
  have hView :=
    psKernelCheckerContextEnterRecDepth_preserves_semantic_view
      context nextContext hEnter
  rw [hView.1, hView.2] at hReduction
  exact hReduction

theorem psKernelCheckerConfigurationSound_enterRecDepth_back
    (context nextContext : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (hEnter :
      psKernelCheckerContextEnterRecDepth context =
        Except.ok nextContext)
    (hSound :
      PsKernelCheckerConfigurationSound
        nextContext
        state) :
    PsKernelCheckerConfigurationSound
      context
      state := by
  have hView :=
    psKernelCheckerContextEnterRecDepth_preserves_semantic_view
      context nextContext hEnter
  unfold PsKernelCheckerConfigurationSound at hSound ⊢
  rw [hView.1, hView.2] at hSound
  exact hSound


theorem psKernelCheckerContextEnterRecDepth_preserves_configuration
    (context nextContext : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (hConfig :
      PsKernelCheckerConfigurationSound context state)
    (hEnter :
      psKernelCheckerContextEnterRecDepth context =
        Except.ok nextContext) :
    PsKernelCheckerConfigurationSound
      nextContext
      state := by
  unfold psKernelCheckerContextEnterRecDepth at hEnter
  cases hUnlimited :
      Nat.beq context.maxRecDepth 0 with
  | true =>
      rw [hUnlimited] at hEnter
      simp at hEnter
      subst nextContext
      exact hConfig
  | false =>
      rw [hUnlimited] at hEnter
      simp only [Bool.false_eq_true, if_false] at hEnter
      cases hTooDeep :
          psKernelNatGt
            (Nat.add context.recDepth 1)
            (Nat.mul
              context.maxRecDepth
              psKernelRecDepthFactor) with
      | true =>
          rw [hTooDeep] at hEnter
          simp at hEnter
      | false =>
          rw [hTooDeep] at hEnter
          simp at hEnter
          subst nextContext
          unfold PsKernelCheckerConfigurationSound at hConfig ⊢
          simpa using hConfig


theorem psKernelCheckerConfigurationSound_transport
    (source target : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (hEnvironment :
      source.environment = target.environment)
    (hLocal :
      source.localContext = target.localContext)
    (hSound :
      PsKernelCheckerConfigurationSound
        source
        state) :
    PsKernelCheckerConfigurationSound
      target
      state := by
  unfold PsKernelCheckerConfigurationSound at hSound ⊢
  rw [← hEnvironment, ← hLocal]
  exact hSound


theorem psKernelCheckerStateExitLocalScope_preserves_configuration
    (context : PsKernelCheckerContext)
    (parent child : PsKernelCheckerState)
    (hParent :
      PsKernelCheckerConfigurationSound
        context
        parent) :
    PsKernelCheckerConfigurationSound
      context
      (psKernelCheckerStateExitLocalScope
        parent
        child) := by
  rcases hParent with
    ⟨hIndex, hBound, hState⟩
  refine
    ⟨
      hIndex,
      psKernelLocalContextFreshBound_mono
        context.localContext
        parent.nextFresh
        (Nat.max parent.nextFresh child.nextFresh)
        hBound
        (Nat.le_max_left
          parent.nextFresh
          child.nextFresh),
      ?_
    ⟩
  unfold PsKernelCheckerStateSemanticSound at hState ⊢
  simpa [psKernelCheckerStateExitLocalScope] using hState
