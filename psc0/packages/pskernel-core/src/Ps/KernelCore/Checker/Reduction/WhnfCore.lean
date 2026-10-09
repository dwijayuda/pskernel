import Ps.KernelCore.Checker.Reduction.KernelReductions
import Ps.KernelCore.Runtime.Acceleration.CachePolicy

/-
Core weak-head reduction.

This module performs the structural beta/zeta/projection/recursor-facing WHNF
steps and deliberately stops before the public post-core pipeline decides native
reduction, Nat reduction, delta unfolding, and cache publication.
-/

def psKernelWhnfCountLambdasWithFuel
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
        psKernelWhnfCountLambdasWithFuel remaining;
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

def psKernelWhnfCountLambdas
    (current : PsKernelExpr)
    (argCount : Nat) :
    Prod PsKernelExpr Nat :=
  psKernelWhnfCountLambdasWithFuel
    (Nat.succ argCount)
    current
    argCount
    0

def psKernelWhnfCoreFinish
    (original : PsKernelExpr)
    (cheapProj : Bool)
    (result : PsKernelExpr)
    (state : PsKernelCheckerState) :
    Except String
      (Prod PsKernelExpr PsKernelCheckerState) :=
  if cheapProj then
    Except.ok
      (Prod.mk result state)
  else if psKernelWhnfCacheEligible original then
    let nextCache :=
      psKernelExprMapInsert
        state.whnfCore
        original
        result;
    Except.ok
      (Prod.mk
        result
        (psKernelCheckerStateWithWhnfCore
          state
          nextCache))
  else
    Except.ok
      (Prod.mk result state)

def psKernelWhnfFinish
    (original : PsKernelExpr)
    (result : PsKernelExpr)
    (state : PsKernelCheckerState) :
    Except String
      (Prod PsKernelExpr PsKernelCheckerState) :=
  if psKernelWhnfCacheEligible original then
    let nextCache :=
      psKernelExprMapInsert
        state.whnf
        original
        result;
    Except.ok
      (Prod.mk
        result
        (psKernelCheckerStateWithWhnf
          state
          nextCache))
  else
    Except.ok
      (Prod.mk result state)

def psKernelWhnfCoreWithFuel
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
        psKernelWhnfCoreWithFuel remaining;
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
                    if psKernelWhnfCacheEligible expr then
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
                              (Bool.or cheapRec cheapProj)
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
                                      (Bool.or cheapRec cheapProj)
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
                                          (Bool.or cheapRec cheapProj)
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
                                let consumedResult :=
                                  psKernelWhnfCountLambdas
                                    fn
                                    (psKernelExprListLength args);
                                let lastLam :=
                                  Prod.fst consumedResult;
                                let consumed :=
                                  Prod.snd consumedResult;
                                match lastLam with
                                | PsKernelExpr.lam _ _ body _ =>
                                    let selected :=
                                      psKernelExprListTake
                                        consumed
                                        args;
                                    let reducedBody :=
                                      psKernelExprInstantiateRev
                                        body
                                        selected;
                                    let rebuilt :=
                                      psKernelExprApplyArgsCheap
                                        reducedBody
                                        (psKernelExprListDrop
                                          consumed
                                          args);
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
                                          (Bool.or cheapRec cheapProj)
                                          (Prod.fst result)
                                          (Prod.snd result)
                                | _ =>
                                    Except.ok
                                      (Prod.mk expr state1)
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
                                        (Bool.or cheapRec cheapProj)
                                        (Prod.fst result)
                                        (Prod.snd result)
                    | _ =>
                        Except.ok
                          (Prod.mk expr state)
