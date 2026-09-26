import Ps.PSCKernel.Core.Expr

def psCKernelExprAbstractFVarCore
    (expr : PsCKernelExpr)
    (target : PsCKernelFVarId)
    (depth : Nat) : PsCKernelExpr :=
  match expr with
  | PsCKernelExpr.bvar index =>
      if Nat.ble depth index then
        PsCKernelExpr.bvar (Nat.add index 1)
      else
        expr
  | PsCKernelExpr.fvar id =>
      if psCKernelFVarIdEq id target then
        PsCKernelExpr.bvar depth
      else
        expr
  | PsCKernelExpr.mvar _ => expr
  | PsCKernelExpr.sortE _ => expr
  | PsCKernelExpr.constE _ _ => expr
  | PsCKernelExpr.app fn arg =>
      PsCKernelExpr.app
        (psCKernelExprAbstractFVarCore fn target depth)
        (psCKernelExprAbstractFVarCore arg target depth)
  | PsCKernelExpr.lam name domain body binderInfo =>
      PsCKernelExpr.lam
        name
        (psCKernelExprAbstractFVarCore domain target depth)
        (psCKernelExprAbstractFVarCore body target (Nat.add depth 1))
        binderInfo
  | PsCKernelExpr.forallE name domain body binderInfo =>
      PsCKernelExpr.forallE
        name
        (psCKernelExprAbstractFVarCore domain target depth)
        (psCKernelExprAbstractFVarCore body target (Nat.add depth 1))
        binderInfo
  | PsCKernelExpr.letE name domain value body nondep =>
      PsCKernelExpr.letE
        name
        (psCKernelExprAbstractFVarCore domain target depth)
        (psCKernelExprAbstractFVarCore value target depth)
        (psCKernelExprAbstractFVarCore body target (Nat.add depth 1))
        nondep
  | PsCKernelExpr.lit _ => expr
  | PsCKernelExpr.proj typeName index value =>
      PsCKernelExpr.proj
        typeName
        index
        (psCKernelExprAbstractFVarCore value target depth)

def psCKernelExprAbstractFVar
    (expr : PsCKernelExpr)
    (target : PsCKernelFVarId) : PsCKernelExpr :=
  psCKernelExprAbstractFVarCore expr target 0
