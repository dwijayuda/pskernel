import Ps.KernelCore.Metatheory.CheckerContracts
import Ps.KernelCore.Metatheory.ContextState
import Ps.KernelCore.Metatheory.ReductionCongruence

/-
Configuration-aware semantic refinement for the application branch of WHNF
core.  The non-lambda tail and optimized multi-beta tail are factored
separately so recursor and substitution semantics remain explicit obligations.
-/

def psKernelWhnfCoreAppNonLambdaTailRun
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
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (original fn0 fn : PsKernelExpr)
    (args : List PsKernelExpr)
    (cheapRec cheapProj : Bool) :
    Except String (Prod PsKernelExpr PsKernelCheckerState) :=
  if psKernelExprEq fn fn0 then
    match
        reduceRecursor
          context
          state
          original
          cheapRec
          cheapProj with
    | Except.error error =>
        Except.error error
    | Except.ok reduction =>
        match Prod.fst reduction with
        | Option.none =>
            Except.ok
              (Prod.mk
                original
                (Prod.snd reduction))
        | Option.some value =>
            psKernelWhnfCoreWithFuel
              remaining
              publicWhnf
              reduceRecursor
              context
              (Prod.snd reduction)
              value
              cheapRec
              cheapProj
  else
    let rebuilt :=
      psKernelExprApplyArgsCheap fn args
    match
        psKernelWhnfCoreWithFuel
          remaining
          publicWhnf
          reduceRecursor
          context
          state
          rebuilt
          cheapRec
          cheapProj with
    | Except.error error =>
        Except.error error
    | Except.ok reduced =>
        psKernelWhnfCoreFinish
          original
          (Bool.or cheapRec cheapProj)
          (Prod.fst reduced)
          (Prod.snd reduced)


theorem psKernelWhnfCoreAppNonLambdaTail_configuration_refines
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
    (hSmaller :
      PsKernelWhnfCoreConfigurationSound
        (psKernelWhnfCoreWithFuel
          remaining
          publicWhnf
          reduceRecursor))
    (hRecursor :
      PsKernelRecursorReductionConfigurationSound
        reduceRecursor)
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (original fn0 fn result : PsKernelExpr)
    (args : List PsKernelExpr)
    (cheapRec cheapProj : Bool)
    (hConfig :
      PsKernelCheckerConfigurationSound context state)
    (hHead :
      PsKernelReductionClosure
        context.environment
        context.localContext
        original
        (psKernelExprApplyArgsCheap fn args))
    (hSuccess :
      psKernelWhnfCoreAppNonLambdaTailRun
          remaining
          publicWhnf
          reduceRecursor
          context
          state
          original
          fn0
          fn
          args
          cheapRec
          cheapProj =
        Except.ok (Prod.mk result nextState)) :
    PsKernelReductionClosure
        context.environment
        context.localContext
        original
        result ∧
      PsKernelCheckerConfigurationSound
        context
        nextState := by
  unfold psKernelWhnfCoreAppNonLambdaTailRun at hSuccess
  cases hEq : psKernelExprEq fn fn0 with
  | true =>
      cases hRecursorRun :
          reduceRecursor
            context
            state
            original
            cheapRec
            cheapProj with
      | error error =>
          simp [hEq, hRecursorRun] at hSuccess
      | ok recursorRun =>
          rcases recursorRun with ⟨answer, recursorState⟩
          have hRecursorSemantic :=
            hRecursor
              context
              state
              recursorState
              original
              cheapRec
              cheapProj
              answer
              hConfig
              hRecursorRun
          cases answer with
          | none =>
              simp [
                hEq,
                hRecursorRun
              ] at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              exact
                ⟨
                  PsKernelReductionClosure.refl original,
                  hRecursorSemantic.1
                ⟩
          | some value =>
              have hRecursorReduction :
                  PsKernelReductionClosure
                    context.environment
                    context.localContext
                    original
                    value := by
                simpa using hRecursorSemantic.2
              cases hReduce :
                  psKernelWhnfCoreWithFuel
                    remaining
                    publicWhnf
                    reduceRecursor
                    context
                    recursorState
                    value
                    cheapRec
                    cheapProj with
              | error error =>
                  simp [
                    hEq,
                    hRecursorRun,
                    hReduce
                  ] at hSuccess
              | ok reduceRun =>
                  rcases reduceRun with ⟨reduced, reducedState⟩
                  have hReduceSemantic :=
                    hSmaller
                      context
                      recursorState
                      reducedState
                      value
                      reduced
                      cheapRec
                      cheapProj
                      hRecursorSemantic.1
                      hReduce
                  simp [
                    hEq,
                    hRecursorRun,
                    hReduce
                  ] at hSuccess
                  rcases hSuccess with ⟨rfl, rfl⟩
                  exact
                    ⟨
                      psKernelReductionClosure_transitive
                        context.environment
                        context.localContext
                        original
                        value
                        reduced
                        hRecursorReduction
                        hReduceSemantic.1,
                      hReduceSemantic.2
                    ⟩
  | false =>
      let rebuilt :=
        psKernelExprApplyArgsCheap fn args
      cases hReduce :
          psKernelWhnfCoreWithFuel
            remaining
            publicWhnf
            reduceRecursor
            context
            state
            rebuilt
            cheapRec
            cheapProj with
      | error error =>
          simp [
            hEq,
            rebuilt,
            hReduce
          ] at hSuccess
      | ok reduceRun =>
          rcases reduceRun with ⟨reduced, reducedState⟩
          have hReduceSemantic :=
            hSmaller
              context
              state
              reducedState
              rebuilt
              reduced
              cheapRec
              cheapProj
              hConfig
              hReduce
          have hCombined :
              PsKernelReductionClosure
                context.environment
                context.localContext
                original
                reduced :=
            psKernelReductionClosure_transitive
              context.environment
              context.localContext
              original
              rebuilt
              reduced
              (by simpa [rebuilt] using hHead)
              hReduceSemantic.1
          have hFinish :
              psKernelWhnfCoreFinish
                  original
                  (Bool.or cheapRec cheapProj)
                  reduced
                  reducedState =
                Except.ok
                  (Prod.mk result nextState) := by
            simpa [
              hEq,
              rebuilt,
              hReduce
            ] using hSuccess
          have hFinishSemantic :=
            psKernelWhnfCoreFinish_success_refines
              context
              reducedState
              nextState
              original
              reduced
              result
              (Bool.or cheapRec cheapProj)
              hReduceSemantic.2
              hCombined
              hFinish
          have hResult : result = reduced :=
            hFinishSemantic.1
          subst result
          exact
            ⟨
              hCombined,
              hFinishSemantic.2
            ⟩


def psKernelWhnfCoreAppLambdaTailRun
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
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (original : PsKernelExpr)
    (name : PsKernelName)
    (type body : PsKernelExpr)
    (binderInfo : PsKernelBinderInfo)
    (args : List PsKernelExpr)
    (cheapRec cheapProj : Bool) :
    Except String (Prod PsKernelExpr PsKernelCheckerState) :=
  let fn :=
    PsKernelExpr.lam name type body binderInfo
  let consumedResult :=
    psKernelWhnfCountLambdas
      fn
      (psKernelExprListLength args)
  let lastLam :=
    Prod.fst consumedResult
  let consumed :=
    Prod.snd consumedResult
  match lastLam with
  | PsKernelExpr.lam _ _ lastBody _ =>
      let selected :=
        psKernelExprListTake consumed args
      let reducedBody :=
        psKernelExprInstantiateRev
          lastBody
          selected
      let rebuilt :=
        psKernelExprApplyArgsCheap
          reducedBody
          (psKernelExprListDrop consumed args)
      match
          psKernelWhnfCoreWithFuel
            remaining
            publicWhnf
            reduceRecursor
            context
            state
            rebuilt
            cheapRec
            cheapProj with
      | Except.error error =>
          Except.error error
      | Except.ok reduced =>
          psKernelWhnfCoreFinish
            original
            (Bool.or cheapRec cheapProj)
            (Prod.fst reduced)
            (Prod.snd reduced)
  | _ =>
      Except.ok (Prod.mk original state)


theorem psKernelWhnfCoreAppLambdaTail_configuration_refines
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
    (hSmaller :
      PsKernelWhnfCoreConfigurationSound
        (psKernelWhnfCoreWithFuel
          remaining
          publicWhnf
          reduceRecursor))
    (hBeta :
      PsKernelBetaSpineSoundLaw)
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (original : PsKernelExpr)
    (name : PsKernelName)
    (type body : PsKernelExpr)
    (binderInfo : PsKernelBinderInfo)
    (args : List PsKernelExpr)
    (result : PsKernelExpr)
    (cheapRec cheapProj : Bool)
    (hArgsNonempty :
      psKernelNatLt
          0
          (psKernelExprListLength args) =
        true)
    (hConfig :
      PsKernelCheckerConfigurationSound context state)
    (hHead :
      PsKernelReductionClosure
        context.environment
        context.localContext
        original
        (psKernelExprApplyArgsCheap
          (PsKernelExpr.lam name type body binderInfo)
          args))
    (hSuccess :
      psKernelWhnfCoreAppLambdaTailRun
          remaining
          publicWhnf
          reduceRecursor
          context
          state
          original
          name
          type
          body
          binderInfo
          args
          cheapRec
          cheapProj =
        Except.ok (Prod.mk result nextState)) :
    PsKernelReductionClosure
        context.environment
        context.localContext
        original
        result ∧
      PsKernelCheckerConfigurationSound
        context
        nextState := by
  unfold psKernelWhnfCoreAppLambdaTailRun at hSuccess
  let fn :=
    PsKernelExpr.lam name type body binderInfo
  cases hCount :
      psKernelWhnfCountLambdas
        fn
        (psKernelExprListLength args) with
  | mk lastLam consumed =>
      cases lastLam with
      | lam lastName lastType lastBody lastBinderInfo =>
          let selected :=
            psKernelExprListTake consumed args
          let reducedBody :=
            psKernelExprInstantiateRev
              lastBody
              selected
          let rebuilt :=
            psKernelExprApplyArgsCheap
              reducedBody
              (psKernelExprListDrop consumed args)
          have hBetaReduction :
              PsKernelReductionClosure
                context.environment
                context.localContext
                (psKernelExprApplyArgsCheap fn args)
                rebuilt := by
            simpa [
              fn,
              selected,
              reducedBody,
              rebuilt
            ] using
              hBeta
                context
                fn
                (PsKernelExpr.lam
                  lastName
                  lastType
                  lastBody
                  lastBinderInfo)
                lastBody
                args
                consumed
                lastName
                lastType
                lastBinderInfo
                hCount
                hArgsNonempty
                rfl
          have hBefore :
              PsKernelReductionClosure
                context.environment
                context.localContext
                original
                rebuilt :=
            psKernelReductionClosure_transitive
              context.environment
              context.localContext
              original
              (psKernelExprApplyArgsCheap fn args)
              rebuilt
              (by simpa [fn] using hHead)
              hBetaReduction
          cases hReduce :
              psKernelWhnfCoreWithFuel
                remaining
                publicWhnf
                reduceRecursor
                context
                state
                rebuilt
                cheapRec
                cheapProj with
          | error error =>
              simp [
                fn,
                hCount,
                selected,
                reducedBody,
                rebuilt,
                hReduce
              ] at hSuccess
          | ok reduceRun =>
              rcases reduceRun with ⟨reduced, reducedState⟩
              have hReduceSemantic :=
                hSmaller
                  context
                  state
                  reducedState
                  rebuilt
                  reduced
                  cheapRec
                  cheapProj
                  hConfig
                  hReduce
              have hCombined :
                  PsKernelReductionClosure
                    context.environment
                    context.localContext
                    original
                    reduced :=
                psKernelReductionClosure_transitive
                  context.environment
                  context.localContext
                  original
                  rebuilt
                  reduced
                  hBefore
                  hReduceSemantic.1
              have hFinish :
                  psKernelWhnfCoreFinish
                      original
                      (Bool.or cheapRec cheapProj)
                      reduced
                      reducedState =
                    Except.ok
                      (Prod.mk result nextState) := by
                simpa [
                  fn,
                  hCount,
                  selected,
                  reducedBody,
                  rebuilt,
                  hReduce
                ] using hSuccess
              have hFinishSemantic :=
                psKernelWhnfCoreFinish_success_refines
                  context
                  reducedState
                  nextState
                  original
                  reduced
                  result
                  (Bool.or cheapRec cheapProj)
                  hReduceSemantic.2
                  hCombined
                  hFinish
              have hResult : result = reduced :=
                hFinishSemantic.1
              subst result
              exact
                ⟨
                  hCombined,
                  hFinishSemantic.2
                ⟩
      | bvar index =>
          simp [fn, hCount] at hSuccess
          rcases hSuccess with ⟨rfl, rfl⟩
          exact ⟨PsKernelReductionClosure.refl original, hConfig⟩
      | fvar fvarName =>
          simp [fn, hCount] at hSuccess
          rcases hSuccess with ⟨rfl, rfl⟩
          exact ⟨PsKernelReductionClosure.refl original, hConfig⟩
      | mvar mvarName =>
          simp [fn, hCount] at hSuccess
          rcases hSuccess with ⟨rfl, rfl⟩
          exact ⟨PsKernelReductionClosure.refl original, hConfig⟩
      | sort level =>
          simp [fn, hCount] at hSuccess
          rcases hSuccess with ⟨rfl, rfl⟩
          exact ⟨PsKernelReductionClosure.refl original, hConfig⟩
      | const constName levels =>
          simp [fn, hCount] at hSuccess
          rcases hSuccess with ⟨rfl, rfl⟩
          exact ⟨PsKernelReductionClosure.refl original, hConfig⟩
      | app appFn appArg =>
          simp [fn, hCount] at hSuccess
          rcases hSuccess with ⟨rfl, rfl⟩
          exact ⟨PsKernelReductionClosure.refl original, hConfig⟩
      | forallE forallName domain codomain forallInfo =>
          simp [fn, hCount] at hSuccess
          rcases hSuccess with ⟨rfl, rfl⟩
          exact ⟨PsKernelReductionClosure.refl original, hConfig⟩
      | letE letName letType letValue letBody nondep =>
          simp [fn, hCount] at hSuccess
          rcases hSuccess with ⟨rfl, rfl⟩
          exact ⟨PsKernelReductionClosure.refl original, hConfig⟩
      | lit literal =>
          simp [fn, hCount] at hSuccess
          rcases hSuccess with ⟨rfl, rfl⟩
          exact ⟨PsKernelReductionClosure.refl original, hConfig⟩
      | mdata metadata mdataBody =>
          simp [fn, hCount] at hSuccess
          rcases hSuccess with ⟨rfl, rfl⟩
          exact ⟨PsKernelReductionClosure.refl original, hConfig⟩
      | proj projectionName projectionIndex projectionBody =>
          simp [fn, hCount] at hSuccess
          rcases hSuccess with ⟨rfl, rfl⟩
          exact ⟨PsKernelReductionClosure.refl original, hConfig⟩


def psKernelWhnfCoreAppTailRun
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
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (original fn0 fn : PsKernelExpr)
    (args : List PsKernelExpr)
    (cheapRec cheapProj : Bool) :
    Except String (Prod PsKernelExpr PsKernelCheckerState) :=
  match fn with
  | PsKernelExpr.lam _ _ _ _ =>
      let consumedResult :=
        psKernelWhnfCountLambdas
          fn
          (psKernelExprListLength args)
      let lastLam :=
        Prod.fst consumedResult
      let consumed :=
        Prod.snd consumedResult
      match lastLam with
      | PsKernelExpr.lam _ _ lastBody _ =>
          let selected :=
            psKernelExprListTake consumed args
          let reducedBody :=
            psKernelExprInstantiateRev
              lastBody
              selected
          let rebuilt :=
            psKernelExprApplyArgsCheap
              reducedBody
              (psKernelExprListDrop consumed args)
          match
              psKernelWhnfCoreWithFuel
                remaining
                publicWhnf
                reduceRecursor
                context
                state
                rebuilt
                cheapRec
                cheapProj with
          | Except.error error =>
              Except.error error
          | Except.ok reduced =>
              psKernelWhnfCoreFinish
                original
                (Bool.or cheapRec cheapProj)
                (Prod.fst reduced)
                (Prod.snd reduced)
      | _ =>
          Except.ok (Prod.mk original state)
  | _ =>
      if psKernelExprEq fn fn0 then
        match
            reduceRecursor
              context
              state
              original
              cheapRec
              cheapProj with
        | Except.error error =>
            Except.error error
        | Except.ok reduction =>
            match Prod.fst reduction with
            | Option.none =>
                Except.ok
                  (Prod.mk
                    original
                    (Prod.snd reduction))
            | Option.some value =>
                psKernelWhnfCoreWithFuel
                  remaining
                  publicWhnf
                  reduceRecursor
                  context
                  (Prod.snd reduction)
                  value
                  cheapRec
                  cheapProj
      else
        let rebuilt :=
          psKernelExprApplyArgsCheap fn args
        match
            psKernelWhnfCoreWithFuel
              remaining
              publicWhnf
              reduceRecursor
              context
              state
              rebuilt
              cheapRec
              cheapProj with
        | Except.error error =>
            Except.error error
        | Except.ok reduced =>
            psKernelWhnfCoreFinish
              original
              (Bool.or cheapRec cheapProj)
              (Prod.fst reduced)
              (Prod.snd reduced)


theorem psKernelWhnfCoreApplication_configuration_refines
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
    (hSmaller :
      PsKernelWhnfCoreConfigurationSound
        (psKernelWhnfCoreWithFuel
          remaining
          publicWhnf
          reduceRecursor))
    (hRecursor :
      PsKernelRecursorReductionConfigurationSound
        reduceRecursor)
    (hBeta :
      PsKernelBetaSpineSoundLaw)
    (context nextContext : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (appFn appArg result : PsKernelExpr)
    (cheapRec cheapProj : Bool)
    (hConfig :
      PsKernelCheckerConfigurationSound context state)
    (hDepth :
      psKernelCheckerContextEnterRecDepth context =
        Except.ok nextContext)
    (hMiss :
      (if
          psKernelSemanticCacheEligible
            (PsKernelExpr.app appFn appArg) then
        psKernelExprMapGet
          state.whnfCore
          (PsKernelExpr.app appFn appArg)
      else
        Option.none) =
        Option.none)
    (hSuccess :
      psKernelWhnfCoreWithFuel
          (Nat.succ remaining)
          publicWhnf
          reduceRecursor
          context
          state
          (PsKernelExpr.app appFn appArg)
          cheapRec
          cheapProj =
        Except.ok (Prod.mk result nextState)) :
    PsKernelReductionClosure
        context.environment
        context.localContext
        (PsKernelExpr.app appFn appArg)
        result ∧
      PsKernelCheckerConfigurationSound
        context
        nextState := by
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
  let original :=
    PsKernelExpr.app appFn appArg
  let spine :=
    psKernelExprGetAppFnArgs original
  let fn0 :=
    Prod.fst spine
  let args :=
    Prod.snd spine
  cases hFn :
      psKernelWhnfCoreWithFuel
        remaining
        publicWhnf
        reduceRecursor
        nextContext
        state
        fn0
        cheapRec
        cheapProj with
  | error error =>
      simp [
        psKernelWhnfCoreWithFuel,
        hDepth,
        hMiss,
        original,
        spine,
        fn0,
        args,
        hFn
      ] at hSuccess
  | ok fnRun =>
      rcases fnRun with ⟨fn, state1⟩
      have hFnSemantic :=
        hSmaller
          nextContext
          state
          state1
          fn0
          fn
          cheapRec
          cheapProj
          hNextConfig
          hFn
      have hHead :
          PsKernelReductionClosure
            nextContext.environment
            nextContext.localContext
            original
            (psKernelExprApplyArgsCheap fn args) := by
        simpa [
          original,
          spine,
          fn0,
          args
        ] using
          psKernelReductionClosure_appSpineHead
            nextContext.environment
            nextContext.localContext
            original
            fn
            hFnSemantic.1
      have hArgsNonempty :
          psKernelNatLt
              0
              (psKernelExprListLength args) =
            true := by
        simpa [
          original,
          spine,
          args
        ] using
          psKernelExprGetAppFnArgs_app_args_nonempty
            appFn
            appArg
      have hBackPair :
          (PsKernelReductionClosure
              nextContext.environment
              nextContext.localContext
              original
              result ∧
            PsKernelCheckerConfigurationSound
              nextContext
              nextState) ->
          (PsKernelReductionClosure
              context.environment
              context.localContext
              original
              result ∧
            PsKernelCheckerConfigurationSound
              context
              nextState) := by
        intro hPair
        exact
          ⟨
            hBackReduction original result hPair.1,
            hBackConfig nextState hPair.2
          ⟩
      have hTailSuccess := hSuccess
      simp only [
        psKernelWhnfCoreWithFuel,
        hDepth,
        hMiss,
        original,
        spine,
        fn0,
        args,
        hFn
      ] at hTailSuccess
      change
        psKernelWhnfCoreAppTailRun
            remaining
            publicWhnf
            reduceRecursor
            nextContext
            state1
            original
            fn0
            fn
            args
            cheapRec
            cheapProj =
          Except.ok (Prod.mk result nextState) at hTailSuccess
      cases hFnShape : fn with
      | lam name type body binderInfo =>
          apply hBackPair
          exact
            psKernelWhnfCoreAppLambdaTail_configuration_refines
              remaining
              publicWhnf
              reduceRecursor
              hSmaller
              hBeta
              nextContext
              state1
              nextState
              original
              name
              type
              body
              binderInfo
              args
              result
              cheapRec
              cheapProj
              hArgsNonempty
              hFnSemantic.2
              (by simpa [hFnShape] using hHead)
              (by
                simpa only [
                  psKernelWhnfCoreAppTailRun,
                  psKernelWhnfCoreAppLambdaTailRun,
                  psKernelWhnfCoreAppNonLambdaTailRun,
                  hFnShape
                ] using hTailSuccess)
      | bvar index =>
          apply hBackPair
          exact
            psKernelWhnfCoreAppNonLambdaTail_configuration_refines
              remaining publicWhnf reduceRecursor
              hSmaller hRecursor
              nextContext state1 nextState
              original fn0 (PsKernelExpr.bvar index) result
              args cheapRec cheapProj
              hFnSemantic.2
              (by simpa [hFnShape] using hHead)
              (by
                simpa only [
                  psKernelWhnfCoreAppTailRun,
                  psKernelWhnfCoreAppLambdaTailRun,
                  psKernelWhnfCoreAppNonLambdaTailRun,
                  hFnShape
                ] using hTailSuccess)
      | fvar name =>
          apply hBackPair
          exact
            psKernelWhnfCoreAppNonLambdaTail_configuration_refines
              remaining publicWhnf reduceRecursor
              hSmaller hRecursor
              nextContext state1 nextState
              original fn0 (PsKernelExpr.fvar name) result
              args cheapRec cheapProj
              hFnSemantic.2
              (by simpa [hFnShape] using hHead)
              (by
                simpa only [
                  psKernelWhnfCoreAppTailRun,
                  psKernelWhnfCoreAppLambdaTailRun,
                  psKernelWhnfCoreAppNonLambdaTailRun,
                  hFnShape
                ] using hTailSuccess)
      | mvar name =>
          apply hBackPair
          exact
            psKernelWhnfCoreAppNonLambdaTail_configuration_refines
              remaining publicWhnf reduceRecursor
              hSmaller hRecursor
              nextContext state1 nextState
              original fn0 (PsKernelExpr.mvar name) result
              args cheapRec cheapProj
              hFnSemantic.2
              (by simpa [hFnShape] using hHead)
              (by
                simpa only [
                  psKernelWhnfCoreAppTailRun,
                  psKernelWhnfCoreAppLambdaTailRun,
                  psKernelWhnfCoreAppNonLambdaTailRun,
                  hFnShape
                ] using hTailSuccess)
      | sort level =>
          apply hBackPair
          exact
            psKernelWhnfCoreAppNonLambdaTail_configuration_refines
              remaining publicWhnf reduceRecursor
              hSmaller hRecursor
              nextContext state1 nextState
              original fn0 (PsKernelExpr.sort level) result
              args cheapRec cheapProj
              hFnSemantic.2
              (by simpa [hFnShape] using hHead)
              (by
                simpa only [
                  psKernelWhnfCoreAppTailRun,
                  psKernelWhnfCoreAppLambdaTailRun,
                  psKernelWhnfCoreAppNonLambdaTailRun,
                  hFnShape
                ] using hTailSuccess)
      | const name levels =>
          apply hBackPair
          exact
            psKernelWhnfCoreAppNonLambdaTail_configuration_refines
              remaining publicWhnf reduceRecursor
              hSmaller hRecursor
              nextContext state1 nextState
              original fn0 (PsKernelExpr.const name levels) result
              args cheapRec cheapProj
              hFnSemantic.2
              (by simpa [hFnShape] using hHead)
              (by
                simpa only [
                  psKernelWhnfCoreAppTailRun,
                  psKernelWhnfCoreAppLambdaTailRun,
                  psKernelWhnfCoreAppNonLambdaTailRun,
                  hFnShape
                ] using hTailSuccess)
      | app nestedFn nestedArg =>
          apply hBackPair
          exact
            psKernelWhnfCoreAppNonLambdaTail_configuration_refines
              remaining publicWhnf reduceRecursor
              hSmaller hRecursor
              nextContext state1 nextState
              original fn0 (PsKernelExpr.app nestedFn nestedArg) result
              args cheapRec cheapProj
              hFnSemantic.2
              (by simpa [hFnShape] using hHead)
              (by
                simpa only [
                  psKernelWhnfCoreAppTailRun,
                  psKernelWhnfCoreAppLambdaTailRun,
                  psKernelWhnfCoreAppNonLambdaTailRun,
                  hFnShape
                ] using hTailSuccess)
      | forallE name domain codomain binderInfo =>
          apply hBackPair
          exact
            psKernelWhnfCoreAppNonLambdaTail_configuration_refines
              remaining publicWhnf reduceRecursor
              hSmaller hRecursor
              nextContext state1 nextState
              original fn0
              (PsKernelExpr.forallE name domain codomain binderInfo)
              result args cheapRec cheapProj
              hFnSemantic.2
              (by simpa [hFnShape] using hHead)
              (by
                simpa only [
                  psKernelWhnfCoreAppTailRun,
                  psKernelWhnfCoreAppLambdaTailRun,
                  psKernelWhnfCoreAppNonLambdaTailRun,
                  hFnShape
                ] using hTailSuccess)
      | letE name type value body nondep =>
          apply hBackPair
          exact
            psKernelWhnfCoreAppNonLambdaTail_configuration_refines
              remaining publicWhnf reduceRecursor
              hSmaller hRecursor
              nextContext state1 nextState
              original fn0
              (PsKernelExpr.letE name type value body nondep)
              result args cheapRec cheapProj
              hFnSemantic.2
              (by simpa [hFnShape] using hHead)
              (by
                simpa only [
                  psKernelWhnfCoreAppTailRun,
                  psKernelWhnfCoreAppLambdaTailRun,
                  psKernelWhnfCoreAppNonLambdaTailRun,
                  hFnShape
                ] using hTailSuccess)
      | lit literal =>
          apply hBackPair
          exact
            psKernelWhnfCoreAppNonLambdaTail_configuration_refines
              remaining publicWhnf reduceRecursor
              hSmaller hRecursor
              nextContext state1 nextState
              original fn0 (PsKernelExpr.lit literal) result
              args cheapRec cheapProj
              hFnSemantic.2
              (by simpa [hFnShape] using hHead)
              (by
                simpa only [
                  psKernelWhnfCoreAppTailRun,
                  psKernelWhnfCoreAppLambdaTailRun,
                  psKernelWhnfCoreAppNonLambdaTailRun,
                  hFnShape
                ] using hTailSuccess)
      | mdata metadata body =>
          apply hBackPair
          exact
            psKernelWhnfCoreAppNonLambdaTail_configuration_refines
              remaining publicWhnf reduceRecursor
              hSmaller hRecursor
              nextContext state1 nextState
              original fn0 (PsKernelExpr.mdata metadata body) result
              args cheapRec cheapProj
              hFnSemantic.2
              (by simpa [hFnShape] using hHead)
              (by
                simpa only [
                  psKernelWhnfCoreAppTailRun,
                  psKernelWhnfCoreAppLambdaTailRun,
                  psKernelWhnfCoreAppNonLambdaTailRun,
                  hFnShape
                ] using hTailSuccess)
      | proj typeName index body =>
          apply hBackPair
          exact
            psKernelWhnfCoreAppNonLambdaTail_configuration_refines
              remaining publicWhnf reduceRecursor
              hSmaller hRecursor
              nextContext state1 nextState
              original fn0 (PsKernelExpr.proj typeName index body) result
              args cheapRec cheapProj
              hFnSemantic.2
              (by simpa [hFnShape] using hHead)
              (by
                simpa only [
                  psKernelWhnfCoreAppTailRun,
                  psKernelWhnfCoreAppLambdaTailRun,
                  psKernelWhnfCoreAppNonLambdaTailRun,
                  hFnShape
                ] using hTailSuccess)
