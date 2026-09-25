import Ps.Core.Expr

def psExprLiftBVars (amount : Nat) (cutoff : Nat) (expr : PsExpr) : PsExpr :=
  match expr with
  | .bvar index =>
      if Nat.ble cutoff index then
        PsExpr.bvar (Nat.add index amount)
      else
        PsExpr.bvar index
  | .fvar id =>
      PsExpr.fvar id
  | .mvar id =>
      PsExpr.mvar id
  | .sortE level =>
      PsExpr.sortE level
  | .constE name levels =>
      PsExpr.constE name levels
  | .app fn arg =>
      PsExpr.app
        (psExprLiftBVars amount cutoff fn)
        (psExprLiftBVars amount cutoff arg)
  | .lam name type body binder =>
      PsExpr.lam
        name
        (psExprLiftBVars amount cutoff type)
        (psExprLiftBVars amount (Nat.succ cutoff) body)
        binder
  | .forallE name type body binder =>
      PsExpr.forallE
        name
        (psExprLiftBVars amount cutoff type)
        (psExprLiftBVars amount (Nat.succ cutoff) body)
        binder
  | .letE name type value body =>
      PsExpr.letE
        name
        (psExprLiftBVars amount cutoff type)
        (psExprLiftBVars amount cutoff value)
        (psExprLiftBVars amount (Nat.succ cutoff) body)
  | .lit value =>
      PsExpr.lit value
  | .proj typeName index value =>
      PsExpr.proj typeName index (psExprLiftBVars amount cutoff value)

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
