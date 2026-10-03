import Ps.KernelSelfHost.TypeCheckerRecursor

def psKernelDefEqFinish
    (state : PsKernelCheckerState)
    (left : PsKernelExpr)
    (right : PsKernelExpr)
    (value : Bool) :
    Prod Bool PsKernelCheckerState :=
  if value then
    Prod.mk
      true
      (psKernelCheckerStateWithSuccess
        state
        (psKernelExprPairSetInsert
          state.success
          left
          right))
  else
    Prod.mk false state

def psKernelDefEqWithLocal
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (userName : PsKernelName)
    (type : PsKernelExpr)
    (binderInfo : PsKernelBinderInfo) :
    Prod
      PsKernelName
      (Prod
        PsKernelCheckerContext
        PsKernelCheckerState) :=
  let freshResult :=
    psKernelCheckerStateFreshName
      state
      userName;
  let fresh :=
    Prod.fst freshResult;
  let nextState :=
    Prod.snd freshResult;
  let localContext :=
    psKernelLocalContextAddLocal
      context.localContext
      fresh
      userName
      type
      binderInfo;
  Prod.mk
    fresh
    (Prod.mk
      (psKernelCheckerContextWithLocalContext
        context
        localContext)
      nextState)

def psKernelDefEqLambdaSpineWithFuel
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
        psKernelDefEqLambdaSpineWithFuel remaining;
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
                        let local :=
                          psKernelDefEqWithLocal
                            context
                            (Prod.snd domains)
                            rightName
                            rightOpened
                            rightBinderInfo;
                        let fresh :=
                          Prod.fst local;
                        let child :=
                          Prod.fst (Prod.snd local);
                        let nextState :=
                          Prod.snd (Prod.snd local);
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
                              List.nil))
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

def psKernelDefEqLambdaSpine
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
      (Prod Bool PsKernelCheckerState) :=
  psKernelDefEqLambdaSpineWithFuel
    (Nat.succ
      (Nat.add
        (psKernelExprNodeCount left)
        (psKernelExprNodeCount right)))
    defeq
    context
    state
    left
    right
    List.nil

def psKernelDefEqForallSpineWithFuel
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
        psKernelDefEqForallSpineWithFuel remaining;
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
                        let local :=
                          psKernelDefEqWithLocal
                            context
                            (Prod.snd domains)
                            rightName
                            rightOpened
                            rightBinderInfo;
                        let fresh :=
                          Prod.fst local;
                        let child :=
                          Prod.fst (Prod.snd local);
                        let nextState :=
                          Prod.snd (Prod.snd local);
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
                              List.nil))
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

def psKernelDefEqForallSpine
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
      (Prod Bool PsKernelCheckerState) :=
  psKernelDefEqForallSpineWithFuel
    (Nat.succ
      (Nat.add
        (psKernelExprNodeCount left)
        (psKernelExprNodeCount right)))
    defeq
    context
    state
    left
    right
    List.nil

def psKernelDefEqArgsWithFuel
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
        psKernelDefEqArgsWithFuel remaining;
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

def psKernelDefEqArgs
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
      (Prod Bool PsKernelCheckerState) :=
  psKernelDefEqArgsWithFuel
    (Nat.succ
      (Nat.add
        (psKernelExprNodeCount left)
        (psKernelExprNodeCount right)))
    defeq
    context
    state
    left
    right

def psKernelDefEqCompareExprListsWithFuel
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
        psKernelDefEqCompareExprListsWithFuel remaining;
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

def psKernelDefEqCompareExprLists
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
    (right : List PsKernelExpr) :
    Except String
      (Prod Bool PsKernelCheckerState) :=
  psKernelDefEqCompareExprListsWithFuel
    (Nat.succ
      (Nat.add
        (psKernelExprListLength left)
        (psKernelExprListLength right)))
    defeq
    context
    state
    left
    right

def psKernelDefEqApp
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
      (Prod Bool PsKernelCheckerState) :=
  match
      defeq
        context
        state
        (psKernelExprGetAppFn left)
        (psKernelExprGetAppFn right) with
  | Except.error error =>
      Except.error error
  | Except.ok headResult =>
      if Prod.fst headResult then
        let leftArgs :=
          psKernelExprGetAppArgs left;
        let rightArgs :=
          psKernelExprGetAppArgs right;
        if
            Nat.beq
              (psKernelExprListLength leftArgs)
              (psKernelExprListLength rightArgs) then
          psKernelDefEqCompareExprLists
            defeq
            context
            (Prod.snd headResult)
            leftArgs
            rightArgs
        else
          Except.ok
            (Prod.mk
              false
              (Prod.snd headResult))
      else
        Except.ok headResult

def psKernelDefEqQuick
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
  if psKernelExprEq left right then
    Except.ok
      (Prod.mk
        (Option.some true)
        state)
  else if
      psKernelExprPairSetContains
        state.success
        left
        right then
    Except.ok
      (Prod.mk
        (Option.some true)
        state)
  else
    match left with
    | PsKernelExpr.lam _ _ _ _ =>
        match right with
        | PsKernelExpr.lam _ _ _ _ =>
            match
                psKernelDefEqLambdaSpine
                  defeq
                  context
                  state
                  left
                  right with
            | Except.error error =>
                Except.error error
            | Except.ok result =>
                Except.ok
                  (Prod.mk
                    (Option.some
                      (Prod.fst result))
                    (Prod.snd result))
        | _ =>
            Except.ok
              (Prod.mk Option.none state)
    | PsKernelExpr.forallE _ _ _ _ =>
        match right with
        | PsKernelExpr.forallE _ _ _ _ =>
            match
                psKernelDefEqForallSpine
                  defeq
                  context
                  state
                  left
                  right with
            | Except.error error =>
                Except.error error
            | Except.ok result =>
                Except.ok
                  (Prod.mk
                    (Option.some
                      (Prod.fst result))
                    (Prod.snd result))
        | _ =>
            Except.ok
              (Prod.mk Option.none state)
    | PsKernelExpr.sort leftLevel =>
        match right with
        | PsKernelExpr.sort rightLevel =>
            Except.ok
              (Prod.mk
                (Option.some
                  (psKernelLevelEquivalent
                    leftLevel
                    rightLevel))
                state)
        | _ =>
            Except.ok
              (Prod.mk Option.none state)
    | PsKernelExpr.mdata _ leftBody =>
        match right with
        | PsKernelExpr.mdata _ rightBody =>
            match
                defeq
                  context
                  state
                  leftBody
                  rightBody with
            | Except.error error =>
                Except.error error
            | Except.ok result =>
                Except.ok
                  (Prod.mk
                    (Option.some
                      (Prod.fst result))
                    (Prod.snd result))
        | _ =>
            Except.ok
              (Prod.mk Option.none state)
    | PsKernelExpr.lit leftLiteral =>
        match right with
        | PsKernelExpr.lit rightLiteral =>
            Except.ok
              (Prod.mk
                (Option.some
                  (psKernelLiteralEq
                    leftLiteral
                    rightLiteral))
                state)
        | _ =>
            Except.ok
              (Prod.mk Option.none state)
    | _ =>
        Except.ok
          (Prod.mk Option.none state)

def psKernelLevelListsEquivalent
    (left : List PsKernelLevel) :
    List PsKernelLevel -> Bool :=
  match left with
  | List.nil =>
      fun (right : List PsKernelLevel) =>
        match right with
        | List.nil => true
        | List.cons _ _ => false
  | List.cons leftHead leftTail =>
      let smaller :=
        psKernelLevelListsEquivalent leftTail;
      fun (right : List PsKernelLevel) =>
        match right with
        | List.nil =>
            false
        | List.cons rightHead rightTail =>
            if
                psKernelLevelEquivalent
                  leftHead
                  rightHead then
              smaller rightTail
            else
              false

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
        PsKernelExpr
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
              PsKernelExpr
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

def psKernelDefEqLazyReductionAfterPred
    (continue :
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
                  match
                      psKernelDefEqLazyStep
                        defeq
                        coreWhnf
                        context
                        (Prod.snd rightNatResult)
                        left
                        right with
                  | Except.error error =>
                      Except.error error
                  | Except.ok stepResult =>
                      match Prod.fst stepResult with
                      | PsKernelDeltaStepResult.continue nextLeft nextRight =>
                          continue
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
          let continue :
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
                    continue
                    defeq
                    whnf
                    coreWhnf
                    context
                    state
                    left
                    right
          | Option.none =>
              psKernelDefEqLazyReductionAfterPred
                continue
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

def psKernelDefEqIsPropWith
    (inferType :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String
        (Prod PsKernelExpr PsKernelCheckerState))
    (whnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String
        (Prod PsKernelExpr PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (expr : PsKernelExpr) :
    Except String
      (Prod Bool PsKernelCheckerState) :=
  match inferType context state expr with
  | Except.error error =>
      Except.error error
  | Except.ok typeResult =>
      match
          whnf
            context
            (Prod.snd typeResult)
            (Prod.fst typeResult) with
      | Except.error error =>
          Except.error error
      | Except.ok reducedResult =>
          match Prod.fst reducedResult with
          | PsKernelExpr.sort level =>
              Except.ok
                (Prod.mk
                  (psKernelLevelNormalizesToZero level)
                  (Prod.snd reducedResult))
          | _ =>
              Except.error "expected sort"

def psKernelDefEqEtaStructFieldsWithFuel
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
        psKernelDefEqEtaStructFieldsWithFuel remaining;
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

def psKernelDefEqEtaStructCoreWith
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String
        (Prod Bool PsKernelCheckerState))
    (inferType :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String
        (Prod PsKernelExpr PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (term : PsKernelExpr)
    (structureValue : PsKernelExpr) :
    Except String
      (Prod Bool PsKernelCheckerState) :=
  let fn :=
    psKernelExprGetAppFn structureValue;
  let args :=
    psKernelExprGetAppArgs structureValue;
  match fn with
  | PsKernelExpr.const ctorName _ =>
      match
          psKernelEnvironmentFind
            context.environment
            ctorName with
      | Option.some info =>
          match info with
          | PsKernelConstantInfo.ctorInfo ctor =>
              if
                  Nat.beq
                    (psKernelExprListLength args)
                    (Nat.add
                      ctor.numParams
                      ctor.numFields) then
                if
                    psKernelEnvironmentIsNonRecStructure
                      context.environment
                      ctor.induct then
                  match inferType context state term with
                  | Except.error error =>
                      Except.error error
                  | Except.ok termType =>
                      match
                          inferType
                            context
                            (Prod.snd termType)
                            structureValue with
                      | Except.error error =>
                          Except.error error
                      | Except.ok structureType =>
                          match
                              defeq
                                context
                                (Prod.snd structureType)
                                (Prod.fst termType)
                                (Prod.fst structureType) with
                          | Except.error error =>
                              Except.error error
                          | Except.ok typesEqual =>
                              if Prod.fst typesEqual then
                                psKernelDefEqEtaStructFieldsWithFuel
                                  (Nat.succ ctor.numFields)
                                  defeq
                                  context
                                  (Prod.snd typesEqual)
                                  ctor.induct
                                  term
                                  args
                                  ctor.numParams
                                  0
                              else
                                Except.ok typesEqual
                else
                  Except.ok
                    (Prod.mk false state)
              else
                Except.ok
                  (Prod.mk false state)
          | _ =>
              Except.ok
                (Prod.mk false state)
      | Option.none =>
          Except.ok
            (Prod.mk false state)
  | _ =>
      Except.ok
        (Prod.mk false state)

def psKernelDefEqEtaStructWith
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String
        (Prod Bool PsKernelCheckerState))
    (inferType :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String
        (Prod PsKernelExpr PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (left : PsKernelExpr)
    (right : PsKernelExpr) :
    Except String
      (Prod Bool PsKernelCheckerState) :=
  match
      psKernelDefEqEtaStructCoreWith
        defeq
        inferType
        context
        state
        left
        right with
  | Except.error error =>
      Except.error error
  | Except.ok first =>
      if Prod.fst first then
        Except.ok first
      else
        psKernelDefEqEtaStructCoreWith
          defeq
          inferType
          context
          (Prod.snd first)
          right
          left

def psKernelDefEqStringLitExpansionCoreWith
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
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (left : PsKernelExpr)
    (right : PsKernelExpr) :
    Except String
      (Prod
        (Option Bool)
        PsKernelCheckerState) :=
  match left with
  | PsKernelExpr.lit literal =>
      match literal with
      | PsKernelLiteral.str value =>
          if psKernelExprIsStringOfListApp right then
            match
                whnf
                  context
                  state
                  (psKernelStringLitToConstructor value) with
            | Except.error error =>
                Except.error error
            | Except.ok expanded =>
                match
                    defeq
                      context
                      (Prod.snd expanded)
                      (Prod.fst expanded)
                      right with
                | Except.error error =>
                    Except.error error
                | Except.ok result =>
                    Except.ok
                      (Prod.mk
                        (Option.some
                          (Prod.fst result))
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

def psKernelDefEqStringLitExpansionWith
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
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (left : PsKernelExpr)
    (right : PsKernelExpr) :
    Except String
      (Prod
        (Option Bool)
        PsKernelCheckerState) :=
  match
      psKernelDefEqStringLitExpansionCoreWith
        defeq
        whnf
        context
        state
        left
        right with
  | Except.error error =>
      Except.error error
  | Except.ok first =>
      match Prod.fst first with
      | Option.some value =>
          Except.ok
            (Prod.mk
              (Option.some value)
              (Prod.snd first))
      | Option.none =>
          psKernelDefEqStringLitExpansionCoreWith
            defeq
            whnf
            context
            (Prod.snd first)
            right
            left

def psKernelDefEqUnitLikeWith
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String
        (Prod Bool PsKernelCheckerState))
    (inferType :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String
        (Prod PsKernelExpr PsKernelCheckerState))
    (whnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String
        (Prod PsKernelExpr PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (left : PsKernelExpr)
    (right : PsKernelExpr) :
    Except String
      (Prod Bool PsKernelCheckerState) :=
  match inferType context state left with
  | Except.error error =>
      Except.error error
  | Except.ok leftTypeResult =>
      match
          whnf
            context
            (Prod.snd leftTypeResult)
            (Prod.fst leftTypeResult) with
      | Except.error error =>
          Except.error error
      | Except.ok reducedTypeResult =>
          let reducedType :=
            Prod.fst reducedTypeResult;
          match psKernelExprGetAppFn reducedType with
          | PsKernelExpr.const inductName _ =>
              if
                  psKernelEnvironmentIsNonRecStructure
                    context.environment
                    inductName then
                match
                    psKernelEnvironmentFind
                      context.environment
                      inductName with
                | Option.some info =>
                    match info with
                    | PsKernelConstantInfo.inductInfo inductInfo =>
                        match inductInfo.ctors with
                        | List.cons ctorName ctorTail =>
                            match ctorTail with
                            | List.nil =>
                                match
                                    psKernelEnvironmentFind
                                      context.environment
                                      ctorName with
                                | Option.some ctorValue =>
                                    match ctorValue with
                                    | PsKernelConstantInfo.ctorInfo ctor =>
                                        if Nat.beq ctor.numFields 0 then
                                          match
                                              inferType
                                                context
                                                (Prod.snd reducedTypeResult)
                                                right with
                                          | Except.error error =>
                                              Except.error error
                                          | Except.ok rightTypeResult =>
                                              defeq
                                                context
                                                (Prod.snd rightTypeResult)
                                                reducedType
                                                (Prod.fst rightTypeResult)
                                        else
                                          Except.ok
                                            (Prod.mk
                                              false
                                              (Prod.snd reducedTypeResult))
                                    | _ =>
                                        Except.ok
                                          (Prod.mk
                                            false
                                            (Prod.snd reducedTypeResult))
                                | Option.none =>
                                    Except.ok
                                      (Prod.mk
                                        false
                                        (Prod.snd reducedTypeResult))
                            | List.cons _ _ =>
                                Except.ok
                                  (Prod.mk
                                    false
                                    (Prod.snd reducedTypeResult))
                        | List.nil =>
                            Except.ok
                              (Prod.mk
                                false
                                (Prod.snd reducedTypeResult))
                    | _ =>
                        Except.ok
                          (Prod.mk
                            false
                            (Prod.snd reducedTypeResult))
                | Option.none =>
                    Except.ok
                      (Prod.mk
                        false
                        (Prod.snd reducedTypeResult))
              else
                Except.ok
                  (Prod.mk
                    false
                    (Prod.snd reducedTypeResult))
          | _ =>
              Except.ok
                (Prod.mk
                  false
                  (Prod.snd reducedTypeResult))
