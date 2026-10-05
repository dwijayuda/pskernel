import Ps.KernelCore.Core.Substitution.Instantiate

/-
Cheap application construction and beta reduction helpers used by the kernel.

This module is a theory-oriented split of the original portable Instantiate
implementation. Public definitions and PSC1 recursion shapes are preserved.
-/

def psKernelExprApplyArgsCheapWorker
    (args : List PsKernelExpr) :
    PsKernelExpr -> PsKernelExpr :=
  match args with
  | List.nil =>
      fun (fn : PsKernelExpr) =>
        fn
  | List.cons arg rest =>
      let smaller :
          PsKernelExpr -> PsKernelExpr :=
        psKernelExprApplyArgsCheapWorker rest;
      fun (fn : PsKernelExpr) =>
        smaller
          (PsKernelExpr.app fn arg)

def psKernelExprApplyArgsCheap
    (fn : PsKernelExpr)
    (args : List PsKernelExpr) : PsKernelExpr :=
  psKernelExprApplyArgsCheapWorker
    args
    fn

def psKernelExprConsumeLambdaSpineWithFuel
    (fuel : Nat) :
    PsKernelExpr ->
    List PsKernelExpr ->
    Nat ->
    Prod PsKernelExpr Nat :=
  match fuel with
  | Nat.zero =>
      fun
        (fn : PsKernelExpr)
        (_args : List PsKernelExpr)
        (count : Nat) =>
        Prod.mk fn count
  | Nat.succ remaining =>
      let smaller :
          PsKernelExpr ->
          List PsKernelExpr ->
          Nat ->
          Prod PsKernelExpr Nat :=
        psKernelExprConsumeLambdaSpineWithFuel remaining;
      fun
        (fn : PsKernelExpr)
        (args : List PsKernelExpr)
        (count : Nat) =>
        match fn with
        | PsKernelExpr.lam _ _ body _ =>
            if
                psKernelNatLt
                  count
                  (psKernelExprListLength args) then
              smaller
                body
                args
                (Nat.succ count)
            else
              Prod.mk fn count
        | _ =>
            Prod.mk fn count

def psKernelExprConsumeLambdaSpine
    (fn : PsKernelExpr)
    (args : List PsKernelExpr)
    (count : Nat) :
    Prod PsKernelExpr Nat :=
  psKernelExprConsumeLambdaSpineWithFuel
    (Nat.succ (psKernelExprNodeCount fn))
    fn
    args
    count

def psKernelExprCheapBetaReduce
    (expr : PsKernelExpr) : PsKernelExpr :=
  match psKernelExprGetAppFn expr with
  | PsKernelExpr.lam _ _ _ _ =>
      let args :=
        psKernelExprGetAppArgs expr;
      let consumedResult :=
        psKernelExprConsumeLambdaSpine
          (psKernelExprGetAppFn expr)
          args
          0;
      let body := (Prod.fst consumedResult);
      let consumed := (Prod.snd consumedResult);
      if Nat.beq consumed 0 then
        expr
      else if psKernelExprHasLooseBVar body then
        match body with
        | PsKernelExpr.bvar index =>
            if psKernelNatLt index consumed then
              let selectedIndex :=
                Nat.sub
                  (Nat.sub consumed index)
                  1;
              match
                  psKernelExprListGet
                    args
                    selectedIndex with
              | Option.some selected =>
                  psKernelExprApplyArgsCheap
                    selected
                    (psKernelExprListDrop consumed args)
              | Option.none =>
                  expr
            else
              expr
        | _ =>
            expr
      else
        psKernelExprApplyArgsCheap
          body
          (psKernelExprListDrop consumed args)
  | _ =>
      expr
