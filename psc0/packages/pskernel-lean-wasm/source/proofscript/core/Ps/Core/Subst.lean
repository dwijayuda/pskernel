import Ps.Core.Expr

def psExprLiftBVarsWorker
    (amount : Nat)
    (expr : PsExpr) : Nat -> PsExpr :=
  match expr with
  | .bvar index =>
      fun (cutoff : Nat) =>
        if Nat.ble cutoff index then
          PsExpr.bvar (Nat.add index amount)
        else
          PsExpr.bvar index
  | .fvar id =>
      fun (cutoff : Nat) => PsExpr.fvar id
  | .mvar id =>
      fun (cutoff : Nat) => PsExpr.mvar id
  | .sortE level =>
      fun (cutoff : Nat) => PsExpr.sortE level
  | .constE name levels =>
      fun (cutoff : Nat) => PsExpr.constE name levels
  | .app fn arg =>
      let liftedFn : Nat -> PsExpr :=
        psExprLiftBVarsWorker amount fn;
      let liftedArg : Nat -> PsExpr :=
        psExprLiftBVarsWorker amount arg;
      fun (cutoff : Nat) =>
        PsExpr.app
          (liftedFn cutoff)
          (liftedArg cutoff)
  | .lam name type body binder =>
      let liftedType : Nat -> PsExpr :=
        psExprLiftBVarsWorker amount type;
      let liftedBody : Nat -> PsExpr :=
        psExprLiftBVarsWorker amount body;
      fun (cutoff : Nat) =>
        PsExpr.lam
          name
          (liftedType cutoff)
          (liftedBody (Nat.succ cutoff))
          binder
  | .forallE name type body binder =>
      let liftedType : Nat -> PsExpr :=
        psExprLiftBVarsWorker amount type;
      let liftedBody : Nat -> PsExpr :=
        psExprLiftBVarsWorker amount body;
      fun (cutoff : Nat) =>
        PsExpr.forallE
          name
          (liftedType cutoff)
          (liftedBody (Nat.succ cutoff))
          binder
  | .letE name type value body =>
      let liftedType : Nat -> PsExpr :=
        psExprLiftBVarsWorker amount type;
      let liftedValue : Nat -> PsExpr :=
        psExprLiftBVarsWorker amount value;
      let liftedBody : Nat -> PsExpr :=
        psExprLiftBVarsWorker amount body;
      fun (cutoff : Nat) =>
        PsExpr.letE
          name
          (liftedType cutoff)
          (liftedValue cutoff)
          (liftedBody (Nat.succ cutoff))
  | .lit value =>
      fun (cutoff : Nat) => PsExpr.lit value
  | .proj typeName index value =>
      let liftedValue : Nat -> PsExpr :=
        psExprLiftBVarsWorker amount value;
      fun (cutoff : Nat) =>
        PsExpr.proj typeName index (liftedValue cutoff)

def psExprLiftBVars
    (amount : Nat)
    (cutoff : Nat)
    (expr : PsExpr) : PsExpr :=
  let lifted : Nat -> PsExpr :=
    psExprLiftBVarsWorker amount expr;
  lifted cutoff

def psExprInstantiateAtWorker
    (replacement : PsExpr)
    (expr : PsExpr) : Nat -> PsExpr :=
  match expr with
  | .bvar index =>
      fun (depth : Nat) =>
        if Nat.beq index depth then
          psExprLiftBVars depth 0 replacement
        else if Nat.blt depth index then
          PsExpr.bvar (Nat.sub index 1)
        else
          PsExpr.bvar index
  | .fvar id =>
      fun (depth : Nat) => PsExpr.fvar id
  | .mvar id =>
      fun (depth : Nat) => PsExpr.mvar id
  | .sortE level =>
      fun (depth : Nat) => PsExpr.sortE level
  | .constE name levels =>
      fun (depth : Nat) => PsExpr.constE name levels
  | .app fn arg =>
      let instantiatedFn : Nat -> PsExpr :=
        psExprInstantiateAtWorker replacement fn;
      let instantiatedArg : Nat -> PsExpr :=
        psExprInstantiateAtWorker replacement arg;
      fun (depth : Nat) =>
        PsExpr.app
          (instantiatedFn depth)
          (instantiatedArg depth)
  | .lam name type body binder =>
      let instantiatedType : Nat -> PsExpr :=
        psExprInstantiateAtWorker replacement type;
      let instantiatedBody : Nat -> PsExpr :=
        psExprInstantiateAtWorker replacement body;
      fun (depth : Nat) =>
        PsExpr.lam
          name
          (instantiatedType depth)
          (instantiatedBody (Nat.succ depth))
          binder
  | .forallE name type body binder =>
      let instantiatedType : Nat -> PsExpr :=
        psExprInstantiateAtWorker replacement type;
      let instantiatedBody : Nat -> PsExpr :=
        psExprInstantiateAtWorker replacement body;
      fun (depth : Nat) =>
        PsExpr.forallE
          name
          (instantiatedType depth)
          (instantiatedBody (Nat.succ depth))
          binder
  | .letE name type value body =>
      let instantiatedType : Nat -> PsExpr :=
        psExprInstantiateAtWorker replacement type;
      let instantiatedValue : Nat -> PsExpr :=
        psExprInstantiateAtWorker replacement value;
      let instantiatedBody : Nat -> PsExpr :=
        psExprInstantiateAtWorker replacement body;
      fun (depth : Nat) =>
        PsExpr.letE
          name
          (instantiatedType depth)
          (instantiatedValue depth)
          (instantiatedBody (Nat.succ depth))
  | .lit value =>
      fun (depth : Nat) => PsExpr.lit value
  | .proj typeName index value =>
      let instantiatedValue : Nat -> PsExpr :=
        psExprInstantiateAtWorker replacement value;
      fun (depth : Nat) =>
        PsExpr.proj typeName index (instantiatedValue depth)

def psExprInstantiateAt
    (replacement : PsExpr)
    (depth : Nat)
    (expr : PsExpr) : PsExpr :=
  let instantiated : Nat -> PsExpr :=
    psExprInstantiateAtWorker replacement expr;
  instantiated depth

def psExprInstantiate1 (body : PsExpr) (replacement : PsExpr) : PsExpr :=
  psExprInstantiateAt replacement 0 body
