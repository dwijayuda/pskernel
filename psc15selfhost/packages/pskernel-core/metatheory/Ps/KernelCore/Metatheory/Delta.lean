import Ps.KernelCore.Metatheory.Judgments
import Ps.KernelCore.Checker.DefEq.DeltaStep

theorem psKernelReductionClosure_trans
    (environment : PsKernelEnvironment)
    (localContext : PsKernelLocalContext)
    (left middle right : PsKernelExpr)
    (hLeft :
      PsKernelReductionClosure
        environment localContext left middle)
    (hRight :
      PsKernelReductionClosure
        environment localContext middle right) :
    PsKernelReductionClosure
      environment localContext left right := by
  induction hLeft with
  | refl expr =>
      exact hRight
  | cons first next last hStep hRest ih =>
      exact
        PsKernelReductionClosure.cons
          first
          next
          right
          hStep
          (ih hRight)

theorem psKernelUnfoldDefinition_some_refines_reduction
    (context : PsKernelCheckerContext)
    (expr result : PsKernelExpr)
    (hIndex :
      PsKernelEnvironmentIndexRefines context.environment)
    (hSuccess :
      psKernelUnfoldDefinition context expr =
        Option.some result) :
    PsKernelReductionStep
      context.environment
      context.localContext
      expr
      result := by
  cases hHead : psKernelExprGetAppFn expr with
  | bvar index =>
      simp [psKernelUnfoldDefinition, hHead] at hSuccess
  | fvar name =>
      simp [psKernelUnfoldDefinition, hHead] at hSuccess
  | mvar name =>
      simp [psKernelUnfoldDefinition, hHead] at hSuccess
  | sort level =>
      simp [psKernelUnfoldDefinition, hHead] at hSuccess
  | app fn arg =>
      simp [psKernelUnfoldDefinition, hHead] at hSuccess
  | lam name type body binderInfo =>
      simp [psKernelUnfoldDefinition, hHead] at hSuccess
  | forallE name type body binderInfo =>
      simp [psKernelUnfoldDefinition, hHead] at hSuccess
  | letE name type value body nondep =>
      simp [psKernelUnfoldDefinition, hHead] at hSuccess
  | lit literal =>
      simp [psKernelUnfoldDefinition, hHead] at hSuccess
  | mdata metadata body =>
      simp [psKernelUnfoldDefinition, hHead] at hSuccess
  | proj typeName index body =>
      simp [psKernelUnfoldDefinition, hHead] at hSuccess
  | const name levels =>
      cases hFind :
          psKernelEnvironmentFind
            context.environment
            name with
      | none =>
          simp [
            psKernelUnfoldDefinition,
            hHead,
            hFind
          ] at hSuccess
      | some info =>
          cases hDelta :
              psKernelConstantInfoDeltaValue info with
          | none =>
              simp [
                psKernelUnfoldDefinition,
                hHead,
                hFind,
                hDelta
              ] at hSuccess
          | some value =>
              cases hLevels :
                  Nat.beq
                    (psKernelNameListLength
                      (psKernelConstantInfoLevelParams info))
                    (psKernelLevelListLength levels) with
              | false =>
                  simp [
                    psKernelUnfoldDefinition,
                    hHead,
                    hFind,
                    hDelta,
                    hLevels
                  ] at hSuccess
              | true =>
                  have hLevelCount :
                      psKernelNameListLength
                          (psKernelConstantInfoLevelParams info) =
                        psKernelLevelListLength levels := by
                    simpa using hLevels
                  have hIndexed :
                      psKernelFindConstantInList
                          name
                          (psKernelEnvironmentIndexFind
                            context.environment.index
                            name) =
                        Option.some info := by
                    simpa [psKernelEnvironmentFind] using hFind
                  have hAuthoritative :
                      psKernelFindConstantInList
                          name
                          context.environment.constants =
                        Option.some info := by
                    rw [← hIndex name]
                    exact hIndexed
                  have hResult :
                      result =
                        psKernelApplyArgs
                          (psKernelExprInstantiateLevelParams
                            value
                            (psKernelConstantInfoLevelParams info)
                            levels)
                          (psKernelExprGetAppArgs expr) := by
                    simpa [
                      psKernelUnfoldDefinition,
                      hHead,
                      hFind,
                      hDelta,
                      hLevels
                    ] using hSuccess.symm
                  subst result
                  exact
                    PsKernelReductionStep.deltaSpine
                      expr
                      name
                      levels
                      info
                      value
                      hHead
                      hAuthoritative
                      hDelta
                      hLevelCount

theorem psKernelUnfoldDefinition_some_refines_closure
    (context : PsKernelCheckerContext)
    (expr result : PsKernelExpr)
    (hIndex :
      PsKernelEnvironmentIndexRefines context.environment)
    (hSuccess :
      psKernelUnfoldDefinition context expr =
        Option.some result) :
    PsKernelReductionClosure
      context.environment
      context.localContext
      expr
      result := by
  exact
    PsKernelReductionClosure.cons
      expr
      result
      result
      (psKernelUnfoldDefinition_some_refines_reduction
        context expr result hIndex hSuccess)
      (PsKernelReductionClosure.refl result)

theorem psKernelDefEqUnfold_some_refines_reduction
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (expr result : PsKernelExpr)
    (hIndex :
      PsKernelEnvironmentIndexRefines context.environment)
    (hCache :
      PsKernelReductionCacheSound
        context.environment
        context.localContext
        state.unfold)
    (hSuccess :
      Prod.fst
          (psKernelDefEqUnfold
            context
            state
            expr) =
        Option.some result) :
    PsKernelReductionClosure
      context.environment
      context.localContext
      expr
      result := by
  cases hCacheGet :
      psKernelExprMapGet state.unfold expr with
  | some cached =>
      have hEq : cached = result := by
        simpa [
          psKernelDefEqUnfold,
          hCacheGet
        ] using hSuccess
      subst result
      exact hCache expr cached hCacheGet
  | none =>
      cases hDirect :
          psKernelUnfoldDefinition context expr with
      | none =>
          simp [
            psKernelDefEqUnfold,
            hCacheGet,
            hDirect
          ] at hSuccess
      | some unfolded =>
          have hEq : unfolded = result := by
            simpa [
              psKernelDefEqUnfold,
              hCacheGet,
              hDirect
            ] using hSuccess
          subst result
          exact
            psKernelUnfoldDefinition_some_refines_closure
              context
              expr
              unfolded
              hIndex
              hDirect

theorem psKernelDefEqDeltaOnce_refines_reduction
    (coreWhnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Bool ->
      Bool ->
      Except String
        (Prod PsKernelExpr PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (expr result : PsKernelExpr)
    (hIndex :
      PsKernelEnvironmentIndexRefines context.environment)
    (hCache :
      PsKernelReductionCacheSound
        context.environment
        context.localContext
        state.unfold)
    (hCoreSound :
      PsKernelWhnfCoreSound coreWhnf)
    (hSuccess :
      psKernelDefEqDeltaOnce
          coreWhnf
          context
          state
          expr =
        Except.ok (Prod.mk result nextState)) :
    PsKernelReductionClosure
      context.environment
      context.localContext
      expr
      result := by
  let unfolded :=
    psKernelDefEqUnfold context state expr
  cases hValue :
      Prod.fst unfolded with
  | none =>
      simp [
        psKernelDefEqDeltaOnce,
        unfolded,
        hValue
      ] at hSuccess
  | some value =>
      have hUnfold :
          Prod.fst
              (psKernelDefEqUnfold
                context
                state
                expr) =
            Option.some value := by
        simpa [unfolded] using hValue
      have hFirst :
          PsKernelReductionClosure
            context.environment
            context.localContext
            expr
            value :=
        psKernelDefEqUnfold_some_refines_reduction
          context
          state
          expr
          value
          hIndex
          hCache
          hUnfold
      have hCore :
          coreWhnf
              context
              (Prod.snd unfolded)
              value
              false
              true =
            Except.ok (Prod.mk result nextState) := by
        simpa [
          psKernelDefEqDeltaOnce,
          unfolded,
          hValue
        ] using hSuccess
      have hSecond :
          PsKernelReductionClosure
            context.environment
            context.localContext
            value
            result :=
        hCoreSound
          context
          (Prod.snd unfolded)
          nextState
          value
          result
          false
          true
          hCore
      exact
        psKernelReductionClosure_trans
          context.environment
          context.localContext
          expr
          value
          result
          hFirst
          hSecond

theorem psKernelDefEqTryUnfoldProjApp_some_refines_reduction
    (coreWhnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Bool ->
      Bool ->
      Except String
        (Prod PsKernelExpr PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (expr result : PsKernelExpr)
    (hCoreSound :
      PsKernelWhnfCoreSound coreWhnf)
    (hSuccess :
      psKernelDefEqTryUnfoldProjApp
          coreWhnf
          context
          state
          expr =
        Except.ok
          (Prod.mk (Option.some result) nextState)) :
    PsKernelReductionClosure
      context.environment
      context.localContext
      expr
      result := by
  cases hHead : psKernelExprGetAppFn expr with
  | proj typeName index body =>
      cases hCore :
          coreWhnf
            context
            state
            expr
            false
            false with
      | error error =>
          simp [
            psKernelDefEqTryUnfoldProjApp,
            hHead,
            hCore
          ] at hSuccess
      | ok coreResult =>
          cases coreResult with
          | mk value coreState =>
              cases hEq :
                  psKernelExprEq value expr with
              | true =>
                  simp [
                    psKernelDefEqTryUnfoldProjApp,
                    hHead,
                    hCore,
                    hEq
                  ] at hSuccess
              | false =>
                  simp [
                    psKernelDefEqTryUnfoldProjApp,
                    hHead,
                    hCore,
                    hEq
                  ] at hSuccess
                  rcases hSuccess with ⟨rfl, rfl⟩
                  exact
                    hCoreSound
                      context
                      state
                      coreState
                      expr
                      value
                      false
                      false
                      hCore
  | bvar value =>
      simp [psKernelDefEqTryUnfoldProjApp, hHead] at hSuccess
  | fvar value =>
      simp [psKernelDefEqTryUnfoldProjApp, hHead] at hSuccess
  | mvar value =>
      simp [psKernelDefEqTryUnfoldProjApp, hHead] at hSuccess
  | sort value =>
      simp [psKernelDefEqTryUnfoldProjApp, hHead] at hSuccess
  | const name levels =>
      simp [psKernelDefEqTryUnfoldProjApp, hHead] at hSuccess
  | app fn arg =>
      simp [psKernelDefEqTryUnfoldProjApp, hHead] at hSuccess
  | lam name type body binderInfo =>
      simp [psKernelDefEqTryUnfoldProjApp, hHead] at hSuccess
  | forallE name type body binderInfo =>
      simp [psKernelDefEqTryUnfoldProjApp, hHead] at hSuccess
  | letE name type value body nondep =>
      simp [psKernelDefEqTryUnfoldProjApp, hHead] at hSuccess
  | lit literal =>
      simp [psKernelDefEqTryUnfoldProjApp, hHead] at hSuccess
  | mdata metadata body =>
      simp [psKernelDefEqTryUnfoldProjApp, hHead] at hSuccess
