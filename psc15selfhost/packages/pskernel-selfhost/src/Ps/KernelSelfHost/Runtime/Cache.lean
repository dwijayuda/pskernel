import Ps.KernelSelfHost.Expr

structure PsKernelExprMap where
  entries : List (Prod PsKernelExpr PsKernelExpr)

def psKernelExprMapEmpty :
    PsKernelExprMap :=
  {
    entries := List.nil
  }

def psKernelExprMapGetIn
    (expr : PsKernelExpr)
    (entries : List (Prod PsKernelExpr PsKernelExpr)) :
    Option PsKernelExpr :=
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
          expr
          rest

def psKernelExprMapGet
    (cache : PsKernelExprMap)
    (expr : PsKernelExpr) :
    Option PsKernelExpr :=
  psKernelExprMapGetIn
    expr
    cache.entries

def psKernelExprMapInsertIn
    (expr : PsKernelExpr)
    (value : PsKernelExpr)
    (entries : List (Prod PsKernelExpr PsKernelExpr)) :
    List (Prod PsKernelExpr PsKernelExpr) :=
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
            expr
            value
            rest)

def psKernelExprMapInsert
    (cache : PsKernelExprMap)
    (expr : PsKernelExpr)
    (value : PsKernelExpr) :
    PsKernelExprMap :=
  {
    entries :=
      psKernelExprMapInsertIn
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

