import Ps.KernelSelfHost.Theory.DefEq.FullShape

/-
Lean 4.34 algorithmic definitional equality orchestration.

Read this file top-to-bottom for the observable kernel order:
quick equality -> reflection -> cheap WHNF -> proof irrelevance ->
lazy delta -> projection shortcut -> full WHNF -> full-shape rules ->
terminal eta/literal/unit-like rules.

Supporting rule implementations live under Theory/DefEq.
-/

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
