import Ps.KernelCore.Core.Substitution.Beta

/-
Free-variable abstraction and closing helpers.

This module is a theory-oriented split of the original portable Instantiate
implementation. Public definitions and PSC1 recursion shapes are preserved.
-/

def psKernelNameLastIndexWorker
    (values : List PsKernelName) :
    PsKernelName -> Nat -> Option Nat -> Option Nat :=
  match values with
  | List.nil =>
      fun
        (_needle : PsKernelName)
        (_index : Nat)
        (answer : Option Nat) =>
        answer
  | List.cons head tail =>
      let smaller :
          PsKernelName -> Nat -> Option Nat -> Option Nat :=
        psKernelNameLastIndexWorker tail;
      fun
        (needle : PsKernelName)
        (index : Nat)
        (answer : Option Nat) =>
        let nextAnswer :=
          if psKernelNameEq needle head then
            Option.some index
          else
            answer;
        smaller
          needle
          (Nat.succ index)
          nextAnswer

def psKernelNameLastIndex
    (needle : PsKernelName)
    (values : List PsKernelName) :
    Option Nat :=
  psKernelNameLastIndexWorker
    values
    needle
    0
    Option.none

def psKernelExprAbstractFVarsAtChangedWithFuel
    (fuel : Nat) :
    PsKernelExpr ->
    List PsKernelName ->
    Nat ->
    Prod PsKernelExpr Bool :=
  match fuel with
  | Nat.zero =>
      fun
        (expr : PsKernelExpr)
        (_fvars : List PsKernelName)
        (_offset : Nat) =>
        Prod.mk expr false
  | Nat.succ remaining =>
      let smaller :
          PsKernelExpr ->
          List PsKernelName ->
          Nat ->
          Prod PsKernelExpr Bool :=
        psKernelExprAbstractFVarsAtChangedWithFuel remaining;
      fun
        (expr : PsKernelExpr)
        (fvars : List PsKernelName)
        (offset : Nat) =>
        match expr with
        | PsKernelExpr.fvar name =>
            match psKernelNameLastIndex name fvars with
            | Option.none =>
                Prod.mk expr false
            | Option.some index =>
                Prod.mk
                  (PsKernelExpr.bvar
                    (Nat.sub
                      (Nat.sub
                        (Nat.add
                          offset
                          (psKernelNameListLength fvars))
                        index)
                      1))
                  true
        | PsKernelExpr.app fn arg =>
            let fnResult := smaller fn fvars offset;
            let argResult := smaller arg fvars offset;
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
            let typeResult := smaller type fvars offset;
            let bodyResult := smaller body fvars (Nat.succ offset);
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
            let typeResult := smaller type fvars offset;
            let bodyResult := smaller body fvars (Nat.succ offset);
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
            let typeResult := smaller type fvars offset;
            let valueResult := smaller value fvars offset;
            let bodyResult := smaller body fvars (Nat.succ offset);
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
            let bodyResult := smaller body fvars offset;
            if (Prod.snd bodyResult) then
              Prod.mk
                (PsKernelExpr.mdata
                  metadata
                  (Prod.fst bodyResult))
                true
            else
              Prod.mk expr false
        | PsKernelExpr.proj typeName index body =>
            let bodyResult := smaller body fvars offset;
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

def psKernelExprAbstractFVarsAtChanged
    (expr : PsKernelExpr)
    (fvars : List PsKernelName)
    (offset : Nat) : Prod PsKernelExpr Bool :=
  match expr with
  | PsKernelExpr.fvar name =>
      match psKernelNameLastIndex name fvars with
      | Option.none =>
          Prod.mk expr false
      | Option.some index =>
          Prod.mk
            (PsKernelExpr.bvar
              (Nat.sub
                (Nat.sub
                  (Nat.add
                    offset
                    (psKernelNameListLength fvars))
                  index)
                1))
            true
  | PsKernelExpr.app fn arg =>
      let fnResult := psKernelExprAbstractFVarsAtChanged fn fvars offset;
      let argResult := psKernelExprAbstractFVarsAtChanged arg fvars offset;
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
      let typeResult := psKernelExprAbstractFVarsAtChanged type fvars offset;
      let bodyResult := psKernelExprAbstractFVarsAtChanged body fvars (Nat.succ offset);
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
      let typeResult := psKernelExprAbstractFVarsAtChanged type fvars offset;
      let bodyResult := psKernelExprAbstractFVarsAtChanged body fvars (Nat.succ offset);
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
      let typeResult := psKernelExprAbstractFVarsAtChanged type fvars offset;
      let valueResult := psKernelExprAbstractFVarsAtChanged value fvars offset;
      let bodyResult := psKernelExprAbstractFVarsAtChanged body fvars (Nat.succ offset);
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
      let bodyResult := psKernelExprAbstractFVarsAtChanged body fvars offset;
      if (Prod.snd bodyResult) then
        Prod.mk
          (PsKernelExpr.mdata
            metadata
            (Prod.fst bodyResult))
          true
      else
        Prod.mk expr false
  | PsKernelExpr.proj typeName index body =>
      let bodyResult := psKernelExprAbstractFVarsAtChanged body fvars offset;
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

@[inline] def abstractAlgebra (fvars : List PsKernelName) : Algebra Changed :=
  changedAlgebra fun e offset =>
    match e with
    | .fvar name =>
      match psKernelNameLastIndex name fvars with
      | none => (e, false)
      | some index => (.bvar ((offset + psKernelNameListLength fvars) - index - 1), true)
    | _ => (e, false)

theorem abstract_fold (e : PsKernelExpr) (fvars : List PsKernelName) (offset : Nat) :
    fold (abstractAlgebra fvars) e offset =
      psKernelExprAbstractFVarsAtChanged e fvars offset := by
  induction e generalizing offset <;>
    simp_all [PsKernelSharing.fold, PsKernelSharing.changedAlgebra,
      PsKernelSharing.rebuildUnary, PsKernelSharing.rebuildBinary,
      PsKernelSharing.rebuildTernary, abstractAlgebra,
      psKernelExprAbstractFVarsAtChanged] <;> try rfl

end PsKernelSharing

def psKernelExprAbstractFVarsAtChangedShared (e : PsKernelExpr)
    (fvars : List PsKernelName) (offset : Nat) : Prod PsKernelExpr Bool :=
  if PsKernelSharing.small e then psKernelExprAbstractFVarsAtChanged e fvars offset
  else PsKernelSharing.run (PsKernelSharing.abstractAlgebra fvars) e offset

@[csimp] theorem psKernelExprAbstractFVarsAtChanged_shared_eq :
    psKernelExprAbstractFVarsAtChanged = psKernelExprAbstractFVarsAtChangedShared := by
  funext e fvars offset
  simp [psKernelExprAbstractFVarsAtChangedShared, PsKernelSharing.run_eq,
    PsKernelSharing.abstract_fold]


def psKernelExprAbstractFVarsAt
    (expr : PsKernelExpr)
    (fvars : List PsKernelName)
    (offset : Nat) : PsKernelExpr :=
  match fvars with
  | List.nil =>
      expr
  | List.cons _ _ =>
      Prod.fst
        (psKernelExprAbstractFVarsAtChanged
          expr
          fvars
          offset)

def psKernelExprAbstractFVars
    (expr : PsKernelExpr)
    (fvars : List PsKernelName) :
    PsKernelExpr :=
  psKernelExprAbstractFVarsAt
    expr
    fvars
    0
