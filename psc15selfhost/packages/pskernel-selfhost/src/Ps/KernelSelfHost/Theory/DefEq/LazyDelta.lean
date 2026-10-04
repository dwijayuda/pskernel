import Ps.KernelSelfHost.TypeCheckerDefEqSupport

/-
Lean 4.34 lazy delta and projection-sensitive definitional equality.

PSK-DEFEQ-DELTA

Algorithmic equality is intentionally incomplete and non-transitive, so the
order of unfolding is part of compatibility. This module keeps definition
selection, reducibility-hint ordering, same-head argument comparison,
Nat/native fast reductions, and projection-sensitive lazy reduction together.

Lean 4.34:
  src/kernel/type_checker.cpp::lazy_delta_reduction
  src/kernel/type_checker.cpp::lazy_delta_proj_reduction
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
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (expr : PsKernelExpr) :
    Prod (Option PsKernelExpr) PsKernelCheckerState :=
  match
      psKernelExprMapGet
        state.unfold
        expr with
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
          let cache :=
            psKernelExprMapInsert
              state.unfold
              expr
              value;
          Prod.mk
            (Option.some value)
            (psKernelCheckerStateWithUnfold
              state
              cache)

def psKernelDefEqDeltaOnce
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
            psKernelExprPairSetContains
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
              psKernelCheckerStateWithFailure
                comparedState
                (psKernelExprPairSetInsert
                  comparedState.failure
                  left
                  right)
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

def psKernelDefEqNativeThenLazyStep
    (resume :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String
        (Prod PsKernelDeltaResult PsKernelCheckerState))
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
      (Prod PsKernelDeltaResult PsKernelCheckerState) :=
  match psKernelReduceNative context left with
  | Except.error error =>
      Except.error error
  | Except.ok leftNative =>
      match leftNative with
      | Option.some value =>
          match
              defeq
                context
                state
                value
                right with
          | Except.error error =>
              Except.error error
          | Except.ok result =>
              Except.ok
                (Prod.mk
                  (PsKernelDeltaResult.decided
                    (Prod.fst result))
                  (Prod.snd result))
      | Option.none =>
          match psKernelReduceNative context right with
          | Except.error error =>
              Except.error error
          | Except.ok rightNative =>
              match rightNative with
              | Option.some value =>
                  match
                      defeq
                        context
                        state
                        left
                        value with
                  | Except.error error =>
                      Except.error error
                  | Except.ok result =>
                      Except.ok
                        (Prod.mk
                          (PsKernelDeltaResult.decided
                            (Prod.fst result))
                          (Prod.snd result))
              | Option.none =>
                  match
                      psKernelDefEqLazyStep
                        defeq
                        coreWhnf
                        context
                        state
                        left
                        right with
                  | Except.error error =>
                      Except.error error
                  | Except.ok stepResult =>
                      match Prod.fst stepResult with
                      | PsKernelDeltaStepResult.continue nextLeft nextRight =>
                          resume
                            context
                            (Prod.snd stepResult)
                            nextLeft
                            nextRight
                      | PsKernelDeltaStepResult.unknown nextLeft nextRight =>
                          Except.ok
                            (Prod.mk
                              (PsKernelDeltaResult.residual
                                nextLeft
                                nextRight)
                              (Prod.snd stepResult))
                      | PsKernelDeltaStepResult.equal =>
                          Except.ok
                            (Prod.mk
                              (PsKernelDeltaResult.decided true)
                              (Prod.snd stepResult))
                      | PsKernelDeltaStepResult.different _ _ =>
                          Except.ok
                            (Prod.mk
                              (PsKernelDeltaResult.decided false)
                              (Prod.snd stepResult))

def psKernelDefEqLazyReductionAfterPred
    (resume :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String
        (Prod PsKernelDeltaResult PsKernelCheckerState))
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String
        (Prod Bool PsKernelCheckerState))
    (whnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String
        (Prod PsKernelExpr PsKernelCheckerState))
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
      (Prod PsKernelDeltaResult PsKernelCheckerState) :=
  let eager :=
    if context.eagerReduce then
      true
    else if psKernelExprHasFVar left then
      false
    else if psKernelExprHasFVar right then
      false
    else
      true;
  let leftNat :
      Except String
        (Prod
          (Option PsKernelExpr)
          PsKernelCheckerState) :=
    if eager then
      psKernelReduceNatWith
        whnf
        context
        state
        left
    else
      Except.ok
        (Prod.mk Option.none state);
  match leftNat with
  | Except.error error =>
      Except.error error
  | Except.ok leftNatResult =>
      match Prod.fst leftNatResult with
      | Option.some value =>
          match
              defeq
                context
                (Prod.snd leftNatResult)
                value
                right with
          | Except.error error =>
              Except.error error
          | Except.ok result =>
              Except.ok
                (Prod.mk
                  (PsKernelDeltaResult.decided
                    (Prod.fst result))
                  (Prod.snd result))
      | Option.none =>
          let rightNat :
              Except String
                (Prod
                  (Option PsKernelExpr)
                  PsKernelCheckerState) :=
            if eager then
              psKernelReduceNatWith
                whnf
                context
                (Prod.snd leftNatResult)
                right
            else
              Except.ok
                (Prod.mk
                  Option.none
                  (Prod.snd leftNatResult));
          match rightNat with
          | Except.error error =>
              Except.error error
          | Except.ok rightNatResult =>
              match Prod.fst rightNatResult with
              | Option.some value =>
                  match
                      defeq
                        context
                        (Prod.snd rightNatResult)
                        left
                        value with
                  | Except.error error =>
                      Except.error error
                  | Except.ok result =>
                      Except.ok
                        (Prod.mk
                          (PsKernelDeltaResult.decided
                            (Prod.fst result))
                          (Prod.snd result))
              | Option.none =>
                  psKernelDefEqNativeThenLazyStep
                    resume
                    defeq
                    coreWhnf
                    context
                    (Prod.snd rightNatResult)
                    left
                    right

def psKernelDefEqLazyReductionWithFuel
    (fuel : Nat) :
    (PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String
        (Prod Bool PsKernelCheckerState)) ->
    (PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String
        (Prod PsKernelExpr PsKernelCheckerState)) ->
    (PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Bool ->
      Bool ->
      Except String
        (Prod PsKernelExpr PsKernelCheckerState)) ->
    PsKernelCheckerContext ->
    PsKernelCheckerState ->
    PsKernelExpr ->
    PsKernelExpr ->
    Except String
      (Prod PsKernelDeltaResult PsKernelCheckerState) :=
  match fuel with
  | Nat.zero =>
      fun
        (_defeq :
          PsKernelCheckerContext ->
          PsKernelCheckerState ->
          PsKernelExpr ->
          PsKernelExpr ->
          Except String
            (Prod Bool PsKernelCheckerState))
        (_whnf :
          PsKernelCheckerContext ->
          PsKernelCheckerState ->
          PsKernelExpr ->
          Except String
            (Prod PsKernelExpr PsKernelCheckerState))
        (_coreWhnf :
          PsKernelCheckerContext ->
          PsKernelCheckerState ->
          PsKernelExpr ->
          Bool ->
          Bool ->
          Except String
            (Prod PsKernelExpr PsKernelCheckerState))
        (_context : PsKernelCheckerContext)
        (_state : PsKernelCheckerState)
        (_left : PsKernelExpr)
        (_right : PsKernelExpr) =>
        Except.error
          "kernel lazy-delta budget exhausted"
  | Nat.succ remaining =>
      let smaller :=
        psKernelDefEqLazyReductionWithFuel remaining;
      fun
        (defeq :
          PsKernelCheckerContext ->
          PsKernelCheckerState ->
          PsKernelExpr ->
          PsKernelExpr ->
          Except String
            (Prod Bool PsKernelCheckerState))
        (whnf :
          PsKernelCheckerContext ->
          PsKernelCheckerState ->
          PsKernelExpr ->
          Except String
            (Prod PsKernelExpr PsKernelCheckerState))
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
        (right : PsKernelExpr) =>
        if
            if psKernelExprIsNatZero left then
              psKernelExprIsNatZero right
            else
              false then
          Except.ok
            (Prod.mk
              (PsKernelDeltaResult.decided true)
              state)
        else
          let resume :
              PsKernelCheckerContext ->
              PsKernelCheckerState ->
              PsKernelExpr ->
              PsKernelExpr ->
              Except String
                (Prod
                  PsKernelDeltaResult
                  PsKernelCheckerState) :=
            smaller defeq whnf coreWhnf;
          match psKernelExprNatPred left with
          | Option.some leftPred =>
              match psKernelExprNatPred right with
              | Option.some rightPred =>
                  match
                      defeq
                        context
                        state
                        leftPred
                        rightPred with
                  | Except.error error =>
                      Except.error error
                  | Except.ok result =>
                      Except.ok
                        (Prod.mk
                          (PsKernelDeltaResult.decided
                            (Prod.fst result))
                          (Prod.snd result))
              | Option.none =>
                  psKernelDefEqLazyReductionAfterPred
                    resume
                    defeq
                    whnf
                    coreWhnf
                    context
                    state
                    left
                    right
          | Option.none =>
              psKernelDefEqLazyReductionAfterPred
                resume
                defeq
                whnf
                coreWhnf
                context
                state
                left
                right

def psKernelDefEqLazyProjFinish
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
    (right : PsKernelExpr)
    (typeName : PsKernelName)
    (index : Nat) :
    Except String
      (Prod Bool PsKernelCheckerState) :=
  let leftField :=
    psKernelReduceProjCore
      context
      typeName
      index
      left;
  let rightField :=
    psKernelReduceProjCore
      context
      typeName
      index
      right;
  match leftField with
  | Option.some leftValue =>
      match rightField with
      | Option.some rightValue =>
          defeq
            context
            state
            leftValue
            rightValue
      | Option.none =>
          defeq
            context
            state
            left
            right
  | Option.none =>
      defeq
        context
        state
        left
        right

def psKernelDefEqLazyProjReductionWithFuel
    (fuel : Nat) :
    (PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String
        (Prod Bool PsKernelCheckerState)) ->
    (PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Bool ->
      Bool ->
      Except String
        (Prod PsKernelExpr PsKernelCheckerState)) ->
    PsKernelCheckerContext ->
    PsKernelCheckerState ->
    PsKernelExpr ->
    PsKernelExpr ->
    PsKernelName ->
    Nat ->
    Except String
      (Prod Bool PsKernelCheckerState) :=
  match fuel with
  | Nat.zero =>
      fun
        (_defeq :
          PsKernelCheckerContext ->
          PsKernelCheckerState ->
          PsKernelExpr ->
          PsKernelExpr ->
          Except String
            (Prod Bool PsKernelCheckerState))
        (_coreWhnf :
          PsKernelCheckerContext ->
          PsKernelCheckerState ->
          PsKernelExpr ->
          Bool ->
          Bool ->
          Except String
            (Prod PsKernelExpr PsKernelCheckerState))
        (_context : PsKernelCheckerContext)
        (_state : PsKernelCheckerState)
        (_left : PsKernelExpr)
        (_right : PsKernelExpr)
        (_typeName : PsKernelName)
        (_index : Nat) =>
        Except.error
          "kernel lazy-projection budget exhausted"
  | Nat.succ remaining =>
      let smaller :=
        psKernelDefEqLazyProjReductionWithFuel remaining;
      fun
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
        (typeName : PsKernelName)
        (index : Nat) =>
        match
            psKernelDefEqLazyStep
              defeq
              coreWhnf
              context
              state
              left
              right with
        | Except.error error =>
            Except.error error
        | Except.ok stepResult =>
            match Prod.fst stepResult with
            | PsKernelDeltaStepResult.continue nextLeft nextRight =>
                smaller
                  defeq
                  coreWhnf
                  context
                  (Prod.snd stepResult)
                  nextLeft
                  nextRight
                  typeName
                  index
            | PsKernelDeltaStepResult.equal =>
                Except.ok
                  (Prod.mk
                    true
                    (Prod.snd stepResult))
            | PsKernelDeltaStepResult.unknown nextLeft nextRight =>
                psKernelDefEqLazyProjFinish
                  defeq
                  context
                  (Prod.snd stepResult)
                  nextLeft
                  nextRight
                  typeName
                  index
            | PsKernelDeltaStepResult.different nextLeft nextRight =>
                psKernelDefEqLazyProjFinish
                  defeq
                  context
                  (Prod.snd stepResult)
                  nextLeft
                  nextRight
                  typeName
                  index
