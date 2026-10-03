import Ps.KernelSelfHost.Expr

def psKernelExprListGet
    (values : List PsKernelExpr) :
    Nat -> Option PsKernelExpr :=
  match values with
  | List.nil =>
      fun (_index : Nat) =>
        Option.none
  | List.cons head tail =>
      let smaller : Nat -> Option PsKernelExpr :=
        psKernelExprListGet tail;
      fun (index : Nat) =>
        match index with
        | Nat.zero =>
            Option.some head
        | Nat.succ remaining =>
            smaller remaining

def psKernelExprListIsEmpty
    (values : List PsKernelExpr) : Bool :=
  match values with
  | List.nil => true
  | List.cons _ _ => false

def psKernelExprListReverseWorker
    (values : List PsKernelExpr) :
    List PsKernelExpr -> List PsKernelExpr :=
  match values with
  | List.nil =>
      fun (acc : List PsKernelExpr) =>
        acc
  | List.cons head tail =>
      let smaller :
          List PsKernelExpr -> List PsKernelExpr :=
        psKernelExprListReverseWorker tail;
      fun (acc : List PsKernelExpr) =>
        smaller (List.cons head acc)

def psKernelExprListReverse
    (values : List PsKernelExpr) :
    List PsKernelExpr :=
  psKernelExprListReverseWorker
    values
    List.nil

def psKernelExprListTake
    (amount : Nat) :
    List PsKernelExpr -> List PsKernelExpr :=
  match amount with
  | Nat.zero =>
      fun (_values : List PsKernelExpr) =>
        List.nil
  | Nat.succ remaining =>
      let smaller :
          List PsKernelExpr -> List PsKernelExpr :=
        psKernelExprListTake remaining;
      fun (values : List PsKernelExpr) =>
        match values with
        | List.nil =>
            List.nil
        | List.cons head tail =>
            List.cons head (smaller tail)

def psKernelExprListDrop
    (amount : Nat) :
    List PsKernelExpr -> List PsKernelExpr :=
  match amount with
  | Nat.zero =>
      fun (values : List PsKernelExpr) =>
        values
  | Nat.succ remaining =>
      let smaller :
          List PsKernelExpr -> List PsKernelExpr :=
        psKernelExprListDrop remaining;
      fun (values : List PsKernelExpr) =>
        match values with
        | List.nil =>
            List.nil
        | List.cons _ tail =>
            smaller tail

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

def psKernelExprInstantiate1
    (expr : PsKernelExpr)
    (replacement : PsKernelExpr) : PsKernelExpr :=
  psKernelExprInstantiate
    expr
    (List.cons replacement List.nil)

def psKernelExprInstantiateRev
    (expr : PsKernelExpr)
    (subst : List PsKernelExpr) : PsKernelExpr :=
  psKernelExprInstantiate
    expr
    (psKernelExprListReverse subst)

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

def psKernelNameListLength
    (values : List PsKernelName) : Nat :=
  match values with
  | List.nil =>
      0
  | List.cons _ rest =>
      Nat.succ (psKernelNameListLength rest)

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
    (offset : Nat) :
    Prod PsKernelExpr Bool :=
  psKernelExprAbstractFVarsAtChangedWithFuel
    (Nat.succ (psKernelExprNodeCount expr))
    expr
    fvars
    offset

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
