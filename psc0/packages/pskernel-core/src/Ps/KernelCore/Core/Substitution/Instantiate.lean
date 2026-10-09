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
  match expr with
  | PsKernelExpr.bvar index =>
      let substitutionStart :=
        Nat.add start offset
      if psKernelNatLt index substitutionStart then
        Prod.mk expr false
      else
        let relative :=
          Nat.sub index substitutionStart
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
      let fnResult :=
        psKernelExprInstantiateAtChanged
          fn start subst offset
      let argResult :=
        psKernelExprInstantiateAtChanged
          arg start subst offset
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
        psKernelExprInstantiateAtChanged
          type start subst offset
      let bodyResult :=
        psKernelExprInstantiateAtChanged
          body start subst (Nat.succ offset)
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
        psKernelExprInstantiateAtChanged
          type start subst offset
      let bodyResult :=
        psKernelExprInstantiateAtChanged
          body start subst (Nat.succ offset)
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
        psKernelExprInstantiateAtChanged
          type start subst offset
      let valueResult :=
        psKernelExprInstantiateAtChanged
          value start subst offset
      let bodyResult :=
        psKernelExprInstantiateAtChanged
          body start subst (Nat.succ offset)
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
        psKernelExprInstantiateAtChanged
          body start subst offset
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
        psKernelExprInstantiateAtChanged
          body start subst offset
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

namespace PsKernelSharing

@[inline, instance_reducible] def instantiateAlgebra (start : Nat) (subst : List PsKernelExpr) : Algebra Changed :=
  changedAlgebra fun e offset =>
    match e with
    | .bvar index =>
      if psKernelNatLt index (start + offset) then (e, false)
      else match psKernelExprListGet subst (index - (start + offset)) with
        | some replacement => (psKernelExprLiftLooseBVars replacement 0 offset, true)
        | none => if psKernelExprListIsEmpty subst then (e, false)
            else (.bvar (index - psKernelExprListLength subst), true)
    | _ => (e, false)

theorem instantiate_fold (e : PsKernelExpr) (start : Nat)
    (subst : List PsKernelExpr) (offset : Nat) :
    fold (instantiateAlgebra start subst) e offset =
      psKernelExprInstantiateAtChanged e start subst offset := by
  induction e generalizing offset <;>
    simp_all [PsKernelSharing.Algebra.atom, PsKernelSharing.Algebra.unary,
      PsKernelSharing.Algebra.binary, PsKernelSharing.Algebra.ternary, PsKernelSharing.fold, PsKernelSharing.changedAlgebra,
      PsKernelSharing.rebuildUnary, PsKernelSharing.rebuildBinary,
      PsKernelSharing.rebuildTernary, instantiateAlgebra,
      psKernelExprInstantiateAtChanged] <;> try rfl

end PsKernelSharing

def psKernelExprInstantiateAtChangedShared (e : PsKernelExpr) (start : Nat)
    (subst : List PsKernelExpr) (offset : Nat) : Prod PsKernelExpr Bool :=
  if PsKernelSharing.small e then psKernelExprInstantiateAtChanged e start subst offset
  else PsKernelSharing.run (PsKernelSharing.instantiateAlgebra start subst) e offset

@[csimp] theorem psKernelExprInstantiateAtChanged_shared_eq :
    psKernelExprInstantiateAtChanged = psKernelExprInstantiateAtChangedShared := by
  funext e start subst offset
  simp [psKernelExprInstantiateAtChangedShared, PsKernelSharing.run_eq,
    PsKernelSharing.instantiate_fold]


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

def psKernelExprInstantiate1
    (expr : PsKernelExpr)
    (replacement : PsKernelExpr) : PsKernelExpr :=
  if psKernelExprHasLooseBVar expr then
    psKernelExprInstantiate
      expr
      (List.cons replacement List.nil)
  else
    expr

def psKernelExprInstantiateRev
    (expr : PsKernelExpr)
    (subst : List PsKernelExpr) : PsKernelExpr :=
  psKernelExprInstantiate
    expr
    (psKernelExprListReverse subst)
