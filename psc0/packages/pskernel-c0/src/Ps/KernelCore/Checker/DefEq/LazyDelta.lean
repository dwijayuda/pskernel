import Ps.KernelCore.Checker.DefEq.DeltaStep

/-
Lean 4.34 iterative lazy-delta and projection-sensitive definitional equality.

PSK-DEFEQ-DELTA

Algorithmic equality is intentionally incomplete and non-transitive, so the
order of reductions is observable. This module orchestrates repeated
single-step delta decisions with Nat/native reduction and projection-sensitive
comparison.

Single-step definition selection/unfold ordering lives in `DeltaStep.lean`.

Lean 4.34:
  src/kernel/type_checker.cpp::lazy_delta_reduction
  src/kernel/type_checker.cpp::lazy_delta_proj_reduction
-/

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
