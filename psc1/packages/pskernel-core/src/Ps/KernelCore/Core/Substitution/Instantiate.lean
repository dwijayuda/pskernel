import Ps.KernelCore.Core.Substitution.Lift

/-
Capture-avoiding de Bruijn instantiation. Non-dependent instantiate1 returns the codomain unchanged.

This module is a theory-oriented split of the original portable Instantiate
implementation. Public definitions and PSC1 recursion shapes are preserved.
-/

def psKernelExprInstantiateAtChangedWithFuel
    (fuel : Nat) :
    PsKernelExpr ->
    Nat ->
    List PsKernelExpr ->
    Nat ->
    Prod PsKernelExpr Bool :=
  match fuel with
  | Nat.zero =>
      fun
        (expr : PsKernelExpr)
        (_start : Nat)
        (_subst : List PsKernelExpr)
        (_offset : Nat) =>
        Prod.mk expr false
  | Nat.succ remaining =>
      let smaller :
          PsKernelExpr ->
          Nat ->
          List PsKernelExpr ->
          Nat ->
          Prod PsKernelExpr Bool :=
        psKernelExprInstantiateAtChangedWithFuel remaining;
      fun
        (expr : PsKernelExpr)
        (start : Nat)
        (subst : List PsKernelExpr)
        (offset : Nat) =>
        match expr with
        | PsKernelExpr.bvar index =>
            let substitutionStart :=
              Nat.add start offset;
            if psKernelNatLt index substitutionStart then
              Prod.mk expr false
            else
              let relative :=
                Nat.sub index substitutionStart;
              match psKernelExprListGet subst relative with
              | Option.some replacement =>
                  Prod.mk
                    (psKernelExprLiftLooseBVars
                      replacement
                      0
                      offset)
                    true
              | Option.none =>
                  if psKernelExprListIsEmpty subst then
                    Prod.mk expr false
                  else
                    Prod.mk
                      (PsKernelExpr.bvar
                        (Nat.sub
                          index
                          (psKernelExprListLength subst)))
                      true
        | PsKernelExpr.app fn arg =>
            let fnResult := smaller fn start subst offset;
            let argResult := smaller arg start subst offset;
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
            let typeResult := smaller type start subst offset;
            let bodyResult := smaller body start subst (Nat.succ offset);
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
            let typeResult := smaller type start subst offset;
            let bodyResult := smaller body start subst (Nat.succ offset);
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
            let typeResult := smaller type start subst offset;
            let valueResult := smaller value start subst offset;
            let bodyResult := smaller body start subst (Nat.succ offset);
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
            let bodyResult := smaller body start subst offset;
            if (Prod.snd bodyResult) then
              Prod.mk
                (PsKernelExpr.mdata
                  metadata
                  (Prod.fst bodyResult))
                true
            else
              Prod.mk expr false
        | PsKernelExpr.proj typeName index body =>
            let bodyResult := smaller body start subst offset;
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

def psKernelExprInstantiateAtChanged
    (expr : PsKernelExpr)
    (start : Nat)
    (subst : List PsKernelExpr)
    (offset : Nat) :
    Prod PsKernelExpr Bool :=
  psKernelExprInstantiateAtChangedWithFuel
    (Nat.succ (psKernelExprNodeCount expr))
    expr
    start
    subst
    offset

def psKernelExprInstantiateAt
    (expr : PsKernelExpr)
    (start : Nat)
    (subst : List PsKernelExpr)
    (offset : Nat) : PsKernelExpr :=
  if psKernelExprListIsEmpty subst then
    expr
  else
    Prod.fst
      (psKernelExprInstantiateAtChanged
        expr
        start
        subst
        offset)

def psKernelExprInstantiate
    (expr : PsKernelExpr)
    (subst : List PsKernelExpr) : PsKernelExpr :=
  psKernelExprInstantiateAt
    expr
    0
    subst
    0

/-
C0's structurally recursive single-variable substitution.  The fuel-based
general substitution above remains unchanged; it is also an independent
reference for native differential checks.  Structural recursion terminates
on immediate subexpressions and preserves the same de Bruijn capture avoidance.
-/
def psKernelC0ExprInstantiateOneChanged
    (expr : PsKernelExpr)
    (replacement : PsKernelExpr)
    (offset : Nat) :
    Prod PsKernelExpr Bool :=
        match expr with
        | PsKernelExpr.bvar index =>
            if psKernelNatLt index offset then
              Prod.mk expr false
            else if Nat.beq index offset then
              Prod.mk (psKernelExprLiftLooseBVars replacement 0 offset) true
            else
              Prod.mk (PsKernelExpr.bvar (Nat.sub index 1)) true
        | PsKernelExpr.app fn arg =>
            let fnResult := psKernelC0ExprInstantiateOneChanged fn replacement offset;
            let argResult := psKernelC0ExprInstantiateOneChanged arg replacement offset;
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
            let typeResult := psKernelC0ExprInstantiateOneChanged type replacement offset;
            let bodyResult := psKernelC0ExprInstantiateOneChanged body replacement (Nat.succ offset);
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
            let typeResult := psKernelC0ExprInstantiateOneChanged type replacement offset;
            let bodyResult := psKernelC0ExprInstantiateOneChanged body replacement (Nat.succ offset);
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
            let typeResult := psKernelC0ExprInstantiateOneChanged type replacement offset;
            let valueResult := psKernelC0ExprInstantiateOneChanged value replacement offset;
            let bodyResult := psKernelC0ExprInstantiateOneChanged body replacement (Nat.succ offset);
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
            let bodyResult := psKernelC0ExprInstantiateOneChanged body replacement offset;
            if (Prod.snd bodyResult) then
              Prod.mk
                (PsKernelExpr.mdata
                  metadata
                  (Prod.fst bodyResult))
                true
            else
              Prod.mk expr false
        | PsKernelExpr.proj typeName index body =>
            let bodyResult := psKernelC0ExprInstantiateOneChanged body replacement offset;
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

def psKernelExprInstantiate1
    (expr : PsKernelExpr)
    (replacement : PsKernelExpr) : PsKernelExpr :=
  match expr with
  | PsKernelExpr.lam _ _ _ _ =>
      if psKernelExprHasLooseBVar expr then
        Prod.fst (psKernelC0ExprInstantiateOneChanged expr replacement 0)
      else
        expr
  | PsKernelExpr.forallE _ _ _ _ =>
      if psKernelExprHasLooseBVar expr then
        Prod.fst (psKernelC0ExprInstantiateOneChanged expr replacement 0)
      else
        expr
  | PsKernelExpr.letE _ _ _ _ _ =>
      if psKernelExprHasLooseBVar expr then
        Prod.fst (psKernelC0ExprInstantiateOneChanged expr replacement 0)
      else
        expr
  | _ =>
      Prod.fst (psKernelC0ExprInstantiateOneChanged expr replacement 0)

def psKernelExprInstantiateRev
    (expr : PsKernelExpr)
    (subst : List PsKernelExpr) : PsKernelExpr :=
  psKernelExprInstantiate
    expr
    (psKernelExprListReverse subst)
