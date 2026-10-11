import Ps.Core.Expr

def psExprAbstractFVarAtWorker
    (target : Nat)
    (expr : PsExpr) : Nat -> PsExpr :=
  match expr with
  | .bvar index =>
      fun (depth : Nat) => PsExpr.bvar index
  | .fvar id =>
      fun (depth : Nat) =>
        if Nat.beq id target then
          PsExpr.bvar depth
        else
          PsExpr.fvar id
  | .mvar id =>
      fun (depth : Nat) => PsExpr.mvar id
  | .sortE level =>
      fun (depth : Nat) => PsExpr.sortE level
  | .constE name levels =>
      fun (depth : Nat) => PsExpr.constE name levels
  | .app fn arg =>
      let abstractFn : Nat -> PsExpr :=
        psExprAbstractFVarAtWorker target fn;
      let abstractArg : Nat -> PsExpr :=
        psExprAbstractFVarAtWorker target arg;
      fun (depth : Nat) =>
        PsExpr.app
          (abstractFn depth)
          (abstractArg depth)
  | .lam name type body binder =>
      let abstractType : Nat -> PsExpr :=
        psExprAbstractFVarAtWorker target type;
      let abstractBody : Nat -> PsExpr :=
        psExprAbstractFVarAtWorker target body;
      fun (depth : Nat) =>
        PsExpr.lam
          name
          (abstractType depth)
          (abstractBody (Nat.succ depth))
          binder
  | .forallE name type body binder =>
      let abstractType : Nat -> PsExpr :=
        psExprAbstractFVarAtWorker target type;
      let abstractBody : Nat -> PsExpr :=
        psExprAbstractFVarAtWorker target body;
      fun (depth : Nat) =>
        PsExpr.forallE
          name
          (abstractType depth)
          (abstractBody (Nat.succ depth))
          binder
  | .letE name type value body =>
      let abstractType : Nat -> PsExpr :=
        psExprAbstractFVarAtWorker target type;
      let abstractValue : Nat -> PsExpr :=
        psExprAbstractFVarAtWorker target value;
      let abstractBody : Nat -> PsExpr :=
        psExprAbstractFVarAtWorker target body;
      fun (depth : Nat) =>
        PsExpr.letE
          name
          (abstractType depth)
          (abstractValue depth)
          (abstractBody (Nat.succ depth))
  | .lit value =>
      fun (depth : Nat) => PsExpr.lit value
  | .proj typeName index value =>
      let abstractValue : Nat -> PsExpr :=
        psExprAbstractFVarAtWorker target value;
      fun (depth : Nat) =>
        PsExpr.proj typeName index (abstractValue depth)

def psExprAbstractFVarAt
    (target : Nat)
    (depth : Nat)
    (expr : PsExpr) : PsExpr :=
  let abstracted : Nat -> PsExpr :=
    psExprAbstractFVarAtWorker target expr;
  abstracted depth

def psExprAbstractFVar (target : Nat) (expr : PsExpr) : PsExpr :=
  psExprAbstractFVarAt target 0 expr
