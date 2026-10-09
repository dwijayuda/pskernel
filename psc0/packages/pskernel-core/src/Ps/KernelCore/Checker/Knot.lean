import Ps.KernelCore.Checker.Ops
import Ps.KernelCore.Checker.DefEq.FullShape

/-
Single owner of cross-component checker recursion.

The existing curried fuel workers are preserved verbatim: recursor callbacks use
remaining fuel; the defeq continuation uses its own remaining fuel; the projection
shortcut retains its expression-derived budget. Exhaustion still rejects.
The inference-only and fully checked entry points remain distinct.
-/

def psKernelReduceRecursorBoundedWithFuel
    (fuel : Nat) :
    (PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String
        (Prod Bool PsKernelCheckerState)) ->
    PsKernelCheckerContext ->
    PsKernelCheckerState ->
    PsKernelExpr ->
    Bool ->
    Bool ->
    Except String
      (Prod
        (Option PsKernelExpr)
        PsKernelCheckerState) :=
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
        (_context : PsKernelCheckerContext)
        (_state : PsKernelCheckerState)
        (_expr : PsKernelExpr)
        (_cheapRec : Bool)
        (_cheapProj : Bool) =>
        Except.error
          "kernel recursor budget exhausted"
  | Nat.succ remaining =>
      let nextReducer :=
        psKernelReduceRecursorBoundedWithFuel remaining;
      fun
        (defeq :
          PsKernelCheckerContext ->
          PsKernelCheckerState ->
          PsKernelExpr ->
          PsKernelExpr ->
          Except String
            (Prod Bool PsKernelCheckerState))
        (context : PsKernelCheckerContext)
        (state : PsKernelCheckerState)
        (expr : PsKernelExpr)
        (cheapRec : Bool)
        (cheapProj : Bool) =>
        let reducer :=
          fun
            (nextContext : PsKernelCheckerContext)
            (nextState : PsKernelCheckerState)
            (nextExpr : PsKernelExpr)
            (nextCheapRec : Bool)
            (nextCheapProj : Bool) =>
            nextReducer
              defeq
              nextContext
              nextState
              nextExpr
              nextCheapRec
              nextCheapProj;
        let publicWhnf :=
          fun
            (nextContext : PsKernelCheckerContext)
            (nextState : PsKernelCheckerState)
            (nextExpr : PsKernelExpr) =>
            psKernelWhnfWithFuel
              remaining
              reducer
              nextContext
              nextState
              nextExpr;
        let coreWhnf :=
          fun
            (nextContext : PsKernelCheckerContext)
            (nextState : PsKernelCheckerState)
            (nextExpr : PsKernelExpr)
            (nextCheapRec : Bool)
            (nextCheapProj : Bool) =>
            psKernelWhnfCoreWithFuel
              remaining
              publicWhnf
              reducer
              nextContext
              nextState
              nextExpr
              nextCheapRec
              nextCheapProj;
        let inferType :=
          fun
            (nextContext : PsKernelCheckerContext)
            (nextState : PsKernelCheckerState)
            (nextExpr : PsKernelExpr) =>
            psKernelInferWithFuel
              remaining
              publicWhnf
              defeq
              nextContext
              nextState
              nextExpr;
        psKernelReduceRecursorWith
          publicWhnf
          coreWhnf
          inferType
          defeq
          context
          state
          expr
          cheapRec
          cheapProj

def psKernelWhnfWithRecursorFuel
    (fuel : Nat)
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String
        (Prod Bool PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (expr : PsKernelExpr) :
    Except String
      (Prod PsKernelExpr PsKernelCheckerState) :=
  psKernelWhnfWithFuel
    fuel
    (psKernelReduceRecursorBoundedWithFuel
      fuel
      defeq)
    context
    state
    expr

def psKernelWhnfCoreWithRecursorFuel
    (fuel : Nat)
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String
        (Prod Bool PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (expr : PsKernelExpr)
    (cheapRec : Bool)
    (cheapProj : Bool) :
    Except String
      (Prod PsKernelExpr PsKernelCheckerState) :=
  let reducer :=
    psKernelReduceRecursorBoundedWithFuel
      fuel
      defeq;
  psKernelWhnfCoreWithFuel
    fuel
    (psKernelWhnfWithRecursorFuel
      fuel
      defeq)
    reducer
    context
    state
    expr
    cheapRec
    cheapProj

def psKernelInferWithRecursorFuel
    (fuel : Nat)
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String
        (Prod Bool PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (expr : PsKernelExpr) :
    Except String
      (Prod PsKernelExpr PsKernelCheckerState) :=
  psKernelInferWithFuel
    fuel
    (psKernelWhnfWithRecursorFuel
      fuel
      defeq)
    defeq
    context
    state
    expr

def psKernelDefEqProjectionShortcut
    (fuel : Nat)
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
        (Option Bool)
        PsKernelCheckerState) :=
  match left with
  | PsKernelExpr.const leftName leftLevels =>
      match right with
      | PsKernelExpr.const rightName rightLevels =>
          if
              if psKernelNameEq leftName rightName then
                psKernelLevelListsEquivalent
                  leftLevels
                  rightLevels
              else
                false then
            Except.ok
              (Prod.mk
                (Option.some true)
                state)
          else
            Except.ok
              (Prod.mk Option.none state)
      | _ =>
          Except.ok
            (Prod.mk Option.none state)
  | PsKernelExpr.fvar leftName =>
      match right with
      | PsKernelExpr.fvar rightName =>
          if psKernelNameEq leftName rightName then
            Except.ok
              (Prod.mk
                (Option.some true)
                state)
          else
            Except.ok
              (Prod.mk Option.none state)
      | _ =>
          Except.ok
            (Prod.mk Option.none state)
  | PsKernelExpr.proj leftName leftIndex leftExpr =>
      match right with
      | PsKernelExpr.proj rightName rightIndex rightExpr =>
          if
              if psKernelNameEq leftName rightName then
                Nat.beq leftIndex rightIndex
              else
                false then
            match
                psKernelDefEqLazyProjReductionWithFuel
                  fuel
                  defeq
                  (psKernelWhnfCoreWithRecursorFuel
                    fuel
                    defeq)
                  context
                  state
                  leftExpr
                  rightExpr
                  leftName
                  leftIndex with
            | Except.error error =>
                Except.error error
            | Except.ok result =>
                if Prod.fst result then
                  Except.ok
                    (Prod.mk
                      (Option.some true)
                      (Prod.snd result))
                else
                  Except.ok
                    (Prod.mk
                      Option.none
                      (Prod.snd result))
          else
            Except.ok
              (Prod.mk Option.none state)
      | _ =>
          Except.ok
            (Prod.mk Option.none state)
  | _ =>
      Except.ok
        (Prod.mk Option.none state)

def psKernelIsDefEqWithFuel
    (fuel : Nat) :
    PsKernelCheckerContext ->
    PsKernelCheckerState ->
    PsKernelExpr ->
    PsKernelExpr ->
    Except String
      (Prod Bool PsKernelCheckerState) :=
  match fuel with
  | Nat.zero =>
      fun
        (_context : PsKernelCheckerContext)
        (_state : PsKernelCheckerState)
        (_left : PsKernelExpr)
        (_right : PsKernelExpr) =>
        Except.error
          "kernel definitional equality budget exhausted"
  | Nat.succ remaining =>
      let defeq :
          PsKernelCheckerContext ->
          PsKernelCheckerState ->
          PsKernelExpr ->
          PsKernelExpr ->
          Except String
            (Prod Bool PsKernelCheckerState) :=
        psKernelIsDefEqWithFuel remaining;
      fun
        (context : PsKernelCheckerContext)
        (state : PsKernelCheckerState)
        (left : PsKernelExpr)
        (right : PsKernelExpr) =>
        match
            psKernelCheckerContextEnterRecDepth
              context with
        | Except.error error =>
            Except.error error
        | Except.ok nextContext =>
            if psKernelExprEq left right then
              Except.ok
                (psKernelDefEqFinish
                  state
                  left
                  right
                  true)
            else if
                psKernelExprPairSetContains
                  state.success
                  left
                  right then
              Except.ok
                (Prod.mk true state)
            else
              let whnf :=
                psKernelWhnfWithRecursorFuel
                  remaining
                  defeq;
              let coreWhnf :=
                psKernelWhnfCoreWithRecursorFuel
                  remaining
                  defeq;
              let inferType :=
                psKernelInferWithRecursorFuel
                  remaining
                  defeq;
              match
                  psKernelDefEqQuick
                    defeq
                    nextContext
                    state
                    left
                    right with
              | Except.error error =>
                  Except.error error
              | Except.ok quickResult =>
                  match Prod.fst quickResult with
                  | Option.some value =>
                      Except.ok
                        (psKernelDefEqFinish
                          (Prod.snd quickResult)
                          left
                          right
                          value)
                  | Option.none =>
                      match
                          psKernelDefEqReflectionWith
                            whnf
                            nextContext
                            (Prod.snd quickResult)
                            left
                            right with
                      | Except.error error =>
                          Except.error error
                      | Except.ok reflectionResult =>
                          match Prod.fst reflectionResult with
                          | Option.some value =>
                              Except.ok
                                (psKernelDefEqFinish
                                  (Prod.snd reflectionResult)
                                  left
                                  right
                                  value)
                          | Option.none =>
                              match
                                  coreWhnf
                                    nextContext
                                    (Prod.snd reflectionResult)
                                    left
                                    false
                                    true with
                              | Except.error error =>
                                  Except.error error
                              | Except.ok leftCoreResult =>
                                  match
                                      coreWhnf
                                        nextContext
                                        (Prod.snd leftCoreResult)
                                        right
                                        false
                                        true with
                                  | Except.error error =>
                                      Except.error error
                                  | Except.ok rightCoreResult =>
                                      let leftCore :=
                                        Prod.fst leftCoreResult;
                                      let rightCore :=
                                        Prod.fst rightCoreResult;
                                      match
                                          psKernelDefEqQuick
                                            defeq
                                            nextContext
                                            (Prod.snd rightCoreResult)
                                            leftCore
                                            rightCore with
                                      | Except.error error =>
                                          Except.error error
                                      | Except.ok coreQuick =>
                                          match Prod.fst coreQuick with
                                          | Option.some value =>
                                              Except.ok
                                                (psKernelDefEqFinish
                                                  (Prod.snd coreQuick)
                                                  left
                                                  right
                                                  value)
                                          | Option.none =>
                                              match
                                                  inferType
                                                    nextContext
                                                    (Prod.snd coreQuick)
                                                    leftCore with
                                              | Except.error error =>
                                                  Except.error error
                                              | Except.ok leftTypeResult =>
                                                  match
                                                      psKernelDefEqIsPropWith
                                                        inferType
                                                        whnf
                                                        nextContext
                                                        (Prod.snd leftTypeResult)
                                                        (Prod.fst leftTypeResult) with
                                                  | Except.error error =>
                                                      Except.error error
                                                  | Except.ok proofResult =>
                                                      if Prod.fst proofResult then
                                                        match
                                                            inferType
                                                              nextContext
                                                              (Prod.snd proofResult)
                                                              rightCore with
                                                        | Except.error error =>
                                                            Except.error error
                                                        | Except.ok rightTypeResult =>
                                                            match
                                                                defeq
                                                                  nextContext
                                                                  (Prod.snd rightTypeResult)
                                                                  (Prod.fst leftTypeResult)
                                                                  (Prod.fst rightTypeResult) with
                                                            | Except.error error =>
                                                                Except.error error
                                                            | Except.ok proofEqual =>
                                                                Except.ok
                                                                  (psKernelDefEqFinish
                                                                    (Prod.snd proofEqual)
                                                                    left
                                                                    right
                                                                    (Prod.fst proofEqual))
                                                      else
                                                        match
                                                            psKernelDefEqLazyReductionWithFuel
                                                              remaining
                                                              defeq
                                                              whnf
                                                              coreWhnf
                                                              nextContext
                                                              (Prod.snd proofResult)
                                                              leftCore
                                                              rightCore with
                                                        | Except.error error =>
                                                            Except.error error
                                                        | Except.ok deltaResult =>
                                                            match Prod.fst deltaResult with
                                                            | PsKernelDeltaResult.decided value =>
                                                                Except.ok
                                                                  (psKernelDefEqFinish
                                                                    (Prod.snd deltaResult)
                                                                    left
                                                                    right
                                                                    value)
                                                            | PsKernelDeltaResult.residual leftDelta rightDelta =>
                                                                match
                                                                    psKernelDefEqProjectionShortcut
                                                                      remaining
                                                                      defeq
                                                                      nextContext
                                                                      (Prod.snd deltaResult)
                                                                      leftDelta
                                                                      rightDelta with
                                                                | Except.error error =>
                                                                    Except.error error
                                                                | Except.ok shortcutResult =>
                                                                    match Prod.fst shortcutResult with
                                                                    | Option.some value =>
                                                                        Except.ok
                                                                          (psKernelDefEqFinish
                                                                            (Prod.snd shortcutResult)
                                                                            left
                                                                            right
                                                                            value)
                                                                    | Option.none =>
                                                                        match
                                                                            coreWhnf
                                                                              nextContext
                                                                              (Prod.snd shortcutResult)
                                                                              leftDelta
                                                                              false
                                                                              false with
                                                                        | Except.error error =>
                                                                            Except.error error
                                                                        | Except.ok leftFullResult =>
                                                                            match
                                                                                coreWhnf
                                                                                  nextContext
                                                                                  (Prod.snd leftFullResult)
                                                                                  rightDelta
                                                                                  false
                                                                                  false with
                                                                            | Except.error error =>
                                                                                Except.error error
                                                                            | Except.ok rightFullResult =>
                                                                                let leftFull :=
                                                                                  Prod.fst leftFullResult;
                                                                                let rightFull :=
                                                                                  Prod.fst rightFullResult;
                                                                                let changed :=
                                                                                  if
                                                                                      psKernelExprEq
                                                                                        leftFull
                                                                                        leftDelta then
                                                                                    if
                                                                                        psKernelExprEq
                                                                                          rightFull
                                                                                          rightDelta then
                                                                                      false
                                                                                    else
                                                                                      true
                                                                                  else
                                                                                    true;
                                                                                if changed then
                                                                                  match
                                                                                      defeq
                                                                                        nextContext
                                                                                        (Prod.snd rightFullResult)
                                                                                        leftFull
                                                                                        rightFull with
                                                                                  | Except.error error =>
                                                                                      Except.error error
                                                                                  | Except.ok changedResult =>
                                                                                      Except.ok
                                                                                        (psKernelDefEqFinish
                                                                                          (Prod.snd changedResult)
                                                                                          left
                                                                                          right
                                                                                          (Prod.fst changedResult))
                                                                                else
                                                                                  match
                                                                                      psKernelDefEqFullShapeWith
                                                                                        defeq
                                                                                        inferType
                                                                                        whnf
                                                                                        nextContext
                                                                                        (Prod.snd rightFullResult)
                                                                                        leftFull
                                                                                        rightFull with
                                                                                  | Except.error error =>
                                                                                      Except.error error
                                                                                  | Except.ok shapeResult =>
                                                                                      match Prod.fst shapeResult with
                                                                                      | Option.some value =>
                                                                                          Except.ok
                                                                                            (psKernelDefEqFinish
                                                                                              (Prod.snd shapeResult)
                                                                                              left
                                                                                              right
                                                                                              value)
                                                                                      | Option.none =>
                                                                                          psKernelIsDefEqAfterFullShape
                                                                                            defeq
                                                                                            inferType
                                                                                            whnf
                                                                                            nextContext
                                                                                            (Prod.snd shapeResult)
                                                                                            left
                                                                                            right
                                                                                            leftFull
                                                                                            rightFull

def psKernelIsDefEq
    (fuel : Nat)
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (left : PsKernelExpr)
    (right : PsKernelExpr) :
    Except String
      (Prod Bool PsKernelCheckerState) :=
  psKernelIsDefEqWithFuel
    fuel
    context
    state
    left
    right


/- Concrete operations let Session avoid allocating an entire callback record
on each cache hit. They share the same fuel wiring as the Ops constructor. -/
def psKernelCheckerWhnf
    (fuel : Nat)
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (expr : PsKernelExpr) :
    Except String (Prod PsKernelExpr PsKernelCheckerState) :=
  let defeq := psKernelIsDefEqWithFuel fuel;
  psKernelWhnfWithRecursorFuel fuel defeq context state expr

def psKernelCheckerInfer
    (fuel : Nat)
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (expr : PsKernelExpr) :
    Except String (Prod PsKernelExpr PsKernelCheckerState) :=
  let defeq := psKernelIsDefEqWithFuel fuel;
  psKernelInferWithRecursorFuel fuel defeq context state expr

def psKernelCheckerCheck
    (fuel : Nat)
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (expr : PsKernelExpr) :
    Except String (Prod PsKernelExpr PsKernelCheckerState) :=
  let defeq := psKernelIsDefEqWithFuel fuel;
  let whnf := psKernelWhnfWithRecursorFuel fuel defeq;
  psKernelCheckWithFuel fuel whnf defeq context state expr

def psKernelCheckerOpsWithFuel
    (fuel : Nat) : PsKernelCheckerOps :=
  let defeq := psKernelIsDefEqWithFuel fuel;
  {
    infer := psKernelCheckerInfer fuel
    check := psKernelCheckerCheck fuel
    whnfCore := psKernelWhnfCoreWithRecursorFuel fuel defeq
    whnf := psKernelCheckerWhnf fuel
    defeq := defeq
    reduceRecursor := psKernelReduceRecursorBoundedWithFuel fuel defeq
  }
