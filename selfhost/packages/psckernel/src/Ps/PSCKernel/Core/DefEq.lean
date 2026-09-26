import Ps.PSCKernel.Core.DefEqBasic
import Ps.PSCKernel.Core.TypeInference

def psCKernelExprIsProposition
    (env : PsCKernelEnvironment)
    (lctx : PsCKernelLocalContext)
    (expr : PsCKernelExpr) : Bool :=
  match psCKernelInfer? env lctx expr with
  | none => false
  | some exprType =>
      match psCKernelExprWhnfBasic env lctx exprType with
      | PsCKernelExpr.sortE level =>
          psCKernelLevelEquivalent level psCKernelLevelZero
      | _ => false

partial def psCKernelIsDefEq
    (env : PsCKernelEnvironment)
    (lctx : PsCKernelLocalContext)
    (left : PsCKernelExpr)
    (right : PsCKernelExpr) : Bool :=
  if psCKernelIsDefEqBasic env lctx left right then
    true
  else
    match psCKernelInfer? env lctx left with
    | none => false
    | some leftType =>
        if psCKernelExprIsProposition env lctx leftType then
          match psCKernelInfer? env lctx right with
          | none => false
          | some rightType =>
              psCKernelIsDefEq env lctx leftType rightType
        else
          false
