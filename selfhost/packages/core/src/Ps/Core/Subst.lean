import Ps.Core.Expr

def psExprLiftBVars (amount : Nat) (cutoff : Nat) : PsExpr -> PsExpr
  | .bvar index =>
      if Nat.ble cutoff index then
        PsExpr.bvar (Nat.add index amount)
      else
        PsExpr.bvar index
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
        (psExprLiftBVars amount (cutoff + 1) body)
  | .proj typeName index value =>
      PsExpr.proj typeName index (psExprLiftBVars amount cutoff value)
  | expr => expr

def psExprInstantiateAt (replacement : PsExpr) (depth : Nat) : PsExpr -> PsExpr
  | .bvar index =>
      if Nat.beq index depth then
        psExprLiftBVars depth 0 replacement
      else if depth < index then
        PsExpr.bvar (index - 1)
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
        (psExprInstantiateAt replacement (depth + 1) body)
        binder
  | .forallE name type body binder =>
      PsExpr.forallE
        name
        (psExprInstantiateAt replacement depth type)
        (psExprInstantiateAt replacement (depth + 1) body)
        binder
  | .letE name type value body =>
      PsExpr.letE
        name
        (psExprInstantiateAt replacement depth type)
        (psExprInstantiateAt replacement depth value)
        (psExprInstantiateAt replacement (depth + 1) body)
  | .proj typeName index value =>
      PsExpr.proj typeName index (psExprInstantiateAt replacement depth value)
  | expr => expr

def psExprInstantiate1 (body : PsExpr) (replacement : PsExpr) : PsExpr :=
  psExprInstantiateAt replacement 0 body
