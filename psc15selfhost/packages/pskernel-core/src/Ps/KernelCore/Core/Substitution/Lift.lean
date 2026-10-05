import Ps.KernelCore.Core.Substitution.ListOps

/-
Binder-aware lifting of loose de Bruijn variables.

This module is a theory-oriented split of the original portable Instantiate
implementation. Public definitions and PSC1 recursion shapes are preserved.
-/

def psKernelExprLiftLooseBVarsChangedWithFuel
    (fuel : Nat) :
    PsKernelExpr -> Nat -> Nat -> Prod PsKernelExpr Bool :=
  match fuel with
  | Nat.zero =>
      fun
        (expr : PsKernelExpr)
        (_start : Nat)
        (_amount : Nat) =>
        Prod.mk expr false
  | Nat.succ remaining =>
      let smaller :
          PsKernelExpr -> Nat -> Nat -> Prod PsKernelExpr Bool :=
        psKernelExprLiftLooseBVarsChangedWithFuel remaining;
      fun
        (expr : PsKernelExpr)
        (start : Nat)
        (amount : Nat) =>
        if Nat.beq amount 0 then
          Prod.mk expr false
        else
          match expr with
          | PsKernelExpr.bvar index =>
              if psKernelNatGe index start then
                Prod.mk
                  (PsKernelExpr.bvar
                    (Nat.add index amount))
                  true
              else
                Prod.mk expr false
          | PsKernelExpr.app fn arg =>
              let fnResult := smaller fn start amount;
              let argResult := smaller arg start amount;
              if (Prod.snd fnResult) then
                Prod.mk
                  (PsKernelExpr.app
                    (Prod.fst fnResult)
                    (Prod.fst argResult))
                  true
              else if (Prod.snd argResult) then
                Prod.mk
                  (PsKernelExpr.app
                    (Prod.fst fnResult)
                    (Prod.fst argResult))
                  true
              else
                Prod.mk expr false
          | PsKernelExpr.lam name type body binderInfo =>
              let typeResult := smaller type start amount;
              let bodyResult := smaller body (Nat.succ start) amount;
              if (Prod.snd typeResult) then
                Prod.mk
                  (PsKernelExpr.lam
                    name
                    (Prod.fst typeResult)
                    (Prod.fst bodyResult)
                    binderInfo)
                  true
              else if (Prod.snd bodyResult) then
                Prod.mk
                  (PsKernelExpr.lam
                    name
                    (Prod.fst typeResult)
                    (Prod.fst bodyResult)
                    binderInfo)
                  true
              else
                Prod.mk expr false
          | PsKernelExpr.forallE name type body binderInfo =>
              let typeResult := smaller type start amount;
              let bodyResult := smaller body (Nat.succ start) amount;
              if (Prod.snd typeResult) then
                Prod.mk
                  (PsKernelExpr.forallE
                    name
                    (Prod.fst typeResult)
                    (Prod.fst bodyResult)
                    binderInfo)
                  true
              else if (Prod.snd bodyResult) then
                Prod.mk
                  (PsKernelExpr.forallE
                    name
                    (Prod.fst typeResult)
                    (Prod.fst bodyResult)
                    binderInfo)
                  true
              else
                Prod.mk expr false
          | PsKernelExpr.letE name type value body nondep =>
              let typeResult := smaller type start amount;
              let valueResult := smaller value start amount;
              let bodyResult := smaller body (Nat.succ start) amount;
              if (Prod.snd typeResult) then
                Prod.mk
                  (PsKernelExpr.letE
                    name
                    (Prod.fst typeResult)
                    (Prod.fst valueResult)
                    (Prod.fst bodyResult)
                    nondep)
                  true
              else if (Prod.snd valueResult) then
                Prod.mk
                  (PsKernelExpr.letE
                    name
                    (Prod.fst typeResult)
                    (Prod.fst valueResult)
                    (Prod.fst bodyResult)
                    nondep)
                  true
              else if (Prod.snd bodyResult) then
                Prod.mk
                  (PsKernelExpr.letE
                    name
                    (Prod.fst typeResult)
                    (Prod.fst valueResult)
                    (Prod.fst bodyResult)
                    nondep)
                  true
              else
                Prod.mk expr false
          | PsKernelExpr.mdata metadata body =>
              let bodyResult := smaller body start amount;
              if (Prod.snd bodyResult) then
                Prod.mk
                  (PsKernelExpr.mdata
                    metadata
                    (Prod.fst bodyResult))
                  true
              else
                Prod.mk expr false
          | PsKernelExpr.proj typeName index body =>
              let bodyResult := smaller body start amount;
              if (Prod.snd bodyResult) then
                Prod.mk
                  (PsKernelExpr.proj
                    typeName
                    index
                    (Prod.fst bodyResult))
                  true
              else
                Prod.mk expr false
          | _ =>
              Prod.mk expr false

def psKernelExprLiftLooseBVarsChanged
    (expr : PsKernelExpr)
    (start : Nat)
    (amount : Nat) :
    Prod PsKernelExpr Bool :=
  -- The worker already returns this result for zero. Avoid counting the tree
  -- and constructing its fuel worker before reaching that same branch.
  if Nat.beq amount 0 then
    Prod.mk expr false
  else
    psKernelExprLiftLooseBVarsChangedWithFuel
      (Nat.succ (psKernelExprNodeCount expr))
      expr
      start
      amount

def psKernelExprLiftLooseBVars
    (expr : PsKernelExpr)
    (start : Nat)
    (amount : Nat) : PsKernelExpr :=
  Prod.fst
    (psKernelExprLiftLooseBVarsChanged
      expr
      start
      amount)

def psKernelExprLift
    (expr : PsKernelExpr)
    (amount : Nat) : PsKernelExpr :=
  psKernelExprLiftLooseBVars
    expr
    0
    amount
