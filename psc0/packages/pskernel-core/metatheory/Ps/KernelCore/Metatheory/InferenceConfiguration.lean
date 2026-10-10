import Ps.KernelCore.Metatheory.ProjectionConfiguration
import Ps.KernelCore.Checker.Inference.Core

/-
Concrete infer-only configuration preservation.

This is intentionally a configuration theorem, not a typing theorem.  Binder
child caches are not trusted or published: scope exit restores the parent
semantic caches and preserves only a monotone fresh-name counter.
-/

theorem psKernelInferOnlyCoreConfigurationPreserves_contract
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
    (hWhnf :
      PsKernelWhnfConfigurationSound whnf) :
    PsKernelInferOnlyCoreConfigurationPreserves
      whnf
      defeq := by
  intro fuel
  induction fuel with
  | zero =>
      intro context state nextState expr result hConfig hSuccess
      simp [psKernelInferCoreWithFuel] at hSuccess
  | succ remaining ih =>
      intro context state nextState expr result hConfig hSuccess
      have hMissCase :
          (if
              psKernelInferCacheEligible
                true
                expr then
            psKernelExprMapGet
              state.inferOnly
              expr
          else
            Option.none) =
            Option.none ->
          PsKernelCheckerConfigurationSound
            context
            nextState := by
        intro hMiss
        cases hDepth :
            psKernelCheckerContextEnterRecDepth
              context with
        | error error =>
            simp [
              psKernelInferCoreWithFuel,
              hMiss,
              hDepth
            ] at hSuccess
        | ok nextContext =>
            have hNextConfig :
                PsKernelCheckerConfigurationSound
                  nextContext
                  state :=
              psKernelCheckerContextEnterRecDepth_preserves_configuration
                context
                nextContext
                state
                hConfig
                hDepth
            have hBack :
                ∀ (candidate : PsKernelCheckerState),
                  PsKernelCheckerConfigurationSound
                      nextContext
                      candidate ->
                    PsKernelCheckerConfigurationSound
                      context
                      candidate := by
              intro candidate hCandidate
              exact
                psKernelCheckerConfigurationSound_enterRecDepth_back
                  context
                  nextContext
                  candidate
                  hDepth
                  hCandidate
            have hPublish :
                ∀
                  (baseState : PsKernelCheckerState)
                  (cacheExpr cacheResult : PsKernelExpr),
                  PsKernelCheckerConfigurationSound
                      nextContext
                      baseState ->
                    PsKernelCheckerConfigurationSound
                      context
                      (psKernelCacheInferResult
                        baseState
                        true
                        cacheExpr
                        cacheResult) := by
              intro baseState cacheExpr cacheResult hBase
              exact
                hBack
                  (psKernelCacheInferResult
                    baseState
                    true
                    cacheExpr
                    cacheResult)
                  (psKernelCacheInferOnlyResult_preserves_configuration
                    nextContext
                    baseState
                    cacheExpr
                    cacheResult
                    hBase)
            cases expr with
            | bvar index =>
                simp [
                  psKernelInferCoreWithFuel,
                  hMiss,
                  hDepth
                ] at hSuccess
            | mvar name =>
                simp [
                  psKernelInferCoreWithFuel,
                  hMiss,
                  hDepth
                ] at hSuccess
            | fvar name =>
                cases hFind :
                    psKernelLocalContextFind
                      nextContext.localContext
                      name with
                | none =>
                    simp [
                      psKernelInferCoreWithFuel,
                      hMiss,
                      hDepth,
                      hFind
                    ] at hSuccess
                | some declaration =>
                    simp [
                      psKernelInferCoreWithFuel,
                      hMiss,
                      hDepth,
                      hFind
                    ] at hSuccess
                    rcases hSuccess with ⟨rfl, rfl⟩
                    exact
                      hPublish
                        state
                        (PsKernelExpr.fvar name)
                        (psKernelLocalDeclType declaration)
                        hNextConfig
            | sort level =>
                simp [
                  psKernelInferCoreWithFuel,
                  hMiss,
                  hDepth
                ] at hSuccess
                rcases hSuccess with ⟨rfl, rfl⟩
                exact
                  hPublish
                    state
                    (PsKernelExpr.sort level)
                    (PsKernelExpr.sort
                      (PsKernelLevel.succ level))
                    hNextConfig
            | const name levels =>
                cases hFind :
                    psKernelEnvironmentFind
                      nextContext.environment
                      name with
                | none =>
                    simp [
                      psKernelInferCoreWithFuel,
                      hMiss,
                      hDepth,
                      hFind
                    ] at hSuccess
                | some info =>
                    cases hArity :
                        Nat.beq
                          (psKernelNameListLength
                            (psKernelConstantInfoLevelParams info))
                          (psKernelLevelListLength levels) with
                    | false =>
                        have hArityNe :
                            psKernelNameListLength
                                (psKernelConstantInfoLevelParams info) ≠
                              psKernelLevelListLength levels := by
                          intro hEq
                          have hTrue :
                              Nat.beq
                                  (psKernelNameListLength
                                    (psKernelConstantInfoLevelParams info))
                                  (psKernelLevelListLength levels) =
                                true := by
                            simpa [hEq]
                          rw [hArity] at hTrue
                          cases hTrue
                        simp [
                          psKernelInferCoreWithFuel,
                          hMiss,
                          hDepth,
                          hFind,
                          hArityNe
                        ] at hSuccess
                    | true =>
                        have hArityEq :
                            psKernelNameListLength
                                (psKernelConstantInfoLevelParams info) =
                              psKernelLevelListLength levels := by
                          simpa using hArity
                        let inferred :=
                          psKernelExprInstantiateLevelParams
                            (psKernelConstantInfoType info)
                            (psKernelConstantInfoLevelParams info)
                            levels
                        simp [
                          psKernelInferCoreWithFuel,
                          hMiss,
                          hDepth,
                          hFind,
                          hArityEq,
                          inferred
                        ] at hSuccess
                        rcases hSuccess with ⟨rfl, rfl⟩
                        exact
                          hPublish
                            state
                            (PsKernelExpr.const name levels)
                            inferred
                            hNextConfig
            | lit literal =>
                cases literal with
                | nat value =>
                    cases hSize :
                        psKernelCheckNatSize
                          nextContext.maxNatSize
                          value with
                    | error error =>
                        simp [
                          psKernelInferCoreWithFuel,
                          hMiss,
                          hDepth,
                          hSize
                        ] at hSuccess
                    | ok unit =>
                        cases unit
                        simp [
                          psKernelInferCoreWithFuel,
                          hMiss,
                          hDepth,
                          hSize
                        ] at hSuccess
                        rcases hSuccess with ⟨rfl, rfl⟩
                        exact
                          hPublish
                            state
                            (PsKernelExpr.lit
                              (PsKernelLiteral.nat value))
                            (PsKernelExpr.const
                              psKernelNatName
                              List.nil)
                            hNextConfig
                | str value =>
                    simp [
                      psKernelInferCoreWithFuel,
                      hMiss,
                      hDepth
                    ] at hSuccess
                    rcases hSuccess with ⟨rfl, rfl⟩
                    exact
                      hPublish
                        state
                        (PsKernelExpr.lit
                          (PsKernelLiteral.str value))
                        (PsKernelExpr.const
                          psKernelStringName
                          List.nil)
                        hNextConfig
            | mdata metadata body =>
                cases hBody :
                    psKernelInferCoreWithFuel
                      remaining
                      whnf
                      defeq
                      nextContext
                      state
                      body
                      true with
                | error error =>
                    simp [
                      psKernelInferCoreWithFuel,
                      hMiss,
                      hDepth,
                      hBody
                    ] at hSuccess
                | ok bodyRun =>
                    rcases bodyRun with ⟨bodyType, bodyState⟩
                    have hBodyConfig :
                        PsKernelCheckerConfigurationSound
                          nextContext
                          bodyState :=
                      ih
                        nextContext
                        state
                        bodyState
                        body
                        bodyType
                        hNextConfig
                        hBody
                    simp [
                      psKernelInferCoreWithFuel,
                      hMiss,
                      hDepth,
                      hBody
                    ] at hSuccess
                    rcases hSuccess with ⟨rfl, rfl⟩
                    exact
                      hPublish
                        bodyState
                        (PsKernelExpr.mdata metadata body)
                        bodyType
                        hBodyConfig
            | app fn arg =>
                let appExpr := PsKernelExpr.app fn arg
                let args :=
                  psKernelExprGetAppArgs appExpr
                let headExpr :=
                  psKernelExprGetAppFn appExpr
                cases hFn :
                    psKernelInferCoreWithFuel
                      remaining
                      whnf
                      defeq
                      nextContext
                      state
                      headExpr
                      true with
                | error error =>
                    simp [
                      psKernelInferCoreWithFuel,
                      hMiss,
                      hDepth,
                      appExpr,
                      args,
                      headExpr,
                      hFn
                    ] at hSuccess
                | ok fnRun =>
                    rcases fnRun with ⟨fnType, fnState⟩
                    have hFnConfig :
                        PsKernelCheckerConfigurationSound
                          nextContext
                          fnState :=
                      ih
                        nextContext
                        state
                        fnState
                        headExpr
                        fnType
                        hNextConfig
                        hFn
                    cases hLoop :
                        psKernelInferAppOnlyLoopWithFuel
                          (Nat.succ
                            (psKernelExprListLength args))
                          whnf
                          nextContext
                          fnState
                          args
                          0
                          0
                          fnType with
                    | error error =>
                        simp [
                          psKernelInferCoreWithFuel,
                          hMiss,
                          hDepth,
                          appExpr,
                          args,
                          headExpr,
                          hFn,
                          hLoop
                        ] at hSuccess
                    | ok appRun =>
                        rcases appRun with ⟨appType, appState⟩
                        have hAppConfig :
                            PsKernelCheckerConfigurationSound
                              nextContext
                              appState :=
                          psKernelInferAppOnlyLoopWithFuel_configuration_preserves_contract
                            whnf
                            hWhnf
                            (Nat.succ
                              (psKernelExprListLength args))
                            nextContext
                            fnState
                            appState
                            args
                            0
                            0
                            fnType
                            appType
                            hFnConfig
                            hLoop
                        simp [
                          psKernelInferCoreWithFuel,
                          hMiss,
                          hDepth,
                          appExpr,
                          args,
                          headExpr,
                          hFn,
                          hLoop
                        ] at hSuccess
                        rcases hSuccess with ⟨rfl, rfl⟩
                        exact
                          hPublish
                            appState
                            appExpr
                            appType
                            hAppConfig
            | lam name domain body binderInfo =>
                let freshResult :=
                  psKernelCheckerStateFreshName
                    state
                    name
                let fresh :=
                  Prod.fst freshResult
                let state1 :=
                  Prod.snd freshResult
                let childLocal :=
                  psKernelLocalContextAddLocal
                    nextContext.localContext
                    fresh
                    name
                    domain
                    binderInfo
                let child :=
                  psKernelCheckerContextWithLocalContext
                    nextContext
                    childLocal
                let openedBody :=
                  psKernelExprInstantiate1
                    body
                    (PsKernelExpr.fvar fresh)
                cases hBody :
                    psKernelInferCoreWithFuel
                      remaining
                      whnf
                      defeq
                      child
                      state1
                      openedBody
                      true with
                | error error =>
                    simp [
                      psKernelInferCoreWithFuel, psKernelInferSortWith, psKernelLambdaCodomainVisitWith,
                      hMiss,
                      hDepth,
                      freshResult,
                      fresh,
                      state1,
                      childLocal,
                      child,
                      openedBody,
                      hBody
                    ] at hSuccess
                | ok bodyRun =>
                    rcases bodyRun with ⟨rawBodyType, bodyState⟩
                    let bodyType :=
                      rawBodyType
                    let closedBody :=
                      psKernelExprAbstractFVars
                        bodyType
                        (List.cons fresh List.nil)
                    let inferred :=
                      PsKernelExpr.forallE
                        name
                        domain
                        closedBody
                        binderInfo
                    let scopedState :=
                      psKernelCheckerStateExitLocalScope
                        state1
                        bodyState
                    have hState1Config :
                        PsKernelCheckerConfigurationSound
                          nextContext
                          state1 := by
                      simpa [
                        freshResult,
                        state1
                      ] using
                        psKernelCheckerStateFreshName_preserves_configuration
                          nextContext
                          state
                          name
                          hNextConfig
                    have hScopedConfig :
                        PsKernelCheckerConfigurationSound
                          nextContext
                          scopedState := by
                      simpa [scopedState] using
                        psKernelCheckerStateExitLocalScope_preserves_configuration
                          nextContext
                          state1
                          bodyState
                          hState1Config
                    simp [
                      psKernelInferCoreWithFuel, psKernelInferSortWith, psKernelLambdaCodomainVisitWith,
                      hMiss,
                      hDepth,
                      freshResult,
                      fresh,
                      state1,
                      childLocal,
                      child,
                      openedBody,
                      hBody,
                      bodyType,
                      closedBody,
                      inferred,
                      scopedState
                    ] at hSuccess
                    rcases hSuccess with ⟨rfl, rfl⟩
                    exact
                      hPublish
                        scopedState
                        (PsKernelExpr.lam
                          name domain body binderInfo)
                        inferred
                        hScopedConfig
            | forallE name domain body binderInfo =>
                cases hDomain :
                    psKernelInferCoreWithFuel
                      remaining
                      whnf
                      defeq
                      nextContext
                      state
                      domain
                      true with
                | error error =>
                    simp [
                      psKernelInferCoreWithFuel, psKernelInferSortWith, psKernelLambdaCodomainVisitWith,
                      hMiss,
                      hDepth,
                      hDomain
                    ] at hSuccess
                | ok domainRun =>
                    rcases domainRun with ⟨domainType, domainState⟩
                    have hDomainConfig :
                        PsKernelCheckerConfigurationSound
                          nextContext
                          domainState :=
                      ih
                        nextContext
                        state
                        domainState
                        domain
                        domainType
                        hNextConfig
                        hDomain
                    cases hDomainSort :
                        psKernelEnsureSortWith
                          whnf
                          nextContext
                          domainState
                          domainType with
                    | error error =>
                        simp [
                          psKernelInferCoreWithFuel, psKernelInferSortWith, psKernelLambdaCodomainVisitWith,
                          hMiss,
                          hDepth,
                          hDomain,
                          hDomainSort
                        ] at hSuccess
                    | ok domainSortRun =>
                        rcases domainSortRun with
                          ⟨domainLevel, domainSortState⟩
                        have hDomainSortConfig :
                            PsKernelCheckerConfigurationSound
                              nextContext
                              domainSortState :=
                          (psKernelEnsureSortWith_configuration_refines
                            whnf
                            hWhnf
                            nextContext
                            domainState
                            domainSortState
                            domainType
                            domainLevel
                            hDomainConfig
                            hDomainSort).2
                        let freshResult :=
                          psKernelCheckerStateFreshName
                            domainSortState
                            name
                        let fresh :=
                          Prod.fst freshResult
                        let state1 :=
                          Prod.snd freshResult
                        let childLocal :=
                          psKernelLocalContextAddLocal
                            nextContext.localContext
                            fresh
                            name
                            domain
                            binderInfo
                        let child :=
                          psKernelCheckerContextWithLocalContext
                            nextContext
                            childLocal
                        let openedBody :=
                          psKernelExprInstantiate1
                            body
                            (PsKernelExpr.fvar fresh)
                        cases hBody :
                            psKernelInferCoreWithFuel
                              remaining
                              whnf
                              defeq
                              child
                              state1
                              openedBody
                              true with
                        | error error =>
                            simp [
                              psKernelInferCoreWithFuel, psKernelInferSortWith, psKernelLambdaCodomainVisitWith,
                              hMiss,
                              hDepth,
                              hDomain,
                              hDomainSort,
                              freshResult,
                              fresh,
                              state1,
                              childLocal,
                              child,
                              openedBody,
                              hBody
                            ] at hSuccess
                        | ok bodyRun =>
                            rcases bodyRun with
                              ⟨bodyType, bodyState⟩
                            cases hBodySort :
                                psKernelEnsureSortWith
                                  whnf
                                  child
                                  bodyState
                                  bodyType with
                            | error error =>
                                simp [
                                  psKernelInferCoreWithFuel, psKernelInferSortWith, psKernelLambdaCodomainVisitWith,
                                  hMiss,
                                  hDepth,
                                  hDomain,
                                  hDomainSort,
                                  freshResult,
                                  fresh,
                                  state1,
                                  childLocal,
                                  child,
                                  openedBody,
                                  hBody,
                                  hBodySort
                                ] at hSuccess
                            | ok bodySortRun =>
                                rcases bodySortRun with
                                  ⟨bodyLevel, bodySortState⟩
                                let inferred :=
                                  PsKernelExpr.sort
                                    (psKernelLevelMkIMax
                                      domainLevel
                                      bodyLevel)
                                let scopedState :=
                                  psKernelCheckerStateExitLocalScope
                                    state1
                                    bodySortState
                                have hState1Config :
                                    PsKernelCheckerConfigurationSound
                                      nextContext
                                      state1 := by
                                  simpa [
                                    freshResult,
                                    state1
                                  ] using
                                    psKernelCheckerStateFreshName_preserves_configuration
                                      nextContext
                                      domainSortState
                                      name
                                      hDomainSortConfig
                                have hScopedConfig :
                                    PsKernelCheckerConfigurationSound
                                      nextContext
                                      scopedState := by
                                  simpa [scopedState] using
                                    psKernelCheckerStateExitLocalScope_preserves_configuration
                                      nextContext
                                      state1
                                      bodySortState
                                      hState1Config
                                simp [
                                  psKernelInferCoreWithFuel, psKernelInferSortWith, psKernelLambdaCodomainVisitWith,
                                  hMiss,
                                  hDepth,
                                  hDomain,
                                  hDomainSort,
                                  freshResult,
                                  fresh,
                                  state1,
                                  childLocal,
                                  child,
                                  openedBody,
                                  hBody,
                                  hBodySort,
                                  inferred,
                                  scopedState
                                ] at hSuccess
                                rcases hSuccess with ⟨rfl, rfl⟩
                                exact
                                  hPublish
                                    scopedState
                                    (PsKernelExpr.forallE
                                      name domain body binderInfo)
                                    inferred
                                    hScopedConfig
            | letE name type value body nondep =>
                let freshResult :=
                  psKernelCheckerStateFreshName
                    state
                    name
                let fresh :=
                  Prod.fst freshResult
                let state1 :=
                  Prod.snd freshResult
                let childLocal :=
                  psKernelLocalContextAddLet
                    nextContext.localContext
                    fresh
                    name
                    type
                    value
                let child :=
                  psKernelCheckerContextWithLocalContext
                    nextContext
                    childLocal
                let openedBody :=
                  psKernelExprInstantiate1
                    body
                    (PsKernelExpr.fvar fresh)
                cases hBody :
                    psKernelInferCoreWithFuel
                      remaining
                      whnf
                      defeq
                      child
                      state1
                      openedBody
                      true with
                | error error =>
                    simp [
                      psKernelInferCoreWithFuel,
                      hMiss,
                      hDepth,
                      freshResult,
                      fresh,
                      state1,
                      childLocal,
                      child,
                      openedBody,
                      hBody
                    ] at hSuccess
                | ok bodyRun =>
                    rcases bodyRun with ⟨rawBodyType, bodyState⟩
                    let bodyType :=
                      psKernelExprCheapBetaReduce rawBodyType
                    let closedBody :=
                      psKernelExprAbstractFVars
                        bodyType
                        (List.cons fresh List.nil)
                    let inferred :=
                      if
                          psKernelExprHasLooseBVarAt
                            closedBody
                            0 then
                        PsKernelExpr.letE
                          name
                          type
                          value
                          closedBody
                          nondep
                      else
                        bodyType
                    let scopedState :=
                      psKernelCheckerStateExitLocalScope
                        state1
                        bodyState
                    have hState1Config :
                        PsKernelCheckerConfigurationSound
                          nextContext
                          state1 := by
                      simpa [
                        freshResult,
                        state1
                      ] using
                        psKernelCheckerStateFreshName_preserves_configuration
                          nextContext
                          state
                          name
                          hNextConfig
                    have hScopedConfig :
                        PsKernelCheckerConfigurationSound
                          nextContext
                          scopedState := by
                      simpa [scopedState] using
                        psKernelCheckerStateExitLocalScope_preserves_configuration
                          nextContext
                          state1
                          bodyState
                          hState1Config
                    simp [
                      psKernelInferCoreWithFuel,
                      hMiss,
                      hDepth,
                      freshResult,
                      fresh,
                      state1,
                      childLocal,
                      child,
                      openedBody,
                      hBody,
                      bodyType,
                      closedBody,
                      inferred,
                      scopedState
                    ] at hSuccess
                    rcases hSuccess with ⟨rfl, rfl⟩
                    exact
                      hPublish
                        scopedState
                        (PsKernelExpr.letE
                          name type value body nondep)
                        inferred
                        hScopedConfig
            | proj typeName index structValue =>
                let inferType :=
                  fun
                    (projectionContext : PsKernelCheckerContext)
                    (projectionState : PsKernelCheckerState)
                    (projectionExpr : PsKernelExpr) =>
                    psKernelInferCoreWithFuel
                      remaining
                      whnf
                      defeq
                      projectionContext
                      projectionState
                      projectionExpr
                      true
                have hInferType :
                    PsKernelInferOnlyConfigurationPreserves
                      inferType := by
                  intro projectionContext projectionState projectionNext
                    projectionExpr projectionResult
                    hProjectionConfig hProjectionRun
                  exact
                    ih
                      projectionContext
                      projectionState
                      projectionNext
                      projectionExpr
                      projectionResult
                      hProjectionConfig
                      hProjectionRun
                cases hProjection :
                    psKernelInferProjectionWith
                      whnf
                      inferType
                      nextContext
                      state
                      typeName
                      index
                      structValue with
                | error error =>
                    simp [
                      psKernelInferCoreWithFuel,
                      hMiss,
                      hDepth,
                      inferType,
                      hProjection
                    ] at hSuccess
                | ok projectionRun =>
                    rcases projectionRun with
                      ⟨projectionType, projectionState⟩
                    have hProjectionConfig :
                        PsKernelCheckerConfigurationSound
                          nextContext
                          projectionState :=
                      psKernelInferProjectionWith_preserves_configuration_of_infer_preserves
                        whnf
                        inferType
                        hWhnf
                        hInferType
                        nextContext
                        state
                        projectionState
                        typeName
                        index
                        structValue
                        projectionType
                        hNextConfig
                        hProjection
                    simp [
                      psKernelInferCoreWithFuel,
                      hMiss,
                      hDepth,
                      inferType,
                      hProjection
                    ] at hSuccess
                    rcases hSuccess with ⟨rfl, rfl⟩
                    exact
                      hPublish
                        projectionState
                        (PsKernelExpr.proj
                          typeName
                          index
                          structValue)
                        projectionType
                        hProjectionConfig
      cases hEligible :
          psKernelInferCacheEligible
            true
            expr with
      | false =>
          exact
            hMissCase
              (by simp [hEligible])
      | true =>
          cases hGet :
              psKernelExprMapGet
                state.inferOnly
                expr with
          | none =>
              exact
                hMissCase
                  (by simp [hEligible, hGet])
          | some cached =>
              cases hDepth :
                  psKernelCheckerContextEnterRecDepth
                    context with
              | error error =>
                  simp [
                    psKernelInferCoreWithFuel,
                    hEligible,
                    hGet,
                    hDepth
                  ] at hSuccess
              | ok nextContext =>
                  simp [
                    psKernelInferCoreWithFuel,
                    hEligible,
                    hGet,
                    hDepth
                  ] at hSuccess
                  rcases hSuccess with ⟨rfl, rfl⟩
                  exact hConfig
