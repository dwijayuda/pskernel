import Ps.KernelCore.Metatheory.Judgments

theorem psKernelInferCore_sort_refines_typing
    (remaining : Nat)
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
    (context nextContext : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (level : PsKernelLevel)
    (inferOnly : Bool)
    (hCache :
      psKernelExprMapGet
          (if inferOnly then state.inferOnly else state.checkedInfer)
          (PsKernelExpr.sort level) =
        Option.none)
    (hDepth :
      psKernelCheckerContextEnterRecDepth context =
        Except.ok nextContext) :
    ∃ nextState : PsKernelCheckerState,
      psKernelInferCoreWithFuel
          (Nat.succ remaining)
          whnf
          defeq
          context
          state
          (PsKernelExpr.sort level)
          inferOnly =
        Except.ok
          (Prod.mk
            (PsKernelExpr.sort (PsKernelLevel.succ level))
            nextState) ∧
      PsKernelTypingJudgment
        nextContext.environment
        nextContext.localContext
        (PsKernelExpr.sort level)
        (PsKernelExpr.sort (PsKernelLevel.succ level)) := by
  refine ⟨
    psKernelCacheInferResult
      state
      inferOnly
      (PsKernelExpr.sort level)
      (PsKernelExpr.sort (PsKernelLevel.succ level)),
    ?_,
    PsKernelTypingJudgment.sort level
  ⟩
  cases inferOnly with
  | false =>
      simp at hCache
      simp [
        psKernelInferCoreWithFuel,
        psKernelInferCacheEligible,
        hCache,
        hDepth
      ]
  | true =>
      simp at hCache
      simp [
        psKernelInferCoreWithFuel,
        psKernelInferCacheEligible,
        hCache,
        hDepth
      ]

theorem psKernelInferCore_string_literal_refines_typing
    (remaining : Nat)
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
    (context nextContext : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (value : String)
    (inferOnly : Bool)
    (hDepth :
      psKernelCheckerContextEnterRecDepth context =
        Except.ok nextContext) :
    psKernelInferCoreWithFuel
        (Nat.succ remaining)
        whnf
        defeq
        context
        state
        (PsKernelExpr.lit (PsKernelLiteral.str value))
        inferOnly =
      Except.ok
        (Prod.mk
          (PsKernelExpr.const psKernelStringName List.nil)
          state) ∧
    PsKernelTypingJudgment
      nextContext.environment
      nextContext.localContext
      (PsKernelExpr.lit (PsKernelLiteral.str value))
      (PsKernelExpr.const psKernelStringName List.nil) := by
  constructor
  · simp [
      psKernelInferCoreWithFuel,
      psKernelInferCacheEligible,
      psKernelCacheInferResult,
      hDepth
    ]
  · exact PsKernelTypingJudgment.stringLiteral value

theorem psKernelInferCore_nat_literal_refines_typing
    (remaining : Nat)
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
    (context nextContext : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (value : Nat)
    (inferOnly : Bool)
    (hDepth :
      psKernelCheckerContextEnterRecDepth context =
        Except.ok nextContext)
    (hNat :
      psKernelCheckNatSize nextContext.maxNatSize value =
        Except.ok Unit.unit) :
    psKernelInferCoreWithFuel
        (Nat.succ remaining)
        whnf
        defeq
        context
        state
        (PsKernelExpr.lit (PsKernelLiteral.nat value))
        inferOnly =
      Except.ok
        (Prod.mk
          (PsKernelExpr.const psKernelNatName List.nil)
          state) ∧
    PsKernelTypingJudgment
      nextContext.environment
      nextContext.localContext
      (PsKernelExpr.lit (PsKernelLiteral.nat value))
      (PsKernelExpr.const psKernelNatName List.nil) := by
  constructor
  · simp [
      psKernelInferCoreWithFuel,
      psKernelInferCacheEligible,
      psKernelCacheInferResult,
      hDepth,
      hNat
    ]
  · exact PsKernelTypingJudgment.natLiteral value

theorem psKernelInferCore_fvar_refines_typing
    (remaining : Nat)
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
    (context nextContext : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (name : PsKernelName)
    (declaration : PsKernelLocalDecl)
    (inferOnly : Bool)
    (hCache :
      psKernelExprMapGet
          (if inferOnly then state.inferOnly else state.checkedInfer)
          (PsKernelExpr.fvar name) =
        Option.none)
    (hDepth :
      psKernelCheckerContextEnterRecDepth context =
        Except.ok nextContext)
    (hFind :
      psKernelLocalContextFind nextContext.localContext name =
        Option.some declaration) :
    ∃ nextState : PsKernelCheckerState,
      psKernelInferCoreWithFuel
          (Nat.succ remaining)
          whnf
          defeq
          context
          state
          (PsKernelExpr.fvar name)
          inferOnly =
        Except.ok
          (Prod.mk
            (psKernelLocalDeclType declaration)
            nextState) ∧
      PsKernelTypingJudgment
        nextContext.environment
        nextContext.localContext
        (PsKernelExpr.fvar name)
        (psKernelLocalDeclType declaration) := by
  refine ⟨
    psKernelCacheInferResult
      state
      inferOnly
      (PsKernelExpr.fvar name)
      (psKernelLocalDeclType declaration),
    ?_,
    PsKernelTypingJudgment.fvar name declaration hFind
  ⟩
  cases inferOnly with
  | false =>
      simp at hCache
      simp [
        psKernelInferCoreWithFuel,
        psKernelInferCacheEligible,
        hCache,
        hDepth,
        hFind
      ]
  | true =>
      simp at hCache
      simp [
        psKernelInferCoreWithFuel,
        psKernelInferCacheEligible,
        hCache,
        hDepth,
        hFind
      ]

theorem psKernelInferCore_const_inferOnly_refines_typing
    (remaining : Nat)
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
    (context nextContext : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (name : PsKernelName)
    (levels : List PsKernelLevel)
    (info : PsKernelConstantInfo)
    (hLookupSound :
      PsKernelEnvironmentLookupSound nextContext.environment)
    (hCache :
      psKernelExprMapGet
          state.inferOnly
          (PsKernelExpr.const name levels) =
        Option.none)
    (hDepth :
      psKernelCheckerContextEnterRecDepth context =
        Except.ok nextContext)
    (hFind :
      psKernelEnvironmentFind nextContext.environment name =
        Option.some info)
    (hLevels :
      psKernelNameListLength
          (psKernelConstantInfoLevelParams info) =
        psKernelLevelListLength levels) :
    ∃ nextState : PsKernelCheckerState,
      psKernelInferCoreWithFuel
          (Nat.succ remaining)
          whnf
          defeq
          context
          state
          (PsKernelExpr.const name levels)
          true =
        Except.ok
          (Prod.mk
            (psKernelExprInstantiateLevelParams
              (psKernelConstantInfoType info)
              (psKernelConstantInfoLevelParams info)
              levels)
            nextState) ∧
      PsKernelTypingJudgment
        nextContext.environment
        nextContext.localContext
        (PsKernelExpr.const name levels)
        (psKernelExprInstantiateLevelParams
          (psKernelConstantInfoType info)
          (psKernelConstantInfoLevelParams info)
          levels) := by
  refine ⟨
    psKernelCacheInferResult
      state
      true
      (PsKernelExpr.const name levels)
      (psKernelExprInstantiateLevelParams
        (psKernelConstantInfoType info)
        (psKernelConstantInfoLevelParams info)
        levels),
    ?_,
    ?_
  ⟩
  · simp [
      psKernelInferCoreWithFuel,
      psKernelInferCacheEligible,
      hCache,
      hDepth,
      hFind,
      hLevels
    ]
  · exact
      PsKernelTypingJudgment.const
        name
        levels
        info
        (hLookupSound name info hFind)
        hLevels


theorem psKernelInferCore_app_checked_refines_typing
    (remaining : Nat)
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
    (context nextContext : PsKernelCheckerContext)
    (state fnState forallState argState : PsKernelCheckerState)
    (fn arg fnType argType : PsKernelExpr)
    (view : PsKernelForallView)
    (hDepth :
      psKernelCheckerContextEnterRecDepth context =
        Except.ok nextContext)
    (hFn :
      psKernelInferCoreWithFuel
          remaining
          whnf
          defeq
          nextContext
          state
          fn
          false =
        Except.ok (Prod.mk fnType fnState))
    (hForall :
      psKernelEnsureForallWith
          whnf
          nextContext
          fnState
          fnType =
        Except.ok (Prod.mk view forallState))
    (hArg :
      psKernelInferCoreWithFuel
          remaining
          whnf
          defeq
          nextContext
          forallState
          arg
          false =
        Except.ok (Prod.mk argType argState))
    (hEq :
      psKernelExprEq argType view.domain = true)
    (hFnTyping :
      PsKernelTypingJudgment
        nextContext.environment
        nextContext.localContext
        fn
        fnType)
    (hFnType :
      PsKernelDefEqJudgment
        nextContext.environment
        nextContext.localContext
        fnType
        (PsKernelExpr.forallE
          view.name
          view.domain
          view.body
          view.binderInfo))
    (hArgTyping :
      PsKernelTypingJudgment
        nextContext.environment
        nextContext.localContext
        arg
        argType)
    (hArgType :
      PsKernelDefEqJudgment
        nextContext.environment
        nextContext.localContext
        argType
        view.domain) :
    psKernelInferCoreWithFuel
        (Nat.succ remaining)
        whnf
        defeq
        context
        state
        (PsKernelExpr.app fn arg)
        false =
      Except.ok
        (Prod.mk
          (psKernelExprInstantiate1 view.body arg)
          argState) ∧
    PsKernelTypingJudgment
      nextContext.environment
      nextContext.localContext
      (PsKernelExpr.app fn arg)
      (psKernelExprInstantiate1 view.body arg) := by
  constructor
  · simp [
      psKernelInferCoreWithFuel,
      psKernelInferCacheEligible,
      psKernelCacheInferResult,
      hDepth,
      hFn,
      hForall,
      hArg,
      hEq
    ]
  · exact
      PsKernelTypingJudgment.app
        fn
        arg
        fnType
        argType
        view.domain
        view.body
        view.name
        view.binderInfo
        hFnTyping
        hFnType
        hArgTyping
        hArgType


theorem psKernelInferCore_cache_hit_refines_typing
    (remaining : Nat)
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
    (context nextContext : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (expr result : PsKernelExpr)
    (inferOnly : Bool)
    (hEligible :
      psKernelInferCacheEligible inferOnly expr = true)
    (hCache :
      psKernelExprMapGet
          (if inferOnly then state.inferOnly else state.checkedInfer)
          expr =
        Option.some result)
    (hDepth :
      psKernelCheckerContextEnterRecDepth context =
        Except.ok nextContext)
    (hSound :
      PsKernelInferenceCacheSound
        context.environment
        context.localContext
        (if inferOnly then state.inferOnly else state.checkedInfer)) :
    psKernelInferCoreWithFuel
        (Nat.succ remaining)
        whnf
        defeq
        context
        state
        expr
        inferOnly =
      Except.ok (Prod.mk result state) ∧
    PsKernelTypingJudgment
      context.environment
      context.localContext
      expr
      result := by
  constructor
  · simp [
      psKernelInferCoreWithFuel,
      hEligible,
      hCache,
      hDepth
    ]
  · exact hSound expr result hCache


theorem psKernelInferCore_app_checked_defeq_refines_typing
    (remaining : Nat)
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
    (context nextContext : PsKernelCheckerContext)
    (state fnState forallState argState eqState : PsKernelCheckerState)
    (fn arg fnType argType : PsKernelExpr)
    (view : PsKernelForallView)
    (hDepth :
      psKernelCheckerContextEnterRecDepth context =
        Except.ok nextContext)
    (hFn :
      psKernelInferCoreWithFuel
          remaining whnf defeq nextContext state fn false =
        Except.ok (Prod.mk fnType fnState))
    (hForall :
      psKernelEnsureForallWith
          whnf nextContext fnState fnType =
        Except.ok (Prod.mk view forallState))
    (hArg :
      psKernelInferCoreWithFuel
          remaining whnf defeq nextContext forallState arg false =
        Except.ok (Prod.mk argType argState))
    (hEq :
      psKernelExprEq argType view.domain = false)
    (hDefEq :
      defeq
          (if psKernelExprIsEagerReduce arg then
            psKernelCheckerContextWithEagerReduce nextContext true
          else
            nextContext)
          argState
          argType
          view.domain =
        Except.ok (Prod.mk true eqState))
    (hFnTyping :
      PsKernelTypingJudgment
        nextContext.environment
        nextContext.localContext
        fn
        fnType)
    (hFnType :
      PsKernelDefEqJudgment
        nextContext.environment
        nextContext.localContext
        fnType
        (PsKernelExpr.forallE
          view.name
          view.domain
          view.body
          view.binderInfo))
    (hArgTyping :
      PsKernelTypingJudgment
        nextContext.environment
        nextContext.localContext
        arg
        argType)
    (hArgType :
      PsKernelDefEqJudgment
        nextContext.environment
        nextContext.localContext
        argType
        view.domain) :
    psKernelInferCoreWithFuel
        (Nat.succ remaining)
        whnf defeq context state
        (PsKernelExpr.app fn arg)
        false =
      Except.ok
        (Prod.mk
          (psKernelExprInstantiate1 view.body arg)
          eqState) ∧
    PsKernelTypingJudgment
      nextContext.environment
      nextContext.localContext
      (PsKernelExpr.app fn arg)
      (psKernelExprInstantiate1 view.body arg) := by
  constructor
  · cases hEager : psKernelExprIsEagerReduce arg with
    | false =>
        simp [hEager] at hDefEq
        simp [
          psKernelInferCoreWithFuel,
          psKernelInferCacheEligible,
          psKernelCacheInferResult,
          hDepth,
          hFn,
          hForall,
          hArg,
          hEq,
          hEager,
          hDefEq
        ]
    | true =>
        simp [hEager] at hDefEq
        simp [
          psKernelInferCoreWithFuel,
          psKernelInferCacheEligible,
          psKernelCacheInferResult,
          hDepth,
          hFn,
          hForall,
          hArg,
          hEq,
          hEager,
          hDefEq
        ]
  · exact
      PsKernelTypingJudgment.app
        fn arg fnType argType
        view.domain view.body
        view.name view.binderInfo
        hFnTyping hFnType hArgTyping hArgType

theorem psKernelInferCore_lam_checked_refines_typing
    (remaining : Nat)
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
    (context nextContext : PsKernelCheckerContext)
    (state domainState sortState state1 bodyState typeState codomainState : PsKernelCheckerState)
    (name fresh : PsKernelName)
    (domain body domainType bodyType typeOfBodyType : PsKernelExpr)
    (binderInfo : PsKernelBinderInfo)
    (domainLevel codomainLevel : PsKernelLevel)
    (hDepth :
      psKernelCheckerContextEnterRecDepth context =
        Except.ok nextContext)
    (hDomainRun :
      psKernelInferCoreWithFuel
          remaining whnf defeq nextContext state domain false =
        Except.ok (Prod.mk domainType domainState))
    (hDomainSort :
      psKernelEnsureSortWith
          whnf nextContext domainState domainType =
        Except.ok (Prod.mk domainLevel sortState))
    (hFreshState :
      psKernelCheckerStateFreshName sortState name =
        Prod.mk fresh state1)
    (hBodyRun :
      psKernelInferCoreWithFuel
          remaining
          whnf
          defeq
          (psKernelCheckerContextWithLocalContext
            nextContext
            (psKernelLocalContextAddLocal
              nextContext.localContext
              fresh
              name
              domain
              binderInfo))
          state1
          (psKernelExprInstantiate1
            body
            (PsKernelExpr.fvar fresh))
          false =
        Except.ok (Prod.mk bodyType bodyState))
    (hTypeRun :
      psKernelInferCoreWithFuel remaining whnf defeq
          (psKernelCheckerContextWithLocalContext nextContext
            (psKernelLocalContextAddLocal nextContext.localContext fresh name domain binderInfo))
          bodyState bodyType true =
        Except.ok (Prod.mk typeOfBodyType typeState))
    (hCodomainSort :
      psKernelEnsureSortWith whnf
          (psKernelCheckerContextWithLocalContext nextContext
            (psKernelLocalContextAddLocal nextContext.localContext fresh name domain binderInfo))
          typeState typeOfBodyType =
        Except.ok (Prod.mk codomainLevel codomainState))
    (hFresh :
      psKernelLocalContextFind
          nextContext.localContext
          fresh =
        Option.none)
    (hDomainTyping :
      PsKernelTypingJudgment
        nextContext.environment
        nextContext.localContext
        domain
        (PsKernelExpr.sort domainLevel))
    (hBodyTyping :
      PsKernelTypingJudgment
        nextContext.environment
        (psKernelLocalContextAddLocal
          nextContext.localContext
          fresh
          name
          domain
          binderInfo)
        (psKernelExprInstantiate1
          body
          (PsKernelExpr.fvar fresh))
        bodyType) :
    let result :=
      PsKernelExpr.forallE
        name
        domain
        (psKernelExprAbstractFVars
          bodyType
          (List.cons fresh List.nil))
        binderInfo
    psKernelInferCoreWithFuel
        (Nat.succ remaining)
        whnf defeq context state
        (PsKernelExpr.lam name domain body binderInfo)
        false =
      Except.ok
        (Prod.mk
          result
          (psKernelCheckerStateExitLocalScope
            state1
            codomainState)) ∧
    PsKernelTypingJudgment
      nextContext.environment
      nextContext.localContext
      (PsKernelExpr.lam name domain body binderInfo)
      result := by
  dsimp
  constructor
  · simp [
      psKernelInferCoreWithFuel,
      psKernelInferSortWith,
      psKernelLambdaCodomainVisitWith,
      psKernelInferCacheEligible,
      psKernelCacheInferResult,
      hDepth,
      hDomainRun,
      hDomainSort,
      hFreshState,
      hBodyRun,
      hTypeRun,
      hCodomainSort
    ]
  · exact
      PsKernelTypingJudgment.lam
        name fresh domain body bodyType binderInfo domainLevel
        hFresh hDomainTyping hBodyTyping

theorem psKernelInferCore_forall_checked_refines_typing
    (remaining : Nat)
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
    (context nextContext : PsKernelCheckerContext)
    (state domainState domainSortState state1 bodyState bodySortState :
      PsKernelCheckerState)
    (name fresh : PsKernelName)
    (domain body domainType bodyType : PsKernelExpr)
    (binderInfo : PsKernelBinderInfo)
    (domainLevel bodyLevel : PsKernelLevel)
    (hDepth :
      psKernelCheckerContextEnterRecDepth context =
        Except.ok nextContext)
    (hDomainRun :
      psKernelInferCoreWithFuel
          remaining whnf defeq nextContext state domain false =
        Except.ok (Prod.mk domainType domainState))
    (hDomainSort :
      psKernelEnsureSortWith
          whnf nextContext domainState domainType =
        Except.ok (Prod.mk domainLevel domainSortState))
    (hFreshState :
      psKernelCheckerStateFreshName domainSortState name =
        Prod.mk fresh state1)
    (hBodyRun :
      psKernelInferCoreWithFuel
          remaining
          whnf
          defeq
          (psKernelCheckerContextWithLocalContext
            nextContext
            (psKernelLocalContextAddLocal
              nextContext.localContext
              fresh
              name
              domain
              binderInfo))
          state1
          (psKernelExprInstantiate1
            body
            (PsKernelExpr.fvar fresh))
          false =
        Except.ok (Prod.mk bodyType bodyState))
    (hBodySort :
      psKernelEnsureSortWith
          whnf
          (psKernelCheckerContextWithLocalContext
            nextContext
            (psKernelLocalContextAddLocal
              nextContext.localContext
              fresh
              name
              domain
              binderInfo))
          bodyState
          bodyType =
        Except.ok (Prod.mk bodyLevel bodySortState))
    (hFresh :
      psKernelLocalContextFind
          nextContext.localContext
          fresh =
        Option.none)
    (hDomainTyping :
      PsKernelTypingJudgment
        nextContext.environment
        nextContext.localContext
        domain
        (PsKernelExpr.sort domainLevel))
    (hBodyTyping :
      PsKernelTypingJudgment
        nextContext.environment
        (psKernelLocalContextAddLocal
          nextContext.localContext
          fresh
          name
          domain
          binderInfo)
        (psKernelExprInstantiate1
          body
          (PsKernelExpr.fvar fresh))
        (PsKernelExpr.sort bodyLevel)) :
    psKernelInferCoreWithFuel
        (Nat.succ remaining)
        whnf defeq context state
        (PsKernelExpr.forallE name domain body binderInfo)
        false =
      Except.ok
        (Prod.mk
          (PsKernelExpr.sort
            (psKernelLevelMkIMax
              domainLevel
              bodyLevel))
          (psKernelCheckerStateExitLocalScope
            state1
            bodySortState)) ∧
    PsKernelTypingJudgment
      nextContext.environment
      nextContext.localContext
      (PsKernelExpr.forallE name domain body binderInfo)
      (PsKernelExpr.sort
        (psKernelLevelMkIMax
          domainLevel
          bodyLevel)) := by
  constructor
  · simp [
      psKernelInferCoreWithFuel,
      psKernelInferSortWith,
      psKernelInferCacheEligible,
      psKernelCacheInferResult,
      hDepth,
      hDomainRun,
      hDomainSort,
      hFreshState,
      hBodyRun,
      hBodySort
    ]
  · exact
      PsKernelTypingJudgment.forallE
        name fresh domain body binderInfo
        domainLevel bodyLevel
        hFresh hDomainTyping hBodyTyping

theorem psKernelInferCore_let_checked_refines_typing
    (remaining : Nat)
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
    (context nextContext : PsKernelCheckerContext)
    (state typeState typeSortState valueState eqState state1 bodyState :
      PsKernelCheckerState)
    (name fresh : PsKernelName)
    (type value body typeType valueType bodyType : PsKernelExpr)
    (nondep : Bool)
    (typeLevel : PsKernelLevel)
    (hCache :
      psKernelExprMapGet
          state.checkedInfer
          (PsKernelExpr.letE name type value body nondep) =
        Option.none)
    (hDepth :
      psKernelCheckerContextEnterRecDepth context =
        Except.ok nextContext)
    (hTypeRun :
      psKernelInferCoreWithFuel
          remaining whnf defeq nextContext state type false =
        Except.ok (Prod.mk typeType typeState))
    (hTypeSort :
      psKernelEnsureSortWith
          whnf nextContext typeState typeType =
        Except.ok (Prod.mk typeLevel typeSortState))
    (hValueRun :
      psKernelInferCoreWithFuel
          remaining whnf defeq nextContext typeSortState value false =
        Except.ok (Prod.mk valueType valueState))
    (hValueEq :
      defeq
          nextContext
          valueState
          valueType
          type =
        Except.ok (Prod.mk true eqState))
    (hFreshState :
      psKernelCheckerStateFreshName eqState name =
        Prod.mk fresh state1)
    (hBodyRun :
      psKernelInferCoreWithFuel
          remaining
          whnf
          defeq
          (psKernelCheckerContextWithLocalContext
            nextContext
            (psKernelLocalContextAddLet
              nextContext.localContext
              fresh
              name
              type
              value))
          state1
          (psKernelExprInstantiate1
            body
            (PsKernelExpr.fvar fresh))
          false =
        Except.ok (Prod.mk bodyType bodyState))
    (hFresh :
      psKernelLocalContextFind
          nextContext.localContext
          fresh =
        Option.none)
    (hTypeTyping :
      PsKernelTypingJudgment
        nextContext.environment
        nextContext.localContext
        type
        (PsKernelExpr.sort typeLevel))
    (hValueTyping :
      PsKernelTypingJudgment
        nextContext.environment
        nextContext.localContext
        value
        valueType)
    (hValueType :
      PsKernelDefEqJudgment
        nextContext.environment
        nextContext.localContext
        valueType
        type)
    (hBodyTyping :
      PsKernelTypingJudgment
        nextContext.environment
        (psKernelLocalContextAddLet
          nextContext.localContext
          fresh
          name
          type
          value)
        (psKernelExprInstantiate1
          body
          (PsKernelExpr.fvar fresh))
        bodyType) :
    let reducedBodyType :=
      psKernelExprCheapBetaReduce bodyType
    let closedBody :=
      psKernelExprAbstractFVars
        reducedBodyType
        (List.cons fresh List.nil)
    let result :=
      if
          psKernelExprHasLooseBVarAt
            closedBody
            0 then
        PsKernelExpr.letE
          name type value closedBody nondep
      else
        reducedBodyType
    psKernelInferCoreWithFuel
        (Nat.succ remaining)
        whnf defeq context state
        (PsKernelExpr.letE name type value body nondep)
        false =
      Except.ok
        (Prod.mk
          result
          (psKernelCacheInferResult
            (psKernelCheckerStateExitLocalScope
              state1
              bodyState)
            false
            (PsKernelExpr.letE name type value body nondep)
            result)) ∧
    PsKernelTypingJudgment
      nextContext.environment
      nextContext.localContext
      (PsKernelExpr.letE name type value body nondep)
      result := by
  dsimp
  constructor
  · simp [
      psKernelInferCoreWithFuel,
      psKernelInferCacheEligible,
      hCache,
      hDepth,
      hTypeRun,
      hTypeSort,
      hValueRun,
      hValueEq,
      hFreshState,
      hBodyRun
    ]
  · exact
      PsKernelTypingJudgment.letE
        name fresh type value body valueType bodyType
        nondep typeLevel
        hFresh hTypeTyping hValueTyping hValueType hBodyTyping


theorem psKernelInferCore_mdata_refines_typing
    (remaining : Nat)
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
    (context nextContext : PsKernelCheckerContext)
    (state bodyState : PsKernelCheckerState)
    (metadata : Nat)
    (body bodyType : PsKernelExpr)
    (inferOnly : Bool)
    (hCache :
      psKernelExprMapGet
          (if inferOnly then state.inferOnly else state.checkedInfer)
          (PsKernelExpr.mdata metadata body) =
        Option.none)
    (hDepth :
      psKernelCheckerContextEnterRecDepth context =
        Except.ok nextContext)
    (hBody :
      psKernelInferCoreWithFuel
          remaining
          whnf
          defeq
          nextContext
          state
          body
          inferOnly =
        Except.ok (Prod.mk bodyType bodyState))
    (hBodyTyping :
      PsKernelTypingJudgment
        nextContext.environment
        nextContext.localContext
        body
        bodyType) :
    ∃ nextState : PsKernelCheckerState,
      psKernelInferCoreWithFuel
          (Nat.succ remaining)
          whnf
          defeq
          context
          state
          (PsKernelExpr.mdata metadata body)
          inferOnly =
        Except.ok
          (Prod.mk bodyType nextState) ∧
      PsKernelTypingJudgment
        nextContext.environment
        nextContext.localContext
        (PsKernelExpr.mdata metadata body)
        bodyType := by
  refine ⟨
    psKernelCacheInferResult
      bodyState
      inferOnly
      (PsKernelExpr.mdata metadata body)
      bodyType,
    ?_,
    PsKernelTypingJudgment.mdata
      metadata
      body
      bodyType
      hBodyTyping
  ⟩
  cases inferOnly with
  | false =>
      simp at hCache
      simp [
        psKernelInferCoreWithFuel,
        psKernelInferCacheEligible,
        hCache,
        hDepth,
        hBody
      ]
  | true =>
      simp at hCache
      simp [
        psKernelInferCoreWithFuel,
        psKernelInferCacheEligible,
        hCache,
        hDepth,
        hBody
      ]


theorem psKernelInferCore_projection_refines_typing
    (remaining : Nat)
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
    (context nextContext : PsKernelCheckerContext)
    (state projectionState : PsKernelCheckerState)
    (typeName : PsKernelName)
    (index : Nat)
    (structValue result : PsKernelExpr)
    (inferOnly : Bool)
    (hCache :
      psKernelExprMapGet
          (if inferOnly then state.inferOnly else state.checkedInfer)
          (PsKernelExpr.proj typeName index structValue) =
        Option.none)
    (hDepth :
      psKernelCheckerContextEnterRecDepth context =
        Except.ok nextContext)
    (hProjectionSound :
      PsKernelProjectionSound
        whnf
        (fun
          projectionContext
          projectionState
          projectionExpr =>
            psKernelInferCoreWithFuel
              remaining
              whnf
              defeq
              projectionContext
              projectionState
              projectionExpr
              inferOnly))
    (hIndex :
      PsKernelEnvironmentIndexRefines nextContext.environment)
    (hProjection :
      psKernelInferProjectionWith
          whnf
          (fun
            projectionContext
            projectionState
            projectionExpr =>
              psKernelInferCoreWithFuel
                remaining
                whnf
                defeq
                projectionContext
                projectionState
                projectionExpr
                inferOnly)
          nextContext
          state
          typeName
          index
          structValue =
        Except.ok (Prod.mk result projectionState)) :
    psKernelInferCoreWithFuel
        (Nat.succ remaining)
        whnf
        defeq
        context
        state
        (PsKernelExpr.proj typeName index structValue)
        inferOnly =
      Except.ok
        (Prod.mk
          result
          (psKernelCacheInferResult
            projectionState
            inferOnly
            (PsKernelExpr.proj typeName index structValue)
            result)) ∧
    PsKernelTypingJudgment
      nextContext.environment
      nextContext.localContext
      (PsKernelExpr.proj typeName index structValue)
      result := by
  constructor
  · cases inferOnly with
    | false =>
        simp at hCache
        simp [
          psKernelInferCoreWithFuel,
          psKernelInferCacheEligible,
          hCache,
          hDepth,
          hProjection
        ]
    | true =>
        simp at hCache
        simp [
          psKernelInferCoreWithFuel,
          psKernelInferCacheEligible,
          hCache,
          hDepth,
          hProjection
        ]
  · exact
      hProjectionSound
        nextContext
        state
        projectionState
        typeName
        index
        structValue
        result
        hIndex
        hProjection
