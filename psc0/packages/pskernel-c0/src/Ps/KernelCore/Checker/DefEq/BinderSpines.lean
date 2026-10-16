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
    if psKernelSemanticPairCacheEligible left right then
      Prod.mk true
        (psKernelCheckerStateWithSuccess state
          (psKernelExprPairSetInsert state.success left right))
    else Prod.mk true state
  else Prod.mk false state

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

/-
DefEq spine recursion budgets are bounded by the shape of the traversal,
not by the number of nodes in binder domains or application arguments.
The old whole-expression node-count prepasses revisit arbitrarily large,
possibly shared subtrees even when the worker only descends along a spine.
The extra successor covers the terminal mismatched/non-binder comparison;
it preserves the exact old worker's budget and error behavior.
-/
def psKernelC0LambdaSpineLength : PsKernelExpr → Nat
  | .lam _ _ body _ => Nat.succ (psKernelC0LambdaSpineLength body)
  | _ => 0

def psKernelC0ForallSpineLength : PsKernelExpr → Nat
  | .forallE _ _ body _ => Nat.succ (psKernelC0ForallSpineLength body)
  | _ => 0

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
    List Nat ->
    List Nat ->
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
        (_subst : List PsKernelExpr)
        (_leftRanges : List Nat)
        (_rightRanges : List Nat) =>
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
        (subst : List PsKernelExpr)
        (leftRanges : List Nat)
        (rightRanges : List Nat) =>
        match left with
        | PsKernelExpr.lam _ leftDomain leftBody _ =>
            match right with
            | PsKernelExpr.lam rightName rightDomain rightBody rightBinderInfo =>
                let leftOpened :=
                  psKernelExprInstantiate
                    leftDomain
                    subst;
                let rightOpened :=
                  psKernelExprInstantiate
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
                      let (openLocal, nextLeftRanges, nextRightRanges) :=
                        match leftRanges, rightRanges with
                        | leftRange :: leftTail, rightRange :: rightTail =>
                            (leftRange != 0 || rightRange != 0,
                             leftTail, rightTail)
                        | _, _ =>
                            (psKernelExprHasLooseBVar leftBody ||
                             psKernelExprHasLooseBVar rightBody, [], [])
                      if openLocal then
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
                        match smaller
                            defeq child nextState leftBody rightBody
                            (List.cons (PsKernelExpr.fvar fresh) subst)
                            nextLeftRanges nextRightRanges with
                        | Except.error error => Except.error error
                        | Except.ok childResult =>
                            Except.ok (Prod.mk childResult.fst
                              (psKernelCheckerStateExitLocalScope
                                nextState childResult.snd))
                      else
                        smaller
                          defeq
                          context
                          (Prod.snd domains)
                          leftBody
                          rightBody
                          (List.cons (PsKernelExpr.sort PsKernelLevel.zero) subst)
                          nextLeftRanges
                          nextRightRanges
                    else
                      Except.ok
                        (Prod.mk
                          false
                          (Prod.snd domains))
            | _ =>
                defeq
                  context
                  state
                  (psKernelExprInstantiate left subst)
                  (psKernelExprInstantiate right subst)
        | _ =>
            defeq
              context
              state
              (psKernelExprInstantiate left subst)
              (psKernelExprInstantiate right subst)

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
  let summaryDepth := 12
  let (leftRanges, rightRanges) :=
    if psKernelC0HasBinderPrefix summaryDepth true left &&
        psKernelC0HasBinderPrefix summaryDepth true right then
      match psKernelC0BinderBodyRangesWithFuel 1024 left,
            psKernelC0BinderBodyRangesWithFuel 1024 right with
      | some (_, a), some (_, b) => (a, b)
      | _, _ => ([], [])
    else
      ([], [])
  psKernelDefEqLambdaSpineWithFuel
    (Nat.succ
      (Nat.add
        (psKernelC0LambdaSpineLength left)
        (psKernelC0LambdaSpineLength right)))
    defeq
    context
    state
    left
    right
    List.nil
    leftRanges
    rightRanges

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
    List Nat ->
    List Nat ->
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
        (_subst : List PsKernelExpr)
        (_leftRanges : List Nat)
        (_rightRanges : List Nat) =>
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
        (subst : List PsKernelExpr)
        (leftRanges : List Nat)
        (rightRanges : List Nat) =>
        match left with
        | PsKernelExpr.forallE _ leftDomain leftBody _ =>
            match right with
            | PsKernelExpr.forallE rightName rightDomain rightBody rightBinderInfo =>
                let leftOpened :=
                  psKernelExprInstantiate
                    leftDomain
                    subst;
                let rightOpened :=
                  psKernelExprInstantiate
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
                      let (openLocal, nextLeftRanges, nextRightRanges) :=
                        match leftRanges, rightRanges with
                        | leftRange :: leftTail, rightRange :: rightTail =>
                            (leftRange != 0 || rightRange != 0,
                             leftTail, rightTail)
                        | _, _ =>
                            (psKernelExprHasLooseBVar leftBody ||
                             psKernelExprHasLooseBVar rightBody, [], [])
                      if openLocal then
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
                        match smaller
                            defeq child nextState leftBody rightBody
                            (List.cons (PsKernelExpr.fvar fresh) subst)
                            nextLeftRanges nextRightRanges with
                        | Except.error error => Except.error error
                        | Except.ok childResult =>
                            Except.ok (Prod.mk childResult.fst
                              (psKernelCheckerStateExitLocalScope
                                nextState childResult.snd))
                      else
                        smaller
                          defeq
                          context
                          (Prod.snd domains)
                          leftBody
                          rightBody
                          (List.cons (PsKernelExpr.sort PsKernelLevel.zero) subst)
                          nextLeftRanges
                          nextRightRanges
                    else
                      Except.ok
                        (Prod.mk
                          false
                          (Prod.snd domains))
            | _ =>
                defeq
                  context
                  state
                  (psKernelExprInstantiate left subst)
                  (psKernelExprInstantiate right subst)
        | _ =>
            defeq
              context
              state
              (psKernelExprInstantiate left subst)
              (psKernelExprInstantiate right subst)

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
  let summaryDepth := 12
  let (leftRanges, rightRanges) :=
    if psKernelC0HasBinderPrefix summaryDepth false left &&
        psKernelC0HasBinderPrefix summaryDepth false right then
      match psKernelC0BinderBodyRangesWithFuel 1024 left,
            psKernelC0BinderBodyRangesWithFuel 1024 right with
      | some (_, a), some (_, b) => (a, b)
      | _, _ => ([], [])
    else
      ([], [])
  psKernelDefEqForallSpineWithFuel
    (Nat.succ
      (Nat.add
        (psKernelC0ForallSpineLength left)
        (psKernelC0ForallSpineLength right)))
    defeq
    context
    state
    left
    right
    List.nil
    leftRanges
    rightRanges

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
        (psKernelExprGetAppNumArgs left)
        (psKernelExprGetAppNumArgs right)))
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
          -- The list lengths are already known from the shape guard.
          -- Pass the same exact historical sufficient fuel, without walking
          -- both argument lists a second time.
          psKernelDefEqCompareExprListsWithFuel
            (Nat.succ (Nat.add
              (psKernelExprListLength leftArgs)
              (psKernelExprListLength rightArgs)))
            defeq context (Prod.snd headResult) leftArgs rightArgs
        else
          Except.ok
            (Prod.mk
              false
              (Prod.snd headResult))
      else
        Except.ok headResult
