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


/-
Total reference semantics for capture-avoiding de Bruijn instantiation.

Substitution hits use the reference lifting operation above, so this
specification does not depend on the production instantiation or lifting
workers.
-/

def psKernelExprInstantiateAtReferenceChanged
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
              (psKernelExprLiftLooseBVarsReference
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
        psKernelExprInstantiateAtReferenceChanged
          fn start subst offset
      let argResult :=
        psKernelExprInstantiateAtReferenceChanged
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
        psKernelExprInstantiateAtReferenceChanged
          type start subst offset
      let bodyResult :=
        psKernelExprInstantiateAtReferenceChanged
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
        psKernelExprInstantiateAtReferenceChanged
          type start subst offset
      let bodyResult :=
        psKernelExprInstantiateAtReferenceChanged
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
        psKernelExprInstantiateAtReferenceChanged
          type start subst offset
      let valueResult :=
        psKernelExprInstantiateAtReferenceChanged
          value start subst offset
      let bodyResult :=
        psKernelExprInstantiateAtReferenceChanged
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
        psKernelExprInstantiateAtReferenceChanged
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
        psKernelExprInstantiateAtReferenceChanged
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
termination_by expr

def psKernelExprInstantiateAtReference
    (expr : PsKernelExpr)
    (start : Nat)
    (subst : List PsKernelExpr)
    (offset : Nat) :
    PsKernelExpr :=
  if psKernelExprListIsEmpty subst then
    expr
  else
    Prod.fst
      (psKernelExprInstantiateAtReferenceChanged
        expr start subst offset)

def psKernelExprInstantiateReference
    (expr : PsKernelExpr)
    (subst : List PsKernelExpr) :
    PsKernelExpr :=
  psKernelExprInstantiateAtReference
    expr 0 subst 0

def psKernelExprInstantiate1Reference
    (expr replacement : PsKernelExpr) :
    PsKernelExpr :=
  if psKernelExprHasLooseBVar expr then
    psKernelExprInstantiateReference
      expr
      (List.cons replacement List.nil)
  else
    expr

def psKernelExprInstantiateRevReference
    (expr : PsKernelExpr)
    (subst : List PsKernelExpr) :
    PsKernelExpr :=
  psKernelExprInstantiateReference
    expr
    (psKernelExprListReverse subst)


def psKernelNameLastIndexReferenceWorker
    (values : List PsKernelName)
    (needle : PsKernelName)
    (index : Nat)
    (answer : Option Nat) :
    Option Nat :=
  match values with
  | List.nil =>
      answer
  | List.cons head tail =>
      let nextAnswer :=
        if psKernelNameEq needle head then
          Option.some index
        else
          answer
      psKernelNameLastIndexReferenceWorker
        tail needle (Nat.succ index) nextAnswer

def psKernelNameLastIndexReference
    (needle : PsKernelName)
    (values : List PsKernelName) :
    Option Nat :=
  psKernelNameLastIndexReferenceWorker
    values needle 0 Option.none

/-
Total reference semantics for free-variable abstraction.
-/

def psKernelExprAbstractFVarsAtReferenceChanged
    (expr : PsKernelExpr)
    (fvars : List PsKernelName)
    (offset : Nat) :
    Prod PsKernelExpr Bool :=
  match expr with
  | PsKernelExpr.fvar name =>
      match psKernelNameLastIndexReference name fvars with
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
      let fnResult :=
        psKernelExprAbstractFVarsAtReferenceChanged
          fn fvars offset
      let argResult :=
        psKernelExprAbstractFVarsAtReferenceChanged
          arg fvars offset
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
        psKernelExprAbstractFVarsAtReferenceChanged
          type fvars offset
      let bodyResult :=
        psKernelExprAbstractFVarsAtReferenceChanged
          body fvars (Nat.succ offset)
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
        psKernelExprAbstractFVarsAtReferenceChanged
          type fvars offset
      let bodyResult :=
        psKernelExprAbstractFVarsAtReferenceChanged
          body fvars (Nat.succ offset)
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
        psKernelExprAbstractFVarsAtReferenceChanged
          type fvars offset
      let valueResult :=
        psKernelExprAbstractFVarsAtReferenceChanged
          value fvars offset
      let bodyResult :=
        psKernelExprAbstractFVarsAtReferenceChanged
          body fvars (Nat.succ offset)
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
        psKernelExprAbstractFVarsAtReferenceChanged
          body fvars offset
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
        psKernelExprAbstractFVarsAtReferenceChanged
          body fvars offset
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

def psKernelExprAbstractFVarsAtReference
    (expr : PsKernelExpr)
    (fvars : List PsKernelName)
    (offset : Nat) :
    PsKernelExpr :=
  match fvars with
  | List.nil =>
      expr
  | List.cons _ _ =>
      Prod.fst
        (psKernelExprAbstractFVarsAtReferenceChanged
          expr fvars offset)

def psKernelExprAbstractFVarsReference
    (expr : PsKernelExpr)
    (fvars : List PsKernelName) :
    PsKernelExpr :=
  psKernelExprAbstractFVarsAtReference
    expr fvars 0


def PsKernelNameEqSoundAgainst
    (target : PsKernelName) : Prop :=
  ∀ (candidate : PsKernelName),
    psKernelNameEq candidate target = true ->
      candidate = target
