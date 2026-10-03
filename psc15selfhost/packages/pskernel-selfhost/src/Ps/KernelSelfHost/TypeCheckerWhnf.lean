import Ps.KernelSelfHost.TypeCheckerPrimitives

def psKernelNoRecursorReduction
    (_context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (_expr : PsKernelExpr)
    (_cheapRec : Bool)
    (_cheapProj : Bool) :
    Except String
      (Prod
        (Option PsKernelExpr)
        PsKernelCheckerState) :=
  Except.ok
    (Prod.mk
      Option.none
      state)

def psKernelReduceQuotWith
    (publicWhnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String
        (Prod PsKernelExpr PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (expr : PsKernelExpr) :
    Except String
      (Prod
        (Option PsKernelExpr)
        PsKernelCheckerState) :=
  if context.environment.quotInitialized then
    let fn :=
      psKernelExprGetAppFn expr;
    match fn with
    | PsKernelExpr.const fnName _ =>
        let isLift :=
          psKernelNameEq
            fnName
            psKernelQuotLiftName;
        let isInd :=
          psKernelNameEq
            fnName
            psKernelQuotIndName;
        if isLift then
          let mkPos := 5;
          let argPos := 3;
          let args :=
            psKernelExprGetAppArgs expr;
          if
              Nat.ble
                (psKernelExprListLength args)
                mkPos then
            Except.ok
              (Prod.mk Option.none state)
          else
            match psKernelExprListGet args mkPos with
            | Option.none =>
                Except.ok
                  (Prod.mk Option.none state)
            | Option.some major =>
                match publicWhnf context state major with
                | Except.error error =>
                    Except.error error
                | Except.ok majorResult =>
                    let majorReduced :=
                      Prod.fst majorResult;
                    let state1 :=
                      Prod.snd majorResult;
                    match
                        psKernelExprGetAppFn
                          majorReduced with
                    | PsKernelExpr.const mkName _ =>
                        if
                            psKernelNameEq
                              mkName
                              psKernelQuotMkName then
                          if
                              Nat.beq
                                (psKernelExprGetAppNumArgs
                                  majorReduced)
                                3 then
                            let mkArgs :=
                              psKernelExprGetAppArgs
                                majorReduced;
                            match
                                psKernelExprListGet
                                  mkArgs
                                  2 with
                            | Option.none =>
                                Except.ok
                                  (Prod.mk
                                    Option.none
                                    state1)
                            | Option.some representative =>
                                match
                                    psKernelExprListGet
                                      args
                                      argPos with
                                | Option.none =>
                                    Except.ok
                                      (Prod.mk
                                        Option.none
                                        state1)
                                | Option.some fnValue =>
                                    let base :=
                                      PsKernelExpr.app
                                        fnValue
                                        representative;
                                    let remaining :=
                                      psKernelExprListDrop
                                        (Nat.succ mkPos)
                                        args;
                                    Except.ok
                                      (Prod.mk
                                        (Option.some
                                          (psKernelApplyArgs
                                            base
                                            remaining))
                                        state1)
                          else
                            Except.ok
                              (Prod.mk Option.none state1)
                        else
                          Except.ok
                            (Prod.mk Option.none state1)
                    | _ =>
                        Except.ok
                          (Prod.mk Option.none state1)
        else if isInd then
          let mkPos := 4;
          let argPos := 3;
          let args :=
            psKernelExprGetAppArgs expr;
          if
              Nat.ble
                (psKernelExprListLength args)
                mkPos then
            Except.ok
              (Prod.mk Option.none state)
          else
            match psKernelExprListGet args mkPos with
            | Option.none =>
                Except.ok
                  (Prod.mk Option.none state)
            | Option.some major =>
                match publicWhnf context state major with
                | Except.error error =>
                    Except.error error
                | Except.ok majorResult =>
                    let majorReduced :=
                      Prod.fst majorResult;
                    let state1 :=
                      Prod.snd majorResult;
                    match
                        psKernelExprGetAppFn
                          majorReduced with
                    | PsKernelExpr.const mkName _ =>
                        if
                            psKernelNameEq
                              mkName
                              psKernelQuotMkName then
                          if
                              Nat.beq
                                (psKernelExprGetAppNumArgs
                                  majorReduced)
                                3 then
                            let mkArgs :=
                              psKernelExprGetAppArgs
                                majorReduced;
                            match
                                psKernelExprListGet
                                  mkArgs
                                  2 with
                            | Option.none =>
                                Except.ok
                                  (Prod.mk
                                    Option.none
                                    state1)
                            | Option.some representative =>
                                match
                                    psKernelExprListGet
                                      args
                                      argPos with
                                | Option.none =>
                                    Except.ok
                                      (Prod.mk
                                        Option.none
                                        state1)
                                | Option.some fnValue =>
                                    let base :=
                                      PsKernelExpr.app
                                        fnValue
                                        representative;
                                    let remaining :=
                                      psKernelExprListDrop
                                        (Nat.succ mkPos)
                                        args;
                                    Except.ok
                                      (Prod.mk
                                        (Option.some
                                          (psKernelApplyArgs
                                            base
                                            remaining))
                                        state1)
                          else
                            Except.ok
                              (Prod.mk Option.none state1)
                        else
                          Except.ok
                            (Prod.mk Option.none state1)
                    | _ =>
                        Except.ok
                          (Prod.mk Option.none state1)
        else
          Except.ok
            (Prod.mk Option.none state)
    | _ =>
        Except.ok
          (Prod.mk Option.none state)
  else
    Except.ok
      (Prod.mk Option.none state)

def psKernelReduceNatWith
    (publicWhnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String
        (Prod PsKernelExpr PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (expr : PsKernelExpr) :
    Except String
      (Prod
        (Option PsKernelExpr)
        PsKernelCheckerState) :=
  match expr with
  | PsKernelExpr.app fn right =>
      match fn with
      | PsKernelExpr.const name levels =>
          match levels with
          | List.nil =>
              if
                  psKernelNameEq
                    name
                    psKernelNatSuccName then
                match
                    publicWhnf
                      context
                      state
                      right with
                | Except.error error =>
                    Except.error error
                | Except.ok reducedResult =>
                    let reduced :=
                      Prod.fst reducedResult;
                    let next :=
                      Prod.snd reducedResult;
                    match
                        psKernelExprNatLiteralValue
                          reduced with
                    | Option.none =>
                        Except.ok
                          (Prod.mk Option.none next)
                    | Option.some value =>
                        let result :=
                          Nat.succ value;
                        match
                            psKernelCheckNatSize
                              context.maxNatSize
                              result with
                        | Except.error error =>
                            Except.error error
                        | Except.ok _ =>
                            Except.ok
                              (Prod.mk
                                (Option.some
                                  (PsKernelExpr.lit
                                    (PsKernelLiteral.nat
                                      result)))
                                next)
              else
                Except.ok
                  (Prod.mk Option.none state)
          | List.cons _ _ =>
              Except.ok
                (Prod.mk Option.none state)
      | PsKernelExpr.app binaryHead left =>
          match binaryHead with
          | PsKernelExpr.const name levels =>
              match levels with
              | List.nil =>
                  match
                      publicWhnf
                        context
                        state
                        left with
                  | Except.error error =>
                      Except.error error
                  | Except.ok leftResult =>
                      let leftReduced :=
                        Prod.fst leftResult;
                      let state1 :=
                        Prod.snd leftResult;
                      match
                          publicWhnf
                            context
                            state1
                            right with
                      | Except.error error =>
                          Except.error error
                      | Except.ok rightResult =>
                          let rightReduced :=
                            Prod.fst rightResult;
                          let state2 :=
                            Prod.snd rightResult;
                          match
                              psKernelExprNatLiteralValue
                                leftReduced with
                          | Option.none =>
                              Except.ok
                                (Prod.mk
                                  Option.none
                                  state2)
                          | Option.some leftValue =>
                              match
                                  psKernelExprNatLiteralValue
                                    rightReduced with
                              | Option.none =>
                                  Except.ok
                                    (Prod.mk
                                      Option.none
                                      state2)
                              | Option.some rightValue =>
                                  match
                                      psKernelReduceNatBinary
                                        context.maxNatSize
                                        name
                                        leftValue
                                        rightValue with
                                  | Except.error error =>
                                      Except.error error
                                  | Except.ok result =>
                                      Except.ok
                                        (Prod.mk
                                          result
                                          state2)
              | List.cons _ _ =>
                  Except.ok
                    (Prod.mk Option.none state)
          | _ =>
              Except.ok
                (Prod.mk Option.none state)
      | _ =>
          Except.ok
            (Prod.mk Option.none state)
  | _ =>
      Except.ok
        (Prod.mk Option.none state)

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
    (Nat.succ (psKernelExprNodeCount current))
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
  else
    let nextCache :=
      psKernelExprMapInsert
        PsKernelExpr
        state.whnfCore
        original
        result;
    Except.ok
      (Prod.mk
        result
        (psKernelCheckerStateWithWhnfCore
          state
          nextCache))

def psKernelWhnfFinish
    (original : PsKernelExpr)
    (result : PsKernelExpr)
    (state : PsKernelCheckerState) :
    Except String
      (Prod PsKernelExpr PsKernelCheckerState) :=
  let nextCache :=
    psKernelExprMapInsert
      PsKernelExpr
      state.whnf
      original
      result;
  Except.ok
    (Prod.mk
      result
      (psKernelCheckerStateWithWhnf
        state
        nextCache))

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
                    psKernelExprMapGet
                      PsKernelExpr
                      state.whnfCore
                      expr with
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
                        let fn0 :=
                          psKernelExprGetAppFn expr;
                        let args :=
                          psKernelExprGetAppArgs expr;
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
                                          cheapProj
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
                                        cheapProj
                                        (Prod.fst result)
                                        (Prod.snd result)
                    | _ =>
                        Except.ok
                          (Prod.mk expr state)

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
                        psKernelExprMapGet
                          PsKernelExpr
                          state.whnf
                          expr with
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
                            match
                                psKernelReduceNatWith
                                  publicWhnf
                                  context
                                  state1
                                  core with
                            | Except.error error =>
                                Except.error error
                            | Except.ok natResult =>
                                match
                                    Prod.fst natResult with
                                | Option.some value =>
                                    psKernelWhnfFinish
                                      expr
                                      value
                                      (Prod.snd natResult)
                                | Option.none =>
                                    match
                                        psKernelUnfoldDefinition
                                          context
                                          core with
                                    | Option.none =>
                                        psKernelWhnfFinish
                                          expr
                                          core
                                          (Prod.snd natResult)
                                    | Option.some value =>
                                        match
                                            smaller
                                              reduceRecursor
                                              context
                                              (Prod.snd natResult)
                                              value with
                                        | Except.error error =>
                                            Except.error error
                                        | Except.ok result =>
                                            psKernelWhnfFinish
                                              expr
                                              (Prod.fst result)
                                              (Prod.snd result)
        | _ =>
            match
                psKernelExprMapGet
                  PsKernelExpr
                  state.whnf
                  expr with
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
                    match
                        psKernelReduceNatWith
                          publicWhnf
                          context
                          state1
                          core with
                    | Except.error error =>
                        Except.error error
                    | Except.ok natResult =>
                        match
                            Prod.fst natResult with
                        | Option.some value =>
                            psKernelWhnfFinish
                              expr
                              value
                              (Prod.snd natResult)
                        | Option.none =>
                            match
                                psKernelUnfoldDefinition
                                  context
                                  core with
                            | Option.none =>
                                psKernelWhnfFinish
                                  expr
                                  core
                                  (Prod.snd natResult)
                            | Option.some value =>
                                match
                                    smaller
                                      reduceRecursor
                                      context
                                      (Prod.snd natResult)
                                      value with
                                | Except.error error =>
                                    Except.error error
                                | Except.ok result =>
                                    psKernelWhnfFinish
                                      expr
                                      (Prod.fst result)
                                      (Prod.snd result)

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
