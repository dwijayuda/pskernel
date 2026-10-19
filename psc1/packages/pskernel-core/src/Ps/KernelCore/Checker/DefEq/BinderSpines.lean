import Ps.KernelCore.Checker.Recursor.Reduction

/-
Lean 4.34 binder/application comparison support.

This module contains the recursive structural machinery for:
- opening lambda/forall spines with shared locals;
- comparing application arguments;
- comparing expression lists;
- application congruence.

Binder display names and binder-info metadata are not semantic equality data.
The whole-spine shape is observable because kernel definitional equality is
algorithmic and intentionally incomplete.
-/

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
