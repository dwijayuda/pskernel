import Ps.KernelCore.Checker.Reduction.WhnfCore
import Ps.KernelCore.Metatheory.Judgments

theorem psKernelWhnfCountLambdasWithFuel_zero
    (expr : PsKernelExpr)
    (argCount count : Nat) :
    psKernelWhnfCountLambdasWithFuel
        0 expr argCount count =
      Prod.mk expr count := by
  rfl

theorem psKernelWhnfCoreFinish_cheap
    (original result : PsKernelExpr)
    (state : PsKernelCheckerState) :
    psKernelWhnfCoreFinish original true result state =
      Except.ok (Prod.mk result state) := by
  rfl

theorem psKernelWhnfFinish_result
    (original result : PsKernelExpr)
    (state : PsKernelCheckerState) :
    Prod.fst
      (match psKernelWhnfFinish original result state with
       | Except.ok pair => pair
       | Except.error _ => Prod.mk result state) =
      result := by
  cases hEligible :
      psKernelWhnfCacheEligible original <;>
    simp [
      psKernelWhnfFinish,
      hEligible
    ]

theorem psKernelWhnfCoreWithFuel_zero
    (publicWhnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (reduceRecursor :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Bool ->
      Bool ->
      Except String
        (Prod (Option PsKernelExpr) PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (expr : PsKernelExpr)
    (cheapRec cheapProj : Bool) :
    psKernelWhnfCoreWithFuel
        0 publicWhnf reduceRecursor
        context state expr cheapRec cheapProj =
      Except.error "kernel reduction budget exhausted" := by
  rfl


theorem psKernelWhnfCoreWithFuel_let_zeta
    (remaining : Nat)
    (publicWhnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (reduceRecursor :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Bool ->
      Bool ->
      Except String
        (Prod (Option PsKernelExpr) PsKernelCheckerState))
    (context nextContext : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (name : PsKernelName)
    (type value body result : PsKernelExpr)
    (nondep cheapRec cheapProj : Bool)
    (hDepth :
      psKernelCheckerContextEnterRecDepth context =
        Except.ok nextContext)
    (hCache :
      psKernelExprMapGet
          state.whnfCore
          (PsKernelExpr.letE name type value body nondep) =
        Option.none)
    (hReduce :
      psKernelWhnfCoreWithFuel
          remaining
          publicWhnf
          reduceRecursor
          nextContext
          state
          (psKernelExprInstantiate1 body value)
          cheapRec
          cheapProj =
        Except.ok (Prod.mk result nextState)) :
    psKernelWhnfCoreWithFuel
        (Nat.succ remaining)
        publicWhnf
        reduceRecursor
        context
        state
        (PsKernelExpr.letE name type value body nondep)
        cheapRec
        cheapProj =
      psKernelWhnfCoreFinish
        (PsKernelExpr.letE name type value body nondep)
        (Bool.or cheapRec cheapProj)
        result
        nextState := by
  cases hEligible :
      psKernelWhnfCacheEligible
        (PsKernelExpr.letE name type value body nondep) <;>
    simp [
      psKernelWhnfCoreWithFuel,
      hDepth,
      hEligible,
      hCache,
      hReduce
    ]

theorem psKernelWhnfCoreWithFuel_fvar_let
    (remaining : Nat)
    (publicWhnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (reduceRecursor :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Bool ->
      Bool ->
      Except String
        (Prod (Option PsKernelExpr) PsKernelCheckerState))
    (context nextContext : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (name : PsKernelName)
    (declaration : PsKernelLocalDecl)
    (value result : PsKernelExpr)
    (cheapRec cheapProj : Bool)
    (hDepth :
      psKernelCheckerContextEnterRecDepth context =
        Except.ok nextContext)
    (hFind :
      psKernelLocalContextFind
          nextContext.localContext
          name =
        Option.some declaration)
    (hValue :
      psKernelLocalDeclValue declaration =
        Option.some value)
    (hReduce :
      psKernelWhnfCoreWithFuel
          remaining
          publicWhnf
          reduceRecursor
          nextContext
          state
          value
          cheapRec
          cheapProj =
        Except.ok (Prod.mk result nextState)) :
    psKernelWhnfCoreWithFuel
        (Nat.succ remaining)
        publicWhnf
        reduceRecursor
        context
        state
        (PsKernelExpr.fvar name)
        cheapRec
        cheapProj =
      Except.ok (Prod.mk result nextState) := by
  simp [
    psKernelWhnfCoreWithFuel,
    hDepth,
    hFind,
    hValue,
    hReduce
  ]


theorem psKernelWhnfCoreFinish_preserves_semantic_sound
    (environment : PsKernelEnvironment)
    (localContext : PsKernelLocalContext)
    (original result : PsKernelExpr)
    (cheapProj : Bool)
    (state : PsKernelCheckerState)
    (hInsert : PsKernelReductionCacheInsertLaw)
    (hState :
      PsKernelCheckerStateSemanticSound
        environment
        localContext
        state)
    (hReduction :
      PsKernelReductionClosure
        environment
        localContext
        original
        result) :
    ∃ nextState : PsKernelCheckerState,
      psKernelWhnfCoreFinish
          original
          cheapProj
          result
          state =
        Except.ok (Prod.mk result nextState) ∧
      PsKernelCheckerStateSemanticSound
        environment
        localContext
        nextState := by
  unfold PsKernelCheckerStateSemanticSound at hState
  rcases hState with
    ⟨hInferOnly, hChecked, hWhnfCore, hWhnf, hUnfold, hSuccess⟩
  cases cheapProj with
  | true =>
      refine ⟨state, ?_, ?_⟩
      · rfl
      · exact
          ⟨hInferOnly, hChecked, hWhnfCore, hWhnf, hUnfold, hSuccess⟩
  | false =>
      cases hEligible :
          psKernelWhnfCacheEligible original with
      | false =>
          refine ⟨state, ?_, ?_⟩
          · simp [psKernelWhnfCoreFinish, hEligible]
          · exact
              ⟨hInferOnly, hChecked, hWhnfCore, hWhnf, hUnfold, hSuccess⟩
      | true =>
          let nextCache :=
            psKernelExprMapInsert
              state.whnfCore
              original
              result
          let nextState :=
            psKernelCheckerStateWithWhnfCore
              state
              nextCache
          refine ⟨nextState, ?_, ?_⟩
          · simp [
              psKernelWhnfCoreFinish,
              hEligible,
              nextCache,
              nextState
            ]
          · simpa [
              nextState,
              psKernelCheckerStateWithWhnfCore,
              PsKernelCheckerStateSemanticSound
            ] using
              (show
                PsKernelInferOnlyCacheIsolated
                      environment localContext state.inferOnly ∧
                  PsKernelInferenceCacheSound
                      environment localContext state.checkedInfer ∧
                  PsKernelReductionCacheSound
                      environment localContext
                      (psKernelExprMapInsert
                        state.whnfCore
                        original
                        result) ∧
                  PsKernelReductionCacheSound
                      environment localContext state.whnf ∧
                  PsKernelReductionCacheSound
                      environment localContext state.unfold ∧
                  PsKernelDefEqCacheSound
                      environment localContext state.success
                from
                  ⟨
                    hInferOnly,
                    hChecked,
                    hInsert
                      environment
                      localContext
                      state.whnfCore
                      original
                      result
                      hWhnfCore
                      hReduction,
                    hWhnf,
                    hUnfold,
                    hSuccess
                  ⟩)
theorem psKernelWhnfFinish_preserves_semantic_sound
    (environment : PsKernelEnvironment)
    (localContext : PsKernelLocalContext)
    (original result : PsKernelExpr)
    (state : PsKernelCheckerState)
    (hInsert : PsKernelReductionCacheInsertLaw)
    (hState :
      PsKernelCheckerStateSemanticSound
        environment
        localContext
        state)
    (hReduction :
      PsKernelReductionClosure
        environment
        localContext
        original
        result) :
    ∃ nextState : PsKernelCheckerState,
      psKernelWhnfFinish
          original
          result
          state =
        Except.ok (Prod.mk result nextState) ∧
      PsKernelCheckerStateSemanticSound
        environment
        localContext
        nextState := by
  unfold PsKernelCheckerStateSemanticSound at hState
  rcases hState with
    ⟨hInferOnly, hChecked, hWhnfCore, hWhnf, hUnfold, hSuccess⟩
  cases hEligible :
      psKernelWhnfCacheEligible original with
  | false =>
      refine ⟨state, ?_, ?_⟩
      · simp [psKernelWhnfFinish, hEligible]
      · exact
          ⟨hInferOnly, hChecked, hWhnfCore, hWhnf, hUnfold, hSuccess⟩
  | true =>
      let nextCache :=
        psKernelExprMapInsert
          state.whnf
          original
          result
      let nextState :=
        psKernelCheckerStateWithWhnf
          state
          nextCache
      refine ⟨nextState, ?_, ?_⟩
      · simp [
          psKernelWhnfFinish,
          hEligible,
          nextCache,
          nextState
        ]
      · simpa [
          nextState,
          psKernelCheckerStateWithWhnf,
          PsKernelCheckerStateSemanticSound
        ] using
          (show
            PsKernelInferOnlyCacheIsolated
                  environment localContext state.inferOnly ∧
              PsKernelInferenceCacheSound
                  environment localContext state.checkedInfer ∧
              PsKernelReductionCacheSound
                  environment localContext state.whnfCore ∧
              PsKernelReductionCacheSound
                  environment localContext
                  (psKernelExprMapInsert
                    state.whnf
                    original
                    result) ∧
              PsKernelReductionCacheSound
                  environment localContext state.unfold ∧
              PsKernelDefEqCacheSound
                  environment localContext state.success
            from
              ⟨
                hInferOnly,
                hChecked,
                hWhnfCore,
                hInsert
                  environment
                  localContext
                  state.whnf
                  original
                  result
                  hWhnf
                  hReduction,
                hUnfold,
                hSuccess
              ⟩)



theorem psKernelWhnfCoreFinish_fvar_not_cached
    (state : PsKernelCheckerState)
    (name : PsKernelName)
    (result : PsKernelExpr)
    (cheapProj : Bool) :
    psKernelWhnfCoreFinish
        (PsKernelExpr.fvar name)
        cheapProj
        result
        state =
      Except.ok (Prod.mk result state) := by
  cases cheapProj <;> rfl

theorem psKernelWhnfFinish_fvar_not_cached
    (state : PsKernelCheckerState)
    (name : PsKernelName)
    (result : PsKernelExpr) :
    psKernelWhnfFinish
        (PsKernelExpr.fvar name)
        result
        state =
      Except.ok (Prod.mk result state) := by
  rfl
