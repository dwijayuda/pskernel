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
    (amount : Nat) : Prod PsKernelExpr Bool :=
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
        let fnResult := psKernelExprLiftLooseBVarsChanged fn start amount;
        let argResult := psKernelExprLiftLooseBVarsChanged arg start amount;
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
        let typeResult := psKernelExprLiftLooseBVarsChanged type start amount;
        let bodyResult := psKernelExprLiftLooseBVarsChanged body (Nat.succ start) amount;
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
        let typeResult := psKernelExprLiftLooseBVarsChanged type start amount;
        let bodyResult := psKernelExprLiftLooseBVarsChanged body (Nat.succ start) amount;
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
        let typeResult := psKernelExprLiftLooseBVarsChanged type start amount;
        let valueResult := psKernelExprLiftLooseBVarsChanged value start amount;
        let bodyResult := psKernelExprLiftLooseBVarsChanged body (Nat.succ start) amount;
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
        let bodyResult := psKernelExprLiftLooseBVarsChanged body start amount;
        if (Prod.snd bodyResult) then
          Prod.mk
            (PsKernelExpr.mdata
              metadata
              (Prod.fst bodyResult))
            true
        else
          Prod.mk expr false
    | PsKernelExpr.proj typeName index body =>
        let bodyResult := psKernelExprLiftLooseBVarsChanged body start amount;
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

namespace PsKernelSharing

@[inline] def liftAlgebra (amount : Nat) : Algebra Changed :=
  changedAlgebra fun e start =>
    if Nat.beq amount 0 then (e, false)
    else match e with
      | .bvar i => if psKernelNatGe i start then (.bvar (i + amount), true) else (e, false)
      | _ => (e, false)

theorem lift_zero (e : PsKernelExpr) (start : Nat) :
    psKernelExprLiftLooseBVarsChanged e start 0 = (e, false) := by
  cases e <;> rfl

theorem lift_fold (e : PsKernelExpr) (start amount : Nat) :
    fold (liftAlgebra amount) e start = psKernelExprLiftLooseBVarsChanged e start amount := by
  by_cases h : amount = 0
  · subst amount
    induction e generalizing start <;> simp_all [PsKernelSharing.fold, PsKernelSharing.changedAlgebra,
      PsKernelSharing.rebuildUnary, PsKernelSharing.rebuildBinary,
      PsKernelSharing.rebuildTernary, liftAlgebra, psKernelExprLiftLooseBVarsChanged, lift_zero]
  · induction e generalizing start <;> simp_all [PsKernelSharing.fold, PsKernelSharing.changedAlgebra,
      PsKernelSharing.rebuildUnary, PsKernelSharing.rebuildBinary,
      PsKernelSharing.rebuildTernary, liftAlgebra, psKernelExprLiftLooseBVarsChanged, h]

end PsKernelSharing

def psKernelExprLiftLooseBVarsChangedShared (e : PsKernelExpr) (start amount : Nat) :
    Prod PsKernelExpr Bool :=
  if Nat.beq amount 0 then (e, false)
  else if PsKernelSharing.small e then psKernelExprLiftLooseBVarsChanged e start amount
  else PsKernelSharing.run (PsKernelSharing.liftAlgebra amount) e start

@[csimp] theorem psKernelExprLiftLooseBVarsChanged_shared_eq :
    psKernelExprLiftLooseBVarsChanged = psKernelExprLiftLooseBVarsChangedShared := by
  funext e start amount
  cases amount with
  | zero => cases e <;> rfl
  | succ n =>
    simp [psKernelExprLiftLooseBVarsChangedShared,
      PsKernelSharing.run_eq, PsKernelSharing.lift_fold]

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
