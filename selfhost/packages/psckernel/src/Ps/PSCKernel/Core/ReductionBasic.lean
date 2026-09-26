import Ps.PSCKernel.Core.Environment
import Ps.PSCKernel.Core.LocalContext
import Ps.PSCKernel.Core.ExprLevelInstantiation
import Ps.PSCKernel.Core.ExprInstantiation

def psCKernelExprUnfoldDefinitionBasic?
    (env : PsCKernelEnvironment)
    (expr : PsCKernelExpr) : Option PsCKernelExpr :=
  match expr with
  | PsCKernelExpr.constE name levels =>
      match psCKernelEnvironmentFind? env name with
      | some info =>
          match info with
          | PsCKernelConstantInfo.defnInfo value =>
              if Nat.beq levels.length value.base.levelParams.length then
                some
                  (psCKernelInstantiateExprLevels
                    value.value
                    value.base.levelParams
                    levels)
              else
                none
          | _ => none
      | none => none
  | _ => none

partial def psCKernelExprWhnfBasic
    (env : PsCKernelEnvironment)
    (lctx : PsCKernelLocalContext)
    (expr : PsCKernelExpr) : PsCKernelExpr :=
  match expr with
  | PsCKernelExpr.fvar fvarId =>
      match psCKernelLocalContextFind? lctx fvarId with
      | none => expr
      | some decl =>
          match psCKernelLocalDeclValue? decl false with
          | none => expr
          | some value => psCKernelExprWhnfBasic env lctx value
  | PsCKernelExpr.constE _ _ =>
      match psCKernelExprUnfoldDefinitionBasic? env expr with
      | none => expr
      | some value => psCKernelExprWhnfBasic env lctx value
  | PsCKernelExpr.app fn arg =>
      let reducedFn : PsCKernelExpr := psCKernelExprWhnfBasic env lctx fn
      match reducedFn with
      | PsCKernelExpr.lam _ _ body _ =>
          psCKernelExprWhnfBasic
            env
            lctx
            (psCKernelExprInstantiate1 body arg)
      | _ =>
          if psCKernelExprEqStructural reducedFn fn then
            expr
          else
            PsCKernelExpr.app reducedFn arg
  | PsCKernelExpr.letE _ _ value body _ =>
      psCKernelExprWhnfBasic
        env
        lctx
        (psCKernelExprInstantiate1 body value)
  | _ => expr
