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
