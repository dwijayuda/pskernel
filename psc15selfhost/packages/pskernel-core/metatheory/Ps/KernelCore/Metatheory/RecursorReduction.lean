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


theorem psKernelFindRecursorRule_some_matches_metatheory
    (ctorName : PsKernelName)
    (rules : List PsKernelRecursorRule)
    (rule : PsKernelRecursorRule)
    (hSearch :
      psKernelFindRecursorRule ctorName rules =
        Option.some rule) :
    psKernelNameEq rule.ctor ctorName = true := by
  induction rules with
  | nil =>
      simp [psKernelFindRecursorRule] at hSearch
  | cons head tail ih =>
      cases hEq :
          psKernelNameEq head.ctor ctorName with
      | false =>
          simp [psKernelFindRecursorRule, hEq] at hSearch
          exact ih hSearch
      | true =>
          simp [psKernelFindRecursorRule, hEq] at hSearch
          subst rule
          exact hEq


theorem psKernelFindRecursorRule_some_mem_metatheory
    (ctorName : PsKernelName)
    (rules : List PsKernelRecursorRule)
    (rule : PsKernelRecursorRule)
    (hSearch :
      psKernelFindRecursorRule ctorName rules =
        Option.some rule) :
    rule ∈ rules := by
  induction rules with
  | nil =>
      simp [psKernelFindRecursorRule] at hSearch
  | cons head tail ih =>
      cases hEq :
          psKernelNameEq head.ctor ctorName with
      | false =>
          simp [psKernelFindRecursorRule, hEq] at hSearch
          exact List.mem_cons_of_mem head (ih hSearch)
      | true =>
          simp [psKernelFindRecursorRule, hEq] at hSearch
          subst rule
          exact List.mem_cons_self


theorem psKernelRecursorIota_refines
    (context : PsKernelCheckerContext)
    (expr : PsKernelExpr)
    (recName ctorName : PsKernelName)
    (recLevels ctorLevels : List PsKernelLevel)
    (recArgs majorArgs : List PsKernelExpr)
    (recursor : PsKernelRecursorInfo)
    (rule : PsKernelRecursorRule)
    (major0 prepared majorReduced major : PsKernelExpr)
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
    (hPrepared :
      PsKernelDefEqJudgment
        context.environment
        context.localContext
        major0
        prepared)
    (hMajorConversion :
      PsKernelDefEqJudgment
        context.environment
        context.localContext
        prepared
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
      prepared
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
      hPrepared
      hMajorConversion
      hNormalize
      hCtorHead
      hMajorArgs
      (psKernelFindRecursorRule_some_mem_metatheory
        ctorName recursor.rules rule hRule)
      (psKernelFindRecursorRule_some_matches_metatheory
        ctorName recursor.rules rule hRule)
      hFields
      hLevels



def psKernelReduceInductiveRecMajorTailWith
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
    (recLevels : List PsKernelLevel)
    (recArgs : List PsKernelExpr)
    (major0 : PsKernelExpr)
    (cheapRec cheapProj : Bool) :
    Except String
      (Prod (Option PsKernelExpr) PsKernelCheckerState) :=
  match
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
        cheapProj with
  | Except.error error =>
      Except.error error
  | Except.ok prepared =>
      match
          psKernelRecursorNormalizeMajorWith
            publicWhnf
            inferType
            context
            (Prod.snd prepared)
            recursor
            (Prod.fst prepared) with
      | Except.error error =>
          Except.error error
      | Except.ok normalized =>
          let major :=
            Prod.fst normalized
          let majorSpine :=
            psKernelExprGetAppFnArgs major
          match Prod.fst majorSpine with
          | PsKernelExpr.const ctorName _ =>
              match
                  psKernelFindRecursorRule
                    ctorName
                    recursor.rules with
              | Option.none =>
                  Except.ok
                    (Prod.mk
                      Option.none
                      (Prod.snd normalized))
              | Option.some rule =>
                  let majorArgs :=
                    Prod.snd majorSpine
                  if
                      psKernelNatGt
                        rule.nFields
                        (psKernelExprListLength majorArgs) then
                    Except.ok
                      (Prod.mk
                        Option.none
                        (Prod.snd normalized))
                  else if
                      Nat.beq
                        (psKernelLevelListLength recLevels)
                        (psKernelNameListLength
                          recursor.base.levelParams) then
                    let rhs0 :=
                      psKernelExprInstantiateLevelParams
                        rule.rhs
                        recursor.base.levelParams
                        recLevels
                    let fixedCount :=
                      Nat.add
                        recursor.numParams
                        (Nat.add
                          recursor.numMotives
                          recursor.numMinors)
                    let rhs1 :=
                      psKernelApplyArgs
                        rhs0
                        (psKernelExprListTake
                          fixedCount
                          recArgs)
                    let ctorParamCount :=
                      Nat.sub
                        (psKernelExprListLength majorArgs)
                        rule.nFields
                    let rhs2 :=
                      psKernelApplyArgs
                        rhs1
                        (psKernelExprListTake
                          rule.nFields
                          (psKernelExprListDrop
                            ctorParamCount
                            majorArgs))
                    let majorIndex :=
                      Nat.add
                        recursor.numParams
                        (Nat.add
                          recursor.numMotives
                          (Nat.add
                            recursor.numMinors
                            recursor.numIndices))
                    Except.ok
                      (Prod.mk
                        (Option.some
                          (psKernelApplyArgs
                            rhs2
                            (psKernelExprListDrop
                              (Nat.succ majorIndex)
                              recArgs)))
                        (Prod.snd normalized))
                  else
                    Except.ok
                      (Prod.mk
                        Option.none
                        (Prod.snd normalized))
          | _ =>
              Except.ok
                (Prod.mk
                  Option.none
                  (Prod.snd normalized))


theorem psKernelReduceInductiveRecMajorTailWith_configuration_sound
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
    (hStructure :
      PsKernelRecursorStructureConversionConfigurationSound
        publicWhnf inferType)
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (expr : PsKernelExpr)
    (recName : PsKernelName)
    (recLevels : List PsKernelLevel)
    (recArgs : List PsKernelExpr)
    (recursor : PsKernelRecursorInfo)
    (major0 : PsKernelExpr)
    (cheapRec cheapProj : Bool)
    (answer : Option PsKernelExpr)
    (hConfig :
      PsKernelCheckerConfigurationSound context state)
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
    (hSuccess :
      psKernelReduceInductiveRecMajorTailWith
          publicWhnf
          coreWhnf
          inferType
          defeq
          context
          state
          recursor
          recLevels
          recArgs
          major0
          cheapRec
          cheapProj =
        Except.ok (Prod.mk answer nextState)) :
    PsKernelOptionalReductionPostcondition
      context
      nextState
      expr
      answer := by
  cases hPrepared :
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
        cheapProj with
  | error error =>
      simp [
        psKernelReduceInductiveRecMajorTailWith,
        hPrepared
      ] at hSuccess
  | ok preparedRun =>
      rcases preparedRun with
        ⟨prepared, preparedState⟩
      have hPreparedSemantic :=
        psKernelRecursorPrepareMajorWith_configuration_sound
          publicWhnf
          coreWhnf
          inferType
          defeq
          hWhnf
          hCore
          hK
          context
          state
          preparedState
          recursor
          major0
          prepared
          cheapRec
          cheapProj
          hConfig
          hPrepared
      cases hNormalized :
          psKernelRecursorNormalizeMajorWith
            publicWhnf
            inferType
            context
            preparedState
            recursor
            prepared with
      | error error =>
          simp [
            psKernelReduceInductiveRecMajorTailWith,
            hPrepared,
            hNormalized
          ] at hSuccess
      | ok normalizedRun =>
          rcases normalizedRun with
            ⟨normalized, normalizedState⟩
          have hNormalizedSemantic :=
            psKernelRecursorNormalizeMajorWith_configuration_sound
              publicWhnf
              inferType
              hWhnf
              hStructure
              context
              preparedState
              normalizedState
              recursor
              prepared
              normalized
              hPreparedSemantic.2
              hNormalized
          rcases hNormalizedSemantic.2 with
            ⟨semanticReduced,
              hNormalizeReduction,
              hNormalize⟩
          have hMajorReduction :
              PsKernelReductionClosure
                context.environment
                context.localContext
                major0
                semanticReduced :=
            psKernelReductionClosure_transitive
              context.environment
              context.localContext
              major0
              prepared
              semanticReduced
              hPreparedSemantic.1
              hNormalizeReduction
          cases hCtorHead :
              Prod.fst
                (psKernelExprGetAppFnArgs normalized) with
          | const ctorName ctorLevels =>
              cases hRule :
                  psKernelFindRecursorRule
                    ctorName
                    recursor.rules with
              | none =>
                  simp [
                    psKernelReduceInductiveRecMajorTailWith,
                    hPrepared,
                    hNormalized,
                    hCtorHead,
                    hRule
                  ] at hSuccess
                  rcases hSuccess with ⟨rfl, rfl⟩
                  exact ⟨hNormalizedSemantic.1, trivial⟩
              | some rule =>
                  let majorArgs :=
                    Prod.snd
                      (psKernelExprGetAppFnArgs normalized)
                  cases hFields :
                      psKernelNatGt
                        rule.nFields
                        (psKernelExprListLength majorArgs) with
                  | true =>
                      simp [
                        psKernelReduceInductiveRecMajorTailWith,
                        hPrepared,
                        hNormalized,
                        hCtorHead,
                        hRule,
                        majorArgs,
                        hFields
                      ] at hSuccess
                      rcases hSuccess with ⟨rfl, rfl⟩
                      exact ⟨hNormalizedSemantic.1, trivial⟩
                  | false =>
                      cases hLevels :
                          Nat.beq
                            (psKernelLevelListLength recLevels)
                            (psKernelNameListLength
                              recursor.base.levelParams) with
                      | false =>
                          simp [
                            psKernelReduceInductiveRecMajorTailWith,
                            hPrepared,
                            hNormalized,
                            hCtorHead,
                            hRule,
                            majorArgs,
                            hFields,
                            hLevels
                          ] at hSuccess
                          rcases hSuccess with ⟨rfl, rfl⟩
                          exact ⟨hNormalizedSemantic.1, trivial⟩
                      | true =>
                          simp [
                            psKernelReduceInductiveRecMajorTailWith,
                            hPrepared,
                            hNormalized,
                            hCtorHead,
                            hRule,
                            majorArgs,
                            hFields,
                            hLevels
                          ] at hSuccess
                          rcases hSuccess with ⟨rfl, rfl⟩
                          constructor
                          · exact hNormalizedSemantic.1
                          · exact
                              psKernelRecursorIota_refines
                                context
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
                                semanticReduced
                                normalized
                                hConfig.1
                                hHead
                                hArgs
                                hFind
                                hMajor
                                hMajorReduction
                                hNormalize
                                hCtorHead
                                rfl
                                hRule
                                hFields
                                hLevels
          | bvar index =>
              simp [
                psKernelReduceInductiveRecMajorTailWith,
                hPrepared,
                hNormalized,
                hCtorHead
              ] at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              exact ⟨hNormalizedSemantic.1, trivial⟩
          | fvar name =>
              simp [
                psKernelReduceInductiveRecMajorTailWith,
                hPrepared,
                hNormalized,
                hCtorHead
              ] at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              exact ⟨hNormalizedSemantic.1, trivial⟩
          | mvar name =>
              simp [
                psKernelReduceInductiveRecMajorTailWith,
                hPrepared,
                hNormalized,
                hCtorHead
              ] at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              exact ⟨hNormalizedSemantic.1, trivial⟩
          | sort level =>
              simp [
                psKernelReduceInductiveRecMajorTailWith,
                hPrepared,
                hNormalized,
                hCtorHead
              ] at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              exact ⟨hNormalizedSemantic.1, trivial⟩
          | app fn arg =>
              simp [
                psKernelReduceInductiveRecMajorTailWith,
                hPrepared,
                hNormalized,
                hCtorHead
              ] at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              exact ⟨hNormalizedSemantic.1, trivial⟩
          | lam name type body binderInfo =>
              simp [
                psKernelReduceInductiveRecMajorTailWith,
                hPrepared,
                hNormalized,
                hCtorHead
              ] at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              exact ⟨hNormalizedSemantic.1, trivial⟩
          | forallE name type body binderInfo =>
              simp [
                psKernelReduceInductiveRecMajorTailWith,
                hPrepared,
                hNormalized,
                hCtorHead
              ] at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              exact ⟨hNormalizedSemantic.1, trivial⟩
          | letE name type value body nondep =>
              simp [
                psKernelReduceInductiveRecMajorTailWith,
                hPrepared,
                hNormalized,
                hCtorHead
              ] at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              exact ⟨hNormalizedSemantic.1, trivial⟩
          | lit literal =>
              simp [
                psKernelReduceInductiveRecMajorTailWith,
                hPrepared,
                hNormalized,
                hCtorHead
              ] at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              exact ⟨hNormalizedSemantic.1, trivial⟩
          | mdata metadata body =>
              simp [
                psKernelReduceInductiveRecMajorTailWith,
                hPrepared,
                hNormalized,
                hCtorHead
              ] at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              exact ⟨hNormalizedSemantic.1, trivial⟩
          | proj typeName index body =>
              simp [
                psKernelReduceInductiveRecMajorTailWith,
                hPrepared,
                hNormalized,
                hCtorHead
              ] at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              exact ⟨hNormalizedSemantic.1, trivial⟩


def psKernelReduceInductiveRecMajorInlineTailWith
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
    (recLevels : List PsKernelLevel)
    (recArgs : List PsKernelExpr)
    (major0 : PsKernelExpr)
    (cheapRec cheapProj : Bool) :
    Except String
      (Prod (Option PsKernelExpr) PsKernelCheckerState) :=
  let majorIndex :=
    Nat.add
      recursor.numParams
      (Nat.add
        recursor.numMotives
        (Nat.add
          recursor.numMinors
          recursor.numIndices))
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
      let reducedResult :
          Except String (Prod PsKernelExpr PsKernelCheckerState) :=
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
      match reducedResult with
      | Except.error error =>
          Except.error error
      | Except.ok reduced =>
          let majorReduced :=
            Prod.fst reduced
          let normalizeResult :
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
                            (Prod.snd reduced))
                    | Nat.succ predecessor =>
                        Except.ok
                          (Prod.mk
                            (PsKernelExpr.app
                              (PsKernelExpr.const
                                psKernelNatSuccName
                                List.nil)
                              (PsKernelExpr.lit
                                (PsKernelLiteral.nat
                                  predecessor)))
                            (Prod.snd reduced))
                | PsKernelLiteral.str value =>
                    publicWhnf
                      context
                      (Prod.snd reduced)
                      (psKernelStringLitToConstructor value)
            | _ =>
                psKernelToConstructorWhenStructure
                  publicWhnf
                  inferType
                  context
                  (Prod.snd reduced)
                  recursor
                  majorReduced
          match normalizeResult with
          | Except.error error =>
              Except.error error
          | Except.ok normalized =>
              let major :=
                Prod.fst normalized
              let majorSpine :=
                psKernelExprGetAppFnArgs major
              match Prod.fst majorSpine with
              | PsKernelExpr.const ctorName _ =>
                  match
                      psKernelFindRecursorRule
                        ctorName
                        recursor.rules with
                  | Option.none =>
                      Except.ok
                        (Prod.mk Option.none (Prod.snd normalized))
                  | Option.some rule =>
                      let majorArgs :=
                        Prod.snd majorSpine
                      if
                          psKernelNatGt
                            rule.nFields
                            (psKernelExprListLength majorArgs) then
                        Except.ok
                          (Prod.mk Option.none (Prod.snd normalized))
                      else if
                          Nat.beq
                            (psKernelLevelListLength recLevels)
                            (psKernelNameListLength
                              recursor.base.levelParams) then
                        let rhs0 :=
                          psKernelExprInstantiateLevelParams
                            rule.rhs
                            recursor.base.levelParams
                            recLevels
                        let fixedCount :=
                          Nat.add
                            recursor.numParams
                            (Nat.add
                              recursor.numMotives
                              recursor.numMinors)
                        let rhs1 :=
                          psKernelApplyArgs
                            rhs0
                            (psKernelExprListTake
                              fixedCount
                              recArgs)
                        let ctorParamCount :=
                          Nat.sub
                            (psKernelExprListLength majorArgs)
                            rule.nFields
                        let rhs2 :=
                          psKernelApplyArgs
                            rhs1
                            (psKernelExprListTake
                              rule.nFields
                              (psKernelExprListDrop
                                ctorParamCount
                                majorArgs))
                        Except.ok
                          (Prod.mk
                            (Option.some
                              (psKernelApplyArgs
                                rhs2
                                (psKernelExprListDrop
                                  (Nat.succ majorIndex)
                                  recArgs)))
                            (Prod.snd normalized))
                      else
                        Except.ok
                          (Prod.mk Option.none (Prod.snd normalized))
              | _ =>
                  Except.ok
                    (Prod.mk Option.none (Prod.snd normalized))


theorem psKernelReduceInductiveRecMajorInlineTailWith_eq_factored
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
    (recLevels : List PsKernelLevel)
    (recArgs : List PsKernelExpr)
    (major0 : PsKernelExpr)
    (cheapRec cheapProj : Bool) :
    psKernelReduceInductiveRecMajorInlineTailWith
        publicWhnf coreWhnf inferType defeq
        context state recursor recLevels recArgs major0
        cheapRec cheapProj =
      psKernelReduceInductiveRecMajorTailWith
        publicWhnf coreWhnf inferType defeq
        context state recursor recLevels recArgs major0
        cheapRec cheapProj := by
  unfold psKernelReduceInductiveRecMajorInlineTailWith
  unfold psKernelReduceInductiveRecMajorTailWith
  unfold psKernelRecursorPrepareMajorWith
  unfold psKernelRecursorNormalizeMajorWith
  cases hMajorK :
      (if recursor.k then
        psKernelToConstructorWhenK
          publicWhnf inferType defeq
          context state recursor major0
       else
        Except.ok (Prod.mk major0 state)) <;>
    rfl


def psKernelReduceInductiveRecPrefixWith
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
    (recLevels : List PsKernelLevel)
    (recArgs : List PsKernelExpr)
    (cheapRec cheapProj : Bool) :
    Except String
      (Prod (Option PsKernelExpr) PsKernelCheckerState) :=
  let majorIndex :=
    Nat.add
      recursor.numParams
      (Nat.add
        recursor.numMotives
        (Nat.add
          recursor.numMinors
          recursor.numIndices))
  if
      psKernelNatGe
        majorIndex
        (psKernelExprListLength recArgs) then
    Except.ok
      (Prod.mk Option.none state)
  else
    match
        psKernelExprListGet
          recArgs
          majorIndex with
    | Option.none =>
        Except.ok
          (Prod.mk Option.none state)
    | Option.some major0 =>
        psKernelReduceInductiveRecMajorInlineTailWith
          publicWhnf
          coreWhnf
          inferType
          defeq
          context
          state
          recursor
          recLevels
          recArgs
          major0
          cheapRec
          cheapProj


def psKernelReduceInductiveRecFactoredWith
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
    (expr : PsKernelExpr)
    (cheapRec cheapProj : Bool) :
    Except String
      (Prod (Option PsKernelExpr) PsKernelCheckerState) :=
  let recSpine :=
    psKernelExprGetAppFnArgs expr
  match Prod.fst recSpine with
  | PsKernelExpr.const recName recLevels =>
      match
          psKernelEnvironmentFind
            context.environment
            recName with
      | Option.some info =>
          match info with
          | PsKernelConstantInfo.recInfo recursor =>
              let recArgs :=
                Prod.snd recSpine
              psKernelReduceInductiveRecPrefixWith
                publicWhnf
                coreWhnf
                inferType
                defeq
                context
                state
                recursor
                recLevels
                recArgs
                cheapRec
                cheapProj
          | _ =>
              Except.ok
                (Prod.mk Option.none state)
      | Option.none =>
          Except.ok
            (Prod.mk Option.none state)
  | _ =>
      Except.ok
        (Prod.mk Option.none state)


theorem psKernelReduceInductiveRecWith_eq_factored
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
    (expr : PsKernelExpr)
    (cheapRec cheapProj : Bool) :
    psKernelReduceInductiveRecWith
        publicWhnf coreWhnf inferType defeq
        context state expr cheapRec cheapProj =
      psKernelReduceInductiveRecFactoredWith
        publicWhnf coreWhnf inferType defeq
        context state expr cheapRec cheapProj := by
  unfold psKernelReduceInductiveRecWith
  unfold psKernelReduceInductiveRecFactoredWith
  unfold psKernelReduceInductiveRecPrefixWith
  unfold psKernelReduceInductiveRecMajorInlineTailWith
  rfl


theorem psKernelReduceInductiveRecPrefixWith_configuration_sound
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
    (hStructure :
      PsKernelRecursorStructureConversionConfigurationSound
        publicWhnf inferType)
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (expr : PsKernelExpr)
    (recName : PsKernelName)
    (recLevels : List PsKernelLevel)
    (recArgs : List PsKernelExpr)
    (recursor : PsKernelRecursorInfo)
    (cheapRec cheapProj : Bool)
    (answer : Option PsKernelExpr)
    (hConfig :
      PsKernelCheckerConfigurationSound context state)
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
    (hSuccess :
      psKernelReduceInductiveRecPrefixWith
          publicWhnf
          coreWhnf
          inferType
          defeq
          context
          state
          recursor
          recLevels
          recArgs
          cheapRec
          cheapProj =
        Except.ok (Prod.mk answer nextState)) :
    PsKernelOptionalReductionPostcondition
      context
      nextState
      expr
      answer := by
  let majorIndex :=
    Nat.add
      recursor.numParams
      (Nat.add
        recursor.numMotives
        (Nat.add
          recursor.numMinors
          recursor.numIndices))
  have hExecutable :
      (if
          psKernelNatGe
              majorIndex
              (psKernelExprListLength recArgs) =
            true then
        Except.ok
          (Prod.mk Option.none state)
       else
        match
            psKernelExprListGet
              recArgs
              majorIndex with
        | Option.none =>
            Except.ok
              (Prod.mk Option.none state)
        | Option.some major0 =>
            psKernelReduceInductiveRecMajorInlineTailWith
              publicWhnf
              coreWhnf
              inferType
              defeq
              context
              state
              recursor
              recLevels
              recArgs
              major0
              cheapRec
              cheapProj) =
        Except.ok (Prod.mk answer nextState) := by
    simpa [
      psKernelReduceInductiveRecPrefixWith,
      majorIndex
    ] using hSuccess
  by_cases hShort :
      psKernelNatGe
          majorIndex
          (psKernelExprListLength recArgs) =
        true
  · have hRun := hExecutable
    rw [if_pos hShort] at hRun
    simp at hRun
    rcases hRun with ⟨hAnswer, hState⟩
    subst answer
    subst nextState
    exact ⟨hConfig, trivial⟩
  · have hRun := hExecutable
    rw [if_neg hShort] at hRun
    have hMajorCases :
        psKernelExprListGet recArgs majorIndex =
            Option.none ∨
          ∃ major0 : PsKernelExpr,
            psKernelExprListGet recArgs majorIndex =
              Option.some major0 := by
      cases hLookup :
          psKernelExprListGet recArgs majorIndex with
      | none =>
          exact Or.inl rfl
      | some major0 =>
          exact Or.inr ⟨major0, rfl⟩
    rcases hMajorCases with hMajor | ⟨major0, hMajor⟩
    · rw [hMajor] at hRun
      simp at hRun
      rcases hRun with ⟨hAnswer, hState⟩
      subst answer
      subst nextState
      exact ⟨hConfig, trivial⟩
    · rw [hMajor] at hRun
      have hInline :
          psKernelReduceInductiveRecMajorInlineTailWith
              publicWhnf
              coreWhnf
              inferType
              defeq
              context
              state
              recursor
              recLevels
              recArgs
              major0
              cheapRec
              cheapProj =
            Except.ok
              (Prod.mk answer nextState) :=
        hRun
      have hTail :
          psKernelReduceInductiveRecMajorTailWith
              publicWhnf
              coreWhnf
              inferType
              defeq
              context
              state
              recursor
              recLevels
              recArgs
              major0
              cheapRec
              cheapProj =
            Except.ok
              (Prod.mk answer nextState) := by
        rw [
          ← psKernelReduceInductiveRecMajorInlineTailWith_eq_factored
            publicWhnf
            coreWhnf
            inferType
            defeq
            context
            state
            recursor
            recLevels
            recArgs
            major0
            cheapRec
            cheapProj
        ]
        exact hInline
      have hTailSemantic :=
        psKernelReduceInductiveRecMajorTailWith_configuration_sound
          publicWhnf
          coreWhnf
          inferType
          defeq
          hWhnf
          hCore
          hK
          hStructure
          context
          state
          nextState
          expr
          recName
          recLevels
          recArgs
          recursor
          major0
          cheapRec
          cheapProj
          answer
          hConfig
          hHead
          hArgs
          hFind
          (by
            simpa [majorIndex] using hMajor)
          hTail
      simpa using hTailSemantic

theorem psKernelReduceInductiveRecFactoredWith_configuration_sound
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
    (hStructure :
      PsKernelRecursorStructureConversionConfigurationSound
        publicWhnf inferType) :
    PsKernelRecursorReductionConfigurationSound
      (psKernelReduceInductiveRecFactoredWith
        publicWhnf coreWhnf inferType defeq) := by
  intro
    context state nextState expr cheapRec cheapProj answer
    hConfig hSuccess
  let recSpine :=
    psKernelExprGetAppFnArgs expr
  cases hHead :
      Prod.fst recSpine with
  | const recName recLevels =>
      cases hFind :
          psKernelEnvironmentFind
            context.environment
            recName with
      | none =>
          simp [
            psKernelReduceInductiveRecFactoredWith,
            recSpine,
            hHead,
            hFind
          ] at hSuccess
          rcases hSuccess with ⟨rfl, rfl⟩
          exact ⟨hConfig, trivial⟩
      | some info =>
          cases info with
          | recInfo recursor =>
              let recArgs :=
                Prod.snd recSpine
              have hPrefix :
                  psKernelReduceInductiveRecPrefixWith
                      publicWhnf
                      coreWhnf
                      inferType
                      defeq
                      context
                      state
                      recursor
                      recLevels
                      recArgs
                      cheapRec
                      cheapProj =
                    Except.ok
                      (Prod.mk answer nextState) := by
                simpa [
                  psKernelReduceInductiveRecFactoredWith,
                  recSpine,
                  hHead,
                  hFind,
                  recArgs
                ] using hSuccess
              exact
                psKernelReduceInductiveRecPrefixWith_configuration_sound
                  publicWhnf
                  coreWhnf
                  inferType
                  defeq
                  hWhnf
                  hCore
                  hK
                  hStructure
                  context
                  state
                  nextState
                  expr
                  recName
                  recLevels
                  recArgs
                  recursor
                  cheapRec
                  cheapProj
                  answer
                  hConfig
                  (by
                    simpa [recSpine] using hHead)
                  (by
                    rfl)
                  hFind
                  hPrefix
          | axiomInfo value =>
              simp [
                psKernelReduceInductiveRecFactoredWith,
                recSpine,
                hHead,
                hFind
              ] at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              exact ⟨hConfig, trivial⟩
          | defnInfo value =>
              simp [
                psKernelReduceInductiveRecFactoredWith,
                recSpine,
                hHead,
                hFind
              ] at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              exact ⟨hConfig, trivial⟩
          | thmInfo value =>
              simp [
                psKernelReduceInductiveRecFactoredWith,
                recSpine,
                hHead,
                hFind
              ] at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              exact ⟨hConfig, trivial⟩
          | opaqueInfo value =>
              simp [
                psKernelReduceInductiveRecFactoredWith,
                recSpine,
                hHead,
                hFind
              ] at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              exact ⟨hConfig, trivial⟩
          | inductInfo value =>
              simp [
                psKernelReduceInductiveRecFactoredWith,
                recSpine,
                hHead,
                hFind
              ] at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              exact ⟨hConfig, trivial⟩
          | ctorInfo value =>
              simp [
                psKernelReduceInductiveRecFactoredWith,
                recSpine,
                hHead,
                hFind
              ] at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              exact ⟨hConfig, trivial⟩
          | quotInfo value =>
              simp [
                psKernelReduceInductiveRecFactoredWith,
                recSpine,
                hHead,
                hFind
              ] at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              exact ⟨hConfig, trivial⟩
  | bvar index =>
      simp [
        psKernelReduceInductiveRecFactoredWith,
        recSpine,
        hHead
      ] at hSuccess
      rcases hSuccess with ⟨rfl, rfl⟩
      exact ⟨hConfig, trivial⟩
  | fvar name =>
      simp [
        psKernelReduceInductiveRecFactoredWith,
        recSpine,
        hHead
      ] at hSuccess
      rcases hSuccess with ⟨rfl, rfl⟩
      exact ⟨hConfig, trivial⟩
  | mvar name =>
      simp [
        psKernelReduceInductiveRecFactoredWith,
        recSpine,
        hHead
      ] at hSuccess
      rcases hSuccess with ⟨rfl, rfl⟩
      exact ⟨hConfig, trivial⟩
  | sort level =>
      simp [
        psKernelReduceInductiveRecFactoredWith,
        recSpine,
        hHead
      ] at hSuccess
      rcases hSuccess with ⟨rfl, rfl⟩
      exact ⟨hConfig, trivial⟩
  | app fn arg =>
      simp [
        psKernelReduceInductiveRecFactoredWith,
        recSpine,
        hHead
      ] at hSuccess
      rcases hSuccess with ⟨rfl, rfl⟩
      exact ⟨hConfig, trivial⟩
  | lam name type body binderInfo =>
      simp [
        psKernelReduceInductiveRecFactoredWith,
        recSpine,
        hHead
      ] at hSuccess
      rcases hSuccess with ⟨rfl, rfl⟩
      exact ⟨hConfig, trivial⟩
  | forallE name type body binderInfo =>
      simp [
        psKernelReduceInductiveRecFactoredWith,
        recSpine,
        hHead
      ] at hSuccess
      rcases hSuccess with ⟨rfl, rfl⟩
      exact ⟨hConfig, trivial⟩
  | letE name type value body nondep =>
      simp [
        psKernelReduceInductiveRecFactoredWith,
        recSpine,
        hHead
      ] at hSuccess
      rcases hSuccess with ⟨rfl, rfl⟩
      exact ⟨hConfig, trivial⟩
  | lit literal =>
      simp [
        psKernelReduceInductiveRecFactoredWith,
        recSpine,
        hHead
      ] at hSuccess
      rcases hSuccess with ⟨rfl, rfl⟩
      exact ⟨hConfig, trivial⟩
  | mdata metadata body =>
      simp [
        psKernelReduceInductiveRecFactoredWith,
        recSpine,
        hHead
      ] at hSuccess
      rcases hSuccess with ⟨rfl, rfl⟩
      exact ⟨hConfig, trivial⟩
  | proj typeName index body =>
      simp [
        psKernelReduceInductiveRecFactoredWith,
        recSpine,
        hHead
      ] at hSuccess
      rcases hSuccess with ⟨rfl, rfl⟩
      exact ⟨hConfig, trivial⟩


theorem psKernelReduceInductiveRecWith_configuration_sound_of_components
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
    (hStructure :
      PsKernelRecursorStructureConversionConfigurationSound
        publicWhnf inferType) :
    PsKernelRecursorReductionConfigurationSound
      (psKernelReduceInductiveRecWith
        publicWhnf coreWhnf inferType defeq) := by
  intro
    context state nextState expr cheapRec cheapProj answer
    hConfig hSuccess
  have hFactored :
      psKernelReduceInductiveRecFactoredWith
          publicWhnf coreWhnf inferType defeq
          context state expr cheapRec cheapProj =
        Except.ok (Prod.mk answer nextState) := by
    rw [
      ← psKernelReduceInductiveRecWith_eq_factored
        publicWhnf coreWhnf inferType defeq
        context state expr cheapRec cheapProj
    ]
    exact hSuccess
  exact
    psKernelReduceInductiveRecFactoredWith_configuration_sound
      publicWhnf
      coreWhnf
      inferType
      defeq
      hWhnf
      hCore
      hK
      hStructure
      context
      state
      nextState
      expr
      cheapRec
      cheapProj
      answer
      hConfig
      hFactored



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
