import Ps.KernelCore.Metatheory.CheckerContracts
import Ps.KernelCore.Metatheory.ContextState
import Ps.KernelCore.Metatheory.ProjectionReduction
import Ps.KernelCore.Metatheory.ReductionCongruence


def psKernelWhnfProjectionExpandWith
    (publicWhnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (expr : PsKernelExpr) :
    Except String (Prod PsKernelExpr PsKernelCheckerState) :=
  match expr with
  | PsKernelExpr.lit literal =>
      match literal with
      | PsKernelLiteral.str value =>
          publicWhnf
            context
            state
            (psKernelStringLitToConstructor value)
      | PsKernelLiteral.nat _ =>
          Except.ok (Prod.mk expr state)
  | _ =>
      Except.ok (Prod.mk expr state)

/-
Configuration-aware semantic refinement for the projection branch of WHNF core.

This is separated from the main fuel induction because the branch combines
major normalization, String-literal constructor expansion, projection
computation, recursive normalization, and cache publication.

This module is a registered PsKernelCoreMetatheory root; CI therefore validates
the theorem itself rather than only its eventual import site.
-/

theorem psKernelWhnfCoreProjection_configuration_refines
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
    (hPublic :
      PsKernelWhnfConfigurationSound publicWhnf)
    (hSmaller :
      PsKernelWhnfCoreConfigurationSound
        (psKernelWhnfCoreWithFuel
          remaining
          publicWhnf
          reduceRecursor))
    (context nextContext : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (typeName : PsKernelName)
    (index : Nat)
    (structValue result : PsKernelExpr)
    (cheapRec cheapProj : Bool)
    (hConfig :
      PsKernelCheckerConfigurationSound context state)
    (hDepth :
      psKernelCheckerContextEnterRecDepth context =
        Except.ok nextContext)
    (hMiss :
      (if
          psKernelWhnfCacheEligible
            (PsKernelExpr.proj typeName index structValue) then
        psKernelExprMapGet
          state.whnfCore
          (PsKernelExpr.proj typeName index structValue)
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
          (PsKernelExpr.proj typeName index structValue)
          cheapRec
          cheapProj =
        Except.ok (Prod.mk result nextState)) :
    PsKernelReductionClosure
        context.environment
        context.localContext
        (PsKernelExpr.proj typeName index structValue)
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
    PsKernelExpr.proj typeName index structValue
  let structResult :=
    if cheapProj then
      psKernelWhnfCoreWithFuel
        remaining
        publicWhnf
        reduceRecursor
        nextContext
        state
        structValue
        cheapRec
        cheapProj
    else
      publicWhnf
        nextContext
        state
        structValue
  cases hStruct : structResult with
  | error error =>
      simp [
        psKernelWhnfCoreWithFuel,
        hDepth,
        hMiss,
        original,
        structResult,
        hStruct
      ] at hSuccess
  | ok firstRun =>
      rcases firstRun with ⟨structReduced, state1⟩
      have hStructSemantic :
          PsKernelReductionClosure
              nextContext.environment
              nextContext.localContext
              structValue
              structReduced ∧
            PsKernelCheckerConfigurationSound
              nextContext
              state1 := by
        cases cheapProj with
        | false =>
            have hRun :
                publicWhnf
                    nextContext
                    state
                    structValue =
                  Except.ok
                    (Prod.mk structReduced state1) := by
              simpa [structResult] using hStruct
            exact
              hPublic
                nextContext
                state
                state1
                structValue
                structReduced
                hNextConfig
                hRun
        | true =>
            have hRun :
                psKernelWhnfCoreWithFuel
                    remaining
                    publicWhnf
                    reduceRecursor
                    nextContext
                    state
                    structValue
                    cheapRec
                    true =
                  Except.ok
                    (Prod.mk structReduced state1) := by
              simpa [structResult] using hStruct
            exact
              hSmaller
                nextContext
                state
                state1
                structValue
                structReduced
                cheapRec
                true
                hNextConfig
                hRun
      let expandedResult :
          Except String
            (Prod PsKernelExpr PsKernelCheckerState) :=
        psKernelWhnfProjectionExpandWith
          publicWhnf
          nextContext
          state1
          structReduced
      have hSuccessExpanded :
          (match expandedResult with
           | Except.error error =>
               Except.error error
           | Except.ok secondResult =>
               match
                   psKernelReduceProjCore
                     nextContext
                     typeName
                     index
                     (Prod.fst secondResult) with
               | Option.none =>
                   psKernelWhnfCoreFinish
                     original
                     (Bool.or cheapRec cheapProj)
                     original
                     (Prod.snd secondResult)
               | Option.some value =>
                   match
                       psKernelWhnfCoreWithFuel
                         remaining
                         publicWhnf
                         reduceRecursor
                         nextContext
                         (Prod.snd secondResult)
                         value
                         cheapRec
                         cheapProj with
                   | Except.error error =>
                       Except.error error
                   | Except.ok reduced =>
                       psKernelWhnfCoreFinish
                         original
                         (Bool.or cheapRec cheapProj)
                         (Prod.fst reduced)
                         (Prod.snd reduced)) =
            Except.ok (Prod.mk result nextState) := by
        have hMain := hSuccess
        simp only [
          psKernelWhnfCoreWithFuel,
          hDepth,
          hMiss,
          structResult,
          hStruct
        ] at hMain
        change
          (match
              psKernelWhnfProjectionExpandWith
                publicWhnf
                nextContext
                state1
                structReduced with
           | Except.error error =>
               Except.error error
           | Except.ok secondResult =>
               match
                   psKernelReduceProjCore
                     nextContext
                     typeName
                     index
                     (Prod.fst secondResult) with
               | Option.none =>
                   psKernelWhnfCoreFinish
                     original
                     (Bool.or cheapRec cheapProj)
                     original
                     (Prod.snd secondResult)
               | Option.some value =>
                   match
                       psKernelWhnfCoreWithFuel
                         remaining
                         publicWhnf
                         reduceRecursor
                         nextContext
                         (Prod.snd secondResult)
                         value
                         cheapRec
                         cheapProj with
                   | Except.error error =>
                       Except.error error
                   | Except.ok reduced =>
                       psKernelWhnfCoreFinish
                         original
                         (Bool.or cheapRec cheapProj)
                         (Prod.fst reduced)
                         (Prod.snd reduced)) =
            Except.ok (Prod.mk result nextState) at hMain
        simpa [expandedResult] using hMain
      cases hExpanded : expandedResult with
      | error error =>
          simp [hExpanded] at hSuccessExpanded
      | ok secondRun =>
          rcases secondRun with ⟨expanded, state2⟩
          have hExpandedSemantic :
              PsKernelReductionClosure
                  nextContext.environment
                  nextContext.localContext
                  structValue
                  expanded ∧
                PsKernelCheckerConfigurationSound
                  nextContext
                  state2 := by
            cases structReduced with
            | bvar value =>
                simp [psKernelWhnfProjectionExpandWith, expandedResult] at hExpanded
                rcases hExpanded with ⟨rfl, rfl⟩
                exact hStructSemantic
            | fvar value =>
                simp [psKernelWhnfProjectionExpandWith, expandedResult] at hExpanded
                rcases hExpanded with ⟨rfl, rfl⟩
                exact hStructSemantic
            | mvar value =>
                simp [psKernelWhnfProjectionExpandWith, expandedResult] at hExpanded
                rcases hExpanded with ⟨rfl, rfl⟩
                exact hStructSemantic
            | sort value =>
                simp [psKernelWhnfProjectionExpandWith, expandedResult] at hExpanded
                rcases hExpanded with ⟨rfl, rfl⟩
                exact hStructSemantic
            | const name levels =>
                simp [psKernelWhnfProjectionExpandWith, expandedResult] at hExpanded
                rcases hExpanded with ⟨rfl, rfl⟩
                exact hStructSemantic
            | app fn arg =>
                simp [psKernelWhnfProjectionExpandWith, expandedResult] at hExpanded
                rcases hExpanded with ⟨rfl, rfl⟩
                exact hStructSemantic
            | lam name type body binderInfo =>
                simp [psKernelWhnfProjectionExpandWith, expandedResult] at hExpanded
                rcases hExpanded with ⟨rfl, rfl⟩
                exact hStructSemantic
            | forallE name type body binderInfo =>
                simp [psKernelWhnfProjectionExpandWith, expandedResult] at hExpanded
                rcases hExpanded with ⟨rfl, rfl⟩
                exact hStructSemantic
            | letE name type value body nondep =>
                simp [psKernelWhnfProjectionExpandWith, expandedResult] at hExpanded
                rcases hExpanded with ⟨rfl, rfl⟩
                exact hStructSemantic
            | lit literal =>
                cases literal with
                | nat value =>
                    simp [psKernelWhnfProjectionExpandWith, expandedResult] at hExpanded
                    rcases hExpanded with ⟨rfl, rfl⟩
                    exact hStructSemantic
                | str value =>
                    have hStringRun :
                        publicWhnf
                            nextContext
                            state1
                            (psKernelStringLitToConstructor value) =
                          Except.ok
                            (Prod.mk expanded state2) := by
                      simpa [psKernelWhnfProjectionExpandWith, expandedResult] using hExpanded
                    have hStringSemantic :=
                      hPublic
                        nextContext
                        state1
                        state2
                        (psKernelStringLitToConstructor value)
                        expanded
                        hStructSemantic.2
                        hStringRun
                    have hLiteralStep :
                        PsKernelReductionClosure
                          nextContext.environment
                          nextContext.localContext
                          (PsKernelExpr.lit
                            (PsKernelLiteral.str value))
                          (psKernelStringLitToConstructor value) :=
                      PsKernelReductionClosure.cons
                        (PsKernelExpr.lit
                          (PsKernelLiteral.str value))
                        (psKernelStringLitToConstructor value)
                        (psKernelStringLitToConstructor value)
                        (PsKernelReductionStep.stringLiteral value)
                        (PsKernelReductionClosure.refl
                          (psKernelStringLitToConstructor value))
                    exact
                      ⟨
                        psKernelReductionClosure_transitive
                          nextContext.environment
                          nextContext.localContext
                          structValue
                          (PsKernelExpr.lit
                            (PsKernelLiteral.str value))
                          expanded
                          hStructSemantic.1
                          (psKernelReductionClosure_transitive
                            nextContext.environment
                            nextContext.localContext
                            (PsKernelExpr.lit
                              (PsKernelLiteral.str value))
                            (psKernelStringLitToConstructor value)
                            expanded
                            hLiteralStep
                            hStringSemantic.1),
                        hStringSemantic.2
                      ⟩
            | mdata metadata body =>
                simp [psKernelWhnfProjectionExpandWith, expandedResult] at hExpanded
                rcases hExpanded with ⟨rfl, rfl⟩
                exact hStructSemantic
            | proj projectionName projectionIndex body =>
                simp [psKernelWhnfProjectionExpandWith, expandedResult] at hExpanded
                rcases hExpanded with ⟨rfl, rfl⟩
                exact hStructSemantic
          cases hProjection :
              psKernelReduceProjCore
                nextContext
                typeName
                index
                expanded with
          | none =>
              have hFinish :
                  psKernelWhnfCoreFinish
                      original
                      (Bool.or cheapRec cheapProj)
                      original
                      state2 =
                    Except.ok
                      (Prod.mk result nextState) := by
                simpa [hExpanded, hProjection] using hSuccessExpanded
              have hFinishSemantic :=
                psKernelWhnfCoreFinish_success_refines
                  nextContext
                  state2
                  nextState
                  original
                  original
                  result
                  (Bool.or cheapRec cheapProj)
                  hExpandedSemantic.2
                  (PsKernelReductionClosure.refl original)
                  hFinish
              have hResult : result = original :=
                hFinishSemantic.1
              subst result
              exact
                ⟨
                  PsKernelReductionClosure.refl original,
                  hBackConfig
                    nextState
                    hFinishSemantic.2
                ⟩
          | some value =>
              have hProjectionSemantic :=
                psKernelReduceProjCore_some_refines_closure
                  nextContext
                  typeName
                  index
                  expanded
                  value
                  hExpandedSemantic.2.1
                  hProjection
              have hMajorSemantic :
                  PsKernelReductionClosure
                    nextContext.environment
                    nextContext.localContext
                    original
                    (PsKernelExpr.proj
                      typeName
                      index
                      expanded) := by
                simpa [original] using
                  PsKernelReductionClosure.projectionMajor
                    typeName
                    index
                    structValue
                    expanded
                    hExpandedSemantic.1
              have hToValue :
                  PsKernelReductionClosure
                    nextContext.environment
                    nextContext.localContext
                    original
                    value :=
                psKernelReductionClosure_transitive
                  nextContext.environment
                  nextContext.localContext
                  original
                  (PsKernelExpr.proj
                    typeName
                    index
                    expanded)
                  value
                  hMajorSemantic
                  hProjectionSemantic
              cases hReduce :
                  psKernelWhnfCoreWithFuel
                    remaining
                    publicWhnf
                    reduceRecursor
                    nextContext
                    state2
                    value
                    cheapRec
                    cheapProj with
              | error error =>
                  simp [hExpanded, hProjection, hReduce] at hSuccessExpanded
              | ok reduceRun =>
                  rcases reduceRun with ⟨reduced, state3⟩
                  have hReduceSemantic :=
                    hSmaller
                      nextContext
                      state2
                      state3
                      value
                      reduced
                      cheapRec
                      cheapProj
                      hExpandedSemantic.2
                      hReduce
                  have hCombined :
                      PsKernelReductionClosure
                        nextContext.environment
                        nextContext.localContext
                        original
                        reduced :=
                    psKernelReductionClosure_transitive
                      nextContext.environment
                      nextContext.localContext
                      original
                      value
                      reduced
                      hToValue
                      hReduceSemantic.1
                  have hFinish :
                      psKernelWhnfCoreFinish
                          original
                          (Bool.or cheapRec cheapProj)
                          reduced
                          state3 =
                        Except.ok
                          (Prod.mk result nextState) := by
                    simpa [hExpanded, hProjection, hReduce] using hSuccessExpanded
                  have hFinishSemantic :=
                    psKernelWhnfCoreFinish_success_refines
                      nextContext
                      state3
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
                      hBackReduction
                        original
                        reduced
                        hCombined,
                      hBackConfig
                        nextState
                        hFinishSemantic.2
                    ⟩
