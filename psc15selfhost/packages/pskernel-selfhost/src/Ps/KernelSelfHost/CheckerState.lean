import Ps.KernelSelfHost.Expr

structure PsKernelExprMap (alpha : Type) where
  entries : List (Prod PsKernelExpr alpha)

def psKernelExprMapEmpty
    (alpha : Type) :
    PsKernelExprMap alpha :=
  {
    entries := List.nil
  }

def psKernelExprMapGetIn
    (alpha : Type)
    (expr : PsKernelExpr)
    (entries : List (Prod PsKernelExpr alpha)) :
    Option alpha :=
  match entries with
  | List.nil =>
      Option.none
  | List.cons entry rest =>
      if
          psKernelExprEq
            (Prod.fst entry)
            expr then
        Option.some (Prod.snd entry)
      else
        psKernelExprMapGetIn
          alpha
          expr
          rest

def psKernelExprMapGet
    (alpha : Type)
    (cache : PsKernelExprMap alpha)
    (expr : PsKernelExpr) :
    Option alpha :=
  psKernelExprMapGetIn
    alpha
    expr
    cache.entries

def psKernelExprMapInsertIn
    (alpha : Type)
    (expr : PsKernelExpr)
    (value : alpha)
    (entries : List (Prod PsKernelExpr alpha)) :
    List (Prod PsKernelExpr alpha) :=
  match entries with
  | List.nil =>
      List.cons
        (Prod.mk expr value)
        List.nil
  | List.cons entry rest =>
      if
          psKernelExprEq
            (Prod.fst entry)
            expr then
        List.cons
          (Prod.mk expr value)
          rest
      else
        List.cons
          entry
          (psKernelExprMapInsertIn
            alpha
            expr
            value
            rest)

def psKernelExprMapInsert
    (alpha : Type)
    (cache : PsKernelExprMap alpha)
    (expr : PsKernelExpr)
    (value : alpha) :
    PsKernelExprMap alpha :=
  {
    entries :=
      psKernelExprMapInsertIn
        alpha
        expr
        value
        cache.entries
  }

structure PsKernelExprPairSet where
  entries : List (Prod PsKernelExpr PsKernelExpr)

def psKernelExprPairSetEmpty :
    PsKernelExprPairSet :=
  {
    entries := List.nil
  }

def psKernelExprPairEq
    (left : PsKernelExpr)
    (right : PsKernelExpr)
    (entry : Prod PsKernelExpr PsKernelExpr) :
    Bool :=
  let first := Prod.fst entry;
  let second := Prod.snd entry;
  if psKernelExprEq first left then
    psKernelExprEq second right
  else if psKernelExprEq first right then
    psKernelExprEq second left
  else
    false

def psKernelExprPairSetContainsIn
    (left : PsKernelExpr)
    (right : PsKernelExpr)
    (entries : List (Prod PsKernelExpr PsKernelExpr)) :
    Bool :=
  match entries with
  | List.nil =>
      false
  | List.cons entry rest =>
      if
          psKernelExprPairEq
            left
            right
            entry then
        true
      else
        psKernelExprPairSetContainsIn
          left
          right
          rest

def psKernelExprPairSetContains
    (set : PsKernelExprPairSet)
    (left : PsKernelExpr)
    (right : PsKernelExpr) :
    Bool :=
  psKernelExprPairSetContainsIn
    left
    right
    set.entries

def psKernelExprPairSetInsert
    (set : PsKernelExprPairSet)
    (left : PsKernelExpr)
    (right : PsKernelExpr) :
    PsKernelExprPairSet :=
  if psKernelExprPairSetContains set left right then
    set
  else
    {
      entries :=
        List.cons
          (Prod.mk left right)
          set.entries
    }

structure PsKernelCheckerState where
  nextFresh : Nat
  inferOnly : PsKernelExprMap PsKernelExpr
  checkedInfer : PsKernelExprMap PsKernelExpr
  whnfCore : PsKernelExprMap PsKernelExpr
  whnf : PsKernelExprMap PsKernelExpr
  unfold : PsKernelExprMap PsKernelExpr
  success : PsKernelExprPairSet
  failure : PsKernelExprPairSet

def psKernelCheckerStateEmpty :
    PsKernelCheckerState :=
  {
    nextFresh := 0
    inferOnly := psKernelExprMapEmpty PsKernelExpr
    checkedInfer := psKernelExprMapEmpty PsKernelExpr
    whnfCore := psKernelExprMapEmpty PsKernelExpr
    whnf := psKernelExprMapEmpty PsKernelExpr
    unfold := psKernelExprMapEmpty PsKernelExpr
    success := psKernelExprPairSetEmpty
    failure := psKernelExprPairSetEmpty
  }

def psKernelCheckerStateFreshName
    (state : PsKernelCheckerState)
    (base : PsKernelName) :
    Prod PsKernelName PsKernelCheckerState :=
  let name :=
    PsKernelName.num
      base
      state.nextFresh;
  Prod.mk
    name
    {
      nextFresh := Nat.succ state.nextFresh
      inferOnly := state.inferOnly
      checkedInfer := state.checkedInfer
      whnfCore := state.whnfCore
      whnf := state.whnf
      unfold := state.unfold
      success := state.success
      failure := state.failure
    }
