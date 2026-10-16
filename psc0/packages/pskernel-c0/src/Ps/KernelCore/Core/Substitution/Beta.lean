import Ps.KernelCore.Core.Substitution.Instantiate
import Ps.KernelCore.Architecture.CertifiedInstantiateMemo

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

/-
C0 linear lambda-spine consumption.

The historical wrapper first traversed the full function tree to count nodes
and then recomputed the argument-list length for each consumed lambda. The
argument list itself is the exact bound, so consume it structurally once.
The count parameter remains compatible with callers that already consumed a
prefix: drop those previously consumed arguments before proceeding.
-/
def psKernelC0ConsumeLambdaSpineLinear
    (fn : PsKernelExpr)
    (args : List PsKernelExpr)
    (count : Nat) : Prod PsKernelExpr Nat :=
  match args with
  | List.nil => Prod.mk fn count
  | List.cons _ rest =>
      match fn with
      | PsKernelExpr.lam _ _ body _ =>
          psKernelC0ConsumeLambdaSpineLinear body rest (Nat.succ count)
      | _ => Prod.mk fn count

def psKernelExprConsumeLambdaSpine
    (fn : PsKernelExpr)
    (args : List PsKernelExpr)
    (count : Nat) :
    Prod PsKernelExpr Nat :=
  psKernelC0ConsumeLambdaSpineLinear
    fn
    (List.drop count args)
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


/-
C0 portable beta-spine plan.

The old WHNF beta path performed an entire lambda-body node count, lambda
spine counting, selected-argument take, selected-argument reversal, and
remaining-argument drop. This executable plan consumes the argument list
once, inspecting at most one lambda per selected argument. The returned
selected arguments are already in de Bruijn instantiation order (reversed).

Only the C0 implementation imports this optimization. The source profile
uses inductives, List, Prod, Option and structural recursion so that the
same .lean implementation can be translated by the future self-host target.
-/

def psKernelC0BetaSpineWorker
    (args : List PsKernelExpr) :
    PsKernelExpr ->
    List PsKernelExpr ->
    Option
      (Prod
        PsKernelExpr
        (Prod
          (List PsKernelExpr)
          (List PsKernelExpr))) :=
  match args with
  | List.nil =>
      fun
        (_fn : PsKernelExpr)
        (_reversed : List PsKernelExpr) =>
        Option.none
  | List.cons arg rest =>
      let smaller :
          PsKernelExpr ->
          List PsKernelExpr ->
          Option
            (Prod
              PsKernelExpr
              (Prod
                (List PsKernelExpr)
                (List PsKernelExpr))) :=
        psKernelC0BetaSpineWorker rest;
      fun
        (fn : PsKernelExpr)
        (reversed : List PsKernelExpr) =>
        match fn with
        | PsKernelExpr.lam _ _ body _ =>
            let selected := List.cons arg reversed;
            match rest with
            | List.nil =>
                Option.some
                  (Prod.mk body
                    (Prod.mk selected List.nil))
            | List.cons _ _ =>
                match body with
                | PsKernelExpr.lam _ _ _ _ =>
                    smaller body selected
                | _ =>
                    Option.some
                      (Prod.mk body
                        (Prod.mk selected rest))
        | _ =>
            Option.none

def psKernelC0BetaSpinePlan
    (fn : PsKernelExpr)
    (args : List PsKernelExpr) :
    Option
      (Prod
        PsKernelExpr
        (Prod
          (List PsKernelExpr)
          (List PsKernelExpr))) :=
  psKernelC0BetaSpineWorker args fn List.nil

def psKernelC0BetaSpineApply
    (plan :
      Prod PsKernelExpr
        (Prod
          (List PsKernelExpr)
          (List PsKernelExpr))) :
    PsKernelExpr :=
  let body := Prod.fst plan;
  let selectedRev := Prod.fst (Prod.snd plan);
  let remaining := Prod.snd (Prod.snd plan);
  -- C0 single-binder specialization. The common one-argument beta case
  -- avoids the generic list-substitution interpreter; multi-binder spines
  -- retain the existing simultaneous instantiation order.
  let opened :=
    match selectedRev with
    | List.cons replacement List.nil =>
        psKernelExprInstantiate1 body replacement
    | _ =>
        psKernelExprInstantiate body selectedRev;
  psKernelExprApplyArgsCheap
    opened
    remaining
