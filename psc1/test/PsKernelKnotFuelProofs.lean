import Ps.KernelCore.Checker.Knot

/-!
Exact extensional equivalence of delayed recursive aliases for every fuel,
callback, context, state and input. Each frozen worker is copied verbatim from
854bdb9e0febf4e01fb5ce4b2cc8ea91f61287e4 with only its own recursive name changed.
Both sides use the same imported helper definitions. These are local replacement
theorems; they do not assert a global kernel soundness theorem or a runtime
allocation bound. The frozen workers remain outside the portable source closure.
-/
namespace PsKernelKnotFuelProofs

def beforeReduceRecursorBoundedWithFuel
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
        beforeReduceRecursorBoundedWithFuel remaining;
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


def beforeIsDefEqWithFuel
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
        beforeIsDefEqWithFuel remaining;
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
                    right
                    true with
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
                                            rightCore
                                            false with
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


def beforeWhnfWithFuel
    (fuel : Nat) :
    (PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Bool ->
      Bool ->
      Except String
        (Prod
          (Option PsKernelExpr)
          PsKernelCheckerState)) ->
    PsKernelCheckerContext ->
    PsKernelCheckerState ->
    PsKernelExpr ->
    Except String
      (Prod PsKernelExpr PsKernelCheckerState) :=
  match fuel with
  | Nat.zero =>
      fun
        (_reduceRecursor :
          PsKernelCheckerContext ->
          PsKernelCheckerState ->
          PsKernelExpr ->
          Bool ->
          Bool ->
          Except String
            (Prod
              (Option PsKernelExpr)
              PsKernelCheckerState))
        (_context : PsKernelCheckerContext)
        (_state : PsKernelCheckerState)
        (_expr : PsKernelExpr) =>
        Except.error
          "kernel reduction budget exhausted"
  | Nat.succ remaining =>
      let smaller :=
        beforeWhnfWithFuel remaining;
      fun
        (reduceRecursor :
          PsKernelCheckerContext ->
          PsKernelCheckerState ->
          PsKernelExpr ->
          Bool ->
          Bool ->
          Except String
            (Prod
              (Option PsKernelExpr)
              PsKernelCheckerState))
        (context : PsKernelCheckerContext)
        (state : PsKernelCheckerState)
        (expr : PsKernelExpr) =>
        match expr with
        | PsKernelExpr.bvar _ =>
            Except.ok (Prod.mk expr state)
        | PsKernelExpr.sort _ =>
            Except.ok (Prod.mk expr state)
        | PsKernelExpr.mvar _ =>
            Except.ok (Prod.mk expr state)
        | PsKernelExpr.forallE _ _ _ _ =>
            Except.ok (Prod.mk expr state)
        | PsKernelExpr.lit _ =>
            Except.ok (Prod.mk expr state)
        | PsKernelExpr.mdata _ body =>
            smaller
              reduceRecursor
              context
              state
              body
        | PsKernelExpr.fvar name =>
            match
                psKernelLocalContextFind
                  context.localContext
                  name with
            | Option.none =>
                Except.ok (Prod.mk expr state)
            | Option.some declaration =>
                match
                    psKernelLocalDeclValue
                      declaration with
                | Option.none =>
                    Except.ok (Prod.mk expr state)
                | Option.some _ =>
                    match
                        if psKernelSemanticCacheEligible expr then
                          psKernelExprMapGet
                            state.whnf
                            expr
                        else
                          Option.none with
                    | Option.some cached =>
                        Except.ok
                          (Prod.mk cached state)
                    | Option.none =>
                        let publicWhnf :=
                          fun
                            (nextContext : PsKernelCheckerContext)
                            (nextState : PsKernelCheckerState)
                            (nextExpr : PsKernelExpr) =>
                            smaller
                              reduceRecursor
                              nextContext
                              nextState
                              nextExpr;
                        match
                            psKernelWhnfCoreWithFuel
                              remaining
                              publicWhnf
                              reduceRecursor
                              context
                              state
                              expr
                              false
                              false with
                        | Except.error error =>
                            Except.error error
                        | Except.ok coreResult =>
                            let core :=
                              Prod.fst coreResult;
                            let state1 :=
                              Prod.snd coreResult;
                            psKernelWhnfAfterCore
                              publicWhnf
                              context
                              state1
                              expr
                              core
        | _ =>
            match
                if psKernelSemanticCacheEligible expr then
                  psKernelExprMapGet
                    state.whnf
                    expr
                else
                  Option.none with
            | Option.some cached =>
                Except.ok
                  (Prod.mk cached state)
            | Option.none =>
                let publicWhnf :=
                  fun
                    (nextContext : PsKernelCheckerContext)
                    (nextState : PsKernelCheckerState)
                    (nextExpr : PsKernelExpr) =>
                    smaller
                      reduceRecursor
                      nextContext
                      nextState
                      nextExpr;
                match
                    psKernelWhnfCoreWithFuel
                      remaining
                      publicWhnf
                      reduceRecursor
                      context
                      state
                      expr
                      false
                      false with
                | Except.error error =>
                    Except.error error
                | Except.ok coreResult =>
                    let core :=
                      Prod.fst coreResult;
                    let state1 :=
                      Prod.snd coreResult;
                    psKernelWhnfAfterCore
                      publicWhnf
                      context
                      state1
                      expr
                      core


def beforeWhnfCoreWithFuel
    (fuel : Nat) :
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
        (Prod
          (Option PsKernelExpr)
          PsKernelCheckerState)) ->
    PsKernelCheckerContext ->
    PsKernelCheckerState ->
    PsKernelExpr ->
    Bool ->
    Bool ->
    Except String
      (Prod PsKernelExpr PsKernelCheckerState) :=
  match fuel with
  | Nat.zero =>
      fun
        (_publicWhnf :
          PsKernelCheckerContext ->
          PsKernelCheckerState ->
          PsKernelExpr ->
          Except String
            (Prod PsKernelExpr PsKernelCheckerState))
        (_reduceRecursor :
          PsKernelCheckerContext ->
          PsKernelCheckerState ->
          PsKernelExpr ->
          Bool ->
          Bool ->
          Except String
            (Prod
              (Option PsKernelExpr)
              PsKernelCheckerState))
        (_context : PsKernelCheckerContext)
        (_state : PsKernelCheckerState)
        (_expr : PsKernelExpr)
        (_cheapRec : Bool)
        (_cheapProj : Bool) =>
        Except.error
          "kernel reduction budget exhausted"
  | Nat.succ remaining =>
      let smaller :=
        beforeWhnfCoreWithFuel remaining;
      fun
        (publicWhnf :
          PsKernelCheckerContext ->
          PsKernelCheckerState ->
          PsKernelExpr ->
          Except String
            (Prod PsKernelExpr PsKernelCheckerState))
        (reduceRecursor :
          PsKernelCheckerContext ->
          PsKernelCheckerState ->
          PsKernelExpr ->
          Bool ->
          Bool ->
          Except String
            (Prod
              (Option PsKernelExpr)
              PsKernelCheckerState))
        (context : PsKernelCheckerContext)
        (state : PsKernelCheckerState)
        (expr : PsKernelExpr)
        (cheapRec : Bool)
        (cheapProj : Bool) =>
        match
            psKernelCheckerContextEnterRecDepth
              context with
        | Except.error error =>
            Except.error error
        | Except.ok nextContext =>
            match expr with
            | PsKernelExpr.bvar _ =>
                Except.ok (Prod.mk expr state)
            | PsKernelExpr.sort _ =>
                Except.ok (Prod.mk expr state)
            | PsKernelExpr.mvar _ =>
                Except.ok (Prod.mk expr state)
            | PsKernelExpr.forallE _ _ _ _ =>
                Except.ok (Prod.mk expr state)
            | PsKernelExpr.const _ _ =>
                Except.ok (Prod.mk expr state)
            | PsKernelExpr.lam _ _ _ _ =>
                Except.ok (Prod.mk expr state)
            | PsKernelExpr.lit _ =>
                Except.ok (Prod.mk expr state)
            | PsKernelExpr.mdata _ body =>
                smaller
                  publicWhnf
                  reduceRecursor
                  nextContext
                  state
                  body
                  cheapRec
                  cheapProj
            | PsKernelExpr.fvar name =>
                match
                    psKernelLocalContextFind
                      nextContext.localContext
                      name with
                | Option.none =>
                    Except.ok (Prod.mk expr state)
                | Option.some declaration =>
                    match
                        psKernelLocalDeclValue
                          declaration with
                    | Option.none =>
                        Except.ok (Prod.mk expr state)
                    | Option.some value =>
                        smaller
                          publicWhnf
                          reduceRecursor
                          nextContext
                          state
                          value
                          cheapRec
                          cheapProj
            | _ =>
                match
                    if psKernelSemanticCacheEligible expr then
                      psKernelExprMapGet
                        state.whnfCore
                        expr
                    else
                      Option.none with
                | Option.some cached =>
                    Except.ok
                      (Prod.mk cached state)
                | Option.none =>
                    match expr with
                    | PsKernelExpr.letE _ _ value body _ =>
                        let reduced :=
                          psKernelExprInstantiate1
                            body
                            value;
                        match
                            smaller
                              publicWhnf
                              reduceRecursor
                              nextContext
                              state
                              reduced
                              cheapRec
                              cheapProj with
                        | Except.error error =>
                            Except.error error
                        | Except.ok result =>
                            psKernelWhnfCoreFinish
                              expr
                              cheapProj
                              (Prod.fst result)
                              (Prod.snd result)
                    | PsKernelExpr.proj typeName index structValue =>
                        let structResult :=
                          if cheapProj then
                            smaller
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
                              structValue;
                        match structResult with
                        | Except.error error =>
                            Except.error error
                        | Except.ok firstResult =>
                            let structReduced :=
                              Prod.fst firstResult;
                            let state1 :=
                              Prod.snd firstResult;
                            let expandedResult :
                                Except String
                                  (Prod
                                    PsKernelExpr
                                    PsKernelCheckerState) :=
                              match structReduced with
                              | PsKernelExpr.lit literal =>
                                  match literal with
                                  | PsKernelLiteral.str value =>
                                      publicWhnf
                                        nextContext
                                        state1
                                        (psKernelStringLitToConstructor
                                          value)
                                  | PsKernelLiteral.nat _ =>
                                      Except.ok
                                        (Prod.mk
                                          structReduced
                                          state1)
                              | _ =>
                                  Except.ok
                                    (Prod.mk
                                      structReduced
                                      state1);
                            match expandedResult with
                            | Except.error error =>
                                Except.error error
                            | Except.ok secondResult =>
                                let expanded :=
                                  Prod.fst secondResult;
                                let state2 :=
                                  Prod.snd secondResult;
                                match
                                    psKernelReduceProjCore
                                      nextContext
                                      typeName
                                      index
                                      expanded with
                                | Option.none =>
                                    psKernelWhnfCoreFinish
                                      expr
                                      cheapProj
                                      expr
                                      state2
                                | Option.some value =>
                                    match
                                        smaller
                                          publicWhnf
                                          reduceRecursor
                                          nextContext
                                          state2
                                          value
                                          cheapRec
                                          cheapProj with
                                    | Except.error error =>
                                        Except.error error
                                    | Except.ok result =>
                                        psKernelWhnfCoreFinish
                                          expr
                                          cheapProj
                                          (Prod.fst result)
                                          (Prod.snd result)
                    | PsKernelExpr.app _ _ =>
                        let spine :=
                          psKernelExprGetAppFnArgs expr;
                        let fn0 :=
                          Prod.fst spine;
                        let args :=
                          Prod.snd spine;
                        match
                            smaller
                              publicWhnf
                              reduceRecursor
                              nextContext
                              state
                              fn0
                              cheapRec
                              cheapProj with
                        | Except.error error =>
                            Except.error error
                        | Except.ok fnResult =>
                            let fn :=
                              Prod.fst fnResult;
                            let state1 :=
                              Prod.snd fnResult;
                            match fn with
                            | PsKernelExpr.lam _ _ _ _ =>
                                match psKernelC0BetaSpinePlan fn args with
                                | Option.none =>
                                    Except.ok (Prod.mk expr state1)
                                | Option.some plan =>
                                    let rebuilt := psKernelC0BetaSpineApply plan;
                                    match
                                        smaller
                                          publicWhnf
                                          reduceRecursor
                                          nextContext
                                          state1
                                          rebuilt
                                          cheapRec
                                          cheapProj with
                                    | Except.error error =>
                                        Except.error error
                                    | Except.ok result =>
                                        psKernelWhnfCoreFinish
                                          expr
                                          cheapProj
                                          (Prod.fst result)
                                          (Prod.snd result)
                            | _ =>
                                if psKernelExprEq fn fn0 then
                                  match
                                      reduceRecursor
                                        nextContext
                                        state1
                                        expr
                                        cheapRec
                                        cheapProj with
                                  | Except.error error =>
                                      Except.error error
                                  | Except.ok reduction =>
                                      match
                                          Prod.fst reduction with
                                      | Option.none =>
                                          Except.ok
                                            (Prod.mk
                                              expr
                                              (Prod.snd reduction))
                                      | Option.some value =>
                                          smaller
                                            publicWhnf
                                            reduceRecursor
                                            nextContext
                                            (Prod.snd reduction)
                                            value
                                            cheapRec
                                            cheapProj
                                else
                                  let rebuilt :=
                                    psKernelExprApplyArgsCheap
                                      fn
                                      args;
                                  match
                                      smaller
                                        publicWhnf
                                        reduceRecursor
                                        nextContext
                                        state1
                                        rebuilt
                                        cheapRec
                                        cheapProj with
                                  | Except.error error =>
                                      Except.error error
                                  | Except.ok result =>
                                      psKernelWhnfCoreFinish
                                        expr
                                        cheapProj
                                        (Prod.fst result)
                                        (Prod.snd result)
                    | _ =>
                        Except.ok
                          (Prod.mk expr state)

def beforeInferCoreWithFuel
    (fuel : Nat) :
    (PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String
        (Prod PsKernelExpr PsKernelCheckerState)) ->
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
    Except String
      (Prod PsKernelExpr PsKernelCheckerState) :=
  match fuel with
  | Nat.zero =>
      fun
        (_whnf :
          PsKernelCheckerContext ->
          PsKernelCheckerState ->
          PsKernelExpr ->
          Except String
            (Prod PsKernelExpr PsKernelCheckerState))
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
        (_inferOnly : Bool) =>
        Except.error
          "kernel inference budget exhausted"
  | Nat.succ remaining =>
      let smaller :=
        beforeInferCoreWithFuel remaining;
      fun
        (whnf :
          PsKernelCheckerContext ->
          PsKernelCheckerState ->
          PsKernelExpr ->
          Except String
            (Prod PsKernelExpr PsKernelCheckerState))
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
        (inferOnly : Bool) =>
        let cache :=
          if inferOnly then
            state.inferOnly
          else
            state.checkedInfer;
        let cached :=
          if
              psKernelInferCacheEligible
                inferOnly
                expr then
            psKernelExprMapGet
              cache
              expr
          else
            Option.none;
        match cached with
        | Option.some cached =>
            match
                psKernelCheckerContextEnterRecDepth
                  context with
            | Except.error error =>
                Except.error error
            | Except.ok _ =>
                Except.ok
                  (Prod.mk cached state)
        | Option.none =>
            match
                psKernelCheckerContextEnterRecDepth
                  context with
            | Except.error error =>
                Except.error error
            | Except.ok nextContext =>
                match expr with
                | PsKernelExpr.bvar _ =>
                    Except.error
                      "loose bound variable in type checker"
                | PsKernelExpr.mvar _ =>
                    Except.error
                      "kernel type checker does not support metavariables"
                | PsKernelExpr.fvar name =>
                    match
                        psKernelLocalContextFind
                          nextContext.localContext
                          name with
                    | Option.none =>
                        Except.error
                          "unknown free variable"
                    | Option.some declaration =>
                        let result :=
                          psKernelLocalDeclType
                            declaration;
                        Except.ok
                          (Prod.mk
                            result
                            (psKernelCacheInferResult
                              state
                              inferOnly
                              expr
                              result))
                | PsKernelExpr.sort level =>
                    let result :=
                      PsKernelExpr.sort
                        (PsKernelLevel.succ level);
                    Except.ok
                      (Prod.mk
                        result
                        (psKernelCacheInferResult
                          state
                          inferOnly
                          expr
                          result))
                | PsKernelExpr.const name levels =>
                    match
                        psKernelInferConstantType
                          nextContext name levels inferOnly with
                    | Except.error error => Except.error error
                    | Except.ok result =>
                        Except.ok
                          (Prod.mk
                            result
                            (psKernelCacheInferResult
                              state inferOnly expr result))
                | PsKernelExpr.lit literal =>
                    match literal with
                    | PsKernelLiteral.nat value =>
                        match
                            psKernelCheckNatSize
                              nextContext.maxNatSize
                              value with
                        | Except.error error =>
                            Except.error error
                        | Except.ok _ =>
                            let result :=
                              PsKernelExpr.const
                                psKernelNatName
                                List.nil;
                            Except.ok
                              (Prod.mk
                                result
                                (psKernelCacheInferResult
                                  state
                                  inferOnly
                                  expr
                                  result))
                    | PsKernelLiteral.str _ =>
                        let result :=
                          PsKernelExpr.const
                            psKernelStringName
                            List.nil;
                        Except.ok
                          (Prod.mk
                            result
                            (psKernelCacheInferResult
                              state
                              inferOnly
                              expr
                              result))
                | PsKernelExpr.mdata _ body =>
                    match
                        smaller
                          whnf
                          defeq
                          nextContext
                          state
                          body
                          inferOnly with
                    | Except.error error =>
                        Except.error error
                    | Except.ok result =>
                        Except.ok
                          (Prod.mk
                            (Prod.fst result)
                            (psKernelCacheInferResult
                              (Prod.snd result)
                              inferOnly
                              expr
                              (Prod.fst result)))
                | PsKernelExpr.app fn arg =>
                    if inferOnly then
                      let args :=
                        psKernelExprGetAppArgs expr;
                      match
                          smaller
                            whnf
                            defeq
                            nextContext
                            state
                            (psKernelExprGetAppFn expr)
                            true with
                      | Except.error error =>
                          Except.error error
                      | Except.ok fnResult =>
                          match
                              psKernelInferAppOnlyLoopWithFuel
                                (Nat.succ
                                  (psKernelExprListLength args))
                                whnf
                                nextContext
                                (Prod.snd fnResult)
                                args
                                0
                                0
                                (Prod.fst fnResult) with
                          | Except.error error =>
                              Except.error error
                          | Except.ok appResult =>
                              Except.ok
                                (Prod.mk
                                  (Prod.fst appResult)
                                  (psKernelCacheInferResult
                                    (Prod.snd appResult)
                                    true
                                    expr
                                    (Prod.fst appResult)))
                    else
                      match
                          smaller
                            whnf
                            defeq
                            nextContext
                            state
                            fn
                            false with
                      | Except.error error =>
                          Except.error error
                      | Except.ok fnResult =>
                          match
                              psKernelEnsureForallWith
                                whnf
                                nextContext
                                (Prod.snd fnResult)
                                (Prod.fst fnResult) with
                          | Except.error error =>
                              Except.error error
                          | Except.ok forallResult =>
                              let view :=
                                Prod.fst forallResult;
                              let state2 :=
                                Prod.snd forallResult;
                              match
                                  smaller
                                    whnf
                                    defeq
                                    nextContext
                                    state2
                                    arg
                                    false with
                              | Except.error error =>
                                  Except.error error
                              | Except.ok argResult =>
                                  let argType :=
                                    Prod.fst argResult;
                                  if
                                      psKernelExprEq
                                        argType
                                        view.domain then
                                    let result :=
                                      psKernelExprInstantiate1
                                        view.body
                                        arg;
                                    Except.ok
                                      (Prod.mk
                                        result
                                        (psKernelCacheInferResult
                                          (Prod.snd argResult)
                                          false
                                          expr
                                          result))
                                  else
                                    let eqContext :=
                                      if
                                          psKernelExprIsEagerReduce
                                            arg then
                                        psKernelCheckerContextWithEagerReduce
                                          nextContext
                                          true
                                      else
                                        nextContext;
                                    match
                                        defeq
                                          eqContext
                                          (Prod.snd argResult)
                                          argType
                                          view.domain with
                                    | Except.error error =>
                                        Except.error error
                                    | Except.ok eqResult =>
                                        if Prod.fst eqResult then
                                          let result :=
                                            psKernelExprInstantiate1
                                              view.body
                                              arg;
                                          Except.ok
                                            (Prod.mk
                                              result
                                              (psKernelCacheInferResult
                                                (Prod.snd eqResult)
                                                false
                                                expr
                                                result))
                                        else
                                          Except.error
                                            "application type mismatch"
                | PsKernelExpr.lam name domain body binderInfo =>
                    let checkedDomain :=
                      if inferOnly then
                        Except.ok
                          (Prod.mk
                            domain
                            state)
                      else
                        match
                            smaller
                              whnf
                              defeq
                              nextContext
                              state
                              domain
                              false with
                        | Except.error error =>
                            Except.error error
                        | Except.ok domainResult =>
                            match
                                psKernelEnsureSortWith
                                  whnf
                                  nextContext
                                  (Prod.snd domainResult)
                                  (Prod.fst domainResult) with
                            | Except.error error =>
                                Except.error error
                            | Except.ok sortResult =>
                                Except.ok
                                  (Prod.mk
                                    domain
                                    (Prod.snd sortResult));
                    match checkedDomain with
                    | Except.error error =>
                        Except.error error
                    | Except.ok domainState =>
                        let freshResult :=
                          psKernelCheckerStateFreshName
                            (Prod.snd domainState)
                            name;
                        let fresh :=
                          Prod.fst freshResult;
                        let state1 :=
                          Prod.snd freshResult;
                        let childLocal :=
                          psKernelLocalContextAddLocal
                            nextContext.localContext
                            fresh
                            name
                            domain
                            binderInfo;
                        let child :=
                          psKernelCheckerContextWithLocalContext
                            nextContext
                            childLocal;
                        let openedBody :=
                          psKernelExprInstantiate1
                            body
                            (PsKernelExpr.fvar fresh);
                        match
                            smaller
                              whnf
                              defeq
                              child
                              state1
                              openedBody
                              inferOnly with
                        | Except.error error =>
                            Except.error error
                        | Except.ok bodyResult =>
                            let bodyType :=
                              psKernelExprCheapBetaReduce
                                (Prod.fst bodyResult);
                            let closedBody :=
                              psKernelExprAbstractFVars
                                bodyType
                                (List.cons
                                  fresh
                                  List.nil);
                            let result :=
                              PsKernelExpr.forallE
                                name
                                domain
                                closedBody
                                binderInfo;
                            let scopedState :=
                              psKernelCheckerStateExitLocalScope
                                state1
                                (Prod.snd bodyResult);
                            Except.ok
                              (Prod.mk
                                result
                                (psKernelCacheInferResult
                                  scopedState
                                  inferOnly
                                  expr
                                  result))
                | PsKernelExpr.forallE name domain body binderInfo =>
                    match
                        smaller
                          whnf
                          defeq
                          nextContext
                          state
                          domain
                          inferOnly with
                    | Except.error error =>
                        Except.error error
                    | Except.ok domainResult =>
                        match
                            psKernelEnsureSortWith
                              whnf
                              nextContext
                              (Prod.snd domainResult)
                              (Prod.fst domainResult) with
                        | Except.error error =>
                            Except.error error
                        | Except.ok domainSort =>
                            let freshResult :=
                              psKernelCheckerStateFreshName
                                (Prod.snd domainSort)
                                name;
                            let fresh :=
                              Prod.fst freshResult;
                            let state1 :=
                              Prod.snd freshResult;
                            let childLocal :=
                              psKernelLocalContextAddLocal
                                nextContext.localContext
                                fresh
                                name
                                domain
                                binderInfo;
                            let child :=
                              psKernelCheckerContextWithLocalContext
                                nextContext
                                childLocal;
                            let openedBody :=
                              psKernelExprInstantiate1
                                body
                                (PsKernelExpr.fvar fresh);
                            match
                                smaller
                                  whnf
                                  defeq
                                  child
                                  state1
                                  openedBody
                                  inferOnly with
                            | Except.error error =>
                                Except.error error
                            | Except.ok bodyResult =>
                                match
                                    psKernelEnsureSortWith
                                      whnf
                                      child
                                      (Prod.snd bodyResult)
                                      (Prod.fst bodyResult) with
                                | Except.error error =>
                                    Except.error error
                                | Except.ok bodySort =>
                                    let result :=
                                      PsKernelExpr.sort
                                        (psKernelLevelMkIMax
                                          (Prod.fst domainSort)
                                          (Prod.fst bodySort));
                                    let scopedState :=
                                      psKernelCheckerStateExitLocalScope
                                        state1
                                        (Prod.snd bodySort);
                                    Except.ok
                                      (Prod.mk
                                        result
                                        (psKernelCacheInferResult
                                          scopedState
                                          inferOnly
                                          expr
                                          result))
                | PsKernelExpr.letE name type value body nondep =>
                    let checked :=
                      if inferOnly then
                        Except.ok
                          (Prod.mk
                            type
                            state)
                      else
                        match
                            smaller
                              whnf
                              defeq
                              nextContext
                              state
                              type
                              false with
                        | Except.error error =>
                            Except.error error
                        | Except.ok typeResult =>
                            match
                                psKernelEnsureSortWith
                                  whnf
                                  nextContext
                                  (Prod.snd typeResult)
                                  (Prod.fst typeResult) with
                            | Except.error error =>
                                Except.error error
                            | Except.ok typeSort =>
                                match
                                    smaller
                                      whnf
                                      defeq
                                      nextContext
                                      (Prod.snd typeSort)
                                      value
                                      false with
                                | Except.error error =>
                                    Except.error error
                                | Except.ok valueResult =>
                                    match
                                        defeq
                                          nextContext
                                          (Prod.snd valueResult)
                                          (Prod.fst valueResult)
                                          type with
                                    | Except.error error =>
                                        Except.error error
                                    | Except.ok eqResult =>
                                        if Prod.fst eqResult then
                                          Except.ok
                                            (Prod.mk
                                              type
                                              (Prod.snd eqResult))
                                        else
                                          Except.error
                                            "let value type mismatch";
                    match checked with
                    | Except.error error =>
                        Except.error error
                    | Except.ok checkedResult =>
                        let freshResult :=
                          psKernelCheckerStateFreshName
                            (Prod.snd checkedResult)
                            name;
                        let fresh :=
                          Prod.fst freshResult;
                        let state1 :=
                          Prod.snd freshResult;
                        let childLocal :=
                          psKernelLocalContextAddLet
                            nextContext.localContext
                            fresh
                            name
                            type
                            value;
                        let child :=
                          psKernelCheckerContextWithLocalContext
                            nextContext
                            childLocal;
                        let openedBody :=
                          psKernelExprInstantiate1
                            body
                            (PsKernelExpr.fvar fresh);
                        match
                            smaller
                              whnf
                              defeq
                              child
                              state1
                              openedBody
                              inferOnly with
                        | Except.error error =>
                            Except.error error
                        | Except.ok bodyResult =>
                            let bodyType :=
                              psKernelExprCheapBetaReduce
                                (Prod.fst bodyResult);
                            let closedBody :=
                              psKernelExprAbstractFVars
                                bodyType
                                (List.cons
                                  fresh
                                  List.nil);
                            let result :=
                              if
                                  psKernelExprHasLooseBVarAt
                                    closedBody
                                    0 then
                                PsKernelExpr.letE
                                  name
                                  type
                                  value
                                  closedBody
                                  nondep
                              else
                                bodyType;
                            let scopedState :=
                              psKernelCheckerStateExitLocalScope
                                state1
                                (Prod.snd bodyResult);
                            Except.ok
                              (Prod.mk
                                result
                                (psKernelCacheInferResult
                                  scopedState
                                  inferOnly
                                  expr
                                  result))
                | PsKernelExpr.proj typeName index structValue =>
                    let inferType :=
                      fun
                        (projectionContext : PsKernelCheckerContext)
                        (projectionState : PsKernelCheckerState)
                        (projectionExpr : PsKernelExpr) =>
                        smaller
                          whnf
                          defeq
                          projectionContext
                          projectionState
                          projectionExpr
                          inferOnly;
                    match
                        psKernelInferProjectionWith
                          whnf
                          inferType
                          nextContext
                          state
                          typeName
                          index
                          structValue with
                    | Except.error error =>
                        Except.error error
                    | Except.ok projectionResult =>
                        let result :=
                          Prod.fst projectionResult;
                        Except.ok
                          (Prod.mk
                            result
                            (psKernelCacheInferResult
                              (Prod.snd projectionResult)
                              inferOnly
                              expr
                              result))

def beforeInferAppOnlyLoopWithFuel
    (fuel : Nat) :
    (PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String
        (Prod PsKernelExpr PsKernelCheckerState)) ->
    PsKernelCheckerContext ->
    PsKernelCheckerState ->
    List PsKernelExpr ->
    Nat ->
    Nat ->
    PsKernelExpr ->
    Except String
      (Prod PsKernelExpr PsKernelCheckerState) :=
  match fuel with
  | Nat.zero =>
      fun
        (_whnf :
          PsKernelCheckerContext ->
          PsKernelCheckerState ->
          PsKernelExpr ->
          Except String
            (Prod PsKernelExpr PsKernelCheckerState))
        (_context : PsKernelCheckerContext)
        (_state : PsKernelCheckerState)
        (_args : List PsKernelExpr)
        (_index : Nat)
        (_instantiated : Nat)
        (_current : PsKernelExpr) =>
        Except.error
          "kernel inference budget exhausted"
  | Nat.succ remaining =>
      let smaller :=
        beforeInferAppOnlyLoopWithFuel remaining;
      fun
        (whnf :
          PsKernelCheckerContext ->
          PsKernelCheckerState ->
          PsKernelExpr ->
          Except String
            (Prod PsKernelExpr PsKernelCheckerState))
        (context : PsKernelCheckerContext)
        (state : PsKernelCheckerState)
        (args : List PsKernelExpr)
        (index : Nat)
        (instantiated : Nat)
        (current : PsKernelExpr) =>
        let argCount :=
          psKernelExprListLength args;
        if psKernelNatLt index argCount then
          match current with
          | PsKernelExpr.forallE _ _ body _ =>
              smaller
                whnf
                context
                state
                args
                (Nat.succ index)
                instantiated
                body
          | _ =>
              let pending :=
                psKernelExprListTake
                  (Nat.sub index instantiated)
                  (psKernelExprListDrop
                    instantiated
                    args);
              let exposed :=
                psKernelExprInstantiateRev
                  current
                  pending;
              match
                  psKernelEnsureForallWith
                    whnf
                    context
                    state
                    exposed with
              | Except.error error =>
                  Except.error error
              | Except.ok forallResult =>
                  let view :=
                    Prod.fst forallResult;
                  smaller
                    whnf
                    context
                    (Prod.snd forallResult)
                    args
                    (Nat.succ index)
                    index
                    view.body
        else
          Except.ok
            (Prod.mk
              (psKernelExprInstantiateRev
                current
                (psKernelExprListDrop
                  instantiated
                  args))
              state)

def beforeDefEqLazyReductionWithFuel
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
        beforeDefEqLazyReductionWithFuel remaining;
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


def beforeDefEqLazyProjReductionWithFuel
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
        beforeDefEqLazyProjReductionWithFuel remaining;
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

def beforeDefEqArgsWithFuel
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
    PsKernelExpr ->
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
        (_context : PsKernelCheckerContext)
        (_state : PsKernelCheckerState)
        (_left : PsKernelExpr)
        (_right : PsKernelExpr) =>
        Except.error
          "kernel defeq argument budget exhausted"
  | Nat.succ remaining =>
      let smaller :=
        beforeDefEqArgsWithFuel remaining;
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
        (left : PsKernelExpr)
        (right : PsKernelExpr) =>
        match left with
        | PsKernelExpr.app leftFn leftArg =>
            match right with
            | PsKernelExpr.app rightFn rightArg =>
                match
                    defeq
                      context
                      state
                      leftArg
                      rightArg with
                | Except.error error =>
                    Except.error error
                | Except.ok argResult =>
                    if Prod.fst argResult then
                      smaller
                        defeq
                        context
                        (Prod.snd argResult)
                        leftFn
                        rightFn
                    else
                      Except.ok argResult
            | _ =>
                Except.ok
                  (Prod.mk false state)
        | _ =>
            match right with
            | PsKernelExpr.app _ _ =>
                Except.ok
                  (Prod.mk false state)
            | _ =>
                Except.ok
                  (Prod.mk true state)


theorem ReduceRecursorBoundedWithFuel_delayed_recursion_preserves (fuel : Nat) :
    psKernelReduceRecursorBoundedWithFuel fuel = beforeReduceRecursorBoundedWithFuel fuel := by
  induction fuel with
  | zero => rfl
  | succ fuel ih =>
      funext defeq context state expr cheapRec cheapProj
      simp only [psKernelReduceRecursorBoundedWithFuel, beforeReduceRecursorBoundedWithFuel, ih] <;> rfl

#print axioms ReduceRecursorBoundedWithFuel_delayed_recursion_preserves

theorem IsDefEqWithFuel_delayed_recursion_preserves (fuel : Nat) :
    psKernelIsDefEqWithFuel fuel = beforeIsDefEqWithFuel fuel := by
  induction fuel with
  | zero => rfl
  | succ fuel ih =>
      funext context state left right
      simp only [psKernelIsDefEqWithFuel, beforeIsDefEqWithFuel, ih] <;> rfl

#print axioms IsDefEqWithFuel_delayed_recursion_preserves

theorem WhnfWithFuel_delayed_recursion_preserves (fuel : Nat) :
    psKernelWhnfWithFuel fuel = beforeWhnfWithFuel fuel := by
  induction fuel with
  | zero => rfl
  | succ fuel ih =>
      funext reduceRecursor context state expr
      simp only [psKernelWhnfWithFuel, beforeWhnfWithFuel, ih] <;> rfl

#print axioms WhnfWithFuel_delayed_recursion_preserves

theorem WhnfCoreWithFuel_delayed_recursion_preserves (fuel : Nat) :
    psKernelWhnfCoreWithFuel fuel = beforeWhnfCoreWithFuel fuel := by
  induction fuel with
  | zero => rfl
  | succ fuel ih =>
      funext publicWhnf reduceRecursor context state expr cheapRec cheapProj
      simp only [psKernelWhnfCoreWithFuel, beforeWhnfCoreWithFuel, ih] <;> rfl

#print axioms WhnfCoreWithFuel_delayed_recursion_preserves

theorem InferCoreWithFuel_delayed_recursion_preserves (fuel : Nat) :
    psKernelInferCoreWithFuel fuel = beforeInferCoreWithFuel fuel := by
  induction fuel with
  | zero => rfl
  | succ fuel ih =>
      funext whnf defeq context state expr inferOnly
      simp only [psKernelInferCoreWithFuel, beforeInferCoreWithFuel, ih] <;> rfl

#print axioms InferCoreWithFuel_delayed_recursion_preserves

theorem InferAppOnlyLoopWithFuel_delayed_recursion_preserves (fuel : Nat) :
    psKernelInferAppOnlyLoopWithFuel fuel = beforeInferAppOnlyLoopWithFuel fuel := by
  induction fuel with
  | zero => rfl
  | succ fuel ih =>
      funext whnf context state args index instantiated current
      simp only [psKernelInferAppOnlyLoopWithFuel, beforeInferAppOnlyLoopWithFuel, ih] <;> rfl

#print axioms InferAppOnlyLoopWithFuel_delayed_recursion_preserves

theorem DefEqLazyReductionWithFuel_delayed_recursion_preserves (fuel : Nat) :
    psKernelDefEqLazyReductionWithFuel fuel = beforeDefEqLazyReductionWithFuel fuel := by
  induction fuel with
  | zero => rfl
  | succ fuel ih =>
      funext defeq whnf coreWhnf context state left right
      simp only [psKernelDefEqLazyReductionWithFuel, beforeDefEqLazyReductionWithFuel, ih] <;> rfl

#print axioms DefEqLazyReductionWithFuel_delayed_recursion_preserves

theorem DefEqLazyProjReductionWithFuel_delayed_recursion_preserves (fuel : Nat) :
    psKernelDefEqLazyProjReductionWithFuel fuel = beforeDefEqLazyProjReductionWithFuel fuel := by
  induction fuel with
  | zero => rfl
  | succ fuel ih =>
      funext defeq coreWhnf context state left right typeName index
      simp only [psKernelDefEqLazyProjReductionWithFuel, beforeDefEqLazyProjReductionWithFuel, ih] <;> rfl

#print axioms DefEqLazyProjReductionWithFuel_delayed_recursion_preserves

theorem DefEqArgsWithFuel_delayed_recursion_preserves (fuel : Nat) :
    psKernelDefEqArgsWithFuel fuel = beforeDefEqArgsWithFuel fuel := by
  induction fuel with
  | zero => rfl
  | succ fuel ih =>
      funext defeq context state left right
      simp only [psKernelDefEqArgsWithFuel, beforeDefEqArgsWithFuel, ih] <;> rfl

#print axioms DefEqArgsWithFuel_delayed_recursion_preserves

def beforeDefEqLambdaSpineWithFuel
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
    PsKernelExpr ->
    List PsKernelExpr ->
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
        (_context : PsKernelCheckerContext)
        (_state : PsKernelCheckerState)
        (_left : PsKernelExpr)
        (_right : PsKernelExpr)
        (_subst : List PsKernelExpr) =>
        Except.error
          "kernel defeq lambda-spine budget exhausted"
  | Nat.succ remaining =>
      let smaller :=
        beforeDefEqLambdaSpineWithFuel remaining;
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
        (left : PsKernelExpr)
        (right : PsKernelExpr)
        (subst : List PsKernelExpr) =>
        match left with
        | PsKernelExpr.lam _ leftDomain leftBody _ =>
            match right with
            | PsKernelExpr.lam rightName rightDomain rightBody rightBinderInfo =>
                let leftOpened :=
                  psKernelExprInstantiateRev
                    leftDomain
                    subst;
                let rightOpened :=
                  psKernelExprInstantiateRev
                    rightDomain
                    subst;
                let domainResult :
                    Except String
                      (Prod Bool PsKernelCheckerState) :=
                  if psKernelExprEq leftDomain rightDomain then
                    Except.ok
                      (Prod.mk true state)
                  else
                    defeq
                      context
                      state
                      leftOpened
                      rightOpened;
                match domainResult with
                | Except.error error =>
                    Except.error error
                | Except.ok domains =>
                    if Prod.fst domains then
                      if
                          if psKernelExprHasLooseBVar leftBody then
                            true
                          else
                            psKernelExprHasLooseBVar rightBody then
                        let openedLocal :=
                          psKernelDefEqWithLocal
                            context
                            (Prod.snd domains)
                            rightName
                            rightOpened
                            rightBinderInfo;
                        let fresh :=
                          Prod.fst openedLocal;
                        let child :=
                          Prod.fst (Prod.snd openedLocal);
                        let nextState :=
                          Prod.snd (Prod.snd openedLocal);
                        match
                            smaller
                              defeq
                              child
                              nextState
                              leftBody
                              rightBody
                              (psKernelExprListAppend
                                subst
                                (List.cons
                                  (PsKernelExpr.fvar fresh)
                                  List.nil)) with
                        | Except.error error =>
                            Except.error error
                        | Except.ok childResult =>
                            Except.ok
                              (Prod.mk
                                (Prod.fst childResult)
                                (psKernelCheckerStateExitLocalScope
                                  nextState
                                  (Prod.snd childResult)))
                      else
                        smaller
                          defeq
                          context
                          (Prod.snd domains)
                          leftBody
                          rightBody
                          (psKernelExprListAppend
                            subst
                            (List.cons
                              (PsKernelExpr.sort
                                PsKernelLevel.zero)
                              List.nil))
                    else
                      Except.ok
                        (Prod.mk
                          false
                          (Prod.snd domains))
            | _ =>
                defeq
                  context
                  state
                  (psKernelExprInstantiateRev left subst)
                  (psKernelExprInstantiateRev right subst)
        | _ =>
            defeq
              context
              state
              (psKernelExprInstantiateRev left subst)
              (psKernelExprInstantiateRev right subst)


theorem DefEqLambdaSpineWithFuel_delayed_recursion_preserves (fuel : Nat) :
    psKernelDefEqLambdaSpineWithFuel fuel = beforeDefEqLambdaSpineWithFuel fuel := by
  induction fuel with
  | zero => rfl
  | succ fuel ih =>
      funext defeq context state left right subst
      simp only [psKernelDefEqLambdaSpineWithFuel, beforeDefEqLambdaSpineWithFuel, ih] <;> rfl

#print axioms DefEqLambdaSpineWithFuel_delayed_recursion_preserves

def beforeDefEqForallSpineWithFuel
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
    PsKernelExpr ->
    List PsKernelExpr ->
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
        (_context : PsKernelCheckerContext)
        (_state : PsKernelCheckerState)
        (_left : PsKernelExpr)
        (_right : PsKernelExpr)
        (_subst : List PsKernelExpr) =>
        Except.error
          "kernel defeq forall-spine budget exhausted"
  | Nat.succ remaining =>
      let smaller :=
        beforeDefEqForallSpineWithFuel remaining;
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
        (left : PsKernelExpr)
        (right : PsKernelExpr)
        (subst : List PsKernelExpr) =>
        match left with
        | PsKernelExpr.forallE _ leftDomain leftBody _ =>
            match right with
            | PsKernelExpr.forallE rightName rightDomain rightBody rightBinderInfo =>
                let leftOpened :=
                  psKernelExprInstantiateRev
                    leftDomain
                    subst;
                let rightOpened :=
                  psKernelExprInstantiateRev
                    rightDomain
                    subst;
                let domainResult :
                    Except String
                      (Prod Bool PsKernelCheckerState) :=
                  if psKernelExprEq leftDomain rightDomain then
                    Except.ok
                      (Prod.mk true state)
                  else
                    defeq
                      context
                      state
                      leftOpened
                      rightOpened;
                match domainResult with
                | Except.error error =>
                    Except.error error
                | Except.ok domains =>
                    if Prod.fst domains then
                      if
                          if psKernelExprHasLooseBVar leftBody then
                            true
                          else
                            psKernelExprHasLooseBVar rightBody then
                        let openedLocal :=
                          psKernelDefEqWithLocal
                            context
                            (Prod.snd domains)
                            rightName
                            rightOpened
                            rightBinderInfo;
                        let fresh :=
                          Prod.fst openedLocal;
                        let child :=
                          Prod.fst (Prod.snd openedLocal);
                        let nextState :=
                          Prod.snd (Prod.snd openedLocal);
                        match
                            smaller
                              defeq
                              child
                              nextState
                              leftBody
                              rightBody
                              (psKernelExprListAppend
                                subst
                                (List.cons
                                  (PsKernelExpr.fvar fresh)
                                  List.nil)) with
                        | Except.error error =>
                            Except.error error
                        | Except.ok childResult =>
                            Except.ok
                              (Prod.mk
                                (Prod.fst childResult)
                                (psKernelCheckerStateExitLocalScope
                                  nextState
                                  (Prod.snd childResult)))
                      else
                        smaller
                          defeq
                          context
                          (Prod.snd domains)
                          leftBody
                          rightBody
                          (psKernelExprListAppend
                            subst
                            (List.cons
                              (PsKernelExpr.sort
                                PsKernelLevel.zero)
                              List.nil))
                    else
                      Except.ok
                        (Prod.mk
                          false
                          (Prod.snd domains))
            | _ =>
                defeq
                  context
                  state
                  (psKernelExprInstantiateRev left subst)
                  (psKernelExprInstantiateRev right subst)
        | _ =>
            defeq
              context
              state
              (psKernelExprInstantiateRev left subst)
              (psKernelExprInstantiateRev right subst)


theorem DefEqForallSpineWithFuel_delayed_recursion_preserves (fuel : Nat) :
    psKernelDefEqForallSpineWithFuel fuel = beforeDefEqForallSpineWithFuel fuel := by
  induction fuel with
  | zero => rfl
  | succ fuel ih =>
      funext defeq context state left right subst
      simp only [psKernelDefEqForallSpineWithFuel, beforeDefEqForallSpineWithFuel, ih] <;> rfl

#print axioms DefEqForallSpineWithFuel_delayed_recursion_preserves

def beforeDefEqCompareExprListsWithFuel
    (fuel : Nat) :
    (PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String
        (Prod Bool PsKernelCheckerState)) ->
    PsKernelCheckerContext ->
    PsKernelCheckerState ->
    List PsKernelExpr ->
    List PsKernelExpr ->
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
        (_context : PsKernelCheckerContext)
        (_state : PsKernelCheckerState)
        (_left : List PsKernelExpr)
        (_right : List PsKernelExpr) =>
        Except.error
          "kernel defeq argument-list budget exhausted"
  | Nat.succ remaining =>
      let smaller :=
        beforeDefEqCompareExprListsWithFuel remaining;
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
        (left : List PsKernelExpr)
        (right : List PsKernelExpr) =>
        match left with
        | List.nil =>
            match right with
            | List.nil =>
                Except.ok
                  (Prod.mk true state)
            | List.cons _ _ =>
                Except.ok
                  (Prod.mk false state)
        | List.cons leftHead leftTail =>
            match right with
            | List.nil =>
                Except.ok
                  (Prod.mk false state)
            | List.cons rightHead rightTail =>
                match
                    defeq
                      context
                      state
                      leftHead
                      rightHead with
                | Except.error error =>
                    Except.error error
                | Except.ok headResult =>
                    if Prod.fst headResult then
                      smaller
                        defeq
                        context
                        (Prod.snd headResult)
                        leftTail
                        rightTail
                    else
                      Except.ok headResult


theorem DefEqCompareExprListsWithFuel_delayed_recursion_preserves (fuel : Nat) :
    psKernelDefEqCompareExprListsWithFuel fuel = beforeDefEqCompareExprListsWithFuel fuel := by
  induction fuel with
  | zero => rfl
  | succ fuel ih =>
      funext defeq context state left right
      simp only [psKernelDefEqCompareExprListsWithFuel, beforeDefEqCompareExprListsWithFuel, ih] <;> rfl

#print axioms DefEqCompareExprListsWithFuel_delayed_recursion_preserves

def beforeDefEqEtaStructFieldsWithFuel
    (fuel : Nat) :
    (PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String
        (Prod Bool PsKernelCheckerState)) ->
    PsKernelCheckerContext ->
    PsKernelCheckerState ->
    PsKernelName ->
    PsKernelExpr ->
    List PsKernelExpr ->
    Nat ->
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
        (_context : PsKernelCheckerContext)
        (_state : PsKernelCheckerState)
        (_induct : PsKernelName)
        (_term : PsKernelExpr)
        (_args : List PsKernelExpr)
        (_numParams : Nat)
        (_index : Nat) =>
        Except.error
          "kernel structure eta budget exhausted"
  | Nat.succ remaining =>
      let smaller :=
        beforeDefEqEtaStructFieldsWithFuel remaining;
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
        (induct : PsKernelName)
        (term : PsKernelExpr)
        (args : List PsKernelExpr)
        (numParams : Nat)
        (index : Nat) =>
        let fieldCount :=
          Nat.sub
            (psKernelExprListLength args)
            numParams;
        if psKernelNatLt index fieldCount then
          match
              psKernelExprListGet
                args
                (Nat.add
                  numParams
                  index) with
          | Option.none =>
              Except.ok
                (Prod.mk false state)
          | Option.some arg =>
              match
                  defeq
                    context
                    state
                    (PsKernelExpr.proj
                      induct
                      index
                      term)
                    arg with
              | Except.error error =>
                  Except.error error
              | Except.ok result =>
                  if Prod.fst result then
                    smaller
                      defeq
                      context
                      (Prod.snd result)
                      induct
                      term
                      args
                      numParams
                      (Nat.succ index)
                  else
                    Except.ok result
        else
          Except.ok
            (Prod.mk true state)


theorem DefEqEtaStructFieldsWithFuel_delayed_recursion_preserves (fuel : Nat) :
    psKernelDefEqEtaStructFieldsWithFuel fuel = beforeDefEqEtaStructFieldsWithFuel fuel := by
  induction fuel with
  | zero => rfl
  | succ fuel ih =>
      funext defeq context state induct term args numParams index
      simp only [psKernelDefEqEtaStructFieldsWithFuel, beforeDefEqEtaStructFieldsWithFuel, ih] <;> rfl

#print axioms DefEqEtaStructFieldsWithFuel_delayed_recursion_preserves

def beforeWhnfCountLambdasWithFuel
    (fuel : Nat) :
    PsKernelExpr ->
    Nat ->
    Nat ->
    Prod PsKernelExpr Nat :=
  match fuel with
  | Nat.zero =>
      fun
        (current : PsKernelExpr)
        (_argCount : Nat)
        (count : Nat) =>
        Prod.mk current count
  | Nat.succ remaining =>
      let smaller :
          PsKernelExpr ->
          Nat ->
          Nat ->
          Prod PsKernelExpr Nat :=
        beforeWhnfCountLambdasWithFuel remaining;
      fun
        (current : PsKernelExpr)
        (argCount : Nat)
        (count : Nat) =>
        match current with
        | PsKernelExpr.lam _ _ body _ =>
            if psKernelNatLt count argCount then
              let nextCount :=
                Nat.succ count;
              if psKernelNatLt nextCount argCount then
                match body with
                | PsKernelExpr.lam _ _ _ _ =>
                    smaller
                      body
                      argCount
                      nextCount
                | _ =>
                    Prod.mk
                      current
                      nextCount
              else
                Prod.mk
                  current
                  nextCount
            else
              Prod.mk current count
        | _ =>
            Prod.mk current count


theorem WhnfCountLambdasWithFuel_delayed_recursion_preserves (fuel : Nat) :
    psKernelWhnfCountLambdasWithFuel fuel = beforeWhnfCountLambdasWithFuel fuel := by
  induction fuel with
  | zero => rfl
  | succ fuel ih =>
      funext current argCount count
      simp only [psKernelWhnfCountLambdasWithFuel, beforeWhnfCountLambdasWithFuel, ih] <;> rfl

#print axioms WhnfCountLambdasWithFuel_delayed_recursion_preserves

def beforeStringConstructorDataWithFuel
    (fuel : Nat) :
    String ->
    Nat ->
    PsKernelExpr ->
    PsKernelExpr ->
    PsKernelExpr ->
    PsKernelExpr :=
  match fuel with
  | Nat.zero =>
      fun
        (_value : String)
        (_position : Nat)
        (listNil : PsKernelExpr)
        (_listCons : PsKernelExpr)
        (_charOfNat : PsKernelExpr) =>
        listNil
  | Nat.succ remaining =>
      let smaller :
          String ->
          Nat ->
          PsKernelExpr ->
          PsKernelExpr ->
          PsKernelExpr ->
          PsKernelExpr :=
        beforeStringConstructorDataWithFuel remaining;
      fun
        (value : String)
        (position : Nat)
        (listNil : PsKernelExpr)
        (listCons : PsKernelExpr)
        (charOfNat : PsKernelExpr) =>
        if
            String.Internal.atEnd
              value
              (String.Pos.Raw.mk position) then
          listNil
        else
          let char :=
            String.Internal.get
              value
              (String.Pos.Raw.mk position);
          let nextPosition :=
            String.Pos.Raw.byteIdx
              (String.Internal.next
                value
                (String.Pos.Raw.mk position));
          let charExpr :=
            PsKernelExpr.app
              charOfNat
              (PsKernelExpr.lit
                (PsKernelLiteral.nat
                  (Char.toNat char)));
          let rest :=
            smaller
              value
              nextPosition
              listNil
              listCons
              charOfNat;
          PsKernelExpr.app
            (PsKernelExpr.app
              listCons
              charExpr)
            rest


theorem StringConstructorDataWithFuel_delayed_recursion_preserves (fuel : Nat) :
    psKernelStringConstructorDataWithFuel fuel = beforeStringConstructorDataWithFuel fuel := by
  induction fuel with
  | zero => rfl
  | succ fuel ih =>
      funext value position listNil listCons charOfNat
      simp only [psKernelStringConstructorDataWithFuel, beforeStringConstructorDataWithFuel, ih] <;> rfl

#print axioms StringConstructorDataWithFuel_delayed_recursion_preserves

end PsKernelKnotFuelProofs

#eval IO.println "PSKERNEL_KNOT_FUEL_PROOFS: PASS workers=15"
