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

def psCKernelProofIrrelevanceEquivalent
    (env : PsCKernelEnvironment)
    (lctx : PsCKernelLocalContext)
    (left : PsCKernelExpr)
    (right : PsCKernelExpr)
    (isDefEq : PsCKernelExpr -> PsCKernelExpr -> Bool) : Bool :=
  match psCKernelInfer? env lctx left with
  | none => false
  | some leftType =>
      if psCKernelExprIsProposition env lctx leftType then
        match psCKernelInfer? env lctx right with
        | none => false
        | some rightType => isDefEq leftType rightType
      else
        false

def psCKernelEtaExpand?
    (env : PsCKernelEnvironment)
    (lctx : PsCKernelLocalContext)
    (expr : PsCKernelExpr) : Option PsCKernelExpr :=
  match psCKernelInfer? env lctx expr with
  | none => none
  | some exprType =>
      match psCKernelExprWhnfBasic env lctx exprType with
      | PsCKernelExpr.forallE name domain _ binderInfo =>
          some
            (PsCKernelExpr.lam
              name
              domain
              (PsCKernelExpr.app
                (psCKernelExprLiftLooseBVars expr 0 1)
                (PsCKernelExpr.bvar 0))
              binderInfo)
      | _ => none

partial def psCKernelIsDefEq
    (env : PsCKernelEnvironment)
    (lctx : PsCKernelLocalContext)
    (left : PsCKernelExpr)
    (right : PsCKernelExpr) : Bool :=
  if psCKernelIsDefEqBasic env lctx left right then
    true
  else if
      psCKernelProofIrrelevanceEquivalent
        env lctx left right (psCKernelIsDefEq env lctx) then
    true
  else
    match left, right with
    | PsCKernelExpr.lam _ _ _ _, PsCKernelExpr.lam _ _ _ _ => false
    | PsCKernelExpr.lam _ _ _ _, _ =>
        match psCKernelEtaExpand? env lctx right with
        | none => false
        | some expandedRight =>
            psCKernelIsDefEq env lctx left expandedRight
    | _, PsCKernelExpr.lam _ _ _ _ =>
        match psCKernelEtaExpand? env lctx left with
        | none => false
        | some expandedLeft =>
            psCKernelIsDefEq env lctx expandedLeft right
    | _, _ => false
