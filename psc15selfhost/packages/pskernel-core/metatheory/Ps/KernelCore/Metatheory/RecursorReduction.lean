import Ps.KernelCore.Checker.Recursor.Reduction
import Ps.KernelCore.Metatheory.CheckerContracts
import Ps.KernelCore.Metatheory.QuotReduction
import Ps.KernelCore.Metatheory.ReductionCongruence

/-
Configuration-aware semantics for recursor computation.

K conversion and structure conversion are explicit proof obligations because
they are semantic conversions, not ordinary WHNF callbacks.  The top-level
recursor reducer itself is then just Quot reduction followed by ordinary
inductive recursor reduction.
-/

def PsKernelRecursorKConversionConfigurationSound
    (publicWhnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (inferType :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String (Prod Bool PsKernelCheckerState)) : Prop :=
  ∀
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (recursor : PsKernelRecursorInfo)
    (major result : PsKernelExpr),
    PsKernelCheckerConfigurationSound context state ->
    psKernelToConstructorWhenK
        publicWhnf
        inferType
        defeq
        context
        state
        recursor
        major =
      Except.ok (Prod.mk result nextState) ->
    PsKernelCheckerConfigurationSound context nextState ∧
      PsKernelReductionClosure
        context.environment
        context.localContext
        major
        result


def PsKernelRecursorStructureConversionConfigurationSound
    (publicWhnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (inferType :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState)) : Prop :=
  ∀
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (recursor : PsKernelRecursorInfo)
    (major result : PsKernelExpr),
    PsKernelCheckerConfigurationSound context state ->
    psKernelToConstructorWhenStructure
        publicWhnf
        inferType
        context
        state
        recursor
        major =
      Except.ok (Prod.mk result nextState) ->
    PsKernelCheckerConfigurationSound context nextState ∧
      PsKernelReductionClosure
        context.environment
        context.localContext
        major
        result


def psKernelRecursorPrepareMajorWith
    (publicWhnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (coreWhnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Bool ->
      Bool ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (inferType :
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
    (recursor : PsKernelRecursorInfo)
    (major0 : PsKernelExpr)
    (cheapRec cheapProj : Bool) :
    Except String (Prod PsKernelExpr PsKernelCheckerState) :=
  let majorKResult :
      Except String (Prod PsKernelExpr PsKernelCheckerState) :=
    if recursor.k then
      psKernelToConstructorWhenK
        publicWhnf
        inferType
        defeq
        context
        state
        recursor
        major0
    else
      Except.ok (Prod.mk major0 state)
  match majorKResult with
  | Except.error error =>
      Except.error error
  | Except.ok majorK =>
      if
          psKernelIsConstructorApp
            context.environment
            (Prod.fst majorK) then
        Except.ok majorK
      else if cheapRec then
        coreWhnf
          context
          (Prod.snd majorK)
          (Prod.fst majorK)
          cheapRec
          cheapProj
      else
        publicWhnf
          context
          (Prod.snd majorK)
          (Prod.fst majorK)


theorem psKernelRecursorPrepareMajorWith_configuration_sound
    (publicWhnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (coreWhnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Bool ->
      Bool ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (inferType :
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
      PsKernelWhnfConfigurationSound publicWhnf)
    (hCore :
      PsKernelWhnfCoreConfigurationSound coreWhnf)
    (hK :
      PsKernelRecursorKConversionConfigurationSound
        publicWhnf inferType defeq)
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (recursor : PsKernelRecursorInfo)
    (major0 result : PsKernelExpr)
    (cheapRec cheapProj : Bool)
    (hConfig :
      PsKernelCheckerConfigurationSound context state)
    (hSuccess :
      psKernelRecursorPrepareMajorWith
          publicWhnf
          coreWhnf
          inferType
          defeq
          context
          state
          recursor
          major0
          cheapRec
          cheapProj =
        Except.ok (Prod.mk result nextState)) :
    PsKernelReductionClosure
        context.environment
        context.localContext
        major0
        result ∧
      PsKernelCheckerConfigurationSound
        context
        nextState := by
  cases hKFlag : recursor.k with
  | false =>
      have hBaseReduction :
          PsKernelReductionClosure
            context.environment
            context.localContext
            major0
            major0 :=
        PsKernelReductionClosure.refl major0
      cases hCtor :
          psKernelIsConstructorApp
            context.environment
            major0 with
      | true =>
          simp [
            psKernelRecursorPrepareMajorWith,
            hKFlag,
            hCtor
          ] at hSuccess
          rcases hSuccess with ⟨rfl, rfl⟩
          exact ⟨hBaseReduction, hConfig⟩
      | false =>
          cases cheapRec with
          | false =>
              cases hRun :
                  publicWhnf
                    context
                    state
                    major0 with
              | error error =>
                  simp [
                    psKernelRecursorPrepareMajorWith,
                    hKFlag,
                    hCtor,
                    hRun
                  ] at hSuccess
              | ok run =>
                  rcases run with ⟨reduced, reducedState⟩
                  have hSemantic :=
                    hWhnf
                      context state reducedState
                      major0 reduced
                      hConfig hRun
                  simp [
                    psKernelRecursorPrepareMajorWith,
                    hKFlag,
                    hCtor,
                    hRun
                  ] at hSuccess
                  rcases hSuccess with ⟨rfl, rfl⟩
                  exact hSemantic
          | true =>
              cases hRun :
                  coreWhnf
                    context
                    state
                    major0
                    true
                    cheapProj with
              | error error =>
                  simp [
                    psKernelRecursorPrepareMajorWith,
                    hKFlag,
                    hCtor,
                    hRun
                  ] at hSuccess
              | ok run =>
                  rcases run with ⟨reduced, reducedState⟩
                  have hSemantic :=
                    hCore
                      context state reducedState
                      major0 reduced
                      true cheapProj
                      hConfig hRun
                  simp [
                    psKernelRecursorPrepareMajorWith,
                    hKFlag,
                    hCtor,
                    hRun
                  ] at hSuccess
                  rcases hSuccess with ⟨rfl, rfl⟩
                  exact hSemantic
  | true =>
      cases hKRun :
          psKernelToConstructorWhenK
            publicWhnf
            inferType
            defeq
            context
            state
            recursor
            major0 with
      | error error =>
          simp [
            psKernelRecursorPrepareMajorWith,
            hKFlag,
            hKRun
          ] at hSuccess
      | ok run =>
          rcases run with ⟨majorK, stateK⟩
          have hKSemantic :=
            hK
              context state stateK
              recursor major0 majorK
              hConfig hKRun
          cases hCtor :
              psKernelIsConstructorApp
                context.environment
                majorK with
          | true =>
              simp [
                psKernelRecursorPrepareMajorWith,
                hKFlag,
                hKRun,
                hCtor
              ] at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              exact ⟨hKSemantic.2, hKSemantic.1⟩
          | false =>
              cases cheapRec with
              | false =>
                  cases hRun :
                      publicWhnf
                        context
                        stateK
                        majorK with
                  | error error =>
                      simp [
                        psKernelRecursorPrepareMajorWith,
                        hKFlag,
                        hKRun,
                        hCtor,
                        hRun
                      ] at hSuccess
                  | ok reducedRun =>
                      rcases reducedRun with
                        ⟨reduced, reducedState⟩
                      have hReducedSemantic :=
                        hWhnf
                          context stateK reducedState
                          majorK reduced
                          hKSemantic.1 hRun
                      simp [
                        psKernelRecursorPrepareMajorWith,
                        hKFlag,
                        hKRun,
                        hCtor,
                        hRun
                      ] at hSuccess
                      rcases hSuccess with ⟨rfl, rfl⟩
                      exact
                        ⟨
                          psKernelReductionClosure_transitive
                            context.environment
                            context.localContext
                            major0 majorK reduced
                            hKSemantic.2
                            hReducedSemantic.1,
                          hReducedSemantic.2
                        ⟩
              | true =>
                  cases hRun :
                      coreWhnf
                        context
                        stateK
                        majorK
                        true
                        cheapProj with
                  | error error =>
                      simp [
                        psKernelRecursorPrepareMajorWith,
                        hKFlag,
                        hKRun,
                        hCtor,
                        hRun
                      ] at hSuccess
                  | ok reducedRun =>
                      rcases reducedRun with
                        ⟨reduced, reducedState⟩
                      have hReducedSemantic :=
                        hCore
                          context stateK reducedState
                          majorK reduced
                          true cheapProj
                          hKSemantic.1 hRun
                      simp [
                        psKernelRecursorPrepareMajorWith,
                        hKFlag,
                        hKRun,
                        hCtor,
                        hRun
                      ] at hSuccess
                      rcases hSuccess with ⟨rfl, rfl⟩
                      exact
                        ⟨
                          psKernelReductionClosure_transitive
                            context.environment
                            context.localContext
                            major0 majorK reduced
                            hKSemantic.2
                            hReducedSemantic.1,
                          hReducedSemantic.2
                        ⟩


def PsKernelRecursorNormalizedMajor
    (environment : PsKernelEnvironment)
    (localContext : PsKernelLocalContext)
    (input output : PsKernelExpr) : Prop :=
  ∃ reduced : PsKernelExpr,
    PsKernelReductionClosure
        environment
        localContext
        input
        reduced ∧
      PsKernelRecursorMajorNormalization
        reduced
        output


def psKernelRecursorNormalizeMajorWith
    (publicWhnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (inferType :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (recursor : PsKernelRecursorInfo)
    (majorReduced : PsKernelExpr) :
    Except String (Prod PsKernelExpr PsKernelCheckerState) :=
  match majorReduced with
  | PsKernelExpr.lit literal =>
      match literal with
      | PsKernelLiteral.nat value =>
          match value with
          | Nat.zero =>
              Except.ok
                (Prod.mk
                  (PsKernelExpr.const
                    psKernelNatZeroName
                    List.nil)
                  state)
          | Nat.succ predecessor =>
              Except.ok
                (Prod.mk
                  (PsKernelExpr.app
                    (PsKernelExpr.const
                      psKernelNatSuccName
                      List.nil)
                    (PsKernelExpr.lit
                      (PsKernelLiteral.nat predecessor)))
                  state)
      | PsKernelLiteral.str value =>
          publicWhnf
            context
            state
            (psKernelStringLitToConstructor value)
  | _ =>
      psKernelToConstructorWhenStructure
        publicWhnf
        inferType
        context
        state
        recursor
        majorReduced


theorem psKernelRecursorNormalizeMajorWith_configuration_sound
    (publicWhnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (inferType :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (hWhnf :
      PsKernelWhnfConfigurationSound publicWhnf)
    (hStructure :
      PsKernelRecursorStructureConversionConfigurationSound
        publicWhnf
        inferType)
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (recursor : PsKernelRecursorInfo)
    (majorReduced normalized : PsKernelExpr)
    (hConfig :
      PsKernelCheckerConfigurationSound context state)
    (hSuccess :
      psKernelRecursorNormalizeMajorWith
          publicWhnf
          inferType
          context
          state
          recursor
          majorReduced =
        Except.ok (Prod.mk normalized nextState)) :
    PsKernelCheckerConfigurationSound context nextState ∧
      PsKernelRecursorNormalizedMajor
        context.environment
        context.localContext
        majorReduced
        normalized := by
  cases majorReduced with
  | lit literal =>
      cases literal with
      | nat value =>
          cases value with
          | zero =>
              simp [
                psKernelRecursorNormalizeMajorWith
              ] at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              constructor
              · exact hConfig
              · exact
                  ⟨
                    PsKernelExpr.lit
                      (PsKernelLiteral.nat 0),
                    PsKernelReductionClosure.refl
                      (PsKernelExpr.lit
                        (PsKernelLiteral.nat 0)),
                    PsKernelRecursorMajorNormalization.natZero
                  ⟩
          | succ predecessor =>
              simp [
                psKernelRecursorNormalizeMajorWith
              ] at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              constructor
              · exact hConfig
              · exact
                  ⟨
                    PsKernelExpr.lit
                      (PsKernelLiteral.nat
                        (Nat.succ predecessor)),
                    PsKernelReductionClosure.refl
                      (PsKernelExpr.lit
                        (PsKernelLiteral.nat
                          (Nat.succ predecessor))),
                    PsKernelRecursorMajorNormalization.natSucc
                      predecessor
                  ⟩
      | str value =>
          cases hWhnfRun :
              publicWhnf
                context
                state
                (psKernelStringLitToConstructor value) with
          | error error =>
              simp [
                psKernelRecursorNormalizeMajorWith,
                hWhnfRun
              ] at hSuccess
          | ok run =>
              rcases run with ⟨result, resultState⟩
              have hWhnfSemantic :=
                hWhnf
                  context
                  state
                  resultState
                  (psKernelStringLitToConstructor value)
                  result
                  hConfig
                  hWhnfRun
              simp [
                psKernelRecursorNormalizeMajorWith,
                hWhnfRun
              ] at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              have hStringStep :
                  PsKernelReductionClosure
                    context.environment
                    context.localContext
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
              have hCombined :
                  PsKernelReductionClosure
                    context.environment
                    context.localContext
                    (PsKernelExpr.lit
                      (PsKernelLiteral.str value))
                    result :=
                psKernelReductionClosure_transitive
                  context.environment
                  context.localContext
                  (PsKernelExpr.lit
                    (PsKernelLiteral.str value))
                  (psKernelStringLitToConstructor value)
                  result
                  hStringStep
                  hWhnfSemantic.1
              exact
                ⟨
                  hWhnfSemantic.2,
                  ⟨
                    result,
                    hCombined,
                    PsKernelRecursorMajorNormalization.identity
                      result
                  ⟩
                ⟩
  | bvar index =>
      have hStructureSemantic :=
        hStructure
          context state nextState recursor
          (PsKernelExpr.bvar index)
          normalized
          hConfig
          (by
            simpa [psKernelRecursorNormalizeMajorWith]
              using hSuccess)
      exact
        ⟨
          hStructureSemantic.1,
          ⟨
            normalized,
            hStructureSemantic.2,
            PsKernelRecursorMajorNormalization.identity normalized
          ⟩
        ⟩
  | fvar name =>
      have hStructureSemantic :=
        hStructure
          context state nextState recursor
          (PsKernelExpr.fvar name)
          normalized
          hConfig
          (by
            simpa [psKernelRecursorNormalizeMajorWith]
              using hSuccess)
      exact
        ⟨hStructureSemantic.1,
          ⟨normalized, hStructureSemantic.2,
            PsKernelRecursorMajorNormalization.identity normalized⟩⟩
  | mvar name =>
      have hStructureSemantic :=
        hStructure
          context state nextState recursor
          (PsKernelExpr.mvar name)
          normalized
          hConfig
          (by
            simpa [psKernelRecursorNormalizeMajorWith]
              using hSuccess)
      exact
        ⟨hStructureSemantic.1,
          ⟨normalized, hStructureSemantic.2,
            PsKernelRecursorMajorNormalization.identity normalized⟩⟩
  | sort level =>
      have hStructureSemantic :=
        hStructure
          context state nextState recursor
          (PsKernelExpr.sort level)
          normalized
          hConfig
          (by
            simpa [psKernelRecursorNormalizeMajorWith]
              using hSuccess)
      exact
        ⟨hStructureSemantic.1,
          ⟨normalized, hStructureSemantic.2,
            PsKernelRecursorMajorNormalization.identity normalized⟩⟩
  | const name levels =>
      have hStructureSemantic :=
        hStructure
          context state nextState recursor
          (PsKernelExpr.const name levels)
          normalized
          hConfig
          (by
            simpa [psKernelRecursorNormalizeMajorWith]
              using hSuccess)
      exact
        ⟨hStructureSemantic.1,
          ⟨normalized, hStructureSemantic.2,
            PsKernelRecursorMajorNormalization.identity normalized⟩⟩
  | app fn arg =>
      have hStructureSemantic :=
        hStructure
          context state nextState recursor
          (PsKernelExpr.app fn arg)
          normalized
          hConfig
          (by
            simpa [psKernelRecursorNormalizeMajorWith]
              using hSuccess)
      exact
        ⟨hStructureSemantic.1,
          ⟨normalized, hStructureSemantic.2,
            PsKernelRecursorMajorNormalization.identity normalized⟩⟩
  | lam name type body binderInfo =>
      have hStructureSemantic :=
        hStructure
          context state nextState recursor
          (PsKernelExpr.lam name type body binderInfo)
          normalized
          hConfig
          (by
            simpa [psKernelRecursorNormalizeMajorWith]
              using hSuccess)
      exact
        ⟨hStructureSemantic.1,
          ⟨normalized, hStructureSemantic.2,
            PsKernelRecursorMajorNormalization.identity normalized⟩⟩
  | forallE name type body binderInfo =>
      have hStructureSemantic :=
        hStructure
          context state nextState recursor
          (PsKernelExpr.forallE name type body binderInfo)
          normalized
          hConfig
          (by
            simpa [psKernelRecursorNormalizeMajorWith]
              using hSuccess)
      exact
        ⟨hStructureSemantic.1,
          ⟨normalized, hStructureSemantic.2,
            PsKernelRecursorMajorNormalization.identity normalized⟩⟩
  | letE name type value body nondep =>
      have hStructureSemantic :=
        hStructure
          context state nextState recursor
          (PsKernelExpr.letE name type value body nondep)
          normalized
          hConfig
          (by
            simpa [psKernelRecursorNormalizeMajorWith]
              using hSuccess)
      exact
        ⟨hStructureSemantic.1,
          ⟨normalized, hStructureSemantic.2,
            PsKernelRecursorMajorNormalization.identity normalized⟩⟩
  | mdata metadata body =>
      have hStructureSemantic :=
        hStructure
          context state nextState recursor
          (PsKernelExpr.mdata metadata body)
          normalized
          hConfig
          (by
            simpa [psKernelRecursorNormalizeMajorWith]
              using hSuccess)
      exact
        ⟨hStructureSemantic.1,
          ⟨normalized, hStructureSemantic.2,
            PsKernelRecursorMajorNormalization.identity normalized⟩⟩
  | proj typeName index body =>
      have hStructureSemantic :=
        hStructure
          context state nextState recursor
          (PsKernelExpr.proj typeName index body)
          normalized
          hConfig
          (by
            simpa [psKernelRecursorNormalizeMajorWith]
              using hSuccess)
      exact
        ⟨hStructureSemantic.1,
          ⟨normalized, hStructureSemantic.2,
            PsKernelRecursorMajorNormalization.identity normalized⟩⟩


theorem psKernelEnvironmentFind_some_authoritative
    (environment : PsKernelEnvironment)
    (name : PsKernelName)
    (info : PsKernelConstantInfo)
    (hIndex :
      PsKernelEnvironmentIndexRefines environment)
    (hFind :
      psKernelEnvironmentFind environment name =
        Option.some info) :
    psKernelFindConstantInList
        name
        environment.constants =
      Option.some info := by
  have hRefines := hIndex name
  unfold psKernelEnvironmentFind at hFind
  calc
    psKernelFindConstantInList
        name
        environment.constants =
      psKernelFindConstantInList
        name
        (psKernelEnvironmentIndexFind
          environment.index
          name) := hRefines.symm
    _ = Option.some info := hFind


theorem psKernelRecursorIota_refines
    (context : PsKernelCheckerContext)
    (expr : PsKernelExpr)
    (recName ctorName : PsKernelName)
    (recLevels ctorLevels : List PsKernelLevel)
    (recArgs majorArgs : List PsKernelExpr)
    (recursor : PsKernelRecursorInfo)
    (rule : PsKernelRecursorRule)
    (major0 majorReduced major : PsKernelExpr)
    (hIndex :
      PsKernelEnvironmentIndexRefines
        context.environment)
    (hHead :
      Prod.fst (psKernelExprGetAppFnArgs expr) =
        PsKernelExpr.const recName recLevels)
    (hArgs :
      Prod.snd (psKernelExprGetAppFnArgs expr) =
        recArgs)
    (hFind :
      psKernelEnvironmentFind
          context.environment
          recName =
        Option.some
          (PsKernelConstantInfo.recInfo recursor))
    (hMajor :
      psKernelExprListGet
          recArgs
          (Nat.add
            recursor.numParams
            (Nat.add
              recursor.numMotives
              (Nat.add
                recursor.numMinors
                recursor.numIndices))) =
        Option.some major0)
    (hMajorReduction :
      PsKernelReductionClosure
        context.environment
        context.localContext
        major0
        majorReduced)
    (hNormalize :
      PsKernelRecursorMajorNormalization
        majorReduced major)
    (hCtorHead :
      Prod.fst (psKernelExprGetAppFnArgs major) =
        PsKernelExpr.const ctorName ctorLevels)
    (hMajorArgs :
      Prod.snd (psKernelExprGetAppFnArgs major) =
        majorArgs)
    (hRule :
      psKernelFindRecursorRule
          ctorName
          recursor.rules =
        Option.some rule)
    (hFields :
      psKernelNatGt
          rule.nFields
          (psKernelExprListLength majorArgs) =
        false)
    (hLevels :
      Nat.beq
          (psKernelLevelListLength recLevels)
          (psKernelNameListLength
            recursor.base.levelParams) =
        true) :
    PsKernelReductionClosure
      context.environment
      context.localContext
      expr
      (psKernelApplyArgs
        (psKernelApplyArgs
          (psKernelApplyArgs
            (psKernelExprInstantiateLevelParams
              rule.rhs
              recursor.base.levelParams
              recLevels)
            (psKernelExprListTake
              (Nat.add
                recursor.numParams
                (Nat.add
                  recursor.numMotives
                  recursor.numMinors))
              recArgs))
          (psKernelExprListTake
            rule.nFields
            (psKernelExprListDrop
              (Nat.sub
                (psKernelExprListLength majorArgs)
                rule.nFields)
              majorArgs)))
        (psKernelExprListDrop
          (Nat.succ
            (Nat.add
              recursor.numParams
              (Nat.add
                recursor.numMotives
                (Nat.add
                  recursor.numMinors
                  recursor.numIndices))))
          recArgs)) := by
  exact
    PsKernelReductionClosure.recursorIota
      expr
      recName
      ctorName
      recLevels
      ctorLevels
      recArgs
      majorArgs
      recursor
      rule
      major0
      majorReduced
      major
      hHead
      hArgs
      (psKernelEnvironmentFind_some_authoritative
        context.environment
        recName
        (PsKernelConstantInfo.recInfo recursor)
        hIndex
        hFind)
      hMajor
      hMajorReduction
      hNormalize
      hCtorHead
      hMajorArgs
      hRule
      hFields
      hLevels


theorem psKernelReduceRecursorWith_configuration_sound_of_inductive
    (publicWhnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (coreWhnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Bool ->
      Bool ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (inferType :
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
      PsKernelWhnfConfigurationSound publicWhnf)
    (hInductive :
      PsKernelRecursorReductionConfigurationSound
        (psKernelReduceInductiveRecWith
          publicWhnf
          coreWhnf
          inferType
          defeq)) :
    PsKernelRecursorReductionConfigurationSound
      (psKernelReduceRecursorWith
        publicWhnf
        coreWhnf
        inferType
        defeq) := by
  intro
    context state nextState expr cheapRec cheapProj answer
    hConfig hSuccess
  have hQuotSound :=
    psKernelReduceQuotWith_configuration_sound
      publicWhnf
      hWhnf
  cases hQuot :
      psKernelReduceQuotWith
        publicWhnf
        context
        state
        expr with
  | error error =>
      simp [
        psKernelReduceRecursorWith,
        hQuot
      ] at hSuccess
  | ok quotient =>
      rcases quotient with
        ⟨quotientAnswer, quotientState⟩
      have hQuotSemantic :=
        hQuotSound
          context
          state
          quotientState
          expr
          quotientAnswer
          hConfig
          hQuot
      cases quotientAnswer with
      | some value =>
          simp [
            psKernelReduceRecursorWith,
            hQuot
          ] at hSuccess
          rcases hSuccess with ⟨rfl, rfl⟩
          exact hQuotSemantic
      | none =>
          have hInductiveRun :
              psKernelReduceInductiveRecWith
                  publicWhnf
                  coreWhnf
                  inferType
                  defeq
                  context
                  quotientState
                  expr
                  cheapRec
                  cheapProj =
                Except.ok
                  (Prod.mk answer nextState) := by
            simpa [
              psKernelReduceRecursorWith,
              hQuot
            ] using hSuccess
          exact
            hInductive
              context
              quotientState
              nextState
              expr
              cheapRec
              cheapProj
              answer
              hQuotSemantic.1
              hInductiveRun
