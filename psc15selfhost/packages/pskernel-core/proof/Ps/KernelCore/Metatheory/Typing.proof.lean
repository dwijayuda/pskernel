import Ps.KernelCore.Checker.Inference.Core

/-
Independent proof-layer typing judgments for the executable kernel.

The authoritative environment component is environment.constants.  The runtime
index is intentionally absent from PsKernelTypingJudgment; a separate lookup
soundness assumption bridges the acceleration layer to semantic history.
-/

def PsKernelEnvironmentLookupSound
    (environment : PsKernelEnvironment) : Prop :=
  ∀ (name : PsKernelName) (info : PsKernelConstantInfo),
    psKernelEnvironmentFind environment name = Option.some info ->
      psKernelFindConstantInList
          name
          environment.constants =
        Option.some info

inductive PsKernelTypingJudgment
    (environment : PsKernelEnvironment)
    (localContext : PsKernelLocalContext) :
    PsKernelExpr -> PsKernelExpr -> Prop
  | sort
      (level : PsKernelLevel) :
      PsKernelTypingJudgment
        environment
        localContext
        (PsKernelExpr.sort level)
        (PsKernelExpr.sort (PsKernelLevel.succ level))
  | natLiteral
      (value : Nat) :
      PsKernelTypingJudgment
        environment
        localContext
        (PsKernelExpr.lit (PsKernelLiteral.nat value))
        (PsKernelExpr.const psKernelNatName List.nil)
  | stringLiteral
      (value : String) :
      PsKernelTypingJudgment
        environment
        localContext
        (PsKernelExpr.lit (PsKernelLiteral.str value))
        (PsKernelExpr.const psKernelStringName List.nil)
  | fvar
      (name : PsKernelName)
      (declaration : PsKernelLocalDecl)
      (hFind :
        psKernelLocalContextFind localContext name =
          Option.some declaration) :
      PsKernelTypingJudgment
        environment
        localContext
        (PsKernelExpr.fvar name)
        (psKernelLocalDeclType declaration)
  | const
      (name : PsKernelName)
      (levels : List PsKernelLevel)
      (info : PsKernelConstantInfo)
      (hFind :
        psKernelFindConstantInList
            name
            environment.constants =
          Option.some info)
      (hLevels :
        psKernelNameListLength
            (psKernelConstantInfoLevelParams info) =
          psKernelLevelListLength levels) :
      PsKernelTypingJudgment
        environment
        localContext
        (PsKernelExpr.const name levels)
        (psKernelExprInstantiateLevelParams
          (psKernelConstantInfoType info)
          (psKernelConstantInfoLevelParams info)
          levels)

def PsKernelInferenceCacheSound
    (environment : PsKernelEnvironment)
    (localContext : PsKernelLocalContext)
    (cache : PsKernelExprMap) : Prop :=
  ∀ (expr result : PsKernelExpr),
    psKernelExprMapGet cache expr = Option.some result ->
      PsKernelTypingJudgment
        environment
        localContext
        expr
        result

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
