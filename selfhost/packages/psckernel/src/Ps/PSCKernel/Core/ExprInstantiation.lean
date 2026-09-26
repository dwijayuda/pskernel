import Ps.PSCKernel.Core.Expr

def psCKernelExprListGet?
    (values : List PsCKernelExpr)
    (index : Nat) : Option PsCKernelExpr :=
  match values, index with
  | [], _ => none
  | value :: _, 0 => some value
  | _ :: rest, Nat.succ previous => psCKernelExprListGet? rest previous

def psCKernelExprLiftLooseBVarsCore
    (expr : PsCKernelExpr)
    (cutoff : Nat)
    (amount : Nat) : PsCKernelExpr :=
  match expr with
  | PsCKernelExpr.bvar index =>
      if Nat.ble cutoff index then
        PsCKernelExpr.bvar (Nat.add index amount)
      else
        expr
  | PsCKernelExpr.fvar _ => expr
  | PsCKernelExpr.mvar _ => expr
  | PsCKernelExpr.sortE _ => expr
  | PsCKernelExpr.constE _ _ => expr
  | PsCKernelExpr.app fn arg =>
      PsCKernelExpr.app
        (psCKernelExprLiftLooseBVarsCore fn cutoff amount)
        (psCKernelExprLiftLooseBVarsCore arg cutoff amount)
  | PsCKernelExpr.lam name type body binderInfo =>
      PsCKernelExpr.lam
        name
        (psCKernelExprLiftLooseBVarsCore type cutoff amount)
        (psCKernelExprLiftLooseBVarsCore body (Nat.add cutoff 1) amount)
        binderInfo
  | PsCKernelExpr.forallE name type body binderInfo =>
      PsCKernelExpr.forallE
        name
        (psCKernelExprLiftLooseBVarsCore type cutoff amount)
        (psCKernelExprLiftLooseBVarsCore body (Nat.add cutoff 1) amount)
        binderInfo
  | PsCKernelExpr.letE name type value body nondep =>
      PsCKernelExpr.letE
        name
        (psCKernelExprLiftLooseBVarsCore type cutoff amount)
        (psCKernelExprLiftLooseBVarsCore value cutoff amount)
        (psCKernelExprLiftLooseBVarsCore body (Nat.add cutoff 1) amount)
        nondep
  | PsCKernelExpr.lit _ => expr
  | PsCKernelExpr.proj typeName index value =>
      PsCKernelExpr.proj
        typeName
        index
        (psCKernelExprLiftLooseBVarsCore value cutoff amount)

def psCKernelExprLiftLooseBVars
    (expr : PsCKernelExpr)
    (cutoff : Nat)
    (amount : Nat) : PsCKernelExpr :=
  if Nat.beq amount 0 then
    expr
  else
    psCKernelExprLiftLooseBVarsCore expr cutoff amount

def psCKernelExprInstantiateCore
    (expr : PsCKernelExpr)
    (substitution : List PsCKernelExpr)
    (substitutionSize : Nat)
    (depth : Nat) : PsCKernelExpr :=
  match expr with
  | PsCKernelExpr.bvar index =>
      if Nat.blt index depth then
        expr
      else
        let relativeIndex : Nat := Nat.sub index depth
        match psCKernelExprListGet? substitution relativeIndex with
        | some replacement =>
            psCKernelExprLiftLooseBVars replacement 0 depth
        | none =>
            PsCKernelExpr.bvar (Nat.sub index substitutionSize)
  | PsCKernelExpr.fvar _ => expr
  | PsCKernelExpr.mvar _ => expr
  | PsCKernelExpr.sortE _ => expr
  | PsCKernelExpr.constE _ _ => expr
  | PsCKernelExpr.app fn arg =>
      PsCKernelExpr.app
        (psCKernelExprInstantiateCore fn substitution substitutionSize depth)
        (psCKernelExprInstantiateCore arg substitution substitutionSize depth)
  | PsCKernelExpr.lam name type body binderInfo =>
      PsCKernelExpr.lam
        name
        (psCKernelExprInstantiateCore type substitution substitutionSize depth)
        (psCKernelExprInstantiateCore
          body
          substitution
          substitutionSize
          (Nat.add depth 1))
        binderInfo
  | PsCKernelExpr.forallE name type body binderInfo =>
      PsCKernelExpr.forallE
        name
        (psCKernelExprInstantiateCore type substitution substitutionSize depth)
        (psCKernelExprInstantiateCore
          body
          substitution
          substitutionSize
          (Nat.add depth 1))
        binderInfo
  | PsCKernelExpr.letE name type value body nondep =>
      PsCKernelExpr.letE
        name
        (psCKernelExprInstantiateCore type substitution substitutionSize depth)
        (psCKernelExprInstantiateCore value substitution substitutionSize depth)
        (psCKernelExprInstantiateCore
          body
          substitution
          substitutionSize
          (Nat.add depth 1))
        nondep
  | PsCKernelExpr.lit _ => expr
  | PsCKernelExpr.proj typeName index value =>
      PsCKernelExpr.proj
        typeName
        index
        (psCKernelExprInstantiateCore value substitution substitutionSize depth)

def psCKernelExprInstantiate
    (expr : PsCKernelExpr)
    (substitution : List PsCKernelExpr) : PsCKernelExpr :=
  match substitution with
  | [] => expr
  | _ =>
      psCKernelExprInstantiateCore
        expr
        substitution
        substitution.length
        0

def psCKernelExprInstantiate1
    (expr : PsCKernelExpr)
    (replacement : PsCKernelExpr) : PsCKernelExpr :=
  psCKernelExprInstantiate expr [replacement]
