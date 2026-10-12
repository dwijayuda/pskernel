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

/-
C0 source-portable direct structural instantiation.

Unlike the historical fuel-based implementation, this checker hot path
recurses on the expression's immediate subterms, removing the complete
psKernelExprNodeCount prepass. The original bounded function is retained
as an independently executable differential oracle. No extra kernel
acceptance rules are introduced.
-/
def psKernelC0ExprInstantiateAtChanged
    (expr : PsKernelExpr)
    (start : Nat)
    (subst : List PsKernelExpr)
    (offset : Nat) :
    Prod PsKernelExpr Bool :=
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
            let fnResult := psKernelC0ExprInstantiateAtChanged fn start subst offset;
            let argResult := psKernelC0ExprInstantiateAtChanged arg start subst offset;
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
            let typeResult := psKernelC0ExprInstantiateAtChanged type start subst offset;
            let bodyResult := psKernelC0ExprInstantiateAtChanged body start subst (Nat.succ offset);
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
            let typeResult := psKernelC0ExprInstantiateAtChanged type start subst offset;
            let bodyResult := psKernelC0ExprInstantiateAtChanged body start subst (Nat.succ offset);
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
            let typeResult := psKernelC0ExprInstantiateAtChanged type start subst offset;
            let valueResult := psKernelC0ExprInstantiateAtChanged value start subst offset;
            let bodyResult := psKernelC0ExprInstantiateAtChanged body start subst (Nat.succ offset);
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
            let bodyResult := psKernelC0ExprInstantiateAtChanged body start subst offset;
            if (Prod.snd bodyResult) then
              Prod.mk
                (PsKernelExpr.mdata
                  metadata
                  (Prod.fst bodyResult))
                true
            else
              Prod.mk expr false
        | PsKernelExpr.proj typeName index body =>
            let bodyResult := psKernelC0ExprInstantiateAtChanged body start subst offset;
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


/-
C0 dedicated single-variable substitution for beta and zeta.
The generic list-substitution path remains for simultaneous substitutions.
This path removes a list lookup and list-length traversal at every BVar.
It preserves unchanged subtrees and lifts replacements across binders.
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



def psKernelExprInstantiateAtChanged
    (expr : PsKernelExpr)
    (start : Nat)
    (subst : List PsKernelExpr)
    (offset : Nat) :
    Prod PsKernelExpr Bool :=
  psKernelC0ExprInstantiateAtChanged
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

/--
Single-variable instantiation has two genuinely different cost profiles.

Application-heavy open expressions benefit from the one-pass changed-flag
worker. Binder-headed *closed* expressions (especially nested Pi codomains
returned by checked application inference) are better served by a lightweight
loose-variable probe: when no loose variable is present, return the original
expression without constructing a pair at every binder node.

Do not scan application-headed terms up front; their previous specialized
one-pass performance would be lost. A positive probe invokes the same
capture-avoiding worker as before. Both paths preserve the exact original
instantiate1 semantics; neither can issue any checker acceptance decision.
-/
def psKernelExprInstantiate1
    (expr : PsKernelExpr)
    (replacement : PsKernelExpr) : PsKernelExpr :=
  match expr with
  | .lam _ _ _ _
  | .forallE _ _ _ _
  | .letE _ _ _ _ _ =>
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
