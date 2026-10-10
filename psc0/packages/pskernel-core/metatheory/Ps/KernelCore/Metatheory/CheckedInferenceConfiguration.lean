import Ps.KernelCore.Metatheory.InferenceConfiguration
import Ps.KernelCore.Metatheory.InferenceTyping
import Ps.KernelCore.Metatheory.CheckedProjectionConfiguration
import Ps.KernelCore.Metatheory.ExprEq

/-
Checked inference is proved by fuel induction. Projection is factored out as a
recursive configuration contract because the projection checker itself calls
the smaller checked-inference function.
-/

theorem psKernelCheckedInferenceCoreConfigurationSound_contract
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
    (hString : PsKernelStringEqSoundLaw)
    (hWhnf :
      PsKernelWhnfConfigurationSound whnf)
    (hDefEq :
      PsKernelDefEqConfigurationSound defeq) :
    PsKernelCheckedInferenceCoreConfigurationSound
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
                false
                expr then
            psKernelExprMapGet
              state.checkedInfer
              expr
          else
            Option.none) =
            Option.none ->
          PsKernelTypingJudgment
              context.environment
              context.localContext
              expr
              result ∧
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
            have hBackConfig :
                ∀ candidate : PsKernelCheckerState,
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
            have hBackTyping :
                ∀
                  (checkedExpr checkedType : PsKernelExpr),
                  PsKernelTypingJudgment
                      nextContext.environment
                      nextContext.localContext
                      checkedExpr
                      checkedType ->
                    PsKernelTypingJudgment
                      context.environment
                      context.localContext
                      checkedExpr
                      checkedType := by
              intro checkedExpr checkedType hTyping
              exact
                psKernelTypingJudgment_enterRecDepth_back
                  context
                  nextContext
                  checkedExpr
                  checkedType
                  hDepth
                  hTyping
            have hPublish :
                ∀
                  (baseState : PsKernelCheckerState)
                  (cacheExpr cacheResult : PsKernelExpr),
                  PsKernelCheckerConfigurationSound
                      nextContext
                      baseState ->
                    PsKernelTypingJudgment
                      nextContext.environment
                      nextContext.localContext
                      cacheExpr
                      cacheResult ->
                    PsKernelCheckerConfigurationSound
                      context
                      (psKernelCacheInferResult
                        baseState
                        false
                        cacheExpr
                        cacheResult) := by
              intro baseState cacheExpr cacheResult hBase hTyping
              exact
                hBackConfig
                  (psKernelCacheInferResult
                    baseState
                    false
                    cacheExpr
                    cacheResult)
                  (psKernelCacheInferResult_preserves_configuration
                    nextContext
                    baseState
                    false
                    cacheExpr
                    cacheResult
                    hBase
                    hTyping)
            have hLookupSound :
                PsKernelEnvironmentLookupSound
                  nextContext.environment := by
              intro query info hFind
              unfold psKernelEnvironmentFind at hFind
              have hRefine :=
                hNextConfig.1 query
              rw [← hRefine]
              exact hFind
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
                    have hTyping :
                        PsKernelTypingJudgment
                          nextContext.environment
                          nextContext.localContext
                          (PsKernelExpr.fvar name)
                          (psKernelLocalDeclType declaration) :=
                      PsKernelTypingJudgment.fvar
                        name
                        declaration
                        hFind
                    simp [
                      psKernelInferCoreWithFuel,
                      hMiss,
                      hDepth,
                      hFind
                    ] at hSuccess
                    rcases hSuccess with ⟨rfl, rfl⟩
                    exact
                      ⟨
                        hBackTyping
                          (PsKernelExpr.fvar name)
                          (psKernelLocalDeclType declaration)
                          hTyping,
                        hPublish
                          state
                          (PsKernelExpr.fvar name)
                          (psKernelLocalDeclType declaration)
                          hNextConfig
                          hTyping
                      ⟩
            | sort level =>
                have hTyping :
                    PsKernelTypingJudgment
                      nextContext.environment
                      nextContext.localContext
                      (PsKernelExpr.sort level)
                      (PsKernelExpr.sort
                        (PsKernelLevel.succ level)) :=
                  PsKernelTypingJudgment.sort level
                simp [
                  psKernelInferCoreWithFuel,
                  hMiss,
                  hDepth
                ] at hSuccess
                rcases hSuccess with ⟨rfl, rfl⟩
                exact
                  ⟨
                    hBackTyping
                      (PsKernelExpr.sort level)
                      (PsKernelExpr.sort
                        (PsKernelLevel.succ level))
                      hTyping,
                    hPublish
                      state
                      (PsKernelExpr.sort level)
                      (PsKernelExpr.sort
                        (PsKernelLevel.succ level))
                      hNextConfig
                      hTyping
                  ⟩
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
                        have hTyping :
                            PsKernelTypingJudgment
                              nextContext.environment
                              nextContext.localContext
                              (PsKernelExpr.const name levels)
                              inferred := by
                          exact
                            PsKernelTypingJudgment.const
                              name
                              levels
                              info
                              (hLookupSound name info hFind)
                              hArityEq
                        cases hUnsafe :
                            psKernelConstantInfoIsUnsafe info with
                        | true =>
                            cases hSafety :
                                psKernelDefinitionSafetyIsUnsafe
                                  nextContext.safety with
                            | false =>
                                simp [
                                  psKernelInferCoreWithFuel,
                                  hMiss,
                                  hDepth,
                                  hFind,
                                  hArityEq,
                                  hUnsafe,
                                  hSafety
                                ] at hSuccess
                            | true =>
                                simp [
                                  psKernelInferCoreWithFuel,
                                  hMiss,
                                  hDepth,
                                  hFind,
                                  hArityEq,
                                  hUnsafe,
                                  hSafety,
                                  inferred
                                ] at hSuccess
                                rcases hSuccess with ⟨rfl, rfl⟩
                                exact
                                  ⟨
                                    hBackTyping
                                      (PsKernelExpr.const name levels)
                                      inferred
                                      hTyping,
                                    hPublish
                                      state
                                      (PsKernelExpr.const name levels)
                                      inferred
                                      hNextConfig
                                      hTyping
                                  ⟩
                        | false =>
                            cases hPartial :
                                psKernelConstantInfoIsPartial info with
                            | true =>
                                cases hSafe :
                                    psKernelDefinitionSafetyIsSafe
                                      nextContext.safety with
                                | true =>
                                    simp [
                                      psKernelInferCoreWithFuel,
                                      hMiss,
                                      hDepth,
                                      hFind,
                                      hArityEq,
                                      hUnsafe,
                                      hPartial,
                                      hSafe
                                    ] at hSuccess
                                | false =>
                                    simp [
                                      psKernelInferCoreWithFuel,
                                      hMiss,
                                      hDepth,
                                      hFind,
                                      hArityEq,
                                      hUnsafe,
                                      hPartial,
                                      hSafe,
                                      inferred
                                    ] at hSuccess
                                    rcases hSuccess with ⟨rfl, rfl⟩
                                    exact
                                      ⟨
                                        hBackTyping
                                          (PsKernelExpr.const name levels)
                                          inferred
                                          hTyping,
                                        hPublish
                                          state
                                          (PsKernelExpr.const name levels)
                                          inferred
                                          hNextConfig
                                          hTyping
                                      ⟩
                            | false =>
                                simp [
                                  psKernelInferCoreWithFuel,
                                  hMiss,
                                  hDepth,
                                  hFind,
                                  hArityEq,
                                  hUnsafe,
                                  hPartial,
                                  inferred
                                ] at hSuccess
                                rcases hSuccess with ⟨rfl, rfl⟩
                                exact
                                  ⟨
                                    hBackTyping
                                      (PsKernelExpr.const name levels)
                                      inferred
                                      hTyping,
                                    hPublish
                                      state
                                      (PsKernelExpr.const name levels)
                                      inferred
                                      hNextConfig
                                      hTyping
                                  ⟩
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
                        have hTyping :
                            PsKernelTypingJudgment
                              nextContext.environment
                              nextContext.localContext
                              (PsKernelExpr.lit
                                (PsKernelLiteral.nat value))
                              (PsKernelExpr.const
                                psKernelNatName
                                List.nil) :=
                          PsKernelTypingJudgment.natLiteral value
                        simp [
                          psKernelInferCoreWithFuel,
                          hMiss,
                          hDepth,
                          hSize
                        ] at hSuccess
                        rcases hSuccess with ⟨rfl, rfl⟩
                        exact
                          ⟨
                            hBackTyping
                              (PsKernelExpr.lit
                                (PsKernelLiteral.nat value))
                              (PsKernelExpr.const
                                psKernelNatName
                                List.nil)
                              hTyping,
                            hPublish
                              state
                              (PsKernelExpr.lit
                                (PsKernelLiteral.nat value))
                              (PsKernelExpr.const
                                psKernelNatName
                                List.nil)
                              hNextConfig
                              hTyping
                          ⟩
                | str value =>
                    have hTyping :
                        PsKernelTypingJudgment
                          nextContext.environment
                          nextContext.localContext
                          (PsKernelExpr.lit
                            (PsKernelLiteral.str value))
                          (PsKernelExpr.const
                            psKernelStringName
                            List.nil) :=
                      PsKernelTypingJudgment.stringLiteral value
                    simp [
                      psKernelInferCoreWithFuel,
                      hMiss,
                      hDepth
                    ] at hSuccess
                    rcases hSuccess with ⟨rfl, rfl⟩
                    exact
                      ⟨
                        hBackTyping
                          (PsKernelExpr.lit
                            (PsKernelLiteral.str value))
                          (PsKernelExpr.const
                            psKernelStringName
                            List.nil)
                          hTyping,
                        hPublish
                          state
                          (PsKernelExpr.lit
                            (PsKernelLiteral.str value))
                          (PsKernelExpr.const
                            psKernelStringName
                            List.nil)
                          hNextConfig
                          hTyping
                      ⟩
            | mdata metadata body =>
                cases hBody :
                    psKernelInferCoreWithFuel
                      remaining
                      whnf
                      defeq
                      nextContext
                      state
                      body
                      false with
                | error error =>
                    simp [
                      psKernelInferCoreWithFuel,
                      hMiss,
                      hDepth,
                      hBody
                    ] at hSuccess
                | ok bodyRun =>
                    rcases bodyRun with ⟨bodyType, bodyState⟩
                    have hBodySemantic :=
                      ih
                        nextContext
                        state
                        bodyState
                        body
                        bodyType
                        hNextConfig
                        hBody
                    have hTyping :
                        PsKernelTypingJudgment
                          nextContext.environment
                          nextContext.localContext
                          (PsKernelExpr.mdata metadata body)
                          bodyType :=
                      PsKernelTypingJudgment.mdata
                        metadata
                        body
                        bodyType
                        hBodySemantic.1
                    simp [
                      psKernelInferCoreWithFuel,
                      hMiss,
                      hDepth,
                      hBody
                    ] at hSuccess
                    rcases hSuccess with ⟨rfl, rfl⟩
                    exact
                      ⟨
                        hBackTyping
                          (PsKernelExpr.mdata metadata body)
                          bodyType
                          hTyping,
                        hPublish
                          bodyState
                          (PsKernelExpr.mdata metadata body)
                          bodyType
                          hBodySemantic.2
                          hTyping
                      ⟩
            | app fn arg =>
                cases hFn :
                    psKernelInferCoreWithFuel
                      remaining
                      whnf
                      defeq
                      nextContext
                      state
                      fn
                      false with
                | error error =>
                    simp [
                      psKernelInferCoreWithFuel,
                      hMiss,
                      hDepth,
                      hFn
                    ] at hSuccess
                | ok fnRun =>
                    rcases fnRun with ⟨fnType, fnState⟩
                    have hFnSemantic :=
                      ih
                        nextContext
                        state
                        fnState
                        fn
                        fnType
                        hNextConfig
                        hFn
                    cases hForall :
                        psKernelEnsureForallWith
                          whnf
                          nextContext
                          fnState
                          fnType with
                    | error error =>
                        simp [
                          psKernelInferCoreWithFuel,
                          hMiss,
                          hDepth,
                          hFn,
                          hForall
                        ] at hSuccess
                    | ok forallRun =>
                        rcases forallRun with ⟨view, forallState⟩
                        have hForallSemantic :=
                          psKernelEnsureForallWith_configuration_refines
                            whnf
                            hWhnf
                            nextContext
                            fnState
                            forallState
                            fnType
                            view
                            hFnSemantic.2
                            hForall
                        cases hArg :
                            psKernelInferCoreWithFuel
                              remaining
                              whnf
                              defeq
                              nextContext
                              forallState
                              arg
                              false with
                        | error error =>
                            simp [
                              psKernelInferCoreWithFuel,
                              hMiss,
                              hDepth,
                              hFn,
                              hForall,
                              hArg
                            ] at hSuccess
                        | ok argRun =>
                            rcases argRun with ⟨argType, argState⟩
                            have hArgSemantic :=
                              ih
                                nextContext
                                forallState
                                argState
                                arg
                                argType
                                hForallSemantic.2
                                hArg
                            cases hEq :
                                psKernelExprEq
                                  argType
                                  view.domain with
                            | true =>
                                have hArgType :
                                    PsKernelDefEqJudgment
                                      nextContext.environment
                                      nextContext.localContext
                                      argType
                                      view.domain :=
                                  PsKernelDefEqJudgment.structural
                                    argType
                                    view.domain
                                    (psKernelExprEq_true_refines_structural
                                      argType
                                      view.domain
                                      hEq)
                                let inferred :=
                                  psKernelExprInstantiate1
                                    view.body
                                    arg
                                have hTyping :
                                    PsKernelTypingJudgment
                                      nextContext.environment
                                      nextContext.localContext
                                      (PsKernelExpr.app fn arg)
                                      inferred :=
                                  PsKernelTypingJudgment.app
                                    fn
                                    arg
                                    fnType
                                    argType
                                    view.domain
                                    view.body
                                    view.name
                                    view.binderInfo
                                    hFnSemantic.1
                                    hForallSemantic.1
                                    hArgSemantic.1
                                    hArgType
                                simp [
                                  psKernelInferCoreWithFuel,
                                  hMiss,
                                  hDepth,
                                  hFn,
                                  hForall,
                                  hArg,
                                  hEq,
                                  inferred
                                ] at hSuccess
                                rcases hSuccess with ⟨rfl, rfl⟩
                                exact
                                  ⟨
                                    hBackTyping
                                      (PsKernelExpr.app fn arg)
                                      inferred
                                      hTyping,
                                    hPublish
                                      argState
                                      (PsKernelExpr.app fn arg)
                                      inferred
                                      hArgSemantic.2
                                      hTyping
                                  ⟩
                            | false =>
                                let eqContext :=
                                  if
                                      psKernelExprIsEagerReduce arg then
                                    psKernelCheckerContextWithEagerReduce
                                      nextContext
                                      true
                                  else
                                    nextContext
                                have hEqConfig :
                                    PsKernelCheckerConfigurationSound
                                      eqContext
                                      argState := by
                                  unfold eqContext
                                  split
                                  next hEager =>
                                    exact
                                      psKernelCheckerContextWithEagerReduce_preserves_configuration
                                        nextContext
                                        argState
                                        true
                                        hArgSemantic.2
                                  next hNotEager =>
                                    exact hArgSemantic.2
                                cases hDefEqRun :
                                    defeq
                                      eqContext
                                      argState
                                      argType
                                      view.domain with
                                | error error =>
                                    simp [
                                      psKernelInferCoreWithFuel,
                                      hMiss,
                                      hDepth,
                                      hFn,
                                      hForall,
                                      hArg,
                                      hEq,
                                      eqContext,
                                      hDefEqRun
                                    ] at hSuccess
                                | ok eqRun =>
                                    rcases eqRun with ⟨eqValue, eqState⟩
                                    cases eqValue with
                                    | false =>
                                        simp [
                                          psKernelInferCoreWithFuel,
                                          hMiss,
                                          hDepth,
                                          hFn,
                                          hForall,
                                          hArg,
                                          hEq,
                                          eqContext,
                                          hDefEqRun
                                        ] at hSuccess
                                    | true =>
                                        have hEqSemantic :=
                                          hDefEq
                                            eqContext
                                            argState
                                            eqState
                                            argType
                                            view.domain
                                            true
                                            hEqConfig
                                            hDefEqRun
                                        have hEqEnvironment :
                                            eqContext.environment =
                                              nextContext.environment := by
                                          unfold eqContext
                                          split <;> rfl
                                        have hEqLocal :
                                            eqContext.localContext =
                                              nextContext.localContext := by
                                          unfold eqContext
                                          split <;> rfl
                                        have hEqStateConfig :
                                            PsKernelCheckerConfigurationSound
                                              nextContext
                                              eqState :=
                                          psKernelCheckerConfigurationSound_transport
                                            eqContext
                                            nextContext
                                            eqState
                                            hEqEnvironment
                                            hEqLocal
                                            hEqSemantic.1
                                        have hArgType :
                                            PsKernelDefEqJudgment
                                              nextContext.environment
                                              nextContext.localContext
                                              argType
                                              view.domain := by
                                          have hEqJudgment :=
                                            hEqSemantic.2 rfl
                                          rw [hEqEnvironment, hEqLocal] at hEqJudgment
                                          exact hEqJudgment
                                        let inferred :=
                                          psKernelExprInstantiate1
                                            view.body
                                            arg
                                        have hTyping :
                                            PsKernelTypingJudgment
                                              nextContext.environment
                                              nextContext.localContext
                                              (PsKernelExpr.app fn arg)
                                              inferred :=
                                          PsKernelTypingJudgment.app
                                            fn
                                            arg
                                            fnType
                                            argType
                                            view.domain
                                            view.body
                                            view.name
                                            view.binderInfo
                                            hFnSemantic.1
                                            hForallSemantic.1
                                            hArgSemantic.1
                                            hArgType
                                        simp [
                                          psKernelInferCoreWithFuel,
                                          hMiss,
                                          hDepth,
                                          hFn,
                                          hForall,
                                          hArg,
                                          hEq,
                                          eqContext,
                                          hDefEqRun,
                                          inferred
                                        ] at hSuccess
                                        rcases hSuccess with ⟨rfl, rfl⟩
                                        exact
                                          ⟨
                                            hBackTyping
                                              (PsKernelExpr.app fn arg)
                                              inferred
                                              hTyping,
                                            hPublish
                                              eqState
                                              (PsKernelExpr.app fn arg)
                                              inferred
                                              hEqStateConfig
                                              hTyping
                                          ⟩
            | lam name domain body binderInfo =>
                cases hDomain :
                    psKernelInferCoreWithFuel
                      remaining
                      whnf
                      defeq
                      nextContext
                      state
                      domain
                      false with
                | error error =>
                    simp [
                      psKernelInferCoreWithFuel,
                      hMiss,
                      hDepth,
                      hDomain
                    ] at hSuccess
                | ok domainRun =>
                    rcases domainRun with ⟨domainType, domainState⟩
                    have hDomainSemantic :=
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
                          psKernelInferCoreWithFuel,
                          hMiss,
                          hDepth,
                          hDomain,
                          hDomainSort
                        ] at hSuccess
                    | ok sortRun =>
                        rcases sortRun with ⟨domainLevel, sortState⟩
                        have hSortSemantic :=
                          psKernelEnsureSortWith_configuration_refines
                            whnf
                            hWhnf
                            nextContext
                            domainState
                            sortState
                            domainType
                            domainLevel
                            hDomainSemantic.2
                            hDomainSort
                        have hDomainTyping :
                            PsKernelTypingJudgment
                              nextContext.environment
                              nextContext.localContext
                              domain
                              (PsKernelExpr.sort domainLevel) :=
                          PsKernelTypingJudgment.convert
                            domain
                            domainType
                            (PsKernelExpr.sort domainLevel)
                            hDomainSemantic.1
                            hSortSemantic.1
                        let freshResult :=
                          psKernelCheckerStateFreshName
                            sortState
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
                        have hFreshState :
                            psKernelCheckerStateFreshName
                                sortState
                                name =
                              Prod.mk fresh state1 := by
                          rfl
                        have hFresh :
                            psKernelLocalContextFind
                                nextContext.localContext
                                fresh =
                              Option.none :=
                          psKernelCheckerStateFreshName_absent_of_configuration
                            nextContext
                            sortState
                            state1
                            name
                            fresh
                            hString
                            hSortSemantic.2
                            hFreshState
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
                              sortState
                              name
                              hSortSemantic.2
                        have hChildConfig :
                            PsKernelCheckerConfigurationSound
                              child
                              state1 := by
                          simpa [
                            freshResult,
                            fresh,
                            state1,
                            childLocal,
                            child
                          ] using
                            psKernelCheckerFreshLocal_preserves_configuration
                              nextContext
                              sortState
                              name
                              domain
                              binderInfo
                              hString
                              hSortSemantic.2
                        cases hBody :
                            psKernelInferCoreWithFuel
                              remaining
                              whnf
                              defeq
                              child
                              state1
                              openedBody
                              false with
                        | error error =>
                            simp [
                              psKernelInferCoreWithFuel,
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
                            rcases bodyRun with ⟨rawBodyType, bodyState⟩
                            have hBodySemantic :=
                              ih
                                child
                                state1
                                bodyState
                                openedBody
                                rawBodyType
                                hChildConfig
                                hBody
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
                            have hTyping :
                                PsKernelTypingJudgment
                                  nextContext.environment
                                  nextContext.localContext
                                  (PsKernelExpr.lam
                                    name domain body binderInfo)
                                  inferred := by
                              dsimp [inferred, closedBody, bodyType]
                              exact
                                PsKernelTypingJudgment.lam
                                  name
                                  fresh
                                  domain
                                  body
                                  rawBodyType
                                  binderInfo
                                  domainLevel
                                  hFresh
                                  hDomainTyping
                                  hBodySemantic.1
                            let scopedState :=
                              psKernelCheckerStateExitLocalScope
                                state1
                                bodyState
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
                              hDomain,
                              hDomainSort,
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
                              ⟨
                                hBackTyping
                                  (PsKernelExpr.lam
                                    name domain body binderInfo)
                                  inferred
                                  hTyping,
                                hPublish
                                  scopedState
                                  (PsKernelExpr.lam
                                    name domain body binderInfo)
                                  inferred
                                  hScopedConfig
                                  hTyping
                              ⟩
            | forallE name domain body binderInfo =>
                cases hDomain :
                    psKernelInferCoreWithFuel
                      remaining
                      whnf
                      defeq
                      nextContext
                      state
                      domain
                      false with
                | error error =>
                    simp [
                      psKernelInferCoreWithFuel,
                      hMiss,
                      hDepth,
                      hDomain
                    ] at hSuccess
                | ok domainRun =>
                    rcases domainRun with ⟨domainType, domainState⟩
                    have hDomainSemantic :=
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
                          psKernelInferCoreWithFuel,
                          hMiss,
                          hDepth,
                          hDomain,
                          hDomainSort
                        ] at hSuccess
                    | ok domainSortRun =>
                        rcases domainSortRun with
                          ⟨domainLevel, domainSortState⟩
                        have hDomainSortSemantic :=
                          psKernelEnsureSortWith_configuration_refines
                            whnf
                            hWhnf
                            nextContext
                            domainState
                            domainSortState
                            domainType
                            domainLevel
                            hDomainSemantic.2
                            hDomainSort
                        have hDomainTyping :
                            PsKernelTypingJudgment
                              nextContext.environment
                              nextContext.localContext
                              domain
                              (PsKernelExpr.sort domainLevel) :=
                          PsKernelTypingJudgment.convert
                            domain
                            domainType
                            (PsKernelExpr.sort domainLevel)
                            hDomainSemantic.1
                            hDomainSortSemantic.1
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
                        have hFreshState :
                            psKernelCheckerStateFreshName
                                domainSortState
                                name =
                              Prod.mk fresh state1 := by
                          rfl
                        have hFresh :
                            psKernelLocalContextFind
                                nextContext.localContext
                                fresh =
                              Option.none :=
                          psKernelCheckerStateFreshName_absent_of_configuration
                            nextContext
                            domainSortState
                            state1
                            name
                            fresh
                            hString
                            hDomainSortSemantic.2
                            hFreshState
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
                              hDomainSortSemantic.2
                        have hChildConfig :
                            PsKernelCheckerConfigurationSound
                              child
                              state1 := by
                          simpa [
                            freshResult,
                            fresh,
                            state1,
                            childLocal,
                            child
                          ] using
                            psKernelCheckerFreshLocal_preserves_configuration
                              nextContext
                              domainSortState
                              name
                              domain
                              binderInfo
                              hString
                              hDomainSortSemantic.2
                        cases hBody :
                            psKernelInferCoreWithFuel
                              remaining
                              whnf
                              defeq
                              child
                              state1
                              openedBody
                              false with
                        | error error =>
                            simp [
                              psKernelInferCoreWithFuel,
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
                            rcases bodyRun with ⟨bodyType, bodyState⟩
                            have hBodySemantic :=
                              ih
                                child
                                state1
                                bodyState
                                openedBody
                                bodyType
                                hChildConfig
                                hBody
                            cases hBodySort :
                                psKernelEnsureSortWith
                                  whnf
                                  child
                                  bodyState
                                  bodyType with
                            | error error =>
                                simp [
                                  psKernelInferCoreWithFuel,
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
                                have hBodySortSemantic :=
                                  psKernelEnsureSortWith_configuration_refines
                                    whnf
                                    hWhnf
                                    child
                                    bodyState
                                    bodySortState
                                    bodyType
                                    bodyLevel
                                    hBodySemantic.2
                                    hBodySort
                                have hBodyTyping :
                                    PsKernelTypingJudgment
                                      child.environment
                                      child.localContext
                                      openedBody
                                      (PsKernelExpr.sort bodyLevel) :=
                                  PsKernelTypingJudgment.convert
                                    openedBody
                                    bodyType
                                    (PsKernelExpr.sort bodyLevel)
                                    hBodySemantic.1
                                    hBodySortSemantic.1
                                let inferred :=
                                  PsKernelExpr.sort
                                    (psKernelLevelMkIMax
                                      domainLevel
                                      bodyLevel)
                                have hTyping :
                                    PsKernelTypingJudgment
                                      nextContext.environment
                                      nextContext.localContext
                                      (PsKernelExpr.forallE
                                        name domain body binderInfo)
                                      inferred := by
                                  simpa [
                                    inferred,
                                    child,
                                    psKernelCheckerContextWithLocalContext
                                  ] using
                                    (PsKernelTypingJudgment.forallE
                                      name
                                      fresh
                                      domain
                                      body
                                      binderInfo
                                      domainLevel
                                      bodyLevel
                                      hFresh
                                      hDomainTyping
                                      hBodyTyping)
                                let scopedState :=
                                  psKernelCheckerStateExitLocalScope
                                    state1
                                    bodySortState
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
                                  psKernelInferCoreWithFuel,
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
                                  ⟨
                                    hBackTyping
                                      (PsKernelExpr.forallE
                                        name domain body binderInfo)
                                      inferred
                                      hTyping,
                                    hPublish
                                      scopedState
                                      (PsKernelExpr.forallE
                                        name domain body binderInfo)
                                      inferred
                                      hScopedConfig
                                      hTyping
                                  ⟩
            | letE name type value body nondep =>
                cases hType :
                    psKernelInferCoreWithFuel
                      remaining
                      whnf
                      defeq
                      nextContext
                      state
                      type
                      false with
                | error error =>
                    simp [
                      psKernelInferCoreWithFuel,
                      hMiss,
                      hDepth,
                      hType
                    ] at hSuccess
                | ok typeRun =>
                    rcases typeRun with ⟨typeType, typeState⟩
                    have hTypeSemantic :=
                      ih
                        nextContext
                        state
                        typeState
                        type
                        typeType
                        hNextConfig
                        hType
                    cases hTypeSort :
                        psKernelEnsureSortWith
                          whnf
                          nextContext
                          typeState
                          typeType with
                    | error error =>
                        simp [
                          psKernelInferCoreWithFuel,
                          hMiss,
                          hDepth,
                          hType,
                          hTypeSort
                        ] at hSuccess
                    | ok typeSortRun =>
                        rcases typeSortRun with
                          ⟨typeLevel, typeSortState⟩
                        have hTypeSortSemantic :=
                          psKernelEnsureSortWith_configuration_refines
                            whnf
                            hWhnf
                            nextContext
                            typeState
                            typeSortState
                            typeType
                            typeLevel
                            hTypeSemantic.2
                            hTypeSort
                        have hTypeTyping :
                            PsKernelTypingJudgment
                              nextContext.environment
                              nextContext.localContext
                              type
                              (PsKernelExpr.sort typeLevel) :=
                          PsKernelTypingJudgment.convert
                            type
                            typeType
                            (PsKernelExpr.sort typeLevel)
                            hTypeSemantic.1
                            hTypeSortSemantic.1
                        cases hValue :
                            psKernelInferCoreWithFuel
                              remaining
                              whnf
                              defeq
                              nextContext
                              typeSortState
                              value
                              false with
                        | error error =>
                            simp [
                              psKernelInferCoreWithFuel,
                              hMiss,
                              hDepth,
                              hType,
                              hTypeSort,
                              hValue
                            ] at hSuccess
                        | ok valueRun =>
                            rcases valueRun with ⟨valueType, valueState⟩
                            have hValueSemantic :=
                              ih
                                nextContext
                                typeSortState
                                valueState
                                value
                                valueType
                                hTypeSortSemantic.2
                                hValue
                            cases hValueEq :
                                defeq
                                  nextContext
                                  valueState
                                  valueType
                                  type with
                            | error error =>
                                simp [
                                  psKernelInferCoreWithFuel,
                                  hMiss,
                                  hDepth,
                                  hType,
                                  hTypeSort,
                                  hValue,
                                  hValueEq
                                ] at hSuccess
                            | ok eqRun =>
                                rcases eqRun with ⟨eqValue, eqState⟩
                                cases eqValue with
                                | false =>
                                    simp [
                                      psKernelInferCoreWithFuel,
                                      hMiss,
                                      hDepth,
                                      hType,
                                      hTypeSort,
                                      hValue,
                                      hValueEq
                                    ] at hSuccess
                                | true =>
                                    have hEqSemantic :=
                                      hDefEq
                                        nextContext
                                        valueState
                                        eqState
                                        valueType
                                        type
                                        true
                                        hValueSemantic.2
                                        hValueEq
                                    let freshResult :=
                                      psKernelCheckerStateFreshName
                                        eqState
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
                                    have hFreshState :
                                        psKernelCheckerStateFreshName
                                            eqState
                                            name =
                                          Prod.mk fresh state1 := by
                                      rfl
                                    have hFresh :
                                        psKernelLocalContextFind
                                            nextContext.localContext
                                            fresh =
                                          Option.none :=
                                      psKernelCheckerStateFreshName_absent_of_configuration
                                        nextContext
                                        eqState
                                        state1
                                        name
                                        fresh
                                        hString
                                        hEqSemantic.1
                                        hFreshState
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
                                          eqState
                                          name
                                          hEqSemantic.1
                                    have hChildConfig :
                                        PsKernelCheckerConfigurationSound
                                          child
                                          state1 := by
                                      simpa [
                                        freshResult,
                                        fresh,
                                        state1,
                                        childLocal,
                                        child
                                      ] using
                                        psKernelCheckerFreshLet_preserves_configuration
                                          nextContext
                                          eqState
                                          name
                                          type
                                          value
                                          hString
                                          hEqSemantic.1
                                    cases hBody :
                                        psKernelInferCoreWithFuel
                                          remaining
                                          whnf
                                          defeq
                                          child
                                          state1
                                          openedBody
                                          false with
                                    | error error =>
                                        simp [
                                          psKernelInferCoreWithFuel,
                                          hMiss,
                                          hDepth,
                                          hType,
                                          hTypeSort,
                                          hValue,
                                          hValueEq,
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
                                        have hBodySemantic :=
                                          ih
                                            child
                                            state1
                                            bodyState
                                            openedBody
                                            bodyType
                                            hChildConfig
                                            hBody
                                        let reducedBodyType :=
                                          psKernelExprCheapBetaReduce
                                            bodyType
                                        let closedBody :=
                                          psKernelExprAbstractFVars
                                            reducedBodyType
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
                                            reducedBodyType
                                        have hTyping :
                                            PsKernelTypingJudgment
                                              nextContext.environment
                                              nextContext.localContext
                                              (PsKernelExpr.letE
                                                name type value body nondep)
                                              inferred := by
                                          dsimp [
                                            inferred,
                                            closedBody,
                                            reducedBodyType
                                          ]
                                          exact
                                            PsKernelTypingJudgment.letE
                                              name
                                              fresh
                                              type
                                              value
                                              body
                                              valueType
                                              bodyType
                                              nondep
                                              typeLevel
                                              hFresh
                                              hTypeTyping
                                              hValueSemantic.1
                                              (hEqSemantic.2 rfl)
                                              hBodySemantic.1
                                        let scopedState :=
                                          psKernelCheckerStateExitLocalScope
                                            state1
                                            bodyState
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
                                          hType,
                                          hTypeSort,
                                          hValue,
                                          hValueEq,
                                          freshResult,
                                          fresh,
                                          state1,
                                          childLocal,
                                          child,
                                          openedBody,
                                          hBody,
                                          reducedBodyType,
                                          closedBody,
                                          inferred,
                                          scopedState
                                        ] at hSuccess
                                        rcases hSuccess with ⟨rfl, rfl⟩
                                        exact
                                          ⟨
                                            hBackTyping
                                              (PsKernelExpr.letE
                                                name type value body nondep)
                                              inferred
                                              hTyping,
                                            hPublish
                                              scopedState
                                              (PsKernelExpr.letE
                                                name type value body nondep)
                                              inferred
                                              hScopedConfig
                                              hTyping
                                          ⟩
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
                      false
                cases hProjectionRun :
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
                      hProjectionRun
                    ] at hSuccess
                | ok projectionRun =>
                    rcases projectionRun with
                      ⟨projectionType, projectionState⟩
                    have hInferChecked :
                        PsKernelCheckedInferenceConfigurationSound
                          inferType := by
                      intro
                        projectionContext
                        projectionState0
                        projectionNext
                        projectionExpr
                        projectionResult
                        hProjectionConfig
                        hProjectionCoreRun
                      exact
                        ih
                          projectionContext
                          projectionState0
                          projectionNext
                          projectionExpr
                          projectionResult
                          hProjectionConfig
                          hProjectionCoreRun
                    have hProjectionSemantic :=
                      psKernelInferProjectionWith_configuration_sound
                        whnf
                        inferType
                        hWhnf
                        hInferChecked
                        nextContext
                        state
                        projectionState
                        typeName
                        index
                        structValue
                        projectionType
                        hNextConfig
                        hProjectionRun
                    simp [
                      psKernelInferCoreWithFuel,
                      hMiss,
                      hDepth,
                      inferType,
                      hProjectionRun
                    ] at hSuccess
                    rcases hSuccess with ⟨rfl, rfl⟩
                    exact
                      ⟨
                        hBackTyping
                          (PsKernelExpr.proj
                            typeName index structValue)
                          projectionType
                          hProjectionSemantic.1,
                        hPublish
                          projectionState
                          (PsKernelExpr.proj
                            typeName index structValue)
                          projectionType
                          hProjectionSemantic.2
                          hProjectionSemantic.1
                      ⟩
      cases hEligible :
          psKernelInferCacheEligible
            false
            expr with
      | false =>
          exact
            hMissCase
              (by simp [hEligible])
      | true =>
          cases hGet :
              psKernelExprMapGet
                state.checkedInfer
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
                  have hStateSound :=
                    hConfig.2.2
                  rcases hStateSound with
                    ⟨_hInferOnly, hChecked, _hWhnfCore,
                      _hWhnfCache, _hUnfold, _hDefEqCache⟩
                  exact
                    ⟨
                      hChecked expr cached hGet,
                      hConfig
                    ⟩
