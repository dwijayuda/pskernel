import Ps.KernelCore.Checker.Reduction.WhnfCore
import Ps.KernelCore.Runtime.Acceleration.CachePolicy

/-
Public weak-head normalization pipeline.

The ordering in this module is observable Lean 4.34 behavior:
  core WHNF -> optional native reduction -> Nat reduction -> delta unfolding.
The final public entry point keeps recursor reduction injectable so the same
core algorithm is reused by the recursor checker without circular semantics.
-/

def psKernelWhnfAfterCore
    (continueWhnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String
        (Prod PsKernelExpr PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (original : PsKernelExpr)
    (core : PsKernelExpr) :
    Except String
      (Prod PsKernelExpr PsKernelCheckerState) :=
  match
      psKernelReduceNative
        context
        core with
  | Except.error error =>
      Except.error error
  | Except.ok nativeResult =>
      match nativeResult with
      | Option.some value =>
          psKernelWhnfFinish
            original
            value
            state
      | Option.none =>
          match
              psKernelReduceNatWith
                continueWhnf
                context
                state
                core with
          | Except.error error =>
              Except.error error
          | Except.ok natResult =>
              match Prod.fst natResult with
              | Option.some value =>
                  psKernelWhnfFinish
                    original
                    value
                    (Prod.snd natResult)
              | Option.none =>
                  match
                      psKernelUnfoldDefinition
                        context
                        core with
                  | Option.none =>
                      psKernelWhnfFinish
                        original
                        core
                        (Prod.snd natResult)
                  | Option.some value =>
                      match
                          continueWhnf
                            context
                            (Prod.snd natResult)
                            value with
                      | Except.error error =>
                          Except.error error
                      | Except.ok result =>
                          psKernelWhnfFinish
                            original
                            (Prod.fst result)
                            (Prod.snd result)

def psKernelWhnfWithFuel
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
        psKernelWhnfWithFuel remaining;
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

def psKernelWhnfNoRecursor
    (fuel : Nat)
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (expr : PsKernelExpr) :
    Except String
      (Prod PsKernelExpr PsKernelCheckerState) :=
  psKernelWhnfWithFuel
    fuel
    psKernelNoRecursorReduction
    context
    state
    expr
