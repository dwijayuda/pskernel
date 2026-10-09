import Ps.KernelCore.Metatheory.WhnfCoreConfiguration
import Ps.KernelCore.Metatheory.PrimitiveNatReduction
import Ps.KernelCore.Metatheory.NativeReduction
import Ps.KernelCore.Metatheory.Delta

/-
Public-WHNF composition layer.

WHNF core is already proved by fuel induction.  This module proves the
observable post-core pipeline:
  core -> trusted native reduction -> primitive Nat reduction -> delta unfold
  -> final WHNF cache publication.

Native evaluator correctness remains an explicit TCB law; primitive Nat and
delta behavior are discharged internally.
-/

theorem psKernelWhnfAfterCore_configuration_refines
    (continueWhnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (hContinue :
      PsKernelWhnfConfigurationSound continueWhnf)
    (hNative :
      PsKernelNativeReductionSoundLaw)
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (original core result : PsKernelExpr)
    (hConfig :
      PsKernelCheckerConfigurationSound context state)
    (hCore :
      PsKernelReductionClosure
        context.environment
        context.localContext
        original
        core)
    (hSuccess :
      psKernelWhnfAfterCore
          continueWhnf
          context
          state
          original
          core =
        Except.ok (Prod.mk result nextState)) :
    PsKernelReductionClosure
        context.environment
        context.localContext
        original
        result ∧
      PsKernelCheckerConfigurationSound
        context
        nextState := by
  cases hNativeRun :
      psKernelReduceNative context core with
  | error error =>
      simp [
        psKernelWhnfAfterCore,
        hNativeRun
      ] at hSuccess
  | ok nativeAnswer =>
      cases nativeAnswer with
      | some nativeValue =>
          have hNativeReduction :
              PsKernelReductionClosure
                context.environment
                context.localContext
                core
                nativeValue :=
            hNative
              context
              core
              nativeValue
              hNativeRun
          have hCombined :
              PsKernelReductionClosure
                context.environment
                context.localContext
                original
                nativeValue :=
            psKernelReductionClosure_transitive
              context.environment
              context.localContext
              original
              core
              nativeValue
              hCore
              hNativeReduction
          have hFinish :
              psKernelWhnfFinish
                  original
                  nativeValue
                  state =
                Except.ok
                  (Prod.mk result nextState) := by
            simpa [
              psKernelWhnfAfterCore,
              hNativeRun
            ] using hSuccess
          have hFinishSemantic :=
            psKernelWhnfFinish_success_refines
              context
              state
              nextState
              original
              nativeValue
              result
              hConfig
              hCombined
              hFinish
          have hResult : result = nativeValue :=
            hFinishSemantic.1
          subst result
          exact
            ⟨hCombined, hFinishSemantic.2⟩
      | none =>
          have hNatSound :=
            psKernelReduceNatWith_configuration_sound
              continueWhnf
              hContinue
          cases hNatRun :
              psKernelReduceNatWith
                continueWhnf
                context
                state
                core with
          | error error =>
              simp [
                psKernelWhnfAfterCore,
                hNativeRun,
                hNatRun
              ] at hSuccess
          | ok natRun =>
              rcases natRun with ⟨natAnswer, natState⟩
              have hNatSemantic :=
                hNatSound
                  context
                  state
                  natState
                  core
                  natAnswer
                  hConfig
                  hNatRun
              cases natAnswer with
              | some natValue =>
                  have hNatReduction :
                      PsKernelReductionClosure
                        context.environment
                        context.localContext
                        core
                        natValue := by
                    simpa using hNatSemantic.2
                  have hCombined :
                      PsKernelReductionClosure
                        context.environment
                        context.localContext
                        original
                        natValue :=
                    psKernelReductionClosure_transitive
                      context.environment
                      context.localContext
                      original
                      core
                      natValue
                      hCore
                      hNatReduction
                  have hFinish :
                      psKernelWhnfFinish
                          original
                          natValue
                          natState =
                        Except.ok
                          (Prod.mk result nextState) := by
                    simpa [
                      psKernelWhnfAfterCore,
                      hNativeRun,
                      hNatRun
                    ] using hSuccess
                  have hFinishSemantic :=
                    psKernelWhnfFinish_success_refines
                      context
                      natState
                      nextState
                      original
                      natValue
                      result
                      hNatSemantic.1
                      hCombined
                      hFinish
                  have hResult : result = natValue :=
                    hFinishSemantic.1
                  subst result
                  exact
                    ⟨hCombined, hFinishSemantic.2⟩
              | none =>
                  cases hUnfold :
                      psKernelUnfoldDefinition
                        context
                        core with
                  | none =>
                      have hFinish :
                          psKernelWhnfFinish
                              original
                              core
                              natState =
                            Except.ok
                              (Prod.mk result nextState) := by
                        simpa [
                          psKernelWhnfAfterCore,
                          hNativeRun,
                          hNatRun,
                          hUnfold
                        ] using hSuccess
                      have hFinishSemantic :=
                        psKernelWhnfFinish_success_refines
                          context
                          natState
                          nextState
                          original
                          core
                          result
                          hNatSemantic.1
                          hCore
                          hFinish
                      have hResult : result = core :=
                        hFinishSemantic.1
                      subst result
                      exact
                        ⟨hCore, hFinishSemantic.2⟩
                  | some unfolded =>
                      have hUnfoldReduction :
                          PsKernelReductionClosure
                            context.environment
                            context.localContext
                            core
                            unfolded :=
                        psKernelUnfoldDefinition_some_refines_closure
                          context
                          core
                          unfolded
                          hConfig.1
                          hUnfold
                      have hToUnfolded :
                          PsKernelReductionClosure
                            context.environment
                            context.localContext
                            original
                            unfolded :=
                        psKernelReductionClosure_transitive
                          context.environment
                          context.localContext
                          original
                          core
                          unfolded
                          hCore
                          hUnfoldReduction
                      cases hContinueRun :
                          continueWhnf
                            context
                            natState
                            unfolded with
                      | error error =>
                          simp [
                            psKernelWhnfAfterCore,
                            hNativeRun,
                            hNatRun,
                            hUnfold,
                            hContinueRun
                          ] at hSuccess
                      | ok continueRun =>
                          rcases continueRun with
                            ⟨continued, continuedState⟩
                          have hContinueSemantic :=
                            hContinue
                              context
                              natState
                              continuedState
                              unfolded
                              continued
                              hNatSemantic.1
                              hContinueRun
                          have hCombined :
                              PsKernelReductionClosure
                                context.environment
                                context.localContext
                                original
                                continued :=
                            psKernelReductionClosure_transitive
                              context.environment
                              context.localContext
                              original
                              unfolded
                              continued
                              hToUnfolded
                              hContinueSemantic.1
                          have hFinish :
                              psKernelWhnfFinish
                                  original
                                  continued
                                  continuedState =
                                Except.ok
                                  (Prod.mk result nextState) := by
                            simpa [
                              psKernelWhnfAfterCore,
                              hNativeRun,
                              hNatRun,
                              hUnfold,
                              hContinueRun
                            ] using hSuccess
                          have hFinishSemantic :=
                            psKernelWhnfFinish_success_refines
                              context
                              continuedState
                              nextState
                              original
                              continued
                              result
                              hContinueSemantic.2
                              hCombined
                              hFinish
                          have hResult : result = continued :=
                            hFinishSemantic.1
                          subst result
                          exact
                            ⟨hCombined, hFinishSemantic.2⟩


theorem psKernelWhnfCoreMiss_configuration_refines
    (remaining : Nat)
    (reduceRecursor :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Bool ->
      Bool ->
      Except String
        (Prod (Option PsKernelExpr) PsKernelCheckerState))
    (hPublic :
      PsKernelWhnfConfigurationSound
        (fun nextContext nextState nextExpr =>
          psKernelWhnfWithFuel
            remaining
            reduceRecursor
            nextContext
            nextState
            nextExpr))
    (hRecursor :
      PsKernelRecursorReductionConfigurationSound
        reduceRecursor)
    (hBeta :
      PsKernelBetaSpineSoundLaw)
    (hNative :
      PsKernelNativeReductionSoundLaw)
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (expr result : PsKernelExpr)
    (hConfig :
      PsKernelCheckerConfigurationSound context state)
    (hSuccess :
      (match
          psKernelWhnfCoreWithFuel
            remaining
            (fun nextContext nextState nextExpr =>
          psKernelWhnfWithFuel
            remaining
            reduceRecursor
            nextContext
            nextState
            nextExpr)
            reduceRecursor
            context
            state
            expr
            false
            false with
       | Except.error error =>
           Except.error error
       | Except.ok coreResult =>
           psKernelWhnfAfterCore
             (fun nextContext nextState nextExpr =>
          psKernelWhnfWithFuel
            remaining
            reduceRecursor
            nextContext
            nextState
            nextExpr)
             context
             (Prod.snd coreResult)
             expr
             (Prod.fst coreResult)) =
        Except.ok (Prod.mk result nextState)) :
    PsKernelReductionClosure
        context.environment
        context.localContext
        expr
        result ∧
      PsKernelCheckerConfigurationSound context nextState := by
  cases hCore :
      psKernelWhnfCoreWithFuel
        remaining
        (fun nextContext nextState nextExpr =>
          psKernelWhnfWithFuel
            remaining
            reduceRecursor
            nextContext
            nextState
            nextExpr)
        reduceRecursor
        context
        state
        expr
        false
        false with
  | error error =>
      simp [hCore] at hSuccess
  | ok coreRun =>
      rcases coreRun with ⟨core, coreState⟩
      have hCoreSemantic :=
        psKernelWhnfCoreWithFuel_public_configuration_refines
          remaining
          (fun nextContext nextState nextExpr =>
          psKernelWhnfWithFuel
            remaining
            reduceRecursor
            nextContext
            nextState
            nextExpr)
          reduceRecursor
          hPublic
          hRecursor
          hBeta
          context
          state
          coreState
          expr
          core
          hConfig
          hCore
      have hAfter :
          psKernelWhnfAfterCore
              (fun nextContext nextState nextExpr =>
          psKernelWhnfWithFuel
            remaining
            reduceRecursor
            nextContext
            nextState
            nextExpr)
              context
              coreState
              expr
              core =
            Except.ok (Prod.mk result nextState) := by
        simpa [hCore] using hSuccess
      exact
        psKernelWhnfAfterCore_configuration_refines
          (fun nextContext nextState nextExpr =>
          psKernelWhnfWithFuel
            remaining
            reduceRecursor
            nextContext
            nextState
            nextExpr)
          hPublic
          hNative
          context
          coreState
          nextState
          expr
          core
          result
          hCoreSemantic.2
          hCoreSemantic.1
          hAfter


def psKernelWhnfCachedCoreRun
    (remaining : Nat)
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
    (expr : PsKernelExpr) :
    Except String (Prod PsKernelExpr PsKernelCheckerState) :=
  match
      if psKernelSemanticCacheEligible expr then
        psKernelExprMapGet state.whnf expr
      else
        Option.none with
  | Option.some cached =>
      Except.ok (Prod.mk cached state)
  | Option.none =>
      match
          psKernelWhnfCoreWithFuel
            remaining
            (fun nextContext nextState nextExpr =>
              psKernelWhnfWithFuel
                remaining
                reduceRecursor
                nextContext
                nextState
                nextExpr)
            reduceRecursor
            context
            state
            expr
            false
            false with
      | Except.error error =>
          Except.error error
      | Except.ok coreResult =>
          psKernelWhnfAfterCore
            (fun nextContext nextState nextExpr =>
              psKernelWhnfWithFuel
                remaining
                reduceRecursor
                nextContext
                nextState
                nextExpr)
            context
            (Prod.snd coreResult)
            expr
            (Prod.fst coreResult)


theorem psKernelWhnfCachedCore_configuration_refines
    (remaining : Nat)
    (reduceRecursor :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Bool ->
      Bool ->
      Except String
        (Prod (Option PsKernelExpr) PsKernelCheckerState))
    (hPublic :
      PsKernelWhnfConfigurationSound
        (fun nextContext nextState nextExpr =>
          psKernelWhnfWithFuel
            remaining
            reduceRecursor
            nextContext
            nextState
            nextExpr))
    (hRecursor :
      PsKernelRecursorReductionConfigurationSound
        reduceRecursor)
    (hBeta :
      PsKernelBetaSpineSoundLaw)
    (hNative :
      PsKernelNativeReductionSoundLaw)
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (expr result : PsKernelExpr)
    (hConfig :
      PsKernelCheckerConfigurationSound context state)
    (hSuccess :
      psKernelWhnfCachedCoreRun
          remaining
          reduceRecursor
          context
          state
          expr =
        Except.ok (Prod.mk result nextState)) :
    PsKernelReductionClosure
        context.environment
        context.localContext
        expr
        result ∧
      PsKernelCheckerConfigurationSound context nextState := by
  unfold psKernelWhnfCachedCoreRun at hSuccess
  have hCacheSound :
      PsKernelReductionCacheSound
        context.environment
        context.localContext
        state.whnf := by
    rcases hConfig.2.2 with
      ⟨_hInferOnly, _hChecked, _hWhnfCore,
        hWhnf, _hUnfold, _hDefEq⟩
    exact hWhnf
  cases hEligible :
      psKernelSemanticCacheEligible expr with
  | true =>
      cases hGet :
          psKernelExprMapGet state.whnf expr with
      | some cached =>
          simp [hEligible, hGet] at hSuccess
          rcases hSuccess with ⟨rfl, rfl⟩
          exact
            ⟨hCacheSound expr cached hGet, hConfig⟩
      | none =>
          have hTail :
              (match
                  psKernelWhnfCoreWithFuel
                    remaining
                    (fun nextContext nextState nextExpr =>
          psKernelWhnfWithFuel
            remaining
            reduceRecursor
            nextContext
            nextState
            nextExpr)
                    reduceRecursor
                    context
                    state
                    expr
                    false
                    false with
               | Except.error error =>
                   Except.error error
               | Except.ok coreResult =>
                   psKernelWhnfAfterCore
                     (fun nextContext nextState nextExpr =>
          psKernelWhnfWithFuel
            remaining
            reduceRecursor
            nextContext
            nextState
            nextExpr)
                     context
                     (Prod.snd coreResult)
                     expr
                     (Prod.fst coreResult)) =
                Except.ok (Prod.mk result nextState) := by
            simpa [hEligible, hGet] using hSuccess
          exact
            psKernelWhnfCoreMiss_configuration_refines
              remaining
              reduceRecursor
              hPublic
              hRecursor
              hBeta
              hNative
              context
              state
              nextState
              expr
              result
              hConfig
              hTail
  | false =>
      have hTail :
          (match
              psKernelWhnfCoreWithFuel
                remaining
                (fun nextContext nextState nextExpr =>
          psKernelWhnfWithFuel
            remaining
            reduceRecursor
            nextContext
            nextState
            nextExpr)
                reduceRecursor
                context
                state
                expr
                false
                false with
           | Except.error error =>
               Except.error error
           | Except.ok coreResult =>
               psKernelWhnfAfterCore
                 (fun nextContext nextState nextExpr =>
          psKernelWhnfWithFuel
            remaining
            reduceRecursor
            nextContext
            nextState
            nextExpr)
                 context
                 (Prod.snd coreResult)
                 expr
                 (Prod.fst coreResult)) =
            Except.ok (Prod.mk result nextState) := by
        simpa [hEligible] using hSuccess
      exact
        psKernelWhnfCoreMiss_configuration_refines
          remaining
          reduceRecursor
          hPublic
          hRecursor
          hBeta
          hNative
          context
          state
          nextState
          expr
          result
          hConfig
          hTail


theorem psKernelWhnfWithFuel_configuration_sound_contract
    (fuel : Nat)
    (reduceRecursor :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Bool ->
      Bool ->
      Except String
        (Prod (Option PsKernelExpr) PsKernelCheckerState))
    (hRecursor :
      PsKernelRecursorReductionConfigurationSound
        reduceRecursor)
    (hBeta :
      PsKernelBetaSpineSoundLaw)
    (hNative :
      PsKernelNativeReductionSoundLaw) :
    PsKernelWhnfConfigurationSound
      (psKernelWhnfWithFuel fuel reduceRecursor) := by
  induction fuel with
  | zero =>
      intro context state nextState expr result hConfig hSuccess
      simp [psKernelWhnfWithFuel] at hSuccess
  | succ remaining ih =>
      intro context state nextState expr result hConfig hSuccess
      have ihEta :
          PsKernelWhnfConfigurationSound
            (fun nextContext nextState nextExpr =>
              psKernelWhnfWithFuel
                remaining
                reduceRecursor
                nextContext
                nextState
                nextExpr) := by
        intro
          nextContext nextState finalState
          nextExpr nextResult
          hNextConfig hNextSuccess
        exact
          ih
            nextContext
            nextState
            finalState
            nextExpr
            nextResult
            hNextConfig
            hNextSuccess
      cases expr with
      | bvar index =>
          simp [psKernelWhnfWithFuel] at hSuccess
          rcases hSuccess with ⟨rfl, rfl⟩
          exact
            ⟨
              PsKernelReductionClosure.refl
                (PsKernelExpr.bvar index),
              hConfig
            ⟩
      | sort level =>
          simp [psKernelWhnfWithFuel] at hSuccess
          rcases hSuccess with ⟨rfl, rfl⟩
          exact
            ⟨
              PsKernelReductionClosure.refl
                (PsKernelExpr.sort level),
              hConfig
            ⟩
      | mvar name =>
          simp [psKernelWhnfWithFuel] at hSuccess
          rcases hSuccess with ⟨rfl, rfl⟩
          exact
            ⟨
              PsKernelReductionClosure.refl
                (PsKernelExpr.mvar name),
              hConfig
            ⟩
      | forallE name domain codomain binderInfo =>
          simp [psKernelWhnfWithFuel] at hSuccess
          rcases hSuccess with ⟨rfl, rfl⟩
          exact
            ⟨
              PsKernelReductionClosure.refl
                (PsKernelExpr.forallE
                  name domain codomain binderInfo),
              hConfig
            ⟩
      | lit literal =>
          simp [psKernelWhnfWithFuel] at hSuccess
          rcases hSuccess with ⟨rfl, rfl⟩
          exact
            ⟨
              PsKernelReductionClosure.refl
                (PsKernelExpr.lit literal),
              hConfig
            ⟩
      | mdata metadata body =>
          cases hRun :
              psKernelWhnfWithFuel
                remaining
                reduceRecursor
                context
                state
                body with
          | error error =>
              simp [
                psKernelWhnfWithFuel,
                hRun
              ] at hSuccess
          | ok run =>
              rcases run with ⟨reduced, reducedState⟩
              have hRest :=
                ih
                  context
                  state
                  reducedState
                  body
                  reduced
                  hConfig
                  hRun
              have hReduction :
                  PsKernelReductionClosure
                    context.environment
                    context.localContext
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
                psKernelWhnfWithFuel,
                hRun
              ] at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              exact
                ⟨hReduction, hRest.2⟩
      | fvar name =>
          cases hFind :
              psKernelLocalContextFind
                context.localContext
                name with
          | none =>
              simp [
                psKernelWhnfWithFuel,
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
                  psKernelLocalDeclValue declaration with
              | none =>
                  simp [
                    psKernelWhnfWithFuel,
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
                  simp only [
                    psKernelWhnfWithFuel,
                    hFind,
                    hValue
                  ] at hSuccess
                  change
                    psKernelWhnfCachedCoreRun
                        remaining
                        reduceRecursor
                        context
                        state
                        (PsKernelExpr.fvar name) =
                      Except.ok
                        (Prod.mk result nextState) at hSuccess
                  exact
                    psKernelWhnfCachedCore_configuration_refines
                      remaining
                      reduceRecursor
                      ihEta
                      hRecursor
                      hBeta
                      hNative
                      context
                      state
                      nextState
                      (PsKernelExpr.fvar name)
                      result
                      hConfig
                      hSuccess
      | const name levels =>
          exact
            psKernelWhnfCachedCore_configuration_refines
              remaining reduceRecursor ihEta hRecursor hBeta hNative
              context state nextState
              (PsKernelExpr.const name levels)
              result hConfig
              (by
                change
                  psKernelWhnfCachedCoreRun
                      remaining
                      reduceRecursor
                      context
                      state
                      (PsKernelExpr.const name levels) =
                    Except.ok
                      (Prod.mk result nextState) at hSuccess
                exact hSuccess)
      | lam name type body binderInfo =>
          exact
            psKernelWhnfCachedCore_configuration_refines
              remaining reduceRecursor ihEta hRecursor hBeta hNative
              context state nextState
              (PsKernelExpr.lam name type body binderInfo)
              result hConfig
              (by
                change
                  psKernelWhnfCachedCoreRun
                      remaining
                      reduceRecursor
                      context
                      state
                      (PsKernelExpr.lam name type body binderInfo) =
                    Except.ok
                      (Prod.mk result nextState) at hSuccess
                exact hSuccess)
      | letE name type value body nondep =>
          exact
            psKernelWhnfCachedCore_configuration_refines
              remaining reduceRecursor ihEta hRecursor hBeta hNative
              context state nextState
              (PsKernelExpr.letE name type value body nondep)
              result hConfig
              (by
                change
                  psKernelWhnfCachedCoreRun
                      remaining
                      reduceRecursor
                      context
                      state
                      (PsKernelExpr.letE name type value body nondep) =
                    Except.ok
                      (Prod.mk result nextState) at hSuccess
                exact hSuccess)
      | app fn arg =>
          exact
            psKernelWhnfCachedCore_configuration_refines
              remaining reduceRecursor ihEta hRecursor hBeta hNative
              context state nextState
              (PsKernelExpr.app fn arg)
              result hConfig
              (by
                change
                  psKernelWhnfCachedCoreRun
                      remaining
                      reduceRecursor
                      context
                      state
                      (PsKernelExpr.app fn arg) =
                    Except.ok
                      (Prod.mk result nextState) at hSuccess
                exact hSuccess)
      | proj typeName index body =>
          exact
            psKernelWhnfCachedCore_configuration_refines
              remaining reduceRecursor ihEta hRecursor hBeta hNative
              context state nextState
              (PsKernelExpr.proj typeName index body)
              result hConfig
              (by
                change
                  psKernelWhnfCachedCoreRun
                      remaining
                      reduceRecursor
                      context
                      state
                      (PsKernelExpr.proj typeName index body) =
                    Except.ok
                      (Prod.mk result nextState) at hSuccess
                exact hSuccess)
