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

def psExprInstantiateAt (replacement : PsExpr) (depth : Nat) : PsExpr -> PsExpr
  | .bvar index =>
      if Nat.beq index depth then
        psExprLiftBVars depth 0 replacement
      else if Nat.blt depth index then
        PsExpr.bvar (Nat.sub index 1)
      else
        PsExpr.bvar index
  | .app fn arg =>
      PsExpr.app
        (psExprInstantiateAt replacement depth fn)
        (psExprInstantiateAt replacement depth arg)
  | .lam name type body binder =>
      PsExpr.lam
        name
        (psExprInstantiateAt replacement depth type)
        (psExprInstantiateAt replacement (Nat.succ depth) body)
        binder
  | .forallE name type body binder =>
      PsExpr.forallE
        name
        (psExprInstantiateAt replacement depth type)
        (psExprInstantiateAt replacement (Nat.succ depth) body)
        binder
  | .letE name type value body =>
      PsExpr.letE
        name
        (psExprInstantiateAt replacement depth type)
        (psExprInstantiateAt replacement depth value)
        (psExprInstantiateAt replacement (Nat.succ depth) body)
  | .proj typeName index value =>
      PsExpr.proj typeName index (psExprInstantiateAt replacement depth value)
  | expr => expr

def psExprInstantiate1 (body : PsExpr) (replacement : PsExpr) : PsExpr :=
  psExprInstantiateAt replacement 0 body
