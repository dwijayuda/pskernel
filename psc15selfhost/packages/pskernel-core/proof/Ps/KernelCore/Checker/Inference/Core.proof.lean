import Ps.KernelCore.Checker.Inference.Core

theorem psKernelInferCoreWithFuel_zero
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
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (expr : PsKernelExpr)
    (inferOnly : Bool) :
    psKernelInferCoreWithFuel
        0 whnf defeq context state expr inferOnly =
      Except.error "kernel inference budget exhausted" := by
  rfl


theorem psKernelInferCoreWithFuel_string_literal
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
          state) := by
  simp [
    psKernelInferCoreWithFuel,
    psKernelInferCacheEligible,
    psKernelCacheInferResult,
    hDepth
  ]

theorem psKernelInferCoreWithFuel_nat_literal
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
          state) := by
  simp [
    psKernelInferCoreWithFuel,
    psKernelInferCacheEligible,
    psKernelCacheInferResult,
    hDepth,
    hNat
  ]


theorem psKernelInferCoreWithFuel_sort_cache_miss
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
          (if inferOnly then
            state.inferOnly
          else
            state.checkedInfer)
          (PsKernelExpr.sort level) =
        Option.none)
    (hDepth :
      psKernelCheckerContextEnterRecDepth context =
        Except.ok nextContext) :
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
          (psKernelCacheInferResult
            state
            inferOnly
            (PsKernelExpr.sort level)
            (PsKernelExpr.sort (PsKernelLevel.succ level)))) := by
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


theorem psKernelInferCoreWithFuel_fvar_cache_miss
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
          (if inferOnly then
            state.inferOnly
          else
            state.checkedInfer)
          (PsKernelExpr.fvar name) =
        Option.none)
    (hDepth :
      psKernelCheckerContextEnterRecDepth context =
        Except.ok nextContext)
    (hFind :
      psKernelLocalContextFind
          nextContext.localContext
          name =
        Option.some declaration) :
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
          (psKernelCacheInferResult
            state
            inferOnly
            (PsKernelExpr.fvar name)
            (psKernelLocalDeclType declaration))) := by
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


theorem psKernelInferCoreWithFuel_const_inferOnly_cache_miss
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
    (hCache :
      psKernelExprMapGet
          state.inferOnly
          (PsKernelExpr.const name levels) =
        Option.none)
    (hDepth :
      psKernelCheckerContextEnterRecDepth context =
        Except.ok nextContext)
    (hFind :
      psKernelEnvironmentFind
          nextContext.environment
          name =
        Option.some info)
    (hLevels :
      Nat.beq
          (psKernelNameListLength
            (psKernelConstantInfoLevelParams info))
          (psKernelLevelListLength levels) =
        true) :
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
          (psKernelCacheInferResult
            state
            true
            (PsKernelExpr.const name levels)
            (psKernelExprInstantiateLevelParams
              (psKernelConstantInfoType info)
              (psKernelConstantInfoLevelParams info)
              levels))) := by
  simp [
    psKernelInferCoreWithFuel,
    psKernelInferCacheEligible,
    hCache,
    hDepth,
    hFind,
    hLevels
  ]

theorem psKernelInferCoreWithFuel_const_checked_safe
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
    (hCache :
      psKernelExprMapGet
          state.checkedInfer
          (PsKernelExpr.const name levels) =
        Option.none)
    (hDepth :
      psKernelCheckerContextEnterRecDepth context =
        Except.ok nextContext)
    (hFind :
      psKernelEnvironmentFind
          nextContext.environment
          name =
        Option.some info)
    (hLevels :
      Nat.beq
          (psKernelNameListLength
            (psKernelConstantInfoLevelParams info))
          (psKernelLevelListLength levels) =
        true)
    (hUnsafe :
      psKernelConstantInfoIsUnsafe info = false)
    (hPartial :
      psKernelConstantInfoIsPartial info = false) :
    psKernelInferCoreWithFuel
        (Nat.succ remaining)
        whnf
        defeq
        context
        state
        (PsKernelExpr.const name levels)
        false =
      Except.ok
        (Prod.mk
          (psKernelExprInstantiateLevelParams
            (psKernelConstantInfoType info)
            (psKernelConstantInfoLevelParams info)
            levels)
          (psKernelCacheInferResult
            state
            false
            (PsKernelExpr.const name levels)
            (psKernelExprInstantiateLevelParams
              (psKernelConstantInfoType info)
              (psKernelConstantInfoLevelParams info)
              levels))) := by
  simp [
    psKernelInferCoreWithFuel,
    psKernelInferCacheEligible,
    hCache,
    hDepth,
    hFind,
    hLevels,
    hUnsafe,
    hPartial
  ]

theorem psKernelInferCoreWithFuel_app_checked_direct
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
      psKernelExprEq argType view.domain = true) :
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
          argState) := by
  simp [
    psKernelInferCoreWithFuel,
    psKernelInferCacheEligible,
    psKernelCacheInferResult,
    hDepth,
    hFn,
    hForall,
    hArg,
    hEq
  ]
