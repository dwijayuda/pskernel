import Ps.KernelCore.Core.Substitution.Lift

/-
Total, fuel-free reference semantics for loose de Bruijn lifting.

The production kernel uses a fuel-bounded worker so it remains portable through
the PSC1 self-host profile. This definition is Assurance Plane only: it gives
the structural operation that the production worker must refine.
-/

def psKernelExprLiftLooseBVarsReferenceChanged
    (expr : PsKernelExpr)
    (start amount : Nat) :
    Prod PsKernelExpr Bool :=
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
        let fnResult :=
          psKernelExprLiftLooseBVarsReferenceChanged
            fn start amount
        let argResult :=
          psKernelExprLiftLooseBVarsReferenceChanged
            arg start amount
        if Prod.snd fnResult then
          Prod.mk
            (PsKernelExpr.app
              (Prod.fst fnResult)
              (Prod.fst argResult))
            true
        else if Prod.snd argResult then
          Prod.mk
            (PsKernelExpr.app
              (Prod.fst fnResult)
              (Prod.fst argResult))
            true
        else
          Prod.mk expr false
    | PsKernelExpr.lam name type body binderInfo =>
        let typeResult :=
          psKernelExprLiftLooseBVarsReferenceChanged
            type start amount
        let bodyResult :=
          psKernelExprLiftLooseBVarsReferenceChanged
            body (Nat.succ start) amount
        if Prod.snd typeResult then
          Prod.mk
            (PsKernelExpr.lam
              name
              (Prod.fst typeResult)
              (Prod.fst bodyResult)
              binderInfo)
            true
        else if Prod.snd bodyResult then
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
        let typeResult :=
          psKernelExprLiftLooseBVarsReferenceChanged
            type start amount
        let bodyResult :=
          psKernelExprLiftLooseBVarsReferenceChanged
            body (Nat.succ start) amount
        if Prod.snd typeResult then
          Prod.mk
            (PsKernelExpr.forallE
              name
              (Prod.fst typeResult)
              (Prod.fst bodyResult)
              binderInfo)
            true
        else if Prod.snd bodyResult then
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
        let typeResult :=
          psKernelExprLiftLooseBVarsReferenceChanged
            type start amount
        let valueResult :=
          psKernelExprLiftLooseBVarsReferenceChanged
            value start amount
        let bodyResult :=
          psKernelExprLiftLooseBVarsReferenceChanged
            body (Nat.succ start) amount
        if Prod.snd typeResult then
          Prod.mk
            (PsKernelExpr.letE
              name
              (Prod.fst typeResult)
              (Prod.fst valueResult)
              (Prod.fst bodyResult)
              nondep)
            true
        else if Prod.snd valueResult then
          Prod.mk
            (PsKernelExpr.letE
              name
              (Prod.fst typeResult)
              (Prod.fst valueResult)
              (Prod.fst bodyResult)
              nondep)
            true
        else if Prod.snd bodyResult then
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
        let bodyResult :=
          psKernelExprLiftLooseBVarsReferenceChanged
            body start amount
        if Prod.snd bodyResult then
          Prod.mk
            (PsKernelExpr.mdata
              metadata
              (Prod.fst bodyResult))
            true
        else
          Prod.mk expr false
    | PsKernelExpr.proj typeName index body =>
        let bodyResult :=
          psKernelExprLiftLooseBVarsReferenceChanged
            body start amount
        if Prod.snd bodyResult then
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
termination_by expr

def psKernelExprLiftLooseBVarsReference
    (expr : PsKernelExpr)
    (start amount : Nat) :
    PsKernelExpr :=
  Prod.fst
    (psKernelExprLiftLooseBVarsReferenceChanged
      expr start amount)


theorem psKernelExprLiftLooseBVarsReferenceChanged_zero_amount
    (expr : PsKernelExpr)
    (start : Nat) :
    psKernelExprLiftLooseBVarsReferenceChanged expr start 0 =
      Prod.mk expr false := by
  cases expr <;>
    simp [psKernelExprLiftLooseBVarsReferenceChanged]
