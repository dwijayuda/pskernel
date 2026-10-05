import Ps.KernelCore.Core.Expr

/-
Portable expression-list helpers used by substitution and beta reduction.

This module is a theory-oriented split of the original portable Instantiate
implementation. Public definitions and PSC1 recursion shapes are preserved.
-/

def psKernelExprListGet
    (values : List PsKernelExpr) :
    Nat -> Option PsKernelExpr :=
  match values with
  | List.nil =>
      fun (_index : Nat) =>
        Option.none
  | List.cons head tail =>
      let smaller : Nat -> Option PsKernelExpr :=
        psKernelExprListGet tail;
      fun (index : Nat) =>
        match index with
        | Nat.zero =>
            Option.some head
        | Nat.succ remaining =>
            smaller remaining

def psKernelExprListIsEmpty
    (values : List PsKernelExpr) : Bool :=
  match values with
  | List.nil => true
  | List.cons _ _ => false

def psKernelExprListReverseWorker
    (values : List PsKernelExpr) :
    List PsKernelExpr -> List PsKernelExpr :=
  match values with
  | List.nil =>
      fun (acc : List PsKernelExpr) =>
        acc
  | List.cons head tail =>
      let smaller :
          List PsKernelExpr -> List PsKernelExpr :=
        psKernelExprListReverseWorker tail;
      fun (acc : List PsKernelExpr) =>
        smaller (List.cons head acc)

def psKernelExprListReverse
    (values : List PsKernelExpr) :
    List PsKernelExpr :=
  psKernelExprListReverseWorker
    values
    List.nil

def psKernelExprListTake
    (amount : Nat) :
    List PsKernelExpr -> List PsKernelExpr :=
  match amount with
  | Nat.zero =>
      fun (_values : List PsKernelExpr) =>
        List.nil
  | Nat.succ remaining =>
      let smaller :
          List PsKernelExpr -> List PsKernelExpr :=
        psKernelExprListTake remaining;
      fun (values : List PsKernelExpr) =>
        match values with
        | List.nil =>
            List.nil
        | List.cons head tail =>
            List.cons head (smaller tail)

def psKernelExprListDrop
    (amount : Nat) :
    List PsKernelExpr -> List PsKernelExpr :=
  match amount with
  | Nat.zero =>
      fun (values : List PsKernelExpr) =>
        values
  | Nat.succ remaining =>
      let smaller :
          List PsKernelExpr -> List PsKernelExpr :=
        psKernelExprListDrop remaining;
      fun (values : List PsKernelExpr) =>
        match values with
        | List.nil =>
            List.nil
        | List.cons _ tail =>
            smaller tail
