import Ps.PSCKernel.Core.Expr

def psCKernelInstantiateLevelList
    (levels : List PsCKernelLevel)
    (params : List PsCKernelName)
    (values : List PsCKernelLevel) : List PsCKernelLevel :=
  match levels with
  | [] => []
  | level :: rest =>
      psCKernelInstantiateLevel level params values ::
        psCKernelInstantiateLevelList rest params values

def psCKernelInstantiateExprLevels
    (expr : PsCKernelExpr)
    (params : List PsCKernelName)
    (values : List PsCKernelLevel) : PsCKernelExpr :=
  match params with
  | [] => expr
  | _ =>
      match expr with
      | PsCKernelExpr.bvar _ => expr
      | PsCKernelExpr.fvar _ => expr
      | PsCKernelExpr.mvar _ => expr
      | PsCKernelExpr.sortE level =>
          PsCKernelExpr.sortE
            (psCKernelInstantiateLevel level params values)
      | PsCKernelExpr.constE name levels =>
          PsCKernelExpr.constE
            name
            (psCKernelInstantiateLevelList levels params values)
      | PsCKernelExpr.app fn arg =>
          PsCKernelExpr.app
            (psCKernelInstantiateExprLevels fn params values)
            (psCKernelInstantiateExprLevels arg params values)
      | PsCKernelExpr.lam name type body binderInfo =>
          PsCKernelExpr.lam
            name
            (psCKernelInstantiateExprLevels type params values)
            (psCKernelInstantiateExprLevels body params values)
            binderInfo
      | PsCKernelExpr.forallE name type body binderInfo =>
          PsCKernelExpr.forallE
            name
            (psCKernelInstantiateExprLevels type params values)
            (psCKernelInstantiateExprLevels body params values)
            binderInfo
      | PsCKernelExpr.letE name type value body nondep =>
          PsCKernelExpr.letE
            name
            (psCKernelInstantiateExprLevels type params values)
            (psCKernelInstantiateExprLevels value params values)
            (psCKernelInstantiateExprLevels body params values)
            nondep
      | PsCKernelExpr.lit _ => expr
      | PsCKernelExpr.proj typeName index value =>
          PsCKernelExpr.proj
            typeName
            index
            (psCKernelInstantiateExprLevels value params values)
