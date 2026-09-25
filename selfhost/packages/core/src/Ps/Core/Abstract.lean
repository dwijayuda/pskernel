import Ps.Core.Expr

def psExprAbstractFVarAt (target : Nat) (depth : Nat) (expr : PsExpr) : PsExpr :=
  match expr with
  | .bvar index =>
      PsExpr.bvar index
  | .fvar id =>
      if Nat.beq id target then
        PsExpr.bvar depth
      else
        PsExpr.fvar id
  | .mvar id =>
      PsExpr.mvar id
  | .sortE level =>
      PsExpr.sortE level
  | .constE name levels =>
      PsExpr.constE name levels
  | .app fn arg =>
      PsExpr.app
        (psExprAbstractFVarAt target depth fn)
        (psExprAbstractFVarAt target depth arg)
  | .lam name type body binder =>
      PsExpr.lam
        name
        (psExprAbstractFVarAt target depth type)
        (psExprAbstractFVarAt target (Nat.succ depth) body)
        binder
  | .forallE name type body binder =>
      PsExpr.forallE
        name
        (psExprAbstractFVarAt target depth type)
        (psExprAbstractFVarAt target (Nat.succ depth) body)
        binder
  | .letE name type value body =>
      PsExpr.letE
        name
        (psExprAbstractFVarAt target depth type)
        (psExprAbstractFVarAt target depth value)
        (psExprAbstractFVarAt target (Nat.succ depth) body)
  | .lit value =>
      PsExpr.lit value
  | .proj typeName index value =>
      PsExpr.proj typeName index (psExprAbstractFVarAt target depth value)

def psExprAbstractFVar (target : Nat) (expr : PsExpr) : PsExpr :=
  psExprAbstractFVarAt target 0 expr
