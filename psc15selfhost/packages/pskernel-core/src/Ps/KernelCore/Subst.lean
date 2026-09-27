import Ps.KernelCore.Expr

def psKernelCoreExprListIsEmpty
    (items : PsKernelCoreList PsKernelCoreExpr) : Bool :=
  match items with
  | PsKernelCoreList.nil => true
  | PsKernelCoreList.cons _ _ => false

def psKernelCoreExprListLength
    (items : PsKernelCoreList PsKernelCoreExpr) : Nat :=
  match items with
  | PsKernelCoreList.nil => 0
  | PsKernelCoreList.cons _ rest =>
      Nat.succ (psKernelCoreExprListLength rest)

def psKernelCoreExprListGet
    (items : PsKernelCoreList PsKernelCoreExpr) :
    Nat -> PsKernelCoreOption PsKernelCoreExpr :=
  match items with
  | PsKernelCoreList.nil =>
      fun (_index : Nat) => PsKernelCoreOption.none
  | PsKernelCoreList.cons head rest =>
      let smaller : Nat -> PsKernelCoreOption PsKernelCoreExpr :=
        psKernelCoreExprListGet rest;
      fun (index : Nat) =>
        match index with
        | Nat.zero => PsKernelCoreOption.some head
        | Nat.succ remaining => smaller remaining

def psKernelCoreExprListAppend
    (left : PsKernelCoreList PsKernelCoreExpr) :
    PsKernelCoreList PsKernelCoreExpr -> PsKernelCoreList PsKernelCoreExpr :=
  match left with
  | PsKernelCoreList.nil =>
      fun (right : PsKernelCoreList PsKernelCoreExpr) => right
  | PsKernelCoreList.cons head rest =>
      let appendRest :
          PsKernelCoreList PsKernelCoreExpr -> PsKernelCoreList PsKernelCoreExpr :=
        psKernelCoreExprListAppend rest;
      fun (right : PsKernelCoreList PsKernelCoreExpr) =>
        PsKernelCoreList.cons head (appendRest right)

def psKernelCoreExprListReverse
    (items : PsKernelCoreList PsKernelCoreExpr) :
    PsKernelCoreList PsKernelCoreExpr :=
  match items with
  | PsKernelCoreList.nil => PsKernelCoreList.nil
  | PsKernelCoreList.cons head rest =>
      psKernelCoreExprListAppend
        (psKernelCoreExprListReverse rest)
        (PsKernelCoreList.cons head PsKernelCoreList.nil)

def psKernelCoreExprLiftBVarsWorker
    (amount : Nat)
    (expr : PsKernelCoreExpr) : Nat -> PsKernelCoreExpr :=
  match expr with
  | PsKernelCoreExpr.bvar index =>
      fun (start : Nat) =>
        if Nat.ble start index then
          PsKernelCoreExpr.bvar (Nat.add index amount)
        else
          PsKernelCoreExpr.bvar index
  | PsKernelCoreExpr.fvar name =>
      fun (_start : Nat) => PsKernelCoreExpr.fvar name
  | PsKernelCoreExpr.mvar name =>
      fun (_start : Nat) => PsKernelCoreExpr.mvar name
  | PsKernelCoreExpr.sort level =>
      fun (_start : Nat) => PsKernelCoreExpr.sort level
  | PsKernelCoreExpr.const name levels =>
      fun (_start : Nat) => PsKernelCoreExpr.const name levels
  | PsKernelCoreExpr.app fn arg =>
      let liftedFn : Nat -> PsKernelCoreExpr :=
        psKernelCoreExprLiftBVarsWorker amount fn;
      let liftedArg : Nat -> PsKernelCoreExpr :=
        psKernelCoreExprLiftBVarsWorker amount arg;
      fun (start : Nat) =>
        PsKernelCoreExpr.app
          (liftedFn start)
          (liftedArg start)
  | PsKernelCoreExpr.lam name type body binderInfo =>
      let liftedType : Nat -> PsKernelCoreExpr :=
        psKernelCoreExprLiftBVarsWorker amount type;
      let liftedBody : Nat -> PsKernelCoreExpr :=
        psKernelCoreExprLiftBVarsWorker amount body;
      fun (start : Nat) =>
        PsKernelCoreExpr.lam
          name
          (liftedType start)
          (liftedBody (Nat.succ start))
          binderInfo
  | PsKernelCoreExpr.forallE name type body binderInfo =>
      let liftedType : Nat -> PsKernelCoreExpr :=
        psKernelCoreExprLiftBVarsWorker amount type;
      let liftedBody : Nat -> PsKernelCoreExpr :=
        psKernelCoreExprLiftBVarsWorker amount body;
      fun (start : Nat) =>
        PsKernelCoreExpr.forallE
          name
          (liftedType start)
          (liftedBody (Nat.succ start))
          binderInfo
  | PsKernelCoreExpr.letE name type value body nondep =>
      let liftedType : Nat -> PsKernelCoreExpr :=
        psKernelCoreExprLiftBVarsWorker amount type;
      let liftedValue : Nat -> PsKernelCoreExpr :=
        psKernelCoreExprLiftBVarsWorker amount value;
      let liftedBody : Nat -> PsKernelCoreExpr :=
        psKernelCoreExprLiftBVarsWorker amount body;
      fun (start : Nat) =>
        PsKernelCoreExpr.letE
          name
          (liftedType start)
          (liftedValue start)
          (liftedBody (Nat.succ start))
          nondep
  | PsKernelCoreExpr.lit value =>
      fun (_start : Nat) => PsKernelCoreExpr.lit value
  | PsKernelCoreExpr.mdata metadata body =>
      let liftedBody : Nat -> PsKernelCoreExpr :=
        psKernelCoreExprLiftBVarsWorker amount body;
      fun (start : Nat) =>
        PsKernelCoreExpr.mdata metadata (liftedBody start)
  | PsKernelCoreExpr.proj typeName index body =>
      let liftedBody : Nat -> PsKernelCoreExpr :=
        psKernelCoreExprLiftBVarsWorker amount body;
      fun (start : Nat) =>
        PsKernelCoreExpr.proj typeName index (liftedBody start)

def psKernelCoreExprLiftBVars
    (expr : PsKernelCoreExpr)
    (start : Nat)
    (amount : Nat) : PsKernelCoreExpr :=
  let lifted : Nat -> PsKernelCoreExpr :=
    psKernelCoreExprLiftBVarsWorker amount expr;
  lifted start

def psKernelCoreExprInstantiateWorker
    (subst : PsKernelCoreList PsKernelCoreExpr)
    (expr : PsKernelCoreExpr) : Nat -> PsKernelCoreExpr :=
  match expr with
  | PsKernelCoreExpr.bvar index =>
      fun (offset : Nat) =>
        if Nat.blt index offset then
          PsKernelCoreExpr.bvar index
        else
          let relative := Nat.sub index offset;
          match psKernelCoreExprListGet subst relative with
          | PsKernelCoreOption.some replacement =>
              psKernelCoreExprLiftBVars replacement 0 offset
          | PsKernelCoreOption.none =>
              if psKernelCoreExprListIsEmpty subst then
                PsKernelCoreExpr.bvar index
              else
                PsKernelCoreExpr.bvar
                  (Nat.sub index (psKernelCoreExprListLength subst))
  | PsKernelCoreExpr.fvar name =>
      fun (_offset : Nat) => PsKernelCoreExpr.fvar name
  | PsKernelCoreExpr.mvar name =>
      fun (_offset : Nat) => PsKernelCoreExpr.mvar name
  | PsKernelCoreExpr.sort level =>
      fun (_offset : Nat) => PsKernelCoreExpr.sort level
  | PsKernelCoreExpr.const name levels =>
      fun (_offset : Nat) => PsKernelCoreExpr.const name levels
  | PsKernelCoreExpr.app fn arg =>
      let instantiatedFn : Nat -> PsKernelCoreExpr :=
        psKernelCoreExprInstantiateWorker subst fn;
      let instantiatedArg : Nat -> PsKernelCoreExpr :=
        psKernelCoreExprInstantiateWorker subst arg;
      fun (offset : Nat) =>
        PsKernelCoreExpr.app
          (instantiatedFn offset)
          (instantiatedArg offset)
  | PsKernelCoreExpr.lam name type body binderInfo =>
      let instantiatedType : Nat -> PsKernelCoreExpr :=
        psKernelCoreExprInstantiateWorker subst type;
      let instantiatedBody : Nat -> PsKernelCoreExpr :=
        psKernelCoreExprInstantiateWorker subst body;
      fun (offset : Nat) =>
        PsKernelCoreExpr.lam
          name
          (instantiatedType offset)
          (instantiatedBody (Nat.succ offset))
          binderInfo
  | PsKernelCoreExpr.forallE name type body binderInfo =>
      let instantiatedType : Nat -> PsKernelCoreExpr :=
        psKernelCoreExprInstantiateWorker subst type;
      let instantiatedBody : Nat -> PsKernelCoreExpr :=
        psKernelCoreExprInstantiateWorker subst body;
      fun (offset : Nat) =>
        PsKernelCoreExpr.forallE
          name
          (instantiatedType offset)
          (instantiatedBody (Nat.succ offset))
          binderInfo
  | PsKernelCoreExpr.letE name type value body nondep =>
      let instantiatedType : Nat -> PsKernelCoreExpr :=
        psKernelCoreExprInstantiateWorker subst type;
      let instantiatedValue : Nat -> PsKernelCoreExpr :=
        psKernelCoreExprInstantiateWorker subst value;
      let instantiatedBody : Nat -> PsKernelCoreExpr :=
        psKernelCoreExprInstantiateWorker subst body;
      fun (offset : Nat) =>
        PsKernelCoreExpr.letE
          name
          (instantiatedType offset)
          (instantiatedValue offset)
          (instantiatedBody (Nat.succ offset))
          nondep
  | PsKernelCoreExpr.lit value =>
      fun (_offset : Nat) => PsKernelCoreExpr.lit value
  | PsKernelCoreExpr.mdata metadata body =>
      let instantiatedBody : Nat -> PsKernelCoreExpr :=
        psKernelCoreExprInstantiateWorker subst body;
      fun (offset : Nat) =>
        PsKernelCoreExpr.mdata metadata (instantiatedBody offset)
  | PsKernelCoreExpr.proj typeName index body =>
      let instantiatedBody : Nat -> PsKernelCoreExpr :=
        psKernelCoreExprInstantiateWorker subst body;
      fun (offset : Nat) =>
        PsKernelCoreExpr.proj typeName index (instantiatedBody offset)

def psKernelCoreExprInstantiate
    (expr : PsKernelCoreExpr)
    (subst : PsKernelCoreList PsKernelCoreExpr) : PsKernelCoreExpr :=
  if psKernelCoreExprListIsEmpty subst then
    expr
  else
    let instantiated : Nat -> PsKernelCoreExpr :=
      psKernelCoreExprInstantiateWorker subst expr;
    instantiated 0

def psKernelCoreExprInstantiate1
    (expr : PsKernelCoreExpr)
    (replacement : PsKernelCoreExpr) : PsKernelCoreExpr :=
  psKernelCoreExprInstantiate
    expr
    (PsKernelCoreList.cons replacement PsKernelCoreList.nil)

def psKernelCoreExprInstantiateRev
    (expr : PsKernelCoreExpr)
    (subst : PsKernelCoreList PsKernelCoreExpr) : PsKernelCoreExpr :=
  psKernelCoreExprInstantiate expr (psKernelCoreExprListReverse subst)

def psKernelCoreExprHasFVarName
    (expr : PsKernelCoreExpr) : PsKernelCoreName -> Bool :=
  match expr with
  | PsKernelCoreExpr.bvar _ => fun (_target : PsKernelCoreName) => false
  | PsKernelCoreExpr.fvar name =>
      fun (target : PsKernelCoreName) => psKernelCoreNameEq name target
  | PsKernelCoreExpr.mvar _ => fun (_target : PsKernelCoreName) => false
  | PsKernelCoreExpr.sort _ => fun (_target : PsKernelCoreName) => false
  | PsKernelCoreExpr.const _ _ => fun (_target : PsKernelCoreName) => false
  | PsKernelCoreExpr.app fn arg =>
      let hasFn : PsKernelCoreName -> Bool := psKernelCoreExprHasFVarName fn;
      let hasArg : PsKernelCoreName -> Bool := psKernelCoreExprHasFVarName arg;
      fun (target : PsKernelCoreName) =>
        if hasFn target then true else hasArg target
  | PsKernelCoreExpr.lam _ type body _ =>
      let hasType : PsKernelCoreName -> Bool := psKernelCoreExprHasFVarName type;
      let hasBody : PsKernelCoreName -> Bool := psKernelCoreExprHasFVarName body;
      fun (target : PsKernelCoreName) =>
        if hasType target then true else hasBody target
  | PsKernelCoreExpr.forallE _ type body _ =>
      let hasType : PsKernelCoreName -> Bool := psKernelCoreExprHasFVarName type;
      let hasBody : PsKernelCoreName -> Bool := psKernelCoreExprHasFVarName body;
      fun (target : PsKernelCoreName) =>
        if hasType target then true else hasBody target
  | PsKernelCoreExpr.letE _ type value body _ =>
      let hasType : PsKernelCoreName -> Bool := psKernelCoreExprHasFVarName type;
      let hasValue : PsKernelCoreName -> Bool := psKernelCoreExprHasFVarName value;
      let hasBody : PsKernelCoreName -> Bool := psKernelCoreExprHasFVarName body;
      fun (target : PsKernelCoreName) =>
        if hasType target then true
        else if hasValue target then true
        else hasBody target
  | PsKernelCoreExpr.lit _ => fun (_target : PsKernelCoreName) => false
  | PsKernelCoreExpr.mdata _ body =>
      let hasBody : PsKernelCoreName -> Bool := psKernelCoreExprHasFVarName body;
      fun (target : PsKernelCoreName) => hasBody target
  | PsKernelCoreExpr.proj _ _ body =>
      let hasBody : PsKernelCoreName -> Bool := psKernelCoreExprHasFVarName body;
      fun (target : PsKernelCoreName) => hasBody target

def psKernelCoreExprAbstractFVarWorker
    (expr : PsKernelCoreExpr) :
    PsKernelCoreName -> Nat -> PsKernelCoreExpr :=
  match expr with
  | PsKernelCoreExpr.bvar index =>
      fun (_target : PsKernelCoreName) (depth : Nat) =>
        if Nat.ble depth index then
          PsKernelCoreExpr.bvar (Nat.succ index)
        else
          PsKernelCoreExpr.bvar index
  | PsKernelCoreExpr.fvar name =>
      fun (target : PsKernelCoreName) (depth : Nat) =>
        if psKernelCoreNameEq name target then
          PsKernelCoreExpr.bvar depth
        else
          PsKernelCoreExpr.fvar name
  | PsKernelCoreExpr.mvar name =>
      fun (_target : PsKernelCoreName) (_depth : Nat) => PsKernelCoreExpr.mvar name
  | PsKernelCoreExpr.sort level =>
      fun (_target : PsKernelCoreName) (_depth : Nat) => PsKernelCoreExpr.sort level
  | PsKernelCoreExpr.const name levels =>
      fun (_target : PsKernelCoreName) (_depth : Nat) => PsKernelCoreExpr.const name levels
  | PsKernelCoreExpr.app fn arg =>
      let abstractFn : PsKernelCoreName -> Nat -> PsKernelCoreExpr :=
        psKernelCoreExprAbstractFVarWorker fn;
      let abstractArg : PsKernelCoreName -> Nat -> PsKernelCoreExpr :=
        psKernelCoreExprAbstractFVarWorker arg;
      fun (target : PsKernelCoreName) (depth : Nat) =>
        PsKernelCoreExpr.app
          (abstractFn target depth)
          (abstractArg target depth)
  | PsKernelCoreExpr.lam name type body binderInfo =>
      let abstractType : PsKernelCoreName -> Nat -> PsKernelCoreExpr :=
        psKernelCoreExprAbstractFVarWorker type;
      let abstractBody : PsKernelCoreName -> Nat -> PsKernelCoreExpr :=
        psKernelCoreExprAbstractFVarWorker body;
      fun (target : PsKernelCoreName) (depth : Nat) =>
        PsKernelCoreExpr.lam
          name
          (abstractType target depth)
          (abstractBody target (Nat.succ depth))
          binderInfo
  | PsKernelCoreExpr.forallE name type body binderInfo =>
      let abstractType : PsKernelCoreName -> Nat -> PsKernelCoreExpr :=
        psKernelCoreExprAbstractFVarWorker type;
      let abstractBody : PsKernelCoreName -> Nat -> PsKernelCoreExpr :=
        psKernelCoreExprAbstractFVarWorker body;
      fun (target : PsKernelCoreName) (depth : Nat) =>
        PsKernelCoreExpr.forallE
          name
          (abstractType target depth)
          (abstractBody target (Nat.succ depth))
          binderInfo
  | PsKernelCoreExpr.letE name type value body nondep =>
      let abstractType : PsKernelCoreName -> Nat -> PsKernelCoreExpr :=
        psKernelCoreExprAbstractFVarWorker type;
      let abstractValue : PsKernelCoreName -> Nat -> PsKernelCoreExpr :=
        psKernelCoreExprAbstractFVarWorker value;
      let abstractBody : PsKernelCoreName -> Nat -> PsKernelCoreExpr :=
        psKernelCoreExprAbstractFVarWorker body;
      fun (target : PsKernelCoreName) (depth : Nat) =>
        PsKernelCoreExpr.letE
          name
          (abstractType target depth)
          (abstractValue target depth)
          (abstractBody target (Nat.succ depth))
          nondep
  | PsKernelCoreExpr.lit value =>
      fun (_target : PsKernelCoreName) (_depth : Nat) => PsKernelCoreExpr.lit value
  | PsKernelCoreExpr.mdata metadata body =>
      let abstractBody : PsKernelCoreName -> Nat -> PsKernelCoreExpr :=
        psKernelCoreExprAbstractFVarWorker body;
      fun (target : PsKernelCoreName) (depth : Nat) =>
        PsKernelCoreExpr.mdata metadata (abstractBody target depth)
  | PsKernelCoreExpr.proj typeName index body =>
      let abstractBody : PsKernelCoreName -> Nat -> PsKernelCoreExpr :=
        psKernelCoreExprAbstractFVarWorker body;
      fun (target : PsKernelCoreName) (depth : Nat) =>
        PsKernelCoreExpr.proj typeName index (abstractBody target depth)

def psKernelCoreExprAbstractFVar
    (expr : PsKernelCoreExpr)
    (target : PsKernelCoreName) : PsKernelCoreExpr :=
  psKernelCoreExprAbstractFVarWorker expr target Nat.zero
