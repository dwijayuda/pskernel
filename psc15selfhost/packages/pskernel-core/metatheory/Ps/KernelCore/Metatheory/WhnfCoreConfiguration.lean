import Ps.KernelCore.Metatheory.WhnfCoreProjection
import Ps.KernelCore.Metatheory.WhnfCoreApplication

/-
Concrete configuration-aware soundness for WHNF core.

The two dense branches are delegated to registered refinement modules:
projection and application.  This theorem owns the fuel induction, semantic-cache
hit, reflexive heads, metadata/local-let reduction, and zeta reduction.
-/

theorem psKernelWhnfCoreWithFuel_configuration_sound_contract
    (fuel : Nat)
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
    (hPublic :
      PsKernelWhnfConfigurationSound publicWhnf)
    (hRecursor :
      PsKernelRecursorReductionConfigurationSound
        reduceRecursor)
    (hBeta :
      PsKernelBetaSpineSoundLaw) :
    PsKernelWhnfCoreConfigurationSound
      (psKernelWhnfCoreWithFuel
        fuel
        publicWhnf
        reduceRecursor) := by
  induction fuel with
  | zero =>
      intro
        context state nextState expr result
        cheapRec cheapProj hConfig hSuccess
      simp [psKernelWhnfCoreWithFuel] at hSuccess
  | succ remaining ih =>
      intro
        context state nextState expr result
        cheapRec cheapProj hConfig hSuccess
      cases hDepth :
          psKernelCheckerContextEnterRecDepth
            context with
      | error error =>
          simp [
            psKernelWhnfCoreWithFuel,
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
          have hBackReduction :
              ∀ (left right : PsKernelExpr),
                PsKernelReductionClosure
                    nextContext.environment
                    nextContext.localContext
                    left
                    right ->
                  PsKernelReductionClosure
                    context.environment
                    context.localContext
                    left
                    right := by
            intro left right hReduction
            exact
              psKernelReductionClosure_enterRecDepth_back
                context
                nextContext
                left
                right
                hDepth
                hReduction
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
          have hCacheSound :
              PsKernelReductionCacheSound
                nextContext.environment
                nextContext.localContext
                state.whnfCore := by
            rcases hNextConfig.2.2 with
              ⟨_hInferOnly, _hChecked, hWhnfCore,
                _hWhnf, _hUnfold, _hDefEq⟩
            exact hWhnfCore
          cases expr with
          | bvar index =>
              simp [
                psKernelWhnfCoreWithFuel,
                hDepth
              ] at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              exact
                ⟨
                  PsKernelReductionClosure.refl
                    (PsKernelExpr.bvar index),
                  hConfig
                ⟩
          | sort level =>
              simp [
                psKernelWhnfCoreWithFuel,
                hDepth
              ] at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              exact
                ⟨
                  PsKernelReductionClosure.refl
                    (PsKernelExpr.sort level),
                  hConfig
                ⟩
          | mvar name =>
              simp [
                psKernelWhnfCoreWithFuel,
                hDepth
              ] at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              exact
                ⟨
                  PsKernelReductionClosure.refl
                    (PsKernelExpr.mvar name),
                  hConfig
                ⟩
          | forallE name domain body binderInfo =>
              simp [
                psKernelWhnfCoreWithFuel,
                hDepth
              ] at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              exact
                ⟨
                  PsKernelReductionClosure.refl
                    (PsKernelExpr.forallE
                      name domain body binderInfo),
                  hConfig
                ⟩
          | const name levels =>
              simp [
                psKernelWhnfCoreWithFuel,
                hDepth
              ] at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              exact
                ⟨
                  PsKernelReductionClosure.refl
                    (PsKernelExpr.const name levels),
                  hConfig
                ⟩
          | lam name type body binderInfo =>
              simp [
                psKernelWhnfCoreWithFuel,
                hDepth
              ] at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              exact
                ⟨
                  PsKernelReductionClosure.refl
                    (PsKernelExpr.lam
                      name type body binderInfo),
                  hConfig
                ⟩
          | lit literal =>
              simp [
                psKernelWhnfCoreWithFuel,
                hDepth
              ] at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              exact
                ⟨
                  PsKernelReductionClosure.refl
                    (PsKernelExpr.lit literal),
                  hConfig
                ⟩
          | mdata metadata body =>
              cases hRun :
                  psKernelWhnfCoreWithFuel
                    remaining
                    publicWhnf
                    reduceRecursor
                    nextContext
                    state
                    body
                    cheapRec
                    cheapProj with
              | error error =>
                  simp [
                    psKernelWhnfCoreWithFuel,
                    hDepth,
                    hRun
                  ] at hSuccess
              | ok run =>
                  rcases run with ⟨reduced, reducedState⟩
                  have hRest :=
                    ih
                      nextContext
                      state
                      reducedState
                      body
                      reduced
                      cheapRec
                      cheapProj
                      hNextConfig
                      hRun
                  have hReduction :
                      PsKernelReductionClosure
                        nextContext.environment
                        nextContext.localContext
                        (PsKernelExpr.mdata metadata body)
                        reduced :=
                    PsKernelReductionClosure.cons
                      (PsKernelExpr.mdata metadata body)
                      body
                      reduced
                      (PsKernelReductionStep.metadata
                        metadata body)
                      hRest.1
                  simp [
                    psKernelWhnfCoreWithFuel,
                    hDepth,
                    hRun
                  ] at hSuccess
                  rcases hSuccess with ⟨rfl, rfl⟩
                  exact
                    ⟨
                      hBackReduction
                        (PsKernelExpr.mdata metadata body)
                        reduced
                        hReduction,
                      hBackConfig reducedState hRest.2
                    ⟩
          | fvar name =>
              cases hFind :
                  psKernelLocalContextFind
                    nextContext.localContext
                    name with
              | none =>
                  simp [
                    psKernelWhnfCoreWithFuel,
                    hDepth,
                    hFind
                  ] at hSuccess
                  rcases hSuccess with ⟨rfl, rfl⟩
                  exact
                    ⟨
                      PsKernelReductionClosure.refl
                        (PsKernelExpr.fvar name),
                      hConfig
                    ⟩
              | some declaration =>
                  cases hValue :
                      psKernelLocalDeclValue
                        declaration with
                  | none =>
                      simp [
                        psKernelWhnfCoreWithFuel,
                        hDepth,
                        hFind,
                        hValue
                      ] at hSuccess
                      rcases hSuccess with ⟨rfl, rfl⟩
                      exact
                        ⟨
                          PsKernelReductionClosure.refl
                            (PsKernelExpr.fvar name),
                          hConfig
                        ⟩
                  | some value =>
                      cases hRun :
                          psKernelWhnfCoreWithFuel
                            remaining
                            publicWhnf
                            reduceRecursor
                            nextContext
                            state
                            value
                            cheapRec
                            cheapProj with
                      | error error =>
                          simp [
                            psKernelWhnfCoreWithFuel,
                            hDepth,
                            hFind,
                            hValue,
                            hRun
                          ] at hSuccess
                      | ok run =>
                          rcases run with
                            ⟨reduced, reducedState⟩
                          have hRest :=
                            ih
                              nextContext
                              state
                              reducedState
                              value
                              reduced
                              cheapRec
                              cheapProj
                              hNextConfig
                              hRun
                          have hReduction :
                              PsKernelReductionClosure
                                nextContext.environment
                                nextContext.localContext
                                (PsKernelExpr.fvar name)
                                reduced :=
                            PsKernelReductionClosure.cons
                              (PsKernelExpr.fvar name)
                              value
                              reduced
                              (PsKernelReductionStep.localLet
                                name
                                declaration
                                value
                                hFind
                                hValue)
                              hRest.1
                          simp [
                            psKernelWhnfCoreWithFuel,
                            hDepth,
                            hFind,
                            hValue,
                            hRun
                          ] at hSuccess
                          rcases hSuccess with ⟨rfl, rfl⟩
                          exact
                            ⟨
                              hBackReduction
                                (PsKernelExpr.fvar name)
                                reduced
                                hReduction,
                              hBackConfig
                                reducedState
                                hRest.2
                            ⟩
          | letE name type value body nondep =>
              let original :=
                PsKernelExpr.letE
                  name type value body nondep
              cases hEligible :
                  psKernelSemanticCacheEligible original with
              | true =>
                  cases hGet :
                      psKernelExprMapGet
                        state.whnfCore
                        original with
                  | some cached =>
                      simp [
                        psKernelWhnfCoreWithFuel,
                        hDepth,
                        original,
                        hEligible,
                        hGet
                      ] at hSuccess
                      rcases hSuccess with ⟨rfl, rfl⟩
                      exact
                        ⟨
                          hBackReduction
                            original
                            cached
                            (hCacheSound
                              original
                              cached
                              hGet),
                          hConfig
                        ⟩
                  | none =>
                      let reduced :=
                        psKernelExprInstantiate1 body value
                      cases hRun :
                          psKernelWhnfCoreWithFuel
                            remaining
                            publicWhnf
                            reduceRecursor
                            nextContext
                            state
                            reduced
                            cheapRec
                            cheapProj with
                      | error error =>
                          simp [
                            psKernelWhnfCoreWithFuel,
                            hDepth,
                            original,
                            hEligible,
                            hGet,
                            reduced,
                            hRun
                          ] at hSuccess
                      | ok run =>
                          rcases run with
                            ⟨candidate, candidateState⟩
                          have hRest :=
                            ih
                              nextContext
                              state
                              candidateState
                              reduced
                              candidate
                              cheapRec
                              cheapProj
                              hNextConfig
                              hRun
                          have hReduction :
                              PsKernelReductionClosure
                                nextContext.environment
                                nextContext.localContext
                                original
                                candidate :=
                            PsKernelReductionClosure.cons
                              original
                              reduced
                              candidate
                              (PsKernelReductionStep.zeta
                                name type value body nondep)
                              hRest.1
                          have hFinish :
                              psKernelWhnfCoreFinish
                                  original
                                  cheapProj
                                  candidate
                                  candidateState =
                                Except.ok
                                  (Prod.mk result nextState) := by
                            simpa [
                              psKernelWhnfCoreWithFuel,
                              hDepth,
                              original,
                              hEligible,
                              hGet,
                              reduced,
                              hRun
                            ] using hSuccess
                          have hFinishSemantic :=
                            psKernelWhnfCoreFinish_success_refines
                              nextContext
                              candidateState
                              nextState
                              original
                              candidate
                              result
                              cheapProj
                              hRest.2
                              hReduction
                              hFinish
                          have hResult :
                              result = candidate :=
                            hFinishSemantic.1
                          subst result
                          exact
                            ⟨
                              hBackReduction
                                original
                                candidate
                                hReduction,
                              hBackConfig
                                nextState
                                hFinishSemantic.2
                            ⟩
              | false =>
                  let reduced :=
                    psKernelExprInstantiate1 body value
                  cases hRun :
                      psKernelWhnfCoreWithFuel
                        remaining
                        publicWhnf
                        reduceRecursor
                        nextContext
                        state
                        reduced
                        cheapRec
                        cheapProj with
                  | error error =>
                      simp [
                        psKernelWhnfCoreWithFuel,
                        hDepth,
                        original,
                        hEligible,
                        reduced,
                        hRun
                      ] at hSuccess
                  | ok run =>
                      rcases run with
                        ⟨candidate, candidateState⟩
                      have hRest :=
                        ih
                          nextContext
                          state
                          candidateState
                          reduced
                          candidate
                          cheapRec
                          cheapProj
                          hNextConfig
                          hRun
                      have hReduction :
                          PsKernelReductionClosure
                            nextContext.environment
                            nextContext.localContext
                            original
                            candidate :=
                        PsKernelReductionClosure.cons
                          original
                          reduced
                          candidate
                          (PsKernelReductionStep.zeta
                            name type value body nondep)
                          hRest.1
                      have hFinish :
                          psKernelWhnfCoreFinish
                              original
                              cheapProj
                              candidate
                              candidateState =
                            Except.ok
                              (Prod.mk result nextState) := by
                        simpa [
                          psKernelWhnfCoreWithFuel,
                          hDepth,
                          original,
                          hEligible,
                          reduced,
                          hRun
                        ] using hSuccess
                      have hFinishSemantic :=
                        psKernelWhnfCoreFinish_success_refines
                          nextContext
                          candidateState
                          nextState
                          original
                          candidate
                          result
                          cheapProj
                          hRest.2
                          hReduction
                          hFinish
                      have hResult :
                          result = candidate :=
                        hFinishSemantic.1
                      subst result
                      exact
                        ⟨
                          hBackReduction
                            original
                            candidate
                            hReduction,
                          hBackConfig
                            nextState
                            hFinishSemantic.2
                        ⟩
          | proj typeName index structValue =>
              let original :=
                PsKernelExpr.proj
                  typeName index structValue
              cases hEligible :
                  psKernelSemanticCacheEligible original with
              | true =>
                  cases hGet :
                      psKernelExprMapGet
                        state.whnfCore
                        original with
                  | some cached =>
                      simp [
                        psKernelWhnfCoreWithFuel,
                        hDepth,
                        original,
                        hEligible,
                        hGet
                      ] at hSuccess
                      rcases hSuccess with ⟨rfl, rfl⟩
                      exact
                        ⟨
                          hBackReduction
                            original
                            cached
                            (hCacheSound
                              original
                              cached
                              hGet),
                          hConfig
                        ⟩
                  | none =>
                      exact
                        psKernelWhnfCoreProjection_configuration_refines
                          remaining
                          publicWhnf
                          reduceRecursor
                          hPublic
                          ih
                          context
                          nextContext
                          state
                          nextState
                          typeName
                          index
                          structValue
                          result
                          cheapRec
                          cheapProj
                          hConfig
                          hDepth
                          (by
                            simp [
                              original,
                              hEligible,
                              hGet
                            ])
                          hSuccess
              | false =>
                  exact
                    psKernelWhnfCoreProjection_configuration_refines
                      remaining
                      publicWhnf
                      reduceRecursor
                      hPublic
                      ih
                      context
                      nextContext
                      state
                      nextState
                      typeName
                      index
                      structValue
                      result
                      cheapRec
                      cheapProj
                      hConfig
                      hDepth
                      (by
                        simp [
                          original,
                          hEligible
                        ])
                      hSuccess
          | app appFn appArg =>
              let original :=
                PsKernelExpr.app appFn appArg
              cases hEligible :
                  psKernelSemanticCacheEligible original with
              | true =>
                  cases hGet :
                      psKernelExprMapGet
                        state.whnfCore
                        original with
                  | some cached =>
                      simp [
                        psKernelWhnfCoreWithFuel,
                        hDepth,
                        original,
                        hEligible,
                        hGet
                      ] at hSuccess
                      rcases hSuccess with ⟨rfl, rfl⟩
                      exact
                        ⟨
                          hBackReduction
                            original
                            cached
                            (hCacheSound
                              original
                              cached
                              hGet),
                          hConfig
                        ⟩
                  | none =>
                      exact
                        psKernelWhnfCoreApplication_configuration_refines
                          remaining
                          publicWhnf
                          reduceRecursor
                          ih
                          hRecursor
                          hBeta
                          context
                          nextContext
                          state
                          nextState
                          appFn
                          appArg
                          result
                          cheapRec
                          cheapProj
                          hConfig
                          hDepth
                          (by
                            simp [
                              original,
                              hEligible,
                              hGet
                            ])
                          hSuccess
              | false =>
                  exact
                    psKernelWhnfCoreApplication_configuration_refines
                      remaining
                      publicWhnf
                      reduceRecursor
                      ih
                      hRecursor
                      hBeta
                      context
                      nextContext
                      state
                      nextState
                      appFn
                      appArg
                      result
                      cheapRec
                      cheapProj
                      hConfig
                      hDepth
                      (by
                        simp [
                          original,
                          hEligible
                        ])
                      hSuccess


/-
Public WHNF always invokes WHNF core with both cheap-reduction flags disabled.
Expose that specialization directly so the public composition layer does not
need to reopen the core fuel induction.
-/
theorem psKernelWhnfCoreWithFuel_public_configuration_refines
    (fuel : Nat)
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
    (hPublic :
      PsKernelWhnfConfigurationSound publicWhnf)
    (hRecursor :
      PsKernelRecursorReductionConfigurationSound
        reduceRecursor)
    (hBeta :
      PsKernelBetaSpineSoundLaw)
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (expr result : PsKernelExpr)
    (hConfig :
      PsKernelCheckerConfigurationSound context state)
    (hSuccess :
      psKernelWhnfCoreWithFuel
          fuel
          publicWhnf
          reduceRecursor
          context
          state
          expr
          false
          false =
        Except.ok (Prod.mk result nextState)) :
    PsKernelReductionClosure
        context.environment
        context.localContext
        expr
        result ∧
      PsKernelCheckerConfigurationSound
        context
        nextState :=
  psKernelWhnfCoreWithFuel_configuration_sound_contract
    fuel
    publicWhnf
    reduceRecursor
    hPublic
    hRecursor
    hBeta
    context
    state
    nextState
    expr
    result
    false
    false
    hConfig
    hSuccess
