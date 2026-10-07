import Ps.KernelCore.Checker.Recursor.Reduction
import Ps.KernelCore.Metatheory.CheckerContracts
import Ps.KernelCore.Metatheory.QuotReduction

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
