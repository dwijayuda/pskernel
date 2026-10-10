import Ps.KernelCore.Checker.DefEq.Support
import Ps.KernelCore.Runtime.Acceleration.CachePolicy

/-
Lean 4.34 single-step lazy-delta selection and unfolding.

PSK-DEFEQ-DELTA

This module answers the local question:

  given two applications/definitions, which side should be unfolded next?

It contains definition lookup, reducibility-hint ordering, same-definition
argument checks, cached unfolding, and one-step lazy-delta decisions.

The observable multi-step orchestration, Nat/native fast paths, and
projection-sensitive loop live in `LazyDelta.lean`.

Lean 4.34:
  src/kernel/type_checker.cpp::lazy_delta_reduction
-/

def psKernelDeltaDefinition
    (context : PsKernelCheckerContext)
    (expr : PsKernelExpr) :
    Option PsKernelDefinitionInfo :=
  match psKernelExprGetAppFn expr with
  | PsKernelExpr.const name levels =>
      match
          psKernelEnvironmentFind
            context.environment
            name with
      | Option.some info =>
          match info with
          | PsKernelConstantInfo.defnInfo definition =>
              if
                  Nat.beq
                    (psKernelNameListLength
                      definition.base.levelParams)
                    (psKernelLevelListLength levels) then
                Option.some definition
              else
                Option.none
          | _ =>
              Option.none
      | Option.none =>
          Option.none
  | _ =>
      Option.none

def psKernelSameDeltaDefinition
    (left : PsKernelDefinitionInfo)
    (right : PsKernelDefinitionInfo) :
    Bool :=
  psKernelNameEq
    left.base.name
    right.base.name

def psKernelAppHeadLevelsEquivalent
    (left : PsKernelExpr)
    (right : PsKernelExpr) : Bool :=
  match psKernelExprGetAppFn left with
  | PsKernelExpr.const _ leftLevels =>
      match psKernelExprGetAppFn right with
      | PsKernelExpr.const _ rightLevels =>
          psKernelLevelListsEquivalent
            leftLevels
            rightLevels
      | _ =>
          false
  | _ =>
      false

def psKernelDefEqUnfold
    [cachePolicy : PsKernelSemanticCachePolicy]
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (expr : PsKernelExpr) :
    Prod (Option PsKernelExpr) PsKernelCheckerState :=
  let eligible :=
    psKernelSemanticCacheEligible expr;
  let cached :=
    if eligible then
      psKernelSemanticCacheGet
        state.unfold
        expr
    else
      Option.none;
  match cached with
  | Option.some cached =>
      Prod.mk
        (Option.some cached)
        state
  | Option.none =>
      match
          psKernelUnfoldDefinition
            context
            expr with
      | Option.none =>
          Prod.mk Option.none state
      | Option.some value =>
          if eligible then
            let cache :=
              psKernelSemanticCacheInsert
                state.unfold
                expr
                value;
            Prod.mk
              (Option.some value)
              (psKernelCheckerStateWithUnfold
                state
                cache)
          else
            Prod.mk
              (Option.some value)
              state

def psKernelDefEqDeltaOnce
    [cachePolicy : PsKernelSemanticCachePolicy]
    (coreWhnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Bool ->
      Bool ->
      Except String
        (Prod PsKernelExpr PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (expr : PsKernelExpr) :
    Except String
      (Prod PsKernelExpr PsKernelCheckerState) :=
  let unfolded :=
    psKernelDefEqUnfold
      context
      state
      expr;
  match Prod.fst unfolded with
  | Option.none =>
      Except.error
        "internal lazy-delta request for non-definition"
  | Option.some value =>
      coreWhnf
        context
        (Prod.snd unfolded)
        value
        false
        true

def psKernelDefEqTryUnfoldProjApp
    (coreWhnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Bool ->
      Bool ->
      Except String
        (Prod PsKernelExpr PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (expr : PsKernelExpr) :
    Except String
      (Prod
        (Option PsKernelExpr)
        PsKernelCheckerState) :=
  match psKernelExprGetAppFn expr with
  | PsKernelExpr.proj _ _ _ =>
      match
          coreWhnf
            context
            state
            expr
            false
            false with
      | Except.error error =>
          Except.error error
      | Except.ok result =>
          if
              psKernelExprEq
                (Prod.fst result)
                expr then
            Except.ok
              (Prod.mk
                Option.none
                (Prod.snd result))
          else
            Except.ok
              (Prod.mk
                (Option.some
                  (Prod.fst result))
                (Prod.snd result))
  | _ =>
      Except.ok
        (Prod.mk Option.none state)

def psKernelDefEqFinishLazyStep
    [cachePolicy : PsKernelSemanticCachePolicy]
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String
        (Prod Bool PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (left : PsKernelExpr)
    (right : PsKernelExpr) :
    Except String
      (Prod
        PsKernelDeltaStepResult
        PsKernelCheckerState) :=
  match
      psKernelDefEqQuick
        defeq
        context
        state
        left
        right with
  | Except.error error =>
      Except.error error
  | Except.ok quickResult =>
      match Prod.fst quickResult with
      | Option.some value =>
          if value then
            Except.ok
              (Prod.mk
                PsKernelDeltaStepResult.equal
                (Prod.snd quickResult))
          else
            Except.ok
              (Prod.mk
                (PsKernelDeltaStepResult.different
                  left
                  right)
                (Prod.snd quickResult))
      | Option.none =>
          Except.ok
            (Prod.mk
              (PsKernelDeltaStepResult.continue
                left
                right)
              (Prod.snd quickResult))

def psKernelDefEqLazyStepLeftOnly
    [cachePolicy : PsKernelSemanticCachePolicy]
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String
        (Prod Bool PsKernelCheckerState))
    (coreWhnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Bool ->
      Bool ->
      Except String
        (Prod PsKernelExpr PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (left : PsKernelExpr)
    (right : PsKernelExpr) :
    Except String
      (Prod PsKernelDeltaStepResult PsKernelCheckerState) :=
  match
      psKernelDefEqTryUnfoldProjApp
        coreWhnf
        context
        state
        right with
  | Except.error error =>
      Except.error error
  | Except.ok rightProj =>
      match Prod.fst rightProj with
      | Option.some rightValue =>
          psKernelDefEqFinishLazyStep
            defeq
            context
            (Prod.snd rightProj)
            left
            rightValue
      | Option.none =>
          match
              psKernelDefEqDeltaOnce
                coreWhnf
                context
                (Prod.snd rightProj)
                left with
          | Except.error error =>
              Except.error error
          | Except.ok leftResult =>
              psKernelDefEqFinishLazyStep
                defeq
                context
                (Prod.snd leftResult)
                (Prod.fst leftResult)
                right

def psKernelDefEqLazyStepRightOnly
    [cachePolicy : PsKernelSemanticCachePolicy]
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String
        (Prod Bool PsKernelCheckerState))
    (coreWhnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Bool ->
      Bool ->
      Except String
        (Prod PsKernelExpr PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (left : PsKernelExpr)
    (right : PsKernelExpr) :
    Except String
      (Prod PsKernelDeltaStepResult PsKernelCheckerState) :=
  match
      psKernelDefEqTryUnfoldProjApp
        coreWhnf
        context
        state
        left with
  | Except.error error =>
      Except.error error
  | Except.ok leftProj =>
      match Prod.fst leftProj with
      | Option.some leftValue =>
          psKernelDefEqFinishLazyStep
            defeq
            context
            (Prod.snd leftProj)
            leftValue
            right
      | Option.none =>
          match
              psKernelDefEqDeltaOnce
                coreWhnf
                context
                (Prod.snd leftProj)
                right with
          | Except.error error =>
              Except.error error
          | Except.ok rightResult =>
              psKernelDefEqFinishLazyStep
                defeq
                context
                (Prod.snd rightResult)
                left
                (Prod.fst rightResult)

def psKernelDefEqLazyStepBoth
    [cachePolicy : PsKernelSemanticCachePolicy]
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String
        (Prod Bool PsKernelCheckerState))
    (coreWhnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Bool ->
      Bool ->
      Except String
        (Prod PsKernelExpr PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (left : PsKernelExpr)
    (right : PsKernelExpr)
    (leftDef : PsKernelDefinitionInfo)
    (rightDef : PsKernelDefinitionInfo) :
    Except String
      (Prod PsKernelDeltaStepResult PsKernelCheckerState) :=
  if
      psKernelReducibilityHintsLt
        leftDef.hints
        rightDef.hints then
    match
        psKernelDefEqDeltaOnce
          coreWhnf
          context
          state
          left with
    | Except.error error =>
        Except.error error
    | Except.ok leftResult =>
        psKernelDefEqFinishLazyStep
          defeq
          context
          (Prod.snd leftResult)
          (Prod.fst leftResult)
          right
  else if
      psKernelReducibilityHintsLt
        rightDef.hints
        leftDef.hints then
    match
        psKernelDefEqDeltaOnce
          coreWhnf
          context
          state
          right with
    | Except.error error =>
        Except.error error
    | Except.ok rightResult =>
        psKernelDefEqFinishLazyStep
          defeq
          context
          (Prod.snd rightResult)
          left
          (Prod.fst rightResult)
  else
    let sameShortcut :=
      if
          if psKernelNatGt
              (psKernelExprGetAppNumArgs left)
              0 then
            psKernelNatGt
              (psKernelExprGetAppNumArgs right)
              0
          else
            false then
        if
            psKernelSameDeltaDefinition
              leftDef
              rightDef then
          if
              psKernelReducibilityHintsIsRegular
                leftDef.hints then
            psKernelAppHeadLevelsEquivalent
              left
              right
          else
            false
        else
          false
      else
        false;
    let argsResult :
        Except String
          (Prod Bool PsKernelCheckerState) :=
      if sameShortcut then
        if
            psKernelSemanticPairCacheEligible
              left
              right then
          if
              psKernelSemanticCacheContains
                state.failure
                left
                right then
            Except.ok
              (Prod.mk false state)
          else
            psKernelDefEqArgs
              defeq
              context
              state
              left
              right
        else
          psKernelDefEqArgs
            defeq
            context
            state
            left
            right
      else
        Except.ok
          (Prod.mk false state);
    match argsResult with
    | Except.error error =>
        Except.error error
    | Except.ok compared =>
        if
            if sameShortcut then
              Prod.fst compared
            else
              false then
          Except.ok
            (Prod.mk
              PsKernelDeltaStepResult.equal
              (Prod.snd compared))
        else
          let comparedState :=
            Prod.snd compared;
          let afterFailure :=
            if sameShortcut then
              if
                  psKernelSemanticPairCacheEligible
                    left
                    right then
                psKernelCheckerStateWithFailure
                  comparedState
                  (psKernelSemanticCacheInsertPair
                    comparedState.failure
                    left
                    right)
              else
                comparedState
            else
              comparedState;
          match
              psKernelDefEqDeltaOnce
                coreWhnf
                context
                afterFailure
                left with
          | Except.error error =>
              Except.error error
          | Except.ok leftResult =>
              match
                  psKernelDefEqDeltaOnce
                    coreWhnf
                    context
                    (Prod.snd leftResult)
                    right with
              | Except.error error =>
                  Except.error error
              | Except.ok rightResult =>
                  psKernelDefEqFinishLazyStep
                    defeq
                    context
                    (Prod.snd rightResult)
                    (Prod.fst leftResult)
                    (Prod.fst rightResult)

def psKernelDefEqLazyStep
    [cachePolicy : PsKernelSemanticCachePolicy]
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String
        (Prod Bool PsKernelCheckerState))
    (coreWhnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Bool ->
      Bool ->
      Except String
        (Prod PsKernelExpr PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (left : PsKernelExpr)
    (right : PsKernelExpr) :
    Except String
      (Prod PsKernelDeltaStepResult PsKernelCheckerState) :=
  let leftDefinition :=
    psKernelDeltaDefinition context left;
  let rightDefinition :=
    psKernelDeltaDefinition context right;
  match leftDefinition with
  | Option.none =>
      match rightDefinition with
      | Option.none =>
          Except.ok
            (Prod.mk
              (PsKernelDeltaStepResult.unknown
                left
                right)
              state)
      | Option.some _ =>
          psKernelDefEqLazyStepRightOnly
            defeq
            coreWhnf
            context
            state
            left
            right
  | Option.some leftDef =>
      match rightDefinition with
      | Option.none =>
          psKernelDefEqLazyStepLeftOnly
            defeq
            coreWhnf
            context
            state
            left
            right
      | Option.some rightDef =>
          psKernelDefEqLazyStepBoth
            defeq
            coreWhnf
            context
            state
            left
            right
            leftDef
            rightDef

